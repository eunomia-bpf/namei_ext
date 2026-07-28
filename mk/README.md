# Make Infrastructure

Make is the project-owned control plane. Shared files own infrastructure;
suite files own workload semantics.

## Ownership

- `kernel.mk`: patched and matched-stock kernel construction and provenance.
- `docker.mk`: runtime image construction.
- `kvm.mk`: KVM execution and common guest preparation.
- `results.mk`: `namei_ext.run.v2` lifecycle, source-state gates, and minimum
  artifact gates.
- `workload.mk`: pinned third-party workload acquisition and build.
- `experiments/*.mk`: source-derived industrial case studies.
- `benchmarks/*.mk`: standard performance matrices and their analysis entrypoints.

Legacy suites may remain isolated for reproducibility, but new experiments
must not call their runners or extend their result formats. The top-level
`CURRENT_EXPERIMENT_TARGETS` list is the authoritative implemented-suite
aggregate; legacy suites must have explicitly named reproduction targets and
must not be dependencies of `make experiments`. A target should be named and
documented as a preflight until it implements the complete planned matrix.

## Suite Contract

A new formal suite must:

1. expose a public `make` target and keep all orchestration in its owning
   Makefile;
2. put downloads in `.cache/`, builds in `.build/`, and raw runs in
   `results/`;
3. create a new result root, start its lifecycle on the host, and refuse an
   existing `RUN_ID`;
4. use `NAMEI_EXT_KVM_RUN_CAPTURE` so launcher failures and logs are preserved;
5. validate the run while it is `running`, then use
   `NAMEI_EXT_RUN_COMPLETE`;
6. separate `inputs.sha256` from `artifacts.sha256`;
7. fail correctness and mechanism-engagement gates before reporting
   performance; and
8. leave statistical aggregation and figures to `analysis/`.

The top-level current experiment targets also depend on
`experiment-source-clean`. Runs therefore start only from clean main and kernel
trees. The result root still preserves both commits and both status files so
the clean state is part of the raw contract rather than an external assumption.

Patched and matched-stock kernel construction shares one cross-process lock.
The patched build tree is bound to the current kernel commit: changing that
commit invalidates the complete build tree before configuration or compilation.
The source and built commit stamps are independent provenance gates; neither
may be synthesized after a build from another commit. Kernel construction,
cleanup, and provenance must continue to go through `mk/kernel.mk`.

Single-guest suites use `NAMEI_EXT_RUN_VALIDATE_CANONICAL`. Multi-boot matrices
use `NAMEI_EXT_RUN_VALIDATE_BASE` and additionally require one immutable boot
directory with kernel identity, configuration, raw observations, and dmesg for
every planned condition and repetition. They must compare the observed boot
and cell key sets exactly with the declared matrix and establish the kernel
identity from inside each guest.

`NAMEI_EXT_KVM_RUN_CAPTURE` accepts an optional outer timeout after the host
CPU pin argument. Suites with live daemons or other blocking external
processes should freeze this value in their benchmark configuration so a stuck
guest or VM fails the run instead of blocking the matrix indefinitely.
