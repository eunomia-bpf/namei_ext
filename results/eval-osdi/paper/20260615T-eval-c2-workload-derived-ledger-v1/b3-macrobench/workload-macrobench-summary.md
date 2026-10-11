# OSDI B3-B6 C2 Workload Macrobench Derived Ledger

- Run ID: 20260615T-eval-c2-workload-derived-ledger-v1
- Phase 1 evidence run: 20260615T-full-phase1-c2-release-sample-v1
- Raw JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-c2-workload-derived-ledger-v1/b3-macrobench/workload-macrobench.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-c2-workload-derived-ledger-v1/b3-macrobench/workload-macrobench-inputs.sha256
- workload_rows=8
- correctness_oracle_passed=5
- policy_kvm_rows=5
- c2_eligible_rows=0
- c2_supported=false
- release_gate_pass=false
- verdict=derived_contract_only
- missing_evidence=KVM per-sample workload setup/update macrobench, feature-equivalent workload baselines, C2 setup/storage/update success thresholds

## Workload Rows
- w1-redis-build: correctness=true, policy_kvm=true, setup_proxy=true, update_proxy=false, c2_eligible=false, blocker=derived from host build trace plus KVM replay; missing KVM per-sample build-graph setup/update macrobench
- w1-nginx-build: correctness=true, policy_kvm=true, setup_proxy=true, update_proxy=false, c2_eligible=false, blocker=derived from host configure/build trace plus KVM replay; missing KVM per-sample build-graph setup/update macrobench
- w2-nginx-fixture: correctness=true, policy_kvm=true, setup_proxy=true, update_proxy=false, c2_eligible=false, blocker=nginx KVM health oracle exists; missing per-sample config/secret rotation and feature-equivalent baseline comparison
- w2-postgres-secret-fixture: correctness=false, policy_kvm=false, setup_proxy=true, update_proxy=false, c2_eligible=false, blocker=PostgreSQL real app oracle is not implemented
- w3-redis-podman-criu: correctness=true, policy_kvm=true, setup_proxy=true, update_proxy=false, c2_eligible=false, blocker=Redis replay KVM oracle exists, but real Podman/CRIU restore and epoch/update macrobench are missing
- w3-nginx-podman-criu: correctness=false, policy_kvm=false, setup_proxy=true, update_proxy=false, c2_eligible=false, blocker=nginx real Podman/CRIU restore oracle is not implemented
- w4-ccache-redis-nginx: correctness=true, policy_kvm=true, setup_proxy=true, update_proxy=false, c2_eligible=false, blocker=real ccache KVM witnesses exist, but operation-weighted release hit rate and stale/update macrobench are missing
- w4-buildkit-prometheus-go-cache: correctness=false, policy_kvm=false, setup_proxy=true, update_proxy=false, c2_eligible=false, blocker=BuildKit/Prometheus real cache run is not implemented
