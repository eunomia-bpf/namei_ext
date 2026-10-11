# OSDI External Baseline Ledger

- Run ID: 20260615T-kvm-external-baselines-release-pilot
- Raw JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/baselines/20260615T-kvm-external-baselines-release-pilot/baselines.jsonl
- Ledger JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/baselines/20260615T-kvm-external-baselines-release-pilot/baseline-ledger.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/baselines/20260615T-kvm-external-baselines-release-pilot/baseline-inputs.sha256
- Manifest: /home/yunwei37/workspace/namei_ext/results/eval-osdi/baselines/20260615T-kvm-external-baselines-release-pilot/manifest.json
- Baseline smoke gate pass: true
- Baseline release gate pass: true

## Baselines
- copy_tree: selected=true, smoke_pass=true, release_pass=true, samples=20, min_bench_rows=20, min_latency_rows=20, setup_ns=520018, update_ns=7577, files=131, symlinks=0, bind_mounts=0, overlay_mounts=0, fuse_mounts=0, bytes_copied=325, bench_rows=160, content_rows=20, failing_ops=0
- symlink_forest: selected=true, smoke_pass=true, release_pass=true, samples=20, min_bench_rows=20, min_latency_rows=20, setup_ns=301004, update_ns=2336, files=66, symlinks=65, bind_mounts=0, overlay_mounts=0, fuse_mounts=0, bytes_copied=0, bench_rows=160, content_rows=20, failing_ops=0
- bind_mount: selected=true, smoke_pass=true, release_pass=true, samples=20, min_bench_rows=20, min_latency_rows=20, setup_ns=423049, update_ns=2253, files=131, symlinks=0, bind_mounts=65, overlay_mounts=0, fuse_mounts=0, bytes_copied=0, bench_rows=160, content_rows=20, failing_ops=0
- overlayfs: selected=true, smoke_pass=true, release_pass=true, samples=20, min_bench_rows=20, min_latency_rows=20, setup_ns=461423, update_ns=4976, files=131, symlinks=0, bind_mounts=0, overlay_mounts=1, fuse_mounts=0, bytes_copied=325, bench_rows=160, content_rows=20, failing_ops=0
- fuse_redirect: selected=true, smoke_pass=true, release_pass=true, samples=20, min_bench_rows=20, min_latency_rows=20, setup_ns=51209985, update_ns=10158, files=66, symlinks=0, bind_mounts=0, overlay_mounts=0, fuse_mounts=1, bytes_copied=0, bench_rows=160, content_rows=20, failing_ops=0

## Missing Release Evidence
- missing release baselines: 
- release gate pass: true
