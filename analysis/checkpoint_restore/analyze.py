#!/usr/bin/env python3

import argparse
import csv
import json
from pathlib import Path


CONDITIONS = ("pathvirt", "namei_ext", "withdrawn")
COMMON_CASES = {
    "setup_fixture",
    "capture_lower_before",
    "start_coordinator",
    "pre_checkpoint_oracle",
    "checkpoint",
    "update_mapping",
    "restart_oracle",
    "lower_objects_unchanged",
    "cleanup_runtime_tmp",
}
POLICY_CASES = {"configure_policy", "policy_restart_attribution"}
ALLOWED_EVENTS = {
    "checkpoint-restore-case",
    "checkpoint-restore-policy",
    "checkpoint-restore-policy-counter",
    "checkpoint-restore-lifecycle",
    "checkpoint-restore-summary",
}


def load_json(path):
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot read JSON {path}: {error}") from error
    if not isinstance(value, dict):
        raise ValueError(f"expected JSON object in {path}")
    return value


def load_jsonl(path):
    rows = []
    try:
        source = path.open(encoding="utf-8")
    except OSError as error:
        raise ValueError(f"cannot open {path}: {error}") from error
    with source:
        for line_number, line in enumerate(source, 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(
                    f"invalid JSON at {path}:{line_number}: {error}"
                ) from error
            if not isinstance(row, dict):
                raise ValueError(f"non-object JSON at {path}:{line_number}")
            rows.append(row)
    if not rows:
        raise ValueError(f"empty JSONL file: {path}")
    return rows


def one(rows, event, condition=None, **fields):
    matches = []
    for row in rows:
        if row.get("event") != event:
            continue
        if condition is not None and row.get("condition") != condition:
            continue
        if all(row.get(field) == value for field, value in fields.items()):
            matches.append(row)
    if len(matches) != 1:
        detail = ", ".join(f"{key}={value}" for key, value in fields.items())
        raise ValueError(
            f"expected one {event} for {condition or '*'} {detail}, "
            f"got {len(matches)}"
        )
    return matches[0]


def valid_hex(value, length):
    return (
        isinstance(value, str)
        and len(value) == length
        and all(character in "0123456789abcdef" for character in value)
    )


def validate_run(run):
    expected = {
        "schema": "namei_ext.run.v2",
        "protocol_schema": "namei_ext.checkpoint_restore.protocol.v3",
        "suite": "checkpoint-restore",
        "source_system": "dmtcp-pathtranslator",
        "observations": "observations.jsonl",
        "policy": "checkpoint_restore_migration.bpf.c",
        "runner": "namei_ext_checkpoint_restore+dmtcp",
        "status": "completed",
    }
    for field, value in expected.items():
        if run.get(field) != value:
            raise ValueError(f"unexpected run {field}")
    for field in ("source", "kernel"):
        identity = run.get(field)
        if not isinstance(identity, dict) or identity.get("dirty") is not False:
            raise ValueError(f"{field} tree is not clean")
        commit = identity.get("commit")
        if not valid_hex(commit, 40):
            raise ValueError(f"invalid {field} commit")
    if run.get("kernel_commit") != run["kernel"]["commit"]:
        raise ValueError("kernel commit mismatch")
    levels = {
        "kvm_checkpoint_restore_preflight": (
            "single-modified-kernel-boot", 1
        ),
        "kvm_checkpoint_restore_rq1": (
            "three-modified-kernel-boots", 3
        ),
    }
    if run.get("result_level") not in levels:
        raise ValueError("unexpected result level")
    expected_layout, expected_repetitions = levels[run["result_level"]]
    if run.get("layout") != expected_layout:
        raise ValueError("unexpected run layout")
    if run.get("attempt") != 6:
        raise ValueError("unexpected W5 attempt lineage")
    matrix = run.get("matrix")
    if not isinstance(matrix, dict):
        raise ValueError("missing run matrix")
    if matrix.get("conditions") != list(CONDITIONS):
        raise ValueError("unexpected condition sequence")
    if matrix.get("repetitions") != expected_repetitions:
        raise ValueError("unexpected repetition count")
    if matrix.get("control") != "withdrawn":
        raise ValueError("unexpected causal control")
    if matrix.get("timeout_seconds") != 120:
        raise ValueError("unexpected condition timeout")
    if matrix.get("pathtranslator_activation") != \
            "DMTCP_PATHVIRT_PLUGIN=1; DMTCP_PATH_MAPPING generation A to B":
        raise ValueError("unexpected PathTranslator activation")
    if matrix.get("dmtcp_tmpdir") != "guest-local /tmp":
        raise ValueError("unexpected DMTCP runtime filesystem")
    if matrix.get("kvm_timeout") != "600s":
        raise ValueError("unexpected KVM timeout")
    if matrix.get("all_conditions_must_pass") is not True:
        raise ValueError("missing all-condition correctness gate")
    baseline = matrix.get("baseline", "")
    if "DMTCP PathTranslator" not in baseline or \
            "scan-bound fix" not in baseline:
        raise ValueError("patched baseline is not labeled precisely")
    return expected_repetitions


def validate_controller_rows(rows):
    if any(row.get("event") not in ALLOWED_EVENTS for row in rows):
        raise ValueError("unexpected controller event")
    if any(row.get("pass") is not True for row in rows):
        raise ValueError("failed or malformed controller observation")

    lifecycles = {}
    for condition in CONDITIONS:
        condition_rows = [
            row for row in rows if row.get("condition") == condition
        ]
        if not condition_rows:
            raise ValueError(f"missing controller rows for {condition}")
        cases = {
            row.get("case")
            for row in condition_rows
            if row.get("event") == "checkpoint-restore-case"
        }
        expected_cases = set(COMMON_CASES)
        if condition != "pathvirt":
            expected_cases |= POLICY_CASES
        if cases != expected_cases:
            raise ValueError(f"unexpected case set for {condition}")
        summary = one(
            condition_rows, "checkpoint-restore-summary", condition
        )
        if summary.get("failures") != 0:
            raise ValueError(f"nonzero failures for {condition}")
        lifecycle = one(
            condition_rows, "checkpoint-restore-lifecycle", condition
        )
        for field in (
            "checkpoint_ns",
            "update_ns",
            "restart_ns",
            "total_ns",
        ):
            if type(lifecycle.get(field)) is not int or \
                    lifecycle[field] <= 0:
                raise ValueError(
                    f"invalid {field} for {condition}"
                )
        lifecycles[condition] = lifecycle

        policies = [
            row for row in condition_rows
            if row.get("event") == "checkpoint-restore-policy"
        ]
        counters = [
            row for row in condition_rows
            if row.get("event") == "checkpoint-restore-policy-counter"
        ]
        if condition == "pathvirt":
            if policies or counters:
                raise ValueError("pathvirt unexpectedly used BPF policy")
            continue
        if len(policies) != 1:
            raise ValueError(f"missing policy identity for {condition}")
        policy = policies[0]
        if type(policy.get("program_id")) is not int or \
                policy["program_id"] <= 0 or \
                type(policy.get("cgroup_id")) is not int or \
                policy["cgroup_id"] <= 0 or \
                policy.get("target_id") != 1:
            raise ValueError(f"invalid policy identity for {condition}")
        if len(counters) != 2:
            raise ValueError(f"unexpected policy counter count for {condition}")
        by_phase = {row.get("phase"): row for row in counters}
        if set(by_phase) != {"pre-checkpoint", "post-restart"}:
            raise ValueError(f"unexpected counter phases for {condition}")
        if any(row.get("counter") != "select" or
               type(row.get("value")) is not int or row["value"] <= 0
               for row in counters):
            raise ValueError(f"invalid SELECT attribution for {condition}")
        if condition == "namei_ext" and \
                by_phase["post-restart"]["value"] <= \
                by_phase["pre-checkpoint"]["value"]:
            raise ValueError("namei_ext SELECT count did not increase")
    return lifecycles


def validate_application_rows(result, condition, runtime_identity):
    rows = load_jsonl(result / "application-observations.jsonl")
    if len(rows) != 2 or any(
            row.get("event") != "checkpoint-restore-application"
            or row.get("pass") is not True for row in rows):
        raise ValueError(f"invalid application row set for {condition}")
    pre = one(rows, "checkpoint-restore-application",
              stage="pre-checkpoint")
    post = one(rows, "checkpoint-restore-application",
               stage="post-restart")
    for row in rows:
        if row.get("uid") != runtime_identity["uid"] or \
                row.get("gid") != runtime_identity["gid"]:
            raise ValueError(f"runtime identity mismatch for {condition}")
    if not isinstance(pre.get("logical_path"), str) or \
            pre["logical_path"] != post.get("logical_path"):
        raise ValueError(f"logical path changed for {condition}")
    if pre.get("generation") != "a" or pre.get("restarts") != 0 or \
            pre.get("saw_stale") is not True or \
            pre.get("saw_new") is not False or \
            pre.get("expected_failure") is not False:
        raise ValueError(f"invalid pre-checkpoint oracle for {condition}")
    if pre.get("logical_dev") != pre.get("physical_dev") or \
            pre.get("logical_ino") != pre.get("physical_ino") or \
            not pre.get("logical_ino"):
        raise ValueError(f"generation-A identity mismatch for {condition}")
    if post.get("generation") != "b" or \
            type(post.get("restarts")) is not int or \
            post["restarts"] <= 0:
        raise ValueError(f"invalid restart attribution for {condition}")
    if condition != "pathvirt":
        expected_cgroup = f"/{condition}"
        if expected_cgroup not in pre.get("cgroup", "") or \
                expected_cgroup not in post.get("cgroup", ""):
            raise ValueError(f"cgroup attribution is missing for {condition}")

    if condition == "withdrawn":
        if post.get("expected_failure") is not True or \
                post.get("errno") != 2 or \
                post.get("logical_dev") != 0 or \
                post.get("logical_ino") != 0 or \
                post.get("saw_stale") is not False or \
                post.get("saw_new") is not False:
            raise ValueError("withdrawn control did not fail closed")
        return {"pre": pre, "post": post}

    if post.get("saw_stale") is not False or \
            post.get("saw_new") is not True or \
            post.get("expected_failure") is not False:
        raise ValueError(f"invalid post-restart oracle for {condition}")
    if post.get("logical_dev") != post.get("physical_dev") or \
            post.get("logical_ino") != post.get("physical_ino") or \
            not post.get("logical_ino") or \
            post.get("logical_ino") == pre.get("logical_ino"):
        raise ValueError(f"generation-B identity mismatch for {condition}")
    if condition == "pathvirt":
        if post.get("restart_env_status") != 0 or \
                "generation-b/workspace" not in \
                post.get("restart_mapping", "") or \
                "generation-a/workspace" not in \
                post.get("checkpoint_mapping", ""):
            raise ValueError("patched PathTranslator attribution is missing")
    return {"pre": pre, "post": post}


def lower_key(row):
    path = row.get("path")
    marker = "/fixture/"
    if not isinstance(path, str) or marker not in path:
        raise ValueError("invalid lower-object path")
    return path.split(marker, 1)[1]


def validate_lower_objects(result, condition):
    before = load_jsonl(result / "lower-before.jsonl")
    after = load_jsonl(result / "lower-after.jsonl")
    if len(before) != 6 or len(after) != 6:
        raise ValueError(f"unexpected lower-object count for {condition}")
    before_by_key = {lower_key(row): row for row in before}
    after_by_key = {lower_key(row): row for row in after}
    if len(before_by_key) != 6 or set(before_by_key) != set(after_by_key):
        raise ValueError(f"lower-object key mismatch for {condition}")
    expected_contents = {
        "generation-a/workspace/state.txt": "generation-a",
        "generation-a/workspace/shared.txt": "shared-common",
        "generation-a/workspace/stale.txt": "stale-only",
        "generation-b/workspace/state.txt": "generation-b",
        "generation-b/workspace/shared.txt": "shared-common",
        "generation-b/workspace/new.txt": "new-only",
    }
    if set(before_by_key) != set(expected_contents):
        raise ValueError(f"unexpected lower-object set for {condition}")
    fields = (
        "dev", "ino", "mode", "size", "mtime_sec", "mtime_nsec",
        "content", "final_newline",
    )
    for key in before_by_key:
        left = before_by_key[key]
        right = after_by_key[key]
        if left.get("phase") != "before" or right.get("phase") != "after":
            raise ValueError(f"invalid lower phase for {condition}:{key}")
        if left.get("event") != "checkpoint-restore-lower" or \
                right.get("event") != "checkpoint-restore-lower" or \
                type(left.get("dev")) is not int or left["dev"] <= 0 or \
                type(left.get("ino")) is not int or left["ino"] <= 0 or \
                type(left.get("mode")) is not int or \
                left["mode"] & 0o170000 != 0o100000:
            raise ValueError(f"invalid lower object for {condition}:{key}")
        if left.get("content") != expected_contents[key] or \
                left.get("final_newline") is not True:
            raise ValueError(f"wrong lower contents for {condition}:{key}")
        if left.get("size") != len(expected_contents[key]) + 1:
            raise ValueError(f"wrong lower size for {condition}:{key}")
        if any(left.get(field) != right.get(field) for field in fields):
            raise ValueError(f"lower object changed for {condition}:{key}")


def validate_checkpoint_artifact(result, condition):
    lines = [
        line.strip()
        for line in (result / "checkpoint-images.txt")
        .read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    if len(lines) != 1:
        raise ValueError(f"unexpected checkpoint image count for {condition}")
    image = Path(lines[0])
    if image.is_absolute() or ".." in image.parts:
        raise ValueError(f"non-relocatable checkpoint path for {condition}")
    checkpoint = result / image
    if not checkpoint.is_file() or checkpoint.stat().st_size <= 0:
        raise ValueError(f"missing checkpoint image for {condition}")


def validate_condition_inventory(result, condition):
    programs = json.loads(
        (result / "bpf-programs-after.json").read_text(encoding="utf-8")
    )
    if programs != []:
        raise ValueError(f"residual BPF program after {condition}")
    cgroups = json.loads(
        (result / "bpf-cgroup-after.json").read_text(encoding="utf-8")
    )
    if not isinstance(cgroups, list) or any(
            isinstance(item, dict) and "id" in item
            for item in nested_objects(cgroups)):
        raise ValueError(f"residual cgroup BPF program after {condition}")


def validate_inventories(boot):
    for name in ("bpf-programs-before.json", "bpf-programs-after.json"):
        value = json.loads((boot / name).read_text(encoding="utf-8"))
        if value != []:
            raise ValueError(f"nonempty BPF inventory: {name}")
    for name in ("bpf-cgroup-before.json", "bpf-cgroup-after.json"):
        value = json.loads((boot / name).read_text(encoding="utf-8"))
        if not isinstance(value, list) or any(
                isinstance(item, dict) and "id" in item
                for item in nested_objects(value)):
            raise ValueError(f"attached cgroup BPF program: {name}")


def nested_objects(value):
    if isinstance(value, dict):
        yield value
        for nested in value.values():
            yield from nested_objects(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from nested_objects(nested)


def validate_runtime_identity(boot):
    identity = load_json(boot / "runtime-identity.json")
    for field in ("uid", "gid"):
        if type(identity.get(field)) is not int or identity[field] < 0:
            raise ValueError(f"invalid runtime {field}")
    probe = (boot / "runtime-identity-probe.txt").read_text(
        encoding="utf-8"
    ).splitlines()
    if probe != [str(identity["uid"]), str(identity["gid"])]:
        raise ValueError("setpriv runtime identity probe mismatch")
    return identity


def analyze_result(result):
    result = Path(result)
    run = load_json(result / "run.json")
    repetitions = validate_run(run)
    boot_names = [
        line.strip()
        for line in (result / "expected-boots.txt")
        .read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    if len(boot_names) != repetitions or len(set(boot_names)) != repetitions:
        raise ValueError("unexpected boot list")
    timings = {}
    runtime_identities = {}
    applications = {}
    for boot_name in boot_names:
        boot = result / "boots" / boot_name
        boot_json = load_json(boot / "boot.json")
        if boot_json.get("schema") != \
                "namei_ext.checkpoint_restore.boot.v3" or \
                boot_json.get("status") != "completed" or \
                boot_json.get("conditions") != list(CONDITIONS) or \
                boot_json.get("pathtranslator_activation") != \
                "DMTCP_PATHVIRT_PLUGIN=1":
            raise ValueError(f"invalid boot record for {boot_name}")
        validate_inventories(boot)
        runtime_identity = validate_runtime_identity(boot)
        runtime_identities[boot_name] = runtime_identity
        rows = load_jsonl(boot / "observations.jsonl")
        timings[boot_name] = validate_controller_rows(rows)
        applications[boot_name] = {}
        for condition in CONDITIONS:
            condition_result = boot / "conditions" / condition
            applications[boot_name][condition] = validate_application_rows(
                condition_result, condition, runtime_identity
            )
            validate_lower_objects(condition_result, condition)
            validate_checkpoint_artifact(condition_result, condition)
            validate_condition_inventory(condition_result, condition)
    formal = run["result_level"] == "kvm_checkpoint_restore_rq1"
    return {
        "schema": "namei_ext.checkpoint_restore.summary.v3",
        "run_id": run["run_id"],
        "correctness": {
            "all_boots_passed": True,
            "boot_count": repetitions,
            "boots": boot_names,
            "conditions": list(CONDITIONS),
            "pathtranslator_internal_plugin": "explicitly_enabled",
            "pathvirt_a_to_b": "passed",
            "namei_ext_a_to_b": "passed",
            "withdrawn_control": "failed_closed_as_expected",
            "lower_objects_unchanged": True,
            "bpf_inventory_clean": True,
            "runtime_identity_consistent": True,
        },
        "timing_ns": {
            boot_name: {
                condition: {
                    field: timings[boot_name][condition][field]
                    for field in (
                        "checkpoint_ns",
                        "update_ns",
                        "restart_ns",
                        "total_ns",
                    )
                }
                for condition in CONDITIONS
            }
            for boot_name in boot_names
        },
        "mechanism": {
            "pathvirt": "DMTCP PathTranslator with disclosed scan fix",
            "namei_ext": "bounded existing-directory selection",
            "withdrawn": "causal control",
            "runtime_identity_by_boot": runtime_identities,
            "same_logical_path": all(
                applications[boot_name][condition]["pre"]["logical_path"]
                == applications[boot_name][condition]["post"][
                    "logical_path"
                ]
                for boot_name in boot_names
                for condition in CONDITIONS
            ),
        },
        "verdict": {
            "tested_hypothesis": "supported" if formal else "not_tested",
            "evidence_role": (
                "formal_rq1_evidence" if formal else "dependency_preflight"
            ),
            "next_gate": (
                "integrate W5 into the seven-case RQ1 evaluation"
                if formal else
                "independent result review before formal three-boot run"
            ),
        },
    }


def write_outputs(summary, output):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=False)
    (output / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    with (output / "summary.csv").open(
            "w", encoding="utf-8", newline="") as destination:
        writer = csv.writer(destination)
        writer.writerow((
            "boot", "condition", "checkpoint_ns", "update_ns",
            "restart_ns", "total_ns",
        ))
        for boot_name, boot_timings in summary["timing_ns"].items():
            for condition in CONDITIONS:
                timing = boot_timings[condition]
                writer.writerow((
                    boot_name,
                    condition,
                    timing["checkpoint_ns"],
                    timing["update_ns"],
                    timing["restart_ns"],
                    timing["total_ns"],
                ))
    formal = summary["verdict"]["evidence_role"] == "formal_rq1_evidence"
    report = [
        "# Checkpoint/Restore RQ1" if formal else
        "# Checkpoint/Restore Preflight",
        "",
        f"All three conditions passed in {summary['correctness']['boot_count']} "
        "modified-kernel boot(s).",
        "DMTCP PathTranslator and namei_ext both changed the same",
        "remembered pathname from generation A to generation B after a real",
        "DMTCP restart. Withdrawing the namei_ext mapping failed closed as",
        "expected. The lower objects were unchanged, and no BPF program",
        "remained attached after a boot.",
        "",
        (
            "This is formal W5 RQ1 evidence."
            if formal else
            "This is dependency-preflight evidence, not a formal paper result."
        ),
        "Durations are diagnostic and do not support a performance claim.",
        "",
    ]
    (output / "report.md").write_text(
        "\n".join(report), encoding="utf-8"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--result", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    summary = analyze_result(arguments.result)
    write_outputs(summary, arguments.output)


if __name__ == "__main__":
    main()
