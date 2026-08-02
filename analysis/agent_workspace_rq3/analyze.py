#!/usr/bin/env python3

import argparse
import hashlib
import json
import re
from pathlib import Path


KPROBE_SYMBOLS = {
    "fill_super": "wrapfs_fill_super",
    "put_super": "wrapfs_put_super",
    "lookup": "wrapfs_lookup",
    "readdir": "wrapfs_readdir",
    "open": "wrapfs_open",
    "read_iter": "wrapfs_read_iter",
    "write_iter": "wrapfs_write_iter",
    "fsync": "wrapfs_fsync",
    "getattr": "wrapfs_getattr",
    "setattr": "wrapfs_setattr",
    "create": "wrapfs_create",
    "rename": "wrapfs_rename",
    "unlink": "wrapfs_unlink",
}
KPROBE_EVENTS = tuple(KPROBE_SYMBOLS)

FAULT_ERRNOS = {
    "verifier_reject_ctx_write": 13,
    "verifier_reject_action_4": 22,
    "redirect_len_zero": 22,
    "redirect_len_zero_readdir": 22,
    "redirect_len_65": 22,
    "redirect_len_65_readdir": 22,
    "redirect_dot": 22,
    "redirect_dot_readdir": 22,
    "redirect_dot_dot": 22,
    "redirect_dot_dot_readdir": 22,
    "redirect_slash": 22,
    "redirect_slash_readdir": 22,
    "redirect_embedded_nul": 22,
    "redirect_embedded_nul_readdir": 22,
    "target_zero": 22,
    "target_zero_warm": 22,
    "target_unregistered": 2,
    "select_readdir": 95,
    "select_create": 95,
    "redirect_create": 95,
    "select_final_open": 95,
}
RUNTIME_FAULTS = tuple(
    case for case in FAULT_ERRNOS if not case.startswith("verifier_")
)
FAULT_CELL_CASES = tuple(
    case for case in RUNTIME_FAULTS if case != "target_zero_warm"
)
MANIFEST_ROLES = {
    "redirect_source",
    "target_source",
    "final_open_source",
    "readdir_entry",
    "select_create_path",
    "redirect_create_path",
    "redirected_create_path",
    "symlink_fixture",
}
LOWER_TREE_MANIFEST_FIELDS = (
    "base_main_preserved",
    "base_deleted_preserved",
    "base_src_preserved",
    "base_git_preserved",
    "base_symlink_preserved",
    "base_generated_absent",
    "base_cached_negative_absent",
    "upper_main_preserved",
    "upper_deleted_preserved",
    "upper_src_preserved",
    "upper_git_preserved",
    "upper_symlink_preserved",
    "upper_generated_present",
    "upper_renamed_absent",
    "upper_cached_negative_absent",
    "visible_main",
    "visible_deleted",
    "visible_generated",
    "visible_cached_negative",
)

PAIRWISE_CASES = (
    ("base main bytes", "base_epoch_main", "base_lookup_main"),
    ("base main mode", "base_epoch_main_mode", "base_main_mode"),
    ("base hidden lookup", "base_epoch_whiteout", "base_lookup_deleted_hidden"),
    ("base hidden readdir", "base_epoch_readdir", "base_readdir_deleted_hidden"),
    ("base nested src", "base_epoch_src_app", "base_nested_src"),
    ("base nested git", "base_epoch_git_head", "base_nested_git"),
    ("base symlink", "base_epoch_symlink", "base_symlink"),
    ("base symlink follow", "base_epoch_symlink_follow", "base_symlink_follow"),
    ("base execute", "base_epoch_exec_tool", "base_exec_tool"),
    (
        "base denied access",
        "base_epoch_denied_access",
        "base_unprivileged_access_denied",
    ),
    ("base denied mode", "base_epoch_denied_mode", "base_denied_mode"),
    ("upper main bytes", "upper_epoch_main", "upper_lookup_main"),
    ("upper main mode", "upper_epoch_main_mode", "upper_main_mode"),
    (
        "upper hidden lookup",
        "upper_epoch_whiteout",
        "upper_lookup_deleted_hidden",
    ),
    (
        "upper hidden readdir",
        "upper_epoch_readdir_before_write",
        "upper_readdir_deleted_hidden",
    ),
    ("upper nested src", "upper_epoch_src_app", "upper_nested_src"),
    ("upper nested git", "upper_epoch_git_head", "upper_nested_git"),
    ("upper symlink", "upper_epoch_symlink", "upper_symlink"),
    (
        "upper symlink follow",
        "upper_epoch_symlink_follow",
        "upper_symlink_follow",
    ),
    ("upper execute", "upper_epoch_exec_tool", "upper_exec_tool"),
    (
        "upper denied access",
        "upper_epoch_denied_access",
        "upper_unprivileged_access_denied",
    ),
    ("upper denied mode", "upper_epoch_denied_mode", "upper_denied_mode"),
    (
        "generated negative",
        "upper_generated_negative_before_write",
        "generated_negative_before_create",
    ),
    (
        "generated create/write/fsync/fchmod/fstat",
        "upper_epoch_create_write_fsync_fchmod_fstat",
        "generated_create_write_fsync_fchmod_fstat",
    ),
    (
        "generated lower bytes",
        "upper_generated_visible",
        "generated_lower_visible",
    ),
    (
        "generated readdir",
        "upper_epoch_readdir_after_write",
        "generated_readdir_visible",
    ),
    (
        "cached negative before create",
        "agentfs_cached_negative_before_create",
        "cached_negative_before_create",
    ),
    (
        "cached negative create",
        "agentfs_cached_negative_create",
        "cached_negative_create",
    ),
    (
        "cached negative bytes",
        "agentfs_cached_negative_visible",
        "cached_negative_read",
    ),
    (
        "cached negative readdir",
        "agentfs_cached_negative_readdir_visible",
        "cached_negative_readdir_visible",
    ),
    (
        "rename generated",
        "agentfs_rename_generated_to_renamed",
        "rename_generated_to_renamed",
    ),
    (
        "rename old absent",
        "agentfs_rename_generated_old_absent",
        "rename_old_absent",
    ),
    (
        "rename new bytes",
        "agentfs_rename_generated_new_visible",
        "rename_new_visible",
    ),
    (
        "rename restore",
        "agentfs_rename_restored_generated",
        "rename_restore_generated",
    ),
    (
        "unlink cached negative",
        "agentfs_unlink_cached_created",
        "unlink_cached_negative",
    ),
    (
        "unlink result absent",
        "agentfs_unlink_cached_absent",
        "unlink_cached_negative_absent",
    ),
    ("final lower tree", "final_tree_manifest", "final_lower_tree_manifest"),
)

RESPONSIBILITY_ROWS = (
    {
        "responsibility": "policy execution",
        "namei_ext": "verified BPF decision function",
        "wrapfs": "privileged kernel module policy",
        "fuse": "userspace filesystem daemon callbacks",
    },
    {
        "responsibility": "lookup and readdir",
        "namei_ext": "BPF decision; VFS performs resolution",
        "wrapfs": "Wrapfs lookup and iterate methods",
        "fuse": "FUSE requests and daemon callbacks",
    },
    {
        "responsibility": "inode, dentry, super, and file methods",
        "namei_ext": "VFS and lower filesystem",
        "wrapfs": "Wrapfs interposes and forwards",
        "fuse": "FUSE client and daemon filesystem",
    },
    {
        "responsibility": "ordinary open-fd data and metadata operations",
        "namei_ext": "selected lower file operations",
        "wrapfs": "Wrapfs file and inode methods forward to lower",
        "fuse": "daemon-mediated FUSE requests",
    },
    {
        "responsibility": "target and scope state",
        "namei_ext": "cgroup policy link, target registry, policy maps",
        "wrapfs": "mount source, stacked dentries, module policy",
        "fuse": "mount plus daemon path and epoch state",
    },
    {
        "responsibility": "daemon and mount lifetime",
        "namei_ext": "no policy mount or userspace daemon",
        "wrapfs": "stacked mount and kernel module",
        "fuse": "mount and live daemon connection",
    },
    {
        "responsibility": "cache and coherency",
        "namei_ext": "existing VFS and lower-filesystem caches",
        "wrapfs": "stacked dentry/inode state plus lower caches",
        "fuse": "FUSE client caches plus daemon invalidation protocol",
    },
    {
        "responsibility": "invalid policy behavior",
        "namei_ext": "verifier and bounded kernel errno checks",
        "wrapfs": "kernel module validation and failure paths",
        "fuse": "daemon validation, disconnect, and request failure paths",
    },
    {
        "responsibility": "persistence",
        "namei_ext": "lower filesystem",
        "wrapfs": "forwarded to lower filesystem",
        "fuse": "daemon implementation and lower backing store",
    },
)


def read_jsonl(path: Path) -> list[dict]:
    records = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            if not line.strip():
                continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError as error:
                raise ValueError(f"{path}:{line_number}: {error}") from error
    if not records:
        raise ValueError(f"{path}: no observations")
    return records


def validate_replay_input(
    formal_dir: Path,
    input_path: Path,
    run: dict,
) -> None:
    declared = run.get("observations")
    if not isinstance(declared, str) or not declared:
        raise ValueError("run.json lacks an observations path")
    relative = Path(declared)
    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError("run.json observations path escapes the result root")
    expected_path = (formal_dir / relative).resolve()
    if input_path.resolve() != expected_path:
        raise ValueError("replay input does not match run.json")

    boot_dirs = sorted(path for path in formal_dir.glob("boot-*") if path.is_dir())
    if len(boot_dirs) != 3:
        raise ValueError("replay bundle must contain three boot directories")
    combined = b"".join(
        (boot / "observations.jsonl").read_bytes() for boot in boot_dirs
    )
    if input_path.read_bytes() != combined:
        raise ValueError(
            "declared observations are not the exact ordered boot observations"
        )


def one_record(
    records: list[dict],
    *,
    event: str | None = None,
    case: str | None = None,
    counter: str | None = None,
    fault_case: str | None = None,
    phase: str | None = None,
    role: str | None = None,
    manifest: str | None = None,
    directory: str | None = None,
    condition: str | None = None,
) -> dict:
    selectors = {
        "event": event,
        "case": case,
        "counter": counter,
        "fault_case": fault_case,
        "phase": phase,
        "role": role,
        "manifest": manifest,
        "directory": directory,
        "condition": condition,
    }
    matches = [
        record
        for record in records
        if all(value is None or record.get(key) == value
               for key, value in selectors.items())
    ]
    if len(matches) != 1:
        raise ValueError(
            f"expected one record for {selectors}, found {len(matches)}"
        )
    return matches[0]


def count_kprobes(path: Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    counts = {}
    for event, symbol in KPROBE_SYMBOLS.items():
        pattern = (
            rf":\s+{re.escape(event)}:\s+"
            rf"\({re.escape(symbol)}\+[^)]*\[wrapfs\]\)"
        )
        counts[event] = len(re.findall(pattern, text))
        if counts[event] == 0:
            raise ValueError(
                f"{path}: no {event} trace for {symbol} [wrapfs]"
            )
    return counts


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while chunk := source.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def verify_hash_manifest(path: Path) -> int:
    count = 0
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        fields = line.split(maxsplit=1)
        if len(fields) != 2 or len(fields[0]) != 64:
            raise ValueError(f"{path}:{line_number}: malformed SHA-256 row")
        artifact = Path(fields[1].lstrip("*"))
        if not artifact.is_absolute():
            artifact = path.parent / artifact
        if not artifact.is_file():
            raise ValueError(f"{path}:{line_number}: missing {artifact}")
        if file_sha256(artifact) != fields[0]:
            raise ValueError(f"{path}:{line_number}: hash mismatch for {artifact}")
        count += 1
    if not count:
        raise ValueError(f"{path}: empty SHA-256 manifest")
    return count


def validate_pairwise_oracles(records: list[dict]) -> list[dict]:
    expected_case_pairs = {
        (namei_case, wrapfs_case)
        for _, namei_case, wrapfs_case in PAIRWISE_CASES
    }
    by_condition = {}
    for condition in ("namei_ext", "wrapfs"):
        condition_records = [
            record for record in records
            if record.get("event") == "rq3-semantic-oracle"
            and record.get("condition") == condition
        ]
        if len(condition_records) != len(PAIRWISE_CASES):
            raise ValueError(
                f"{condition}: expected {len(PAIRWISE_CASES)} semantic "
                f"oracles, found {len(condition_records)}"
            )
        by_id = {record.get("oracle_id"): record
                 for record in condition_records}
        if None in by_id or len(by_id) != len(condition_records):
            raise ValueError(f"{condition}: duplicate or missing oracle_id")
        by_condition[condition] = by_id

    if set(by_condition["namei_ext"]) != set(by_condition["wrapfs"]):
        raise ValueError("semantic oracle ID sets differ")

    pairs = []
    observed_case_pairs = set()
    for oracle_id in sorted(by_condition["namei_ext"]):
        namei = by_condition["namei_ext"][oracle_id]
        wrapfs = by_condition["wrapfs"][oracle_id]
        for field in ("oracle_id", "operation", "expected", "pass"):
            if namei.get(field) != wrapfs.get(field):
                raise ValueError(
                    f"{oracle_id}: semantic field {field} differs"
                )
        if namei.get("pass") is not True:
            raise ValueError(f"{oracle_id}: pairwise oracle failed")
        observed_case_pairs.add((namei.get("case"), wrapfs.get("case")))
        pairs.append({
            "oracle_id": oracle_id,
            "operation": namei["operation"],
            "expected": namei["expected"],
            "namei_case": namei["case"],
            "wrapfs_case": wrapfs["case"],
            "pass": True,
        })

    if observed_case_pairs != expected_case_pairs:
        raise ValueError("semantic oracle case mapping differs from plan")

    ignored_manifest_fields = {"event", "result_level", "condition"}
    manifests = {}
    for condition in ("namei_ext", "wrapfs"):
        manifest = one_record(
            records,
            event="rq3-lower-tree-manifest",
            condition=condition,
        )
        manifests[condition] = {
            key: value for key, value in manifest.items()
            if key not in ignored_manifest_fields
        }
        if set(manifests[condition]) != {
            "pass", *LOWER_TREE_MANIFEST_FIELDS
        }:
            raise ValueError(
                f"{condition}: lower-tree manifest field set differs"
            )
    if manifests["namei_ext"] != manifests["wrapfs"]:
        raise ValueError("19-field lower-tree manifests differ")
    if manifests["namei_ext"].get("pass") is not True:
        raise ValueError("lower-tree manifest failed")
    return pairs


def comparable_object(record: dict) -> dict:
    ignored = {"event", "fault_case", "phase", "pass"}
    return {key: value for key, value in record.items() if key not in ignored}


def validate_fault_containment(records: list[dict]) -> dict:
    for case in RUNTIME_FAULTS:
        containment = one_record(
            records, event="rq3-fault-containment", fault_case=case
        )
        if containment.get("pass") is not True:
            raise ValueError(f"{case}: lower-object containment failed")
        before_roles = set()
        after_roles = set()
        for role in MANIFEST_ROLES:
            before = one_record(
                records,
                event="rq3-fault-lower-object",
                fault_case=case,
                phase="before",
                role=role,
            )
            after = one_record(
                records,
                event="rq3-fault-lower-object",
                fault_case=case,
                phase="after",
                role=role,
            )
            if comparable_object(before) != comparable_object(after):
                raise ValueError(f"{case}: {role} changed across fault")
            before_roles.add(role)
            after_roles.add(role)
        if before_roles != MANIFEST_ROLES or after_roles != MANIFEST_ROLES:
            raise ValueError(f"{case}: incomplete lower-object manifest")
        for directory in ("root", "readdir"):
            before_directory = one_record(
                records,
                event="rq3-fault-directory-manifest",
                fault_case=case,
                phase="before",
                directory=directory,
            )
            after_directory = one_record(
                records,
                event="rq3-fault-directory-manifest",
                fault_case=case,
                phase="after",
                directory=directory,
            )
            if before_directory.get("entries") != after_directory.get("entries"):
                raise ValueError(
                    f"{case}: {directory} directory entries changed"
                )

    for case in ("select_create", "redirect_create"):
        for role in (
            "select_create_path",
            "redirect_create_path",
            "redirected_create_path",
        ):
            before = one_record(
                records,
                event="rq3-fault-lower-object",
                fault_case=case,
                phase="before",
                role=role,
            )
            after = one_record(
                records,
                event="rq3-fault-lower-object",
                fault_case=case,
                phase="after",
                role=role,
            )
            if before["exists"] or after["exists"]:
                raise ValueError(f"{case}: {role} was created")

    for case in FAULT_CELL_CASES:
        lifecycle = one_record(
            records, event="rq3-fault-cell-lifecycle", fault_case=case
        )
        if lifecycle.get("pass") is not True:
            raise ValueError(f"{case}: policy lifecycle teardown failed")
    return {
        "runtime_faults_with_manifests": len(RUNTIME_FAULTS),
        "objects_per_manifest": len(MANIFEST_ROLES),
        "directories_per_manifest": 2,
        "independent_policy_lifecycles": len(FAULT_CELL_CASES),
    }


def analyze_boot(boot_dir: Path) -> dict:
    records = read_jsonl(boot_dir / "observations.jsonl")
    failed = [record for record in records if record.get("pass") is False]
    if failed:
        raise ValueError(f"{boot_dir}: {len(failed)} pass=false observations")

    done = one_record(records, event="rq3-preflight-done")
    if done.get("run_role") != "formal" or done.get("pass") is not True:
        raise ValueError(f"{boot_dir}: formal completion marker mismatch")
    for case in (
        "agent_workspace_rq3_summary",
        "rq3_wrapfs_complete",
        "rq3_child_cgroup_removed",
        "fault_child_cgroup_removed",
    ):
        if one_record(records, case=case).get("pass") is not True:
            raise ValueError(f"{boot_dir}: {case} failed")
    if one_record(records, event="rq3-fault-summary").get("pass") is not True:
        raise ValueError(f"{boot_dir}: rq3-fault-summary failed")
    for condition in ("namei_ext", "wrapfs"):
        if one_record(
            records,
            event="rq3-lower-tree-manifest",
            condition=condition,
        ).get("pass") is not True:
            raise ValueError(
                f"{boot_dir}: {condition} lower-tree manifest failed"
            )

    before = one_record(
        records,
        event="agent-workspace-policy-counter",
        counter="rq3_fd_total_before",
    )["value"]
    after = one_record(
        records,
        event="agent-workspace-policy-counter",
        counter="rq3_fd_total_after",
    )["value"]
    if before != after:
        raise ValueError(f"{boot_dir}: fd-only policy counter changed")

    observed_faults = {}
    for case, expected_errno in FAULT_ERRNOS.items():
        record = one_record(records, case=case)
        if record.get("errno") != expected_errno:
            raise ValueError(
                f"{boot_dir}: {case} errno {record.get('errno')} "
                f"!= {expected_errno}"
            )
        observed_faults[case] = record["errno"]

    lower_fs = (boot_dir / "lower-filesystem.txt").read_text(encoding="utf-8")
    if "ext4" not in lower_fs:
        raise ValueError(f"{boot_dir}: lower filesystem is not ext4")
    for required in (
        "invalid-ctx-verifier.log",
        "invalid-action-verifier.log",
        "dmesg.log",
        "artifacts.sha256",
        "inputs.sha256",
        "provenance.json",
    ):
        if not (boot_dir / required).is_file():
            raise ValueError(f"{boot_dir}: missing {required}")
    provenance = json.loads(
        (boot_dir / "provenance.json").read_text(encoding="utf-8")
    )
    if provenance.get("project_dirty") or provenance.get("kernel_dirty"):
        raise ValueError(f"{boot_dir}: formal source tree was dirty")
    verifier_expectations = {
        "invalid-ctx-verifier.log":
            "invalid bpf_context access off=0 size=4",
        "invalid-action-verifier.log":
            "R0 has smin=4 smax=4 should have been in [0, 3]",
    }
    for filename, evidence in verifier_expectations.items():
        text = (boot_dir / filename).read_text(encoding="utf-8")
        if evidence not in text:
            raise ValueError(f"{boot_dir}: {filename} lacks exact evidence")

    return {
        "boot": boot_dir.name,
        "observation_count": len(records),
        "namei_fd_policy_counter_before": before,
        "namei_fd_policy_counter_after": after,
        "namei_fd_policy_counter_delta": after - before,
        "pairwise_oracles": validate_pairwise_oracles(records),
        "wrapfs_kprobe_counts": count_kprobes(
            boot_dir / "wrapfs-kprobe.trace"
        ),
        "fault_errnos": observed_faults,
        "fault_containment": validate_fault_containment(records),
        "input_hash_rows": verify_hash_manifest(
            boot_dir / (
                "publication-inputs.sha256"
                if (boot_dir / "publication-inputs.sha256").is_file()
                else "inputs.sha256"
            )
        ),
        "artifact_hash_rows": verify_hash_manifest(
            boot_dir / (
                "publication-artifacts.sha256"
                if (boot_dir / "publication-artifacts.sha256").is_file()
                else "artifacts.sha256"
            )
        ),
        "provenance": provenance,
    }


def require_tokens(path: Path, tokens: tuple[str, ...]) -> None:
    text = path.read_text(encoding="utf-8")
    missing = [token for token in tokens if token not in text]
    if missing:
        raise ValueError(f"{path}: missing source evidence {missing}")


OPERATION_TABLE_PATTERN = re.compile(
    r"(?:static\s+)?(?:const\s+)?struct\s+"
    r"(file_operations|inode_operations|super_operations|"
    r"dentry_operations|address_space_operations|fs_context_operations|"
    r"vm_operations_struct|file_system_type|fuse_operations)\s+"
    r"([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\{(.*?)\n\};",
    re.DOTALL,
)


def make_logical_lines(path: Path) -> list[str]:
    lines = []
    pending = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line and not pending:
            continue
        pending += line[:-1] + " " if line.endswith("\\") else line
        if not line.endswith("\\"):
            lines.append(pending.strip())
            pending = ""
    if pending:
        raise ValueError(f"{path}: unterminated Make continuation")
    return lines


def make_object_sources(
    makefile: Path,
    variable: str,
    config: set[str] | None = None,
) -> list[Path]:
    objects = []
    for line in make_logical_lines(makefile):
        unconditional = re.fullmatch(
            rf"{re.escape(variable)}\s*(?::=|\+=)\s*(.*)", line
        )
        if unconditional:
            objects.extend(unconditional.group(1).split())
            continue
        conditional = re.fullmatch(
            rf"{re.escape(variable[:-1])}"
            r"\$\((CONFIG_[A-Z0-9_]+)\)\s*\+=\s*(.*)",
            line,
        )
        if conditional and config and conditional.group(1) in config:
            objects.extend(conditional.group(2).split())
    sources = []
    for object_name in objects:
        if not object_name.endswith(".o"):
            raise ValueError(f"{makefile}: non-object token {object_name}")
        source = makefile.parent / f"{object_name[:-2]}.c"
        if not source.is_file():
            raise ValueError(f"{makefile}: missing source for {object_name}")
        sources.append(source)
    return sorted(set(sources))


def registered_operation_tables(paths: list[Path]) -> tuple[list[dict], list[str]]:
    tables = []
    slots = set()
    for path in paths:
        text = path.read_text(encoding="utf-8")
        for table_type, table_name, body in OPERATION_TABLE_PATTERN.findall(text):
            assignments = []
            for slot, function in re.findall(
                r"\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
                r"([A-Za-z_][A-Za-z0-9_]*)",
                body,
            ):
                if table_type == "file_system_type" and slot in {
                    "owner", "name", "fs_flags"
                }:
                    continue
                assignments.append({"slot": slot, "function": function})
                slots.add(slot)
            if assignments:
                tables.append({
                    "source": str(path),
                    "type": table_type,
                    "table": table_name,
                    "assignments": assignments,
                })
    return tables, sorted(slots)


def enabled_kernel_config(path: Path) -> set[str]:
    return {
        line.split("=", 1)[0]
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.startswith("CONFIG_") and line.endswith("=y")
    }


def source_accounting(root: Path, kernel_config: Path) -> dict:
    def relative(path: Path) -> str:
        return path.resolve().relative_to(root.resolve()).as_posix()

    def relative_tables(tables: list[dict]) -> list[dict]:
        for table in tables:
            table["source"] = relative(Path(table["source"]))
        return tables

    kernel_dir = root / "kernel"
    kernel_source = kernel_dir / "fs/namei_ext.c"
    policy_source = root / "bpf/policies/agent_workspace_view.bpf.c"
    wrapfs_makefile = root / "thirdparty/wrapfs/Makefile"
    wrapfs_sources = make_object_sources(wrapfs_makefile, "wrapfs-y")
    kernel_integration = {
        kernel_dir / "fs/namei.c": ("namei_ext",),
        kernel_dir / "fs/namei_ext.c": ("namei_ext_register_target",),
        kernel_dir / "fs/readdir.c": ("namei_ext",),
        kernel_dir / "include/linux/bpf-cgroup-defs.h":
            ("CGROUP_NAMEI_EXT",),
        kernel_dir / "include/linux/bpf-cgroup.h": ("namei_ext",),
        kernel_dir / "include/linux/namei_ext.h": ("namei_ext",),
        kernel_dir / "include/uapi/linux/bpf.h":
            ("BPF_PROG_TYPE_NAMEI_EXT",),
        kernel_dir / "kernel/bpf/cgroup.c": ("namei_ext",),
        kernel_dir / "kernel/bpf/verifier.c": ("BPF_PROG_TYPE_NAMEI_EXT",),
    }
    fuse_source = (
        root / "experiments/agent_workspace/namei_ext_agent_workspace_fuse.c"
    )
    fuse_makefile = kernel_dir / "fs/fuse/Makefile"
    fuse_kernel_sources = make_object_sources(
        fuse_makefile,
        "fuse-y",
        enabled_kernel_config(kernel_config),
    )
    require_tokens(
        kernel_source,
        (
            "namei_ext_register_target",
            "namei_ext_clear_targets",
            "namei_ext_scope",
            "namei_ext_get_target",
            "namei_ext_parent_maybe_managed",
        ),
    )
    require_tokens(
        policy_source,
        ("SEC(\"cgroup/namei_ext\")", "namei_ext_policy", "aw_counters"),
    )
    for path, tokens in kernel_integration.items():
        require_tokens(path, tokens)
    wrapfs_tables, wrapfs_slots = registered_operation_tables(wrapfs_sources)
    fuse_tables, fuse_slots = registered_operation_tables([fuse_source])
    fuse_kernel_tables, fuse_kernel_slots = registered_operation_tables(
        fuse_kernel_sources
    )
    required_wrapfs = {
        "lookup", "iterate_shared", "open", "read_iter", "write_iter",
        "fsync", "getattr", "setattr", "create", "rename", "unlink",
        "put_super",
    }
    required_fuse = {
        "getattr", "readdir", "open", "create", "read", "write",
        "readlink", "unlink", "rename", "truncate",
    }
    if not required_wrapfs.issubset(wrapfs_slots):
        raise ValueError("Wrapfs source inventory is incomplete")
    if not required_fuse.issubset(fuse_slots):
        raise ValueError("FUSE callback inventory is incomplete")
    return {
        "namei_ext_shared": {
            "sources": [relative(path) for path in kernel_integration],
            "owned_state": [
                "target registry",
                "cgroup scope",
                "action validation",
                "RCU lifetime",
                "cgroup release",
            ],
        },
        "namei_ext_workload_policy": {
            "source": relative(policy_source),
            "entry_points": ["cgroup/namei_ext"],
        },
        "wrapfs_deployed_module": {
            "makefile": relative(wrapfs_makefile),
            "sources": [relative(path) for path in wrapfs_sources],
            "operation_tables": relative_tables(wrapfs_tables),
            "registered_vfs_slots": wrapfs_slots,
        },
        "fuse_deployed_filesystem": {
            "daemon_source": relative(fuse_source),
            "daemon_operation_tables": relative_tables(fuse_tables),
            "registered_callbacks": fuse_slots,
            "kernel_makefile": relative(fuse_makefile),
            "kernel_sources": [relative(path) for path in fuse_kernel_sources],
            "kernel_operation_tables": relative_tables(fuse_kernel_tables),
            "kernel_registered_vfs_slots": fuse_kernel_slots,
        },
    }


def summarize(formal_dir: Path, root: Path | None = None) -> dict:
    if root is None:
        root = Path(__file__).resolve().parents[2]
    summary_path = formal_dir / "formal-summary.json"
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    if summary.get("pass") is not True or summary.get("boots") != 3:
        raise ValueError(f"{summary_path}: formal summary is not 3/3 pass")
    boot_dirs = sorted(path for path in formal_dir.glob("boot-*") if path.is_dir())
    if len(boot_dirs) != 3:
        raise ValueError(f"{formal_dir}: expected 3 boot directories")
    boots = [analyze_boot(path) for path in boot_dirs]

    provenance_keys = (
        "project_commit",
        "kernel_commit",
        "kernel_submodule_commit",
        "wrapfs_upstream_commit",
    )
    for key in provenance_keys:
        values = {boot["provenance"].get(key) for boot in boots}
        if len(values) != 1 or None in values:
            raise ValueError(f"formal boots disagree on {key}")
    if (
        boots[0]["provenance"]["kernel_commit"]
        != boots[0]["provenance"]["kernel_submodule_commit"]
    ):
        raise ValueError("project submodule does not pin the tested kernel")

    kprobe_ranges = {}
    for event in KPROBE_EVENTS:
        values = [boot["wrapfs_kprobe_counts"][event] for boot in boots]
        kprobe_ranges[event] = {
            "min": min(values),
            "max": max(values),
            "per_boot": values,
            "engaged_boots": sum(value > 0 for value in values),
        }

    return {
        "schema": "namei_ext.agent_workspace_rq3.analysis.v2",
        "formal_run_id": summary["run_id"],
        "boots": boots,
        "completed_boots": len(boots),
        "all_oracles_passed": True,
        "lower_fs": "ext4",
        "namei_fd_policy_counter_unchanged_boots": sum(
            boot["namei_fd_policy_counter_delta"] == 0 for boot in boots
        ),
        "pairwise_oracle_count": len(PAIRWISE_CASES),
        "wrapfs_kprobe_ranges": kprobe_ranges,
        "fault_errnos": FAULT_ERRNOS,
        "responsibility_matrix": list(RESPONSIBILITY_ROWS),
        "source_accounting": source_accounting(
            root, boot_dirs[0] / "kernel.config"
        ),
        "provenance": {
            key: boots[0]["provenance"][key] for key in provenance_keys
        },
    }


def render_markdown(result: dict) -> str:
    lines = [
        "# Agent Workspace RQ3 Formal Report",
        "",
        f"- Formal run: `{result['formal_run_id']}`",
        f"- Complete independent KVM boots: {result['completed_boots']}/3",
        f"- Lower filesystem: {result['lower_fs']}",
        f"- Pairwise AgentFS-derived oracles: "
        f"{result['pairwise_oracle_count']}/{result['pairwise_oracle_count']} "
        "for both mechanisms in every boot",
        f"- `namei_ext` fd-only counter unchanged: "
        f"{result['namei_fd_policy_counter_unchanged_boots']}/3 boots",
        "",
        "## Responsibility Matrix",
        "",
        "| Responsibility | `namei_ext` | Wrapfs-derived | FUSE comparator |",
        "| --- | --- | --- | --- |",
    ]
    for row in result["responsibility_matrix"]:
        lines.append(
            f"| {row['responsibility']} | {row['namei_ext']} | "
            f"{row['wrapfs']} | {row['fuse']} |"
        )
    lines.extend([
        "",
        "## Runtime Attribution",
        "",
        "| Wrapfs method | Count range across boots | Engaged boots |",
        "| --- | ---: | ---: |",
    ])
    for event in KPROBE_EVENTS:
        values = result["wrapfs_kprobe_ranges"][event]
        lines.append(
            f"| `{event}` | {values['min']}-{values['max']} | "
            f"{values['engaged_boots']}/3 |"
        )
    lines.extend([
        "",
        "Every trace row is attributed to the expected `wrapfs_* [wrapfs]` "
        "module symbol. Counts describe this fixed oracle and are not a "
        "performance or safety score.",
        "",
        "## Fail-Closed Matrix",
        "",
        "| Fault | Errno | Lower-object evidence | Boots |",
        "| --- | ---: | --- | ---: |",
    ])
    for case, err in FAULT_ERRNOS.items():
        evidence = (
            "verifier log"
            if case.startswith("verifier_")
            else (
                f"statx + SHA-256 for {len(MANIFEST_ROLES)} objects; "
                "2 directory manifests"
            )
        )
        lines.append(f"| `{case}` | {err} | {evidence} | 3/3 |")
    lines.extend([
        "",
        "Each runtime cell independently loads and attaches the policy, "
        "registers its target, executes one fault, detaches, clears targets, "
        "and preserves the lower-object manifest. The child cgroups are "
        "removed before completion.",
        "",
        "## Source Accounting",
        "",
        f"- `namei_ext` workload entry points: "
        f"{', '.join(result['source_accounting']['namei_ext_workload_policy']['entry_points'])}",
        f"- `namei_ext` deployed kernel integration files: "
        f"{len(result['source_accounting']['namei_ext_shared']['sources'])}",
        f"- Wrapfs deployed compiled sources: "
        f"{len(result['source_accounting']['wrapfs_deployed_module']['sources'])}",
        f"- Wrapfs deployed VFS slots: "
        f"{', '.join(result['source_accounting']['wrapfs_deployed_module']['registered_vfs_slots'])}",
        f"- FUSE comparator callbacks: "
        f"{', '.join(result['source_accounting']['fuse_deployed_filesystem']['registered_callbacks'])}",
        f"- FUSE kernel client compiled sources: "
        f"{len(result['source_accounting']['fuse_deployed_filesystem']['kernel_sources'])}",
        "",
        "## Supported Claim",
        "",
        "For this existing-object Agent workspace view, `namei_ext` confines "
        "workload policy execution to pathname lookup and directory "
        "iteration, after which ordinary file operations use the selected "
        "lower object. The matched stackable implementation registers and "
        "executes superblock, lookup, directory, inode, and file methods for "
        "the same pairwise oracle. Invalid programs and unsupported decisions "
        "return the declared verifier or errno result in this matrix. This "
        "supports the tested method and runtime-responsibility boundary, not "
        "a general comparison of complete filesystems.",
        "",
    ])
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--formal-dir", type=Path)
    parser.add_argument("--root", type=Path)
    parser.add_argument("--json", type=Path)
    parser.add_argument("--markdown", type=Path)
    parser.add_argument("--input", type=Path)
    parser.add_argument("--run", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--seed", type=int)
    args = parser.parse_args()

    direct = any(
        value is not None
        for value in (args.formal_dir, args.root, args.json, args.markdown)
    )
    replay = any(
        value is not None
        for value in (args.input, args.run, args.output, args.seed)
    )
    if direct == replay:
        parser.error("choose either direct formal-dir output or replay mode")
    if direct:
        if None in (args.formal_dir, args.root, args.json, args.markdown):
            parser.error(
                "direct mode requires --formal-dir, --root, --json, "
                "and --markdown"
            )
        formal_dir = args.formal_dir
        root = args.root
        json_path = args.json
        markdown_path = args.markdown
    else:
        if None in (args.input, args.run, args.output, args.seed):
            parser.error(
                "replay mode requires --input, --run, --output, and --seed"
            )
        run = json.loads(args.run.read_text(encoding="utf-8"))
        formal_dir = args.run.parent
        validate_replay_input(formal_dir, args.input, run)
        root = formal_dir / "artifacts/source"
        if not root.is_dir():
            raise ValueError("replay bundle lacks captured source artifacts")
        json_path = args.output / "summary.json"
        markdown_path = args.output / "report.md"

    result = summarize(formal_dir, root)
    json_path.parent.mkdir(parents=True, exist_ok=True)
    markdown_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    markdown_path.write_text(render_markdown(result), encoding="utf-8")


if __name__ == "__main__":
    main()
