# Plan Review: RQ1 Agent Workspace Source Task

## Initial Review

Verdict: NO-GO pending four validity repairs. The reviewer accepted the
paper-value admission, source-task choice, non-duplication argument, and the
decision not to add an RQ1 baseline.

The blocking findings were:

1. A generic nonzero base exit could accept a dependency, collection, or
   unrelated test failure instead of the released fail-to-pass oracle.
2. Checking only `click.__file__` would not establish that the selected
   `src/click/types.py` containing the gold change was imported, and the plan
   did not force cwd and test lookup through the logical workspace.
3. Two completed children did not by itself establish overlapping execution or
   entry into the cgroup before logical lookup.
4. Switch and rollback could reuse an old cwd, file descriptor, or imported
   module instead of resolving the updated mapping.

## Repair Round 1

The plan now requires:

- two independent Click trees from the fixed base commit, with the released
  test patch in both and the gold source patch only in the completed tree;
- exactly 40 collected tests per run; base must report exactly 39 passed and
  only `test_choice_get_invalid_choice_message` failed, while completed must
  report exactly 40 passed;
- logical cwd, test path, `click.__file__`, `click.types.__file__`, and
  device/inode checks for both the changed source file and test file;
- cgroup entry before lookup, a two-child pre-exec barrier, monotonic interval
  records, required interval overlap, and separate pytest temp directories;
- a fresh child from outside the logical tree after every acknowledged update,
  with no inherited workspace cwd, file descriptor, or Python import state;
- the exact base, completed, rollback, and withdrawal sequence;
- six pytest invocations per boot, disabled bytecode and pytest cache output,
  and no claim of complete repository traversal.

Follow-up reviewer verdict is pending. No implementation or real preflight is
authorized by this record alone.

## Follow-up Round 1

Verdict: NO-GO with one remaining leakage defect. The exact fail-to-pass
oracle, concurrency protocol, and fresh switch/rollback resolution rules were
accepted. The remaining problem was that a relative
`PYTHONPATH=view/ws/src`, evaluated after `chdir(view/ws)`, could resolve to a
duplicated path and fall back to an installed Click package.

The plan now defines the absolute logical workspace path `L` before launch,
uses `PYTHONPATH=L/src` after `chdir(L)`, records the effective `sys.path`
entry, and requires exact equality with `L/src`.

## Final Follow-up

Verdict: GO. The reviewer accepted the absolute `L/src` rule, effective
`sys.path` check, module-path checks, and logical/lower inode checks as closing
the final leakage defect. The repaired experiment is scientifically valid and
executable for implementation and real preflight.
