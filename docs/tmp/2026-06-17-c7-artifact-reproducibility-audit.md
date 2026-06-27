# C7 artifact reproducibility audit ledger

## Motivation

当前 claim verdict v11 把 C7 artifact reproducibility scoped out。已有 Make-owned
ledgers 能追溯 W2 paper-release gate、tool-redirect C3、C4 lookup/readdir matrix、
C3 full-suite residual diagnostic 和 C5 rusage/no-hook ablation，但还缺一个独立
artifact audit，把当前论文构建、证据路径、input hashes、worktree cleanliness、
sanitized artifact package manifest 和 clean-checkout blocker 放在同一个 result root 中。

该 step 的目标不是把 C7 升级为 supported claim，而是让 C7 的负结论可复查：当前论文
可以从现有 evidence 构建，关键 evidence paths 存在，sanitized evidence package 已能生成，
且 package-root 能重放论文构建；但 dirty worktrees 和缺失的 clean-checkout gate
仍阻止 reproducibility claim。

## Files inspected or changed

- `mk/eval_osdi.mk`
- `Makefile`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/07-limitations.tex`
- `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v11/claim-verdict/claim-verdict.jsonl`
- `results/eval-osdi/paper/20260617T-eval-c3-full-suite-residual-diagnostic-v3/b2-performance/c3-full-suite-residual-diagnostic.jsonl`
- `results/eval-osdi/paper/20260617T-eval-c5-rusage-nohook-ablation-v2/b2-performance/c5-rusage-nohook-ablation.jsonl`

## Implementation

新增 Make target:

```text
make eval-osdi-c7-artifact-audit-ledger
```

该 target 在 `mk/eval_osdi.mk` 中实现，遵守 Makefile-only control plane。它要求
`jq`、`sha256sum`、`git` 和 `tar` 可用，并显式读取：

- claim verdict v11；
- C3 full-suite residual diagnostic v3；
- C5 rusage/no-hook ablation v2；
- 当前 `docs/paper` LaTeX sections；
- `.build/paper/main.pdf` 和 `.build/paper/main.log`；
- `mk/eval_osdi.mk`。

target 会先运行：

```text
make -C docs/paper check
make -C docs/paper paper
```

随后写出 main repo 和 kernel repo 的 `git status --porcelain`，记录各自 HEAD 和 dirty
entry 数；再生成 package file list、sanitized package root、package tar、tar list、
package manifest 和 anonymization checklist。v5 还把 `docs/paper/Makefile` 放进
package，并在 replay 前删除 package-root 内已打包的 `.build/paper`，再从 sanitized
package root 运行 `make -C docs/paper check` 和 `paper`，保留 replay log 与 replay
PDF/log。最后 target 生成 input hash manifest，并用
`sha256sum -c` 立即校验。

输出 JSONL summary 包含：

- `clean_checkout_gate_pass`
- `paper_build_artifact_pass`
- `evidence_paths_pass`
- `artifact_package_gate_pass`
- `artifact_package_replay_pass`
- `anonymization_checklist_gate_pass`
- `c7_supported`
- `release_gate_pass`
- package declared file count 和 tar entry count
- sanitized package 中 `/home/...` absolute path 命中数
- paper log 中 `Float too large` 和 `Overfull \hbox` 计数
- missing evidence list

v5 中 `artifact_package_gate_pass=true`，因为 17 个声明文件全部进入 Make-owned tar
package；`artifact_package_replay_pass=true`，因为 sanitized package root 能重放
`docs/paper` check/paper；`anonymization_checklist_gate_pass=true`，因为 sanitized
package root 中 host-specific `/home/...` 绝对路径命中数为 0。target 是 diagnostic
ledger，仍不把 clean-checkout 负结果伪装成 release pass。

## Validation command

本轮生成的 canonical command 是：

```text
make eval-osdi-c7-artifact-audit-ledger \
  RUN_ID=20260617T-eval-c7-artifact-audit-v11 \
  EVAL_OSDI_C7_AUDIT_CLAIM_RUN_ID=20260617T-eval-claim-verdict-ledger-v11 \
  EVAL_OSDI_C7_AUDIT_C3_RUN_ID=20260617T-eval-c3-full-suite-residual-diagnostic-v3 \
  EVAL_OSDI_C7_AUDIT_C5_RUN_ID=20260617T-eval-c5-rusage-nohook-ablation-v2
```

该 target 通过，并生成：

- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/c7-artifact-reproducibility-audit.jsonl`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/c7-artifact-reproducibility-audit-inputs.sha256`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/c7-artifact-reproducibility-audit-manifest.json`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/c7-artifact-reproducibility-audit-summary.md`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/artifact-package-files.txt`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/package-root/`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/namei-ext-osdi-evidence-package.tar`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/artifact-package-tar-list.txt`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/artifact-package-manifest.json`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/artifact-anonymization-checklist.json`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/artifact-package-replay.log`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/package-root/.build/paper/main.pdf`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/package-root/.build/paper/main.log`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/main-repo-status.txt`
- `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/kernel-repo-status.txt`

## Result

Summary event:

- `paper_build_artifact_pass=true`
- `evidence_paths_pass=true`
- `clean_checkout_gate_pass=false`
- `artifact_package_gate_pass=true`
- `artifact_package_replay_pass=true`
- `anonymization_checklist_gate_pass=true`
- `c7_supported=false`
- `release_gate_pass=false`
- main repo HEAD `6fe308aa3a16a9ea160f634f60ed76427dcc1b7c`
- main repo dirty entries `208`
- kernel repo HEAD `31a33d22c2122f0db82553fc5325cfc273fe22e0`
- kernel repo dirty entries `4`
- package declared file count `17`
- package tar entry count `17`
- package absolute path occurrences `0`
- package-root paper replay check and build passed
- paper `float_too_large_count=0`
- paper `overfull_hbox_count=8`

The missing evidence list is:

- clean checkout reproduction

## Design choices and alternatives rejected

- Do not add a shell script. The target is Make-owned and writes all artifacts under
  `results/eval-osdi/paper/<RUN_ID>/artifact-audit/`.
- Do not silently pass C7. The JSONL explicitly records `c7_supported=false` and
  `release_gate_pass=false`.
- Do not put raw JSON/log output under `docs/tmp/`. This document records the implementation
  step; raw results stay under `results/`.
- Do not mutate raw results to anonymize them. The target creates a sanitized package root
  under `results/` and runs the anonymization checklist on that derived package, while raw
  result files keep their original provenance outside the package root.
- Do not treat a package tar as reproducible just because it exists. The v5 target includes
  `docs/paper/Makefile`, removes package-root `.build/paper` before replay, and replays
  `make -C docs/paper check` plus `paper` from the sanitized package root, with replay log,
  replay PDF, and replay LaTeX log preserved under `results/`.
- Do not require a clean checkout as an immediate hard failure for the diagnostic target.
  The target records dirty status as raw evidence and keeps the C7 gate false. A future
  release target can turn clean-checkout reproduction into a hard pass/fail gate.

## Remaining risks and follow-up

To support C7, the project still needs a clean-checkout reproduction target that verifies the
same paper/evidence reconstruction path outside the dirty development worktrees. Until that exists,
C7 must remain scoped out in the paper.
