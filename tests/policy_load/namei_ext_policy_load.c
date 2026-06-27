// SPDX-License-Identifier: GPL-2.0

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/bpf.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

struct attached_policy {
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	bool attached;
};

static void emit(FILE *out, const char *policy, bool pass, int err,
		 const char *detail)
{
	fprintf(out,
		"{\"event\":\"policy-load\",\"policy\":\"%s\",\"pass\":%s,"
		"\"errno\":%d,\"detail\":\"%s\"}\n",
		policy, pass ? "true" : "false", err, detail);
	fflush(out);
}

static int load_and_attach(const char *obj_path, const char *cgroup_path,
			   struct attached_policy *policy)
{
	struct bpf_program *prog;
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	int err;

	obj = bpf_object__open_file(obj_path, NULL);
	err = libbpf_get_error(obj);
	if (err) {
		errno = -err;
		return -1;
	}

	err = bpf_object__load(obj);
	if (err) {
		errno = -err;
		goto err_close_obj;
	}

	prog = bpf_object__next_program(obj, NULL);
	if (!prog) {
		errno = EINVAL;
		goto err_close_obj;
	}

	prog_fd = bpf_program__fd(prog);
	if (prog_fd < 0) {
		errno = EINVAL;
		goto err_close_obj;
	}

	cgroup_fd = open(cgroup_path, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (cgroup_fd < 0)
		goto err_close_obj;

	err = bpf_prog_attach(prog_fd, cgroup_fd, BPF_CGROUP_NAMEI_EXT, 0);
	if (err) {
		errno = -err;
		goto err_close_cgroup;
	}

	policy->obj = obj;
	policy->cgroup_fd = cgroup_fd;
	policy->prog_fd = prog_fd;
	policy->attached = true;
	return 0;

err_close_cgroup:
	close(cgroup_fd);
err_close_obj:
	bpf_object__close(obj);
	return -1;
}

static int destroy_policy(struct attached_policy *policy)
{
	int err = 0;

	if (policy->attached) {
		err = bpf_prog_detach2(policy->prog_fd, policy->cgroup_fd,
				       BPF_CGROUP_NAMEI_EXT);
		policy->attached = false;
	}
	if (policy->cgroup_fd >= 0)
		close(policy->cgroup_fd);
	bpf_object__close(policy->obj);
	policy->obj = NULL;
	policy->cgroup_fd = -1;
	policy->prog_fd = -1;
	return err;
}

int main(int argc, char **argv)
{
	const char *out_path;
	const char *cgroup_path;
	FILE *out;
	int i;
	int failures = 0;

	if (argc < 4) {
		fprintf(stderr,
			"usage: %s OUT_JSONL CGROUP_PATH POLICY_OBJECT...\n",
			argv[0]);
		return 2;
	}

	out_path = argv[1];
	cgroup_path = argv[2];
	out = fopen(out_path, "a");
	if (!out) {
		perror("fopen");
		return 1;
	}

	for (i = 3; i < argc; i++) {
		struct attached_policy policy = {
			.cgroup_fd = -1,
			.prog_fd = -1,
		};
		int err;

		errno = 0;
		if (load_and_attach(argv[i], cgroup_path, &policy)) {
			err = errno;
			emit(out, argv[i], false, err, "load or attach failed");
			failures++;
			break;
		}
		emit(out, argv[i], true, 0, "policy loaded and attached");
		err = destroy_policy(&policy);
		if (err) {
			emit(out, argv[i], false, -err, "detach failed");
			failures++;
			break;
		}
		emit(out, argv[i], true, 0, "policy detached");
	}

	fclose(out);
	return failures ? 1 : 0;
}
