#!/usr/bin/env python3

import unittest
from unittest import mock

import pin_vcpu_affinity as pin


class PinVcpuAffinityTests(unittest.TestCase):
    def test_query_vcpu_records_requires_contiguous_indexes(self):
        with mock.patch.object(
                pin, "query_vcpus",
                return_value=[
                    {"cpu-index": 0, "thread-id": 100},
                    {"cpu-index": 2, "thread-id": 102},
                ]):
            with self.assertRaisesRegex(
                    RuntimeError, "non-contiguous vCPU indexes"):
                pin.query_vcpu_records("127.0.0.1", 3636)

    def test_pin_once_sets_and_reads_back_singletons(self):
        qmp = [
            {"cpu-index": 0, "thread-id": 100},
            {"cpu-index": 1, "thread-id": 101},
        ]
        with mock.patch.object(pin, "query_vcpus", return_value=qmp), \
                mock.patch.object(
                    pin, "read_allowed_cpus",
                    side_effect=[[0, 1], [0, 1], [8], [9]]), \
                mock.patch.object(pin.os, "sched_setaffinity") as set_affinity:
            before, after = pin.pin_once("127.0.0.1", 3636, [8, 9])

        self.assertEqual(
            [record["cpus_allowed"] for record in before],
            [[0, 1], [0, 1]])
        self.assertEqual(
            [record["cpus_allowed"] for record in after], [[8], [9]])
        set_affinity.assert_has_calls([
            mock.call(100, {8}),
            mock.call(101, {9}),
        ])

    def test_pin_once_rejects_wrong_vcpu_count(self):
        with mock.patch.object(
                pin, "query_vcpus",
                return_value=[{"cpu-index": 0, "thread-id": 100}]):
            with self.assertRaisesRegex(RuntimeError, "expected 2"):
                pin.pin_once("127.0.0.1", 3636, [8, 9])

    def test_pin_once_rejects_failed_readback(self):
        with mock.patch.object(
                pin, "query_vcpus",
                return_value=[{"cpu-index": 0, "thread-id": 100}]), \
                mock.patch.object(
                    pin, "read_allowed_cpus",
                    side_effect=[[0, 1], [8, 9]]), \
                mock.patch.object(pin.os, "sched_setaffinity"):
            with self.assertRaisesRegex(
                    pin.PinningError, "after pinning") as raised:
                pin.pin_once("127.0.0.1", 3636, [8])
        self.assertEqual(raised.exception.before[0]["cpus_allowed"], [0, 1])
        self.assertEqual(raised.exception.after[0]["cpus_allowed"], [8, 9])

    def test_pin_until_retries_and_records_mapping(self):
        after = [
            {"vcpu_index": 0, "host_tid": 100, "cpus_allowed": [8]},
        ]
        with mock.patch.object(
                pin, "pin_once",
                side_effect=[ConnectionRefusedError(), ([], after)]), \
                mock.patch.object(pin.time, "sleep"):
            passed, payload = pin.pin_until(
                "127.0.0.1", 3636, [8], 1.0, poll_seconds=0)

        self.assertTrue(passed)
        self.assertEqual(payload["status"], "pinned")
        self.assertEqual(payload["attempts"], 2)
        self.assertEqual(
            payload["expected_vcpu_mapping"],
            [{"vcpu_index": 0, "host_cpu": 8}])
        self.assertEqual(payload["vcpus"], after)

    def test_pin_until_preserves_failed_readback(self):
        before = [
            {"vcpu_index": 0, "host_tid": 100, "cpus_allowed": [0, 1]},
        ]
        after = [
            {"vcpu_index": 0, "host_tid": 100, "cpus_allowed": [8, 9]},
        ]
        failure = pin.PinningError("read-back mismatch", before, after)
        with mock.patch.object(pin, "pin_once", side_effect=failure), \
                mock.patch.object(
                    pin.time, "monotonic", side_effect=[0.0, 0.0, 2.0]), \
                mock.patch.object(pin.time, "sleep"):
            passed, payload = pin.pin_until(
                "127.0.0.1", 3636, [8], 1.0, poll_seconds=0)

        self.assertFalse(passed)
        self.assertEqual(payload["status"], "failed")
        self.assertEqual(payload["last_before"], before)
        self.assertEqual(payload["last_vcpus"], after)
        self.assertEqual(payload["error"], "read-back mismatch")


if __name__ == "__main__":
    unittest.main()
