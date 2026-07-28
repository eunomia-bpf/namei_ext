# Unified Multi-Boot Contract Review

## Scope

An independent read-only reviewer inspected `mk/multi_boot.mk`, the Agent
workspace RQ2 migration, infrastructure fixtures, Make expansion, input
hashing, documentation, and the preserved formal-result reanalysis.

## Round 1

Verdict: no-go.

The first implementation recursively counted `boot.json` and
`observations.jsonl` but validated only `boots/*`. One direct boot plus nested
evidence could therefore satisfy the count while avoiding per-boot schema,
affinity, checksum, and log checks.

Repair:

- require exactly the declared number of direct boot directories;
- reject non-directory entries directly under `boots/`;
- collect observations only from direct boot directories; and
- iterate all direct directories, including hidden names, for suite checks.

Negative fixtures moved one required boot file and one observation file below
the direct boot boundary.

## Round 2

Verdict: no-go.

Two complete direct boots plus additional nested `boot.json` or
`observations.jsonl` still passed because the extra evidence was silently
excluded.

Repair:

- reserve both evidence filenames for direct boot directories;
- reject either filename below direct-boot depth; and
- add a fixture with a complete valid direct matrix plus extra nested evidence.

## Round 3

Verdict: go, conditional only on the separately required clean-tree KVM
preflight.

The reviewer found no remaining Make expansion, shell quoting, tree-shape,
input-hash, Agent protocol, ordering, fail-fast, or local-test blocker.

## Remaining Gate

Host fixtures and historical-result reanalysis do not replace modified-kernel
validation. The candidate commit must pass
`make kvm-agent-workspace-rq2-preflight` before this infrastructure migration
is accepted for further suites.
