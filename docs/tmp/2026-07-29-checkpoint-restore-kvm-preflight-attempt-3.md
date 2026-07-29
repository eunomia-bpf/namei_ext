# Checkpoint/Restore KVM Preflight Attempt 3

## Purpose

This record captures the third clean-source modified-kernel dependency
preflight for the DMTCP-derived Checkpoint/Restore and Migration experiment.
The experiment plan allows at most three real preflight attempts once a KVM
result root exists. This run therefore closes the bounded preflight; it is not
a formal paper result.

## Run Identity

- Result root:
  `results/experiments/checkpoint-restore-preflight/20260729T001040Z/`
- Main repository commit:
  `3a2ad6edd82b4a61240afe9228b6707c0829608c`
- Kernel commit:
  `bdc9a83e3dfbef8ff2017f9188c7c86025962183`
- Kernel release:
  `7.1.0-rc7-gbdc9a83e3dfb`
- DMTCP commit:
  `068559d9b14c5f96a57869753bba7c066cbf9653`

Both repositories were clean. The modified kernel booted, the guest verified
the kernel commit and release, the `namei_ext_lookup` symbol was present, and
the copied DMTCP install tree passed its checksum manifest.

## Failure

The upstream PathTranslator control did not start. Its stderr contains:

```text
setpriv: failed to parse reuid: ''
```

The guest target recorded the result-root owner as UID/GID 1000 in
`runtime-identity.json`. That shell assignment was on an earlier Make recipe
line. GNU Make starts a separate shell for each recipe line, so the later
upstream-control line expanded the unset shell variables and invoked
`setpriv --reuid="" --regid=""`.

This failure occurred before the upstream DMTCP test and before the focused
`pathvirt`, `namei_ext`, and `withdrawn` conditions. It therefore provides no
correctness or performance evidence about those mechanisms.

## Repair

The upstream-control recipe now computes the owner directly inside the same
`setpriv` command:

```text
setpriv --reuid="$(stat -c %u <boot-dir>)" \
        --regid="$(stat -c %g <boot-dir>)" --clear-groups ...
```

The recorded `runtime-identity.json` remains independent evidence. A source
contract test requires both inline lookups and rejects reuse of the
cross-recipe shell variables.

No DMTCP strict-checking option, timeout, condition, oracle, or baseline was
changed.

## Decision

The result root remains failed and immutable. It is not analyzed or promoted.
Because this is the third counted attempt, the current dependency-preflight
budget is exhausted and no fourth run is authorized under the existing plan.
Checkpoint/Restore remains a candidate case study without KVM sufficiency
evidence. Work proceeds breadth-first to another predeclared experiment rather
than weakening or silently extending this protocol.
