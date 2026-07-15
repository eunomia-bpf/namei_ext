// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/bpf.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

struct attached_policy {
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	bool attached;
};

enum agent_workspace_counter {
	AW_COUNTER_TOTAL = 0,
	AW_COUNTER_LOOKUP = 1,
	AW_COUNTER_READDIR = 2,
	AW_COUNTER_SELECT_WS_LOOKUP = 3,
	AW_COUNTER_HIDE_DELETED_LOOKUP = 4,
	AW_COUNTER_HIDE_DELETED_READDIR = 5,
	AW_COUNTER_PASS = 6,
};

static const char *result_event = "agent-workspace-preflight";
static const char *result_level = "kvm_agent_workspace_dependency_preflight";

static void emit_case(FILE *out, const char *name, bool pass, int err,
		      const char *detail)
{
	fprintf(out,
		"{\"event\":\"%s\",\"result_level\":\"%s\",\"case\":\"%s\","
		"\"pass\":%s,\"errno\":%d,\"detail\":\"%s\"}\n",
		result_event, result_level, name, pass ? "true" : "false",
		err, detail);
	fflush(out);
}

static void emit_counter(FILE *out, const char *name,
			 unsigned long long value, bool pass,
			 const char *detail)
{
	fprintf(out,
		"{\"event\":\"agent-workspace-policy-counter\","
		"\"result_level\":\"%s\",\"counter\":\"%s\",\"value\":%llu,\"pass\":%s,"
		"\"detail\":\"%s\"}\n",
		result_level, name, value, pass ? "true" : "false", detail);
	fflush(out);
}

static void emit_metric(FILE *out, const char *name,
			unsigned long long value, bool pass,
			const char *unit, const char *detail)
{
	fprintf(out,
		"{\"event\":\"agent-workspace-metric\","
		"\"result_level\":\"%s\",\"metric\":\"%s\",\"value\":%llu,"
		"\"unit\":\"%s\",\"pass\":%s,\"detail\":\"%s\"}\n",
		result_level, name, value, unit, pass ? "true" : "false",
		detail);
	fflush(out);
}

static void emit_sample(FILE *out, const char *name, unsigned int iteration,
			unsigned long long value, bool pass, const char *unit)
{
	fprintf(out,
		"{\"event\":\"agent-workspace-sample\","
		"\"result_level\":\"%s\",\"metric\":\"%s\",\"iteration\":%u,"
		"\"value\":%llu,\"unit\":\"%s\",\"pass\":%s}\n",
		result_level, name, iteration, value, unit,
		pass ? "true" : "false");
	fflush(out);
}

static void emit_manifest(FILE *out, const char *name, bool pass,
			  const char *detail)
{
	fprintf(out,
		"{\"event\":\"agent-workspace-manifest\","
		"\"result_level\":\"%s\",\"manifest\":\"%s\",\"pass\":%s,"
		"\"detail\":\"%s\"}\n",
		result_level, name, pass ? "true" : "false", detail);
	fflush(out);
}

static unsigned long long nsec_now(void)
{
	struct timespec ts;

	if (clock_gettime(CLOCK_MONOTONIC, &ts))
		return 0;
	return (unsigned long long)ts.tv_sec * 1000000000ull + ts.tv_nsec;
}

static int set_path(char *dst, size_t size, const char *dir, const char *name)
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

static bool file_contains_token(const char *path, const char *token)
{
	char buf[4096] = {};
	ssize_t nread;
	int fd;

	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return false;
	nread = read(fd, buf, sizeof(buf) - 1);
	close(fd);
	return nread > 0 && strstr(buf, token);
}

static int expect_source_trace(FILE *out, const char *name, const char *path)
{
	bool pass;

	pass = file_contains_token(path, "TRACE_ID=agentfs-bash-git-workspace-v1") &&
	       file_contains_token(path, "rename generated.txt renamed.txt") &&
	       file_contains_token(path, "unlink cached-negative.txt") &&
	       file_contains_token(path, "git-head agent");
	emit_case(out, name, pass, pass ? 0 : EINVAL,
		  pass ? "AgentFS-derived source trace artifact matched" :
			 "AgentFS-derived source trace artifact missing required tokens");
	return pass ? 0 : -1;
}

static bool read_file_matches_quiet(const char *path, const char *want)
{
	char buf[128] = {};
	ssize_t nread;
	int fd;

	fd = open(path, O_RDONLY);
	if (fd < 0)
		return false;
	nread = read(fd, buf, sizeof(buf) - 1);
	close(fd);
	return nread >= 0 && !strcmp(buf, want);
}

static bool stat_errno_quiet(const char *path, int want_errno)
{
	struct stat st;

	errno = 0;
	if (!stat(path, &st))
		return want_errno == 0;
	return want_errno && errno == want_errno;
}

static int expect_stat_errno(FILE *out, const char *name, const char *path,
			     int want_errno)
{
	struct stat st;

	errno = 0;
	if (!stat(path, &st)) {
		if (!want_errno) {
			emit_case(out, name, true, 0, "stat matched");
			return 0;
		}
		emit_case(out, name, false, 0, "stat unexpectedly succeeded");
		return -1;
	}
	if (want_errno && errno == want_errno) {
		emit_case(out, name, true, errno, "stat errno matched");
		return 0;
	}
	emit_case(out, name, false, errno, "stat mismatch");
	return -1;
}

static int expect_read_file(FILE *out, const char *name, const char *path,
			    const char *want)
{
	char buf[128] = {};
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

static int expect_symlink_read(FILE *out, const char *name, const char *path,
			       const char *want)
{
	char buf[128] = {};
	ssize_t nread;

	errno = 0;
	nread = readlink(path, buf, sizeof(buf) - 1);
	if (nread < 0) {
		emit_case(out, name, false, errno, "readlink failed");
		return -1;
	}
	if (!strcmp(buf, want)) {
		emit_case(out, name, true, 0, "symlink target matched");
		return 0;
	}
	emit_case(out, name, false, 0, "symlink target mismatch");
	return -1;
}

static int expect_workspace_readdir(FILE *out, const char *name, const char *path,
				    bool want_generated)
{
	bool saw_main = false;
	bool saw_deleted = false;
	bool saw_link = false;
	bool saw_generated = false;
	struct dirent *de;
	DIR *dir;

	errno = 0;
	dir = opendir(path);
	if (!dir) {
		emit_case(out, name, false, errno, "opendir failed");
		return -1;
	}
	while ((de = readdir(dir))) {
		if (!strcmp(de->d_name, "main.txt"))
			saw_main = true;
		if (!strcmp(de->d_name, "deleted.txt"))
			saw_deleted = true;
		if (!strcmp(de->d_name, "link.txt"))
			saw_link = true;
		if (!strcmp(de->d_name, "generated.txt"))
			saw_generated = true;
	}
	if (errno) {
		emit_case(out, name, false, errno, "readdir failed");
		closedir(dir);
		return -1;
	}
	closedir(dir);

	if (saw_main && saw_link && !saw_deleted &&
	    saw_generated == want_generated) {
		emit_case(out, name, true, 0,
			  "workspace directory view matched");
		return 0;
	}
	emit_case(out, name, false, 0, "workspace directory view mismatch");
	return -1;
}

static int expect_native_workspace_readdir(FILE *out, const char *name,
					   const char *path, bool want_generated)
{
	bool saw_main = false;
	bool saw_deleted = false;
	bool saw_link = false;
	bool saw_generated = false;
	struct dirent *de;
	DIR *dir;

	errno = 0;
	dir = opendir(path);
	if (!dir) {
		emit_case(out, name, false, errno, "opendir failed");
		return -1;
	}
	while ((de = readdir(dir))) {
		if (!strcmp(de->d_name, "main.txt"))
			saw_main = true;
		if (!strcmp(de->d_name, "deleted.txt"))
			saw_deleted = true;
		if (!strcmp(de->d_name, "link.txt"))
			saw_link = true;
		if (!strcmp(de->d_name, "generated.txt"))
			saw_generated = true;
	}
	if (errno) {
		emit_case(out, name, false, errno, "readdir failed");
		closedir(dir);
		return -1;
	}
	closedir(dir);

	if (saw_main && saw_deleted && saw_link &&
	    saw_generated == want_generated) {
		emit_case(out, name, true, 0,
			  "native lower directory view matched");
		return 0;
	}
	emit_case(out, name, false, 0, "native lower directory view mismatch");
	return -1;
}

static int expect_parent_readdir_ws(FILE *out, const char *name,
				    const char *path)
{
	bool saw_ws = false;
	struct dirent *de;
	DIR *dir;

	errno = 0;
	dir = opendir(path);
	if (!dir) {
		emit_case(out, name, false, errno, "opendir failed");
		return -1;
	}
	while ((de = readdir(dir))) {
		if (!strcmp(de->d_name, "ws"))
			saw_ws = true;
	}
	if (errno) {
		emit_case(out, name, false, errno, "readdir failed");
		closedir(dir);
		return -1;
	}
	closedir(dir);
	emit_case(out, name, saw_ws, saw_ws ? 0 : ENOENT,
		  saw_ws ? "parent listed logical workspace alias" :
			   "parent did not list logical workspace alias");
	return saw_ws ? 0 : -1;
}

static int measure_stat_latency(FILE *out, const char *name, const char *path,
				int want_errno, unsigned int reps)
{
	unsigned long long total_elapsed = 0;
	unsigned int i;

	for (i = 0; i < reps; i++) {
		unsigned long long sample_start = nsec_now();
		unsigned long long sample_elapsed;

		if (!stat_errno_quiet(path, want_errno)) {
			emit_metric(out, name, 0, false, "ns_per_op",
				    "stat latency check failed");
			return -1;
		}
		sample_elapsed = nsec_now() - sample_start;
		total_elapsed += sample_elapsed;
		emit_sample(out, name, i, sample_elapsed, true, "ns");
	}
	emit_metric(out, name, total_elapsed / reps, true, "ns_per_op",
		    "stat latency measured");
	return 0;
}

static int measure_access_latency(FILE *out, const char *name, const char *path,
				  int mode, unsigned int reps)
{
	unsigned long long total_elapsed = 0;
	unsigned int i;

	for (i = 0; i < reps; i++) {
		unsigned long long sample_start = nsec_now();
		unsigned long long sample_elapsed;

		if (access(path, mode)) {
			emit_metric(out, name, 0, false, "ns_per_op",
				    "access latency check failed");
			return -1;
		}
		sample_elapsed = nsec_now() - sample_start;
		total_elapsed += sample_elapsed;
		emit_sample(out, name, i, sample_elapsed, true, "ns");
	}
	emit_metric(out, name, total_elapsed / reps, true, "ns_per_op",
		    "access latency measured");
	return 0;
}

static int measure_open_latency(FILE *out, const char *name, const char *path,
				unsigned int reps)
{
	unsigned long long total_elapsed = 0;
	unsigned int i;

	for (i = 0; i < reps; i++) {
		unsigned long long sample_start = nsec_now();
		unsigned long long sample_elapsed;
		int fd;

		fd = open(path, O_RDONLY | O_CLOEXEC);
		if (fd < 0) {
			emit_metric(out, name, 0, false, "ns_per_op",
				    "open latency check failed");
			return -1;
		}
		close(fd);
		sample_elapsed = nsec_now() - sample_start;
		total_elapsed += sample_elapsed;
		emit_sample(out, name, i, sample_elapsed, true, "ns");
	}
	emit_metric(out, name, total_elapsed / reps, true, "ns_per_op",
		    "open latency measured");
	return 0;
}

static int run_exec_once(const char *path)
{
	pid_t pid;
	int status;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		char *const argv[] = { (char *)path, NULL };

		execv(path, argv);
		_exit(127);
	}
	while (waitpid(pid, &status, 0) < 0) {
		if (errno == EINTR)
			continue;
		return -errno;
	}
	if (WIFEXITED(status) && WEXITSTATUS(status) == 0)
		return 0;
	return -EIO;
}

static int measure_exec_latency(FILE *out, const char *name, const char *path,
				unsigned int reps)
{
	unsigned long long total_elapsed = 0;
	unsigned int i;

	for (i = 0; i < reps; i++) {
		unsigned long long sample_start = nsec_now();
		unsigned long long sample_elapsed;
		int err;

		err = run_exec_once(path);
		if (err) {
			emit_metric(out, name, 0, false, "ns_per_op",
				    "exec latency check failed");
			return -1;
		}
		sample_elapsed = nsec_now() - sample_start;
		total_elapsed += sample_elapsed;
		emit_sample(out, name, i, sample_elapsed, true, "ns");
	}
	emit_metric(out, name, total_elapsed / reps, true, "ns_per_op",
		    "exec latency measured");
	return 0;
}

static int measure_readdir_latency(FILE *out, const char *name,
				   const char *path, unsigned int reps)
{
	unsigned long long total_elapsed = 0;
	unsigned int i;

	for (i = 0; i < reps; i++) {
		unsigned long long sample_start = nsec_now();
		unsigned long long sample_elapsed;
		DIR *dir;
		struct dirent *de;

		errno = 0;
		dir = opendir(path);
		if (!dir) {
			emit_metric(out, name, 0, false, "ns_per_op",
				    "opendir latency check failed");
			return -1;
		}
		while ((de = readdir(dir)))
			;
		if (errno) {
			closedir(dir);
			emit_metric(out, name, 0, false, "ns_per_op",
				    "readdir latency check failed");
			return -1;
		}
		closedir(dir);
		sample_elapsed = nsec_now() - sample_start;
		total_elapsed += sample_elapsed;
		emit_sample(out, name, i, sample_elapsed, true, "ns");
	}
	emit_metric(out, name, total_elapsed / reps, true, "ns_per_op",
		    "readdir latency measured");
	return 0;
}

static int expect_final_manifest(FILE *out, const char *logical_main,
				 const char *logical_deleted,
				 const char *logical_generated,
				 const char *base_generated)
{
	bool pass;

	pass = read_file_matches_quiet(logical_main, "upper-main\n") &&
	       read_file_matches_quiet(logical_generated,
				       "generated-in-upper\n") &&
	       stat_errno_quiet(logical_deleted, ENOENT) &&
	       stat_errno_quiet(base_generated, ENOENT);
	emit_manifest(out, "final_tree_manifest", pass,
		      pass ? "logical tree matched expected upper epoch manifest" :
			     "logical tree manifest mismatch");
	return pass ? 0 : -1;
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

static int register_target(FILE *out, const char *name, unsigned int target_id,
			   const char *target_dir)
{
	char register_buf[64];
	int register_fd;
	int target_fd;
	ssize_t nwritten;

	target_fd = open(target_dir, O_PATH | O_DIRECTORY | O_CLOEXEC);
	if (target_fd < 0) {
		emit_case(out, name, false, errno, "open target O_PATH failed");
		return -1;
	}

	register_fd = open("/sys/kernel/debug/namei_ext/register_target",
			   O_WRONLY | O_CLOEXEC);
	if (register_fd < 0) {
		emit_case(out, name, false, errno,
			  "open target registry failed");
		close(target_fd);
		return -1;
	}

	snprintf(register_buf, sizeof(register_buf), "%u %d\n", target_id,
		 target_fd);
	nwritten = write(register_fd, register_buf, strlen(register_buf));
	if (nwritten != (ssize_t)strlen(register_buf)) {
		emit_case(out, name, false, errno, "target registration failed");
		close(register_fd);
		close(target_fd);
		return -1;
	}

	close(register_fd);
	close(target_fd);
	emit_case(out, name, true, 0, "target directory registered");
	return 0;
}

static int clear_targets(FILE *out, const char *name)
{
	const char clear_cmd[] = "clear\n";
	int register_fd;
	ssize_t nwritten;

	register_fd = open("/sys/kernel/debug/namei_ext/register_target",
			   O_WRONLY | O_CLOEXEC);
	if (register_fd < 0) {
		emit_case(out, name, false, errno,
			  "open target registry failed");
		return -1;
	}

	nwritten = write(register_fd, clear_cmd, strlen(clear_cmd));
	if (nwritten != (ssize_t)strlen(clear_cmd)) {
		emit_case(out, name, false, errno, "target clear failed");
		close(register_fd);
		return -1;
	}

	close(register_fd);
	emit_case(out, name, true, 0, "target registry cleared");
	return 0;
}

static int expect_policy_counter(FILE *out, struct attached_policy *policy,
				 const char *name, __u32 key,
				 bool require_nonzero)
{
	struct bpf_map *map;
	__u64 value = 0;
	int map_fd;

	map = bpf_object__find_map_by_name(policy->obj, "aw_counters");
	if (!map) {
		emit_counter(out, name, 0, false, "counter map not found");
		return -1;
	}
	map_fd = bpf_map__fd(map);
	if (map_fd < 0) {
		emit_counter(out, name, 0, false, "counter map fd invalid");
		return -1;
	}
	if (bpf_map_lookup_elem(map_fd, &key, &value)) {
		emit_counter(out, name, 0, false, "counter lookup failed");
		return -1;
	}
	if (require_nonzero && !value) {
		emit_counter(out, name, value, false, "counter stayed zero");
		return -1;
	}
	emit_counter(out, name, value, true, "counter observed");
	return 0;
}

int main(int argc, char **argv)
{
	const char *cgroup_path = "/sys/fs/cgroup";
	const char *policy_path;
	const char *result_path;
	const char *source_trace_path = NULL;
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	char root[] = "/tmp/namei-ext-agent-workspace-XXXXXX";
	char view[PATH_MAX];
	char base[PATH_MAX];
	char upper[PATH_MAX];
	char logical_root[PATH_MAX];
	char logical_main[PATH_MAX];
	char logical_deleted[PATH_MAX];
	char logical_link[PATH_MAX];
	char logical_generated[PATH_MAX];
	char logical_renamed[PATH_MAX];
	char logical_cached_negative[PATH_MAX];
	char logical_tool[PATH_MAX];
	char base_main[PATH_MAX];
	char base_deleted[PATH_MAX];
	char base_link[PATH_MAX];
	char base_generated[PATH_MAX];
	char base_renamed[PATH_MAX];
	char base_cached_negative[PATH_MAX];
	char base_tool[PATH_MAX];
	char upper_main[PATH_MAX];
	char upper_deleted[PATH_MAX];
	char upper_link[PATH_MAX];
	char upper_generated[PATH_MAX];
	char upper_renamed[PATH_MAX];
	char upper_cached_negative[PATH_MAX];
	char upper_tool[PATH_MAX];
	char logical_src_app[PATH_MAX];
	char logical_git_head[PATH_MAX];
	char base_src[PATH_MAX];
	char upper_src[PATH_MAX];
	char base_git[PATH_MAX];
	char upper_git[PATH_MAX];
	char base_src_app[PATH_MAX];
	char upper_src_app[PATH_MAX];
	char base_git_head[PATH_MAX];
	char upper_git_head[PATH_MAX];
	FILE *out;
	bool matrix_mode = false;
	int fails = 0;
	int err;
	int argi = 1;

	if (argi < argc && !strcmp(argv[argi], "--matrix")) {
		matrix_mode = true;
		result_event = "agent-workspace-matrix";
		result_level = "kvm_agent_workspace_lifecycle_matrix";
		argi++;
	}

	if (argc - argi < 2 || argc - argi > 4) {
		fprintf(stderr,
			"usage: %s [--matrix] AGENT_WORKSPACE_POLICY_BPF_O RESULT_JSONL [CGROUP] [SOURCE_TRACE]\n",
			argv[0]);
		return 2;
	}
	policy_path = argv[argi];
	result_path = argv[argi + 1];
	if (argc - argi == 3)
		cgroup_path = argv[argi + 2];
	if (argc - argi == 4) {
		cgroup_path = argv[argi + 2];
		source_trace_path = argv[argi + 3];
	}

	out = fopen(result_path, "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}

	if (!mkdtemp(root)) {
		emit_case(out, "mkdtemp", false, errno, "mkdtemp failed");
		fclose(out);
		return 1;
	}

	if (set_path(view, sizeof(view), root, "view") ||
	    set_path(base, sizeof(base), root, "base") ||
	    set_path(upper, sizeof(upper), root, "upper") ||
	    set_path(logical_root, sizeof(logical_root), view, "ws") ||
	    set_path(logical_main, sizeof(logical_main), view, "ws/main.txt") ||
	    set_path(logical_deleted, sizeof(logical_deleted), view,
		     "ws/deleted.txt") ||
	    set_path(logical_link, sizeof(logical_link), view, "ws/link.txt") ||
	    set_path(logical_generated, sizeof(logical_generated), view,
		     "ws/generated.txt") ||
	    set_path(logical_renamed, sizeof(logical_renamed), view,
		     "ws/renamed.txt") ||
	    set_path(logical_cached_negative, sizeof(logical_cached_negative),
		     view, "ws/cached-negative.txt") ||
	    set_path(logical_tool, sizeof(logical_tool), view, "ws/tool.sh") ||
	    set_path(base_main, sizeof(base_main), base, "main.txt") ||
	    set_path(base_deleted, sizeof(base_deleted), base, "deleted.txt") ||
	    set_path(base_link, sizeof(base_link), base, "link.txt") ||
	    set_path(base_generated, sizeof(base_generated), base,
		     "generated.txt") ||
	    set_path(base_renamed, sizeof(base_renamed), base, "renamed.txt") ||
	    set_path(base_cached_negative, sizeof(base_cached_negative), base,
		     "cached-negative.txt") ||
	    set_path(base_tool, sizeof(base_tool), base, "tool.sh") ||
	    set_path(upper_main, sizeof(upper_main), upper, "main.txt") ||
	    set_path(upper_deleted, sizeof(upper_deleted), upper,
		     "deleted.txt") ||
	    set_path(upper_link, sizeof(upper_link), upper, "link.txt") ||
	    set_path(upper_generated, sizeof(upper_generated), upper,
		     "generated.txt") ||
	    set_path(upper_renamed, sizeof(upper_renamed), upper,
		     "renamed.txt") ||
	    set_path(upper_cached_negative, sizeof(upper_cached_negative),
		     upper, "cached-negative.txt") ||
	    set_path(upper_tool, sizeof(upper_tool), upper, "tool.sh") ||
	    set_path(logical_src_app, sizeof(logical_src_app), view,
		     "ws/src/app.txt") ||
	    set_path(logical_git_head, sizeof(logical_git_head), view,
		     "ws/.git/HEAD") ||
	    set_path(base_src, sizeof(base_src), base, "src") ||
	    set_path(upper_src, sizeof(upper_src), upper, "src") ||
	    set_path(base_git, sizeof(base_git), base, ".git") ||
	    set_path(upper_git, sizeof(upper_git), upper, ".git") ||
	    set_path(base_src_app, sizeof(base_src_app), base_src, "app.txt") ||
	    set_path(upper_src_app, sizeof(upper_src_app), upper_src,
		     "app.txt") ||
	    set_path(base_git_head, sizeof(base_git_head), base_git, "HEAD") ||
	    set_path(upper_git_head, sizeof(upper_git_head), upper_git,
		     "HEAD")) {
		emit_case(out, "set_paths", false, ENAMETOOLONG,
			  "path construction failed");
		fails++;
		goto cleanup;
	}

	if (mkdir(view, 0755) || mkdir(logical_root, 0755) ||
	    mkdir(base, 0755) || mkdir(upper, 0755)) {
		emit_case(out, "setup_dirs", false, errno, "mkdir failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "setup_dirs", true, 0,
		  "view, logical ws placeholder, base, and upper directories created");

	if (mkdir(base_src, 0755) || mkdir(upper_src, 0755) ||
	    mkdir(base_git, 0755) || mkdir(upper_git, 0755)) {
		emit_case(out, "setup_source_dirs", false, errno,
			  "source-like directory setup failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "setup_source_dirs", true, 0,
		  "source-like src and .git directories created");
	if (matrix_mode) {
		if (!source_trace_path) {
			emit_case(out, "agentfs_source_trace_artifact", false,
				  EINVAL, "source trace path missing");
			fails++;
			goto cleanup;
		}
		fails += !!expect_source_trace(out,
					       "agentfs_source_trace_artifact",
					       source_trace_path);
		emit_case(out, "agentfs_source_trace_replayed",
			  fails == 0, fails,
			  "AgentFS-derived trace replayed as .git/src, whiteout, symlink, create, rename, unlink, and cached-negative oracle rows");
	}

	if (write_file(base_main, "base-main\n") ||
	    write_file(base_deleted, "base-deleted\n") ||
	    write_file(upper_main, "upper-main\n") ||
	    write_file(upper_deleted, "upper-deleted\n") ||
	    write_file(base_tool, "#!/bin/sh\nexit 0\n") ||
	    write_file(upper_tool, "#!/bin/sh\nexit 0\n") ||
	    write_file(base_src_app, "base-app\n") ||
	    write_file(upper_src_app, "agent-edited-app\n") ||
	    write_file(base_git_head, "ref: refs/heads/main\n") ||
	    write_file(upper_git_head, "ref: refs/heads/agent\n") ||
	    symlink("main.txt", base_link) ||
	    symlink("main.txt", upper_link)) {
		emit_case(out, "setup_files", false, errno,
			  "workspace file setup failed");
		fails++;
		goto cleanup;
	}
	if (chmod(base_tool, 0755) || chmod(upper_tool, 0755)) {
		emit_case(out, "setup_executable_tools", false, errno,
			  "chmod executable tool failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "setup_executable_tools", true, 0,
		  "base and upper executable tool files created");
	emit_case(out, "setup_files", true, 0,
		  "base and upper workspace files created");

	fails += !!expect_read_file(out, "nohook_base_main", base_main,
				    "base-main\n");
	fails += !!expect_read_file(out, "nohook_upper_main", upper_main,
				    "upper-main\n");
	fails += !!expect_stat_errno(out, "nohook_base_deleted_visible",
				     base_deleted, 0);
	fails += !!expect_native_workspace_readdir(out, "nohook_base_readdir",
						   base, false);
	fails += !!expect_parent_readdir_ws(out, "nohook_parent_lists_ws", view);
	fails += !!measure_stat_latency(out, "nohook_stat_base_main_ns",
					base_main, 0, 100);
	fails += !!measure_readdir_latency(out, "nohook_readdir_base_ns",
					   base, 50);
	fails += !!expect_stat_errno(out, "logical_before_attach",
				     logical_main, ENOENT);

	if (load_and_attach(policy_path, cgroup_path, &policy)) {
		emit_case(out, "attach_policy", false, errno,
			  "load or attach failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "attach_policy", true, 0, "policy attached");

	fails += !!expect_stat_errno(out, "view_root_native", view, 0);
	fails += !!expect_parent_readdir_ws(out, "policy_parent_lists_ws", view);
	fails += !!register_target(out, "register_base_target", 1, base);
	fails += !!expect_stat_errno(out, "selected_root_final_visible",
				     logical_root, 0);
	fails += !!expect_workspace_readdir(out, "base_epoch_readdir",
					    logical_root, false);
	fails += !!expect_read_file(out, "base_epoch_main", logical_main,
				    "base-main\n");
	fails += !!expect_read_file(out, "base_epoch_src_app",
				    logical_src_app, "base-app\n");
	fails += !!expect_read_file(out, "base_epoch_git_head",
				    logical_git_head,
				    "ref: refs/heads/main\n");
	fails += !!expect_stat_errno(out, "base_epoch_whiteout",
				     logical_deleted, ENOENT);
	fails += !!expect_symlink_read(out, "base_epoch_symlink",
				       logical_link, "main.txt");

	fails += !!register_target(out, "register_upper_target", 1, upper);
	fails += !!expect_stat_errno(out, "upper_selected_root_final_visible",
				     logical_root, 0);
	fails += !!expect_workspace_readdir(out, "upper_epoch_readdir_before_write",
					    logical_root, false);
	fails += !!expect_read_file(out, "upper_epoch_main", logical_main,
				    "upper-main\n");
	fails += !!expect_read_file(out, "upper_epoch_src_app",
				    logical_src_app, "agent-edited-app\n");
	fails += !!expect_read_file(out, "upper_epoch_git_head",
				    logical_git_head,
				    "ref: refs/heads/agent\n");
	fails += !!expect_stat_errno(out, "upper_epoch_whiteout",
				     logical_deleted, ENOENT);
	fails += !!expect_symlink_read(out, "upper_epoch_symlink",
				       logical_link, "main.txt");
	fails += !!expect_stat_errno(out, "upper_generated_negative_before_write",
				     logical_generated, ENOENT);

	err = write_file(logical_generated, "generated-in-upper\n");
	if (err) {
		emit_case(out, "upper_epoch_write", false, -err,
			  "logical write failed");
		fails++;
	} else {
		emit_case(out, "upper_epoch_write", true, 0,
			  "logical write completed through lower FS");
		fails += !!expect_read_file(out, "upper_generated_visible",
					    upper_generated,
					    "generated-in-upper\n");
		fails += !!expect_workspace_readdir(
			out, "upper_epoch_readdir_after_write",
			logical_root, true);
		fails += !!expect_stat_errno(out, "base_not_materialized",
					     base_generated, ENOENT);
	}
	{
		unsigned long long macro_start = nsec_now();
		unsigned long long macro_elapsed;

	fails += !!expect_stat_errno(out,
				     "agentfs_cached_negative_before_create",
				     logical_cached_negative, ENOENT);
	err = write_file(logical_cached_negative, "cached-negative-created\n");
	if (err) {
		emit_case(out, "agentfs_cached_negative_create", false, -err,
			  "cached-negative create through logical path failed");
		fails++;
	} else {
		emit_case(out, "agentfs_cached_negative_create", true, 0,
			  "cached-negative create became visible");
		fails += !!expect_read_file(out,
					    "agentfs_cached_negative_visible",
					    upper_cached_negative,
					    "cached-negative-created\n");
	}
	if (rename(logical_generated, logical_renamed)) {
		emit_case(out, "agentfs_rename_generated_to_renamed", false,
			  errno, "logical rename failed");
		fails++;
	} else {
		emit_case(out, "agentfs_rename_generated_to_renamed", true, 0,
			  "logical rename completed through lower FS");
		fails += !!expect_stat_errno(out,
					     "agentfs_rename_generated_old_absent",
					     logical_generated, ENOENT);
		fails += !!expect_read_file(out,
					    "agentfs_rename_generated_new_visible",
					    upper_renamed,
					    "generated-in-upper\n");
		if (rename(logical_renamed, logical_generated)) {
			emit_case(out, "agentfs_rename_restored_generated",
				  false, errno, "logical rename restore failed");
			fails++;
		} else {
			emit_case(out, "agentfs_rename_restored_generated",
				  true, 0, "logical rename restore completed");
		}
	}
	if (unlink(logical_cached_negative)) {
		emit_case(out, "agentfs_unlink_cached_created", false, errno,
			  "logical unlink failed");
		fails++;
	} else {
		emit_case(out, "agentfs_unlink_cached_created", true, 0,
			  "logical unlink removed created file");
		fails += !!expect_stat_errno(out,
					     "agentfs_unlink_cached_absent",
					     logical_cached_negative, ENOENT);
	}
		macro_elapsed = nsec_now() - macro_start;
		emit_metric(out, "namei_ext_macro_lifecycle_ns",
			    macro_elapsed, fails == 0, "ns",
			    "source lifecycle create/rename/unlink macro measured");
	}
	fails += !!expect_final_manifest(out, logical_main, logical_deleted,
					 logical_generated, base_generated);
	fails += !!measure_stat_latency(out, "namei_ext_stat_main_ns",
					logical_main, 0, 100);
	fails += !!measure_open_latency(out, "namei_ext_open_main_ns",
					logical_main, 100);
	fails += !!measure_access_latency(out, "namei_ext_access_main_ns",
					  logical_main, R_OK, 100);
	fails += !!measure_exec_latency(out, "namei_ext_exec_tool_ns",
					logical_tool, 20);
	fails += !!measure_readdir_latency(out, "namei_ext_readdir_ws_ns",
					   logical_root, 50);

	fails += !!expect_policy_counter(out, &policy, "total",
					 AW_COUNTER_TOTAL, true);
	fails += !!expect_policy_counter(out, &policy, "lookup",
					 AW_COUNTER_LOOKUP, true);
	fails += !!expect_policy_counter(out, &policy, "readdir",
					 AW_COUNTER_READDIR, true);
	fails += !!expect_policy_counter(out, &policy, "select_ws_lookup",
					 AW_COUNTER_SELECT_WS_LOOKUP, true);
	fails += !!expect_policy_counter(out, &policy, "hide_deleted_lookup",
					 AW_COUNTER_HIDE_DELETED_LOOKUP, true);
	fails += !!expect_policy_counter(out, &policy, "hide_deleted_readdir",
					 AW_COUNTER_HIDE_DELETED_READDIR, true);
	fails += !!expect_policy_counter(out, &policy, "pass",
					 AW_COUNTER_PASS, true);

	err = destroy_policy(&policy);
	if (err) {
		emit_case(out, "detach_policy", false, -err,
			  "policy detach failed");
		fails++;
	} else {
		emit_case(out, "detach_policy", true, 0, "policy detached");
		fails += !!expect_stat_errno(out, "logical_after_detach",
					     logical_main, ENOENT);
		fails += !!clear_targets(out, "clear_targets_after_detach");
	}

	if (load_and_attach(policy_path, cgroup_path, &policy)) {
		emit_case(out, "attach_after_clear_for_containment", false,
			  errno, "load or attach after target clear failed");
		fails++;
	} else {
		emit_case(out, "attach_after_clear_for_containment", true, 0,
			  "policy attached after target clear");
		fails += !!expect_stat_errno(out,
					     "invalid_unregistered_target_contained",
					     logical_main, ENOENT);
		err = destroy_policy(&policy);
		if (err) {
			emit_case(out, "detach_after_containment", false, -err,
				  "policy detach after containment failed");
			fails++;
		} else {
			emit_case(out, "detach_after_containment", true, 0,
				  "policy detached after containment");
		}
	}

cleanup:
	if (policy.attached)
		destroy_policy(&policy);
	unlink(base_main);
	unlink(base_deleted);
	unlink(base_link);
	unlink(base_generated);
	unlink(base_renamed);
	unlink(base_cached_negative);
	unlink(base_tool);
	unlink(base_src_app);
	unlink(base_git_head);
	unlink(upper_main);
	unlink(upper_deleted);
	unlink(upper_link);
	unlink(upper_generated);
	unlink(upper_renamed);
	unlink(upper_cached_negative);
	unlink(upper_tool);
	unlink(upper_src_app);
	unlink(upper_git_head);
	rmdir(base_src);
	rmdir(base_git);
	rmdir(upper_src);
	rmdir(upper_git);
	rmdir(logical_root);
	rmdir(view);
	rmdir(base);
	rmdir(upper);
	rmdir(root);
	emit_case(out,
		  matrix_mode ? "agent_workspace_matrix_summary" :
				"agent_workspace_preflight_summary",
		  fails == 0, fails,
		  fails ? (matrix_mode ? "agent workspace matrix failures" :
					 "agent workspace preflight failures") :
			  (matrix_mode ? "agent workspace matrix passed" :
					 "agent workspace preflight passed"));
	fclose(out);
	return fails ? 1 : 0;
}
