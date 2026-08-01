// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include "rq2_measurement.h"

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char **argv)
{
	char root[] = "/tmp/namei-ext-rq2-transaction-XXXXXX";
	char document[PATH_MAX];
	char payload[PATH_MAX];
	FILE *out = NULL;
	int parent_fd = -1;
	int ret = 0;

	if (argc != 2) {
		fprintf(stderr, "usage: %s RESULT_JSONL\n", argv[0]);
		return 2;
	}
	out = fopen(argv[1], "w");
	if (!out)
		return 2;
	if (!mkdtemp(root) ||
	    afs_rq2_join_path(document, sizeof(document), root,
			      AFS_RQ2_DOCUMENT_ID) ||
	    afs_rq2_join_path(payload, sizeof(payload), document,
			      AFS_RQ2_DOCUMENT_BASENAME) ||
	    mkdir(document, 0700) || afs_rq2_write_payload(payload)) {
		ret = errno ? -errno : -EINVAL;
		goto out;
	}
	parent_fd = open(root, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (parent_fd < 0) {
		ret = -errno;
		goto out;
	}
	ret = afs_rq2_emit_single_oracle(out, "host-filesystem-smoke", "initial",
					 parent_fd, AFS_RQ2_DOCUMENT_ID);
	if (!ret)
		ret = afs_rq2_run_warmup(parent_fd, AFS_RQ2_DOCUMENT_ID, 2);
	if (!ret)
		ret = afs_rq2_emit_process_snapshot(out, "host-filesystem-smoke",
						    "client", "before",
						    getpid());
	if (!ret)
		ret = afs_rq2_run_measured(out, "host-filesystem-smoke",
					    "host-filesystem-smoke", parent_fd,
					    AFS_RQ2_DOCUMENT_ID, 3);
	if (!ret)
		ret = afs_rq2_emit_process_snapshot(out, "host-filesystem-smoke",
						    "client", "after",
						    getpid());
	if (unlink(payload) && !ret)
		ret = -errno;
	if (rmdir(document) && !ret)
		ret = -errno;
	if (!ret)
		ret = afs_rq2_emit_hidden_oracle(out, "host-filesystem-smoke",
						 "after-remove", parent_fd,
						 AFS_RQ2_DOCUMENT_ID);

out:
	if (parent_fd >= 0 && close(parent_fd) && !ret)
		ret = -errno;
	if (rmdir(root) && errno != ENOENT && !ret)
		ret = -errno;
	fprintf(out, "{\"event\":\"application-file-sharing-rq2-smoke\","
		"\"errno\":%d,\"pass\":%s}\n", ret ? -ret : 0,
		ret ? "false" : "true");
	if (fclose(out) && !ret)
		ret = -errno;
	return ret ? 1 : 0;
}
