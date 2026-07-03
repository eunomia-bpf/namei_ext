# Terminal-Bench Forensics And Document Suite Reproduction

Date: 2026-07-01

## Motivation

This record extends the selected Terminal-Bench official-task reproduction with
document processing, browser-backed security filtering, binary/forensic
analysis, archive recovery, and structured data tasks. The purpose is workload
selection: these tasks provide real Docker-backed inputs, file-state changes,
and executable pytest oracles. They do not prove that the workloads require
`namei_ext`, eBPF, or any particular mechanism.

Raw artifacts stay under `results/`; this Markdown file records only the
standalone evidence summary required for Phase 1 documentation.

## Source And Command

Source checkout:

- Terminal-Bench: `.cache/source-inspection/terminal-bench`
- Upstream commit recorded by the harness: `1a6ffa9674b571da0ed040c470cb40c4d85f9b9b`

Command:

```bash
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache timeout 7200 uv run tb run \
  --dataset-path original-tasks \
  --task-id heterogeneous-dates \
  --task-id financial-document-processor \
  --task-id html-finance-verify \
  --task-id filter-js-from-html \
  --task-id password-recovery \
  --task-id crack-7z-hash \
  --task-id extract-elf \
  --task-id reverse-engineering \
  --agent oracle \
  --n-concurrent 1 \
  --n-attempts 1 \
  --run-id 2026-07-01__terminal-bench-forensics-document-oracle-suite \
  --output-path /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-01-official-workloads/terminal-bench-forensics-document-oracle-suite \
  --no-upload-results \
  --cleanup
```

## Raw Artifacts

- Summary: `results/reproduction/2026-07-01-official-workloads/terminal-bench-forensics-document-oracle-suite/summary.json`
- Results: `results/reproduction/2026-07-01-official-workloads/terminal-bench-forensics-document-oracle-suite/2026-07-01__terminal-bench-forensics-document-oracle-suite/results.json`
- Metadata: `results/reproduction/2026-07-01-official-workloads/terminal-bench-forensics-document-oracle-suite/2026-07-01__terminal-bench-forensics-document-oracle-suite/run_metadata.json`
- Run log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-forensics-document-oracle-suite/2026-07-01__terminal-bench-forensics-document-oracle-suite/run.log`

## Result

The official, unmodified selected suite ran through the upstream harness with
the upstream oracle agent.

| Task | Result | Parser checks | Workload and oracle shape |
| --- | --- | --- | --- |
| `reverse-engineering` | resolved | 2/2 passed | Reverse engineer a compiled application, run it, and check generated output plus password validation. |
| `financial-document-processor` | resolved | 7/7 passed | Classify mixed JPG/PDF documents, move invoices and other files, extract totals/VAT, create invoice CSV, and empty the source directory. |
| `crack-7z-hash` | resolved | 2/2 passed | Recover the word inside an encrypted `secrets.7z` archive and write `/app/solution.txt`. |
| `filter-js-from-html` | resolved | 2/2 passed | Create in-place HTML JavaScript filter; pytest uses browser-backed XSS vectors and clean-HTML preservation checks. |
| `heterogeneous-dates` | resolved | 3/3 passed | Compute an average high-low temperature difference from two CSV files and write a numeric output file. |
| `password-recovery` | unresolved | 0/2 passed | Deleted-file forensic password recovery; the oracle-agent run did not create `/app/recovered_passwords.txt`, so file-exists and password-match checks failed. |
| `extract-elf` | resolved | 2/2 passed | Write `extract.js` to extract memory values from an ELF binary into JSON; tests require exact values and at least 75% coverage. |
| `html-finance-verify` | resolved | 1/1 passed | Inspect an earnings-report HTML/MHTML file and output the incorrect financial metric line/value. |

Suite summary:

- `n_tasks=8`
- `n_resolved=7`
- `n_unresolved=1`
- `accuracy=0.875`
- parser checks: 19 passed, 2 failed

## Reuse Decision

Reuse this suite as Terminal-Bench workload-source evidence for:

- document classification, OCR-like extraction, file movement, and summary
  materialization;
- browser-backed security filtering with XSS behavior checks;
- binary reverse engineering and ELF extraction;
- encrypted archive recovery;
- structured CSV and HTML financial data-output oracles.

The negative `password-recovery` result should be preserved as a workload-level
oracle failure in the unmodified official run. It is still a useful task shape,
but it is not a passing official reproduction from this run.

## Boundary

This is selected official-task reproduction, not full Terminal-Bench-Core
reproduction. It should be cited as a source of real task inputs and oracles
for future `namei_ext` workload construction, not as a claim that these tasks
require a path-view hook.
