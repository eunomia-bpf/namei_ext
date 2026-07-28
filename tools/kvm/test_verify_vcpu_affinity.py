#!/usr/bin/env python3

import json
import socket
import threading
import unittest
from unittest import mock

import verify_vcpu_affinity as verify


class VcpuAffinityTests(unittest.TestCase):
    def test_cpu_list_ranges(self):
        self.assertEqual(verify.parse_cpu_list("1,3-5,8"), [1, 3, 4, 5, 8])

    def test_cpu_list_rejects_duplicates(self):
        with self.assertRaises(ValueError):
            verify.parse_cpu_list("1-3,3")

    def test_affinity_requires_distinct_singletons(self):
        observations = [
            {"cpus_allowed": [4]},
            {"cpus_allowed": [5]},
            {"cpus_allowed": [6]},
            {"cpus_allowed": [7]},
        ]
        self.assertTrue(verify.affinity_matches(observations, [4, 5, 6, 7]))
        observations[3]["cpus_allowed"] = [6, 7]
        self.assertFalse(verify.affinity_matches(
            observations, [4, 5, 6, 7]))

    def test_query_vcpus_uses_qmp_handshake(self):
        listener = socket.socket()
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        port = listener.getsockname()[1]

        def serve():
            connection, _ = listener.accept()
            with connection:
                connection.sendall(
                    b'{"QMP":{"version":{},"capabilities":[]}}\n')
                stream = connection.makefile("r", encoding="utf-8")
                capabilities = json.loads(stream.readline())
                self.assertEqual(
                    capabilities["execute"], "qmp_capabilities")
                connection.sendall(b'{"return":{}}\n')
                query = json.loads(stream.readline())
                self.assertEqual(query["execute"], "query-cpus-fast")
                connection.sendall(
                    b'{"return":[{"cpu-index":0,"thread-id":1234}]}\n')
            listener.close()

        server = threading.Thread(target=serve)
        server.start()
        response = verify.query_vcpus("127.0.0.1", port)
        server.join(timeout=2)
        self.assertFalse(server.is_alive())
        self.assertEqual(response, [{"cpu-index": 0, "thread-id": 1234}])

    def test_verify_until_records_timeout(self):
        with mock.patch.object(
                verify, "observe_affinity",
                side_effect=ConnectionRefusedError("not listening")):
            passed, payload = verify.verify_until(
                "127.0.0.1", 1, [4], 0.001, poll_seconds=0)
        self.assertFalse(passed)
        self.assertEqual(payload["status"], "failed")
        self.assertGreater(payload["attempts"], 0)
        self.assertIn("not listening", payload["error"])


if __name__ == "__main__":
    unittest.main()
