/* SPDX-License-Identifier: MIT */
#include <bpf/libbpf.h>
#include <errno.h>
#include <sched.h>
#include <stdio.h>
#include <string.h>

static int attach_lsm(const char *path)
{
	struct bpf_object *obj;
	struct bpf_program *prog;
	struct bpf_link *link;
	long error;

	obj = bpf_object__open_file(path, NULL);
	error = libbpf_get_error(obj);
	if (error) {
		fprintf(stderr, "open LSM object: %s\n", strerror(-error));
		return 1;
	}
	if (bpf_object__load(obj)) {
		fprintf(stderr, "load LSM object failed\n");
		bpf_object__close(obj);
		return 1;
	}
	prog = bpf_object__find_program_by_name(obj, "ebpfos_bprm_check_security");
	if (!prog) {
		fprintf(stderr, "LSM program not found\n");
		bpf_object__close(obj);
		return 1;
	}
	link = bpf_program__attach_lsm(prog);
	error = libbpf_get_error(link);
	if (error) {
		fprintf(stderr, "attach LSM: %s\n", strerror(-error));
		bpf_object__close(obj);
		return 1;
	}
	puts("EBPFOS_BPF_LSM_ATTACH_PASS");
	bpf_link__destroy(link);
	bpf_object__close(obj);
	return 0;
}

static int attach_sched_ext(const char *path)
{
	struct bpf_object *obj;
	struct bpf_map *ops;
	struct bpf_link *link;
	long error;
	int i;

	obj = bpf_object__open_file(path, NULL);
	error = libbpf_get_error(obj);
	if (error) {
		fprintf(stderr, "open sched_ext object: %s\n", strerror(-error));
		return 1;
	}
	if (bpf_object__load(obj)) {
		fprintf(stderr, "load sched_ext object failed\n");
		bpf_object__close(obj);
		return 1;
	}
	ops = bpf_object__find_map_by_name(obj, "ebpfos_sched_ops");
	if (!ops) {
		fprintf(stderr, "sched_ext struct_ops map not found\n");
		bpf_object__close(obj);
		return 1;
	}
	link = bpf_map__attach_struct_ops(ops);
	error = libbpf_get_error(link);
	if (error) {
		fprintf(stderr, "attach sched_ext: %s\n", strerror(-error));
		bpf_object__close(obj);
		return 1;
	}
	for (i = 0; i < 64; i++)
		sched_yield();
	puts("EBPFOS_SCHED_EXT_ATTACH_PASS");
	bpf_link__destroy(link);
	bpf_object__close(obj);
	return 0;
}

int main(int argc, char **argv)
{
	int failed = 0;

	if (argc != 3) {
		fprintf(stderr, "usage: %s LSM_OBJECT SCHED_EXT_OBJECT\n", argv[0]);
		return 2;
	}
	failed |= attach_lsm(argv[1]);
	failed |= attach_sched_ext(argv[2]);
	if (!failed)
		puts("EBPFOS_NATIVE_ATTACH_PASS");
	return failed ? 1 : 0;
}
