# W5 Attempt 4 Result And Attempt 5 Plan

## Purpose

W5 Checkpoint/Restore and Migration is one of the seven mandatory RQ1 case
studies. This record classifies the fourth KVM preflight, identifies the part
of the execution path that stopped it, and fixes the next execution without
changing the W5 hypothesis or source-derived oracle.

## Attempt 4 Result

The immutable result root is:

```text
results/experiments/checkpoint-restore-preflight/
  20260802T095000Z-w5-attempt04/
```

It used source commit `cd8aa2deb0f406422a3f92ff2494d4632bc1fddc`,
kernel commit `b07117a3cb41826a34af5ca61e3e2c81dade793f`, and DMTCP
commit `068559d9b14c5f96a57869753bba7c066cbf9653`. The modified
kernel booted, the required kernel symbol was present, and the exact
`setpriv` identity probe returned UID 1000 and GID 1000.

The run then entered DMTCP's separate official `pathvirt` autotest. Its
checkpoint and restart phases passed, including creation of the expected
success artifact. Cleanup failed because the autotest still found PID 980 in
the original worker's process group 969 after its SIGKILL wait. The artifact
records the PID but not its process state, command, or parent, so this result
cannot establish whether it was a live helper, a zombie awaiting reaping, or
another transient DMTCP process.

The run stopped before the initial BPF inventory and before all three focal
conditions: the same-application DMTCP PathTranslator lifecycle, the
`namei_ext` lifecycle, and the withdrawn-mapping control. Attempt 4 is
therefore inconclusive. It is neither positive W5 evidence nor a contradiction
of the RQ1 hypothesis.

## PathTranslator Activation Finding

The pinned DMTCP source compiles `src/plugin_pathtranslator.cpp` into
`libdmtcp.so`. `PluginManager` registers the internal `PATHVIRT` plugin and
reads its state from `DMTCP_PATHVIRT_PLUGIN`. However, `dmtcp_launch
--pathvirt` also tries to preload the obsolete standalone
`libdmtcp_pathvirt.so`, which this build neither creates nor installs. That
explains the loader warning in both the passing host lifecycle and attempt 4;
it does not explain the observed A-to-B translation, which is performed by the
internal plugin.

The next runner will activate the internal plugin directly with
`DMTCP_PATHVIRT_PLUGIN=1` and will omit `--pathvirt`. The two `namei_ext`
conditions will set `DMTCP_PATHVIRT_PLUGIN=0` and omit
`DMTCP_PATH_MAPPING`. This makes the mechanism attribution explicit and
removes the obsolete preload attempt.

## Why The KVM Gate Changes

The official DMTCP autotest already passed from the pinned, relocated install
on the host in:

```text
results/workloads/checkpoint-restore-source/
  20260802T094525Z-df8ae7d4/
```

It is a source-positive control, not the W5 paper experiment. Repeating that
different application and its cleanup harness inside every KVM boot adds no
evidence beyond the focal PathTranslator condition, which runs the exact same
checkpointed application and A-to-B oracle used by `namei_ext`.

Attempt 5 therefore removes only the repeated in-guest autotest. Each KVM boot
starts with a clean external BPF inventory and then executes:

1. DMTCP PathTranslator with the internal plugin explicitly enabled;
2. `namei_ext` with PathTranslator explicitly disabled; and
3. the withdrawn `namei_ext` mapping control with PathTranslator disabled.

All three conditions retain the same logical pathname, generation-A before
checkpoint, generation-B after restart, stale-to-new directory transition,
direct lower-object identity and metadata checks, checkpoint-image check,
runtime-identity check, BPF attribution, cleanup checks, and dmesg scan.

## Execution And Interpretation

Attempt 5 remains in the original W5 lineage. It is a material repair of the
executed path, not a renamed experiment and not a reset of prior failures.
The one-boot preflight must complete all three focal conditions. A passing
preflight receives an independent result review before the unchanged
three-fresh-boot formal run.

- Positive preflight: all three conditions and all mechanism/correctness
  checks pass in the modified-kernel boot.
- Contradiction: PathTranslator completes the same application oracle but
  `namei_ext` reaches and fails the A-to-B oracle.
- Inconclusive: a dependency fails before comparable focal conditions finish.

Only the three-boot formal result can complete W5. No lifecycle duration is a
performance claim.

## Plan Review

An independent read-only reviewer returned `GO`. It confirmed that the host
autotest remains the source-positive control, the three KVM conditions retain
the same application and oracle, and the pinned source implements the
environment-controlled internal `PATHVIRT` plugin. It found no scientific
fairness or executability blocker in replacing `--pathvirt` with explicit
`DMTCP_PATHVIRT_PLUGIN` state.

## Host Validation Of The Revised Activation

The revised relocated source workflow passed at:

```text
results/workloads/checkpoint-restore-source/
  20260802T111500Z-w5-attempt5-source/
```

The official autotest again reported one passing group and no failure. The
same-application lifecycle then used the internal plugin without `--pathvirt`:
generation A was observed before checkpoint, generation B after restart, the
remembered pathname was unchanged, the stale/new directory transition passed,
and all lower objects were unchanged. `dmtcp-launch.stderr.log` is empty, so
the obsolete standalone-plugin preload warning is absent from the revised
path. This is host dependency evidence, not a W5 KVM result.
