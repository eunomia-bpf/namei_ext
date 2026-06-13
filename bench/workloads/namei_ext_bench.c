// SPDX-License-Identifier: GPL-2.0

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define TREE_FILES 64

struct bench_env {
	char root[PATH_MAX];
	char native[PATH_MAX];
	char alias[PATH_MAX];
	char backing[PATH_MAX];
	char tree_alias[TREE_FILES][PATH_MAX];
	char tree_backing[TREE_FILES][PATH_MAX];
};

struct attached_policy {
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	bool attached;
};

static int set_path(char *dst, size_t size, const char *fmt, ...)
{
	va_list ap;
	int ret;

	va_start(ap, fmt);
	ret = vsnprintf(dst, size, fmt, ap);
	va_end(ap);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static unsigned long long now_ns(void)
{
	struct timespec ts;

	clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
	return (unsigned long long)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
}

static void emit(FILE *out, const char *event, const char *bench,
		 const char *variant, int sample, unsigned long long ops,
		 unsigned long long elapsed_ns, unsigned long long ok,
		 unsigned long long fail)
{
	fprintf(out,
		"{\"event\":\"%s\",\"bench\":\"%s\",\"variant\":\"%s\","
		"\"sample\":%d,\"ops\":%llu,\"elapsed_ns\":%llu,"
		"\"ok\":%llu,\"fail\":%llu}\n",
		event, bench ? bench : "", variant ? variant : "", sample, ops,
		elapsed_ns, ok, fail);
	fflush(out);
}

static int write_file(const char *path)
{
	int fd;

	fd = open(path, O_CREAT | O_TRUNC | O_WRONLY, 0644);
	if (fd < 0)
		return -errno;
	if (write(fd, "x\n", 2) != 2) {
		int err = errno;

		close(fd);
		return -err;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static int mkdir_if_missing(const char *path)
{
	if (!mkdir(path, 0755) || errno == EEXIST)
		return 0;
	return -errno;
}

static int setup_env(struct bench_env *env)
{
	char dir[PATH_MAX];
	int err;
	int i;

	strncpy(env->root, "/tmp/namei-ext-bench-XXXXXX", sizeof(env->root));
	if (!mkdtemp(env->root))
		return -errno;

	if (set_path(env->native, sizeof(env->native), "%s/native",
		     env->root) ||
	    set_path(env->alias, sizeof(env->alias), "%s/tool",
		     env->root) ||
	    set_path(env->backing, sizeof(env->backing), "%s/tool.real",
		     env->root))
		return -ENAMETOOLONG;
	err = write_file(env->native);
	if (err)
		return err;
	err = write_file(env->backing);
	if (err)
		return err;
	if (chmod(env->native, 0755) || chmod(env->backing, 0755))
		return -errno;

	if (set_path(dir, sizeof(dir), "%s/tree", env->root) ||
	    mkdir_if_missing(dir))
		return -errno;
	if (set_path(dir, sizeof(dir), "%s/tree/include", env->root) ||
	    mkdir_if_missing(dir))
		return -errno;

	for (i = 0; i < TREE_FILES; i++) {
		if (set_path(dir, sizeof(dir), "%s/tree/include/pkg%02d",
			     env->root, i) ||
		    mkdir_if_missing(dir))
			return -errno;
		if (set_path(env->tree_alias[i], sizeof(env->tree_alias[i]),
			     "%s/tool", dir))
			return -errno;
		if (set_path(env->tree_backing[i],
			     sizeof(env->tree_backing[i]), "%s/tool.real",
			     dir))
			return -errno;
		if (write_file(env->tree_backing[i]))
			return -errno;
		if (chmod(env->tree_backing[i], 0755))
			return -errno;
	}
	return 0;
}

static void cleanup_env(struct bench_env *env)
{
	char dir[PATH_MAX];
	int i;

	unlink(env->native);
	unlink(env->backing);
	for (i = 0; i < TREE_FILES; i++) {
		unlink(env->tree_backing[i]);
		if (!set_path(dir, sizeof(dir), "%s/tree/include/pkg%02d",
			      env->root, i))
			rmdir(dir);
	}
	if (!set_path(dir, sizeof(dir), "%s/tree/include", env->root))
		rmdir(dir);
	if (!set_path(dir, sizeof(dir), "%s/tree", env->root))
		rmdir(dir);
	rmdir(env->root);
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

static void bench_stat_path(FILE *out, const char *bench, const char *variant,
			    int sample, const char *path, int want_errno,
			    int iterations)
{
	unsigned long long start, end, ok = 0, fail = 0;
	struct stat st;
	int i;

	start = now_ns();
	for (i = 0; i < iterations; i++) {
		errno = 0;
		if (!stat(path, &st)) {
			if (!want_errno)
				ok++;
			else
				fail++;
		} else if (errno == want_errno) {
			ok++;
		} else {
			fail++;
		}
	}
	end = now_ns();
	emit(out, "bench", bench, variant, sample, iterations, end - start,
	     ok, fail);
}

static void bench_open_path(FILE *out, const char *bench, const char *variant,
			    int sample, const char *path, int want_errno,
			    int iterations)
{
	unsigned long long start, end, ok = 0, fail = 0;
	int fd;
	int i;

	start = now_ns();
	for (i = 0; i < iterations; i++) {
		errno = 0;
		fd = open(path, O_RDONLY);
		if (fd >= 0) {
			close(fd);
			if (!want_errno)
				ok++;
			else
				fail++;
		} else if (errno == want_errno) {
			ok++;
		} else {
			fail++;
		}
	}
	end = now_ns();
	emit(out, "bench", bench, variant, sample, iterations, end - start,
	     ok, fail);
}

static void bench_access_path(FILE *out, const char *bench, const char *variant,
			      int sample, const char *path, int mode,
			      int want_errno, int iterations)
{
	unsigned long long start, end, ok = 0, fail = 0;
	int i;

	start = now_ns();
	for (i = 0; i < iterations; i++) {
		errno = 0;
		if (!access(path, mode)) {
			if (!want_errno)
				ok++;
			else
				fail++;
		} else if (errno == want_errno) {
			ok++;
		} else {
			fail++;
		}
	}
	end = now_ns();
	emit(out, "bench", bench, variant, sample, iterations, end - start,
	     ok, fail);
}

static int exec_errno_once(const char *path, int want_errno)
{
	char *const argv[] = { (char *)path, NULL };
	char *const envp[] = { NULL };
	int status;
	pid_t pid;

	pid = fork();
	if (pid < 0)
		return -1;
	if (pid == 0) {
		execve(path, argv, envp);
		_exit(errno == want_errno ? 0 : 1);
	}
	if (waitpid(pid, &status, 0) < 0)
		return -1;
	return WIFEXITED(status) && WEXITSTATUS(status) == 0 ? 0 : -1;
}

static void bench_exec_path(FILE *out, const char *bench, const char *variant,
			    int sample, const char *path, int want_errno,
			    int iterations)
{
	unsigned long long start, end, ok = 0, fail = 0;
	int i;

	start = now_ns();
	for (i = 0; i < iterations; i++) {
		if (!exec_errno_once(path, want_errno))
			ok++;
		else
			fail++;
	}
	end = now_ns();
	emit(out, "bench", bench, variant, sample, iterations, end - start,
	     ok, fail);
}

static void bench_readdir(FILE *out, const char *variant, int sample,
			  const char *path, bool policy,
			  int iterations)
{
	unsigned long long start, end, ok = 0, fail = 0, ops = 0;
	int i;

	start = now_ns();
	for (i = 0; i < iterations; i++) {
		bool saw_native = false;
		bool saw_alias = false;
		bool saw_backing = false;
		struct dirent *de;
		DIR *dir;

		errno = 0;
		dir = opendir(path);
		if (!dir) {
			fail++;
			continue;
		}
		while ((de = readdir(dir))) {
			ops++;
			if (!strcmp(de->d_name, "native"))
				saw_native = true;
			if (!strcmp(de->d_name, "tool"))
				saw_alias = true;
			if (!strcmp(de->d_name, "tool.real"))
				saw_backing = true;
		}
		if (errno) {
			fail++;
			closedir(dir);
			continue;
		}
		closedir(dir);
		if (saw_native &&
		    ((policy && saw_alias && !saw_backing) ||
		     (!policy && !saw_alias && saw_backing)))
			ok++;
		else
			fail++;
	}
	end = now_ns();
	emit(out, "bench", "readdir_alias_view", variant, sample, ops,
	     end - start, ok, fail);
}

static void bench_tree_walk(FILE *out, const char *variant, int sample,
			    struct bench_env *env, int iterations)
{
	unsigned long long start, end, ok = 0, fail = 0, ops = 0;
	struct stat st;
	int i, j;

	start = now_ns();
	for (i = 0; i < iterations; i++) {
		for (j = 0; j < TREE_FILES; j++) {
			ops++;
			const char *path = strcmp(variant, "policy") ?
					   env->tree_backing[j] :
					   env->tree_alias[j];

			if (!stat(path, &st))
				ok++;
			else
				fail++;
		}
	}
	end = now_ns();
	emit(out, "bench", "build_tree_stat_walk", variant, sample, ops,
	     end - start, ok, fail);
}

static void run_suite(FILE *out, const char *variant, struct bench_env *env,
		      int samples, int iterations, bool policy)
{
	int readdir_iters = iterations / 20;
	int exec_iters = iterations / 100;
	int tree_iters = iterations / TREE_FILES;
	int sample;

	if (readdir_iters < 1)
		readdir_iters = 1;
	if (exec_iters < 1)
		exec_iters = 1;
	if (tree_iters < 1)
		tree_iters = 1;

	for (sample = 0; sample < samples; sample++) {
		const char *tool_path = policy ? env->alias : env->backing;

		bench_stat_path(out, "lookup_native_hot", variant, sample,
				env->native, 0, iterations);
		bench_stat_path(out, "lookup_tool_redirect", variant, sample,
				tool_path, 0, iterations);
		bench_access_path(out, "access_tool_redirect", variant,
				  sample, tool_path, X_OK, 0, iterations);
		bench_open_path(out, "open_tool_redirect", variant, sample,
				tool_path, 0, iterations);
		bench_exec_path(out, "exec_tool_redirect", variant, sample,
				tool_path, ENOEXEC, exec_iters);
		bench_readdir(out, variant, sample, env->root, policy,
			      readdir_iters);
		bench_tree_walk(out, variant, sample, env, tree_iters);
	}
}

int main(int argc, char **argv)
{
	const char *cgroup_path = "/sys/fs/cgroup";
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	struct bench_env env;
	FILE *out;
	int samples;
	int iterations;
	int ret = 1;
	int err;

	if (argc < 5 || argc > 6) {
		fprintf(stderr,
			"usage: %s RESULT_JSONL POLICY_BPF_O SAMPLES ITERATIONS [CGROUP]\n",
			argv[0]);
		return 2;
	}
	if (argc == 6)
		cgroup_path = argv[5];

	samples = atoi(argv[3]);
	iterations = atoi(argv[4]);
	if (samples <= 0 || iterations <= 0)
		return 2;

	out = fopen(argv[1], "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}

	memset(&env, 0, sizeof(env));
	if (setup_env(&env)) {
		emit(out, "bench_setup", "", "", 0, 0, 0, 0, 1);
		goto out_close;
	}
	emit(out, "bench_setup", "", "baseline", 0, 0, 0, 1, 0);
	run_suite(out, "baseline", &env, samples, iterations, false);

	if (load_and_attach(argv[2], cgroup_path, &policy)) {
		emit(out, "bench_attach", "", "policy", 0, 0, 0, 0, 1);
		goto out_cleanup;
	}
	emit(out, "bench_attach", "", "policy", 0, 0, 0, 1, 0);
	run_suite(out, "policy", &env, samples, iterations, true);
	ret = 0;

out_cleanup:
	if (policy.attached) {
		err = destroy_policy(&policy);
		if (err) {
			emit(out, "bench_detach", "", "policy", 0, 0, 0,
			     0, 1);
			ret = 1;
		}
	}
	cleanup_env(&env);
out_close:
	emit(out, "bench_summary", "", "", 0, 0, 0, ret ? 0 : 1,
	     ret ? 1 : 0);
	fclose(out);
	return ret;
}
