# Sandlock Workload Evidence Summary

Date: 2026-07-02

## Motivation

Sandlock is a strong source-backed sandbox/workspace workload seed. Its
workloads cover `sandlock run`, readable and writable path classes, COW workdir
commit, dry-run/change discard, protected path denial, chroot/fs-mount mapping,
checkpoint/fork/reduce, dynamic policy callbacks, profile execution, and
Python/Go SDK entry points.

This record does not rerun the full Sandlock suite. It makes the previously
preserved raw reproduction evidence machine-readable and split from the older
combined BranchFS/Sandlock note. The result is intentionally partial: useful
workspace/path-class oracles pass, while host-sensitive resource, named-UNIX,
and packaging sub-oracles remain negative.

## Source

- Repository: `https://github.com/multikernel/sandlock`
- Local checkout: `.cache/source-inspection/sandlock`
- Commit: `e7f2993a2b10eeee8441ea64ac0bbe48589db90f`

## Raw Artifacts

Result root:
`results/reproduction/2026-07-01-official-workloads/sandlock/`

Files:

- `sandlock-cargo-build-release.log`
- `sandlock-cargo-test-release.log`
- `sandlock-cli-tests-release.log`
- `sandlock-core-integration-release-tee-serial.log`
- `sandlock-core-named-unix-short-target.log`
- `sandlock-python-venv-install.log`
- `sandlock-python-pytest.log`
- `sandlock-go-test.log`
- `sandlock-go-test-sandlock-repo.log`
- `sandlock-cli-cow-protected-path-smoke.log`
- `summary.json`

## Positive Evidence

- `cargo build --release` passed.
- CLI tests passed:
  - 5 CLI unit tests;
  - 22 CLI integration tests;
  - 6 profile integration tests.
- Serial core integration rerun recorded 271 passed and 9 failed.
- Python tests recorded 354 passed and 2 failed.
- Go SDK in repository mode passed with `go test -tags sandlock_repo ./...`.
- Manual COW/protected-path smoke passed:
  - COW workdir commit updated `file.txt`;
  - COW workdir commit created `created.txt`;
  - reading `/etc/group` without `/etc` readability failed with permission
    denied and exit status 1;
  - smoke wrapper exit status was 0.

## Preserved Negative Evidence

- Full `cargo test --release` ended negative: 270 passed and 10 failed in the
  core integration portion.
- Short-target named-UNIX subset recorded 4 passed and 5 failed; the remaining
  deny-path tests succeeded where `EACCES` was expected.
- Python resource/control failures:
  - `test_restrict_max_memory`: the unrestricted 256 MiB control did not
    complete the 128 MiB allocation on this host;
  - `test_throttle_result_correct`: CPU-throttle run returned failure.
- Default Go SDK mode failed because `pkg-config` could not find `sandlock.pc`.

## Reusable Workload Shape

Reusable for `namei_ext` workload design:

- sandbox run lifecycle;
- readable/writable path classes;
- COW workdir commit;
- dry-run/change discard;
- protected path denial;
- chroot and fs-mount path mapping;
- selected checkpoint/fork/reduce traces;
- dynamic policy callback and profile shapes;
- SDK-level workspace API behavior.

Do not claim full Sandlock conformance on this host. The safe reuse subset is
the path-class, COW, protected-path, and workspace-lifecycle behavior, not
Sandlock's full syscall, network, resource-control, or package-installation
surface.

## Implication

Sandlock remains a primary sandbox/workspace source with caveats. Together with
BranchFS, AgentFS, Redis AFS, Mirage, OpenHands SDK, SWE-agent, and SWE-ReX, it
supports a source-backed AI agent workspace lifecycle workload family for
`namei_ext`. It should be cited as a workload and source-system baseline seed,
not as a system that `namei_ext` replaces.
