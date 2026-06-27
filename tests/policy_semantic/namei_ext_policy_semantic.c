// SPDX-License-Identifier: GPL-2.0

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/bpf.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

struct redirect_case {
	const char *branch;
	const char *alias;
	const char *backing;
	const char *content;
	bool lookup;
	bool readdir;
};

struct policy_family {
	const char *family;
	const char *object;
	const struct redirect_case *cases;
	size_t nr_cases;
	const char *negative_name;
};

struct attached_policy {
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	bool attached;
};

static const struct redirect_case build_cases[] = {
	{ "generated", "config.h", "config.gen.h", "generated\n", true, true },
	{ "source_fallback", "version.h", "version.src.h", "source\n", true, true },
	{ "toolchain", "cc", "cc.real", "toolchain\n", true, true },
	{ "external_dep", "libssl.so", "libssl.dep", "external\n", true, true },
	{ "undeclared_poison", "private.h", "poison.dep", "poison\n", true, true },
};

static const struct redirect_case fixture_cases[] = {
	{ "config", "nginx.conf", "nginx.test.conf", "nginx-test\n", true, true },
	{ "service_config", "postgresql.conf", "postgres.test.conf", "postgres-test\n", true, true },
	{ "secret", "db.password", "db.fake.pass", "fake-secret\n", true, true },
	{ "certificate", "server.crt", "server.fake.crt", "fake-cert\n", true, true },
	{ "endpoint", "upstream.sock", "upstream.local", "local-endpoint\n", true, true },
	{ "poison", "prod.token", "poison.secret", "poison\n", true, true },
};

static const struct redirect_case checkpoint_cases[] = {
	{ "state", "dump.rdb", "dump.ckpt", "rdb-checkpoint\n", true, true },
	{ "state_aof", "appendonly.aof", "aof.ckpt", "aof-checkpoint\n", true, true },
	{ "config", "nginx.conf", "nginx.ckpt", "nginx-checkpoint\n", true, true },
	{ "cache", "cache.db", "cache.ckpt", "cache-checkpoint\n", true, true },
	{ "runtime_socket", "redis.sock", "redis.sock.new", "socket-new\n", true, true },
	{ "runtime_pid", "nginx.pid", "nginx.pid.new", "pid-new\n", true, true },
	{ "mixed_epoch", "epoch.bad", "poison.epoch", "epoch-poison\n", true, true },
};

static const struct redirect_case cache_cases[] = {
	{ "verified_hit", "object.o", "object.local", "local-object\n", true, true },
	{ "miss_canonical", "pkg.mod", "pkg.canon", "canonical-module\n", true, true },
	{ "stale_canonical", "stale.o", "stale.canon", "stale-canonical\n", true, true },
	{ "corrupt_reject", "corrupt.o", "corrupt.reject", "corrupt-reject\n", true, true },
};

static void emit(FILE *out, const char *family, const char *branch,
		 const char *op, bool pass, int err, const char *detail)
{
	fprintf(out,
		"{\"event\":\"policy-semantic\",\"family\":\"%s\","
		"\"branch\":\"%s\",\"op\":\"%s\",\"pass\":%s,"
		"\"errno\":%d,\"detail\":\"%s\"}\n",
		family, branch ? branch : "", op, pass ? "true" : "false",
		err, detail);
	fflush(out);
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

static int expect_read(const char *path, const char *want)
{
	char buf[128] = {};
	ssize_t nread;
	int fd;
	int err;

	fd = open(path, O_RDONLY);
	if (fd < 0)
		return -errno;
	nread = read(fd, buf, sizeof(buf) - 1);
	err = errno;
	close(fd);
	if (nread < 0)
		return -err;
	if (strcmp(buf, want))
		return -EINVAL;
	return 0;
}

static int expect_stat_errno(const char *path, int want_errno)
{
	struct stat st;

	errno = 0;
	if (!stat(path, &st))
		return want_errno ? -EINVAL : 0;
	if (want_errno && errno == want_errno)
		return 0;
	return -errno;
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

static int setup_family_dir(const struct policy_family *family, char *dir,
			    size_t dir_size)
{
	char path[PATH_MAX];
	size_t i;

	snprintf(dir, dir_size, "/tmp/namei-ext-%s-XXXXXX", family->family);
	if (!mkdtemp(dir))
		return -errno;

	if (set_path(path, sizeof(path), dir, "native"))
		return -ENAMETOOLONG;
	if (write_file(path, "native\n"))
		return -errno;

	for (i = 0; i < family->nr_cases; i++) {
		if (set_path(path, sizeof(path), dir, family->cases[i].backing))
			return -ENAMETOOLONG;
		if (write_file(path, family->cases[i].content))
			return -errno;
	}
	return 0;
}

static int cleanup_family_dir(const struct policy_family *family,
			      const char *dir)
{
	char path[PATH_MAX];
	size_t i;

	if (!dir[0])
		return 0;
	if (!set_path(path, sizeof(path), dir, "native"))
		unlink(path);
	for (i = 0; i < family->nr_cases; i++) {
		if (!set_path(path, sizeof(path), dir, family->cases[i].backing))
			unlink(path);
	}
	return rmdir(dir) ? -errno : 0;
}

static bool dir_has_name(const char *dir_path, const char *name, int *err_out)
{
	struct dirent *de;
	bool found = false;
	DIR *dir;

	errno = 0;
	dir = opendir(dir_path);
	if (!dir) {
		*err_out = errno;
		return false;
	}
	while ((de = readdir(dir))) {
		if (!strcmp(de->d_name, name)) {
			found = true;
			break;
		}
	}
	if (errno)
		*err_out = errno;
	closedir(dir);
	return found;
}

static int run_family(const struct policy_family *family,
		      const char *cgroup_path, FILE *out)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	char dir[PATH_MAX] = {};
	char path[PATH_MAX];
	int failures = 0;
	size_t i;

	if (setup_family_dir(family, dir, sizeof(dir))) {
		emit(out, family->family, "", "setup", false, errno,
		     "failed to set up fixture directory");
		return 1;
	}
	emit(out, family->family, "", "setup", true, 0,
	     "fixture directory created");

	if (set_path(path, sizeof(path), dir, family->cases[0].alias) ||
	    expect_stat_errno(path, ENOENT)) {
		emit(out, family->family, "pre_attach", "alias_absent",
		     false, errno, "alias existed before attach");
		failures++;
	} else {
		emit(out, family->family, "pre_attach", "alias_absent",
		     true, 0, "alias absent before attach");
	}

	if (load_and_attach(family->object, cgroup_path, &policy)) {
		emit(out, family->family, "", "attach", false, errno,
		     "policy attach failed");
		failures++;
		goto out_cleanup;
	}
	emit(out, family->family, "", "attach", true, 0, "policy attached");

	for (i = 0; i < family->nr_cases; i++) {
		const struct redirect_case *tc = &family->cases[i];
		int err = 0;
		bool saw_alias;
		bool saw_backing;

		if (tc->lookup) {
			if (set_path(path, sizeof(path), dir, tc->alias) ||
			    (err = expect_read(path, tc->content))) {
				emit(out, family->family, tc->branch, "lookup",
				     false, -err, "redirected read failed");
				failures++;
			} else {
				emit(out, family->family, tc->branch, "lookup",
				     true, 0, "redirected read matched");
			}
		}

		if (tc->readdir) {
			err = 0;
			saw_alias = dir_has_name(dir, tc->alias, &err);
			saw_backing = dir_has_name(dir, tc->backing, &err);
			if (!err && saw_alias && !saw_backing) {
				emit(out, family->family, tc->branch, "readdir",
				     true, 0, "alias visible, backing hidden");
			} else {
				emit(out, family->family, tc->branch, "readdir",
				     false, err, "directory view mismatch");
				failures++;
			}
		}
	}

	if (family->negative_name) {
		if (set_path(path, sizeof(path), dir, family->negative_name) ||
		    expect_stat_errno(path, ENOENT)) {
			emit(out, family->family, "negative", "lookup",
			     false, errno, "negative lookup did not pass");
			failures++;
		} else {
			emit(out, family->family, "negative", "lookup",
			     true, 0, "negative lookup passed through");
		}
	}

	if (set_path(path, sizeof(path), dir, "native") ||
	    expect_read(path, "native\n")) {
		emit(out, family->family, "pass_through", "lookup", false,
		     errno, "native pass-through failed");
		failures++;
	} else {
		emit(out, family->family, "pass_through", "lookup", true, 0,
		     "native pass-through matched");
	}

	if (destroy_policy(&policy)) {
		emit(out, family->family, "", "detach", false, errno,
		     "policy detach failed");
		failures++;
	} else {
		emit(out, family->family, "", "detach", true, 0,
		     "policy detached");
	}

	if (set_path(path, sizeof(path), dir, family->cases[0].alias) ||
	    expect_stat_errno(path, ENOENT)) {
		emit(out, family->family, "post_detach", "alias_absent",
		     false, errno, "alias still resolved after detach");
		failures++;
	} else {
		emit(out, family->family, "post_detach", "alias_absent",
		     true, 0, "alias absent after detach");
	}

out_cleanup:
	if (policy.attached)
		destroy_policy(&policy);
	if (cleanup_family_dir(family, dir)) {
		emit(out, family->family, "", "cleanup", false, errno,
		     "fixture cleanup failed");
		failures++;
	}
	emit(out, family->family, "", "summary", failures == 0, failures,
	     failures ? "family semantic failed" : "family semantic passed");
	return failures ? 1 : 0;
}

int main(int argc, char **argv)
{
	struct policy_family families[4];
	const char *out_path;
	const char *cgroup_path;
	FILE *out;
	int failures = 0;
	int i;

	if (argc != 7) {
		fprintf(stderr,
			"usage: %s OUT_JSONL CGROUP_PATH BUILD_POLICY FIXTURE_POLICY CHECKPOINT_POLICY CACHE_POLICY\n",
			argv[0]);
		return 2;
	}

	out_path = argv[1];
	cgroup_path = argv[2];
	families[0] = (struct policy_family){
		.family = "build_graph",
		.object = argv[3],
		.cases = build_cases,
		.nr_cases = sizeof(build_cases) / sizeof(build_cases[0]),
		.negative_name = "missing.h",
	};
	families[1] = (struct policy_family){
		.family = "sandbox_fixture",
		.object = argv[4],
		.cases = fixture_cases,
		.nr_cases = sizeof(fixture_cases) / sizeof(fixture_cases[0]),
		.negative_name = "unmanaged.conf",
	};
	families[2] = (struct policy_family){
		.family = "checkpoint_restore",
		.object = argv[5],
		.cases = checkpoint_cases,
		.nr_cases = sizeof(checkpoint_cases) / sizeof(checkpoint_cases[0]),
		.negative_name = "current.tmp",
	};
	families[3] = (struct policy_family){
		.family = "cache_locality",
		.object = argv[6],
		.cases = cache_cases,
		.nr_cases = sizeof(cache_cases) / sizeof(cache_cases[0]),
		.negative_name = "passthrough.dat",
	};

	out = fopen(out_path, "a");
	if (!out) {
		perror("fopen");
		return 1;
	}

	for (i = 0; i < 4; i++)
		failures += run_family(&families[i], cgroup_path, out);

	fprintf(out,
		"{\"event\":\"policy-semantic-summary\",\"pass\":%s,"
		"\"families\":4,\"failures\":%d}\n",
		failures ? "false" : "true", failures);
	fclose(out);
	return failures ? 1 : 0;
}
