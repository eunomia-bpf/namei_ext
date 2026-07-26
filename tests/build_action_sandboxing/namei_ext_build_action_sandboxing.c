// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <ftw.h>
#include <linux/bpf.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define ACTION_TARGET_ID 1
#define ACTION_A_INPUT "declared-input-A\n"
#define ACTION_B_INPUT "declared-input-B\n"
#define UNDECLARED_INPUT "undeclared-input-must-stay-hidden\n"
#define NAMEI_EXT_NAME_MAX 64

enum build_action_sandboxing_counter {
	BAS_COUNTER_TOTAL = 0,
	BAS_COUNTER_LOOKUP = 1,
	BAS_COUNTER_READDIR = 2,
	BAS_COUNTER_SELECT = 3,
	BAS_COUNTER_HIDE_LOOKUP = 4,
	BAS_COUNTER_HIDE_READDIR = 5,
	BAS_COUNTER_PASS = 6,
};

struct attached_policy {
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	bool attached;
};

struct namei_ext_component_key {
	__u32 event;
	__u32 name_len;
	__u64 cgroup_id;
	__u64 parent_dev;
	__u64 parent_ino;
	__u8 name[NAMEI_EXT_NAME_MAX];
};

struct bazel_action {
	const char *name;
	const char *workspace;
	const char *output_base;
	const char *install_base;
	const char *cgroup;
	const char *stdout_path;
	const char *stderr_path;
	const char *ready_path;
	const char *expected;
	pid_t pid;
};

static void emit_case(FILE *out, const char *name, bool pass, int err,
		      const char *detail)
{
	fprintf(out,
		"{\"event\":\"build-action-sandboxing-case\","
		"\"result_level\":\"kvm_bazel_action_preflight\","
		"\"case\":\"%s\",\"pass\":%s,\"errno\":%d,"
		"\"detail\":\"%s\"}\n",
		name, pass ? "true" : "false", err, detail);
	fflush(out);
}

static void emit_counter(FILE *out, const char *name,
			 unsigned long long value, bool pass)
{
	fprintf(out,
		"{\"event\":\"build-action-sandboxing-policy-counter\","
		"\"result_level\":\"kvm_bazel_action_preflight\","
		"\"counter\":\"%s\",\"value\":%llu,\"pass\":%s}\n",
		name, value, pass ? "true" : "false");
	fflush(out);
}

static int set_path(char *dst, size_t size, const char *dir,
		    const char *name)
{
	int ret = snprintf(dst, size, "%s/%s", dir, name);

	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int write_file(const char *path, const char *value)
{
	size_t len = strlen(value);
	ssize_t nwritten;
	int fd;

	fd = open(path, O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);
	if (fd < 0)
		return -errno;
	nwritten = write(fd, value, len);
	if (nwritten != (ssize_t)len) {
		int saved_errno = errno ? errno : EIO;

		close(fd);
		return -saved_errno;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static bool read_file_matches(const char *path, const char *expected)
{
	char buf[256] = {};
	ssize_t nread;
	int fd;

	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return false;
	nread = read(fd, buf, sizeof(buf) - 1);
	close(fd);
	return nread >= 0 && !strcmp(buf, expected);
}

static int copy_file(const char *source, const char *destination)
{
	char buf[4096];
	ssize_t nread;
	int in_fd;
	int out_fd;

	in_fd = open(source, O_RDONLY | O_CLOEXEC);
	if (in_fd < 0)
		return -errno;
	out_fd = open(destination, O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC,
		      0644);
	if (out_fd < 0) {
		int saved_errno = errno;

		close(in_fd);
		return -saved_errno;
	}
	while ((nread = read(in_fd, buf, sizeof(buf))) > 0) {
		ssize_t offset = 0;

		while (offset < nread) {
			ssize_t nwritten = write(out_fd, buf + offset,
						nread - offset);

			if (nwritten < 0) {
				int saved_errno = errno;

				close(out_fd);
				close(in_fd);
				return -saved_errno;
			}
			offset += nwritten;
		}
	}
	if (nread < 0) {
		int saved_errno = errno;

		close(out_fd);
		close(in_fd);
		return -saved_errno;
	}
	if (close(out_fd)) {
		int saved_errno = errno;

		close(in_fd);
		return -saved_errno;
	}
	if (close(in_fd))
		return -errno;
	return 0;
}

static int move_self_to_cgroup(const char *cgroup_path)
{
	char procs_path[PATH_MAX];
	char pid_buf[32];
	ssize_t nwritten;
	int fd;
	int len;

	if (set_path(procs_path, sizeof(procs_path), cgroup_path,
		     "cgroup.procs"))
		return -ENAMETOOLONG;
	fd = open(procs_path, O_WRONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	len = snprintf(pid_buf, sizeof(pid_buf), "%ld\n", (long)getpid());
	if (len < 0 || (size_t)len >= sizeof(pid_buf)) {
		close(fd);
		return -EINVAL;
	}
	nwritten = write(fd, pid_buf, len);
	if (nwritten != len) {
		int saved_errno = errno ? errno : EIO;

		close(fd);
		return -saved_errno;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static int wait_child(pid_t pid)
{
	int status;

	if (waitpid(pid, &status, 0) != pid)
		return -errno;
	if (!WIFEXITED(status))
		return -ECHILD;
	return WEXITSTATUS(status) ? -EIO : 0;
}

static int register_target_for_cgroup(const char *cgroup_path,
				      const char *target_dir)
{
	pid_t pid = fork();

	if (pid < 0)
		return -errno;
	if (!pid) {
		char register_buf[64];
		ssize_t nwritten;
		int register_fd;
		int target_fd;
		int len;

		if (move_self_to_cgroup(cgroup_path))
			_exit(1);
		target_fd = open(target_dir, O_PATH | O_DIRECTORY | O_CLOEXEC);
		if (target_fd < 0)
			_exit(1);
		register_fd = open("/sys/kernel/debug/namei_ext/register_target",
				   O_WRONLY | O_CLOEXEC);
		if (register_fd < 0) {
			close(target_fd);
			_exit(1);
		}
		len = snprintf(register_buf, sizeof(register_buf), "%u %d\n",
			       ACTION_TARGET_ID, target_fd);
		if (len < 0 || (size_t)len >= sizeof(register_buf)) {
			close(register_fd);
			close(target_fd);
			_exit(1);
		}
		nwritten = write(register_fd, register_buf, len);
		close(register_fd);
		close(target_fd);
		_exit(nwritten == len ? 0 : 1);
	}
	return wait_child(pid);
}

static int clear_targets_for_cgroup(const char *cgroup_path)
{
	pid_t pid = fork();

	if (pid < 0)
		return -errno;
	if (!pid) {
		const char clear[] = "clear\n";
		ssize_t nwritten;
		int register_fd;

		if (move_self_to_cgroup(cgroup_path))
			_exit(1);
		register_fd = open("/sys/kernel/debug/namei_ext/register_target",
				   O_WRONLY | O_CLOEXEC);
		if (register_fd < 0)
			_exit(1);
		nwritten = write(register_fd, clear, strlen(clear));
		close(register_fd);
		_exit(nwritten == (ssize_t)strlen(clear) ? 0 : 1);
	}
	return wait_child(pid);
}

static int cgroup_id_from_path(const char *path, __u64 *id_out)
{
	union {
		__u64 cgroup_id;
		unsigned char bytes[8];
	} id = {};
	struct file_handle *handle;
	struct file_handle *resized;
	size_t size = sizeof(*handle);
	int mount_id = 0;
	int saved_errno;
	int ret;

	handle = calloc(1, size);
	if (!handle)
		return -errno;
	errno = 0;
	ret = name_to_handle_at(AT_FDCWD, path, handle, &mount_id, 0);
	if (ret >= 0 || errno != EOVERFLOW || handle->handle_bytes != 8) {
		saved_errno = errno ? errno : EINVAL;
		free(handle);
		return -saved_errno;
	}
	size += handle->handle_bytes;
	resized = realloc(handle, size);
	if (!resized) {
		saved_errno = errno;
		free(handle);
		return -saved_errno;
	}
	handle = resized;
	ret = name_to_handle_at(AT_FDCWD, path, handle, &mount_id, 0);
	if (ret < 0) {
		saved_errno = errno;
		free(handle);
		return -saved_errno;
	}
	memcpy(id.bytes, handle->f_handle, sizeof(id.bytes));
	free(handle);
	if (!id.cgroup_id)
		return -EINVAL;
	*id_out = id.cgroup_id;
	return 0;
}

static int load_and_attach(const char *obj_path, const char *cgroup_path,
			   struct attached_policy *policy)
{
	struct bpf_program *program;
	struct bpf_object *object;
	int cgroup_fd;
	int program_fd;
	int err;

	object = bpf_object__open_file(obj_path, NULL);
	err = libbpf_get_error(object);
	if (err) {
		errno = -err;
		return -1;
	}
	err = bpf_object__load(object);
	if (err) {
		errno = -err;
		goto close_object;
	}
	program = bpf_object__next_program(object, NULL);
	if (!program) {
		errno = EINVAL;
		goto close_object;
	}
	program_fd = bpf_program__fd(program);
	if (program_fd < 0) {
		errno = EINVAL;
		goto close_object;
	}
	cgroup_fd = open(cgroup_path, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (cgroup_fd < 0)
		goto close_object;
	err = bpf_prog_attach(program_fd, cgroup_fd, BPF_CGROUP_NAMEI_EXT, 0);
	if (err) {
		errno = -err;
		close(cgroup_fd);
		goto close_object;
	}
	policy->obj = object;
	policy->cgroup_fd = cgroup_fd;
	policy->prog_fd = program_fd;
	policy->attached = true;
	return 0;

close_object:
	bpf_object__close(object);
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

static int fill_component_key(struct namei_ext_component_key *key,
			      __u64 cgroup_id, const char *parent,
			      const char *name)
{
	struct stat st;
	size_t name_len = strlen(name);

	if (name_len > sizeof(key->name))
		return -ENAMETOOLONG;
	if (stat(parent, &st))
		return -errno;
	memset(key, 0, sizeof(*key));
	key->name_len = name_len;
	key->cgroup_id = cgroup_id;
	key->parent_dev = st.st_dev;
	key->parent_ino = st.st_ino;
	memcpy(key->name, name, name_len);
	return 0;
}

static int update_component_map(struct attached_policy *policy,
				const char *map_name, __u64 cgroup_id,
				const char *parent, const char *name,
				__u32 value)
{
	struct namei_ext_component_key key;
	struct bpf_map *map;
	int map_fd;
	int ret;

	ret = fill_component_key(&key, cgroup_id, parent, name);
	if (ret)
		return ret;
	map = bpf_object__find_map_by_name(policy->obj, map_name);
	if (!map)
		return -ENOENT;
	map_fd = bpf_map__fd(map);
	if (map_fd < 0)
		return -EINVAL;
	if (bpf_map_update_elem(map_fd, &key, &value, BPF_ANY))
		return -errno;
	return 0;
}

static int check_counter(FILE *out, struct attached_policy *policy,
			 const char *name, __u32 key)
{
	struct bpf_map *map;
	__u64 value = 0;
	int map_fd;
	bool pass;

	map = bpf_object__find_map_by_name(
		policy->obj, "build_action_sandboxing_counters");
	if (!map)
		return -ENOENT;
	map_fd = bpf_map__fd(map);
	if (map_fd < 0)
		return -EINVAL;
	if (bpf_map_lookup_elem(map_fd, &key, &value))
		return -errno;
	pass = value > 0;
	emit_counter(out, name, value, pass);
	return pass ? 0 : -EINVAL;
}

static int write_bazel_workspace(const char *workspace,
				 const char *logical_action,
				 const char *ready_path,
				 const char *release_path)
{
	char build_path[PATH_MAX];
	char workspace_path[PATH_MAX];
	char build[PATH_MAX * 4];
	int len;

	int ret;

	if (mkdir(workspace, 0755))
		return -errno;
	ret = set_path(build_path, sizeof(build_path), workspace,
		       "BUILD.bazel");
	if (!ret)
		ret = set_path(workspace_path, sizeof(workspace_path), workspace,
			       "WORKSPACE.bazel");
	if (ret)
		return ret;
	len = snprintf(
		build, sizeof(build),
		"genrule(\n"
		"    name = \"result\",\n"
		"    outs = [\"result.txt\"],\n"
		"    cmd = \"set -eu; out=\\\"$$PWD/$@\\\"; touch '%s'; "
		"while test ! -e '%s'; do sleep 0.01; done; "
		"cd '%s'; test ! -e private.txt; "
		"test -z \\\"$$(find . -maxdepth 1 -name private.txt "
		"-print -quit)\\\"; cat input.txt > \\\"$$out\\\"\",\n"
		")\n",
		ready_path, release_path, logical_action);
	if (len < 0 || (size_t)len >= sizeof(build))
		return -ENAMETOOLONG;
	ret = write_file(build_path, build);
	if (!ret)
		ret = write_file(
			workspace_path,
			"workspace(name = \"namei_ext_build_action\")\n");
	return ret;
}

static int spawn_bazel_action(const char *bazel,
			      struct bazel_action *action)
{
	pid_t pid = fork();

	if (pid < 0)
		return -errno;
	if (!pid) {
		char output_base[PATH_MAX + 32];
		char install_base[PATH_MAX + 32];
		int stderr_fd;
		int stdout_fd;

		if (move_self_to_cgroup(action->cgroup))
			_exit(120);
		stdout_fd = open(action->stdout_path,
				 O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);
		stderr_fd = open(action->stderr_path,
				 O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);
		if (stdout_fd < 0 || stderr_fd < 0)
			_exit(121);
		if (dup2(stdout_fd, STDOUT_FILENO) < 0 ||
		    dup2(stderr_fd, STDERR_FILENO) < 0)
			_exit(122);
		close(stdout_fd);
		close(stderr_fd);
		if (chdir(action->workspace))
			_exit(123);
		if (snprintf(output_base, sizeof(output_base),
			     "--output_base=%s", action->output_base) >=
		    (int)sizeof(output_base) ||
		    snprintf(install_base, sizeof(install_base),
			     "--install_base=%s", action->install_base) >=
		    (int)sizeof(install_base))
			_exit(124);
		execl(bazel, bazel, "--batch", output_base, install_base,
		      "build", "//:result", "--noenable_bzlmod",
		      "--spawn_strategy=standalone",
		      "--strategy=Genrule=standalone", "--jobs=1",
		      "--color=no", "--curses=no", "--noshow_progress",
		      "--noshow_loading_progress", "--verbose_failures",
		      (char *)NULL);
		_exit(125);
	}
	action->pid = pid;
	return 0;
}

static bool wait_for_both_actions(const char *ready_a, const char *ready_b,
				  unsigned int timeout_ms)
{
	struct timespec delay = {
		.tv_sec = 0,
		.tv_nsec = 10000000,
	};
	unsigned int elapsed = 0;

	while (elapsed < timeout_ms) {
		if (!access(ready_a, F_OK) && !access(ready_b, F_OK))
			return true;
		nanosleep(&delay, NULL);
		elapsed += 10;
	}
	return false;
}

static int remove_callback(const char *path, const struct stat *statbuf,
			   int type, struct FTW *ftw)
{
	(void)statbuf;
	(void)type;
	(void)ftw;
	return remove(path);
}

static void remove_tree(const char *path)
{
	if (path && path[0])
		nftw(path, remove_callback, 64, FTW_DEPTH | FTW_PHYS);
}

int main(int argc, char **argv)
{
	const char *cgroup_root = "/sys/fs/cgroup";
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	char root[] = "/tmp/namei-ext-build-action-XXXXXX";
	char cgroup_a[PATH_MAX] = {};
	char cgroup_b[PATH_MAX] = {};
	char view[PATH_MAX] = {};
	char logical_action[PATH_MAX] = {};
	char target_a[PATH_MAX] = {};
	char target_b[PATH_MAX] = {};
	char input_a[PATH_MAX] = {};
	char input_b[PATH_MAX] = {};
	char private_a[PATH_MAX] = {};
	char private_b[PATH_MAX] = {};
	char workspace_a[PATH_MAX] = {};
	char workspace_b[PATH_MAX] = {};
	char output_base_a[PATH_MAX] = {};
	char output_base_b[PATH_MAX] = {};
	char install_base_a[PATH_MAX] = {};
	char install_base_b[PATH_MAX] = {};
	char ready_a[PATH_MAX] = {};
	char ready_b[PATH_MAX] = {};
	char release[PATH_MAX] = {};
	char bazel_output_a[PATH_MAX] = {};
	char bazel_output_b[PATH_MAX] = {};
	char saved_output_a[PATH_MAX] = {};
	char saved_output_b[PATH_MAX] = {};
	char stdout_a[PATH_MAX] = {};
	char stdout_b[PATH_MAX] = {};
	char stderr_a[PATH_MAX] = {};
	char stderr_b[PATH_MAX] = {};
	struct bazel_action action_a = {};
	struct bazel_action action_b = {};
	struct stat input_a_before;
	struct stat input_b_before;
	struct stat input_a_after;
	struct stat input_b_after;
	__u64 cgroup_id_a = 0;
	__u64 cgroup_id_b = 0;
	FILE *out;
	bool target_a_registered = false;
	bool target_b_registered = false;
	bool both_ready = false;
	int fails = 0;
	int ret;

	if (argc < 5 || argc > 6) {
		fprintf(stderr,
			"usage: %s POLICY_BPF_O RESULT_JSONL BAZEL RESULT_DIR "
			"[CGROUP_ROOT]\n",
			argv[0]);
		return 2;
	}
	if (argc == 6)
		cgroup_root = argv[5];
	out = fopen(argv[2], "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}
	if (!mkdtemp(root)) {
		emit_case(out, "mkdtemp", false, errno, "fixture setup failed");
		fclose(out);
		return 1;
	}
#define BUILD_PATH(dst, dir, name) \
	do { \
		if (set_path((dst), sizeof(dst), (dir), (name))) { \
			emit_case(out, "paths", false, ENAMETOOLONG, \
				  "path construction failed"); \
			fails++; \
			goto cleanup; \
		} \
	} while (0)
	if (snprintf(cgroup_a, sizeof(cgroup_a),
		     "%s/namei-ext-build-action-a-%ld", cgroup_root,
		     (long)getpid()) >= (int)sizeof(cgroup_a) ||
	    snprintf(cgroup_b, sizeof(cgroup_b),
		     "%s/namei-ext-build-action-b-%ld", cgroup_root,
		     (long)getpid()) >= (int)sizeof(cgroup_b)) {
		emit_case(out, "cgroup_paths", false, ENAMETOOLONG,
			  "cgroup path construction failed");
		fails++;
		goto cleanup;
	}
	BUILD_PATH(view, root, "view");
	BUILD_PATH(logical_action, view, "action");
	BUILD_PATH(target_a, root, "target-a");
	BUILD_PATH(target_b, root, "target-b");
	BUILD_PATH(input_a, target_a, "input.txt");
	BUILD_PATH(input_b, target_b, "input.txt");
	BUILD_PATH(private_a, target_a, "private.txt");
	BUILD_PATH(private_b, target_b, "private.txt");
	BUILD_PATH(workspace_a, root, "workspace-a");
	BUILD_PATH(workspace_b, root, "workspace-b");
	BUILD_PATH(output_base_a, root, "output-base-a");
	BUILD_PATH(output_base_b, root, "output-base-b");
	BUILD_PATH(install_base_a, root, "install-base-a");
	BUILD_PATH(install_base_b, root, "install-base-b");
	BUILD_PATH(ready_a, root, "action-a.ready");
	BUILD_PATH(ready_b, root, "action-b.ready");
	BUILD_PATH(release, root, "actions.release");
	BUILD_PATH(bazel_output_a, workspace_a, "bazel-bin/result.txt");
	BUILD_PATH(bazel_output_b, workspace_b, "bazel-bin/result.txt");
	BUILD_PATH(saved_output_a, argv[4], "action-a-output.txt");
	BUILD_PATH(saved_output_b, argv[4], "action-b-output.txt");
	BUILD_PATH(stdout_a, argv[4], "stdout-bazel-action-a.log");
	BUILD_PATH(stdout_b, argv[4], "stdout-bazel-action-b.log");
	BUILD_PATH(stderr_a, argv[4], "stderr-bazel-action-a.log");
	BUILD_PATH(stderr_b, argv[4], "stderr-bazel-action-b.log");
#undef BUILD_PATH

	if (mkdir(view, 0755) || mkdir(logical_action, 0755) ||
	    mkdir(target_a, 0755) || mkdir(target_b, 0755) ||
	    write_file(input_a, ACTION_A_INPUT) ||
	    write_file(input_b, ACTION_B_INPUT) ||
	    write_file(private_a, UNDECLARED_INPUT) ||
	    write_file(private_b, UNDECLARED_INPUT) ||
	    stat(input_a, &input_a_before) || stat(input_b, &input_b_before)) {
		emit_case(out, "fixture", false, errno,
			  "declared and undeclared input fixture failed");
		fails++;
		goto cleanup;
	}
	ret = write_bazel_workspace(workspace_a, logical_action, ready_a,
				    release);
	if (!ret)
		ret = write_bazel_workspace(workspace_b, logical_action, ready_b,
					    release);
	emit_case(out, "bazel_workspaces", !ret, ret ? -ret : 0,
		  "two real Bazel genrule workspaces created");
	fails += !!ret;
	if (ret)
		goto cleanup;

	if (mkdir(cgroup_a, 0755) || mkdir(cgroup_b, 0755)) {
		emit_case(out, "action_cgroups", false, errno,
			  "per-action cgroup setup failed");
		fails++;
		goto cleanup;
	}
	ret = cgroup_id_from_path(cgroup_a, &cgroup_id_a);
	if (!ret)
		ret = cgroup_id_from_path(cgroup_b, &cgroup_id_b);
	emit_case(out, "action_identities", !ret, ret ? -ret : 0,
		  "two action identities derived from cgroup v2");
	fails += !!ret;
	if (ret)
		goto cleanup;

	ret = register_target_for_cgroup(cgroup_a, target_a);
	if (!ret)
		target_a_registered = true;
	if (!ret)
		ret = register_target_for_cgroup(cgroup_b, target_b);
	if (!ret)
		target_b_registered = true;
	emit_case(out, "register_declared_input_roots", !ret,
		  ret ? -ret : 0,
		  "each action registered its own existing input root");
	fails += !!ret;
	if (ret)
		goto cleanup;

	if (load_and_attach(argv[1], cgroup_root, &policy)) {
		emit_case(out, "attach_policy", false, errno,
			  "load or attach failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "attach_policy", true, 0,
		  "policy attached through cgroup/namei_ext");

	ret = update_component_map(&policy, "build_action_views",
				   cgroup_id_a, view, "action",
				   ACTION_TARGET_ID);
	if (!ret)
		ret = update_component_map(&policy, "build_action_views",
					   cgroup_id_b, view, "action",
					   ACTION_TARGET_ID);
	if (!ret)
		ret = update_component_map(&policy,
					   "build_action_hidden_inputs",
					   cgroup_id_a, target_a,
					   "private.txt", 1);
	if (!ret)
		ret = update_component_map(&policy,
					   "build_action_hidden_inputs",
					   cgroup_id_b, target_b,
					   "private.txt", 1);
	emit_case(out, "install_action_views", !ret, ret ? -ret : 0,
		  "declared roots selected and undeclared paths hidden per action");
	fails += !!ret;
	if (ret)
		goto cleanup;

	action_a = (struct bazel_action){
		.name = "action-a",
		.workspace = workspace_a,
		.output_base = output_base_a,
		.install_base = install_base_a,
		.cgroup = cgroup_a,
		.stdout_path = stdout_a,
		.stderr_path = stderr_a,
		.ready_path = ready_a,
		.expected = ACTION_A_INPUT,
		.pid = -1,
	};
	action_b = (struct bazel_action){
		.name = "action-b",
		.workspace = workspace_b,
		.output_base = output_base_b,
		.install_base = install_base_b,
		.cgroup = cgroup_b,
		.stdout_path = stdout_b,
		.stderr_path = stderr_b,
		.ready_path = ready_b,
		.expected = ACTION_B_INPUT,
		.pid = -1,
	};
	ret = spawn_bazel_action(argv[3], &action_a);
	if (!ret)
		ret = spawn_bazel_action(argv[3], &action_b);
	emit_case(out, "start_concurrent_bazel_actions", !ret,
		  ret ? -ret : 0,
		  "two Bazel builds started in separate action cgroups");
	fails += !!ret;
	if (ret)
		goto release_and_wait;

	both_ready = wait_for_both_actions(ready_a, ready_b, 30000);
	emit_case(out, "concurrent_action_overlap", both_ready,
		  both_ready ? 0 : ETIMEDOUT,
		  "both Bazel genrules reached the same-path lookup phase");
	fails += !both_ready;

release_and_wait:
	ret = write_file(release, "release\n");
	if (ret) {
		emit_case(out, "release_actions", false, -ret,
			  "action release marker failed");
		fails++;
	}
	if (action_a.pid > 0) {
		ret = wait_child(action_a.pid);
		emit_case(out, "bazel_action_a", !ret, ret ? -ret : 0,
			  "Bazel action A completed with declared input only");
		fails += !!ret;
		action_a.pid = -1;
	}
	if (action_b.pid > 0) {
		ret = wait_child(action_b.pid);
		emit_case(out, "bazel_action_b", !ret, ret ? -ret : 0,
			  "Bazel action B completed with declared input only");
		fails += !!ret;
		action_b.pid = -1;
	}

	ret = read_file_matches(bazel_output_a, ACTION_A_INPUT) ? 0 : -EIO;
	emit_case(out, "action_a_output_oracle", !ret, ret ? -ret : 0,
		  "same logical pathname produced action A's declared bytes");
	fails += !!ret;
	if (!ret) {
		ret = copy_file(bazel_output_a, saved_output_a);
		if (ret)
			fails++;
	}
	ret = read_file_matches(bazel_output_b, ACTION_B_INPUT) ? 0 : -EIO;
	emit_case(out, "action_b_output_oracle", !ret, ret ? -ret : 0,
		  "same logical pathname produced action B's declared bytes");
	fails += !!ret;
	if (!ret) {
		ret = copy_file(bazel_output_b, saved_output_b);
		if (ret)
			fails++;
	}
	ret = stat(input_a, &input_a_after) || stat(input_b, &input_b_after) ?
		      -errno :
		      0;
	if (!ret &&
	    (input_a_before.st_dev != input_a_after.st_dev ||
	     input_a_before.st_ino != input_a_after.st_ino ||
	     input_a_before.st_mode != input_a_after.st_mode ||
	     input_a_before.st_size != input_a_after.st_size ||
	     input_b_before.st_dev != input_b_after.st_dev ||
	     input_b_before.st_ino != input_b_after.st_ino ||
	     input_b_before.st_mode != input_b_after.st_mode ||
	     input_b_before.st_size != input_b_after.st_size ||
	     !read_file_matches(private_a, UNDECLARED_INPUT) ||
	     !read_file_matches(private_b, UNDECLARED_INPUT)))
		ret = -EIO;
	emit_case(out, "lower_inputs_unchanged", !ret, ret ? -ret : 0,
		  "lower filesystem retained declared and undeclared objects");
	fails += !!ret;

	fails += !!check_counter(out, &policy, "lookup",
				 BAS_COUNTER_LOOKUP);
	fails += !!check_counter(out, &policy, "readdir",
				 BAS_COUNTER_READDIR);
	fails += !!check_counter(out, &policy, "select",
				 BAS_COUNTER_SELECT);
	fails += !!check_counter(out, &policy, "hide_lookup",
				 BAS_COUNTER_HIDE_LOOKUP);
	fails += !!check_counter(out, &policy, "hide_readdir",
				 BAS_COUNTER_HIDE_READDIR);

cleanup:
	if (action_a.pid > 0)
		fails += !!wait_child(action_a.pid);
	if (action_b.pid > 0)
		fails += !!wait_child(action_b.pid);
	if (policy.attached) {
		ret = destroy_policy(&policy);
		emit_case(out, "detach_policy", !ret, ret ? -ret : 0,
			  "policy detached");
		fails += !!ret;
	}
	if (target_a_registered) {
		ret = clear_targets_for_cgroup(cgroup_a);
		emit_case(out, "clear_action_a_target", !ret,
			  ret ? -ret : 0, "action A target registry cleared");
		fails += !!ret;
	}
	if (target_b_registered) {
		ret = clear_targets_for_cgroup(cgroup_b);
		emit_case(out, "clear_action_b_target", !ret,
			  ret ? -ret : 0, "action B target registry cleared");
		fails += !!ret;
	}
	if (cgroup_a[0] && rmdir(cgroup_a) && errno != ENOENT)
		fails++;
	if (cgroup_b[0] && rmdir(cgroup_b) && errno != ENOENT)
		fails++;
	fprintf(out,
		"{\"event\":\"build-action-sandboxing-summary\","
		"\"result_level\":\"kvm_bazel_action_preflight\","
		"\"workload\":\"build-action-sandboxing\","
		"\"source_system\":\"bazel-action-sandboxing\","
		"\"bazel_actions\":2,\"concurrent\":%s,"
		"\"pass\":%s,\"failures\":%d}\n",
		both_ready ? "true" : "false",
		fails ? "false" : "true", fails);
	fclose(out);
	remove_tree(root);
	return fails ? 1 : 0;
}
