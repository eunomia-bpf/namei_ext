# OSDI External Baseline Ledger

- Run ID: 20260615T-kvm-external-baselines-batch64-v1
- Raw JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/baselines/20260615T-kvm-external-baselines-batch64-v1/baselines.jsonl
- Ledger JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/baselines/20260615T-kvm-external-baselines-batch64-v1/baseline-ledger.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/baselines/20260615T-kvm-external-baselines-batch64-v1/baseline-inputs.sha256
- Manifest: /home/yunwei37/workspace/namei_ext/results/eval-osdi/baselines/20260615T-kvm-external-baselines-batch64-v1/manifest.json
- Baseline smoke gate pass: true
- Baseline release gate pass: true
- Baseline unique sample budget pass: true

## Baselines
- copy_tree: selected=true, smoke_pass=true, release_pass=true, expected_bench_set=true, expected_latency_set=true, missing_bench_cases=, missing_latency_cases=, samples=20, min_bench_rows=20, min_latency_rows=20, setup_ns=703315, update_ns=9172, files=131, symlinks=0, bind_mounts=0, overlay_mounts=0, fuse_mounts=0, bytes_copied=325, bench_rows=160, content_rows=20, failing_ops=0
- symlink_forest: selected=true, smoke_pass=true, release_pass=true, expected_bench_set=true, expected_latency_set=true, missing_bench_cases=, missing_latency_cases=, samples=20, min_bench_rows=20, min_latency_rows=20, setup_ns=491542, update_ns=5428, files=66, symlinks=65, bind_mounts=0, overlay_mounts=0, fuse_mounts=0, bytes_copied=0, bench_rows=160, content_rows=20, failing_ops=0
- bind_mount: selected=true, smoke_pass=true, release_pass=true, expected_bench_set=true, expected_latency_set=true, missing_bench_cases=, missing_latency_cases=, samples=20, min_bench_rows=20, min_latency_rows=20, setup_ns=475613, update_ns=3957, files=131, symlinks=0, bind_mounts=65, overlay_mounts=0, fuse_mounts=0, bytes_copied=0, bench_rows=160, content_rows=20, failing_ops=0
- overlayfs: selected=true, smoke_pass=true, release_pass=true, expected_bench_set=true, expected_latency_set=true, missing_bench_cases=, missing_latency_cases=, samples=20, min_bench_rows=20, min_latency_rows=20, setup_ns=771685, update_ns=11663, files=131, symlinks=0, bind_mounts=0, overlay_mounts=1, fuse_mounts=0, bytes_copied=325, bench_rows=160, content_rows=20, failing_ops=0
- fuse_redirect: selected=true, smoke_pass=true, release_pass=true, expected_bench_set=true, expected_latency_set=true, missing_bench_cases=, missing_latency_cases=, samples=20, min_bench_rows=20, min_latency_rows=20, setup_ns=51281458, update_ns=26970, files=66, symlinks=0, bind_mounts=0, overlay_mounts=0, fuse_mounts=1, bytes_copied=0, bench_rows=160, content_rows=20, failing_ops=0

## Missing Release Evidence
- missing release baselines: 
- min bench unique samples per case: 20
- min latency unique samples per case: 20
- release gate pass: true
