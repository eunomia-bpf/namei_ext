# OSDI Claim Verdict Ledger

- Run ID: 20260617T-eval-claim-verdict-ledger-v6
- Raw JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v6/claim-verdict/claim-verdict.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v6/claim-verdict/claim-verdict-inputs.sha256
- Manifest: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v6/claim-verdict/claim-verdict-manifest.json

## Summary
- weak_accept_ready=false
- release_gate_pass=false
- claims=8
- active_main_claims=4
- scoped_out_claims=4
- supported_claims=3
- partial_claims=1
- unsupported_claims=0
- highest_risk_claims=C4, C5, C8
- scoped_out_rationale=C5 residual-overhead evidence is negative; C6 lacks release-level stress or scalability evidence; C7 lacks clean-checkout reproduction and artifact packaging gates; C8 table-only insufficiency is not proven by current W3/W4 counterfactuals
- required_next_actions=turn C4 from Phase 1 oracle-subset consistency into a release-wide lookup/readdir matrix; produce a full-suite C3 performance comparison if the paper wants to expand beyond tool-redirect operations; produce threshold-positive W1/W3/W4 evidence if the paper wants to expand beyond the W2 setup/materialization slice

## Per-Claim Verdicts
- C1: verdict=supported, slice_gate_pass=true, paper_release_gate_pass=false, release_gate_pass=false, wording=The Phase 1 prototype exercises one narrow VFS name-resolution ABI across four policy families in KVM-backed functional slices., scope=No qualifying end-to-end policy family yet satisfies all release gates; C1 release-level programmability and C8 are scoped out of the current main claim set, missing=
- C2: verdict=supported, slice_gate_pass=true, paper_release_gate_pass=false, release_gate_pass=false, wording=The current evidence supports only a W2 nginx fixture C2 slice, not a global setup/materialization-cost claim., scope=W1 setup latency threshold failed; W1 storage footprint gate failed; W1 update latency threshold failed; W1 update materialization threshold failed; W3 setup latency threshold failed against best external baseline; W3 update latency threshold failed against best external baseline; W4 bulk comparison gate failed against materialized/FUSE/native external baselines or missing compile smoke; W4 rule materialization threshold failed against materialized external baseline; W4 setup latency threshold failed against materialized external baseline; W4 update latency threshold failed against materialized external baseline; global C2 requires threshold-positive W1, W2, W3, and W4 slices, missing=
- C3: verdict=supported, slice_gate_pass=true, paper_release_gate_pass=false, release_gate_pass=false, wording=The tool-redirect lookup/access/open/exec slice satisfies the configured native and FUSE p99 thresholds, while the full metadata suite remains unsupported., scope=C3 policy/native p99 threshold; full-suite C3 policy/native p99 threshold, missing=
- C4: verdict=partial, slice_gate_pass=false, paper_release_gate_pass=false, release_gate_pass=false, wording=The Phase 1 rows support lookup/readdir consistency only for the declared oracle subsets., scope=, missing=No release-wide cross-workload lookup/readdir matrix with every policy family marked qualified
- C5: verdict=scoped_out, slice_gate_pass=false, paper_release_gate_pass=false, release_gate_pass=false, wording=The current paper scopes out VFS-placement attribution because residual-overhead evidence is negative., scope=, missing=C5 pass-only residual overhead threshold
- C6: verdict=scoped_out, slice_gate_pass=false, paper_release_gate_pass=false, release_gate_pass=false, wording=The current paper treats fail-fast Phase 1 diagnostics as artifact evidence, not as a release-level stress or scalability claim., scope=, missing=No release-level stress, scale, or robustness sweep
- C7: verdict=scoped_out, slice_gate_pass=false, paper_release_gate_pass=false, release_gate_pass=false, wording=The current paper treats Make-owned KVM/Docker targets and sha manifests as artifact evidence, not as submission-ready reproducibility., scope=, missing=No clean-checkout full release reproduction run; No artifact packaging/anonymization checklist gate
- C8: verdict=scoped_out, slice_gate_pass=false, paper_release_gate_pass=false, release_gate_pass=false, wording=The current paper scopes out table-only insufficiency because W3/W4 table-only comparators still explain the sampled oracles., scope=, missing=table-only budget failure; release-level stale/update window; operation-weighted policy cache hit rate strong enough to distinguish the policy from exact table updates
