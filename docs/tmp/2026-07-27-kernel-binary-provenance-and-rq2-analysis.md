# Kernel Binary Provenance And RQ2 Analysis Repair

## Motivation

The 450-cell RQ2 run
`20260727T-rq2-rcu-target-full-v2` recorded clean kernel source commit
`bdc9a83e3`, but every patched guest booted
`7.1.0-rc7-g83d52c2168e2-dirty`. The image had been built before the RCU target
change was committed. Committing the source did not change source-file
timestamps, so the outer Make dependency considered `bzImage` current and
reused it.

The result's image, BTF, notes, and build-ID hashes accurately identify the
tested binary, but they do not establish that the binary came from the
recorded clean source. The run is therefore numerically useful but invalid as
publication evidence.

Independent review also found two evidence-pipeline gaps:

- every boot contained a pre-measurement clocksource remote-watchdog timeout
  that the declared dmesg pattern did not reject; and
- the generated report showed only the two predeclared admission gates and
  omitted the active `PASS` and complete `SELECT` costs.

A second independent review found three additional publication blockers:

- a long matrix reread mutable global build outputs before every boot, so an
  overlapping build could mix kernel identities inside one completed run;
- stock provenance recorded the configured commit without binding it to the
  extracted source and built binary; and
- the analyzer trusted each observation's self-reported duration and expected
  tree size instead of the committed `run.json` matrix and an independent
  cardinality oracle.

## Build Provenance Design

`mk/kernel.mk` now treats the current kernel commit as a build input even when
no tracked source file changed:

1. every requested patched image reads and validates the 40-character kernel
   HEAD;
2. it writes that commit to `.build/kernel/.source-commit`;
3. if the generated UTS release does not contain the current 12-character
   commit, it removes only the stale Kbuild release and version objects;
4. ordinary Kbuild regenerates and relinks the image;
5. the recipe rejects a release containing `-dirty` or lacking the current
   commit;
6. it confirms that `vmlinux` embeds the validated release and writes
   `.built-commit`; and
7. `kernel-provenance` requires source, built, and live git commits to match.

The patched image recipe is intentionally forced on each owning host Make
invocation. Kbuild remains incremental, but the commit-to-binary check can no
longer be bypassed by unchanged source timestamps.

The stock source stamp now includes the configured 40-character commit. A
commit change selects a new missing target, removes the old extracted source
and build tree, and rebuilds from `git archive`. The recorded SHA-256 is
derived from the commit's canonical `git ls-tree` manifest, not from the
mutable extracted directory. Before build and again during provenance, a
temporary independent Git index compares every tracked file, mode, and symlink
in the extracted tree with that commit and rejects unexpected files. The stock
image records its own `.built-commit`; `kernel-stock-provenance` requires the
requested, source, built, and source-tree identities to match and validates
the generated release against `vmlinux`.

## Run-Local Artifact Identity

Before the first boot, each FxMark run copies both kernel images,
configurations, BTF and notes sections, the FxMark binaries, FUSE binary, and
BPF policy objects into a read-only run-local artifact directory. A structured
manifest records the commit, release, build ID, and notes/BTF hashes for each
kernel. Every boot consumes only these snapshots.

`artifacts.sha256` covers every snapshot and the manifest. Finalization
rechecks it, requires one invariant identity tuple per kernel flavor across
all boots, and rejects any source input change during the run. This prevents
an overlapping build from silently mixing binaries in a long matrix.

## Guest Identity

Both FxMark entrypoints derive the expected release from the validated
generated UTS header. The release is included in every expected boot tuple and
passed to the guest. Before any measured cell, the guest requires `uname -r`
to equal that expected value. Global finalization compares expected and
observed tuples including the release.

Build ID, notes SHA-256, BTF SHA-256, kernel flavor, and configuration checks
remain in place. The new release check complements rather than replaces them.

The run also records the linked libfuse version and `ldd` output. Host
frequency-state collection now writes an explicit
`cpufreq-sysfs-unavailable` record when the host exposes no cpufreq governors,
instead of accepting an unexplained empty file.

## Clocksource Gate

The guest command line now includes `tsc=reliable`, which is explicit in every
captured kernel command line. The dmesg failure pattern rejects remote or
other clocksource-watchdog read timeouts and unstable-clocksource messages.
Every boot records `current_clocksource` before and after measurement and
requires both values to remain `tsc`.

This configuration removed the timeout in the modified-kernel KVM functional
run `results/phase1/20260727T-provenance-tsc-functional-v2/`. All 74
functional cases passed, the guest booted
`7.1.0-rc7-gbdc9a83e3dfb`, and the expanded dmesg gate found no failure.

## Analysis Repair

`analysis/fxmark/analyze.py` now reads the completed matrix from `run.json`
and independently rejects:

- failed FxMark or FUSE process status;
- a row duration different from the plan, a measurement outside the declared
  90--120% interval, or an invalid work count;
- tree cardinality different from the independent FxMark workload oracle,
  even when a row's self-reported actual and expected values agree;
- inconsistent `works / seconds` throughput;
- missing, unstable, or unexpected BPF attachment;
- a selected path that does not require `SELECT`; and
- missing FUSE setup engagement, invalid measured request counts, or a
  pre/post mount type different from `FUSE_SUPER_MAGIC`.

The report retains the predeclared unattached/stock and `SELECT`/FUSE gates,
but labels their verdict scope explicitly. A second table reports
`PASS`/stock, `SELECT`/stock, FUSE/stock, and `SELECT`/`PASS`, each with the
same paired nonparametric bootstrap interval. JSON and CSV outputs also retain
`PASS`/unattached and `SELECT`/unattached.

`analysis/fxmark/test_analyze.py` supplies a complete synthetic one-repetition
matrix, run-plan tests, and negative contracts. The infrastructure test target
runs all 19 tests. Formal analysis also rejects BPF run-time statistics
accounting because the declared cost protocol disables it. The prior raw
matrix cannot satisfy the new FUSE mount-type
contract and remains diagnostic because of the binary-provenance issue.

## Validation

- `make kernel-provenance` detected the stale release, regenerated the UTS and
  version objects, rebuilt the image, and validated
  `7.1.0-rc7-gbdc9a83e3dfb`.
- `make fxmark-kernel-pair` rebuilt stock from commit-specific extracted source
  and validated both source/built commit chains.
- A direct artifact-capture test copied and hashed all 14 run-local artifacts;
  every hash and both manifest commits validated.
- A missing built-commit override was rejected; matching source and built
  commit fixtures passed.
- `make result-contract RUN_ID=20260727T-provenance-contract-final-v2`
  passed all 19 analyzer contracts and the existing source-state and
  result-lifecycle failure tests.
- A deliberate file addition under the extracted stock source was rejected
  even after deleting the saved source-tree hash; the reference hash was
  regenerated from the commit, while the independent-index comparison still
  rejected the polluted directory. Removing the file restored a passing
  provenance check.
- `make kvm-functional
  RUN_ID=20260727T-provenance-tsc-functional-v2` passed 74/74 functional cases
  without the previous guest git-ownership warning or any expanded dmesg
  signature.
- A full Make dry run expanded both updated FxMark host and guest commands
  successfully.

## Remaining Work

The infrastructure and documentation changes must be committed so the formal
clean-source gate can admit a fresh six-condition preflight. That preflight
must show the clean patched release in every patched boot, stock release in
the stock/FUSE boots, nonempty libfuse and host-frequency records, and no
clocksource-watchdog event.

Only after that gate passes may the unchanged 450-cell matrix be rerun. The
prior numerical result is an expected range, not a paper claim.
