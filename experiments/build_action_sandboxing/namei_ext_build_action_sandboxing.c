// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <limits.h>
#include <namei_ext_harness.h>
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
#define RESULT_LEVEL "kvm_bazel_action_rq1"

enum build_action_sandboxing_counter {
	BAS_COUNTER_TOTAL = 0,
	BAS_COUNTER_LOOKUP = 1,
	BAS_COUNTER_READDIR = 2,
	BAS_COUNTER_SELECT = 3,
	BAS_COUNTER_ALLOW_LOOKUP = 4,
	BAS_COUNTER_ALLOW_READDIR = 5,
	BAS_COUNTER_HIDE_LOOKUP = 6,
	BAS_COUNTER_HIDE_READDIR = 7,
	BAS_COUNTER_PASS = 8,
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

struct action_view_observation {
	struct stat logical_input;
	struct stat lower_input;
	int logical_errno;
	int lower_errno;
	int private_errno;
	int move_errno;
};

static void emit_case(FILE *out, const char *name, bool pass, int err,
		      const char *detail)
{
	fprintf(out,
		"{\"event\":\"build-action-sandboxing-case\","
		"\"result_level\":\"" RESULT_LEVEL "\","
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
		"\"result_level\":\"" RESULT_LEVEL "\","
		"\"counter\":\"%s\",\"value\":%llu,\"pass\":%s}\n",
		name, value, pass ? "true" : "false");
	fflush(out);
}

static int check_counter(FILE *out,
			 struct namei_ext_harness_policy *policy,
			 const char *name, uint32_t key)
{
	uint64_t value = 0;
	bool pass;
	int ret;

	ret = namei_ext_policy_counter(
		policy, "build_action_sandboxing_counters", key, &value);
	if (ret)
		return ret;
	pass = value > 0;
	emit_counter(out, name, value, pass);
	return pass ? 0 : -EINVAL;
}

static int write_exact(int fd, const void *buf, size_t len)
{
	const char *cursor = buf;

	while (len) {
		ssize_t written = write(fd, cursor, len);

		if (written < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		cursor += written;
		len -= (size_t)written;
	}
	return 0;
}

static int read_exact(int fd, void *buf, size_t len)
{
	char *cursor = buf;

	while (len) {
		ssize_t bytes = read(fd, cursor, len);

		if (bytes < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		if (!bytes)
			return -EIO;
		cursor += bytes;
		len -= (size_t)bytes;
	}
	return 0;
}

static int observe_action_view(const char *cgroup, const char *logical_input,
			       const char *lower_input,
			       const char *logical_private,
			       struct action_view_observation *observation)
{
	int pipefd[2];
	pid_t pid;
	int ret;

	memset(observation, 0, sizeof(*observation));
	if (pipe2(pipefd, O_CLOEXEC))
		return -errno;
	pid = fork();
	if (pid < 0) {
		ret = -errno;
		close(pipefd[0]);
		close(pipefd[1]);
		return ret;
	}
	if (!pid) {
		struct action_view_observation child = {};
		struct stat private_stat;
		int move_ret;

		close(pipefd[0]);
		move_ret = namei_ext_move_self_to_cgroup(cgroup);
		if (move_ret)
			child.move_errno = -move_ret;
		if (!child.move_errno && stat(logical_input, &child.logical_input))
			child.logical_errno = errno;
		if (!child.move_errno && stat(lower_input, &child.lower_input))
			child.lower_errno = errno;
		if (!child.move_errno) {
			if (!stat(logical_private, &private_stat))
				child.private_errno = 0;
			else
				child.private_errno = errno;
		}
		ret = write_exact(pipefd[1], &child, sizeof(child));
		close(pipefd[1]);
		_exit(ret ? 126 : 0);
	}
	close(pipefd[1]);
	ret = read_exact(pipefd[0], observation, sizeof(*observation));
	close(pipefd[0]);
	if (namei_ext_wait_child(pid) && !ret)
		ret = -ECHILD;
	return ret;
}

static bool same_object_stat(const struct stat *before,
			     const struct stat *after)
{
	return before->st_dev == after->st_dev &&
	       before->st_ino == after->st_ino &&
	       before->st_mode == after->st_mode &&
	       before->st_size == after->st_size;
}

static void emit_action_view(FILE *out, const char *action,
			     const struct action_view_observation *observation,
			     int observation_ret)
{
	bool pass = !observation_ret && !observation->move_errno &&
		    !observation->logical_errno && !observation->lower_errno &&
		    observation->private_errno == ENOENT &&
		    observation->logical_input.st_dev ==
			    observation->lower_input.st_dev &&
		    observation->logical_input.st_ino ==
			    observation->lower_input.st_ino;

	fprintf(out,
		"{\"event\":\"build-action-sandboxing-view\","
		"\"result_level\":\"" RESULT_LEVEL "\","
		"\"action\":\"%s\",\"observation_errno\":%d,"
		"\"move_errno\":%d,\"logical_errno\":%d,"
		"\"lower_errno\":%d,\"private_errno\":%d,"
		"\"logical_dev\":\"%" PRIuMAX "\","
		"\"logical_ino\":\"%" PRIuMAX "\","
		"\"lower_dev\":\"%" PRIuMAX "\","
		"\"lower_ino\":\"%" PRIuMAX "\",\"pass\":%s}\n",
		action, observation_ret ? -observation_ret : 0,
		observation->move_errno, observation->logical_errno,
		observation->lower_errno, observation->private_errno,
		(uintmax_t)observation->logical_input.st_dev,
		(uintmax_t)observation->logical_input.st_ino,
		(uintmax_t)observation->lower_input.st_dev,
		(uintmax_t)observation->lower_input.st_ino,
		pass ? "true" : "false");
	fflush(out);
}

static bool emit_lower_object(FILE *out, const char *object,
			      const struct stat *before,
			      const struct stat *after, int after_errno,
			      bool bytes_expected)
{
	bool metadata_unchanged = !after_errno &&
				  same_object_stat(before, after);
	bool pass = metadata_unchanged && bytes_expected;

	fprintf(out,
		"{\"event\":\"build-action-sandboxing-lower-object\","
		"\"result_level\":\"" RESULT_LEVEL "\","
		"\"object\":\"%s\",\"after_errno\":%d,"
		"\"before_dev\":\"%" PRIuMAX "\","
		"\"before_ino\":\"%" PRIuMAX "\","
		"\"before_mode\":\"%" PRIoMAX "\","
		"\"before_size\":\"%" PRIdMAX "\","
		"\"after_dev\":\"%" PRIuMAX "\","
		"\"after_ino\":\"%" PRIuMAX "\","
		"\"after_mode\":\"%" PRIoMAX "\","
		"\"after_size\":\"%" PRIdMAX "\","
		"\"metadata_unchanged\":%s,\"bytes_expected\":%s,"
		"\"pass\":%s}\n",
		object, after_errno,
		(uintmax_t)before->st_dev, (uintmax_t)before->st_ino,
		(uintmax_t)before->st_mode, (intmax_t)before->st_size,
		(uintmax_t)after->st_dev, (uintmax_t)after->st_ino,
		(uintmax_t)after->st_mode, (intmax_t)after->st_size,
		metadata_unchanged ? "true" : "false",
		bytes_expected ? "true" : "false",
		pass ? "true" : "false");
	fflush(out);
	return pass;
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
	ret = namei_ext_path_join(build_path, sizeof(build_path), workspace,
				  "BUILD.bazel");
	if (!ret)
		ret = namei_ext_path_join(workspace_path,
					  sizeof(workspace_path), workspace,
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
	ret = namei_ext_write_text(build_path, build);
	if (!ret)
		ret = namei_ext_write_text(
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

		if (namei_ext_move_self_to_cgroup(action->cgroup))
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

int main(int argc, char **argv)
{
	const char *cgroup_root = "/sys/fs/cgroup";
	struct namei_ext_harness_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	char root[] = "/tmp/namei-ext-build-action-XXXXXX";
	char cgroup_a[PATH_MAX] = {};
	char cgroup_b[PATH_MAX] = {};
	char view[PATH_MAX] = {};
	char logical_action[PATH_MAX] = {};
	char logical_input[PATH_MAX] = {};
	char logical_private[PATH_MAX] = {};
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
	char saved_input_a[PATH_MAX] = {};
	char saved_input_b[PATH_MAX] = {};
	char saved_private_a[PATH_MAX] = {};
	char saved_private_b[PATH_MAX] = {};
	char stdout_a[PATH_MAX] = {};
	char stdout_b[PATH_MAX] = {};
	char stderr_a[PATH_MAX] = {};
	char stderr_b[PATH_MAX] = {};
	struct bazel_action action_a = {};
	struct bazel_action action_b = {};
	struct stat input_a_before = {};
	struct stat input_b_before = {};
	struct stat private_a_before = {};
	struct stat private_b_before = {};
	struct stat input_a_after = {};
	struct stat input_b_after = {};
	struct stat private_a_after = {};
	struct stat private_b_after = {};
	struct action_view_observation view_a_observation = {};
	struct action_view_observation view_b_observation = {};
	uint64_t cgroup_id_a = 0;
	uint64_t cgroup_id_b = 0;
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
		if (namei_ext_path_join((dst), sizeof(dst), (dir), (name))) { \
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
	BUILD_PATH(logical_input, logical_action, "input.txt");
	BUILD_PATH(logical_private, logical_action, "private.txt");
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
	BUILD_PATH(saved_input_a, argv[4], "lower-action-a-input.txt");
	BUILD_PATH(saved_input_b, argv[4], "lower-action-b-input.txt");
	BUILD_PATH(saved_private_a, argv[4], "lower-action-a-private.txt");
	BUILD_PATH(saved_private_b, argv[4], "lower-action-b-private.txt");
	BUILD_PATH(stdout_a, argv[4], "stdout-bazel-action-a.log");
	BUILD_PATH(stdout_b, argv[4], "stdout-bazel-action-b.log");
	BUILD_PATH(stderr_a, argv[4], "stderr-bazel-action-a.log");
	BUILD_PATH(stderr_b, argv[4], "stderr-bazel-action-b.log");
#undef BUILD_PATH

	if (mkdir(view, 0755) || mkdir(logical_action, 0755) ||
	    mkdir(target_a, 0755) || mkdir(target_b, 0755) ||
	    namei_ext_write_text(input_a, ACTION_A_INPUT) ||
	    namei_ext_write_text(input_b, ACTION_B_INPUT) ||
	    namei_ext_write_text(private_a, UNDECLARED_INPUT) ||
	    namei_ext_write_text(private_b, UNDECLARED_INPUT) ||
	    stat(input_a, &input_a_before) || stat(input_b, &input_b_before) ||
	    stat(private_a, &private_a_before) ||
	    stat(private_b, &private_b_before)) {
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
	ret = namei_ext_cgroup_id(cgroup_a, &cgroup_id_a);
	if (!ret)
		ret = namei_ext_cgroup_id(cgroup_b, &cgroup_id_b);
	emit_case(out, "action_identities", !ret, ret ? -ret : 0,
		  "two action identities derived from cgroup v2");
	fails += !!ret;
	if (ret)
		goto cleanup;

	ret = namei_ext_register_target(cgroup_a, target_a, ACTION_TARGET_ID);
	if (!ret)
		target_a_registered = true;
	if (!ret)
		ret = namei_ext_register_target(cgroup_b, target_b,
					       ACTION_TARGET_ID);
	if (!ret)
		target_b_registered = true;
	emit_case(out, "register_declared_input_roots", !ret,
		  ret ? -ret : 0,
		  "each action registered its own existing input root");
	fails += !!ret;
	if (ret)
		goto cleanup;

	if (namei_ext_policy_load_attach(argv[1], cgroup_root, &policy)) {
		emit_case(out, "attach_policy", false, errno,
			  "load or attach failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "attach_policy", true, 0,
		  "policy attached through cgroup/namei_ext");

	ret = namei_ext_component_map_update(
		&policy, "build_action_views", cgroup_id_a, view, "action",
		ACTION_TARGET_ID);
	if (!ret)
		ret = namei_ext_component_map_update(
			&policy, "build_action_views", cgroup_id_b, view,
			"action", ACTION_TARGET_ID);
	if (!ret)
		ret = namei_ext_component_map_update(
			&policy, "build_action_roots", cgroup_id_a,
			target_a, "", 1);
	if (!ret)
		ret = namei_ext_component_map_update(
			&policy, "build_action_roots", cgroup_id_b,
			target_b, "", 1);
	if (!ret)
		ret = namei_ext_component_map_update(
			&policy, "build_action_declared_inputs", cgroup_id_a,
			target_a, "input.txt", 1);
	if (!ret)
		ret = namei_ext_component_map_update(
			&policy, "build_action_declared_inputs", cgroup_id_b,
			target_b, "input.txt", 1);
	emit_case(out, "install_action_views", !ret, ret ? -ret : 0,
		  "declared roots selected and allowlisted per action");
	fails += !!ret;
	if (ret)
		goto cleanup;

	ret = observe_action_view(cgroup_a, logical_input, input_a,
				  logical_private, &view_a_observation);
	emit_action_view(out, "action-a", &view_a_observation, ret);
	fails += !!ret || view_a_observation.move_errno ||
		 view_a_observation.logical_errno ||
		 view_a_observation.lower_errno ||
		 view_a_observation.private_errno != ENOENT ||
		 view_a_observation.logical_input.st_dev !=
			 view_a_observation.lower_input.st_dev ||
		 view_a_observation.logical_input.st_ino !=
			 view_a_observation.lower_input.st_ino;
	ret = observe_action_view(cgroup_b, logical_input, input_b,
				  logical_private, &view_b_observation);
	emit_action_view(out, "action-b", &view_b_observation, ret);
	fails += !!ret || view_b_observation.move_errno ||
		 view_b_observation.logical_errno ||
		 view_b_observation.lower_errno ||
		 view_b_observation.private_errno != ENOENT ||
		 view_b_observation.logical_input.st_dev !=
			 view_b_observation.lower_input.st_dev ||
		 view_b_observation.logical_input.st_ino !=
			 view_b_observation.lower_input.st_ino;

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
	ret = namei_ext_write_text(release, "release\n");
	if (ret) {
		emit_case(out, "release_actions", false, -ret,
			  "action release marker failed");
		fails++;
	}
	if (action_a.pid > 0) {
		ret = namei_ext_wait_child(action_a.pid);
		emit_case(out, "bazel_action_a", !ret, ret ? -ret : 0,
			  "Bazel action A completed with declared input only");
		fails += !!ret;
		action_a.pid = -1;
	}
	if (action_b.pid > 0) {
		ret = namei_ext_wait_child(action_b.pid);
		emit_case(out, "bazel_action_b", !ret, ret ? -ret : 0,
			  "Bazel action B completed with declared input only");
		fails += !!ret;
		action_b.pid = -1;
	}

	ret = namei_ext_read_text_equals(bazel_output_a, ACTION_A_INPUT) ?
		      namei_ext_copy_file(bazel_output_a, saved_output_a) :
		      -EIO;
	emit_case(out, "action_a_output_oracle", !ret, ret ? -ret : 0,
		  "same logical pathname produced action A's declared bytes");
	fails += !!ret;
	ret = namei_ext_read_text_equals(bazel_output_b, ACTION_B_INPUT) ?
		      namei_ext_copy_file(bazel_output_b, saved_output_b) :
		      -EIO;
	emit_case(out, "action_b_output_oracle", !ret, ret ? -ret : 0,
		  "same logical pathname produced action B's declared bytes");
	fails += !!ret;

	ret = stat(input_a, &input_a_after) ? errno : 0;
	fails += !emit_lower_object(
		out, "action-a-input", &input_a_before, &input_a_after, ret,
		namei_ext_read_text_equals(input_a, ACTION_A_INPUT));
	ret = stat(input_b, &input_b_after) ? errno : 0;
	fails += !emit_lower_object(
		out, "action-b-input", &input_b_before, &input_b_after, ret,
		namei_ext_read_text_equals(input_b, ACTION_B_INPUT));
	ret = stat(private_a, &private_a_after) ? errno : 0;
	fails += !emit_lower_object(
		out, "action-a-private", &private_a_before, &private_a_after,
		ret, namei_ext_read_text_equals(private_a, UNDECLARED_INPUT));
	ret = stat(private_b, &private_b_after) ? errno : 0;
	fails += !emit_lower_object(
		out, "action-b-private", &private_b_before, &private_b_after,
		ret, namei_ext_read_text_equals(private_b, UNDECLARED_INPUT));
	ret = namei_ext_copy_file(input_a, saved_input_a);
	if (!ret)
		ret = namei_ext_copy_file(input_b, saved_input_b);
	if (!ret)
		ret = namei_ext_copy_file(private_a, saved_private_a);
	if (!ret)
		ret = namei_ext_copy_file(private_b, saved_private_b);
	emit_case(out, "preserve_raw_objects", !ret, ret ? -ret : 0,
		  "four lower objects copied for independent byte checks");
	fails += !!ret;
	emit_case(out, "lower_inputs_unchanged",
		  same_object_stat(&input_a_before, &input_a_after) &&
			  same_object_stat(&input_b_before, &input_b_after) &&
			  same_object_stat(&private_a_before,
					   &private_a_after) &&
			  same_object_stat(&private_b_before,
					   &private_b_after) &&
			  namei_ext_read_text_equals(input_a,
						     ACTION_A_INPUT) &&
			  namei_ext_read_text_equals(input_b,
						     ACTION_B_INPUT) &&
			  namei_ext_read_text_equals(private_a,
						     UNDECLARED_INPUT) &&
			  namei_ext_read_text_equals(private_b,
						     UNDECLARED_INPUT),
		  0,
		  "lower filesystem retained declared and undeclared objects");

	fails += !!check_counter(out, &policy, "lookup",
				 BAS_COUNTER_LOOKUP);
	fails += !!check_counter(out, &policy, "readdir",
				 BAS_COUNTER_READDIR);
	fails += !!check_counter(out, &policy, "select",
				 BAS_COUNTER_SELECT);
	fails += !!check_counter(out, &policy, "allow_lookup",
				 BAS_COUNTER_ALLOW_LOOKUP);
	fails += !!check_counter(out, &policy, "allow_readdir",
				 BAS_COUNTER_ALLOW_READDIR);
	fails += !!check_counter(out, &policy, "hide_lookup",
				 BAS_COUNTER_HIDE_LOOKUP);
	fails += !!check_counter(out, &policy, "hide_readdir",
				 BAS_COUNTER_HIDE_READDIR);

cleanup:
	if (action_a.pid > 0)
		fails += !!namei_ext_wait_child(action_a.pid);
	if (action_b.pid > 0)
		fails += !!namei_ext_wait_child(action_b.pid);
	if (policy.attached) {
		ret = namei_ext_policy_destroy(&policy);
		emit_case(out, "detach_policy", !ret, ret ? -ret : 0,
			  "policy detached");
		fails += !!ret;
	}
	if (target_a_registered) {
		ret = namei_ext_clear_targets(cgroup_a);
		emit_case(out, "clear_action_a_target", !ret,
			  ret ? -ret : 0, "action A target registry cleared");
		fails += !!ret;
	}
	if (target_b_registered) {
		ret = namei_ext_clear_targets(cgroup_b);
		emit_case(out, "clear_action_b_target", !ret,
			  ret ? -ret : 0, "action B target registry cleared");
		fails += !!ret;
	}
	if (cgroup_a[0]) {
		ret = rmdir(cgroup_a) && errno != ENOENT ? -errno : 0;
		emit_case(out, "remove_action_a_cgroup", !ret,
			  ret ? -ret : 0, "action A cgroup removed");
		fails += !!ret;
	}
	if (cgroup_b[0]) {
		ret = rmdir(cgroup_b) && errno != ENOENT ? -errno : 0;
		emit_case(out, "remove_action_b_cgroup", !ret,
			  ret ? -ret : 0, "action B cgroup removed");
		fails += !!ret;
	}
	fprintf(out,
		"{\"event\":\"build-action-sandboxing-summary\","
		"\"result_level\":\"" RESULT_LEVEL "\","
		"\"workload\":\"build-action-sandboxing\","
		"\"source_system\":\"bazel-action-sandboxing\","
		"\"bazel_actions\":2,\"concurrent\":%s,"
		"\"pass\":%s,\"failures\":%d}\n",
		both_ready ? "true" : "false",
		fails ? "false" : "true", fails);
	fclose(out);
	namei_ext_remove_tree(root);
	return fails ? 1 : 0;
}
