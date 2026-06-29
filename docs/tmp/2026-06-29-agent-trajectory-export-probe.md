# Agent Trajectory Export Probe

## Motivation

We need a reproducible agent-sandbox workload source based on existing command
trajectory formats, not a project-owned command trace schema. The immediate
question was whether SWE-bench Pro Docent trajectories can be bulk exported; if
not, whether Open-SWE-Traces or Nebius trajectories can be downloaded and used
as-is.

Raw probe outputs from this step were written under:

```text
results/research-probes/20260620T-agent-trace-download-probe/
```

Those files include fetched Docent pages, DQL responses, Hugging Face dataset
viewer responses, and README/parquet metadata. The directory name kept the
existing probe root created earlier in the thread; this document records the
2026-06-29 follow-up.

## Sources Checked

- SWE-bench Pro public leaderboard:
  <https://labs.scale.com/leaderboard/swe_bench_pro_public>
- Docent dashboard collection:
  <https://docent.transluce.org/dashboard/032fb63d-4992-4bfc-911d-3b7dafcb931f/>
- Docent export documentation:
  <https://docs.transluce.org/analysis/exporting>
- Docent DQL schema documentation:
  <https://docs.transluce.org/sdk/dql/schema>
- Open-SWE-Traces:
  <https://huggingface.co/datasets/nvidia/Open-SWE-Traces>
- Nebius SWE-agent trajectories:
  <https://huggingface.co/datasets/nebius/SWE-agent-trajectories>
- Nebius OpenHands trajectories:
  <https://huggingface.co/datasets/nebius/SWE-rebench-openhands-trajectories>

## Docent / SWE-bench Pro Findings

The static Docent dashboard pages return HTTP 200 but do not embed transcript
rows in the HTML. The page shell exposes the collection id and front-end chunks,
but not the agent-run table data or transcript data directly.

The Python SDK (`docent-python`) requires an API key at construction time:

```text
ValueError: api_key is required. Please provide an api_key, set the DOCENT_API_KEY
environment variable, or include DOCENT_API_KEY in a docent.env file.
```

However, the public DQL HTTP endpoint itself accepted no-auth POST requests when
called directly:

```text
POST https://api.docent.transluce.org/rest/dql/032fb63d-4992-4bfc-911d-3b7dafcb931f/execute
body: {"dql": "...", "source": "endpoint", "surface": "sdk"}
```

Small DQL probes succeeded:

- `SELECT COUNT(1) FROM transcripts t` returned `9729`.
- `SELECT COUNT(1) FROM agent_runs ar` returned `9729`.
- `LIMIT 3 OFFSET 0` and `LIMIT 3 OFFSET 3` over `transcripts` joined to
  `agent_runs` both returned rows, so the collection is pageable.
- A sample query selecting `t.messages`, transcript metadata, and agent-run
  metadata returned three large transcript rows.

The directly usable Docent export query is:

```sql
SELECT
  t.id AS transcript_id,
  t.name AS transcript_name,
  t.messages,
  t.metadata_json AS transcript_metadata,
  ar.id AS agent_run_id,
  ar.name AS agent_run_name,
  ar.metadata_json AS agent_run_metadata
FROM transcripts t
JOIN agent_runs ar ON ar.id = t.agent_run_id
ORDER BY t.id
LIMIT 3 OFFSET 0
```

The problem is command fidelity. In the sampled SWE-bench Pro Docent rows,
`messages` decodes to a JSON list of turns, but assistant turns had
`tool_calls: null`; tool outputs appeared as `Observation:` user turns. The
sample carried repository observations and file outputs, but not explicit command
invocations as first-class tool-call records. Docent DQL schema documentation
lists tables such as `agent_runs`, `transcripts`, and `transcript_groups`; it
does not expose a separate command/tool-event table in the checked schema docs.

Interpretation: SWE-bench Pro Docent is bulk-exportable as transcript evidence,
but the public collection should not be the primary command-trace source unless
we later find a column/table that preserves commands. It is good provenance for
SWE-bench Pro trajectories, but not yet sufficient for a command replay
workload.

## Hugging Face Trajectory Findings

### Open-SWE-Traces

The Hugging Face dataset viewer returned these public splits:

```text
nvidia/Open-SWE-Traces, config=openhands, split=minimax_m25
nvidia/Open-SWE-Traces, config=openhands, split=qwen35_122b
nvidia/Open-SWE-Traces, config=sweagent, split=minimax_m25
nvidia/Open-SWE-Traces, config=sweagent, split=qwen35_122b
```

The dataset README reports 207,489 total trajectories and describes a
`trajectory` list with per-message `role`, `content`, `reasoning_content`,
`think`, and `tool_calls`. The first-row probes confirm the native command
format is directly usable:

```json
{
  "role": "assistant",
  "tool_calls": [
    {
      "function": {
        "name": "bash",
        "arguments": "{\"command\": \"cd /testbed && grep -n \\\"get_public_key\\\" moto/kms/*.py\"}"
      },
      "type": "function"
    }
  ]
}
```

OpenHands rows similarly use function-calling tool records, for example
`execute_bash` and `str_replace_editor`, with command arguments stored as a JSON
string. The dataset server also exposes parquet URLs for bulk download. For the
`sweagent/minimax_m25` split, the first parquet chunks are about 171-206 MB
each, so a full local mirror should be a deliberate benchmark-data step rather
than a docs-only probe.

Interpretation: Open-SWE-Traces is the best immediate command-trace source. Use
its native `trajectory[*].tool_calls[*].function.arguments` schema as-is, with a
thin reader that extracts command actions for replay. Do not define a new
canonical trace schema before this ingestion path exists.

### Nebius SWE-agent Trajectories

`nebius/SWE-agent-trajectories` is public and has one `default/train` split. Its
README reports 80,036 trajectories. The first-row sample has:

```text
instance_id, model_name, target, trajectory, exit_status, generated_patch, eval_logs
```

Each trajectory item has fields such as `role` and `text`; there are no
first-class `tool_calls` in the sampled schema. Commands appear to be embedded
in SWE-agent text turns rather than exposed as function-call records.

Interpretation: usable as a secondary SWE-agent transcript source, but not the
cleanest input for command replay because it would require parsing action text.

### Nebius OpenHands Trajectories

`nebius/SWE-rebench-openhands-trajectories` is public and has one
`default/train` split. Its README reports 67,074 trajectories and documents a
native OpenHands message format with assistant `tool_calls`; the dataset viewer
schema also shows `tool_calls[*].function.arguments`. The converted parquet list
is available, but the single train parquet file is about 2.08 GB.

Interpretation: good fallback or cross-check source for OpenHands-style command
traces. It is larger per file than Open-SWE-Traces chunks, so Open-SWE-Traces is
easier for initial benchmark construction.

## Decision

For the agent-sandbox benchmark, use existing source schemas directly:

1. Primary: `nvidia/Open-SWE-Traces`, starting with `sweagent/minimax_m25` and
   one OpenHands split. Extract commands from native tool-call arguments.
2. Secondary: `nebius/SWE-rebench-openhands-trajectories`, if we need an
   independent OpenHands corpus.
3. Tertiary: SWE-bench Pro Docent transcripts, only for provenance or transcript
   comparison until explicit command calls are found.
4. Avoid `nebius/SWE-agent-trajectories` as the first replay workload because
   commands are embedded in text, not first-class tool-call objects.

The benchmark should therefore not create a project-owned command trace schema
as the input contract. The first implementation target should be a Make-owned
reader that consumes the selected source schema and emits replay actions into
the existing workload machinery. Any normalized intermediate artifact should be
treated as a generated result/cache, not as the paper's source-of-truth trace
format.

## Follow-Up Work

- Add a Make target that downloads a small pinned Open-SWE-Traces shard or first
  parquet chunk into a documented cache/result root.
- Add a fail-fast extractor that counts tool-call commands by tool name, command
  string, workspace path prefix, and resolved/unresolved status.
- Build the first replay subset from fixed task ids, not from live agent runs.
- Keep Docent DQL export as an optional provenance path; do not base the command
  replay claim on it unless a command-bearing table or column is found.
