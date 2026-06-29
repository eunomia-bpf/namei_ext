# W2 nginx real trace gate implementation

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## Motivation

The previous claim-verdict ledger had auditable W2 C2 and tool-redirect C3
slices, but no paper-level release gate. The missing reviewer-facing contract
was a real application trace oracle proving that nginx, while the policy is
attached, opens the policy-visible aliases, those aliases resolve to fixture
content, and nginx does not open production decoy paths.

## Inspected paths

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `mk/eval_osdi.mk`
- `configs/eval-osdi/w2-tool-redirect-paper-release-gate.jq`
- `results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-hardgate-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl`
- `results/eval-osdi/paper/20260617T-eval-performance-tool-redirect-scope-v1/b2-performance/performance-tool-redirect-scope.jsonl`

## Design

The new `kvm-w2-nginx-real-trace` target runs the modified kernel in KVM and
reuses the existing real nginx oracle. The runner now has a
`--sandbox-nginx-trace` mode that keeps the original nginx config, startup,
HTTP health, endpoint, quit, pre-attach, and post-detach checks, but traces
only the nginx commands with `strace -e trace=%file`. The `nginx -t` commands
use `-f`; daemon start and quit do not, because following the daemonized
master/worker would keep strace attached after the command returns.

The Make target records raw strace logs under the Phase 1 result directory and
derives only gate facts into JSONL:

- attached nginx command traces must not contain production decoy paths;
- attached nginx command traces must show the config and endpoint aliases
  (`nginx.conf` and `upstream.sock`);
- pre-attach and post-detach negative checks must reject the alias;
- endpoint health and upstream observation must pass;
- policy load and attach must pass;
- dmesg must have no kernel warning, panic, hung task, or BUG evidence.

The runner's own direct fixture probes still compare visible aliases with
fixture backing files and production decoys, so the no-production-open check
deliberately parses only the nginx command strace logs, not the whole runner
process. This split matches the user/kernel boundary: user-space strace records
the path strings nginx opened, while the existing probe rows verify the backing
content selected by the `namei_ext` policy.

## Paper-release ledger

`eval-osdi-w2-tool-redirect-paper-release-gate` combines three evidence streams:

- W2 real nginx no-production-open trace gate;
- W2 setup/materialization macrobench ledger;
- tool-redirect lookup/access/open/exec performance scope ledger.

The target recursively validates the nested input manifests for all three
streams before producing a scoped paper-release verdict. The gate is explicitly
scoped to `w2_nginx_fixture_plus_tool_redirect_metadata`. It does not support
global C2, full-suite C3, release-wide C4, or C8.

## Alternatives rejected

- A C4 release-wide lookup/readdir matrix would be broader and more expensive
  than the immediate blocker.
- A table/update budget gate targets C8, while the current positive evidence is
  the W2 fixture and tool-redirect metadata scope.
- Wrapping the whole runner in strace would create false positives because the
  runner intentionally opens production decoys during direct fixture probes.

## Validation plan

Run:

```text
make kvm-w2-nginx-real-trace RUN_ID=20260617T-w2-nginx-real-trace-release-v1
make eval-osdi-w2-tool-redirect-paper-release-gate \
  RUN_ID=20260617T-eval-w2-tool-redirect-paper-release-v1 \
  EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_RUN_ID=20260617T-w2-nginx-real-trace-release-v1 \
  EVAL_OSDI_W2_TOOL_REDIRECT_W2_RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-hardgate-v5 \
  EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_RUN_ID=20260617T-eval-performance-tool-redirect-scope-v1
```

Remaining risk: this is a scoped paper-release gate, not a full release claim
for every workload family or metadata operation.
