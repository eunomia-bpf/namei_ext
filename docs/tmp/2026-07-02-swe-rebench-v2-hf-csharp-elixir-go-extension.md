# SWE-rebench V2 HF Csharp/Elixir/Go Extension

Date: 2026-07-02

## Motivation

The prior SWE-rebench V2 records covered the README C row, all four public HF
Clojure sample rows, one JavaScript row, one Dart row, one Go row, and one Java
row. This record extends the same official evaluator workflow to three more
public HF sample rows:

- C#: `btcpayserver__btcpayserver-6251`
- Elixir: `mhanberg__temple-135`
- Go: `hashicorp__consul-10576`

The goal is workload-source reproduction: identify which SWE-rebench V2 rows
can provide real repository, Docker image, patch, test-patch, and test-oracle
inputs for a later W4 environment/cache workload. This remains workload
evidence, not proof that the workload requires `namei_ext`.

## Source

- Official repository: <https://github.com/SWE-rebench/SWE-rebench-V2>
- Local checkout: `.cache/source-inspection/swe-rebench-v2`
- Public HF sample dataset: `ibragim-bad/SWE-rebench-V2-sample`
- Dataset split used by the official evaluator: `train`
- Local evaluator command: `scripts/eval.py`
- Raw result roots:
  - `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-csharp/`
  - `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-elixir/`
  - `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-go-consul/`

Selected rows:

| Instance | Repository | Language | Base commit | Image | Test command | F2P | P2P |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `btcpayserver__btcpayserver-6251` | `btcpayserver/btcpayserver` | C# | `272cc3d3c9caf97e538dfcc855ae2cee7c1c45fa` | `docker.io/swerebenchv2/btcpayserver-btcpayserver:6251-272cc3d` | `cd BTCPayServer.Tests && dotnet test -c Release --filter "CanParse\|CanHandle\|CanCalculate\|CanDetect" --logger "console;verbosity=normal" --logger "trx;LogFileName=test-results.xml" && find . -name 'test-results.xml' -exec cat {} \;` | 21 | 0 |
| `mhanberg__temple-135` | `mhanberg/temple` | Elixir | `49ebe8c6031a1f2131923b80432f3a5237e31237` | `docker.io/swerebenchv2/mhanberg-temple:135-49ebe8c` | `TERM=dumb ANSICON=false mix test --trace` | 51 | 12 |
| `hashicorp__consul-10576` | `hashicorp/consul` | Go | `7f083f70ca265548c5c1c29ad571b44416bff373` | `docker.io/swerebenchv2/hashicorp-consul:10576-7f083f7` | `cd agent && go test -v -run ".*[Cc]atalog.*" .` | 39 | 0 |

The selected task specs are saved under their raw result roots as:

- `selected_spec_btcpayserver__btcpayserver-6251.json`
- `selected_spec_mhanberg__temple-135.json`
- `selected_spec_hashicorp__consul-10576.json`

## Commands

Spec extraction used the official evaluator's HF loader:

```sh
cd /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2
python3 - <<'PY' > "$OUT/selected_spec_<instance>.json"
import json
from scripts.eval import load_specs_from_hf
specs = load_specs_from_hf(
    "ibragim-bad/SWE-rebench-V2-sample", "default", "train", 0, 20
)
selected = [s for s in specs if s.get("instance_id") == "<instance>"]
print(json.dumps(selected[0], indent=2, sort_keys=True))
PY
```

Each row was replayed through the official evaluator:

```sh
python3 scripts/eval.py \
  --hf-dataset ibragim-bad/SWE-rebench-V2-sample \
  --hf-config default \
  --hf-split train \
  --hf-offset 0 \
  --hf-length 20 \
  --instance-ids <instance> \
  --max-workers 1 \
  --golden-eval \
  --report-json "$OUT/eval_report_<instance>.json"
```

After each run, the evaluator stdout/stderr, evaluator exit code, report JSON,
selected spec, and container test log were preserved under the raw result root.

## Result

Evaluator-level summary:

| Instance | Evaluator exit | Report `all_ok` | `passed_match` | Row raw exit | F2P passed | P2P failures | Interpretation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `btcpayserver__btcpayserver-6251` | 0 | true | true | 1 | 21/21 | 0/0 | Positive evaluator oracle with raw row exit caveat. |
| `mhanberg__temple-135` | 0 | true | true | 2 | 51/51 | 0/12 | Positive evaluator oracle with raw row exit caveat. |
| `hashicorp__consul-10576` | 0 | true | true | 0 | 39/39 | 0/0 | Clean positive row. |

Raw-log notes:

- C# applied the gold patch and test patch cleanly, then `dotnet test` reported
  22 total tests, 21 passed, and 1 failed. The official parser still matched
  all 21 expected fail-to-pass tests and no pass-to-pass failures were defined.
- Elixir applied through the official evaluator and parser matched all 51
  fail-to-pass tests with no pass-to-pass failures. The raw ExUnit summary
  reported 94 tests and 6 failures, which explains the nonzero row exit.
- Go/Consul applied cleanly and `go test` ended with `PASS` and
  `ok github.com/hashicorp/consul/agent`; the row raw exit was 0.

Docker residual checks for matching SWE-rebench, `btcpayserver`, `mhanberg`,
`temple`, `hashicorp`, and `consul` images or containers returned no matches
after the runs.

## Workload Shapes Reproduced

This extension adds:

- a C#/.NET repository and targeted `dotnet test` workload;
- an Elixir/Mix repository and `mix test --trace` workload;
- a second Go repository with a targeted Consul agent catalog test workload;
- three additional public HF sample rows with preserved image identity, base
  commit, patch, test patch, and parsed correctness oracle.

Together with earlier records, selected SWE-rebench V2 evidence now covers
12/20 public HF sample rows:

- C: `unidata__netcdf-c-1925`
- Clojure: `chrovis__cljam-268`, `pilosus__pip-license-checker-119`,
  `yogthos__migratus-223`, `pilosus__pip-license-checker-49`
- C#: `btcpayserver__btcpayserver-6251`
- Dart: `nyxx-discord__nyxx-547`
- Elixir: `mhanberg__temple-135`
- Go: `mgechev__revive-1408`, `hashicorp__consul-10576`
- Java: `spoonlabs__gumtree-spoon-ast-diff-171`
- JavaScript: `pbiswas101__mathball-153`

Rows with raw row exit caveats are `yogthos__migratus-223`,
`btcpayserver__btcpayserver-6251`, and `mhanberg__temple-135`. Prefer clean raw
exit 0 rows for paper-facing W4 candidates unless the caveat itself is useful.

## Boundaries

This is still not full 20-task HF sample reproduction, full SWE-rebench V2
corpus reproduction, base-image builder reproduction, per-instance image
builder reproduction, or environment-generation reproduction.

Remaining public HF sample rows after this record include additional Elixir,
Go, and Java rows. They should be replayed before claiming complete HF sample
coverage.

## Use In `namei_ext`

`hashicorp__consul-10576` is a strong additional W4 candidate because it has a
clean raw exit status and a targeted Go test oracle. The C# and Elixir rows are
still useful for source diversity and parser/evaluator behavior, but their
nonzero raw row exits should keep them out of the first paper-facing W4
candidate set unless explicitly used as caveated workload evidence.
