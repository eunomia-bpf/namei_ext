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
#include <time.h>
#include <unistd.h>

#define TARGET_A_COMPLETED 1
#define TARGET_A_BASE 2
#define TARGET_B_BASE 3
#define TARGET_B_COMPLETED 4

enum agent_source_task_counter {
	AST_COUNTER_TOTAL = 0,
	AST_COUNTER_LOOKUP = 1,
	AST_COUNTER_READDIR = 2,
	AST_COUNTER_SELECT = 3,
	AST_COUNTER_HIDE_LOOKUP = 4,
	AST_COUNTER_HIDE_READDIR = 5,
	AST_COUNTER_PASS = 6,
};

struct task_paths {
	const char *policy_path;
	const char *result_jsonl;
	const char *result_dir;
	const char *python;
	const char *probe;
	const char *parser;
	const char *base;
	const char *completed;
	const char *cgroup_root;
	char view[PATH_MAX];
	char logical[PATH_MAX];
	char cgroup_a[PATH_MAX];
	char cgroup_b[PATH_MAX];
};

struct task_spec {
	const char *name;
	const char *cgroup;
	const char *logical_root;
	const char *expected_root;
	const char *expected;
};

struct task_wire {
	int internal_errno;
	int move_errno;
	int chdir_errno;
	int probe_exit;
	int pytest_exit;
	int parser_exit;
	uint64_t ready_ns;
	uint64_t start_ns;
	uint64_t end_ns;
};

struct visibility_wire {
	int move_errno;
	int stat_errno;
	int opendir_errno;
	int readdir_errno;
	int closedir_errno;
	bool listed;
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
	fputs("{\"event\":\"agent-source-task-case\",\"case\":", output);
	json_string(output, name);
	fprintf(output, ",\"pass\":%s,\"errno\":%d,\"detail\":",
		pass ? "true" : "false", error);
	json_string(output, detail);
	fputs("}\n", output);
	fflush(output);
}

static uint64_t monotonic_ns(void)
{
	struct timespec time;

	if (clock_gettime(CLOCK_MONOTONIC, &time))
		return 0;
	return (uint64_t)time.tv_sec * 1000000000ULL +
	       (uint64_t)time.tv_nsec;
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

static int drop_privileges(uid_t uid, gid_t gid)
{
	if (setgroups(0, NULL) || setresgid(gid, gid, gid) ||
	    setresuid(uid, uid, uid))
		return -errno;
	return 0;
}

static int prepare_environment(const struct task_paths *paths,
			       const struct task_spec *spec,
			       uid_t uid, gid_t gid)
{
	char python_path[PATH_MAX];
	int ret;

	if (spec->cgroup) {
		ret = namei_ext_move_self_to_cgroup(spec->cgroup);
		if (ret)
			return ret;
	}
	ret = drop_privileges(uid, gid);
	if (ret)
		return ret;
	if (namei_ext_path_join(python_path, sizeof(python_path),
				spec->logical_root, "src"))
		return -ENAMETOOLONG;
	if (clearenv())
		return -errno;
	if (setenv("HOME", paths->result_dir, 1) ||
	    setenv("PATH", "/usr/bin:/bin", 1) ||
	    setenv("LANG", "C.UTF-8", 1) ||
	    setenv("LC_ALL", "C.UTF-8", 1) ||
	    setenv("PYTHONDONTWRITEBYTECODE", "1", 1) ||
	    setenv("PYTHONPATH", python_path, 1))
		return -errno;
	return 0;
}

static int output_path(char *path, size_t size, const char *result_dir,
		       const char *name, const char *suffix)
{
	char leaf[NAME_MAX];

	if (snprintf(leaf, sizeof(leaf), "%s-%s", name, suffix) >=
	    (int)sizeof(leaf))
		return -ENAMETOOLONG;
	return namei_ext_path_join(path, size, result_dir, leaf);
}

static int spawn_capture(char *const command[], const char *stdout_path,
			 const char *stderr_path, int *exit_status)
{
	pid_t pid = fork();

	if (pid < 0)
		return -errno;
	if (!pid) {
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
		execv(command[0], command);
		_exit(121);
	}
	return wait_status(pid, exit_status);
}

static int run_task_body(const struct task_paths *paths,
			 const struct task_spec *spec, uid_t uid, gid_t gid,
			 int ready_fd, int start_fd,
			 struct task_wire *wire)
{
	char import_json[PATH_MAX];
	char junit_xml[PATH_MAX];
	char pytest_json[PATH_MAX];
	char probe_stdout[PATH_MAX];
	char probe_stderr[PATH_MAX];
	char pytest_stdout[PATH_MAX];
	char pytest_stderr[PATH_MAX];
	char parser_stdout[PATH_MAX];
	char parser_stderr[PATH_MAX];
	char basetemp[PATH_MAX];
	char basetemp_arg[PATH_MAX + 16];
	int ret;

	memset(wire, 0, sizeof(*wire));
	wire->probe_exit = -1;
	wire->pytest_exit = -1;
	wire->parser_exit = -1;
	ret = output_path(import_json, sizeof(import_json),
			  paths->result_dir, spec->name, "import.json");
	if (!ret)
		ret = output_path(junit_xml, sizeof(junit_xml),
				  paths->result_dir, spec->name, "junit.xml");
	if (!ret)
		ret = output_path(pytest_json, sizeof(pytest_json),
				  paths->result_dir, spec->name, "pytest.json");
	if (!ret)
		ret = output_path(probe_stdout, sizeof(probe_stdout),
				  paths->result_dir, spec->name,
				  "probe.stdout.log");
	if (!ret)
		ret = output_path(probe_stderr, sizeof(probe_stderr),
				  paths->result_dir, spec->name,
				  "probe.stderr.log");
	if (!ret)
		ret = output_path(pytest_stdout, sizeof(pytest_stdout),
				  paths->result_dir, spec->name,
				  "pytest.stdout.log");
	if (!ret)
		ret = output_path(pytest_stderr, sizeof(pytest_stderr),
				  paths->result_dir, spec->name,
				  "pytest.stderr.log");
	if (!ret)
		ret = output_path(parser_stdout, sizeof(parser_stdout),
				  paths->result_dir, spec->name,
				  "parser.stdout.log");
	if (!ret)
		ret = output_path(parser_stderr, sizeof(parser_stderr),
				  paths->result_dir, spec->name,
				  "parser.stderr.log");
	if (!ret)
		ret = output_path(basetemp, sizeof(basetemp),
				  paths->result_dir, spec->name, "tmp");
	if (!ret &&
	    snprintf(basetemp_arg, sizeof(basetemp_arg), "--basetemp=%s",
		     basetemp) >= (int)sizeof(basetemp_arg))
		ret = -ENAMETOOLONG;
	if (ret) {
		wire->internal_errno = -ret;
		return ret;
	}

	ret = prepare_environment(paths, spec, uid, gid);
	if (ret) {
		wire->move_errno = -ret;
		wire->internal_errno = -ret;
		return ret;
	}
	wire->ready_ns = monotonic_ns();
	if (ready_fd >= 0) {
		char ready = 1;

		ret = write_all(ready_fd, &ready, 1);
		if (ret) {
			wire->internal_errno = -ret;
			return ret;
		}
	}
	if (start_fd >= 0) {
		char start;

		ret = read_all(start_fd, &start, 1);
		if (ret) {
			wire->internal_errno = -ret;
			return ret;
		}
	}
	wire->start_ns = monotonic_ns();
	if (chdir(spec->logical_root)) {
		wire->chdir_errno = errno;
		wire->internal_errno = errno;
		return -errno;
	}

	char *probe_command[] = {
		(char *)paths->python,
		(char *)paths->probe,
		"--logical-root",
		(char *)spec->logical_root,
		"--expected-root",
		(char *)spec->expected_root,
		"--output",
		import_json,
		NULL,
	};
	ret = spawn_capture(probe_command, probe_stdout, probe_stderr,
			    &wire->probe_exit);
	if (ret)
		wire->internal_errno = -ret;

	char *pytest_command[] = {
		(char *)paths->python,
		"-m",
		"pytest",
		"-q",
		"-p",
		"no:cacheprovider",
		"--tb=no",
		basetemp_arg,
		"--junitxml",
		junit_xml,
		"tests/test_types.py",
		NULL,
	};
	if (!ret)
		ret = spawn_capture(pytest_command, pytest_stdout, pytest_stderr,
				    &wire->pytest_exit);
	if (ret && !wire->internal_errno)
		wire->internal_errno = -ret;

	char *parser_command[] = {
		(char *)paths->python,
		(char *)paths->parser,
		"--junit",
		junit_xml,
		"--expected",
		(char *)spec->expected,
		"--output",
		pytest_json,
		NULL,
	};
	if (!ret)
		ret = spawn_capture(parser_command, parser_stdout, parser_stderr,
				    &wire->parser_exit);
	if (ret && !wire->internal_errno)
		wire->internal_errno = -ret;
	wire->end_ns = monotonic_ns();
	return ret;
}

static bool task_passes(const struct task_spec *spec,
			const struct task_wire *wire)
{
	int expected_exit = !strcmp(spec->expected, "base") ? 1 : 0;

	return !wire->internal_errno && !wire->move_errno &&
	       !wire->chdir_errno && wire->probe_exit == 0 &&
	       wire->pytest_exit == expected_exit && wire->parser_exit == 0 &&
	       wire->ready_ns && wire->start_ns && wire->end_ns &&
	       wire->ready_ns <= wire->start_ns &&
	       wire->start_ns < wire->end_ns;
}

static void emit_task(FILE *output, const struct task_spec *spec,
		      const struct task_wire *wire)
{
	bool pass = task_passes(spec, wire);

	fputs("{\"event\":\"agent-source-task-state\",\"state\":", output);
	json_string(output, spec->name);
	fputs(",\"expected\":", output);
	json_string(output, spec->expected);
	fprintf(output,
		",\"internal_errno\":%d,\"move_errno\":%d,"
		"\"chdir_errno\":%d,\"probe_exit\":%d,"
		"\"pytest_exit\":%d,\"parser_exit\":%d,"
		"\"ready_ns\":%llu,\"start_ns\":%llu,\"end_ns\":%llu,"
		"\"pass\":%s}\n",
		wire->internal_errno, wire->move_errno, wire->chdir_errno,
		wire->probe_exit, wire->pytest_exit, wire->parser_exit,
		(unsigned long long)wire->ready_ns,
		(unsigned long long)wire->start_ns,
		(unsigned long long)wire->end_ns,
		pass ? "true" : "false");
	fflush(output);
}

static int run_task(FILE *output, const struct task_paths *paths,
		    const struct task_spec *spec, uid_t uid, gid_t gid)
{
	int pipe_fd[2];
	struct task_wire wire = {};
	pid_t pid;
	int status = -1;
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
		close(pipe_fd[0]);
		run_task_body(paths, spec, uid, gid, -1, -1, &wire);
		if (write_all(pipe_fd[1], &wire, sizeof(wire)))
			_exit(122);
		close(pipe_fd[1]);
		_exit(0);
	}
	close(pipe_fd[1]);
	ret = read_all(pipe_fd[0], &wire, sizeof(wire));
	close(pipe_fd[0]);
	if (wait_status(pid, &status) || status)
		ret = ret ? ret : -ECHILD;
	emit_task(output, spec, &wire);
	if (ret)
		return ret;
	return task_passes(spec, &wire) ? 0 : -EINVAL;
}

static int run_concurrent(FILE *output, const struct task_paths *paths,
			  const struct task_spec *a,
			  const struct task_spec *b,
			  uid_t uid, gid_t gid)
{
	int ready[2], start[2], result_a[2], result_b[2];
	struct task_wire wire_a = {}, wire_b = {};
	pid_t pid_a = -1, pid_b = -1;
	int status_a = -1, status_b = -1;
	uint64_t release_ns = 0;
	int ret = 0;

	if (pipe2(ready, O_CLOEXEC) || pipe2(start, O_CLOEXEC) ||
	    pipe2(result_a, O_CLOEXEC) || pipe2(result_b, O_CLOEXEC))
		return -errno;
	pid_a = fork();
	if (!pid_a) {
		close(ready[0]);
		close(start[1]);
		close(result_a[0]);
		close(result_b[0]);
		close(result_b[1]);
		run_task_body(paths, a, uid, gid, ready[1], start[0],
			      &wire_a);
		if (write_all(result_a[1], &wire_a, sizeof(wire_a)))
			_exit(123);
		_exit(0);
	}
	if (pid_a < 0)
		ret = -errno;
	if (!ret)
		pid_b = fork();
	if (!ret && !pid_b) {
		close(ready[0]);
		close(start[1]);
		close(result_b[0]);
		close(result_a[0]);
		close(result_a[1]);
		run_task_body(paths, b, uid, gid, ready[1], start[0],
			      &wire_b);
		if (write_all(result_b[1], &wire_b, sizeof(wire_b)))
			_exit(124);
		_exit(0);
	}
	if (!ret && pid_b < 0)
		ret = -errno;

	close(ready[1]);
	close(start[0]);
	close(result_a[1]);
	close(result_b[1]);
	if (!ret) {
		char ready_bytes[2];
		char start_bytes[2] = { 1, 1 };

		ret = read_all(ready[0], ready_bytes, sizeof(ready_bytes));
		release_ns = monotonic_ns();
		if (!ret)
			ret = write_all(start[1], start_bytes,
					sizeof(start_bytes));
	}
	close(ready[0]);
	close(start[1]);
	if (pid_a > 0) {
		int read_ret = read_all(result_a[0], &wire_a, sizeof(wire_a));

		if (!ret && read_ret)
			ret = read_ret;
		if (wait_status(pid_a, &status_a) && !ret)
			ret = -ECHILD;
	}
	if (pid_b > 0) {
		int read_ret = read_all(result_b[0], &wire_b, sizeof(wire_b));

		if (!ret && read_ret)
			ret = read_ret;
		if (wait_status(pid_b, &status_b) && !ret)
			ret = -ECHILD;
	}
	close(result_a[0]);
	close(result_b[0]);
	emit_task(output, a, &wire_a);
	emit_task(output, b, &wire_b);

	bool overlap = wire_a.start_ns < wire_b.end_ns &&
		       wire_b.start_ns < wire_a.end_ns;
	bool pass = !ret && status_a == 0 && status_b == 0 &&
		    task_passes(a, &wire_a) && task_passes(b, &wire_b) &&
		    release_ns && wire_a.ready_ns <= release_ns &&
		    wire_b.ready_ns <= release_ns &&
		    wire_a.start_ns >= release_ns &&
		    wire_b.start_ns >= release_ns && overlap;

	fprintf(output,
		"{\"event\":\"agent-source-task-concurrent\","
		"\"participants\":2,\"release_ns\":%llu,"
		"\"a_ready_ns\":%llu,\"b_ready_ns\":%llu,"
		"\"a_start_ns\":%llu,\"b_start_ns\":%llu,"
		"\"a_end_ns\":%llu,\"b_end_ns\":%llu,"
		"\"overlap\":%s,\"pass\":%s}\n",
		(unsigned long long)release_ns,
		(unsigned long long)wire_a.ready_ns,
		(unsigned long long)wire_b.ready_ns,
		(unsigned long long)wire_a.start_ns,
		(unsigned long long)wire_b.start_ns,
		(unsigned long long)wire_a.end_ns,
		(unsigned long long)wire_b.end_ns,
		overlap ? "true" : "false", pass ? "true" : "false");
	fflush(output);
	return pass ? 0 : (ret ? ret : -EINVAL);
}

static int observe_visibility(const char *cgroup, const char *logical,
			      const char *view, struct visibility_wire *wire)
{
	int pipe_fd[2];
	pid_t pid;
	int status = -1;
	int ret;

	memset(wire, 0, sizeof(*wire));
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
		struct stat st;
		DIR *dir;
		struct dirent *entry;

		close(pipe_fd[0]);
		ret = namei_ext_move_self_to_cgroup(cgroup);
		if (ret)
			wire->move_errno = -ret;
		if (!wire->move_errno && stat(logical, &st))
			wire->stat_errno = errno;
		if (!wire->move_errno) {
			dir = opendir(view);
			if (!dir)
				wire->opendir_errno = errno;
			else {
				errno = 0;
				while ((entry = readdir(dir))) {
					if (!strcmp(entry->d_name, "ws"))
						wire->listed = true;
				}
				wire->readdir_errno = errno;
				if (closedir(dir))
					wire->closedir_errno = errno;
			}
		}
		if (write_all(pipe_fd[1], wire, sizeof(*wire)))
			_exit(125);
		_exit(0);
	}
	close(pipe_fd[1]);
	ret = read_all(pipe_fd[0], wire, sizeof(*wire));
	close(pipe_fd[0]);
	if (wait_status(pid, &status) || status)
		ret = ret ? ret : -ECHILD;
	return ret;
}

static int emit_visibility(FILE *output, const char *name,
			   const struct visibility_wire *wire,
			   bool expected_visible)
{
	bool pass = !wire->move_errno && !wire->opendir_errno &&
		    !wire->readdir_errno && !wire->closedir_errno &&
		    ((expected_visible && !wire->stat_errno && wire->listed) ||
		     (!expected_visible && wire->stat_errno == ENOENT &&
		      !wire->listed));

	fputs("{\"event\":\"agent-source-task-visibility\",\"state\":",
	      output);
	json_string(output, name);
	fprintf(output,
		",\"expected_visible\":%s,\"move_errno\":%d,"
		"\"stat_errno\":%d,\"opendir_errno\":%d,"
		"\"readdir_errno\":%d,\"closedir_errno\":%d,"
		"\"listed\":%s,\"pass\":%s}\n",
		expected_visible ? "true" : "false", wire->move_errno,
		wire->stat_errno, wire->opendir_errno, wire->readdir_errno,
		wire->closedir_errno, wire->listed ? "true" : "false",
		pass ? "true" : "false");
	fflush(output);
	return pass ? 0 : -EINVAL;
}

static int update_view(struct namei_ext_harness_policy *policy,
		       uint64_t cgroup_id, const struct task_paths *paths,
		       uint32_t target_id)
{
	return namei_ext_component_map_update(
		policy, "agent_source_task_views", cgroup_id,
		paths->view, "ws", target_id);
}

static int emit_counter(FILE *output,
			struct namei_ext_harness_policy *policy,
			const char *map, const char *name, uint32_t key)
{
	uint64_t value = 0;
	int ret = namei_ext_policy_counter(policy, map, key, &value);
	bool pass = !ret && value > 0;

	fputs("{\"event\":\"agent-source-task-counter\",\"counter\":",
	      output);
	json_string(output, name);
	fprintf(output, ",\"key\":%u,\"value\":%llu,\"pass\":%s}\n",
		key, (unsigned long long)value, pass ? "true" : "false");
	fflush(output);
	return pass ? 0 : (ret ? ret : -ERANGE);
}

static int validate_paths(struct task_paths *paths)
{
	if (namei_ext_path_join(paths->view, sizeof(paths->view),
				paths->result_dir, "view") ||
	    namei_ext_path_join(paths->logical, sizeof(paths->logical),
				paths->view, "ws") ||
	    snprintf(paths->cgroup_a, sizeof(paths->cgroup_a),
		     "%s/namei-ext-agent-source-a-%ld", paths->cgroup_root,
		     (long)getpid()) >= (int)sizeof(paths->cgroup_a) ||
	    snprintf(paths->cgroup_b, sizeof(paths->cgroup_b),
		     "%s/namei-ext-agent-source-b-%ld", paths->cgroup_root,
		     (long)getpid()) >= (int)sizeof(paths->cgroup_b))
		return -ENAMETOOLONG;
	return 0;
}

int main(int argc, char **argv)
{
	struct namei_ext_harness_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	struct task_paths paths = {};
	struct stat result_stat;
	uint64_t cgroup_a_id = 0;
	uint64_t cgroup_b_id = 0;
	FILE *output;
	bool targets_a = false;
	bool targets_b = false;
	int failures = 0;
	int ret;

	if (argc < 9 || argc > 10) {
		fprintf(stderr,
			"usage: %s POLICY RESULT_JSONL RESULT_DIR PYTHON "
			"IMPORT_PROBE JUNIT_PARSER BASE COMPLETED [CGROUP_ROOT]\n",
			argv[0]);
		return 2;
	}
	paths.policy_path = argv[1];
	paths.result_jsonl = argv[2];
	paths.result_dir = argv[3];
	paths.python = argv[4];
	paths.probe = argv[5];
	paths.parser = argv[6];
	paths.base = argv[7];
	paths.completed = argv[8];
	paths.cgroup_root = argc == 10 ? argv[9] : "/sys/fs/cgroup";
	if (stat(paths.result_dir, &result_stat)) {
		perror("stat result directory");
		return 2;
	}
	ret = validate_paths(&paths);
	output = fopen(paths.result_jsonl, "a");
	if (!output) {
		perror("fopen result");
		return 2;
	}
	if (!ret && (mkdir(paths.view, 0755) || mkdir(paths.logical, 0755)))
		ret = -errno;
	emit_case(output, "fixture_paths", !ret, ret ? -ret : 0,
		  "physical task roots and logical workspace placeholder exist");
	if (ret) {
		failures++;
		goto cleanup;
	}

	uid_t uid = result_stat.st_uid;
	gid_t gid = result_stat.st_gid;
	struct task_spec physical_base = {
		.name = "physical-base",
		.logical_root = paths.base,
		.expected_root = paths.base,
		.expected = "base",
	};
	struct task_spec physical_completed = {
		.name = "physical-completed",
		.logical_root = paths.completed,
		.expected_root = paths.completed,
		.expected = "completed",
	};

	ret = run_task(output, &paths, &physical_base, uid, gid);
	failures += !!ret;
	ret = run_task(output, &paths, &physical_completed, uid, gid);
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
		ret = namei_ext_register_target(paths.cgroup_a,
				paths.completed, TARGET_A_COMPLETED);
	if (!ret)
		targets_a = true;
	if (!ret)
		ret = namei_ext_register_target(paths.cgroup_a,
				paths.base, TARGET_A_BASE);
	if (!ret)
		ret = namei_ext_register_target(paths.cgroup_b,
				paths.base, TARGET_B_BASE);
	if (!ret)
		targets_b = true;
	if (!ret)
		ret = namei_ext_register_target(paths.cgroup_b,
				paths.completed, TARGET_B_COMPLETED);
	if (!ret)
		ret = namei_ext_policy_load_attach(paths.policy_path,
						   paths.cgroup_root,
						   &policy);
	emit_case(output, "configure_policy", !ret, ret ? -ret : 0,
		  "two cgroups and four registered workspace targets configured");
	if (ret) {
		failures++;
		goto cleanup;
	}

	struct visibility_wire visibility = {};

	ret = observe_visibility(paths.cgroup_b, paths.logical, paths.view,
				 &visibility);
	if (!ret)
		ret = emit_visibility(output, "before-assignment",
				      &visibility, false);
	failures += !!ret;
	if (failures)
		goto cleanup;

	ret = update_view(&policy, cgroup_a_id, &paths, TARGET_A_COMPLETED);
	if (!ret)
		ret = update_view(&policy, cgroup_b_id, &paths, TARGET_B_BASE);
	emit_case(output, "assign_concurrent_views", !ret, ret ? -ret : 0,
		  "worker A selects completed and worker B selects base");
	failures += !!ret;
	if (failures)
		goto cleanup;

	ret = observe_visibility(paths.cgroup_a, paths.logical, paths.view,
				 &visibility);
	if (!ret)
		ret = emit_visibility(output, "assigned-a", &visibility, true);
	failures += !!ret;
	ret = observe_visibility(paths.cgroup_b, paths.logical, paths.view,
				 &visibility);
	if (!ret)
		ret = emit_visibility(output, "assigned-b", &visibility, true);
	failures += !!ret;
	if (failures)
		goto cleanup;

	struct task_spec concurrent_a = {
		.name = "concurrent-a-completed",
		.cgroup = paths.cgroup_a,
		.logical_root = paths.logical,
		.expected_root = paths.completed,
		.expected = "completed",
	};
	struct task_spec concurrent_b = {
		.name = "concurrent-b-base",
		.cgroup = paths.cgroup_b,
		.logical_root = paths.logical,
		.expected_root = paths.base,
		.expected = "base",
	};

	ret = run_concurrent(output, &paths, &concurrent_a, &concurrent_b,
			     uid, gid);
	failures += !!ret;
	if (failures)
		goto cleanup;

	ret = update_view(&policy, cgroup_b_id, &paths, TARGET_B_COMPLETED);
	emit_case(output, "switch_b_to_completed", !ret, ret ? -ret : 0,
		  "worker B mapping acknowledged as completed");
	failures += !!ret;
	struct task_spec switched = {
		.name = "logical-b-switched-completed",
		.cgroup = paths.cgroup_b,
		.logical_root = paths.logical,
		.expected_root = paths.completed,
		.expected = "completed",
	};
	if (!ret)
		failures += !!run_task(output, &paths, &switched, uid, gid);
	if (failures)
		goto cleanup;

	ret = update_view(&policy, cgroup_b_id, &paths, TARGET_B_BASE);
	emit_case(output, "rollback_b_to_base", !ret, ret ? -ret : 0,
		  "worker B mapping acknowledged as base");
	failures += !!ret;
	struct task_spec rollback = {
		.name = "logical-b-rollback-base",
		.cgroup = paths.cgroup_b,
		.logical_root = paths.logical,
		.expected_root = paths.base,
		.expected = "base",
	};
	if (!ret)
		failures += !!run_task(output, &paths, &rollback, uid, gid);
	if (failures)
		goto cleanup;

	ret = namei_ext_component_map_delete(
		&policy, "agent_source_task_views", cgroup_b_id,
		paths.view, "ws");
	emit_case(output, "withdraw_b_view", !ret, ret ? -ret : 0,
		  "worker B mapping deleted");
	failures += !!ret;
	if (!ret)
		ret = observe_visibility(paths.cgroup_b, paths.logical,
					 paths.view, &visibility);
	if (!ret)
		ret = emit_visibility(output, "after-withdrawal",
				      &visibility, false);
	failures += !!ret;
	if (failures)
		goto cleanup;

	failures += !!emit_counter(output, &policy,
			"agent_source_task_counters", "lookup",
			AST_COUNTER_LOOKUP);
	failures += !!emit_counter(output, &policy,
			"agent_source_task_counters", "readdir",
			AST_COUNTER_READDIR);
	failures += !!emit_counter(output, &policy,
			"agent_source_task_counters", "select",
			AST_COUNTER_SELECT);
	failures += !!emit_counter(output, &policy,
			"agent_source_task_counters", "hide-lookup",
			AST_COUNTER_HIDE_LOOKUP);
	failures += !!emit_counter(output, &policy,
			"agent_source_task_counters", "hide-readdir",
			AST_COUNTER_HIDE_READDIR);
	failures += !!emit_counter(output, &policy,
			"agent_source_task_target_hits", "target-a-completed",
			TARGET_A_COMPLETED);
	failures += !!emit_counter(output, &policy,
			"agent_source_task_target_hits", "target-b-base",
			TARGET_B_BASE);
	failures += !!emit_counter(output, &policy,
			"agent_source_task_target_hits", "target-b-completed",
			TARGET_B_COMPLETED);

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
	if (targets_a) {
		ret = namei_ext_clear_targets(paths.cgroup_a);
		emit_case(output, "clear_targets_a", !ret,
			  ret ? -ret : 0, "worker A targets cleared");
		failures += !!ret;
	}
	if (targets_b) {
		ret = namei_ext_clear_targets(paths.cgroup_b);
		emit_case(output, "clear_targets_b", !ret,
			  ret ? -ret : 0, "worker B targets cleared");
		failures += !!ret;
	}
	if (paths.cgroup_a[0]) {
		ret = rmdir(paths.cgroup_a) && errno != ENOENT ? -errno : 0;
		emit_case(output, "remove_cgroup_a", !ret,
			  ret ? -ret : 0, "worker A cgroup removed");
		failures += !!ret;
	}
	if (paths.cgroup_b[0]) {
		ret = rmdir(paths.cgroup_b) && errno != ENOENT ? -errno : 0;
		emit_case(output, "remove_cgroup_b", !ret,
			  ret ? -ret : 0, "worker B cgroup removed");
		failures += !!ret;
	}

	fprintf(output,
		"{\"event\":\"agent-source-task-summary\","
		"\"source_system\":\"SWE-Factory-Gym\","
		"\"instance\":\"pallets__click-2622\","
		"\"pytest_runs\":6,\"concurrent_pairs\":1,"
		"\"failures\":%d,\"pass\":%s}\n",
		failures, failures ? "false" : "true");
	fclose(output);
	return failures ? 1 : 0;
}
