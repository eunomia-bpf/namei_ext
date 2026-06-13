// SPDX-License-Identifier: GPL-2.0

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/bpf.h>
#include <linux/filter.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

struct attached_policy {
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	bool attached;
};

static void emit_case(FILE *out, const char *name, bool pass, int err,
		      const char *detail)
{
	fprintf(out,
		"{\"event\":\"case\",\"name\":\"%s\",\"pass\":%s,"
		"\"errno\":%d,\"detail\":\"%s\"}\n",
		name, pass ? "true" : "false", err, detail);
	fflush(out);
}

static int write_file(const char *path, const char *value)
{
	int fd;
	ssize_t len;

	fd = open(path, O_CREAT | O_TRUNC | O_WRONLY, 0644);
	if (fd < 0)
		return -errno;
	len = write(fd, value, strlen(value));
	if (close(fd) && len >= 0)
		return -errno;
	if (len < 0)
		return -errno;
	return 0;
}

static int expect_stat(const char *name, const char *path, int want_errno,
		       FILE *out)
{
	struct stat st;
	int ret;

	errno = 0;
	ret = stat(path, &st);
	if (!want_errno && ret == 0) {
		emit_case(out, name, true, 0, "stat matched");
		return 0;
	}
	if (want_errno && ret < 0 && errno == want_errno) {
		emit_case(out, name, true, errno, "stat errno matched");
		return 0;
	}
	emit_case(out, name, false, errno, "stat mismatch");
	return -1;
}

static int expect_open(const char *name, const char *path, int want_errno,
		       FILE *out)
{
	int fd;

	errno = 0;
	fd = open(path, O_RDONLY);
	if (!want_errno && fd >= 0) {
		close(fd);
		emit_case(out, name, true, 0, "open matched");
		return 0;
	}
	if (fd >= 0)
		close(fd);
	if (want_errno && fd < 0 && errno == want_errno) {
		emit_case(out, name, true, errno, "open errno matched");
		return 0;
	}
	emit_case(out, name, false, errno, "open mismatch");
	return -1;
}

static int expect_read_file(const char *name, const char *path,
			    const char *want, FILE *out)
{
	char buf[64] = {};
	ssize_t nread;
	int fd;
	int err;

	errno = 0;
	fd = open(path, O_RDONLY);
	if (fd < 0) {
		emit_case(out, name, false, errno, "open for read failed");
		return -1;
	}
	nread = read(fd, buf, sizeof(buf) - 1);
	err = errno;
	close(fd);
	if (nread < 0) {
		emit_case(out, name, false, err, "read failed");
		return -1;
	}
	if (!strcmp(buf, want)) {
		emit_case(out, name, true, 0, "read content matched");
		return 0;
	}
	emit_case(out, name, false, 0, "read content mismatch");
	return -1;
}

static int expect_access(const char *name, const char *path, int mode,
			 int want_errno, FILE *out)
{
	int ret;

	errno = 0;
	ret = access(path, mode);
	if (!want_errno && ret == 0) {
		emit_case(out, name, true, 0, "access matched");
		return 0;
	}
	if (want_errno && ret < 0 && errno == want_errno) {
		emit_case(out, name, true, errno, "access errno matched");
		return 0;
	}
	emit_case(out, name, false, errno, "access mismatch");
	return -1;
}

static int expect_exec_errno(const char *name, const char *path,
			     int want_errno, FILE *out)
{
	char *const argv[] = { (char *)path, NULL };
	char *const envp[] = { NULL };
	int pipefd[2];
	int status;
	int err = 0;
	ssize_t nread;
	pid_t pid;

	if (pipe(pipefd)) {
		emit_case(out, name, false, errno, "pipe failed");
		return -1;
	}
	if (fcntl(pipefd[1], F_SETFD, FD_CLOEXEC)) {
		err = errno;
		close(pipefd[0]);
		close(pipefd[1]);
		emit_case(out, name, false, err, "fcntl failed");
		return -1;
	}

	pid = fork();
	if (pid < 0) {
		err = errno;
		close(pipefd[0]);
		close(pipefd[1]);
		emit_case(out, name, false, err, "fork failed");
		return -1;
	}

	if (pid == 0) {
		close(pipefd[0]);
		execve(path, argv, envp);
		err = errno;
		if (write(pipefd[1], &err, sizeof(err)) != (ssize_t)sizeof(err))
			_exit(126);
		_exit(127);
	}

	close(pipefd[1]);
	nread = read(pipefd[0], &err, sizeof(err));
	close(pipefd[0]);
	if (waitpid(pid, &status, 0) < 0) {
		emit_case(out, name, false, errno, "waitpid failed");
		return -1;
	}

	if (nread == (ssize_t)sizeof(err) && err == want_errno) {
		emit_case(out, name, true, err, "execve errno matched");
		return 0;
	}
	emit_case(out, name, false, nread == (ssize_t)sizeof(err) ? err : 0,
		  "execve mismatch");
	return -1;
}

static int expect_readdir(const char *path, FILE *out)
{
	bool saw_native = false;
	bool saw_alias = false;
	bool saw_backing = false;
	struct dirent *de;
	DIR *dir;

	errno = 0;
	dir = opendir(path);
	if (!dir) {
		emit_case(out, "readdir_open", false, errno, "opendir failed");
		return -1;
	}

	while ((de = readdir(dir))) {
		if (!strcmp(de->d_name, "native"))
			saw_native = true;
		if (!strcmp(de->d_name, "tool"))
			saw_alias = true;
		if (!strcmp(de->d_name, "tool.real"))
			saw_backing = true;
	}
	if (errno) {
		emit_case(out, "readdir_scan", false, errno, "readdir failed");
		closedir(dir);
		return -1;
	}
	closedir(dir);

	if (saw_native && saw_alias && !saw_backing) {
		emit_case(out, "readdir_view", true, 0,
			  "native and alias listed, backing name rewritten");
		return 0;
	}
	emit_case(out, "readdir_view", false, 0, "unexpected directory view");
	return -1;
}

static unsigned long long ptr_to_u64(const void *ptr)
{
	return (unsigned long long)(uintptr_t)ptr;
}

static int raw_namei_ext_prog_load(enum bpf_attach_type attach_type, int *err_out)
{
	struct bpf_insn insns[] = {
		BPF_MOV64_IMM(BPF_REG_0, BPF_NAMEI_EXT_PASS),
		BPF_EXIT_INSN(),
	};
	char log_buf[8192] = {};
	char license[] = "GPL";
	union bpf_attr attr = {};
	int fd;

	attr.prog_type = BPF_PROG_TYPE_NAMEI_EXT;
	attr.expected_attach_type = attach_type;
	attr.insn_cnt = sizeof(insns) / sizeof(insns[0]);
	attr.insns = ptr_to_u64(insns);
	attr.license = ptr_to_u64(license);
	attr.log_buf = ptr_to_u64(log_buf);
	attr.log_size = sizeof(log_buf);
	attr.log_level = 1;
	memcpy(attr.prog_name, "namei_ext_probe", sizeof("namei_ext_probe"));

	fd = syscall(__NR_bpf, BPF_PROG_LOAD, &attr, sizeof(attr));
	if (fd < 0 && err_out)
		*err_out = errno;
	return fd;
}

static int raw_namei_ext_prog_attach(int prog_fd, int cgroup_fd,
				     unsigned int flags)
{
	union bpf_attr attr = {};

	attr.target_fd = cgroup_fd;
	attr.attach_bpf_fd = prog_fd;
	attr.attach_type = BPF_CGROUP_NAMEI_EXT;
	attr.attach_flags = flags;
	return syscall(__NR_bpf, BPF_PROG_ATTACH, &attr, sizeof(attr));
}

static int raw_namei_ext_prog_detach(int prog_fd, int cgroup_fd,
				     unsigned int flags)
{
	union bpf_attr attr = {};

	attr.target_fd = cgroup_fd;
	attr.attach_bpf_fd = prog_fd;
	attr.attach_type = BPF_CGROUP_NAMEI_EXT;
	attr.attach_flags = flags;
	return syscall(__NR_bpf, BPF_PROG_DETACH, &attr, sizeof(attr));
}

static int expect_attach_flag_rejected(FILE *out, const char *name,
				       int prog_fd, int cgroup_fd,
				       unsigned int flags)
{
	int ret;
	int err;

	errno = 0;
	ret = raw_namei_ext_prog_attach(prog_fd, cgroup_fd, flags);
	err = errno;
	if (ret < 0 && err == EINVAL) {
		emit_case(out, name, true, err, "attach flag rejected");
		return 0;
	}
	if (ret == 0)
		raw_namei_ext_prog_detach(prog_fd, cgroup_fd, 0);
	emit_case(out, name, false, err, "attach flag was not rejected");
	return -1;
}

static int expect_attach_abi(FILE *out, const char *cgroup_path)
{
	union bpf_attr attr = {};
	int cgroup_fd = -1;
	int err = 0;
	int fd;
	int ret;
	int fails = 0;

	fd = raw_namei_ext_prog_load(BPF_CGROUP_NAMEI_EXT, &err);
	if (fd >= 0) {
		emit_case(out, "load_good_attach_type", true, 0,
			  "expected attach type accepted");
		close(fd);
	} else {
		emit_case(out, "load_good_attach_type", false, err,
			  "expected attach type rejected");
		fails++;
	}

	err = 0;
	fd = raw_namei_ext_prog_load(BPF_CGROUP_INET_INGRESS, &err);
	if (fd < 0 && err == EINVAL) {
		emit_case(out, "load_bad_attach_type", true, err,
			  "wrong attach type rejected");
	} else {
		if (fd >= 0)
			close(fd);
		emit_case(out, "load_bad_attach_type", false, err,
			  "wrong attach type was not rejected");
		fails++;
	}

	fd = raw_namei_ext_prog_load(BPF_CGROUP_NAMEI_EXT, &err);
	if (fd < 0) {
		emit_case(out, "multi_attach_rejected", false, err,
			  "probe load failed");
		emit_case(out, "override_attach_rejected", false, err,
			  "probe load failed");
		emit_case(out, "replace_attach_rejected", false, err,
			  "probe load failed");
		emit_case(out, "link_create_rejected", false, err,
			  "probe load failed");
		return fails + 4;
	}

	cgroup_fd = open(cgroup_path, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (cgroup_fd < 0) {
		err = errno;
		close(fd);
		emit_case(out, "multi_attach_rejected", false, err,
			  "open cgroup failed");
		emit_case(out, "override_attach_rejected", false, err,
			  "open cgroup failed");
		emit_case(out, "replace_attach_rejected", false, err,
			  "open cgroup failed");
		emit_case(out, "link_create_rejected", false, err,
			  "open cgroup failed");
		return fails + 4;
	}

	fails += !!expect_attach_flag_rejected(out, "multi_attach_rejected",
					      fd, cgroup_fd,
					      BPF_F_ALLOW_MULTI);
	fails += !!expect_attach_flag_rejected(out, "override_attach_rejected",
					      fd, cgroup_fd,
					      BPF_F_ALLOW_OVERRIDE);
	fails += !!expect_attach_flag_rejected(out, "replace_attach_rejected",
					      fd, cgroup_fd,
					      BPF_F_REPLACE);

	attr.link_create.prog_fd = fd;
	attr.link_create.target_fd = cgroup_fd;
	attr.link_create.attach_type = BPF_CGROUP_NAMEI_EXT;
	errno = 0;
	ret = syscall(__NR_bpf, BPF_LINK_CREATE, &attr, sizeof(attr));
	err = errno;
	if (ret < 0 && err == EOPNOTSUPP) {
		emit_case(out, "link_create_rejected", true, err,
			  "cgroup link attach rejected");
	} else {
		if (ret >= 0)
			close(ret);
		emit_case(out, "link_create_rejected", false, err,
			  "cgroup link attach was not rejected");
		fails++;
	}

	close(cgroup_fd);
	close(fd);
	return fails;
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
	const char *cgroup_path = "/sys/fs/cgroup";
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	char root[] = "/tmp/namei-ext-functional-XXXXXX";
	char native[PATH_MAX];
	char alias[PATH_MAX];
	char backing[PATH_MAX];
	FILE *out;
	int fails = 0;
	int setup_fails = 0;
	int setup_errno = 0;
	int err;

	if (argc < 3 || argc > 4) {
		fprintf(stderr, "usage: %s POLICY_BPF_O RESULT_JSONL [CGROUP]\n",
			argv[0]);
		return 2;
	}
	if (argc == 4)
		cgroup_path = argv[3];

	out = fopen(argv[2], "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}

	fails += expect_attach_abi(out, cgroup_path);

	if (!mkdtemp(root)) {
		emit_case(out, "mkdtemp", false, errno, "mkdtemp failed");
		fclose(out);
		return 1;
	}

	snprintf(native, sizeof(native), "%s/native", root);
	snprintf(alias, sizeof(alias), "%s/tool", root);
	snprintf(backing, sizeof(backing), "%s/tool.real", root);

	err = write_file(native, "native\n");
	if (err) {
		setup_errno = -err;
		setup_fails++;
	}
	err = write_file(backing, "real-tool\n");
	if (err) {
		setup_errno = -err;
		setup_fails++;
	}
	if (chmod(native, 0755)) {
		setup_errno = errno;
		setup_fails++;
	}
	if (chmod(backing, 0755)) {
		setup_errno = errno;
		setup_fails++;
	}
	if (setup_fails) {
		fails += setup_fails;
		emit_case(out, "setup_files", false, setup_errno,
			  "file setup failed");
		goto cleanup;
	}
	emit_case(out, "setup_files", true, 0, "native and backing files created");

	fails += !!expect_stat("alias_before_attach", alias, ENOENT, out);
	fails += !!expect_stat("backing_before_attach", backing, 0, out);

	if (load_and_attach(argv[1], cgroup_path, &policy)) {
		emit_case(out, "attach_policy", false, errno,
			  "load or attach failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "attach_policy", true, 0, "policy attached");

	fails += !!expect_stat("native_stat", native, 0, out);
	fails += !!expect_open("native_open", native, 0, out);
	fails += !!expect_access("native_access", native, X_OK, 0, out);
	fails += !!expect_stat("alias_stat", alias, 0, out);
	fails += !!expect_open("alias_open", alias, 0, out);
	fails += !!expect_access("alias_access", alias, X_OK, 0, out);
	fails += !!expect_read_file("alias_read", alias, "real-tool\n", out);
	fails += !!expect_exec_errno("alias_exec", alias, ENOEXEC, out);
	fails += !!expect_stat("backing_stat", backing, 0, out);
	fails += !!expect_readdir(root, out);

cleanup:
	if (policy.attached) {
		err = destroy_policy(&policy);
		if (err) {
			emit_case(out, "detach_policy", false, -err,
				  "policy detach failed");
			fails++;
		} else {
			emit_case(out, "detach_policy", true, 0,
				  "policy detached");
			fails += !!expect_stat("alias_after_detach", alias,
					       ENOENT, out);
			fails += !!expect_stat("backing_after_detach", backing,
					       0, out);
		}
	}
	unlink(native);
	unlink(backing);
	rmdir(root);
	emit_case(out, "functional_summary", fails == 0, fails,
		  fails ? "functional failures" : "functional passed");
	fclose(out);
	return fails ? 1 : 0;
}
