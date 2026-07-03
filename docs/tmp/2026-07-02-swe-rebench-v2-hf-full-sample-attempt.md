# SWE-rebench V2 HF Full Sample Attempt

Date: 2026-07-02

## Motivation

Earlier records reproduced 12/20 public Hugging Face sample rows from
SWE-rebench V2. This record attempts the remaining eight rows so the project has
a complete accounting of the public 20-row sample before choosing W4
environment/cache candidates.

This is still workload-source reproduction. It identifies usable repositories,
images, patches, test patches, and correctness oracles. It is not a claim that
these workloads require `namei_ext`.

## Source

- Official repository: <https://github.com/SWE-rebench/SWE-rebench-V2>
- Local checkout: `.cache/source-inspection/swe-rebench-v2`
- Public HF sample dataset: `ibragim-bad/SWE-rebench-V2-sample`
- Dataset split: `train`
- Evaluator: `scripts/eval.py`

An initial 8-row batch under
`results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-remaining-8/`
was interrupted after 4/8 rows. It preserved partial progress output and task
specs, but did not write a report JSON or exit-code file, so it is not used as
canonical evidence.

Canonical raw result roots:

- `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-elixir-go-remaining/`
- `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-java-remaining/`

## Commands

Both completed runs used the official evaluator and prebuilt per-instance
images:

```sh
cd /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2
python3 scripts/eval.py \
  --hf-dataset ibragim-bad/SWE-rebench-V2-sample \
  --hf-config default \
  --hf-split train \
  --hf-offset 0 \
  --hf-length 20 \
  --instance-ids <comma-separated subset> \
  --max-workers 1 \
  --golden-eval \
  --report-json "$OUT/eval_report_<subset>.json"
```

The Elixir/Go subset:

```text
elixir-ecto__ecto-2338,rrrene__credo-711,ceph__go-ceph-502,fsouza__fake-gcs-server-1035
```

The Java subset:

```text
alibaba__fescar-382,jchambers__pushy-850,gchq__gaffer-2904,apache__streampipes-2889
```

For each completed run, the raw root contains selected specs, evaluator
stdout/stderr, evaluator exit code, report JSON, and per-instance container
logs.

## Result

Completed subset summaries:

| Subset | Evaluator exit | Report `all_ok` | Interpretation |
| --- | --- | --- | --- |
| Elixir/Go remaining | 0 | true | All four rows are evaluator-positive. |
| Java remaining | 1 | false | Three rows are evaluator-positive; `alibaba__fescar-382` is a mismatch. |

Per-row results:

| Instance | Language | Image | F2P passed | P2P failures | `passed_match` | Raw row exit | Result class |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `elixir-ecto__ecto-2338` | Elixir | `docker.io/swerebenchv2/elixir-ecto-ecto:2338-16e00a3` | 1/1 | 0/806 | true | 2 | Evaluator-positive, raw-exit caveat. |
| `rrrene__credo-711` | Elixir | `docker.io/swerebenchv2/rrrene-credo:711-da1d940` | 1/1 | 0/390 | true | 2 | Evaluator-positive, raw-exit caveat. |
| `ceph__go-ceph-502` | Go | `docker.io/swerebenchv2/ceph-go-ceph:502-4440505` | 17/17 | 0/172 | true | 1 | Evaluator-positive, raw-exit caveat. |
| `fsouza__fake-gcs-server-1035` | Go | `docker.io/swerebenchv2/fsouza-fake-gcs-server:1035-34afa14` | 667/667 | 0/27 | true | 0 | Clean positive row. |
| `alibaba__fescar-382` | Java | `docker.io/swerebenchv2/alibaba-fescar:382-7549d2f` | 24/25 | 0/0 | false | 1 | Mismatch; missing one expected fail-to-pass marker. |
| `jchambers__pushy-850` | Java | `docker.io/swerebenchv2/jchambers-pushy:850-8513c25` | 25/25 | 0/0 | true | 0 | Clean positive row. |
| `gchq__gaffer-2904` | Java | `docker.io/swerebenchv2/gchq-gaffer:2904-5fcab09` | 3/3 | 0/0 | true | 1 | Evaluator-positive, raw-exit caveat. |
| `apache__streampipes-2889` | Java | `docker.io/swerebenchv2/apache-streampipes:2889-f8f9ee3` | 82/82 | 0/42 | true | 1 | Evaluator-positive, raw-exit caveat. |

The `alibaba__fescar-382` expected `FAIL_TO_PASS` list contains 25 names. The
report matched 24 of them; the unmatched expected marker is
`---NO TEST NAME FOUND YET---`. The raw Maven log shows a build failure in
`com.alibaba.fescar.core.rpc.netty.TmRpcClientTest`.

Raw-log notes:

- `fsouza__fake-gcs-server-1035` ended with `PASS` and
  `ok github.com/fsouza/fake-gcs-server/fakestorage`.
- `jchambers__pushy-850` ended with Maven `BUILD SUCCESS`.
- `elixir-ecto__ecto-2338` and `rrrene__credo-711` passed the evaluator
  oracle, but their raw ExUnit summaries contained many failures outside the
  expected pass/fail oracle, explaining raw exit 2.
- `ceph__go-ceph-502`, `gchq__gaffer-2904`, and
  `apache__streampipes-2889` passed the evaluator oracle while preserving raw
  nonzero exit codes and raw test failures/build failures outside the matched
  expected oracle.

Docker residual checks after the completed runs found no matching SWE-rebench,
Elixir, Go, or Java sample containers/images.

## Sample Coverage

The public HF sample now has complete attempted coverage:

- total rows: 20/20 attempted
- evaluator-positive rows: 19/20
- mismatch rows: 1/20 (`alibaba__fescar-382`)
- clean raw-exit-0 positives: 11/20
- evaluator-positive rows with raw-exit caveats: 8/20

Rows that are clean raw-exit-0 positives and are preferable first-choice W4
candidates:

- `unidata__netcdf-c-1925`
- `chrovis__cljam-268`
- `pilosus__pip-license-checker-119`
- `pilosus__pip-license-checker-49`
- `nyxx-discord__nyxx-547`
- `mgechev__revive-1408`
- `hashicorp__consul-10576`
- `fsouza__fake-gcs-server-1035`
- `jchambers__pushy-850`
- `spoonlabs__gumtree-spoon-ast-diff-171`
- `pbiswas101__mathball-153`

Rows that are evaluator-positive but should be treated as caveated:

- `yogthos__migratus-223`
- `btcpayserver__btcpayserver-6251`
- `mhanberg__temple-135`
- `elixir-ecto__ecto-2338`
- `rrrene__credo-711`
- `ceph__go-ceph-502`
- `gchq__gaffer-2904`
- `apache__streampipes-2889`

Rows that are not evaluator-positive on this run:

- `alibaba__fescar-382`

## Boundaries

This completes attempted coverage of the public 20-row HF sample, not full
positive reproduction of every row. It is not full SWE-rebench V2 corpus
reproduction, base-image builder reproduction, per-instance image builder
reproduction, or environment-generation reproduction.

The clean raw-exit rows are stronger candidates for paper-facing W4
environment/cache experiments. Caveated rows remain useful as source-diversity
and evaluator-boundary evidence, but should not be used as first-choice
correctness oracles without explaining the raw failures.

## Use In `namei_ext`

The best additional W4 candidates from this record are
`fsouza__fake-gcs-server-1035` and `jchambers__pushy-850`, because both are
clean raw-exit-0 positives from the previously unreproduced sample remainder.
They add high-cardinality Go and Java workload options beyond the earlier
`mgechev/revive`, `hashicorp/consul`, and SpoonLabs rows.
