#!/usr/bin/env python3

import argparse
import json
import xml.etree.ElementTree as ET


FAILED_TEST = "test_choice_get_invalid_choice_message"
FAILED_CLASSNAME = "tests.test_types"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--junit", required=True)
    parser.add_argument("--expected", choices=("base", "completed"), required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    root = ET.parse(args.junit).getroot()
    suite = root if root.tag == "testsuite" else root.find("testsuite")
    if suite is None:
        raise ValueError("JUnit XML has no testsuite")

    tests = int(suite.attrib.get("tests", 0))
    failures = int(suite.attrib.get("failures", 0))
    errors = int(suite.attrib.get("errors", 0))
    skipped = int(suite.attrib.get("skipped", 0))
    failed = []
    for case in suite.iter("testcase"):
        if case.find("failure") is not None or case.find("error") is not None:
            failed.append(
                {
                    "classname": case.attrib.get("classname", ""),
                    "name": case.attrib.get("name", ""),
                    "file": case.attrib.get("file", ""),
                }
            )

    if args.expected == "base":
        expected = (
            tests == 40
            and failures == 1
            and errors == 0
            and skipped == 0
            and len(failed) == 1
            and failed[0]["classname"] == FAILED_CLASSNAME
            and failed[0]["name"] == FAILED_TEST
        )
    else:
        expected = (
            tests == 40
            and failures == 0
            and errors == 0
            and skipped == 0
            and not failed
        )

    record = {
        "schema": "namei_ext.agent_source_task.pytest.v1",
        "expected": args.expected,
        "tests": tests,
        "passed": tests - failures - errors - skipped,
        "failures": failures,
        "errors": errors,
        "skipped": skipped,
        "failed": failed,
        "pass": expected,
    }
    with open(args.output, "w", encoding="utf-8") as output:
        json.dump(record, output, indent=2, sort_keys=True)
        output.write("\n")
    return 0 if expected else 1


if __name__ == "__main__":
    raise SystemExit(main())
