// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define TREE_FILES 64
#define NAMEI_EXT_NAME_MAX 64
#define BPF_NAMEI_EXT_LOOKUP 0
#define BPF_NAMEI_EXT_READDIR 1
#define BPF_NAMEI_EXT_REDIRECT 1
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

struct namei_ext_component_key {
	uint32_t event;
	uint32_t name_len;
	uint64_t cgroup_id;
	uint64_t parent_dev;
	uint64_t parent_ino;
	uint8_t name[NAMEI_EXT_NAME_MAX];
};

struct namei_ext_redirect_rule {
	uint32_t action;
	uint32_t target_len;
	uint32_t branch;
	uint32_t flags;
	uint8_t target[NAMEI_EXT_NAME_MAX];
};

struct bench_env {
	char root[PATH_MAX];
	char native[PATH_MAX];
	char alias[PATH_MAX];
	char backing[PATH_MAX];
	char tree_alias[TREE_FILES][PATH_MAX];
	char tree_backing[TREE_FILES][PATH_MAX];
	unsigned long long created_dirs;
	unsigned long long created_files;
	unsigned long long bytes_written;
	unsigned long long source_update_writes;
	unsigned long long source_update_bytes;
};

struct attached_policy {
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	int map_fd;
	bool attached;
};

static int latency_samples;
static int latency_batch;
static const char *bench_run_id;

static void run_suite(FILE *out, const char *variant, struct bench_env *env,
		      int samples, int iterations, bool policy);

struct usage_delta {
	long long user_usec;
	long long sys_usec;
	long long minor_faults;
	long long major_faults;
	long long voluntary_ctxt_switches;
	long long involuntary_ctxt_switches;
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

static long long timeval_delta_usec(const struct timeval *after,
				    const struct timeval *before)
{
	return (long long)(after->tv_sec - before->tv_sec) * 1000000LL +
	       (long long)(after->tv_usec - before->tv_usec);
}

static void fill_usage_delta(struct usage_delta *delta,
			     const struct rusage *before,
			     const struct rusage *after)
{
	delta->user_usec = timeval_delta_usec(&after->ru_utime,
					      &before->ru_utime);
	delta->sys_usec = timeval_delta_usec(&after->ru_stime,
					     &before->ru_stime);
	delta->minor_faults = after->ru_minflt - before->ru_minflt;
	delta->major_faults = after->ru_majflt - before->ru_majflt;
	delta->voluntary_ctxt_switches = after->ru_nvcsw - before->ru_nvcsw;
	delta->involuntary_ctxt_switches = after->ru_nivcsw - before->ru_nivcsw;
}

static void get_usage_or_die(FILE *out, const char *phase, int who,
			     struct rusage *usage)
{
	if (!getrusage(who, usage))
		return;
	fprintf(out,
		"{\"event\":\"bench_resource_error\",\"phase\":\"%s\","
		"\"who\":%d,\"errno\":%d}\n",
		phase, who, errno);
	fflush(out);
	exit(3);
}

static int parse_int_arg(const char *arg, int min, int *out)
{
	char *end = NULL;
	long value;

	errno = 0;
	value = strtol(arg, &end, 10);
	if (errno || !end || *end || value < min || value > INT_MAX)
		return -EINVAL;
	*out = (int)value;
	return 0;
}

static void emit(FILE *out, const char *event, const char *bench,
		 const char *variant, int sample, unsigned long long ops,
		 unsigned long long elapsed_ns, unsigned long long ok,
		 unsigned long long fail, const struct usage_delta *self,
		 const struct usage_delta *children)
{
	fprintf(out,
		"{\"event\":\"%s\",\"bench\":\"%s\",\"variant\":\"%s\","
		"\"sample\":%d,\"ops\":%llu,\"elapsed_ns\":%llu,"
		"\"ok\":%llu,\"fail\":%llu,"
		"\"user_usec\":%lld,\"sys_usec\":%lld,"
		"\"minor_faults\":%lld,\"major_faults\":%lld,"
		"\"voluntary_ctxt_switches\":%lld,"
		"\"involuntary_ctxt_switches\":%lld,"
		"\"child_user_usec\":%lld,\"child_sys_usec\":%lld,"
		"\"child_minor_faults\":%lld,\"child_major_faults\":%lld,"
		"\"child_voluntary_ctxt_switches\":%lld,"
		"\"child_involuntary_ctxt_switches\":%lld}\n",
		event, bench ? bench : "", variant ? variant : "", sample, ops,
		elapsed_ns, ok, fail,
		self ? self->user_usec : 0,
		self ? self->sys_usec : 0,
		self ? self->minor_faults : 0,
		self ? self->major_faults : 0,
		self ? self->voluntary_ctxt_switches : 0,
		self ? self->involuntary_ctxt_switches : 0,
		children ? children->user_usec : 0,
		children ? children->sys_usec : 0,
		children ? children->minor_faults : 0,
		children ? children->major_faults : 0,
		children ? children->voluntary_ctxt_switches : 0,
		children ? children->involuntary_ctxt_switches : 0);
	fflush(out);
}

static void emit_latency(FILE *out, const char *bench, const char *variant,
			 int sample, int latency_sample,
			 unsigned long long ops, unsigned long long elapsed_ns,
			 unsigned long long ok, unsigned long long fail,
			 const struct usage_delta *self,
			 const struct usage_delta *children)
{
	fprintf(out,
		"{\"event\":\"bench_latency\",\"bench\":\"%s\","
		"\"variant\":\"%s\",\"sample\":%d,\"latency_sample\":%d,"
		"\"ops\":%llu,\"elapsed_ns\":%llu,\"ok\":%llu,"
		"\"fail\":%llu,"
		"\"user_usec\":%lld,\"sys_usec\":%lld,"
		"\"minor_faults\":%lld,\"major_faults\":%lld,"
		"\"voluntary_ctxt_switches\":%lld,"
		"\"involuntary_ctxt_switches\":%lld,"
		"\"child_user_usec\":%lld,\"child_sys_usec\":%lld,"
		"\"child_minor_faults\":%lld,\"child_major_faults\":%lld,"
		"\"child_voluntary_ctxt_switches\":%lld,"
		"\"child_involuntary_ctxt_switches\":%lld}\n",
		bench ? bench : "", variant ? variant : "", sample,
		latency_sample, ops, elapsed_ns, ok, fail,
		self ? self->user_usec : 0,
		self ? self->sys_usec : 0,
		self ? self->minor_faults : 0,
		self ? self->major_faults : 0,
		self ? self->voluntary_ctxt_switches : 0,
		self ? self->involuntary_ctxt_switches : 0,
		children ? children->user_usec : 0,
		children ? children->sys_usec : 0,
		children ? children->minor_faults : 0,
		children ? children->major_faults : 0,
		children ? children->voluntary_ctxt_switches : 0,
		children ? children->involuntary_ctxt_switches : 0);
	fflush(out);
}

static void emit_namei_ext_setup(FILE *out, const char *variant, int sample,
				 bool pass, int err,
				 unsigned long long setup_ns,
				 const struct bench_env *env)
{
	fprintf(out,
		"{\"schema\":\"namei_ext.eval_osdi.namei_ext_raw.v1\","
		"\"event\":\"namei_ext-setup\","
		"\"run_id\":\"%s\",\"run_environment\":\"kvm\","
		"\"variant\":\"%s\",\"sample\":%d,"
		"\"pass\":%s,\"errno\":%d,\"setup_ns\":%llu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":0,\"bind_mounts\":0,"
		"\"overlay_mounts\":0,\"fuse_mounts\":0,"
		"\"bytes_copied\":0,\"bytes_written\":%llu}\n",
		bench_run_id ? bench_run_id : "", variant, sample,
		pass ? "true" : "false", err, setup_ns,
		env ? env->created_dirs : 0, env ? env->created_files : 0,
		env ? env->bytes_written : 0);
	fflush(out);
}

static void emit_namei_ext_update(FILE *out, const char *variant, int sample,
				  bool pass, int err,
				  unsigned long long update_ns,
				  unsigned long long source_writes,
				  unsigned long long policy_writes,
				  unsigned long long update_bytes)
{
	fprintf(out,
		"{\"schema\":\"namei_ext.eval_osdi.namei_ext_raw.v1\","
		"\"event\":\"namei_ext-update\","
		"\"run_id\":\"%s\",\"run_environment\":\"kvm\","
		"\"variant\":\"%s\",\"sample\":%d,"
		"\"pass\":%s,\"errno\":%d,\"update_ns\":%llu,"
		"\"source_update_writes\":%llu,"
		"\"policy_update_writes\":%llu,"
		"\"update_bytes_copied\":0,"
		"\"update_bytes_written\":%llu}\n",
		bench_run_id ? bench_run_id : "", variant, sample,
		pass ? "true" : "false", err, update_ns, source_writes,
		policy_writes, update_bytes);
	fflush(out);
}

static int write_content(const char *path, const char *content,
			 unsigned long long *bytes_written)
{
	int fd;
	size_t len = strlen(content);

	fd = open(path, O_CREAT | O_TRUNC | O_WRONLY, 0644);
	if (fd < 0)
		return -errno;
	if (write(fd, content, len) != (ssize_t)len) {
		int err = errno;

		close(fd);
		return -err;
	}
	if (close(fd))
		return -errno;
	if (bytes_written)
		*bytes_written += len;
	return 0;
}

static int write_file(const char *path, struct bench_env *env)
{
	int ret;

	ret = write_content(path, "x\n", env ? &env->bytes_written : NULL);
	if (!ret && env)
		env->created_files++;
	return ret;
}

static int mkdir_if_missing(const char *path)
{
	if (!mkdir(path, 0755) || errno == EEXIST)
		return 0;
	return -errno;
}

static int mkdir_counted(const char *path, struct bench_env *env)
{
	int ret;

	ret = mkdir_if_missing(path);
	if (!ret && env)
		env->created_dirs++;
	return ret;
}

static int current_cgroup_path(const char *mount_path, char *out, size_t size)
{
	char line[PATH_MAX + 32];
	FILE *in;

	in = fopen("/proc/self/cgroup", "r");
	if (!in)
		return -errno;
	while (fgets(line, sizeof(line), in)) {
		char *rel;
		int ret;

		if (strncmp(line, "0::", 3))
			continue;
		rel = line + 3;
		rel[strcspn(rel, "\n")] = 0;
		if (!strcmp(rel, "/"))
			ret = snprintf(out, size, "%s", mount_path);
		else
			ret = snprintf(out, size, "%s%s", mount_path, rel);
		fclose(in);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= size)
			return -ENAMETOOLONG;
		return 0;
	}
	fclose(in);
	return -ENOENT;
}

static int cgroup_id_from_path(const char *path, uint64_t *id_out)
{
	union {
		uint64_t cgid;
		unsigned char raw_bytes[8];
	} id = {};
	struct file_handle *fhp;
	struct file_handle *fhp2;
	int mount_id = 0;
	int saved_errno = 0;
	size_t fhsize;
	int err;

	fhsize = sizeof(*fhp);
	fhp = calloc(1, fhsize);
	if (!fhp)
		return -errno;

	errno = 0;
	err = name_to_handle_at(AT_FDCWD, path, fhp, &mount_id, 0);
	if (err >= 0 || errno != EOVERFLOW || fhp->handle_bytes != 8) {
		saved_errno = errno ? errno : EINVAL;
		free(fhp);
		return -saved_errno;
	}

	fhsize = sizeof(*fhp) + fhp->handle_bytes;
	fhp2 = realloc(fhp, fhsize);
	if (!fhp2) {
		saved_errno = errno;
		free(fhp);
		return -saved_errno;
	}
	fhp = fhp2;
	err = name_to_handle_at(AT_FDCWD, path, fhp, &mount_id, 0);
	if (err < 0) {
		saved_errno = errno;
		free(fhp);
		return -saved_errno;
	}

	memcpy(id.raw_bytes, fhp->f_handle, 8);
	free(fhp);
	if (!id.cgid)
		return -EINVAL;
	*id_out = id.cgid;
	return 0;
}

static int fill_key(struct namei_ext_component_key *key, uint32_t event,
		    uint64_t cgroup_id, const char *parent_dir,
		    const char *name)
{
	struct stat st;
	size_t len = strlen(name);

	if (len > NAMEI_EXT_NAME_MAX)
		return -ENAMETOOLONG;
	if (stat(parent_dir, &st))
		return -errno;
	memset(key, 0, sizeof(*key));
	key->event = event;
	key->name_len = len;
	key->cgroup_id = cgroup_id;
	key->parent_dev = st.st_dev;
	key->parent_ino = st.st_ino;
	memcpy(key->name, name, len);
	return 0;
}

static int fill_rule(struct namei_ext_redirect_rule *rule, const char *target,
		     uint32_t branch)
{
	size_t len = strlen(target);

	if (len > NAMEI_EXT_NAME_MAX)
		return -ENAMETOOLONG;
	memset(rule, 0, sizeof(*rule));
	rule->action = BPF_NAMEI_EXT_REDIRECT;
	rule->target_len = len;
	rule->branch = branch;
	memcpy(rule->target, target, len);
	return 0;
}

static int update_redirect_rule(int map_fd, uint64_t cgroup_id,
				uint32_t event, const char *parent_dir,
				const char *name, const char *target,
				uint32_t branch)
{
	struct namei_ext_component_key key;
	struct namei_ext_redirect_rule rule;
	int ret;

	ret = fill_key(&key, event, cgroup_id, parent_dir, name);
	if (ret)
		return ret;
	ret = fill_rule(&rule, target, branch);
	if (ret)
		return ret;
	if (bpf_map_update_elem(map_fd, &key, &rule, BPF_ANY))
		return -errno;
	return 0;
}

static int setup_env(struct bench_env *env)
{
	char dir[PATH_MAX];
	int err;
	int i;

	strncpy(env->root, "/tmp/namei-ext-bench-XXXXXX", sizeof(env->root));
	if (!mkdtemp(env->root))
		return -errno;
	env->created_dirs++;

	if (set_path(env->native, sizeof(env->native), "%s/native",
		     env->root) ||
	    set_path(env->alias, sizeof(env->alias), "%s/tool",
		     env->root) ||
	    set_path(env->backing, sizeof(env->backing), "%s/tool.real",
		     env->root))
		return -ENAMETOOLONG;
	err = write_file(env->native, env);
	if (err)
		return err;
	err = write_file(env->backing, env);
	if (err)
		return err;
	if (chmod(env->native, 0755) || chmod(env->backing, 0755))
		return -errno;

	if (set_path(dir, sizeof(dir), "%s/tree", env->root) ||
	    mkdir_counted(dir, env))
		return -errno;
	if (set_path(dir, sizeof(dir), "%s/tree/include", env->root) ||
	    mkdir_counted(dir, env))
		return -errno;

	for (i = 0; i < TREE_FILES; i++) {
		if (set_path(dir, sizeof(dir), "%s/tree/include/pkg%02d",
			     env->root, i) ||
		    mkdir_counted(dir, env))
			return -errno;
		if (set_path(env->tree_alias[i], sizeof(env->tree_alias[i]),
			     "%s/tool", dir))
			return -errno;
		if (set_path(env->tree_backing[i],
			     sizeof(env->tree_backing[i]), "%s/tool.real",
			     dir))
			return -errno;
		if (write_file(env->tree_backing[i], env))
			return -errno;
		if (chmod(env->tree_backing[i], 0755))
			return -errno;
	}
	return 0;
}

static int update_env_backing(struct bench_env *env)
{
	unsigned long long bytes = 0;
	int ret;
	int i;

	ret = write_content(env->backing, "tool-updated\n", &bytes);
	if (ret)
		return ret;
	env->source_update_writes++;
	for (i = 0; i < TREE_FILES; i++) {
		ret = write_content(env->tree_backing[i], "tool-updated\n",
				    &bytes);
		if (ret)
			return ret;
		env->source_update_writes++;
	}
	env->source_update_bytes += bytes;
	return 0;
}

static void cleanup_env(struct bench_env *env);

static int emit_setup_update_sample(FILE *out, int sample)
{
	struct bench_env env;
	unsigned long long start;
	int err;

	memset(&env, 0, sizeof(env));
	start = now_ns();
	err = setup_env(&env);
	emit_namei_ext_setup(out, "backing_tree", sample, !err,
			     err ? -err : 0, now_ns() - start, &env);
	if (err)
		goto out;

	start = now_ns();
	err = update_env_backing(&env);
	emit_namei_ext_update(out, "backing_tree", sample, !err,
			      err ? -err : 0, now_ns() - start,
			      env.source_update_writes, 0,
			      env.source_update_bytes);
out:
	if (env.root[0])
		cleanup_env(&env);
	return err;
}

static int populate_table_hit_policy(struct attached_policy *policy,
				     const char *cgroup_path,
				     struct bench_env *env,
				     unsigned long long *rules_out)
{
	char current_cgroup[PATH_MAX];
	char parent[PATH_MAX];
	uint64_t cgroup_id = 0;
	unsigned long long rules = 0;
	int ret;
	int i;

	if (policy->map_fd < 0)
		return -ENOENT;
	ret = current_cgroup_path(cgroup_path, current_cgroup,
				  sizeof(current_cgroup));
	if (ret)
		return ret;
	ret = cgroup_id_from_path(current_cgroup, &cgroup_id);
	if (ret)
		return ret;
	ret = update_redirect_rule(policy->map_fd, cgroup_id,
				   BPF_NAMEI_EXT_LOOKUP, env->root, "tool",
				   "tool.real", 1);
	if (ret)
		return ret;
	rules++;
	ret = update_redirect_rule(policy->map_fd, cgroup_id,
				   BPF_NAMEI_EXT_READDIR, env->root,
				   "tool.real", "tool", 2);
	if (ret)
		return ret;
	rules++;

	for (i = 0; i < TREE_FILES; i++) {
		ret = set_path(parent, sizeof(parent), "%s/tree/include/pkg%02d",
			       env->root, i);
		if (ret)
			return ret;
		ret = update_redirect_rule(policy->map_fd, cgroup_id,
					   BPF_NAMEI_EXT_LOOKUP, parent,
					   "tool", "tool.real", i + 3);
		if (ret)
			return ret;
		rules++;
	}
	*rules_out = rules;
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
	struct bpf_map *map;
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
	map = bpf_object__find_map_by_name(obj, "exact_redirects");

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
	policy->map_fd = map ? bpf_map__fd(map) : -1;
	policy->attached = true;
	return 0;

err_close_cgroup:
	close(cgroup_fd);
err_close_obj:
	bpf_object__close(obj);
	return -1;
}

static void init_policy(struct attached_policy *policy)
{
	policy->obj = NULL;
	policy->cgroup_fd = -1;
	policy->prog_fd = -1;
	policy->map_fd = -1;
	policy->attached = false;
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
	policy->map_fd = -1;
	return err;
}

static int run_attached_variant(FILE *out, const char *variant,
				const char *obj_path, const char *cgroup_path,
				struct bench_env *env, int samples,
				int iterations, bool redirects)
{
	struct attached_policy policy;
	int err;

	init_policy(&policy);
	if (load_and_attach(obj_path, cgroup_path, &policy)) {
		emit(out, "bench_attach", "", variant, 0, 0, 0, 0, 1,
		     NULL, NULL);
		return -1;
	}
	emit(out, "bench_attach", "", variant, 0, 0, 0, 1, 0, NULL, NULL);
	run_suite(out, variant, env, samples, iterations, redirects);
	err = destroy_policy(&policy);
	if (err) {
		emit(out, "bench_detach", "", variant, 0, 0, 0, 0, 1,
		     NULL, NULL);
		return -1;
	}
	emit(out, "bench_detach", "", variant, 0, 0, 0, 1, 0, NULL, NULL);
	return 0;
}

static int run_table_hit_variant(FILE *out, const char *obj_path,
				 const char *cgroup_path, struct bench_env *env,
				 int samples, int iterations)
{
	struct attached_policy policy;
	unsigned long long update_start;
	unsigned long long rules;
	int sample;
	int err;

	init_policy(&policy);
	if (load_and_attach(obj_path, cgroup_path, &policy)) {
		emit(out, "bench_attach", "", "table_redirect_hit", 0, 0, 0,
		     0, 1, NULL, NULL);
		return -1;
	}
	emit(out, "bench_attach", "", "table_redirect_hit", 0, 0, 0, 1, 0,
	     NULL, NULL);
	for (sample = 0; sample < samples; sample++) {
		rules = 0;
		update_start = now_ns();
		err = populate_table_hit_policy(&policy, cgroup_path, env,
						&rules);
		emit_namei_ext_update(out, "table_redirect_hit", sample, !err,
				      err ? -err : 0, now_ns() - update_start,
				      0, rules, 0);
		if (err) {
			emit(out, "bench_map_update", "", "table_redirect_hit",
			     sample, rules, 0, 0, 1, NULL, NULL);
			destroy_policy(&policy);
			return -1;
		}
		emit(out, "bench_map_update", "", "table_redirect_hit",
		     sample, rules, 0, rules, 0, NULL, NULL);
	}
	run_suite(out, "table_redirect_hit", env, samples, iterations, true);
	err = destroy_policy(&policy);
	if (err) {
		emit(out, "bench_detach", "", "table_redirect_hit", 0, 0, 0,
		     0, 1, NULL, NULL);
		return -1;
	}
	emit(out, "bench_detach", "", "table_redirect_hit", 0, 0, 0, 1, 0,
	     NULL, NULL);
	return 0;
}

struct path_ctx {
	const char *path;
	int want_errno;
};

struct access_ctx {
	const char *path;
	int mode;
	int want_errno;
};

struct readdir_ctx {
	const char *path;
	bool policy;
};

struct tree_ctx {
	struct bench_env *env;
	bool policy;
};

typedef void (*bench_op_fn)(void *ctx, unsigned long long *ops,
			    unsigned long long *ok,
			    unsigned long long *fail);

struct bench_case {
	const char *name;
	int iterations;
	bench_op_fn op;
	void *ctx;
};

enum variant_kind {
	VARIANT_BASELINE,
	VARIANT_ATTACHED,
	VARIANT_TABLE_HIT,
};

struct variant_case {
	const char *name;
	enum variant_kind kind;
	const char *obj_path;
	bool redirects;
};

static uint64_t order_state;
static unsigned long long order_seed_hash;
static unsigned long long bench_order_seq;
static bool randomize_order = true;
static const char *variant_filter;

static uint64_t fnv1a64(const char *s)
{
	uint64_t h = 1469598103934665603ULL;

	for (; s && *s; s++) {
		h ^= (unsigned char)*s;
		h *= 1099511628211ULL;
	}
	return h;
}

static uint64_t prng_next(void)
{
	uint64_t x = order_state;

	x ^= x >> 12;
	x ^= x << 25;
	x ^= x >> 27;
	order_state = x;
	return x * 2685821657736338717ULL;
}

static void init_order_seed(void)
{
	const char *seed = getenv("NAMEI_EXT_BENCH_ORDER_SEED");
	const char *disable = getenv("NAMEI_EXT_BENCH_RANDOMIZE");

	if (disable && !strcmp(disable, "0"))
		randomize_order = false;
	if (!seed || !seed[0])
		seed = "namei-ext-bench-default-seed";
	order_seed_hash = fnv1a64(seed);
	order_state = order_seed_hash ? order_seed_hash :
				     0x9e3779b97f4a7c15ULL;
}

static void shuffle_order(int *order, int count)
{
	int i;

	for (i = 0; i < count; i++)
		order[i] = i;
	if (!randomize_order)
		return;
	for (i = count - 1; i > 0; i--) {
		int j = prng_next() % (unsigned int)(i + 1);
		int tmp = order[i];

		order[i] = order[j];
		order[j] = tmp;
	}
}

static bool token_equals(const char *token, size_t len, const char *name)
{
	return strlen(name) == len && !strncmp(token, name, len);
}

static bool variant_name_known(const char *token, size_t len)
{
	return token_equals(token, len, "baseline") ||
	       token_equals(token, len, "pass_only") ||
	       token_equals(token, len, "table_redirect_empty") ||
	       token_equals(token, len, "table_redirect_hit") ||
	       token_equals(token, len, "policy");
}

static bool variant_requested(const char *name)
{
	const char *p = variant_filter;

	if (!p || !p[0])
		return true;
	while (*p) {
		size_t len;

		while (*p == ' ' || *p == ',' || *p == ':')
			p++;
		len = strcspn(p, " ,:");
		if (len && token_equals(p, len, name))
			return true;
		p += len;
	}
	return false;
}

static int validate_variant_filter(void)
{
	const char *p = variant_filter;
	int tokens = 0;

	if (!p || !p[0])
		return 0;
	while (*p) {
		size_t len;

		while (*p == ' ' || *p == ',' || *p == ':')
			p++;
		len = strcspn(p, " ,:");
		if (!len)
			break;
		tokens++;
		if (!variant_name_known(p, len))
			return -EINVAL;
		p += len;
	}
	return tokens ? 0 : -EINVAL;
}

static void maybe_add_variant(struct variant_case *variants, int *variant_count,
			      const struct variant_case *variant)
{
	if (!variant_requested(variant->name))
		return;
	variants[(*variant_count)++] = *variant;
}

static void emit_order_start(FILE *out)
{
	fprintf(out,
		"{\"event\":\"bench_order_start\","
		"\"randomized_order\":%s,\"seed_hash\":%llu}\n",
		randomize_order ? "true" : "false", order_seed_hash);
	fflush(out);
}

static void emit_variant_order(FILE *out, const char *variant,
			       unsigned long long sequence)
{
	fprintf(out,
		"{\"event\":\"bench_variant_order\","
		"\"randomized_order\":%s,\"sequence\":%llu,"
		"\"variant\":\"%s\",\"seed_hash\":%llu}\n",
		randomize_order ? "true" : "false", sequence, variant,
		order_seed_hash);
	fflush(out);
}

static void emit_bench_order(FILE *out, const char *variant, int sample,
			     unsigned long long sequence, const char *bench)
{
	fprintf(out,
		"{\"event\":\"bench_order\","
		"\"randomized_order\":%s,\"sequence\":%llu,"
		"\"variant\":\"%s\",\"sample\":%d,\"bench\":\"%s\","
		"\"seed_hash\":%llu}\n",
		randomize_order ? "true" : "false", sequence, variant, sample,
		bench, order_seed_hash);
	fflush(out);
}

static void op_stat_path(void *data, unsigned long long *ops,
			 unsigned long long *ok, unsigned long long *fail)
{
	struct path_ctx *ctx = data;
	struct stat st;

	(*ops)++;
	errno = 0;
	if (!stat(ctx->path, &st)) {
		if (!ctx->want_errno)
			(*ok)++;
		else
			(*fail)++;
	} else if (errno == ctx->want_errno) {
		(*ok)++;
	} else {
		(*fail)++;
	}
}

static void op_open_path(void *data, unsigned long long *ops,
			 unsigned long long *ok, unsigned long long *fail)
{
	struct path_ctx *ctx = data;
	int fd;

	(*ops)++;
	errno = 0;
	fd = open(ctx->path, O_RDONLY);
	if (fd >= 0) {
		close(fd);
		if (!ctx->want_errno)
			(*ok)++;
		else
			(*fail)++;
	} else if (errno == ctx->want_errno) {
		(*ok)++;
	} else {
		(*fail)++;
	}
}

static void op_access_path(void *data, unsigned long long *ops,
			   unsigned long long *ok, unsigned long long *fail)
{
	struct access_ctx *ctx = data;

	(*ops)++;
	errno = 0;
	if (!access(ctx->path, ctx->mode)) {
		if (!ctx->want_errno)
			(*ok)++;
		else
			(*fail)++;
	} else if (errno == ctx->want_errno) {
		(*ok)++;
	} else {
		(*fail)++;
	}
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

static void op_exec_path(void *data, unsigned long long *ops,
			 unsigned long long *ok, unsigned long long *fail)
{
	struct path_ctx *ctx = data;

	(*ops)++;
	if (!exec_errno_once(ctx->path, ctx->want_errno))
		(*ok)++;
	else
		(*fail)++;
}

static void op_readdir_alias_view(void *data, unsigned long long *ops,
				  unsigned long long *ok,
				  unsigned long long *fail)
{
	struct readdir_ctx *ctx = data;
	bool saw_native = false;
	bool saw_alias = false;
	bool saw_backing = false;
	struct dirent *de;
	DIR *dir;

	errno = 0;
	dir = opendir(ctx->path);
	if (!dir) {
		(*fail)++;
		return;
	}
	while ((de = readdir(dir))) {
		(*ops)++;
		if (!strcmp(de->d_name, "native"))
			saw_native = true;
		if (!strcmp(de->d_name, "tool"))
			saw_alias = true;
		if (!strcmp(de->d_name, "tool.real"))
			saw_backing = true;
	}
	if (errno) {
		(*fail)++;
		closedir(dir);
		return;
	}
	closedir(dir);
	if (saw_native &&
	    ((ctx->policy && saw_alias && !saw_backing) ||
	     (!ctx->policy && !saw_alias && saw_backing)))
		(*ok)++;
	else
		(*fail)++;
}

static void op_tree_walk(void *data, unsigned long long *ops,
			 unsigned long long *ok, unsigned long long *fail)
{
	struct tree_ctx *ctx = data;
	struct stat st;
	int j;

	for (j = 0; j < TREE_FILES; j++) {
		const char *path = ctx->policy ? ctx->env->tree_alias[j] :
						 ctx->env->tree_backing[j];

		(*ops)++;
		if (!stat(path, &st))
			(*ok)++;
		else
			(*fail)++;
	}
}

static void run_op_batch(FILE *out, const char *bench, const char *variant,
			 int sample, int latency_sample, int iterations,
			 bench_op_fn op, void *ctx)
{
	struct rusage self_before, self_after, children_before, children_after;
	struct usage_delta self_delta, children_delta;
	unsigned long long start, end, ops = 0, ok = 0, fail = 0;
	int i;

	get_usage_or_die(out, "before-self", RUSAGE_SELF, &self_before);
	get_usage_or_die(out, "before-children", RUSAGE_CHILDREN,
			 &children_before);
	start = now_ns();
	for (i = 0; i < iterations; i++)
		op(ctx, &ops, &ok, &fail);
	end = now_ns();
	get_usage_or_die(out, "after-self", RUSAGE_SELF, &self_after);
	get_usage_or_die(out, "after-children", RUSAGE_CHILDREN,
			 &children_after);
	fill_usage_delta(&self_delta, &self_before, &self_after);
	fill_usage_delta(&children_delta, &children_before, &children_after);
	if (latency_sample >= 0)
		emit_latency(out, bench, variant, sample, latency_sample, ops,
			     end - start, ok, fail, &self_delta,
			     &children_delta);
	else
		emit(out, "bench", bench, variant, sample, ops, end - start,
		     ok, fail, &self_delta, &children_delta);
}

static void run_measured_bench(FILE *out, const char *bench,
			       const char *variant, int sample, int iterations,
			       bench_op_fn op, void *ctx)
{
	int latency_sample;

	run_op_batch(out, bench, variant, sample, -1, iterations, op, ctx);
	for (latency_sample = 0; latency_sample < latency_samples;
	     latency_sample++)
		run_op_batch(out, bench, variant, sample, latency_sample,
			     latency_batch, op, ctx);
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
		struct path_ctx native_stat = { env->native, 0 };
		struct path_ctx tool_stat = { tool_path, 0 };
		struct access_ctx tool_access = { tool_path, X_OK, 0 };
		struct path_ctx tool_open = { tool_path, 0 };
		struct path_ctx tool_exec = { tool_path, ENOEXEC };
		struct readdir_ctx readdir = { env->root, policy };
		struct tree_ctx tree = { env, policy };
		struct bench_case cases[] = {
			{ "lookup_native_hot", iterations, op_stat_path,
			  &native_stat },
			{ "lookup_tool_redirect", iterations, op_stat_path,
			  &tool_stat },
			{ "access_tool_redirect", iterations, op_access_path,
			  &tool_access },
			{ "open_tool_redirect", iterations, op_open_path,
			  &tool_open },
			{ "exec_tool_redirect", exec_iters, op_exec_path,
			  &tool_exec },
			{ "readdir_alias_view", readdir_iters,
			  op_readdir_alias_view, &readdir },
			{ "build_tree_stat_walk", tree_iters, op_tree_walk,
			  &tree },
		};
		int order[ARRAY_SIZE(cases)];
		size_t i;

		shuffle_order(order, ARRAY_SIZE(cases));
		for (i = 0; i < ARRAY_SIZE(cases); i++) {
			struct bench_case *c = &cases[order[i]];

			emit_bench_order(out, variant, sample, bench_order_seq++,
					 c->name);
			run_measured_bench(out, c->name, variant, sample,
					   c->iterations, c->op, c->ctx);
		}
	}
}

static int run_variant_case(FILE *out, const struct variant_case *variant,
			    const char *cgroup_path, struct bench_env *env,
			    int samples, int iterations)
{
	if (variant->kind == VARIANT_BASELINE) {
		run_suite(out, variant->name, env, samples, iterations,
			  variant->redirects);
		return 0;
	}
	if (variant->kind == VARIANT_TABLE_HIT)
		return run_table_hit_variant(out, variant->obj_path, cgroup_path,
					     env, samples, iterations);
	return run_attached_variant(out, variant->name, variant->obj_path,
				    cgroup_path, env, samples, iterations,
				    variant->redirects);
}

int main(int argc, char **argv)
{
	const char *cgroup_path = "/sys/fs/cgroup";
	struct variant_case variants[5];
	int variant_order[ARRAY_SIZE(variants)];
	struct bench_env env;
	FILE *out;
	int samples;
	int iterations;
	int variant_count = 0;
	int i;
	int ret = 1;
	int err;
	unsigned long long start;

	if (argc < 5 || argc > 10) {
		fprintf(stderr,
			"usage: %s RESULT_JSONL REDIRECT_POLICY_BPF_O SAMPLES ITERATIONS [CGROUP [PASS_ONLY_BPF_O [TABLE_REDIRECT_BPF_O [LATENCY_SAMPLES [LATENCY_BATCH]]]]]\n",
			argv[0]);
		return 2;
	}
	if (argc >= 6)
		cgroup_path = argv[5];

	if (parse_int_arg(argv[3], 1, &samples) ||
	    parse_int_arg(argv[4], 1, &iterations))
		return 2;
	if (argc >= 9 && parse_int_arg(argv[8], 0, &latency_samples))
		return 2;
	if (argc >= 10 && parse_int_arg(argv[9], 1, &latency_batch))
		return 2;
	if (latency_samples > 0 && latency_batch <= 0)
		latency_batch = 1;
	variant_filter = getenv("NAMEI_EXT_BENCH_VARIANTS");
	bench_run_id = getenv("NAMEI_EXT_RUN_ID");
	if (validate_variant_filter()) {
		fprintf(stderr, "invalid NAMEI_EXT_BENCH_VARIANTS\n");
		return 2;
	}
	init_order_seed();

	out = fopen(argv[1], "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}
	emit_order_start(out);

	memset(&env, 0, sizeof(env));
	start = now_ns();
	err = setup_env(&env);
	emit_namei_ext_setup(out, "backing_tree", 0, !err, err ? -err : 0,
			     now_ns() - start, &env);
	if (err) {
		emit(out, "bench_setup", "", "", 0, 0, 0, 0, 1, NULL, NULL);
		goto out_close;
	}
	emit(out, "bench_setup", "", "baseline", 0, 0, 0, 1, 0, NULL,
	     NULL);
	start = now_ns();
	err = update_env_backing(&env);
	emit_namei_ext_update(out, "backing_tree", 0, !err, err ? -err : 0,
			      now_ns() - start, env.source_update_writes, 0,
			      env.source_update_bytes);
	if (err)
		goto out_cleanup;
	for (i = 1; i < samples; i++) {
		err = emit_setup_update_sample(out, i);
		if (err)
			goto out_cleanup;
	}
	maybe_add_variant(variants, &variant_count, &(struct variant_case) {
		.name = "baseline",
		.kind = VARIANT_BASELINE,
		.obj_path = NULL,
		.redirects = false,
	});
	if (argc >= 7)
		maybe_add_variant(variants, &variant_count,
				  &(struct variant_case) {
			.name = "pass_only",
			.kind = VARIANT_ATTACHED,
			.obj_path = argv[6],
			.redirects = false,
		});
	if (argc >= 8) {
		maybe_add_variant(variants, &variant_count,
				  &(struct variant_case) {
			.name = "table_redirect_empty",
			.kind = VARIANT_ATTACHED,
			.obj_path = argv[7],
			.redirects = false,
		});
		maybe_add_variant(variants, &variant_count,
				  &(struct variant_case) {
			.name = "table_redirect_hit",
			.kind = VARIANT_TABLE_HIT,
			.obj_path = argv[7],
			.redirects = true,
		});
	}
	maybe_add_variant(variants, &variant_count, &(struct variant_case) {
		.name = "policy",
		.kind = VARIANT_ATTACHED,
		.obj_path = argv[2],
		.redirects = true,
	});
	if (!variant_count) {
		fprintf(stderr, "no benchmark variants selected\n");
		ret = 2;
		goto out_cleanup;
	}
	shuffle_order(variant_order, variant_count);
	for (i = 0; i < variant_count; i++) {
		struct variant_case *variant = &variants[variant_order[i]];

		emit_variant_order(out, variant->name, i);
		if (run_variant_case(out, variant, cgroup_path, &env, samples,
				     iterations))
			goto out_cleanup;
	}

	ret = 0;
out_cleanup:
	cleanup_env(&env);
out_close:
	emit(out, "bench_summary", "", "", 0, 0, 0, ret ? 0 : 1,
	     ret ? 1 : 0, NULL, NULL);
	fclose(out);
	return ret;
}
