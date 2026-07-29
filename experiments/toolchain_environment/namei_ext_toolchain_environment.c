// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <grp.h>
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
#include <unistd.h>

#define TARGET_A_310 1
#define TARGET_A_312 2
#define TARGET_B_312 3

enum toolchain_environment_counter {
	TE_COUNTER_TOTAL = 0,
	TE_COUNTER_LOOKUP = 1,
	TE_COUNTER_SELECT = 2,
	TE_COUNTER_PASS = 3,
};

struct fixture_paths {
	const char *probe;
	const char *result_dir;
	const char *env310;
	const char *env312;
	char env310_python[PATH_MAX];
	char env312_python[PATH_MAX];
	char view[PATH_MAX];
	char current[PATH_MAX];
	char logical_python[PATH_MAX];
	char cgroup_a[PATH_MAX];
	char cgroup_b[PATH_MAX];
};

struct identity_wire {
	int error;
	struct stat root;
	struct stat python;
};

static void json_string(FILE *output, const char *value)
{
	fputc('"', output);
	for (const unsigned char *cursor = (const unsigned char *)value;
	     *cursor; cursor++) {
		switch (*cursor) {
		case '"':
			fputs("\\\"", output);
			break;
		case '\\':
			fputs("\\\\", output);
			break;
		case '\n':
			fputs("\\n", output);
			break;
		case '\r':
			fputs("\\r", output);
			break;
		case '\t':
			fputs("\\t", output);
			break;
		default:
			if (*cursor < 0x20)
				fprintf(output, "\\u%04x", *cursor);
			else
				fputc(*cursor, output);
		}
	}
	fputc('"', output);
}

static void emit_case(FILE *output, const char *name, bool pass, int error,
		      const char *detail)
{
	fputs("{\"event\":\"toolchain-environment-case\",\"case\":", output);
	json_string(output, name);
	fprintf(output, ",\"pass\":%s,\"errno\":%d,\"detail\":",
		pass ? "true" : "false", error);
	json_string(output, detail);
	fputs("}\n", output);
	fflush(output);
}

static int write_all(int fd, const void *buffer, size_t length)
{
	const char *cursor = buffer;

	while (length) {
		ssize_t count = write(fd, cursor, length);

		if (count < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		cursor += count;
		length -= (size_t)count;
	}
	return 0;
}

static int read_all(int fd, void *buffer, size_t length)
{
	char *cursor = buffer;

	while (length) {
		ssize_t count = read(fd, cursor, length);

		if (count < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		if (!count)
			return -EPIPE;
		cursor += count;
		length -= (size_t)count;
	}
	return 0;
}

static int drop_privileges(uid_t uid, gid_t gid)
{
	if (setgroups(0, NULL) || setresgid(gid, gid, gid) ||
	    setresuid(uid, uid, uid))
		return -errno;
	return 0;
}

static int prepare_child(const char *cgroup, uid_t uid, gid_t gid)
{
	int ret;

	if (cgroup) {
		ret = namei_ext_move_self_to_cgroup(cgroup);
		if (ret)
			return ret;
	}
	ret = drop_privileges(uid, gid);
	if (ret)
		return ret;
	if (clearenv())
		return -errno;
	if (setenv("HOME", "/tmp", 1) ||
	    setenv("PATH", "/usr/bin:/bin", 1) ||
	    setenv("LANG", "C", 1) ||
	    setenv("LC_ALL", "C", 1) ||
	    setenv("PYTHONDONTWRITEBYTECODE", "1", 1) ||
	    setenv("PIP_DISABLE_PIP_VERSION_CHECK", "1", 1) ||
	    setenv("PIP_NO_CACHE_DIR", "1", 1))
		return -errno;
	return 0;
}

static int wait_status(pid_t pid, int *exit_status)
{
	int status = 0;

	while (waitpid(pid, &status, 0) < 0) {
		if (errno != EINTR)
			return -errno;
	}
	if (WIFEXITED(status)) {
		*exit_status = WEXITSTATUS(status);
		return 0;
	}
	if (WIFSIGNALED(status)) {
		*exit_status = 128 + WTERMSIG(status);
		return 0;
	}
	return -ECHILD;
}

static pid_t spawn_capture(const char *cgroup, uid_t uid, gid_t gid,
			   char *const command[], const char *stdout_path,
			   const char *stderr_path, int ready_fd,
			   int start_fd, int unused_ready_fd,
			   int unused_start_fd)
{
	pid_t pid = fork();

	if (pid)
		return pid;

	int stdout_fd = open(stdout_path,
			     O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);
	int stderr_fd = open(stderr_path,
			     O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);

	if (stdout_fd < 0 || stderr_fd < 0 ||
	    dup2(stdout_fd, STDOUT_FILENO) < 0 ||
	    dup2(stderr_fd, STDERR_FILENO) < 0)
		_exit(120);
	close(stdout_fd);
	close(stderr_fd);
	if (unused_ready_fd >= 0)
		close(unused_ready_fd);
	if (unused_start_fd >= 0)
		close(unused_start_fd);
	if (prepare_child(cgroup, uid, gid))
		_exit(121);
	if (ready_fd >= 0) {
		char ready = 1;

		if (write_all(ready_fd, &ready, 1))
			_exit(122);
	}
	if (start_fd >= 0) {
		char start;

		if (read_all(start_fd, &start, 1))
			_exit(123);
	}
	execv(command[0], command);
	_exit(124);
}

static int run_capture(const char *cgroup, uid_t uid, gid_t gid,
		       char *const command[], const char *stdout_path,
		       const char *stderr_path, int *exit_status)
{
	pid_t pid = spawn_capture(cgroup, uid, gid, command, stdout_path,
				  stderr_path, -1, -1, -1, -1);

	if (pid < 0)
		return -errno;
	return wait_status(pid, exit_status);
}

static int file_state(const char *path, bool *nonempty)
{
	struct stat st;

	if (stat(path, &st))
		return -errno;
	if (!S_ISREG(st.st_mode))
		return -EINVAL;
	*nonempty = st.st_size > 0;
	return 0;
}

static int make_output_paths(const char *result_dir, const char *name,
			     char *probe_stdout, char *probe_stderr,
			     char *pip_stdout, char *pip_stderr)
{
	char leaf[128];

	if (snprintf(leaf, sizeof(leaf), "%s-probe.json", name) >=
	    (int)sizeof(leaf) ||
	    namei_ext_path_join(probe_stdout, PATH_MAX, result_dir, leaf))
		return -ENAMETOOLONG;
	if (snprintf(leaf, sizeof(leaf), "%s-probe.stderr.log", name) >=
	    (int)sizeof(leaf) ||
	    namei_ext_path_join(probe_stderr, PATH_MAX, result_dir, leaf))
		return -ENAMETOOLONG;
	if (snprintf(leaf, sizeof(leaf), "%s-pip.stdout.log", name) >=
	    (int)sizeof(leaf) ||
	    namei_ext_path_join(pip_stdout, PATH_MAX, result_dir, leaf))
		return -ENAMETOOLONG;
	if (snprintf(leaf, sizeof(leaf), "%s-pip.stderr.log", name) >=
	    (int)sizeof(leaf) ||
	    namei_ext_path_join(pip_stderr, PATH_MAX, result_dir, leaf))
		return -ENAMETOOLONG;
	return 0;
}

static int probe_identity(const char *cgroup, uid_t uid, gid_t gid,
			  const char *root, const char *python,
			  struct identity_wire *wire)
{
	int pipe_fd[2];
	pid_t pid;
	int status;
	int ret;

	if (pipe2(pipe_fd, O_CLOEXEC))
		return -errno;
	pid = fork();
	if (pid < 0) {
		ret = -errno;
		close(pipe_fd[0]);
		close(pipe_fd[1]);
		return ret;
	}
	if (!pid) {
		struct identity_wire child = {};

		close(pipe_fd[0]);
		ret = prepare_child(cgroup, uid, gid);
		if (!ret && stat(root, &child.root))
			ret = -errno;
		if (!ret && stat(python, &child.python))
			ret = -errno;
		child.error = ret ? -ret : 0;
		if (write_all(pipe_fd[1], &child, sizeof(child)))
			_exit(125);
		close(pipe_fd[1]);
		_exit(0);
	}
	close(pipe_fd[1]);
	ret = read_all(pipe_fd[0], wire, sizeof(*wire));
	close(pipe_fd[0]);
	if (wait_status(pid, &status) || status)
		return -ECHILD;
	if (ret)
		return ret;
	return wire->error ? -wire->error : 0;
}

static int run_exec_errno(const char *cgroup, uid_t uid, gid_t gid,
			  const char *path, int *observed_errno)
{
	int pipe_fd[2];
	pid_t pid;
	int status;
	int ret;

	if (pipe2(pipe_fd, O_CLOEXEC))
		return -errno;
	pid = fork();
	if (pid < 0) {
		ret = -errno;
		close(pipe_fd[0]);
		close(pipe_fd[1]);
		return ret;
	}
	if (!pid) {
		char *const command[] = { (char *)path, "--version", NULL };
		int error;

		close(pipe_fd[0]);
		ret = prepare_child(cgroup, uid, gid);
		if (ret)
			error = -ret;
		else {
			execv(path, command);
			error = errno;
		}
		if (write_all(pipe_fd[1], &error, sizeof(error)))
			_exit(126);
		close(pipe_fd[1]);
		_exit(0);
	}
	close(pipe_fd[1]);
	ret = read_all(pipe_fd[0], observed_errno, sizeof(*observed_errno));
	close(pipe_fd[0]);
	if (wait_status(pid, &status) || status)
		return -ECHILD;
	return ret;
}

static int run_state(FILE *output, const struct fixture_paths *paths,
		     const char *name, const char *cgroup,
		     const char *interpreter, const char *prefix,
		     const char *target_root, int major, int minor,
		     uint32_t target_id, uid_t uid, gid_t gid,
		     bool run_pip)
{
	char major_text[16];
	char minor_text[16];
	char probe_stdout[PATH_MAX];
	char probe_stderr[PATH_MAX];
	char pip_stdout[PATH_MAX];
	char pip_stderr[PATH_MAX];
	char target_python[PATH_MAX];
	struct identity_wire actual = {};
	struct stat expected_root;
	struct stat expected_python;
	bool probe_nonempty = false;
	bool probe_stderr_nonempty = false;
	bool pip_nonempty = !run_pip;
	bool pip_stderr_nonempty = false;
	int probe_exit = -1;
	int pip_exit = run_pip ? -1 : 0;
	int ret;

	if (snprintf(major_text, sizeof(major_text), "%d", major) >=
		    (int)sizeof(major_text) ||
	    snprintf(minor_text, sizeof(minor_text), "%d", minor) >=
		    (int)sizeof(minor_text))
		return -ENAMETOOLONG;
	ret = make_output_paths(paths->result_dir, name, probe_stdout,
				probe_stderr, pip_stdout, pip_stderr);
	if (ret)
		return ret;
	if (namei_ext_path_join(target_python, sizeof(target_python),
				 target_root, "bin/python"))
		return -ENAMETOOLONG;

	char *probe_command[] = {
		(char *)interpreter,
		(char *)paths->probe,
		"--major",
		major_text,
		"--minor",
		minor_text,
		"--prefix",
		(char *)prefix,
		NULL,
	};
	ret = run_capture(cgroup, uid, gid, probe_command, probe_stdout,
			  probe_stderr, &probe_exit);
	if (!ret)
		ret = file_state(probe_stdout, &probe_nonempty);
	if (!ret)
		ret = file_state(probe_stderr, &probe_stderr_nonempty);
	if (!ret && run_pip) {
		char *pip_command[] = {
			(char *)interpreter, "-m", "pip", "check", NULL,
		};

		ret = run_capture(cgroup, uid, gid, pip_command, pip_stdout,
				  pip_stderr, &pip_exit);
		if (!ret)
			ret = file_state(pip_stdout, &pip_nonempty);
		if (!ret)
			ret = file_state(pip_stderr, &pip_stderr_nonempty);
	}
	if (!ret)
		ret = probe_identity(cgroup, uid, gid, prefix, interpreter,
				     &actual);
	if (!ret && stat(target_root, &expected_root))
		ret = -errno;
	if (!ret && stat(target_python, &expected_python))
		ret = -errno;

	bool identity_ok = !ret &&
		actual.root.st_dev == expected_root.st_dev &&
		actual.root.st_ino == expected_root.st_ino &&
		actual.python.st_dev == expected_python.st_dev &&
		actual.python.st_ino == expected_python.st_ino;
	bool pass = !ret && probe_exit == 0 && probe_nonempty &&
		!probe_stderr_nonempty && pip_exit == 0 && pip_nonempty &&
		!pip_stderr_nonempty && identity_ok;

	fputs("{\"event\":\"toolchain-environment-state\",\"state\":",
	      output);
	json_string(output, name);
	fprintf(output,
		",\"major\":%d,\"minor\":%d,\"target_id\":%u,"
		"\"probe_exit\":%d,\"probe_nonempty\":%s,"
		"\"probe_stderr_empty\":%s,\"pip_exit\":%d,"
		"\"pip_nonempty\":%s,\"pip_stderr_empty\":%s,"
		"\"actual_root_dev\":%llu,\"actual_root_ino\":%llu,"
		"\"expected_root_dev\":%llu,\"expected_root_ino\":%llu,"
		"\"actual_python_dev\":%llu,\"actual_python_ino\":%llu,"
		"\"expected_python_dev\":%llu,\"expected_python_ino\":%llu,"
		"\"pass\":%s}\n",
		major, minor, target_id, probe_exit,
		probe_nonempty ? "true" : "false",
		probe_stderr_nonempty ? "false" : "true", pip_exit,
		pip_nonempty ? "true" : "false",
		pip_stderr_nonempty ? "false" : "true",
		(unsigned long long)actual.root.st_dev,
		(unsigned long long)actual.root.st_ino,
		(unsigned long long)expected_root.st_dev,
		(unsigned long long)expected_root.st_ino,
		(unsigned long long)actual.python.st_dev,
		(unsigned long long)actual.python.st_ino,
		(unsigned long long)expected_python.st_dev,
		(unsigned long long)expected_python.st_ino,
		pass ? "true" : "false");
	fflush(output);
	return pass ? 0 : (ret ? ret : -EINVAL);
}

static int wait_ready_and_start(int ready_fd, int start_fd)
{
	char ready[2];
	char start[2] = { 1, 1 };
	int ret = read_all(ready_fd, ready, sizeof(ready));

	if (!ret)
		ret = write_all(start_fd, start, sizeof(start));
	return ret;
}

static int run_concurrent_pair(FILE *output,
			       const struct fixture_paths *paths,
			       uid_t uid, gid_t gid)
{
	char a_stdout[PATH_MAX], a_stderr[PATH_MAX];
	char a_pip_stdout[PATH_MAX], a_pip_stderr[PATH_MAX];
	char b_stdout[PATH_MAX], b_stderr[PATH_MAX];
	char b_pip_stdout[PATH_MAX], b_pip_stderr[PATH_MAX];
	char *a_command[] = {
		(char *)paths->logical_python, (char *)paths->probe,
		"--major", "3", "--minor", "10",
		"--prefix", (char *)paths->current, NULL,
	};
	char *b_command[] = {
		(char *)paths->logical_python, (char *)paths->probe,
		"--major", "3", "--minor", "12",
		"--prefix", (char *)paths->current, NULL,
	};
	int ready_pipe[2];
	int start_pipe[2];
	int a_exit = -1;
	int b_exit = -1;
	int ret;

	ret = make_output_paths(paths->result_dir, "concurrent-a-310",
				a_stdout, a_stderr, a_pip_stdout, a_pip_stderr);
	if (!ret)
		ret = make_output_paths(paths->result_dir, "concurrent-b-312",
					b_stdout, b_stderr,
					b_pip_stdout, b_pip_stderr);
	if (ret)
		return ret;
	if (pipe2(ready_pipe, O_CLOEXEC) || pipe2(start_pipe, O_CLOEXEC))
		return -errno;

	pid_t a_pid = spawn_capture(paths->cgroup_a, uid, gid, a_command,
				    a_stdout, a_stderr, ready_pipe[1],
				    start_pipe[0], ready_pipe[0],
				    start_pipe[1]);
	pid_t b_pid = spawn_capture(paths->cgroup_b, uid, gid, b_command,
				    b_stdout, b_stderr, ready_pipe[1],
				    start_pipe[0], ready_pipe[0],
				    start_pipe[1]);
	close(ready_pipe[1]);
	close(start_pipe[0]);
	if (a_pid < 0 || b_pid < 0)
		ret = -errno;
	if (!ret)
		ret = wait_ready_and_start(ready_pipe[0], start_pipe[1]);
	close(ready_pipe[0]);
	close(start_pipe[1]);
	if (a_pid > 0 && wait_status(a_pid, &a_exit) && !ret)
		ret = -ECHILD;
	if (b_pid > 0 && wait_status(b_pid, &b_exit) && !ret)
		ret = -ECHILD;

	bool a_output = false, a_error = false;
	bool b_output = false, b_error = false;

	if (!ret)
		ret = file_state(a_stdout, &a_output);
	if (!ret)
		ret = file_state(a_stderr, &a_error);
	if (!ret)
		ret = file_state(b_stdout, &b_output);
	if (!ret)
		ret = file_state(b_stderr, &b_error);
	bool pass = !ret && a_exit == 0 && b_exit == 0 &&
		a_output && b_output && !a_error && !b_error;

	fprintf(output,
		"{\"event\":\"toolchain-environment-concurrent\","
		"\"barrier_participants\":2,\"a_exit\":%d,\"b_exit\":%d,"
		"\"a_output\":%s,\"b_output\":%s,"
		"\"a_stderr_empty\":%s,\"b_stderr_empty\":%s,"
		"\"pass\":%s}\n",
		a_exit, b_exit, a_output ? "true" : "false",
		b_output ? "true" : "false",
		a_error ? "false" : "true", b_error ? "false" : "true",
		pass ? "true" : "false");
	fflush(output);
	return pass ? 0 : (ret ? ret : -EINVAL);
}

static int update_view(struct namei_ext_harness_policy *policy,
		       uint64_t cgroup_id, const struct fixture_paths *paths,
		       uint32_t target_id)
{
	return namei_ext_component_map_update(
		policy, "toolchain_environment_views", cgroup_id,
		paths->view, "current", target_id);
}

static int emit_counter(FILE *output,
			struct namei_ext_harness_policy *policy,
			const char *map, const char *name, uint32_t key)
{
	uint64_t value = 0;
	int ret = namei_ext_policy_counter(policy, map, key, &value);
	bool pass = !ret && value > 0;

	fputs("{\"event\":\"toolchain-environment-counter\",\"counter\":",
	      output);
	json_string(output, name);
	fprintf(output, ",\"key\":%u,\"value\":%llu,\"pass\":%s}\n",
		key, (unsigned long long)value, pass ? "true" : "false");
	fflush(output);
	return pass ? 0 : (ret ? ret : -ERANGE);
}

static int validate_paths(struct fixture_paths *paths)
{
	if (namei_ext_path_join(paths->env310_python,
				 sizeof(paths->env310_python),
				 paths->env310, "bin/python") ||
	    namei_ext_path_join(paths->env312_python,
				 sizeof(paths->env312_python),
				 paths->env312, "bin/python") ||
	    namei_ext_path_join(paths->view, sizeof(paths->view),
				 paths->result_dir, "view") ||
	    namei_ext_path_join(paths->current, sizeof(paths->current),
				 paths->view, "current") ||
	    namei_ext_path_join(paths->logical_python,
				 sizeof(paths->logical_python),
				 paths->current, "bin/python"))
		return -ENAMETOOLONG;
	return 0;
}

int main(int argc, char **argv)
{
	const char *cgroup_root = "/sys/fs/cgroup";
	struct namei_ext_harness_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	struct fixture_paths paths = {};
	struct stat result_stat;
	uint64_t cgroup_a_id = 0;
	uint64_t cgroup_b_id = 0;
	FILE *output;
	bool target_a_registered = false;
	bool target_b_registered = false;
	int failures = 0;
	int ret;

	if (argc < 7 || argc > 8) {
		fprintf(stderr,
			"usage: %s POLICY PROBE RESULT_JSONL RESULT_DIR "
			"ENV310 ENV312 [CGROUP_ROOT]\n", argv[0]);
		return 2;
	}
	if (argc == 8)
		cgroup_root = argv[7];
	paths.probe = argv[2];
	paths.result_dir = argv[4];
	paths.env310 = argv[5];
	paths.env312 = argv[6];
	if (stat(paths.result_dir, &result_stat)) {
		perror("stat result directory");
		return 2;
	}
	output = fopen(argv[3], "a");
	if (!output) {
		perror("fopen result");
		return 2;
	}
	ret = validate_paths(&paths);
	if (!ret &&
	    (snprintf(paths.cgroup_a, sizeof(paths.cgroup_a),
		      "%s/namei-ext-toolchain-a-%ld", cgroup_root,
		      (long)getpid()) >= (int)sizeof(paths.cgroup_a) ||
	     snprintf(paths.cgroup_b, sizeof(paths.cgroup_b),
		      "%s/namei-ext-toolchain-b-%ld", cgroup_root,
		      (long)getpid()) >= (int)sizeof(paths.cgroup_b)))
		ret = -ENAMETOOLONG;
	if (!ret && (mkdir(paths.view, 0755) ||
		     mkdir(paths.current, 0755)))
		ret = -errno;
	emit_case(output, "fixture_paths", !ret, ret ? -ret : 0,
		  "physical virtual environments and logical current path exist");
	if (ret) {
		failures++;
		goto cleanup;
	}

	uid_t uid = result_stat.st_uid;
	gid_t gid = result_stat.st_gid;

	ret = run_state(output, &paths, "physical-310", NULL,
			paths.env310_python, paths.env310, paths.env310,
			3, 10, 0, uid, gid, true);
	failures += !!ret;
	ret = run_state(output, &paths, "physical-312", NULL,
			paths.env312_python, paths.env312, paths.env312,
			3, 12, 0, uid, gid, true);
	failures += !!ret;
	if (failures)
		goto cleanup;

	if (mkdir(paths.cgroup_a, 0755) || mkdir(paths.cgroup_b, 0755))
		ret = -errno;
	if (!ret)
		ret = namei_ext_cgroup_id(paths.cgroup_a, &cgroup_a_id);
	if (!ret)
		ret = namei_ext_cgroup_id(paths.cgroup_b, &cgroup_b_id);
	if (!ret)
		ret = namei_ext_register_target(paths.cgroup_a, paths.env310,
					       TARGET_A_310);
	if (!ret)
		target_a_registered = true;
	if (!ret)
		ret = namei_ext_register_target(paths.cgroup_a, paths.env312,
					       TARGET_A_312);
	if (!ret)
		ret = namei_ext_register_target(paths.cgroup_b, paths.env312,
					       TARGET_B_312);
	if (!ret)
		target_b_registered = true;
	if (!ret && namei_ext_policy_load_attach(argv[1], cgroup_root,
						  &policy))
		ret = -errno;
	if (!ret)
		ret = update_view(&policy, cgroup_a_id, &paths, TARGET_A_310);
	if (!ret)
		ret = update_view(&policy, cgroup_b_id, &paths, TARGET_B_312);
	emit_case(output, "configure_policy", !ret, ret ? -ret : 0,
		  "two cgroup views select registered existing environments");
	if (ret) {
		failures++;
		goto cleanup;
	}

	ret = run_concurrent_pair(output, &paths, uid, gid);
	failures += !!ret;
	ret = run_state(output, &paths, "logical-a-310", paths.cgroup_a,
			paths.logical_python, paths.current, paths.env310,
			3, 10, TARGET_A_310, uid, gid, true);
	failures += !!ret;
	ret = run_state(output, &paths, "logical-b-312", paths.cgroup_b,
			paths.logical_python, paths.current, paths.env312,
			3, 12, TARGET_B_312, uid, gid, true);
	failures += !!ret;
	if (failures)
		goto cleanup;

	mode_t original_mode;
	struct stat python312_stat;
	int observed_errno = 0;
	bool mode_changed = false;

	if (stat(paths.env312_python, &python312_stat))
		ret = -errno;
	else {
		original_mode = python312_stat.st_mode & 07777;
		ret = chmod(paths.env312_python, 0000) ? -errno : 0;
		mode_changed = !ret;
	}
	if (!ret)
		ret = run_exec_errno(paths.cgroup_b, uid, gid,
				     paths.logical_python, &observed_errno);
	int restore_ret = mode_changed &&
		chmod(paths.env312_python, original_mode) ? -errno : 0;
	bool permission_pass = !ret && !restore_ret &&
		observed_errno == EACCES;
	fprintf(output,
		"{\"event\":\"toolchain-environment-permission\","
		"\"observed_errno\":%d,\"restore_errno\":%d,"
		"\"pass\":%s}\n",
		observed_errno, restore_ret ? -restore_ret : 0,
		permission_pass ? "true" : "false");
	fflush(output);
	if (!permission_pass) {
		failures++;
		goto cleanup;
	}

	ret = update_view(&policy, cgroup_a_id, &paths, TARGET_A_312);
	emit_case(output, "switch_a_to_312", !ret, ret ? -ret : 0,
		  "application A current path switches to Python 3.12");
	failures += !!ret;
	if (!ret) {
		ret = run_state(output, &paths, "logical-a-switched-312",
				paths.cgroup_a, paths.logical_python,
				paths.current, paths.env312, 3, 12,
				TARGET_A_312, uid, gid, true);
		failures += !!ret;
	}
	if (failures)
		goto cleanup;

	ret = update_view(&policy, cgroup_a_id, &paths, TARGET_A_310);
	emit_case(output, "rollback_a_to_310", !ret, ret ? -ret : 0,
		  "application A current path rolls back to Python 3.10");
	failures += !!ret;
	if (!ret) {
		ret = run_state(output, &paths, "logical-a-rollback-310",
				paths.cgroup_a, paths.logical_python,
				paths.current, paths.env310, 3, 10,
				TARGET_A_310, uid, gid, true);
		failures += !!ret;
	}
	if (failures)
		goto cleanup;

	ret = namei_ext_component_map_delete(
		&policy, "toolchain_environment_views", cgroup_a_id,
		paths.view, "current");
	if (!ret)
		ret = run_exec_errno(paths.cgroup_a, uid, gid,
				     paths.logical_python, &observed_errno);
	bool withdrawn_pass = !ret && observed_errno == ENOENT;
	fprintf(output,
		"{\"event\":\"toolchain-environment-withdrawn\","
		"\"observed_errno\":%d,\"pass\":%s}\n",
		observed_errno, withdrawn_pass ? "true" : "false");
	fflush(output);
	if (!withdrawn_pass) {
		failures++;
		goto cleanup;
	}

	failures += !!emit_counter(output, &policy,
				   "toolchain_environment_counters",
				   "lookup", TE_COUNTER_LOOKUP);
	failures += !!emit_counter(output, &policy,
				   "toolchain_environment_counters",
				   "select", TE_COUNTER_SELECT);
	failures += !!emit_counter(output, &policy,
				   "toolchain_environment_target_hits",
				   "target-a-310", TARGET_A_310);
	failures += !!emit_counter(output, &policy,
				   "toolchain_environment_target_hits",
				   "target-a-312", TARGET_A_312);
	failures += !!emit_counter(output, &policy,
				   "toolchain_environment_target_hits",
				   "target-b-312", TARGET_B_312);

cleanup:
	if (policy.attached) {
		ret = namei_ext_policy_destroy(&policy);
		emit_case(output, "detach_policy", !ret, ret ? -ret : 0,
			  "policy detached from cgroup/namei_ext");
		failures += !!ret;
	} else {
		emit_case(output, "detach_policy", true, 0,
			  "policy was not attached");
	}
	if (target_a_registered) {
		ret = namei_ext_clear_targets(paths.cgroup_a);
		emit_case(output, "clear_targets_a", !ret,
			  ret ? -ret : 0, "application A targets cleared");
		failures += !!ret;
	}
	if (target_b_registered) {
		ret = namei_ext_clear_targets(paths.cgroup_b);
		emit_case(output, "clear_targets_b", !ret,
			  ret ? -ret : 0, "application B targets cleared");
		failures += !!ret;
	}
	if (paths.cgroup_a[0] && rmdir(paths.cgroup_a) && errno != ENOENT)
		failures++;
	if (paths.cgroup_b[0] && rmdir(paths.cgroup_b) && errno != ENOENT)
		failures++;

	fprintf(output,
		"{\"event\":\"toolchain-environment-summary\","
		"\"source_system\":\"CPython-venv\","
		"\"physical_environments\":2,\"logical_states\":4,"
		"\"failures\":%d,\"pass\":%s}\n",
		failures, failures ? "false" : "true");
	fclose(output);
	return failures ? 1 : 0;
}
