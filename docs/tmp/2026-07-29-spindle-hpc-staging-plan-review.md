# Spindle HPC File-Staging Plan Review

## Scope

One independent reviewer is used for this experiment. This file preserves the
initial review and all follow-ups. Reviewers do not edit the plan.

## Round 1: Revision 1

The reviewer returned `NO-GO`.

Blocking findings:

1. `test_driver --dlopen --nompi` cannot print the planned exact `PASSED.`
   oracle. Upstream leaves `rank == -1` in `--nompi` mode and reports success
   only through exit status.
2. `--nompi` skips upstream exec and stat suites, so the planned scope was
   broader than the executed source behavior.
3. Manually copying the complete testsuite to tmpfs did not reuse Spindle's
   population/cache control plane. Spindle stores files under generated names
   such as `<index>-spindlens-dso-<basename>`.
4. The copied-executable protocol omitted libtool's real ELF, startup
   libraries, `SPINDLE_TEST`, `LDCS_CHOSEN_PARSED_CACHEPATH`, working-directory
   fixtures, interposition cleanup, and unprivileged identity.
5. A passing source test with the source visible did not prove cache
   engagement. The plan needed `--noclean`, mandatory original-to-cache
   mappings, and cache-object evidence.
6. Cross-mount target selection is feasible, but logical and physical
   device/inode identity and unprivileged permission behavior must be checked.
7. Covering the source tree made post-run source-manifest verification
   underspecified.
8. The formal Make command, root, timeouts, completion rule, and result
   classifications were missing.

The reviewer agreed that source Spindle is the correct positive control,
withdrawn is a causal control, and no FUSE baseline is required for an
RQ1-only correctness experiment.

Final verdict: NO-GO

## Revision 2 Response

Revision 2:

- uses exit status for the honest `--nompi` focal loader slice;
- consumes exact Spindle-created `spindlens-file` cache files without copying
  payloads; this is the first-party cache class selected by `--strip=no`;
- requires Spindle level-3 global-to-local records, `--noclean=yes`,
  `--strip=no`, tmpfs identity, and exact source/cache hashes;
- runs the same upstream wrapper from the source tree in all conditions;
- maps each source component directly to a registered cache-file target and
  attributes hits for all 27 focal objects;
- preserves source fixtures and covers only the resolved source
  `libtest10.so` implementation for the withdrawn control;
- runs the application and permission probes as the unprivileged result owner;
  and
- freezes Make targets, raw roots, timeouts, three-boot completion, and result
  classifications.

## Round 2: Revision 2

The reviewer returned `NO-GO`.

Blocking findings:

1. The current ABI cannot execute the planned per-file rules.
   `namei_ext_lookup()` rejects ordinary final opens using `SELECT_TARGET`,
   `namei_ext_apply_target()` requires a directory, final-open handling
   independently rejects non-directory targets, and the functional harness
   opens registrations with `O_PATH | O_DIRECTORY`. Therefore the proposed
   loader condition, logical identity probes, and permission probe cannot run.
2. The displayed source command is not the exact upstream test path and does
   not freeze its required environment. Upstream's official pull row is
   `./run_driver --dlopen --pull`; `run_driver` changes to the test directory
   and supplies `LD_LIBRARY_PATH`, `SPINDLE_TEST`, and `PATH`. The direct
   `test_driver` invocation may remain a source-derived slice only if the plan
   freezes the absolute built `spindle` executable, installation prefix,
   working directory, and complete environment rather than calling bare
   `spindle`.
3. The 27-object inventory is not the complete executed loader slice.
   `checkTlsSum()` explicitly opens `libtls1.so` through `libtls20.so`, but
   those objects are absent from the required mapping list. The command can
   therefore pass while those 20 DSOs come from the source tree instead of the
   authenticated Spindle cache.

Verified sound elements:

- the `--nompi` exit-status oracle and exclusion of exec/stat are honest;
- `--strip=no` selects the `spindlens-file` cache class;
- level-3 global-name records plus `--noclean`, tmpfs identity, and hash checks
  can authenticate each emitted mapping;
- the `libtest10.so` withdrawn control is causal once final-file selection
  exists;
- the RQ scope correctly reuses Spindle population and does not claim to
  replace its distribution or cache control plane; and
- the Make commands, raw roots, timeouts, three-boot completion rule, result
  classes, and interpretation are otherwise sufficient.

The reviewer recommended implementing final regular-file target selection
through normal VFS completion before repairing the experiment. This directly
represents Spindle's per-object mapping and preserves the one-rule withdrawn
control. Directory selection plus generated-basename `REDIRECT` is
mechanically possible, but it would redirect an entire remaining subtree and
would require bounce-back aliases for executable, startup, alias, source-only,
local-library, and TLS fixtures. That would be a materially different
experiment rather than a local repair.

Final verdict: NO-GO

Revision 3 must wait for the final-file mechanism to pass KVM validation. It
must then freeze the exact upstream/source-derived command environment and a
complete staged-object inventory before the same reviewer performs the one
remaining follow-up allowed by the experiment process.

## Round 3: Revision 3

The reviewer returned `GO`.

Findings:

1. The final-file blocker is resolved. Kernel commit
   `621aff8d1bb52fad718f11fd882c956d6a5686ae` carries final regular-file
   targets through normal VFS completion. The complete Phase 1 root
   `results/phase1/20260729T220000Z-f1e5e1e1/` records 3/3 ABI checks, 8/8
   policy lifecycle events, and 117/117 functional cases passing on that
   kernel, including real tmpfs cross-mount file selection, stat/open/read/
   access/exec, unprivileged `EACCES`, scoped-resolution rejection, target
   replacement and revocation, symlink-stack cleanup, and clean unmount.
2. The command and environment are executable and honest. Revision 3 records
   upstream's official `./run_driver --dlopen --pull` row, freezes absolute
   source/build/prefix/test/cache paths and the installed `spindle` binary,
   and uses the same generated wrapper, serial launcher, pull mode, working
   directory, arguments, UID/GID, and clean `env -i` base in every condition.
   `--nompi`, `--noclean=yes`, and `--strip=no` are explicit source-derived
   scope and observation changes rather than claims of reproducing the full
   upstream row.
3. The focal inventory is complete for the declared slice. All 47 distinct
   regular payloads are mandatory, including the 20 `libtls*.so` objects
   opened by `checkTlsSum()` and the dependency/C++/`$ORIGIN` objects. The
   symlink, local-copy, negative, startup/runtime, script, alias, and readlink
   fixtures have accurate non-focal roles and cannot satisfy a selection
   group.
4. Source engagement and causality are hard-gated independently of application
   success: level-3 first-party global-to-`spindlens-file` mappings,
   `--noclean`, tmpfs identity, distinct source/cache inodes, byte hashes, 47
   logical-to-physical identity probes, per-rule hits, interposition absence,
   the covered-source withdrawn rule, lower-inode permission denial, manifests,
   cleanup, and dmesg all have explicit pass or invalidation rules.
5. The experiment adds valid supporting RQ1 evidence without claiming cache
   population, distribution, scaling, performance, or Spindle replacement.
   Source Spindle is correctly a positive control, withdrawn is a causal
   control, and no additional baseline is required for this correctness-only
   question. The Make entrypoints, raw roots, condition and boot timeouts,
   three-boot 141-mapping/141-selection completion rule, and supported/
   contradicted/mixed/invalid interpretations are sufficient.

No remaining scientific or executability defect would invalidate the planned
result. Minor wording or additional diagnostics would be optional polish, not
grounds to block the real preflight.

Final verdict: GO

## Post-Review Build Artifact Correction

The first Make-owned upstream build after Round 3 showed that, for the frozen
commit and configuration, `testsuite/test_driver` is itself the generated ELF;
there is no `.libs/test_driver` or libtool shell wrapper. The official
`run_driver` invokes this same `testsuite/test_driver` path. The plan and build
checks were corrected to record that ELF directly.

This correction does not change the source command, application arguments,
working directory, environment, 47-object inventory, conditions, oracle,
controls, metrics, or interpretation reviewed in Round 3. It removes an
incorrect artifact label and a nonexistent path check before any Spindle KVM
result root was created.
