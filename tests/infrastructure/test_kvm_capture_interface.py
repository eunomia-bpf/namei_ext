#!/usr/bin/env python3

import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class KvmCaptureInterfaceTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(
            prefix="namei-ext-kvm-capture-"
        )
        self.root = Path(self.temporary.name)
        self.boot = self.root / "boot"
        self.run = self.root / "run"
        self.boot.mkdir()
        self.run.mkdir()
        self.image = self.root / "bzImage"
        self.image.write_text("fixture\n", encoding="utf-8")
        self.argv = self.root / "vng-argv.json"
        self.vng = self.root / "fake-vng"
        self.vng.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "Path(os.environ['NAMEI_EXT_TEST_VNG_ARGV']).write_text(\n"
            "    json.dumps(sys.argv[1:]), encoding='utf-8')\n"
            "print('fake vng stdout')\n"
            "print('fake vng stderr', file=sys.stderr)\n"
            "raise SystemExit(int(os.environ.get('NAMEI_EXT_TEST_VNG_EXIT', 0)))\n",
            encoding="utf-8",
        )
        self.vng.chmod(0o755)

    def tearDown(self):
        self.temporary.cleanup()

    def invoke(
        self, exit_status: int, recorded_run_id: str = "kvm-capture-contract"
    ):
        (self.run / "run.json").write_text(
            json.dumps({"run_id": recorded_run_id, "status": "running"}) + "\n",
            encoding="utf-8",
        )
        environment = os.environ.copy()
        environment["NAMEI_EXT_TEST_VNG_ARGV"] = str(self.argv)
        environment["NAMEI_EXT_TEST_VNG_EXIT"] = str(exit_status)
        return subprocess.run(
            [
                "make",
                "--no-print-directory",
                "-C",
                str(ROOT),
                "__namei_ext_kvm_capture",
                f"VNG={self.vng}",
                "RUN_ID=kvm-capture-contract",
                f"NAMEI_EXT_KVM_CAPTURE_IMAGE={self.image}",
                "NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET=__fixture_guest",
                f"NAMEI_EXT_KVM_CAPTURE_BOOT_DIR={self.boot}",
                f"NAMEI_EXT_KVM_CAPTURE_RUN_DIR={self.run}",
            ],
            check=False,
            env=environment,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

    def test_outer_target_forwards_generated_run_id(self):
        outer_makefile = self.root / "outer.mk"
        outer_makefile.write_text(
            ".PHONY: __contract_outer_kvm_capture\n"
            "__contract_outer_kvm_capture:\n"
            '\tinstall -d "$(TEST_BOOT)" "$(TEST_RUN)"\n'
            "\tprintf '%s\\n' "
            '\'{"run_id":"$(RUN_ID)","status":"running"}\' '
            '> "$(TEST_RUN)/run.json"\n'
            '\t$(MAKE) --no-print-directory -C "$(ROOT_DIR)" '
            "__namei_ext_kvm_capture \\\n"
            '\t\tRUN_ID="$(RUN_ID)" \\\n'
            '\t\tNAMEI_EXT_KVM_CAPTURE_IMAGE="$(TEST_IMAGE)" \\\n'
            "\t\tNAMEI_EXT_KVM_CAPTURE_GUEST_TARGET=__fixture_guest \\\n"
            '\t\tNAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$(TEST_BOOT)" \\\n'
            '\t\tNAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(TEST_RUN)"\n',
            encoding="utf-8",
        )
        environment = os.environ.copy()
        environment["NAMEI_EXT_TEST_VNG_ARGV"] = str(self.argv)
        environment["NAMEI_EXT_TEST_VNG_EXIT"] = "0"
        completed = subprocess.run(
            [
                "make",
                "--no-print-directory",
                "-C",
                str(ROOT),
                "-f",
                "Makefile",
                "-f",
                str(outer_makefile),
                "__contract_outer_kvm_capture",
                f"VNG={self.vng}",
                f"TEST_IMAGE={self.image}",
                f"TEST_BOOT={self.boot}",
                f"TEST_RUN={self.run}",
            ],
            check=False,
            env=environment,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        run_id = json.loads(
            (self.run / "run.json").read_text(encoding="utf-8")
        )["run_id"]
        self.assertRegex(run_id, re.compile(r"^\d{8}T\d{6}Z-[0-9a-f]{8}$"))
        arguments = json.loads(self.argv.read_text(encoding="utf-8"))
        guest = arguments[arguments.index("--exec") + 1]
        self.assertIn(f"RUN_ID={run_id}", guest)

    def test_named_interface_captures_launcher_output(self):
        completed = self.invoke(0)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        arguments = json.loads(self.argv.read_text(encoding="utf-8"))
        self.assertEqual(arguments[arguments.index("--run") + 1], str(self.image))
        guest = arguments[arguments.index("--exec") + 1]
        self.assertIn("__fixture_guest", guest)
        self.assertIn("RUN_ID=kvm-capture-contract", guest)
        self.assertEqual(
            (self.boot / "launcher.stdout.log").read_text(encoding="utf-8"),
            "fake vng stdout\n",
        )
        self.assertEqual(
            (self.boot / "launcher.stderr.log").read_text(encoding="utf-8"),
            "fake vng stderr\n",
        )
        self.assertEqual(
            json.loads((self.run / "run.json").read_text())["status"],
            "running",
        )

    def test_named_interface_marks_launcher_failure(self):
        completed = self.invoke(7)
        self.assertNotEqual(completed.returncode, 0)
        run = json.loads((self.run / "run.json").read_text(encoding="utf-8"))
        self.assertEqual(run["status"], "failed")
        self.assertEqual(run["failure"], "kvm-launch-or-guest-command")
        self.assertIn("failed_at", run)

    def test_named_interface_rejects_mismatched_run_id(self):
        completed = self.invoke(0, recorded_run_id="different-run")
        self.assertNotEqual(completed.returncode, 0)
        self.assertFalse(self.argv.exists())
        run = json.loads((self.run / "run.json").read_text(encoding="utf-8"))
        self.assertEqual(run["status"], "running")

    def test_suites_do_not_use_positional_capture_interface(self):
        for directory in (ROOT / "mk/experiments", ROOT / "mk/benchmarks"):
            for path in directory.glob("*.mk"):
                with self.subTest(path=path.relative_to(ROOT)):
                    source = path.read_text(encoding="utf-8")
                    self.assertNotIn(
                        "$(call NAMEI_EXT_KVM_RUN_CAPTURE",
                        source,
                    )
                    lines = source.splitlines()
                    for index, line in enumerate(lines):
                        if "__namei_ext_kvm_capture" not in line:
                            continue
                        call = "\n".join(lines[index:index + 4])
                        self.assertIn('RUN_ID="$(RUN_ID)"', call)


if __name__ == "__main__":
    unittest.main()
