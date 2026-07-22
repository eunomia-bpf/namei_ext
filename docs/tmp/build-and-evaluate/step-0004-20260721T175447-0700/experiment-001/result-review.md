# Result Review: RQ1 Agent Workspace Expressiveness

## Review Scope And Decision

- **Exact RQ:** Can a narrow VFS name-resolution extension express real
  state-dependent path-view policies without taking over filesystem semantics?
- **Run status:** **completed**. All three formal terminal KVM runs completed
  and conjunctively satisfy the experiment plan.
- **Tested hypothesis result:** **supported**, scoped to the fixed
  AgentFS-derived path-view slice exercised here.
- **Research value:** **headline** evidence for the Agent workspace family.
- **Paper decision:** Fill the Agent workspace row of the RQ1 table as a
  three-of-three pass, including the tested lifecycle and direct lower-FS
  preservation evidence. Do not close RQ1 for the whole paper yet: the frozen
  traditional build/cache workload family remains open.

No timing value from these runs is interpreted in this review. The collected
timings are reserved for a separately planned RQ2 analysis.

## Raw Roots Audited

| Run ID | JSONL rows | Failed `pass` rows | Cases | Final manifests | Policy/FUSE counters | Terminal marker | Verdict |
|---|---:|---:|---:|---:|---:|---:|---|
| `20260722T020120Z-rq1run1` | 1,176 | 0 | 94/94 pass | 2/2 pass | 7/7, 11/11 pass | 1 | complete |
| `20260722T020210Z-rq1run2` | 1,176 | 0 | 94/94 pass | 2/2 pass | 7/7, 11/11 pass | 1 | complete |
| `20260722T020245Z-rq1run3` | 1,176 | 0 | 94/94 pass | 2/2 pass | 7/7, 11/11 pass | 1 | complete |

Each root contains the recorded Make command, twelve input SHA-256 records,
kernel configuration, kernel command line, `uname`, `/proc/version`, JSONL,
stdout, stderr, and dmesg. All twelve recorded digests verify against the
current executed inputs in every root. The three roots use the same kernel,
policy, runners, Make recipe, and fixed trace hashes but distinct run IDs and
KVM boots. The kernel identifies itself as
`7.1.0-rc7-g6641100ef134`; the captured configuration enables
`CONFIG_NAMEI_EXT`, cgroup BPF, FUSE, and BTF.

## Correctness And Mechanism Audit

### Source-trace binding and oracle

- Both runners received the same
  `tests/agent_workspace/agentfs_lifecycle_trace.txt`. Its recorded SHA-256 is
  `bc383bb71e413424b8dcf7538c04a0b061798cab07d03afb2c1e939a4b0e45f4`
  in all three roots.
- Both source-artifact and source-replay gates pass in every run. The fixed
  trace names the AgentFS-derived bash/git epoch switch, edited `src`, `.git`
  state, whiteout, symlink, create, cached-negative create, rename/restore,
  unlink, and final-tree oracle.
- The later direct observations independently exercise those declared rows;
  the positive verdict does not rest on the `source_trace_replayed` label
  alone.

### `namei_ext` mechanism engagement

- `logical_before_attach=ENOENT`, `attach_policy=pass`, base-target selection,
  upper-target selection, `detach_policy=pass`, and
  `logical_after_detach=ENOENT` establish that the logical view depends on the
  attached policy rather than fixture pre-materialization.
- The executed policy is a `SEC("cgroup/namei_ext")` program. It selects target
  ID 1 for `ws`, hides `deleted.txt` for lookup and readdir, and otherwise
  passes. The runner attaches it with `BPF_CGROUP_NAMEI_EXT` and registers base
  and upper directories through the kernel target registry.
- All seven policy counters are nonzero and pass in every run. Each run records
  3,484 total invocations: 2,581 lookup, 903 readdir, 419 target selections,
  three hidden lookups, 53 hidden readdir entries, and 3,009 pass actions.
  This is direct evidence that both lookup selection and readdir hiding paths
  executed.
- Clearing registered targets, reattaching the same policy, and observing
  `invalid_unregistered_target_contained=ENOENT` pass in all runs. The tested
  missing-target case therefore fails closed instead of resolving an
  unregistered object.

### State-dependent path-view correctness

All three runs pass the same direct checks for:

- base versus agent epoch selection for `main.txt`, `src/app.txt`, and
  `.git/HEAD`;
- lookup/readdir agreement for the hidden `deleted.txt` whiteout;
- preserved symlink target and successful executable resolution;
- cached-negative creation becoming visible;
- create, rename, rename restore, and unlink lifecycle transitions;
- final logical-tree state and stale-name absence.

The two final manifests pass in every root. The deterministic correctness
claim therefore meets the plan's three-of-three conjunctive rule.

### Lower-filesystem ownership and preservation

The evidence supports the narrow ownership claim in this experiment:

- a logical create is observed in the selected upper lower-directory;
- the corresponding base-tree path remains `ENOENT`;
- cached-negative create, rename, and unlink are observed directly in the
  selected lower tree;
- the final manifest preserves the upper content while confirming that the
  generated file was not materialized in the base tree; and
- the BPF policy implements only lookup/readdir selection or hiding, not file
  creation, data I/O, rename, unlink, or filesystem methods.

Together, these observations support that the tested name-selection policy
changes the view while the VFS and selected lower filesystem retain object and
data-path semantics for the exercised operations.

### Same-oracle FUSE control

The independent FUSE realization receives and validates the same trace,
passes the same base/agent, whiteout, symlink, create, cached-negative,
rename/unlink, executable, readdir, and final-tree checks, and unmounts cleanly
in every run. Its eleven operation counters are all nonzero, including
`getattr`, `readdir`, `open`, `create`, `read`, `write`, `readlink`, `unlink`,
and `rename`. This establishes that the oracle is realizable through a broader
filesystem boundary as well as `namei_ext`; it is a correctness control here,
not an RQ2 performance result.

## Logs And Provenance Caveats

- Stdout and stderr are empty in all three roots because the runners append
  their records directly to JSONL. No JSONL row has `pass=false`.
- The Make dmesg rejection signatures (`BUG`, `WARNING`, `Oops`, `Call Trace`,
  hung task, general protection fault, null pointer, KASAN, or UBSAN) are absent
  in all three roots. The virtme-ng boot log contains benign permission-denied
  messages in all runs. Run 2 additionally reports a clocksource watchdog
  remote-CPU read timeout. It did not produce an oops/warning marker or prevent
  any correctness gate or terminal marker; because timing is excluded from
  RQ1, it does not overturn the correctness verdict, but it should be retained
  as a virtualization-timing caveat.
- The raw provenance captures hashes for every executed policy, runner, trace,
  kernel image/config, Make input, and the prior complete experiment plan, plus
  the kernel commit in `uname`. It does not directly record the parent
  repository HEAD or dirty-worktree state. Exact executed-input hashes make
  this result auditable, but future targets should also record `git rev-parse
  HEAD` and `git status --porcelain` (or an equivalent patch identity).
- Runtime source validation checks four identifying trace tokens, while the
  Make provenance records the exact full-file digest. Thus exact artifact
  identity is supplied by provenance rather than by a complete runtime parser
  of every trace line.
- The FUSE control is a separately executed implementation but shares a
  deliberately duplicated fixed oracle with the `namei_ext` runner. It rules
  out an oracle that only the proposed mechanism can realize; it is not an
  externally developed conformance suite.

## Scope And Paper Impact

The result supports the following scoped statement: on three fresh KVM boots,
the real `cgroup/namei_ext` path expressed the fixed AgentFS-derived base/agent
workspace view, including lookup/readdir coherence and the exercised mutable
lifecycle, while direct observations placed writes and mutations in the
selected lower filesystem.

It does **not** establish full AgentFS SQLite state, audit history, complete
COW/checkpoint semantics, arbitrary policy composition, or all filesystem
operations. It also does not answer the traditional build/cache workload row.
Accordingly, this experiment closes the Agent workspace experiment cell as
positive headline evidence, but **traditional build/cache remains open and RQ1
must remain open at paper level until that independent workload family is
tested**.
