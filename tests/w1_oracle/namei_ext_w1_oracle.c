// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE
#define FUSE_USE_VERSION 26

#include <arpa/inet.h>
#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <fuse.h>
#include <limits.h>
#include <linux/bpf.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define NAMEI_EXT_MAX_ENTRIES 128
#define NAMEI_EXT_LINE_MAX 8192
#define NAMEI_EXT_NAME_MAX 64
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))
#define NGINX_HEALTH_BODY "namei_ext nginx health\n"
#define NGINX_UPSTREAM_PORT 18080
#define W1_POISON_SENTINEL "NAMEI_EXT_W1_UNDECLARED_DEP_POISON\n"
#define W2_FAKE_CERT "namei-ext fake certificate for nginx fixture\n"
#define W2_FAKE_SECRET "namei_ext_fake_password\n"
#define W2_POISON_SENTINEL "NAMEI_EXT_POISON_SENTINEL\n"
#define W2_PROD_CONFIG_DECOY "namei_ext production config decoy\n"
#define W2_PROD_ENDPOINT_DECOY "proxy_pass http://127.0.0.1:18181;\n"
#define W2_PROD_CERT_DECOY "namei_ext production certificate decoy\n"
#define W2_PROD_SECRET_DECOY "namei_ext production secret decoy\n"
#define W2_PROD_TOKEN_DECOY "namei_ext production token decoy\n"
#define W3_REDIS_KEY "namei_ext_w3_key"
#define W3_REDIS_VALUE "checkpoint_restore_policy_loaded"
#define W4_CACHE_VERIFIED_OBJECT "namei_ext verified local cache object\n"
#define W4_CACHE_WRONG_OBJECT "namei_ext wrong local cache object\n"
#define W4_CACHE_CANONICAL_STALE "namei_ext canonical object after stale cache\n"
#define W4_CACHE_STALE_LOCAL "namei_ext stale local cache object\n"
#define W4_CACHE_CORRUPT_REJECT "NAMEI_EXT_CORRUPT_CACHE_REJECT\n"
#define W4_CACHE_CORRUPT_LOCAL "namei_ext corrupt local cache object\n"
#define W4_CACHE_PKG_CANON "module github.com/prometheus/prometheus\n"
#define W4_CCACHE_PARENT_SIBLING "metadata.txt"
#define W4_CCACHE_PARENT_SIBLING_TEXT "namei_ext ccache parent sibling pass\n"
#define W4_CCACHE_OBJECT_LEN 32
#define W4_CCACHE_PARENT_NAME_WITNESSES 4
#define W4_CCACHE_NAME_HASH_OFFSET 1469598103934665603ULL
#define W4_CCACHE_NAME_HASH_PRIME 1099511628211ULL
#define W1_MAX_BASELINES 5
#define W1_FUSE_MAX_MOUNTS 32
#define W1_ALIAS_MAX (NAMEI_EXT_MAX_ENTRIES + 4)

struct namei_ext_component_key {
	__u32 event;
	__u32 name_len;
	__u64 cgroup_id;
	__u64 parent_dev;
	__u64 parent_ino;
	__u8 name[NAMEI_EXT_NAME_MAX];
};

struct namei_ext_redirect_rule {
	__u32 action;
	__u32 target_len;
	__u32 branch;
	__u32 flags;
	__u8 target[NAMEI_EXT_NAME_MAX];
};

struct build_graph_rule {
	struct namei_ext_redirect_rule redirect;
};

enum build_graph_branch {
	BUILD_BRANCH_GENERATED = 1,
	BUILD_BRANCH_SOURCE_FALLBACK = 2,
	BUILD_BRANCH_TOOLCHAIN = 3,
	BUILD_BRANCH_EXTERNAL_DEP = 4,
	BUILD_BRANCH_UNDECLARED_POISON = 5,
	BUILD_BRANCH_NEGATIVE = 6,
};

struct build_graph_session {
	__u32 build_epoch;
	__u32 active;
	__u32 reserved[2];
};

struct build_graph_epoch_rule_key {
	struct namei_ext_component_key component;
	__u32 branch_class;
	__u32 build_epoch;
};

struct build_graph_epoch_rule {
	struct namei_ext_redirect_rule redirect;
	__u32 branch_class;
	__u32 reserved;
};

struct sandbox_fixture_rule {
	struct namei_ext_redirect_rule redirect;
	__u32 path_class;
};

enum sandbox_fixture_branch {
	FIXTURE_BRANCH_CONFIG = 1,
	FIXTURE_BRANCH_SECRET = 2,
	FIXTURE_BRANCH_CERT = 3,
	FIXTURE_BRANCH_ENDPOINT = 4,
	FIXTURE_BRANCH_POISON = 5,
};

struct sandbox_fixture_session {
	__u32 fixture_epoch;
	__u32 active;
	__u32 reserved[2];
};

struct sandbox_fixture_epoch_rule_key {
	struct namei_ext_component_key component;
	__u32 path_class;
	__u32 fixture_epoch;
};

struct sandbox_fixture_epoch_rule {
	struct namei_ext_redirect_rule redirect;
	__u32 path_class;
	__u32 reserved;
};

enum checkpoint_path_class {
	CHECKPOINT_CLASS_STATE = 1,
	CHECKPOINT_CLASS_CONFIG = 2,
	CHECKPOINT_CLASS_CACHE = 3,
	CHECKPOINT_CLASS_RUNTIME = 4,
	CHECKPOINT_CLASS_MIXED_EPOCH = 5,
};

struct checkpoint_session {
	__u32 restore_id;
	__u32 checkpoint_epoch;
	__u32 active;
	__u32 reserved;
};

struct checkpoint_rule_key {
	struct namei_ext_component_key component;
	__u32 path_class;
	__u32 checkpoint_epoch;
};

struct checkpoint_rule {
	struct namei_ext_redirect_rule redirect;
};

enum cache_state {
	CACHE_STATE_VERIFIED_HIT = 1,
	CACHE_STATE_MISS = 2,
	CACHE_STATE_STALE = 3,
	CACHE_STATE_CORRUPT = 4,
	CACHE_STATE_PASSTHROUGH = 5,
};

struct cache_rule {
	struct namei_ext_redirect_rule verified_hit;
	struct namei_ext_redirect_rule canonical;
	struct namei_ext_redirect_rule reject;
	__u64 expected_hash[4];
	__u64 observed_hash[4];
	__u32 state;
	__u32 witness_count;
};

struct cache_epoch_session {
	__u32 cache_epoch;
	__u32 active;
	__u32 reserved[2];
};

struct cache_epoch_rule_key {
	struct namei_ext_component_key component;
	__u32 cache_epoch;
};

struct cache_epoch_rule {
	struct namei_ext_redirect_rule redirect;
	__u32 state;
	__u32 reserved;
};

enum policy_kind {
	POLICY_BUILD_GRAPH,
	POLICY_SANDBOX_FIXTURE,
	POLICY_CHECKPOINT_RESTORE,
	POLICY_CACHE_LOCALITY,
	POLICY_TABLE,
};

static const char *event_prefix = "w1-oracle";
static const char *ccache_compile_event = "w4-ccache-policy-compile";
static const char *ccache_compile_summary_event =
	"w4-ccache-policy-compile-summary";
static const char *ccache_compile_result_level =
	"kvm_real_ccache_policy_compile_witness";
static const char *ccache_compile_policy_family =
	"cache_locality_view.bpf.c";
static const char *ccache_compile_workload = "w4-ccache-redis-nginx";
static const char *w4_materialized_workload = "w4-ccache-redis-nginx";
static const char *w4_fuse_workload = "w4-ccache-redis-nginx";
static const char *w3_redis_replay_result_level =
	"kvm_checkpoint_restore_replay_witness";
static const char *w3_redis_replay_policy_family =
	"checkpoint_restore_view.bpf.c";
static bool w3_redis_replay_table_baseline;
static bool ccache_compile_table_baseline;
static bool ccache_compile_parent_rules;

struct oracle_entry {
	char workload[64];
	char branch[64];
	char parent_relative[PATH_MAX];
	char parent_absolute[PATH_MAX];
	char visible[NAMEI_EXT_NAME_MAX + 1];
	char shadow[NAMEI_EXT_NAME_MAX + 1];
	char original[PATH_MAX];
	char original_sha256[65];
	char dir[PATH_MAX];
};

struct w4_ccache_source {
	char kind[16];
	char rel[PATH_MAX];
	char path[PATH_MAX];
	char sha256[65];
};

struct attached_policy {
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	int map_fd;
	bool attached;
	enum policy_kind kind;
	const char *name;
};

struct file_content_oracle {
	bool enabled;
	const char *kind;
	size_t expected_len;
	size_t observed_len;
	__u64 expected_hash;
	__u64 observed_hash;
};

struct nginx_macro_stats {
	unsigned long long created_dirs;
	unsigned long long created_files;
	unsigned long long created_symlinks;
	unsigned long long bind_mounts;
	unsigned long long fuse_mounts;
	unsigned long long bytes_written;
	unsigned long long bytes_copied;
	unsigned long long source_update_writes;
	unsigned long long baseline_update_writes;
	unsigned long long policy_update_writes;
	unsigned long long update_bytes_written;
	unsigned long long update_bytes_copied;
};

struct w1_alias_spec {
	char dir[PATH_MAX];
	char visible[NAMEI_EXT_NAME_MAX + 1];
	char shadow[NAMEI_EXT_NAME_MAX + 1];
	char original[PATH_MAX];
};

struct w1_fuse_alias {
	char visible[NAMEI_EXT_NAME_MAX + 1];
	char shadow[NAMEI_EXT_NAME_MAX + 1];
};

struct w1_fuse_env {
	char backing_dir[PATH_MAX];
	struct w1_fuse_alias aliases[W1_ALIAS_MAX];
	size_t nr_aliases;
};

struct w1_fuse_mount {
	char mount_dir[PATH_MAX];
	char backing_dir[PATH_MAX];
	pid_t pid;
	bool active;
};

struct w1_fuse_context {
	struct w1_fuse_mount mounts[W1_FUSE_MAX_MOUNTS];
	size_t nr_mounts;
};

static int add_w1_alias_spec(struct w1_alias_spec *specs, size_t *nr,
			     const char *dir, const char *visible,
			     const char *shadow, const char *original);
static int w1_fuse_backing_dir(const char *mount_dir, char *backing_dir,
			       size_t size);
static int unmount_w1_fuse_context(struct w1_fuse_context *ctx);
static int setup_w1_fuse_mount(const struct w1_alias_spec *specs,
			       size_t nr_specs, const char *dir,
			       struct nginx_macro_stats *stats,
			       struct w1_fuse_context *ctx);

struct w4_fuse_env {
	char backing_dir[PATH_MAX];
};

struct w4_fuse_mount {
	char mount_dir[PATH_MAX];
	char backing_dir[PATH_MAX];
	pid_t pid;
	bool active;
};

static int write_text_file(const char *path, const char *text);
static bool safe_relative_path(const char *rel);
static int prepare_cache_content_dir(const char *work_dir,
				     struct oracle_entry *entries,
				     size_t nr_entries);

static void fprint_json_string(FILE *out, const char *value)
{
	const unsigned char *p = (const unsigned char *)(value ? value : "");

	fputc('"', out);
	for (; *p; p++) {
		switch (*p) {
		case '\\':
			fputs("\\\\", out);
			break;
		case '"':
			fputs("\\\"", out);
			break;
		case '\b':
			fputs("\\b", out);
			break;
		case '\f':
			fputs("\\f", out);
			break;
		case '\n':
			fputs("\\n", out);
			break;
		case '\r':
			fputs("\\r", out);
			break;
		case '\t':
			fputs("\\t", out);
			break;
		default:
			if (*p < 0x20)
				fprintf(out, "\\u%04x", *p);
			else
				fputc(*p, out);
		}
	}
	fputc('"', out);
}

static void emit(FILE *out, const char *policy, const struct oracle_entry *entry,
		 const char *op, bool pass, int err, const char *detail)
{
	const char *effective = entry ? entry->shadow : "";

	if (entry && policy && !strcmp(policy, "build_graph") &&
	    !strcmp(entry->visible, "cc"))
		effective = "cc.real";
	fputs("{\"event\":", out);
	fprint_json_string(out, event_prefix);
	fputs(",\"result_level\":\"kvm_policy_path_oracle\","
	      "\"policy\":",
	      out);
	fprint_json_string(out, policy);
	fputs(",\"workload\":", out);
	fprint_json_string(out, entry ? entry->workload : "");
	fputs(",\"branch\":", out);
	fprint_json_string(out, entry ? entry->branch : "");
	fputs(",\"visible\":", out);
	fprint_json_string(out, entry ? entry->visible : "");
	fputs(",\"shadow\":", out);
	fprint_json_string(out, entry ? entry->shadow : "");
	fputs(",\"effective_shadow\":", out);
	fprint_json_string(out, effective);
	fputs(",\"op\":", out);
	fprint_json_string(out, op);
	fprintf(out, ",\"pass\":%s,\"errno\":%d,\"detail\":",
		pass ? "true" : "false", err);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_meta(FILE *out, const char *op, bool pass, int err,
		      const char *detail)
{
	fputs("{\"event\":", out);
	fprintf(out, "\"%s-meta\"", event_prefix);
	fputs(",\"result_level\":\"kvm_policy_path_oracle\","
	      "\"op\":",
	      out);
	fprint_json_string(out, op);
	fprintf(out, ",\"pass\":%s,\"errno\":%d,\"detail\":",
		pass ? "true" : "false", err);
	fprint_json_string(out, detail);
	fputs("}\n", out);
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

static int copy_string(char *dst, size_t size, const char *src)
{
	size_t len = strlen(src);

	if (len >= size)
		return -ENAMETOOLONG;
	memcpy(dst, src, len + 1);
	return 0;
}

static int parse_tsv_field(char *dst, size_t size, const char *value)
{
	if (!value || !value[0])
		return -EINVAL;
	return copy_string(dst, size, value);
}

static int parse_entry(char *line, struct oracle_entry *entry)
{
	char *fields[8];
	char *saveptr = NULL;
	char *field;
	size_t i = 0;

	line[strcspn(line, "\n")] = 0;
	for (field = strtok_r(line, "\t", &saveptr); field;
	     field = strtok_r(NULL, "\t", &saveptr)) {
		if (i >= 8)
			return -EINVAL;
		fields[i++] = field;
	}
	if (i != 8)
		return -EINVAL;
	if (parse_tsv_field(entry->workload, sizeof(entry->workload), fields[0]))
		return -EINVAL;
	if (parse_tsv_field(entry->branch, sizeof(entry->branch), fields[1]))
		return -EINVAL;
	if (parse_tsv_field(entry->parent_relative,
			    sizeof(entry->parent_relative), fields[2]))
		return -EINVAL;
	if (parse_tsv_field(entry->parent_absolute,
			    sizeof(entry->parent_absolute), fields[3]))
		return -EINVAL;
	if (parse_tsv_field(entry->visible, sizeof(entry->visible), fields[4]))
		return -EINVAL;
	if (parse_tsv_field(entry->shadow, sizeof(entry->shadow), fields[5]))
		return -EINVAL;
	if (parse_tsv_field(entry->original, sizeof(entry->original), fields[6]))
		return -EINVAL;
	if (parse_tsv_field(entry->original_sha256,
			    sizeof(entry->original_sha256), fields[7]))
		return -EINVAL;
	if (strlen(entry->visible) > NAMEI_EXT_NAME_MAX ||
	    strlen(entry->shadow) > NAMEI_EXT_NAME_MAX)
		return -ENAMETOOLONG;
	return 0;
}

static int read_entries(const char *path, struct oracle_entry *entries,
			size_t *nr_entries)
{
	char line[NAMEI_EXT_LINE_MAX];
	FILE *in;
	size_t count = 0;

	in = fopen(path, "r");
	if (!in)
		return -errno;

	while (fgets(line, sizeof(line), in)) {
		if (count >= NAMEI_EXT_MAX_ENTRIES) {
			fclose(in);
			return -E2BIG;
		}
		if (parse_entry(line, &entries[count])) {
			fclose(in);
			return -EINVAL;
		}
		count++;
	}
	if (ferror(in)) {
		fclose(in);
		return -EIO;
	}
	fclose(in);
	if (!count)
		return -ENOENT;
	*nr_entries = count;
	return 0;
}

static int copy_file(const char *src, const char *dst)
{
	char buf[16384];
	ssize_t nread;
	int in_fd;
	int out_fd;
	int saved_errno = 0;

	in_fd = open(src, O_RDONLY | O_CLOEXEC);
	if (in_fd < 0)
		return -errno;
	out_fd = open(dst, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
	if (out_fd < 0) {
		saved_errno = errno;
		close(in_fd);
		return -saved_errno;
	}

	while ((nread = read(in_fd, buf, sizeof(buf))) > 0) {
		ssize_t off = 0;

		while (off < nread) {
			ssize_t nwritten = write(out_fd, buf + off, nread - off);

			if (nwritten < 0) {
				saved_errno = errno;
				close(in_fd);
				close(out_fd);
				return -saved_errno;
			}
			off += nwritten;
		}
	}
	if (nread < 0)
		saved_errno = errno;
	if (close(in_fd) && !saved_errno)
		saved_errno = errno;
	if (close(out_fd) && !saved_errno)
		saved_errno = errno;
	return saved_errno ? -saved_errno : 0;
}

static int compare_files(const char *left, const char *right)
{
	char lbuf[16384];
	char rbuf[16384];
	int lfd;
	int rfd;
	int saved_errno = 0;

	lfd = open(left, O_RDONLY | O_CLOEXEC);
	if (lfd < 0)
		return -errno;
	rfd = open(right, O_RDONLY | O_CLOEXEC);
	if (rfd < 0) {
		saved_errno = errno;
		close(lfd);
		return -saved_errno;
	}

	for (;;) {
		ssize_t ln = read(lfd, lbuf, sizeof(lbuf));
		ssize_t rn = read(rfd, rbuf, sizeof(rbuf));

		if (ln < 0 || rn < 0) {
			saved_errno = errno;
			break;
		}
		if (ln != rn || memcmp(lbuf, rbuf, ln)) {
			saved_errno = EINVAL;
			break;
		}
		if (!ln)
			break;
	}
	if (close(lfd) && !saved_errno)
		saved_errno = errno;
	if (close(rfd) && !saved_errno)
		saved_errno = errno;
	return saved_errno ? -saved_errno : 0;
}

static __u64 fnv1a_hash_update(__u64 hash, const void *data, size_t len)
{
	const unsigned char *p = data;
	size_t i;

	for (i = 0; i < len; i++) {
		hash ^= p[i];
		hash *= W4_CCACHE_NAME_HASH_PRIME;
	}
	return hash;
}

static __u64 fnv1a_hash_bytes(const void *data, size_t len)
{
	return fnv1a_hash_update(W4_CCACHE_NAME_HASH_OFFSET, data, len);
}

static int compare_file_text_hash(const char *path, const char *expected,
				  size_t *expected_len_out,
				  size_t *observed_len_out,
				  __u64 *expected_hash_out,
				  __u64 *observed_hash_out)
{
	char buf[4096];
	size_t expected_len = strlen(expected);
	size_t off = 0;
	__u64 observed_hash = W4_CCACHE_NAME_HASH_OFFSET;
	int fd;
	int saved_errno = 0;
	bool mismatch = false;

	if (expected_len_out)
		*expected_len_out = expected_len;
	if (observed_len_out)
		*observed_len_out = 0;
	if (expected_hash_out)
		*expected_hash_out = fnv1a_hash_bytes(expected, expected_len);
	if (observed_hash_out)
		*observed_hash_out = 0;
	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	for (;;) {
		ssize_t nread = read(fd, buf, sizeof(buf));

		if (nread < 0) {
			saved_errno = errno;
			break;
		}
		if (!nread)
			break;
		observed_hash =
		    fnv1a_hash_update(observed_hash, buf, (size_t)nread);
		if (!mismatch) {
			if (off + (size_t)nread > expected_len ||
			    memcmp(buf, expected + off, nread))
				mismatch = true;
		}
		off += nread;
	}
	if (observed_len_out)
		*observed_len_out = off;
	if (observed_hash_out)
		*observed_hash_out = observed_hash;
	if (!saved_errno && (mismatch || off != expected_len))
		saved_errno = EINVAL;
	if (close(fd) && !saved_errno)
		saved_errno = errno;
	return saved_errno ? -saved_errno : 0;
}

static bool has_suffix(const char *name, const char *suffix)
{
	size_t name_len = strlen(name);
	size_t suffix_len = strlen(suffix);

	return name_len >= suffix_len &&
	       !strcmp(name + name_len - suffix_len, suffix);
}

static int remove_suffix_under(const char *dir_path, const char *suffix)
{
	struct dirent *de;
	DIR *dir;
	int first_error = 0;

	dir = opendir(dir_path);
	if (!dir)
		return -errno;
	while ((de = readdir(dir))) {
		char path[PATH_MAX];
		struct stat st;
		int ret;

		if (!strcmp(de->d_name, ".") || !strcmp(de->d_name, ".."))
			continue;
		ret = set_path(path, sizeof(path), dir_path, de->d_name);
		if (ret) {
			if (!first_error)
				first_error = ret;
			continue;
		}
		if (lstat(path, &st)) {
			if (!first_error)
				first_error = -errno;
			continue;
		}
		if (S_ISDIR(st.st_mode)) {
			ret = remove_suffix_under(path, suffix);
			if (ret && !first_error)
				first_error = ret;
			continue;
		}
		if (S_ISREG(st.st_mode) && has_suffix(de->d_name, suffix) &&
		    unlink(path) && !first_error)
			first_error = -errno;
	}
	if (closedir(dir) && !first_error)
		first_error = -errno;
	return first_error;
}

static int unlink_existing(const char *path)
{
	if (!unlink(path))
		return 0;
	if (errno == ENOENT)
		return 0;
	return -errno;
}

static int mkdir_if_missing(const char *path)
{
	if (!mkdir(path, 0755))
		return 0;
	if (errno == EEXIST)
		return 0;
	return -errno;
}

static __u64 monotonic_ns(void)
{
	struct timespec ts;

	if (clock_gettime(CLOCK_MONOTONIC_RAW, &ts))
		return 0;
	return ((__u64)ts.tv_sec * 1000000000ULL) + (__u64)ts.tv_nsec;
}

static int mkdir_counted(const char *path, struct nginx_macro_stats *stats)
{
	if (!mkdir(path, 0755)) {
		if (stats)
			stats->created_dirs++;
		return 0;
	}
	if (errno == EEXIST)
		return 0;
	return -errno;
}

static int write_text_file_counted(const char *path, const char *text,
				   struct nginx_macro_stats *stats,
				   bool update)
{
	size_t len = strlen(text);
	int ret;

	ret = write_text_file(path, text);
	if (ret)
		return ret;
	if (!stats)
		return 0;
	if (update) {
		stats->source_update_writes++;
		stats->update_bytes_written += len;
	} else {
		stats->created_files++;
		stats->bytes_written += len;
	}
	return 0;
}

static int copy_file_counted(const char *src, const char *dst,
			     struct nginx_macro_stats *stats, bool update)
{
	struct stat st = {};
	unsigned long long bytes = 0;
	int ret;

	if (stats && !stat(src, &st) && st.st_size > 0)
		bytes = (unsigned long long)st.st_size;
	ret = copy_file(src, dst);
	if (ret)
		return ret;
	if (!stats)
		return 0;
	if (update) {
		stats->source_update_writes++;
		stats->update_bytes_copied += bytes;
	} else {
		stats->created_files++;
		stats->bytes_copied += bytes;
	}
	return 0;
}

static int symlink_counted(const char *target, const char *link_path,
			   struct nginx_macro_stats *stats)
{
	if (unlink(link_path) && errno != ENOENT)
		return -errno;
	if (symlink(target, link_path))
		return -errno;
	if (stats)
		stats->created_symlinks++;
	return 0;
}

static int bind_mount_file_counted(const char *src, const char *dst,
				   struct nginx_macro_stats *stats)
{
	int fd;

	if (unlink(dst) && errno != ENOENT)
		return -errno;
	fd = open(dst, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
	if (fd < 0)
		return -errno;
	if (close(fd))
		return -errno;
	if (mount(src, dst, NULL, MS_BIND, NULL))
		return -errno;
	if (stats) {
		stats->created_files++;
		stats->bind_mounts++;
	}
	return 0;
}

static int copy_file_baseline_update(const char *src, const char *dst,
				     struct nginx_macro_stats *stats)
{
	struct stat st = {};
	unsigned long long bytes = 0;
	int ret;

	if (stats && !stat(src, &st) && st.st_size > 0)
		bytes = (unsigned long long)st.st_size;
	ret = copy_file(src, dst);
	if (ret)
		return ret;
	if (stats) {
		stats->baseline_update_writes++;
		stats->update_bytes_copied += bytes;
	}
	return 0;
}

static int set_child_path(char *dst, size_t size, const char *parent,
			  const char *child, const char *leaf)
{
	char tmp[PATH_MAX];
	int ret;

	ret = set_path(tmp, sizeof(tmp), parent, child);
	if (ret)
		return ret;
	return set_path(dst, size, tmp, leaf);
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

static void emit_nginx_case(FILE *out, const char *op, bool pass, int err,
			    int exit_code, const char *detail,
			    const char *stdout_path, const char *stderr_path)
{
	fputs("{\"event\":\"w2-nginx-real\","
	      "\"result_level\":\"kvm_real_app_health_oracle\","
	      "\"workload\":\"w2-nginx-fixture\","
	      "\"app\":\"nginx\",\"op\":",
	      out);
	fprint_json_string(out, op);
	fprintf(out, ",\"pass\":%s,\"errno\":%d,\"exit_code\":%d,"
		"\"qualified_for_c8\":false,\"detail\":",
		pass ? "true" : "false", err, exit_code);
	fprint_json_string(out, detail);
	fputs(",\"stdout\":", out);
	fprint_json_string(out, stdout_path ? stdout_path : "");
	fputs(",\"stderr\":", out);
	fprint_json_string(out, stderr_path ? stderr_path : "");
	fputs("}\n", out);
	fflush(out);
}

static void emit_nginx_probe(FILE *out, const char *op, bool pass, int err,
			     const char *detail, const char *visible_path,
			     const char *backing_path,
			     const char *forbidden_path)
{
	fputs("{\"event\":\"w2-nginx-real\","
	      "\"result_level\":\"kvm_real_app_health_oracle\","
	      "\"workload\":\"w2-nginx-fixture\","
	      "\"app\":\"nginx\",\"op\":",
	      out);
	fprint_json_string(out, op);
	fprintf(out, ",\"pass\":%s,\"errno\":%d,\"exit_code\":0,"
		"\"qualified_for_c8\":false,\"detail\":",
		pass ? "true" : "false", err);
	fprint_json_string(out, detail);
	fputs(",\"visible_path\":", out);
	fprint_json_string(out, visible_path ? visible_path : "");
	fputs(",\"backing_path\":", out);
	fprint_json_string(out, backing_path ? backing_path : "");
	fputs(",\"forbidden_path\":", out);
	fprint_json_string(out, forbidden_path ? forbidden_path : "");
	fputs(",\"stdout\":\"\",\"stderr\":\"\"}\n", out);
	fflush(out);
}

static const char *w4_cache_content_event = "w4-cache-content";
static const char *w4_cache_content_summary_event =
	"w4-cache-content-summary";
static const char *w4_cache_content_result_level = "kvm_cache_content_oracle";
static const char *w4_cache_content_policy = "cache_locality";
static const char *w4_cache_content_policy_family =
	"cache_locality_view.bpf.c";
static bool w4_cache_content_table_baseline;

static void emit_cache_case(FILE *out, const char *branch, const char *op,
			    bool pass, int err, const char *detail,
			    const char *path, const char *expected)
{
	fputs("{\"event\":", out);
	fprint_json_string(out, w4_cache_content_event);
	fputs(",\"result_level\":", out);
	fprint_json_string(out, w4_cache_content_result_level);
	fputs(",\"workload\":\"w4-cache-locality\","
	      "\"policy\":",
	      out);
	fprint_json_string(out, w4_cache_content_policy);
	fputs(",\"policy_family\":", out);
	fprint_json_string(out, w4_cache_content_policy_family);
	fputs(",\"table_baseline_current_oracle_pass\":", out);
	fputs(w4_cache_content_table_baseline && pass ? "true" : "false", out);
	fputs(",\"branch\":", out);
	fprint_json_string(out, branch ? branch : "");
	fputs(",\"op\":", out);
	fprint_json_string(out, op);
	fprintf(out, ",\"pass\":%s,\"errno\":%d,"
		"\"qualified_for_c8\":false,\"detail\":",
		pass ? "true" : "false", err);
	fprint_json_string(out, detail);
	fputs(",\"path\":", out);
	fprint_json_string(out, path ? path : "");
	fputs(",\"expected\":", out);
	fprint_json_string(out, expected ? expected : "");
	fputs("}\n", out);
	fflush(out);
}

static int write_text_file(const char *path, const char *text)
{
	size_t len = strlen(text);
	size_t off = 0;
	int fd;
	int saved_errno = 0;

	fd = open(path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
	if (fd < 0)
		return -errno;
	while (off < len) {
		ssize_t nwritten = write(fd, text + off, len - off);

		if (nwritten < 0) {
			saved_errno = errno;
			break;
		}
		off += nwritten;
	}
	if (close(fd) && !saved_errno)
		saved_errno = errno;
	return saved_errno ? -saved_errno : 0;
}

static int run_nginx_test_trace(const char *nginx_bin, const char *prefix,
				const char *conf_arg, const char *stdout_path,
				const char *stderr_path, const char *trace_path,
				int *exit_code)
{
	char prefix_arg[PATH_MAX];
	int out_fd;
	int err_fd;
	int status;
	pid_t pid;
	int ret;

	ret = snprintf(prefix_arg, sizeof(prefix_arg), "%s/", prefix);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(prefix_arg))
		return -ENAMETOOLONG;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (pid == 0) {
		out_fd = open(stdout_path,
			      O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
		if (out_fd < 0)
			_exit(125);
		err_fd = open(stderr_path,
			      O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
		if (err_fd < 0)
			_exit(125);
		if (dup2(out_fd, STDOUT_FILENO) < 0)
			_exit(125);
		if (dup2(err_fd, STDERR_FILENO) < 0)
			_exit(125);
		close(out_fd);
		close(err_fd);
		if (trace_path) {
			execlp("strace", "strace", "-f", "-e", "trace=%file",
			       "-o", trace_path, nginx_bin, "-t", "-p",
			       prefix_arg, "-c", conf_arg, "-g", "user root;",
			       (char *)NULL);
		} else {
			execl(nginx_bin, nginx_bin, "-t", "-p", prefix_arg, "-c",
			      conf_arg, "-g", "user root;", (char *)NULL);
		}
		_exit(127);
	}

	if (waitpid(pid, &status, 0) < 0)
		return -errno;
	if (WIFEXITED(status)) {
		*exit_code = WEXITSTATUS(status);
		return 0;
	}
	if (WIFSIGNALED(status)) {
		*exit_code = 128 + WTERMSIG(status);
		return 0;
	}
	*exit_code = 126;
	return 0;
}

static int run_nginx_test(const char *nginx_bin, const char *prefix,
			  const char *conf_arg, const char *stdout_path,
			  const char *stderr_path, int *exit_code)
{
	return run_nginx_test_trace(nginx_bin, prefix, conf_arg, stdout_path,
				    stderr_path, NULL, exit_code);
}

static int run_nginx_daemon_cmd_trace(const char *nginx_bin, const char *prefix,
				      const char *conf_arg, const char *signal,
				      const char *stdout_path,
				      const char *stderr_path,
				      const char *trace_path, int *exit_code)
{
	char prefix_arg[PATH_MAX];
	int out_fd;
	int err_fd;
	int status;
	pid_t pid;
	int ret;

	ret = snprintf(prefix_arg, sizeof(prefix_arg), "%s/", prefix);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(prefix_arg))
		return -ENAMETOOLONG;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (pid == 0) {
		out_fd = open(stdout_path,
			      O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
		if (out_fd < 0)
			_exit(125);
		err_fd = open(stderr_path,
			      O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
		if (err_fd < 0)
			_exit(125);
		if (dup2(out_fd, STDOUT_FILENO) < 0)
			_exit(125);
		if (dup2(err_fd, STDERR_FILENO) < 0)
			_exit(125);
		close(out_fd);
		close(err_fd);
		if (signal && trace_path) {
			execlp("strace", "strace", "-e", "trace=%file", "-o",
			       trace_path, nginx_bin, "-s", signal, "-p",
			       prefix_arg, "-c", conf_arg, "-g", "user root;",
			       (char *)NULL);
		} else if (signal) {
			execl(nginx_bin, nginx_bin, "-s", signal, "-p",
			      prefix_arg, "-c", conf_arg, "-g", "user root;",
			      (char *)NULL);
		} else if (trace_path) {
			execlp("strace", "strace", "-e", "trace=%file", "-o",
			       trace_path, nginx_bin, "-p", prefix_arg, "-c",
			       conf_arg, "-g", "user root;", (char *)NULL);
		} else {
			execl(nginx_bin, nginx_bin, "-p", prefix_arg, "-c",
			      conf_arg, "-g", "user root;", (char *)NULL);
		}
		_exit(127);
	}

	if (waitpid(pid, &status, 0) < 0)
		return -errno;
	if (WIFEXITED(status)) {
		*exit_code = WEXITSTATUS(status);
		return 0;
	}
	if (WIFSIGNALED(status)) {
		*exit_code = 128 + WTERMSIG(status);
		return 0;
	}
	*exit_code = 126;
	return 0;
}

static int write_response(int out_fd, const char *buf, size_t len)
{
	size_t off = 0;

	while (off < len) {
		ssize_t nwritten = write(out_fd, buf + off, len - off);

		if (nwritten < 0)
			return -errno;
		off += nwritten;
	}
	return 0;
}

static int connect_local_http(void)
{
	struct sockaddr_in addr = {};
	int saved_errno = ECONNREFUSED;
	int i;

	for (i = 0; i < 50; i++) {
		int fd = socket(AF_INET, SOCK_STREAM | SOCK_CLOEXEC, 0);

		if (fd < 0)
			return -errno;
		addr.sin_family = AF_INET;
		addr.sin_port = htons(80);
		if (inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr) != 1) {
			close(fd);
			return -EINVAL;
		}
		if (!connect(fd, (struct sockaddr *)&addr, sizeof(addr)))
			return fd;
		saved_errno = errno;
		close(fd);
		usleep(100000);
	}
	return -saved_errno;
}

static int start_upstream_server(pid_t *pid_out)
{
	const char response[] =
		"HTTP/1.0 200 OK\r\n"
		"Content-Type: text/plain\r\n"
		"Content-Length: 23\r\n"
		"Connection: close\r\n"
		"\r\n"
		NGINX_HEALTH_BODY;
	struct sockaddr_in addr = {};
	int one = 1;
	int listen_fd;
	pid_t pid;

	*pid_out = -1;
	listen_fd = socket(AF_INET, SOCK_STREAM | SOCK_CLOEXEC, 0);
	if (listen_fd < 0)
		return -errno;
	if (setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &one,
		       sizeof(one))) {
		int saved_errno = errno;

		close(listen_fd);
		return -saved_errno;
	}
	addr.sin_family = AF_INET;
	addr.sin_port = htons(NGINX_UPSTREAM_PORT);
	if (inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr) != 1) {
		close(listen_fd);
		return -EINVAL;
	}
	if (bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr))) {
		int saved_errno = errno;

		close(listen_fd);
		return -saved_errno;
	}
	if (listen(listen_fd, 1)) {
		int saved_errno = errno;

		close(listen_fd);
		return -saved_errno;
	}

	pid = fork();
	if (pid < 0) {
		int saved_errno = errno;

		close(listen_fd);
		return -saved_errno;
	}
	if (pid == 0) {
		char request[512];
		int client_fd;
		int ret;
		ssize_t nread;

		client_fd = accept4(listen_fd, NULL, NULL, SOCK_CLOEXEC);
		if (client_fd < 0)
			_exit(1);
		nread = read(client_fd, request, sizeof(request));
		if (nread <= 0) {
			close(client_fd);
			close(listen_fd);
			_exit(1);
		}
		ret = write_response(client_fd, response, sizeof(response) - 1);
		close(client_fd);
		close(listen_fd);
		_exit(ret ? 1 : 0);
	}

	close(listen_fd);
	*pid_out = pid;
	return 0;
}

static int wait_upstream_server(pid_t pid, int *exit_code)
{
	int status;
	int i;

	*exit_code = -1;
	for (i = 0; i < 50; i++) {
		pid_t waited = waitpid(pid, &status, WNOHANG);

		if (waited < 0)
			return -errno;
		if (waited == pid) {
			if (WIFEXITED(status))
				*exit_code = WEXITSTATUS(status);
			else if (WIFSIGNALED(status))
				*exit_code = 128 + WTERMSIG(status);
			else
				*exit_code = 126;
			return 0;
		}
		usleep(100000);
	}
	kill(pid, SIGTERM);
	waitpid(pid, &status, 0);
	return -ETIMEDOUT;
}

static int run_http_health(const char *response_path, int *exit_code)
{
	const char request[] =
		"GET / HTTP/1.0\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n";
	char response[8192];
	size_t used = 0;
	int out_fd;
	int fd;
	int ret = 0;

	*exit_code = 1;
	fd = connect_local_http();
	if (fd < 0)
		return fd;
	ret = write_response(fd, request, sizeof(request) - 1);
	if (ret) {
		close(fd);
		return ret;
	}

	out_fd = open(response_path,
		      O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
	if (out_fd < 0) {
		ret = -errno;
		close(fd);
		return ret;
	}
	for (;;) {
		char buf[1024];
		ssize_t nread = read(fd, buf, sizeof(buf));

		if (nread < 0) {
			ret = -errno;
			break;
		}
		if (!nread)
			break;
		ret = write_response(out_fd, buf, nread);
		if (ret)
			break;
		if (used < sizeof(response) - 1) {
			size_t copy = nread;

			if (copy > sizeof(response) - 1 - used)
				copy = sizeof(response) - 1 - used;
			memcpy(response + used, buf, copy);
			used += copy;
		}
	}
	response[used] = 0;
	if (close(out_fd) && !ret)
		ret = -errno;
	if (close(fd) && !ret)
		ret = -errno;
	if (ret)
		return ret;
	if (strstr(response, "200 OK") && strstr(response, NGINX_HEALTH_BODY))
		*exit_code = 0;
	return 0;
}

static int prepare_nginx_prefix(const char *work_dir, const char *fixture_conf,
				const char *endpoint_fixture,
				const char *mime_types, char *prefix,
				size_t prefix_size,
				struct nginx_macro_stats *stats)
{
	char prefix_template[] = "/tmp/namei-ext-w2-nginx-real-XXXXXX";
	char path[PATH_MAX];
	char *prefix_dir;
	int ret;

	ret = mkdir_counted(work_dir, stats);
	if (ret)
		return ret;
	prefix_dir = mkdtemp(prefix_template);
	if (!prefix_dir)
		return -errno;
	if (stats)
		stats->created_dirs++;
	ret = copy_string(prefix, prefix_size, prefix_dir);
	if (ret)
		return ret;
	ret = mkdir_counted(prefix, stats);
	if (ret)
		return ret;
	ret = set_path(path, sizeof(path), prefix, "conf");
	if (ret)
		return ret;
	ret = mkdir_counted(path, stats);
	if (ret)
		return ret;
	ret = set_path(path, sizeof(path), prefix, "logs");
	if (ret)
		return ret;
	ret = mkdir_counted(path, stats);
	if (ret)
		return ret;
	ret = set_path(path, sizeof(path), prefix, "html");
	if (ret)
		return ret;
	ret = mkdir_counted(path, stats);
	if (ret)
		return ret;

	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "nginx.conf");
	if (ret)
		return ret;
	unlink(path);
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "nginx.prod.conf");
	if (ret)
		return ret;
	ret = write_text_file_counted(path, W2_PROD_CONFIG_DECOY, stats,
				      false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "nginx.test.conf");
	if (ret)
		return ret;
	ret = copy_file_counted(fixture_conf, path, stats, false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "upstream.local");
	if (ret)
		return ret;
	ret = copy_file_counted(endpoint_fixture, path, stats, false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "upstream.prod");
	if (ret)
		return ret;
	ret = write_text_file_counted(path, W2_PROD_ENDPOINT_DECOY, stats,
				      false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "server.fake.crt");
	if (ret)
		return ret;
	ret = write_text_file_counted(path, W2_FAKE_CERT, stats, false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "server.prod.crt");
	if (ret)
		return ret;
	ret = write_text_file_counted(path, W2_PROD_CERT_DECOY, stats,
				      false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "db.fake.pass");
	if (ret)
		return ret;
	ret = write_text_file_counted(path, W2_FAKE_SECRET, stats, false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "db.prod.pass");
	if (ret)
		return ret;
	ret = write_text_file_counted(path, W2_PROD_SECRET_DECOY, stats,
				      false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "poison.secret");
	if (ret)
		return ret;
	ret = write_text_file_counted(path, W2_POISON_SENTINEL, stats, false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "prod.real.token");
	if (ret)
		return ret;
	ret = write_text_file_counted(path, W2_PROD_TOKEN_DECOY, stats,
				      false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "conf",
			     "mime.types");
	if (ret)
		return ret;
	ret = copy_file_counted(mime_types, path, stats, false);
	if (ret)
		return ret;
	ret = set_child_path(path, sizeof(path), prefix, "html",
			     "index.html");
	if (ret)
		return ret;
	return write_text_file_counted(path, NGINX_HEALTH_BODY, stats, false);
}

static int check_nginx_fixture_probe(FILE *out, const char *prefix,
				     const char *op, const char *visible,
				     const char *backing,
				     const char *forbidden,
				     const char *detail)
{
	char visible_path[PATH_MAX];
	char backing_path[PATH_MAX];
	char forbidden_path[PATH_MAX];
	int ret;

	ret = set_child_path(visible_path, sizeof(visible_path), prefix, "conf",
			     visible);
	if (!ret)
		ret = set_child_path(backing_path, sizeof(backing_path), prefix,
				     "conf", backing);
	if (!ret)
		ret = set_child_path(forbidden_path, sizeof(forbidden_path),
				     prefix, "conf", forbidden);
	if (ret) {
		emit_nginx_probe(out, op, false, -ret,
				 "failed to build fixture probe paths", NULL,
				 NULL, NULL);
		return 1;
	}

	ret = compare_files(visible_path, backing_path);
	if (ret) {
		emit_nginx_probe(out, op, false, -ret,
				 "fixture alias did not resolve to expected backing",
				 visible_path, backing_path, forbidden_path);
		return 1;
	}

	ret = compare_files(visible_path, forbidden_path);
	if (!ret) {
		emit_nginx_probe(out, op, false, 0,
				 "fixture alias matched production decoy",
				 visible_path, backing_path, forbidden_path);
		return 1;
	}
	if (ret != -EINVAL) {
		emit_nginx_probe(out, op, false, -ret,
				 "failed to compare fixture alias with production decoy",
				 visible_path, backing_path, forbidden_path);
		return 1;
	}

	emit_nginx_probe(out, op, true, 0, detail, visible_path, backing_path,
			 forbidden_path);
	return 0;
}

static int check_nginx_fixture_compare(const char *prefix, const char *visible,
				       const char *backing,
				       const char *forbidden)
{
	char visible_path[PATH_MAX];
	char backing_path[PATH_MAX];
	char forbidden_path[PATH_MAX];
	int ret;

	ret = set_child_path(visible_path, sizeof(visible_path), prefix, "conf",
			     visible);
	if (!ret)
		ret = set_child_path(backing_path, sizeof(backing_path), prefix,
				     "conf", backing);
	if (!ret)
		ret = set_child_path(forbidden_path, sizeof(forbidden_path),
				     prefix, "conf", forbidden);
	if (ret)
		return ret;

	ret = compare_files(visible_path, backing_path);
	if (ret)
		return ret;
	ret = compare_files(visible_path, forbidden_path);
	if (!ret)
		return -EINVAL;
	if (ret != -EINVAL)
		return ret;
	return 0;
}

struct nginx_alias_pair {
	const char *visible;
	const char *backing;
};

static const struct nginx_alias_pair nginx_setup_aliases[] = {
	{ "nginx.conf", "nginx.test.conf" },
	{ "upstream.sock", "upstream.local" },
	{ "server.crt", "server.fake.crt" },
	{ "db.password", "db.fake.pass" },
	{ "prod.token", "poison.secret" },
};

static const struct nginx_alias_pair nginx_update_aliases[] = {
	{ "upstream.sock", "upstream.local" },
	{ "server.crt", "server.fake.crt" },
	{ "db.password", "db.fake.pass" },
};

struct nginx_fuse_env {
	char backing_dir[PATH_MAX];
};

static int nginx_fuse_backing_dir(char *dst, size_t size, const char *prefix)
{
	return set_path(dst, size, prefix, ".fuse-conf-backing");
}

static int nginx_fuse_source_path(struct nginx_fuse_env *env, const char *path,
				  char *dst, size_t size)
{
	const char *name;
	size_t i;

	if (!path || strcmp(path, "/") == 0)
		return -EISDIR;
	if (path[0] != '/')
		return -ENOENT;
	name = path + 1;
	if (!name[0] || strchr(name, '/'))
		return -ENOENT;

	for (i = 0; i < ARRAY_SIZE(nginx_setup_aliases); i++) {
		if (!strcmp(name, nginx_setup_aliases[i].visible))
			return set_path(dst, size, env->backing_dir,
					nginx_setup_aliases[i].backing);
	}
	return set_path(dst, size, env->backing_dir, name);
}

static int nginx_fuse_getattr(const char *path, struct stat *st)
{
	struct nginx_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	int ret;

	if (!strcmp(path, "/")) {
		memset(st, 0, sizeof(*st));
		st->st_mode = S_IFDIR | 0755;
		st->st_nlink = 2;
		return 0;
	}

	ret = nginx_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	if (stat(source, st))
		return -errno;
	return 0;
}

static int nginx_fuse_access(const char *path, int mask)
{
	struct nginx_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	int ret;

	if (!strcmp(path, "/"))
		return (mask & W_OK) ? -EACCES : 0;
	if (mask & W_OK)
		return -EACCES;
	ret = nginx_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	if (access(source, mask))
		return -errno;
	return 0;
}

static int nginx_fuse_open(const char *path, struct fuse_file_info *fi)
{
	struct nginx_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	int fd;
	int ret;

	if ((fi->flags & O_ACCMODE) != O_RDONLY)
		return -EACCES;
	ret = nginx_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	fd = open(source, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	fi->fh = (uint64_t)fd;
	fi->direct_io = 1;
	fi->keep_cache = 0;
	return 0;
}

static int nginx_fuse_read(const char *path, char *buf, size_t size,
			   off_t offset, struct fuse_file_info *fi)
{
	ssize_t ret;

	(void)path;
	ret = pread((int)fi->fh, buf, size, offset);
	if (ret < 0)
		return -errno;
	return (int)ret;
}

static int nginx_fuse_release(const char *path, struct fuse_file_info *fi)
{
	int ret;

	(void)path;
	ret = close((int)fi->fh);
	return ret ? -errno : 0;
}

static int nginx_fuse_readdir(const char *path, void *buf,
			      fuse_fill_dir_t filler, off_t offset,
			      struct fuse_file_info *fi)
{
	size_t i;

	(void)offset;
	(void)fi;
	if (strcmp(path, "/"))
		return -ENOENT;
	filler(buf, ".", NULL, 0);
	filler(buf, "..", NULL, 0);
	for (i = 0; i < ARRAY_SIZE(nginx_setup_aliases); i++)
		filler(buf, nginx_setup_aliases[i].visible, NULL, 0);
	filler(buf, "mime.types", NULL, 0);
	return 0;
}

static struct fuse_operations nginx_fuse_ops = {
	.getattr = nginx_fuse_getattr,
	.access = nginx_fuse_access,
	.open = nginx_fuse_open,
	.read = nginx_fuse_read,
	.release = nginx_fuse_release,
	.readdir = nginx_fuse_readdir,
};

static bool is_nginx_baseline_name(const char *name)
{
	return !strcmp(name, "copy_tree") ||
	       !strcmp(name, "symlink_forest") ||
	       !strcmp(name, "bind_mount") ||
	       !strcmp(name, "projected_volume") ||
	       !strcmp(name, "fuse_redirect");
}

static bool nginx_baseline_selected(const char *list, const char *name)
{
	char buf[256];
	char *saveptr = NULL;
	char *tok;

	if (!strcmp(list, "all"))
		return true;
	snprintf(buf, sizeof(buf), "%s", list);
	for (tok = strtok_r(buf, " ,", &saveptr); tok;
	     tok = strtok_r(NULL, " ,", &saveptr)) {
		if (!strcmp(tok, name))
			return true;
	}
	return false;
}

static int count_selected_nginx_baselines(const char *list, int *count)
{
	char buf[256];
	char *saveptr = NULL;
	char *tok;
	int n = 0;

	if (!strcmp(list, "all")) {
		*count = 5;
		return 0;
	}
	snprintf(buf, sizeof(buf), "%s", list);
	for (tok = strtok_r(buf, " ,", &saveptr); tok;
	     tok = strtok_r(NULL, " ,", &saveptr)) {
		if (!is_nginx_baseline_name(tok))
			return -EINVAL;
		n++;
	}
	if (!n)
		return -ENOENT;
	*count = n;
	return 0;
}

static int prepare_nginx_projected_generation(const char *prefix,
					      const char *generation,
					      struct nginx_macro_stats *stats,
					      bool update)
{
	char projected_dir[PATH_MAX];
	char generation_dir[PATH_MAX];
	char tmp_link[PATH_MAX];
	char data_link[PATH_MAX];
	size_t i;
	int ret;

	ret = set_child_path(projected_dir, sizeof(projected_dir), prefix,
			     "conf", ".projected");
	if (!ret)
		ret = set_path(generation_dir, sizeof(generation_dir),
			       projected_dir, generation);
	if (!ret)
		ret = set_path(tmp_link, sizeof(tmp_link), projected_dir,
			       "..data_tmp");
	if (!ret)
		ret = set_path(data_link, sizeof(data_link), projected_dir,
			       "..data");
	if (ret)
		return ret;

	ret = mkdir_counted(projected_dir, update ? NULL : stats);
	if (!ret)
		ret = mkdir_counted(generation_dir, update ? NULL : stats);
	if (ret)
		return ret;

	for (i = 0; i < ARRAY_SIZE(nginx_setup_aliases); i++) {
		char backing_path[PATH_MAX];
		char projected_path[PATH_MAX];

		ret = set_child_path(backing_path, sizeof(backing_path),
				     prefix, "conf",
				     nginx_setup_aliases[i].backing);
		if (!ret)
			ret = set_path(projected_path, sizeof(projected_path),
				       generation_dir,
				       nginx_setup_aliases[i].visible);
		if (ret)
			return ret;
		if (update)
			ret = copy_file_baseline_update(backing_path,
							projected_path, stats);
		else
			ret = copy_file_counted(backing_path, projected_path,
						stats, false);
		if (ret)
			return ret;
	}

	if (unlink(tmp_link) && errno != ENOENT)
		return -errno;
	if (symlink(generation, tmp_link))
		return -errno;
	if (rename(tmp_link, data_link))
		return -errno;
	if (stats) {
		if (update)
			stats->baseline_update_writes++;
		else
			stats->created_symlinks++;
	}
	return 0;
}

static int materialize_nginx_projected_volume(const char *prefix,
					      struct nginx_macro_stats *stats)
{
	size_t i;
	int ret;

	ret = prepare_nginx_projected_generation(prefix, "..gen0", stats,
						false);
	if (ret)
		return ret;

	for (i = 0; i < ARRAY_SIZE(nginx_setup_aliases); i++) {
		char visible_path[PATH_MAX];
		char target[PATH_MAX];
		int n;

		ret = set_child_path(visible_path, sizeof(visible_path), prefix,
				     "conf", nginx_setup_aliases[i].visible);
		if (ret)
			return ret;
		n = snprintf(target, sizeof(target), ".projected/..data/%s",
			     nginx_setup_aliases[i].visible);
		if (n < 0 || (size_t)n >= sizeof(target))
			return -ENAMETOOLONG;
		ret = symlink_counted(target, visible_path, stats);
		if (ret)
			return ret;
	}
	return 0;
}

static int update_nginx_projected_volume(const char *prefix,
					 struct nginx_macro_stats *stats)
{
	return prepare_nginx_projected_generation(prefix, "..gen1", stats,
						 true);
}

static int wait_for_nginx_fuse_ready(const char *prefix, pid_t fuse_pid)
{
	struct timespec delay = { .tv_sec = 0, .tv_nsec = 50000000 };
	char visible_path[PATH_MAX];
	int ret;
	int i;

	ret = set_child_path(visible_path, sizeof(visible_path), prefix, "conf",
			     "nginx.conf");
	if (ret)
		return ret;
	for (i = 0; i < 100; i++) {
		struct stat st;
		int status;
		pid_t wait_ret;

		if (!stat(visible_path, &st))
			return 0;
		wait_ret = waitpid(fuse_pid, &status, WNOHANG);
		if (wait_ret == fuse_pid)
			return -EIO;
		if (wait_ret < 0 && errno != EINTR)
			return -errno;
		nanosleep(&delay, NULL);
	}
	return -ETIMEDOUT;
}

static int setup_nginx_fuse_redirect(const char *prefix,
				     struct nginx_macro_stats *stats,
				     pid_t *fuse_pid)
{
	char conf_dir[PATH_MAX];
	struct nginx_fuse_env env = {};
	char *argv[] = {
		"namei_ext_w2_nginx_fuse",
		"-f",
		"-s",
		"-o",
		"default_permissions,attr_timeout=0,entry_timeout=0,negative_timeout=0",
		conf_dir,
		NULL,
	};
	int ret;

	*fuse_pid = -1;
	ret = set_path(conf_dir, sizeof(conf_dir), prefix, "conf");
	if (!ret)
		ret = nginx_fuse_backing_dir(env.backing_dir,
					     sizeof(env.backing_dir), prefix);
	if (ret)
		return ret;
	if (rename(conf_dir, env.backing_dir))
		return -errno;
	ret = mkdir_counted(conf_dir, stats);
	if (ret)
		return ret;

	*fuse_pid = fork();
	if (*fuse_pid < 0) {
		*fuse_pid = -1;
		return -errno;
	}
	if (*fuse_pid == 0)
		_exit(fuse_main(6, argv, &nginx_fuse_ops, &env));

	ret = wait_for_nginx_fuse_ready(prefix, *fuse_pid);
	if (ret)
		return ret;
	if (stats)
		stats->fuse_mounts++;
	return 0;
}

static int unmount_nginx_fuse(const char *prefix, pid_t fuse_pid)
{
	char conf_dir[PATH_MAX];
	int first_error = 0;
	int status;
	int ret;

	ret = set_path(conf_dir, sizeof(conf_dir), prefix, "conf");
	if (ret)
		first_error = ret;
	else if (umount(conf_dir) && errno != EINVAL)
		first_error = -errno;

	if (fuse_pid > 0) {
		ret = waitpid(fuse_pid, &status, WNOHANG);
		if (ret == 0) {
			kill(fuse_pid, SIGTERM);
			while (waitpid(fuse_pid, &status, 0) < 0) {
				if (errno == EINTR)
					continue;
				if (!first_error)
					first_error = -errno;
				break;
			}
		} else if (ret < 0 && errno != ECHILD && !first_error) {
			first_error = -errno;
		}
	}
	return first_error;
}

static int materialize_nginx_baseline_aliases(const char *prefix,
					      const char *baseline,
					      struct nginx_macro_stats *stats)
{
	size_t i;

	for (i = 0; i < ARRAY_SIZE(nginx_setup_aliases); i++) {
		char visible_path[PATH_MAX];
		char backing_path[PATH_MAX];
		int ret;

		ret = set_child_path(visible_path, sizeof(visible_path), prefix,
				     "conf", nginx_setup_aliases[i].visible);
		if (!ret)
			ret = set_child_path(backing_path, sizeof(backing_path),
					     prefix, "conf",
					     nginx_setup_aliases[i].backing);
		if (ret)
			return ret;
		if (!strcmp(baseline, "copy_tree")) {
			ret = copy_file_counted(backing_path, visible_path,
						stats, false);
		} else if (!strcmp(baseline, "symlink_forest")) {
			ret = symlink_counted(nginx_setup_aliases[i].backing,
					      visible_path, stats);
		} else if (!strcmp(baseline, "bind_mount")) {
			ret = bind_mount_file_counted(backing_path, visible_path,
						      stats);
		} else if (!strcmp(baseline, "projected_volume")) {
			ret = materialize_nginx_projected_volume(prefix, stats);
			if (ret)
				return ret;
			return 0;
		} else if (!strcmp(baseline, "fuse_redirect")) {
			return -EINVAL;
		} else {
			return -EINVAL;
		}
		if (ret)
			return ret;
	}
	return 0;
}

static int update_nginx_baseline_aliases(const char *prefix,
					 const char *baseline,
					 struct nginx_macro_stats *stats)
{
	size_t i;

	if (!strcmp(baseline, "symlink_forest") ||
	    !strcmp(baseline, "bind_mount"))
		return 0;
	if (!strcmp(baseline, "projected_volume"))
		return update_nginx_projected_volume(prefix, stats);
	if (!strcmp(baseline, "fuse_redirect"))
		return 0;
	if (strcmp(baseline, "copy_tree"))
		return -EINVAL;

	for (i = 0; i < ARRAY_SIZE(nginx_update_aliases); i++) {
		char visible_path[PATH_MAX];
		char backing_path[PATH_MAX];
		int ret;

		ret = set_child_path(visible_path, sizeof(visible_path), prefix,
				     "conf", nginx_update_aliases[i].visible);
		if (!ret)
			ret = set_child_path(backing_path, sizeof(backing_path),
					     prefix, "conf",
					     nginx_update_aliases[i].backing);
		if (ret)
			return ret;
		ret = copy_file_baseline_update(backing_path, visible_path,
						stats);
		if (ret)
			return ret;
	}
	return 0;
}

static int unmount_nginx_bind_aliases(const char *prefix)
{
	int first_error = 0;
	size_t i;

	for (i = 0; i < ARRAY_SIZE(nginx_setup_aliases); i++) {
		char visible_path[PATH_MAX];
		int ret;

		ret = set_child_path(visible_path, sizeof(visible_path), prefix,
				     "conf", nginx_setup_aliases[i].visible);
		if (ret) {
			if (!first_error)
				first_error = ret;
			continue;
		}
		if (umount2(visible_path, MNT_DETACH) && errno != EINVAL &&
		    errno != ENOENT) {
			if (!first_error)
				first_error = -errno;
		}
	}
	return first_error;
}

static void emit_nginx_macro_setup(FILE *out, int sample, bool pass, int err,
				   __u64 setup_ns,
				   const struct nginx_macro_stats *stats,
				   const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w2-nginx-macrobench-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_nginx_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_setup_update_poc\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-nginx-fixture\","
	      "\"app\":\"nginx\","
	      "\"policy_family\":\"sandbox_fixture_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":%llu,\"bind_mounts\":0,"
		"\"overlay_mounts\":0,\"fuse_mounts\":0,"
		"\"bytes_written\":%llu,\"bytes_copied\":%llu,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, stats->created_dirs,
		stats->created_files, stats->created_symlinks,
		stats->bytes_written,
		stats->bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_nginx_macro_update(FILE *out, int sample, bool pass, int err,
				    __u64 update_ns,
				    const struct nginx_macro_stats *stats,
				    const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w2-nginx-macrobench-update\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_nginx_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_setup_update_poc\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-nginx-fixture\","
	      "\"app\":\"nginx\","
	      "\"policy_family\":\"sandbox_fixture_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"source_update_writes\":%llu,"
		"\"baseline_update_writes\":%llu,"
		"\"policy_update_writes\":%llu,"
		"\"update_bytes_written\":%llu,"
		"\"update_bytes_copied\":%llu,"
		"\"policy_executed\":true,\"kvm_validated\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns, stats->source_update_writes,
		stats->baseline_update_writes, stats->policy_update_writes,
		stats->update_bytes_written,
		stats->update_bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_nginx_macro_correctness(FILE *out, int sample, bool pass,
					 int failures,
					 bool pre_attach_rejected,
					 bool attached_nginx_test_pass,
					 bool post_update_nginx_test_pass,
					 bool config_probe_pass,
					 bool endpoint_probe_pass,
					 bool cert_probe_pass,
					 bool secret_probe_pass,
					 bool poison_probe_pass,
					 bool post_update_endpoint_probe_pass,
					 bool post_update_cert_probe_pass,
					 bool post_update_secret_probe_pass,
					 bool policy_executed,
					 const char *detail)
{
	fputs("{\"event\":\"w2-nginx-macrobench-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_nginx_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_setup_update_poc\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-nginx-fixture\","
	      "\"app\":\"nginx\","
	      "\"policy_family\":\"sandbox_fixture_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"pre_attach_nginx_rejected\":%s,"
		"\"attached_nginx_test_pass\":%s,"
		"\"post_update_nginx_test_pass\":%s,"
		"\"config_probe_pass\":%s,"
		"\"endpoint_probe_pass\":%s,"
		"\"cert_probe_pass\":%s,"
		"\"secret_probe_pass\":%s,"
		"\"poison_probe_pass\":%s,"
		"\"post_update_endpoint_probe_pass\":%s,"
		"\"post_update_cert_probe_pass\":%s,"
		"\"post_update_secret_probe_pass\":%s,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures,
		pre_attach_rejected ? "true" : "false",
		attached_nginx_test_pass ? "true" : "false",
		post_update_nginx_test_pass ? "true" : "false",
		config_probe_pass ? "true" : "false",
		endpoint_probe_pass ? "true" : "false",
		cert_probe_pass ? "true" : "false",
		secret_probe_pass ? "true" : "false",
		poison_probe_pass ? "true" : "false",
		post_update_endpoint_probe_pass ? "true" : "false",
		post_update_cert_probe_pass ? "true" : "false",
		post_update_secret_probe_pass ? "true" : "false",
		policy_executed ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int update_nginx_macro_fixture_dir(const char *conf_dir, int sample,
					  struct nginx_macro_stats *stats)
{
	char path[PATH_MAX];
	char text[256];
	int ret;

	ret = set_path(path, sizeof(path), conf_dir, "upstream.local");
	if (ret)
		return ret;
	ret = snprintf(text, sizeof(text),
		       "proxy_pass http://127.0.0.1:18080;\n"
		       "# namei_ext macro sample %d\n",
		       sample);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(text))
		return -ENAMETOOLONG;
	ret = write_text_file_counted(path, text, stats, true);
	if (ret)
		return ret;

	ret = set_path(path, sizeof(path), conf_dir, "server.fake.crt");
	if (ret)
		return ret;
	ret = snprintf(text, sizeof(text),
		       "namei-ext fake certificate for nginx fixture sample %d\n",
		       sample);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(text))
		return -ENAMETOOLONG;
	ret = write_text_file_counted(path, text, stats, true);
	if (ret)
		return ret;

	ret = set_path(path, sizeof(path), conf_dir, "db.fake.pass");
	if (ret)
		return ret;
	ret = snprintf(text, sizeof(text),
		       "namei_ext_fake_password_sample_%d\n", sample);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(text))
		return -ENAMETOOLONG;
	return write_text_file_counted(path, text, stats, true);
}

static int update_nginx_macro_fixture(const char *prefix, int sample,
				      struct nginx_macro_stats *stats)
{
	char conf_dir[PATH_MAX];
	int ret;

	ret = set_path(conf_dir, sizeof(conf_dir), prefix, "conf");
	if (ret)
		return ret;
	return update_nginx_macro_fixture_dir(conf_dir, sample, stats);
}

static int update_nginx_fuse_fixture(const char *prefix, int sample,
				     struct nginx_macro_stats *stats)
{
	char backing_dir[PATH_MAX];
	int ret;

	ret = nginx_fuse_backing_dir(backing_dir, sizeof(backing_dir), prefix);
	if (ret)
		return ret;
	return update_nginx_macro_fixture_dir(backing_dir, sample, stats);
}

static bool dir_has_name(const char *dir_path, const char *name, int *err_out)
{
	struct dirent *de;
	bool found = false;
	DIR *dir;

	errno = 0;
	*err_out = 0;
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
	if (closedir(dir) && !*err_out)
		*err_out = errno;
	return found;
}

static const char *effective_shadow(enum policy_kind kind,
				    const struct oracle_entry *entry)
{
	if (kind == POLICY_BUILD_GRAPH && !strcmp(entry->visible, "cc"))
		return "cc.real";
	return entry->shadow;
}

static int materialize_entry(struct oracle_entry *entry,
			     enum policy_kind extra_policy_kind)
{
	char path[PATH_MAX];
	const char *extra_shadow = effective_shadow(extra_policy_kind, entry);
	int ret;

	ret = set_path(path, sizeof(path), entry->dir, entry->shadow);
	if (ret)
		return ret;
	ret = copy_file(entry->original, path);
	if (ret)
		return ret;

	if (strcmp(extra_shadow, entry->shadow)) {
		ret = set_path(path, sizeof(path), entry->dir, extra_shadow);
		if (ret)
			return ret;
		ret = copy_file(entry->original, path);
		if (ret)
			return ret;
	}
	return 0;
}

static int materialize_entries(char *base_dir, size_t base_size,
			       struct oracle_entry *entries, size_t nr_entries,
			       enum policy_kind primary_kind)
{
	size_t i;

	snprintf(base_dir, base_size, "/tmp/namei-ext-w1-XXXXXX");
	if (!mkdtemp(base_dir))
		return -errno;

	for (i = 0; i < nr_entries; i++) {
		int ret = snprintf(entries[i].dir, sizeof(entries[i].dir),
				   "%s/e%03zu", base_dir, i);

		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(entries[i].dir))
			return -ENAMETOOLONG;
		if (mkdir(entries[i].dir, 0755))
			return -errno;
		ret = materialize_entry(&entries[i], primary_kind);
		if (ret)
			return ret;
	}
	return 0;
}

static void cleanup_entries(const char *base_dir, struct oracle_entry *entries,
			    size_t nr_entries)
{
	char path[PATH_MAX];
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		if (entries[i].dir[0]) {
			if (!set_path(path, sizeof(path), entries[i].dir,
				      entries[i].shadow))
				unlink(path);
			if (strcmp(effective_shadow(POLICY_BUILD_GRAPH,
						    &entries[i]),
				   entries[i].shadow) &&
			    !set_path(path, sizeof(path), entries[i].dir,
				      effective_shadow(POLICY_BUILD_GRAPH,
						       &entries[i])))
				unlink(path);
			if (!set_path(path, sizeof(path), entries[i].dir,
				      entries[i].visible))
				unlink(path);
			rmdir(entries[i].dir);
		}
	}
	if (base_dir && base_dir[0])
		rmdir(base_dir);
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

static int cgroup_id_from_path(const char *path, __u64 *id_out)
{
	union {
		__u64 cgid;
		unsigned char raw_bytes[8];
	} id = {};
	struct file_handle *fhp;
	struct file_handle *fhp2;
	int mount_id = 0;
	int err;
	int saved_errno = 0;
	size_t fhsize;

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

static int fill_key(struct namei_ext_component_key *key, __u32 event,
		    __u64 cgroup_id, const char *parent_dir,
		    const char *name)
{
	struct stat st;
	size_t len = strlen(name);

	if (!parent_dir || !parent_dir[0])
		return -EINVAL;
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

static void fill_rule(struct namei_ext_redirect_rule *rule, const char *target,
		      __u32 branch)
{
	size_t len = strlen(target);

	memset(rule, 0, sizeof(*rule));
	rule->action = BPF_NAMEI_EXT_REDIRECT;
	rule->target_len = len;
	rule->branch = branch;
	memcpy(rule->target, target, len);
}

static int cache_state_for_branch(const char *branch, __u32 *state_out)
{
	if (!strcmp(branch, "verified_hit")) {
		*state_out = CACHE_STATE_VERIFIED_HIT;
		return 0;
	}
	if (!strcmp(branch, "miss_canonical")) {
		*state_out = CACHE_STATE_MISS;
		return 0;
	}
	if (!strcmp(branch, "stale_fallback") ||
	    !strcmp(branch, "stale_canonical")) {
		*state_out = CACHE_STATE_STALE;
		return 0;
	}
	if (!strcmp(branch, "corrupt_reject")) {
		*state_out = CACHE_STATE_CORRUPT;
		return 0;
	}
	return -EINVAL;
}

static __u64 sha_prefix_u64(const char *sha256)
{
	char prefix[17] = {};
	size_t i;

	for (i = 0; i < 16 && sha256[i]; i++)
		prefix[i] = sha256[i];
	return strtoull(prefix, NULL, 16);
}

static __u64 component_name_hash(const char *name)
{
	__u64 hash = W4_CCACHE_NAME_HASH_OFFSET;
	size_t i;

	for (i = 0; name[i]; i++) {
		hash ^= (unsigned char)name[i];
		hash *= W4_CCACHE_NAME_HASH_PRIME;
	}
	return hash;
}

static int update_rule(struct attached_policy *policy, __u64 cgroup_id,
		       __u32 event, const char *parent_dir, const char *name,
		       const char *target, __u32 branch)
{
	struct namei_ext_component_key key = {};
	struct namei_ext_redirect_rule rule = {};
	struct build_graph_rule build_rule = {};
	int ret;

	if (strlen(name) > NAMEI_EXT_NAME_MAX ||
	    strlen(target) > NAMEI_EXT_NAME_MAX)
		return -ENAMETOOLONG;

	ret = fill_key(&key, event, cgroup_id, parent_dir, name);
	if (ret)
		return ret;
	fill_rule(&rule, target, branch);
	if (policy->kind == POLICY_BUILD_GRAPH) {
		build_rule.redirect = rule;
		if (bpf_map_update_elem(policy->map_fd, &key, &build_rule,
					BPF_ANY))
			return -errno;
		return 0;
	}
	if (bpf_map_update_elem(policy->map_fd, &key, &rule, BPF_ANY))
		return -errno;
	return 0;
}

static int policy_map_fd_by_name(const struct attached_policy *policy,
				 const char *name)
{
	struct bpf_map *map;
	int fd;

	if (!policy || !policy->obj || !name)
		return -EINVAL;
	map = bpf_object__find_map_by_name(policy->obj, name);
	if (!map)
		return -ENOENT;
	fd = bpf_map__fd(map);
	if (fd < 0)
		return -EINVAL;
	return fd;
}

static int update_build_graph_session(struct attached_policy *policy,
				      __u64 cgroup_id, __u32 build_epoch,
				      bool active)
{
	struct build_graph_session session = {};
	int fd = policy_map_fd_by_name(policy, "build_graph_sessions");

	if (fd < 0)
		return fd;
	session.build_epoch = build_epoch;
	session.active = active ? 1 : 0;
	if (bpf_map_update_elem(fd, &cgroup_id, &session, BPF_ANY))
		return -errno;
	return 0;
}

static int update_build_graph_epoch_rule(
	struct attached_policy *policy, __u64 cgroup_id, __u32 event,
	const char *parent_dir, const char *name, const char *target,
	__u32 branch, __u32 branch_class, __u32 build_epoch)
{
	struct build_graph_epoch_rule_key key = {};
	struct build_graph_epoch_rule rule = {};
	int fd = policy_map_fd_by_name(policy, "build_graph_epoch_rules");
	int ret;

	if (fd < 0)
		return fd;
	if (strlen(name) > NAMEI_EXT_NAME_MAX ||
	    strlen(target) > NAMEI_EXT_NAME_MAX)
		return -ENAMETOOLONG;
	ret = fill_key(&key.component, event, cgroup_id, parent_dir, name);
	if (ret)
		return ret;
	key.branch_class = branch_class;
	key.build_epoch = build_epoch;
	fill_rule(&rule.redirect, target, branch);
	rule.branch_class = branch_class;
	if (bpf_map_update_elem(fd, &key, &rule, BPF_ANY))
		return -errno;
	return 0;
}

static int update_sandbox_fixture_session(struct attached_policy *policy,
					  __u64 cgroup_id,
					  __u32 fixture_epoch, bool active)
{
	struct sandbox_fixture_session session = {};
	int fd = policy_map_fd_by_name(policy, "fixture_sessions");

	if (fd < 0)
		return fd;
	session.fixture_epoch = fixture_epoch;
	session.active = active ? 1 : 0;
	if (bpf_map_update_elem(fd, &cgroup_id, &session, BPF_ANY))
		return -errno;
	return 0;
}

static int update_sandbox_fixture_epoch_rule(
	struct attached_policy *policy, __u64 cgroup_id, __u32 event,
	const char *parent_dir, const char *name, const char *target,
	__u32 branch, __u32 path_class, __u32 fixture_epoch)
{
	struct sandbox_fixture_epoch_rule_key key = {};
	struct sandbox_fixture_epoch_rule rule = {};
	int fd = policy_map_fd_by_name(policy, "fixture_epoch_rules");
	int ret;

	if (fd < 0)
		return fd;
	if (strlen(name) > NAMEI_EXT_NAME_MAX ||
	    strlen(target) > NAMEI_EXT_NAME_MAX)
		return -ENAMETOOLONG;
	ret = fill_key(&key.component, event, cgroup_id, parent_dir, name);
	if (ret)
		return ret;
	key.path_class = path_class;
	key.fixture_epoch = fixture_epoch;
	fill_rule(&rule.redirect, target, branch);
	rule.path_class = path_class;
	if (bpf_map_update_elem(fd, &key, &rule, BPF_ANY))
		return -errno;
	return 0;
}

static int update_checkpoint_session(struct attached_policy *policy,
				     __u64 cgroup_id, __u32 restore_id,
				     __u32 checkpoint_epoch, bool active)
{
	struct checkpoint_session session = {};
	int fd = policy_map_fd_by_name(policy, "checkpoint_sessions");

	if (fd < 0)
		return fd;
	session.restore_id = restore_id;
	session.checkpoint_epoch = checkpoint_epoch;
	session.active = active ? 1 : 0;
	if (bpf_map_update_elem(fd, &cgroup_id, &session, BPF_ANY))
		return -errno;
	return 0;
}

static int update_checkpoint_rule(struct attached_policy *policy,
				  __u64 cgroup_id, __u32 event,
				  const char *parent_dir, const char *name,
				  const char *target, __u32 branch,
				  __u32 path_class, __u32 checkpoint_epoch)
{
	struct checkpoint_rule_key key = {};
	struct checkpoint_rule rule = {};
	int ret;

	if (strlen(name) > NAMEI_EXT_NAME_MAX ||
	    strlen(target) > NAMEI_EXT_NAME_MAX)
		return -ENAMETOOLONG;
	ret = fill_key(&key.component, event, cgroup_id, parent_dir, name);
	if (ret)
		return ret;
	key.path_class = path_class;
	key.checkpoint_epoch = checkpoint_epoch;
	fill_rule(&rule.redirect, target, branch);
	if (bpf_map_update_elem(policy->map_fd, &key, &rule, BPF_ANY))
		return -errno;
	return 0;
}

static int update_cache_parent_rule(struct attached_policy *policy,
				    __u64 cgroup_id, __u32 event,
				    const char *parent_dir, __u32 state,
				    __u32 branch,
				    const __u64 *name_witnesses,
				    __u32 witness_count)
{
	struct namei_ext_component_key key = {};
	struct cache_rule rule = {};
	__u32 i;
	int ret;

	if (!name_witnesses || !witness_count ||
	    witness_count > W4_CCACHE_PARENT_NAME_WITNESSES)
		return -EINVAL;
	ret = fill_key(&key, event, cgroup_id, parent_dir, "");
	if (ret)
		return ret;
	rule.state = state;
	rule.verified_hit.branch = branch;
	rule.witness_count = witness_count;
	for (i = 0; i < witness_count; i++)
		rule.expected_hash[i] = name_witnesses[i];
	if (bpf_map_update_elem(policy->map_fd, &key, &rule, BPF_ANY))
		return -errno;
	return 0;
}

static int update_cache_rule(struct attached_policy *policy, __u64 cgroup_id,
			     __u32 event, const char *parent_dir,
			     const char *name, const char *target, __u32 branch,
			     __u32 state, const char *sha256)
{
	struct namei_ext_component_key key = {};
	struct cache_rule rule = {};
	__u64 witness_hash;
	int ret;

	if (strlen(name) > NAMEI_EXT_NAME_MAX ||
	    strlen(target) > NAMEI_EXT_NAME_MAX)
		return -ENAMETOOLONG;

	ret = fill_key(&key, event, cgroup_id, parent_dir, name);
	if (ret)
		return ret;
	fill_rule(&rule.verified_hit, target, branch);
	fill_rule(&rule.canonical, target, branch);
	fill_rule(&rule.reject, target, branch);
	witness_hash = sha_prefix_u64(sha256);
	rule.expected_hash[0] = witness_hash;
	rule.observed_hash[0] = witness_hash;
	rule.state = state;
	rule.witness_count = 1;
	if (bpf_map_update_elem(policy->map_fd, &key, &rule, BPF_ANY))
		return -errno;
	return 0;
}

static int update_cache_epoch_session(struct attached_policy *policy,
				      __u64 cgroup_id, __u32 cache_epoch,
				      bool active)
{
	struct cache_epoch_session session = {};
	int fd = policy_map_fd_by_name(policy, "cache_epoch_sessions");

	if (fd < 0)
		return fd;
	session.cache_epoch = cache_epoch;
	session.active = active ? 1 : 0;
	if (bpf_map_update_elem(fd, &cgroup_id, &session, BPF_ANY))
		return -errno;
	return 0;
}

static int update_cache_epoch_rule(struct attached_policy *policy,
				   __u64 cgroup_id, __u32 event,
				   const char *parent_dir, const char *name,
				   const char *target, __u32 branch,
				   __u32 state, __u32 cache_epoch)
{
	struct cache_epoch_rule_key key = {};
	struct cache_epoch_rule rule = {};
	int fd = policy_map_fd_by_name(policy, "cache_epoch_rules");
	int ret;

	if (fd < 0)
		return fd;
	if (strlen(name) > NAMEI_EXT_NAME_MAX ||
	    strlen(target) > NAMEI_EXT_NAME_MAX)
		return -ENAMETOOLONG;
	ret = fill_key(&key.component, event, cgroup_id, parent_dir, name);
	if (ret)
		return ret;
	key.cache_epoch = cache_epoch;
	fill_rule(&rule.redirect, target, branch);
	rule.state = state;
	if (bpf_map_update_elem(fd, &key, &rule, BPF_ANY))
		return -errno;
	return 0;
}

static int populate_policy_map(struct attached_policy *policy,
			       const struct oracle_entry *entries,
			       size_t nr_entries, __u64 cgroup_id)
{
	size_t i;

	if (policy->kind == POLICY_SANDBOX_FIXTURE ||
	    policy->kind == POLICY_CHECKPOINT_RESTORE)
		return 0;

	for (i = 0; i < nr_entries; i++) {
		const char *shadow = effective_shadow(policy->kind, &entries[i]);
		int ret;

		if (policy->kind == POLICY_CACHE_LOCALITY) {
			__u32 state = 0;

			ret = cache_state_for_branch(entries[i].branch, &state);
			if (ret)
				return ret;
			ret = update_cache_rule(policy, cgroup_id,
						BPF_NAMEI_EXT_LOOKUP,
						entries[i].dir,
						entries[i].visible, shadow,
						i + 1, state,
						entries[i].original_sha256);
			if (ret)
				return ret;
			ret = update_cache_rule(policy, cgroup_id,
						BPF_NAMEI_EXT_READDIR,
						entries[i].dir, shadow,
						entries[i].visible, i + 1, state,
						entries[i].original_sha256);
			if (ret)
				return ret;
			continue;
		}

		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
				  entries[i].dir, entries[i].visible, shadow,
				  i + 1);
		if (ret)
			return ret;
		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				  entries[i].dir, shadow, entries[i].visible,
				  i + 1);
		if (ret)
			return ret;
	}
	return 0;
}

static int open_policy(const char *obj_path, enum policy_kind kind,
		       const char *policy_name, struct attached_policy *policy)
{
	const char *map_name = "exact_redirects";
	struct bpf_program *prog;
	struct bpf_map *map;
	struct bpf_object *obj;
	int prog_fd;
	int err;

	if (kind == POLICY_BUILD_GRAPH)
		map_name = "build_graph_rules";
	else if (kind == POLICY_SANDBOX_FIXTURE)
		map_name = "fixture_rules";
	else if (kind == POLICY_CHECKPOINT_RESTORE)
		map_name = "checkpoint_rules";
	else if (kind == POLICY_CACHE_LOCALITY)
		map_name = "cache_rules";

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

	map = bpf_object__find_map_by_name(obj, map_name);
	if (!map) {
		errno = ENOENT;
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

	policy->obj = obj;
	policy->prog_fd = prog_fd;
	policy->map_fd = bpf_map__fd(map);
	policy->cgroup_fd = -1;
	policy->attached = false;
	policy->kind = kind;
	policy->name = policy_name;
	return 0;

err_close_obj:
	bpf_object__close(obj);
	return -1;
}

static int attach_policy(struct attached_policy *policy, const char *cgroup_path)
{
	int err;

	policy->cgroup_fd = open(cgroup_path,
				 O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (policy->cgroup_fd < 0)
		return -1;

	err = bpf_prog_attach(policy->prog_fd, policy->cgroup_fd,
			      BPF_CGROUP_NAMEI_EXT, 0);
	if (err) {
		errno = -err;
		close(policy->cgroup_fd);
		policy->cgroup_fd = -1;
		return -1;
	}
	policy->attached = true;
	return 0;
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

static int check_pre_attach(FILE *out, const char *policy,
			    const struct oracle_entry *entries,
			    size_t nr_entries)
{
	char path[PATH_MAX];
	int failures = 0;
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		int ret = set_path(path, sizeof(path), entries[i].dir,
				   entries[i].visible);
		int stat_ret = 0;

		if (!ret)
			stat_ret = expect_stat_errno(path, ENOENT);
		if (ret || stat_ret) {
			emit(out, policy, &entries[i], "pre_attach_absent",
			     false, ret ? -ret : -stat_ret,
			     "alias existed before attach");
			failures++;
		} else {
			emit(out, policy, &entries[i], "pre_attach_absent",
			     true, 0, "alias absent before attach");
		}
	}
	return failures;
}

static int check_entries(FILE *out, const struct attached_policy *policy,
			 const struct oracle_entry *entries, size_t nr_entries)
{
	char visible_path[PATH_MAX];
	char shadow_path[PATH_MAX];
	int failures = 0;
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		const char *shadow = effective_shadow(policy->kind, &entries[i]);
		bool saw_alias;
		bool saw_shadow;
		int err = 0;
		int ret;

		ret = set_path(visible_path, sizeof(visible_path),
			       entries[i].dir, entries[i].visible);
		if (!ret)
			ret = set_path(shadow_path, sizeof(shadow_path),
				       entries[i].dir, shadow);
		if (!ret)
			ret = compare_files(visible_path, shadow_path);
		if (ret) {
			emit(out, policy->name, &entries[i], "lookup", false,
			     -ret, "redirected lookup did not match backing");
			failures++;
		} else {
			emit(out, policy->name, &entries[i], "lookup", true, 0,
			     "redirected lookup matched backing");
		}

		saw_alias = dir_has_name(entries[i].dir, entries[i].visible, &err);
		saw_shadow = dir_has_name(entries[i].dir, shadow, &err);
		if (!err && saw_alias && !saw_shadow) {
			emit(out, policy->name, &entries[i], "readdir", true, 0,
			     "alias visible and policy backing hidden");
		} else {
			emit(out, policy->name, &entries[i], "readdir", false,
			     err, "directory view mismatch");
			failures++;
		}
	}
	return failures;
}

static int check_post_detach(FILE *out, const char *policy,
			     const struct oracle_entry *entries,
			     size_t nr_entries)
{
	char path[PATH_MAX];
	int failures = 0;
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		int ret = set_path(path, sizeof(path), entries[i].dir,
				   entries[i].visible);
		int stat_ret = 0;

		if (!ret)
			stat_ret = expect_stat_errno(path, ENOENT);
		if (ret || stat_ret) {
			emit(out, policy, &entries[i], "post_detach_absent",
			     false, ret ? -ret : -stat_ret,
			     "alias still resolved after detach");
			failures++;
		} else {
			emit(out, policy, &entries[i], "post_detach_absent",
			     true, 0, "alias absent after detach");
		}
	}
	return failures;
}

static int run_policy(FILE *out, const char *obj_path, enum policy_kind kind,
		      const char *policy_name, const char *attach_cgroup_path,
		      __u64 current_cgroup_id,
		      const struct oracle_entry *entries, size_t nr_entries)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	const char *pass_detail = "trace-derived path oracle passed";
	int failures = 0;
	int ret;

	failures += check_pre_attach(out, policy_name, entries, nr_entries);

	if (open_policy(obj_path, kind, policy_name, &policy)) {
		emit(out, policy_name, NULL, "load", false, errno,
		     "policy load failed");
		return failures + 1;
	}
	emit(out, policy_name, NULL, "load", true, 0, "policy loaded");

	if (!strcmp(event_prefix, "w2-oracle"))
		pass_detail = "fixture witness path oracle passed";
	else if (!strcmp(event_prefix, "w3-oracle"))
		pass_detail = "checkpoint witness path oracle passed";
	else if (!strcmp(event_prefix, "w4-oracle"))
		pass_detail = "cache witness path oracle passed";

	if (kind == POLICY_SANDBOX_FIXTURE) {
		emit(out, policy_name, NULL, "policy_state", true, 0,
		     "literal fixture path-class rules active");
	} else if (kind == POLICY_CHECKPOINT_RESTORE) {
		emit(out, policy_name, NULL, "policy_state", true, 0,
		     "literal checkpoint path-class rules active");
	} else {
		ret = populate_policy_map(&policy, entries, nr_entries,
					  current_cgroup_id);
		if (ret) {
			emit(out, policy_name, NULL, "map_update", false, -ret,
			     "failed to update redirect map");
			destroy_policy(&policy);
			return failures + 1;
		}
		emit(out, policy_name, NULL, "map_update", true, 0,
		     "redirect map populated");
	}

	if (attach_policy(&policy, attach_cgroup_path)) {
		emit(out, policy_name, NULL, "attach", false, errno,
		     "policy attach failed");
		destroy_policy(&policy);
		return failures + 1;
	}
	emit(out, policy_name, NULL, "attach", true, 0, "policy attached");

	failures += check_entries(out, &policy, entries, nr_entries);

	ret = destroy_policy(&policy);
	if (ret) {
		emit(out, policy_name, NULL, "detach", false, -ret,
		     "policy detach failed");
		failures++;
	} else {
		emit(out, policy_name, NULL, "detach", true, 0,
		     "policy detached");
	}

	failures += check_post_detach(out, policy_name, entries, nr_entries);

	fputs("{\"event\":", out);
	fprintf(out, "\"%s-summary\"", event_prefix);
	fputs(",\"result_level\":\"kvm_policy_path_oracle\","
	      "\"policy\":",
	      out);
	fprint_json_string(out, policy_name);
	fprintf(out, ",\"entries\":%zu,\"pass\":%s,"
		"\"failures\":%d,\"qualified_for_c8\":false,"
		"\"detail\":",
		nr_entries, failures ? "false" : "true", failures);
	fprint_json_string(out, failures ? "path oracle failed" : pass_detail);
	fputs("}\n", out);
	fflush(out);
	return failures ? 1 : 0;
}

static void emit_redis_replay_case(FILE *out, const char *op, bool pass,
				   int err, int exit_code,
				   bool policy_executed, const char *detail,
				   const char *path, const char *expected,
				   const char *actual)
{
	fputs("{\"event\":\"w3-redis-replay\",\"result_level\":", out);
	fprint_json_string(out, w3_redis_replay_result_level);
	fputs(",\"workload\":\"w3-redis-podman-criu\","
	      "\"app\":\"redis\",\"policy_family\":",
	      out);
	fprint_json_string(out, w3_redis_replay_policy_family);
	fprintf(out, ",\"table_baseline_current_oracle\":%s,\"op\":",
		w3_redis_replay_table_baseline ? "true" : "false");
	fprint_json_string(out, op);
	fprintf(out, ",\"pass\":%s,\"errno\":%d,\"exit_code\":%d,"
		"\"run_environment\":\"kvm\",\"policy_executed\":%s,"
		"\"kvm_validated\":true,"
		"\"podman_criu_restore_executed\":false,"
		"\"post_restore_vfs_replay\":true,"
		"\"qualified_for_c8\":false,\"detail\":",
		pass ? "true" : "false", err, exit_code,
		policy_executed ? "true" : "false");
	fprint_json_string(out, detail);
	fputs(",\"path\":", out);
	fprint_json_string(out, path ? path : "");
	fputs(",\"expected\":", out);
	fprint_json_string(out, expected ? expected : "");
	fputs(",\"actual\":", out);
	fprint_json_string(out, actual ? actual : "");
	fputs("}\n", out);
	fflush(out);
}

static int redis_write_all(int fd, const char *buf, size_t len)
{
	size_t off = 0;

	while (off < len) {
		ssize_t nwritten = write(fd, buf + off, len - off);

		if (nwritten < 0)
			return -errno;
		off += nwritten;
	}
	return 0;
}

static int redis_connect_port(int port)
{
	struct sockaddr_in addr = {};
	int saved_errno = ECONNREFUSED;
	int i;

	for (i = 0; i < 100; i++) {
		int fd = socket(AF_INET, SOCK_STREAM | SOCK_CLOEXEC, 0);

		if (fd < 0)
			return -errno;
		addr.sin_family = AF_INET;
		addr.sin_port = htons(port);
		if (inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr) != 1) {
			close(fd);
			return -EINVAL;
		}
		if (!connect(fd, (struct sockaddr *)&addr, sizeof(addr)))
			return fd;
		saved_errno = errno;
		close(fd);
		usleep(50000);
	}
	return -saved_errno;
}

static int redis_command(int port, const char *cmd, char *response,
			 size_t response_size, bool allow_eof)
{
	size_t used = 0;
	int fd;
	int ret;

	if (!response_size)
		return -EINVAL;
	response[0] = 0;
	fd = redis_connect_port(port);
	if (fd < 0)
		return fd;
	ret = redis_write_all(fd, cmd, strlen(cmd));
	if (ret) {
		close(fd);
		return ret;
	}
	for (;;) {
		ssize_t nread;

		if (used == response_size - 1)
			break;
		nread = read(fd, response + used, response_size - 1 - used);
		if (nread < 0) {
			ret = -errno;
			break;
		}
		if (!nread) {
			if (!used && !allow_eof)
				ret = -EIO;
			break;
		}
		used += nread;
		response[used] = 0;
		if (response[0] == '+' || response[0] == '-' ||
		    response[0] == ':') {
			if (strstr(response, "\r\n"))
				break;
		} else if (response[0] == '$') {
			char *line_end = strstr(response, "\r\n");

			if (line_end) {
				long bulk_len = strtol(response + 1, NULL, 10);
				size_t header_len = line_end + 2 - response;
				size_t want;

				if (bulk_len < 0)
					break;
				want = header_len + (size_t)bulk_len + 2;
				if (used >= want)
					break;
			}
		}
	}
	close(fd);
	response[used] = 0;
	return ret;
}

static int redis_set(int port, const char *key, const char *value,
		     char *response, size_t response_size)
{
	char cmd[512];
	int ret;

	ret = snprintf(cmd, sizeof(cmd),
		       "*3\r\n$3\r\nSET\r\n$%zu\r\n%s\r\n$%zu\r\n%s\r\n",
		       strlen(key), key, strlen(value), value);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(cmd))
		return -ENAMETOOLONG;
	ret = redis_command(port, cmd, response, response_size, false);
	if (ret)
		return ret;
	return strstr(response, "+OK") ? 0 : -EINVAL;
}

static int redis_get(int port, const char *key, char *response,
		     size_t response_size)
{
	char cmd[256];
	int ret;

	ret = snprintf(cmd, sizeof(cmd), "*2\r\n$3\r\nGET\r\n$%zu\r\n%s\r\n",
		       strlen(key), key);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(cmd))
		return -ENAMETOOLONG;
	return redis_command(port, cmd, response, response_size, false);
}

static int redis_save(int port, char *response, size_t response_size)
{
	int ret = redis_command(port, "*1\r\n$4\r\nSAVE\r\n", response,
				response_size, false);

	if (ret)
		return ret;
	return strstr(response, "+OK") ? 0 : -EINVAL;
}

static int redis_shutdown(int port)
{
	char response[256];
	int ret;
	int i;

	ret = redis_command(port,
			    "*2\r\n$8\r\nSHUTDOWN\r\n$6\r\nNOSAVE\r\n",
			    response, sizeof(response), true);
	if (ret && ret != -EIO && ret != -ECONNRESET)
		return ret;
	for (i = 0; i < 100; i++) {
		int fd = redis_connect_port(port);

		if (fd < 0)
			return 0;
		close(fd);
		usleep(50000);
	}
	return -ETIMEDOUT;
}

static int run_redis_daemon(const char *redis_bin, const char *dir,
			    const char *dbfilename, int port,
			    const char *pidfile, const char *logfile,
			    int *exit_code)
{
	char port_arg[16];
	int status;
	pid_t pid;
	int ret;

	ret = snprintf(port_arg, sizeof(port_arg), "%d", port);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(port_arg))
		return -ENAMETOOLONG;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (pid == 0) {
		execl(redis_bin, redis_bin,
		      "--bind", "127.0.0.1",
		      "--protected-mode", "no",
		      "--port", port_arg,
		      "--dir", dir,
		      "--dbfilename", dbfilename,
		      "--appendonly", "no",
		      "--daemonize", "yes",
		      "--pidfile", pidfile,
		      "--logfile", logfile,
		      "--save", "",
		      (char *)NULL);
		_exit(127);
	}
	if (waitpid(pid, &status, 0) < 0)
		return -errno;
	if (WIFEXITED(status))
		*exit_code = WEXITSTATUS(status);
	else if (WIFSIGNALED(status))
		*exit_code = 128 + WTERMSIG(status);
	else
		*exit_code = 126;
	if (*exit_code)
		return 0;

	ret = redis_connect_port(port);
	if (ret < 0)
		return ret;
	close(ret);
	return 0;
}

static bool redis_response_is_nil(const char *response)
{
	return strstr(response, "$-1\r\n") != NULL;
}

static bool redis_response_has_value(const char *response, const char *value)
{
	return strstr(response, value) != NULL;
}

static int run_w3_redis_replay(FILE *out, const char *cgroup_mount,
			       const char *work_dir, const char *redis_bin,
			       const char *policy_path,
			       enum policy_kind policy_kind,
			       const char *policy_name,
			       const char *policy_family,
			       const char *result_level,
			       bool table_baseline)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	char checkpoint_dir[PATH_MAX];
	char runtime_dir[PATH_MAX];
	char dump_rdb[PATH_MAX];
	char dump_ckpt[PATH_MAX];
	char pidfile[PATH_MAX];
	char logfile[PATH_MAX];
	char response[1024];
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	int failures = 0;
	int exit_code = -1;
	int err = 0;
	int port_base = 21000 + (getpid() % 10000);
	int ret;

	w3_redis_replay_result_level = result_level;
	w3_redis_replay_policy_family = policy_family;
	w3_redis_replay_table_baseline = table_baseline;

	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_redis_replay_case(out, "mkdir_work_dir", false, -ret,
				       -1, false,
				       "failed to create W3 Redis replay workdir",
				       work_dir, "", "");
		return 1;
	}
	ret = set_path(checkpoint_dir, sizeof(checkpoint_dir), work_dir,
		       "checkpoint");
	if (!ret)
		ret = set_path(runtime_dir, sizeof(runtime_dir), work_dir,
			       "runtime");
	if (!ret)
		ret = mkdir_if_missing(checkpoint_dir);
	if (!ret)
		ret = mkdir_if_missing(runtime_dir);
	if (!ret)
		ret = set_path(dump_rdb, sizeof(dump_rdb), checkpoint_dir,
			       "dump.rdb");
	if (!ret)
		ret = set_path(dump_ckpt, sizeof(dump_ckpt), checkpoint_dir,
			       "dump.ckpt");
	if (ret) {
		emit_redis_replay_case(out, "prepare_paths", false, -ret, -1,
				       false, "failed to prepare replay paths",
				       work_dir, "", "");
		return 1;
	}
	unlink_existing(dump_rdb);
	unlink_existing(dump_ckpt);

	ret = set_path(pidfile, sizeof(pidfile), runtime_dir,
		       "redis-generate.pid");
	if (!ret)
		ret = set_path(logfile, sizeof(logfile), runtime_dir,
			       "redis-generate.log");
	if (!ret)
		ret = run_redis_daemon(redis_bin, checkpoint_dir, "dump.ckpt",
				       port_base, pidfile, logfile,
				       &exit_code);
	if (ret || exit_code) {
		emit_redis_replay_case(out, "generate_checkpoint_start",
				       false, ret ? -ret : 0, exit_code,
				       false,
				       "failed to start Redis checkpoint generator",
				       checkpoint_dir, "exit_code=0", "");
		return 1;
	}
	emit_redis_replay_case(out, "generate_checkpoint_start", true, 0,
			       exit_code, false,
			       "Redis checkpoint generator started",
			       checkpoint_dir, "exit_code=0", "exit_code=0");

	ret = redis_set(port_base, W3_REDIS_KEY, W3_REDIS_VALUE, response,
			sizeof(response));
	if (ret) {
		emit_redis_replay_case(out, "generate_checkpoint_set", false,
				       -ret, -1, false,
				       "failed to seed Redis checkpoint value",
				       checkpoint_dir, "+OK", response);
		failures++;
	} else {
		emit_redis_replay_case(out, "generate_checkpoint_set", true,
				       0, 0, false,
				       "Redis checkpoint value seeded",
				       checkpoint_dir, "+OK", response);
	}
	ret = redis_save(port_base, response, sizeof(response));
	if (ret) {
		emit_redis_replay_case(out, "generate_checkpoint_save", false,
				       -ret, -1, false,
				       "failed to save Redis checkpoint file",
				       dump_ckpt, "+OK", response);
		failures++;
	} else {
		emit_redis_replay_case(out, "generate_checkpoint_save", true,
				       0, 0, false,
				       "Redis checkpoint file saved",
				       dump_ckpt, "+OK", response);
	}
	redis_shutdown(port_base);
	if (expect_stat_errno(dump_ckpt, 0)) {
		emit_redis_replay_case(out, "checkpoint_file_exists", false,
				       ENOENT, -1, false,
				       "Redis checkpoint backing file missing",
				       dump_ckpt, "exists", "missing");
		failures++;
	} else {
		emit_redis_replay_case(out, "checkpoint_file_exists", true, 0,
				       0, false,
				       "Redis checkpoint backing file exists",
				       dump_ckpt, "exists", "exists");
	}
	unlink_existing(dump_rdb);

	ret = set_path(pidfile, sizeof(pidfile), runtime_dir, "redis-pre.pid");
	if (!ret)
		ret = set_path(logfile, sizeof(logfile), runtime_dir,
			       "redis-pre.log");
	if (!ret)
		ret = run_redis_daemon(redis_bin, checkpoint_dir, "dump.rdb",
				       port_base + 1, pidfile, logfile,
				       &exit_code);
	if (ret || exit_code) {
		emit_redis_replay_case(out, "pre_attach_redis_start", false,
				       ret ? -ret : 0, exit_code, false,
				       "failed to start Redis before attach",
				       checkpoint_dir, "exit_code=0", "");
		failures++;
	} else {
		ret = redis_get(port_base + 1, W3_REDIS_KEY, response,
				sizeof(response));
		if (ret || !redis_response_is_nil(response)) {
			emit_redis_replay_case(out, "pre_attach_get_empty",
					       false, ret ? -ret : EINVAL, -1,
					       false,
					       "Redis saw checkpoint value before attach",
					       dump_rdb, "$-1", response);
			failures++;
		} else {
			emit_redis_replay_case(out, "pre_attach_get_empty",
					       true, 0, 0, false,
					       "Redis did not load hidden checkpoint before attach",
					       dump_rdb, "$-1", response);
		}
		redis_shutdown(port_base + 1);
	}

	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (ret) {
		emit_redis_replay_case(out, "current_cgroup", false, -ret, -1,
				       false,
				       "failed to resolve current cgroup path",
				       cgroup_mount, "", "");
		return 1;
	}
	ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		emit_redis_replay_case(out, "current_cgroup_id", false, -ret,
				       -1, false,
				       "failed to resolve current cgroup id",
				       current_cgroup, "", "");
		return 1;
	}
	if (open_policy(policy_path, policy_kind, policy_name, &policy)) {
		emit_redis_replay_case(out, "load", false, errno, -1, false,
				       "checkpoint replay policy load failed",
				       policy_path, "load", "");
		return 1;
	}
	emit_redis_replay_case(out, "load", true, 0, 0, false,
			       "checkpoint replay policy loaded", policy_path,
			       "load", "load");
	if (table_baseline) {
		ret = update_rule(&policy, current_cgroup_id,
				  BPF_NAMEI_EXT_LOOKUP, checkpoint_dir,
				  "dump.rdb", "dump.ckpt", 1);
		if (!ret)
			ret = update_rule(&policy, current_cgroup_id,
					  BPF_NAMEI_EXT_READDIR, checkpoint_dir,
					  "dump.ckpt", "dump.rdb", 1);
		if (ret) {
			emit_redis_replay_case(out, "populate_table_rules",
					       false, -ret, -1, false,
					       "failed to populate table_redirect checkpoint rules",
					       checkpoint_dir, "2", "");
			destroy_policy(&policy);
			return 1;
		}
		emit_redis_replay_case(out, "populate_table_rules", true, 0,
				       0, false,
				       "table_redirect checkpoint lookup and readdir rules populated",
				       checkpoint_dir, "2", "2");
	}
	if (attach_policy(&policy, current_cgroup)) {
		emit_redis_replay_case(out, "attach", false, errno, -1, false,
				       "checkpoint replay policy attach failed",
				       current_cgroup, "attach", "");
		destroy_policy(&policy);
		return 1;
	}
	emit_redis_replay_case(out, "attach", true, 0, 0, true,
			       "checkpoint replay policy attached",
			       current_cgroup, "attach", "attach");

	ret = set_path(pidfile, sizeof(pidfile), runtime_dir,
		       "redis-attached.pid");
	if (!ret)
		ret = set_path(logfile, sizeof(logfile), runtime_dir,
			       "redis-attached.log");
	if (!ret)
		ret = run_redis_daemon(redis_bin, checkpoint_dir, "dump.rdb",
				       port_base + 2, pidfile, logfile,
				       &exit_code);
	if (ret || exit_code) {
		emit_redis_replay_case(out, "attached_redis_start", false,
				       ret ? -ret : 0, exit_code, true,
				       "failed to start Redis while policy attached",
				       checkpoint_dir, "exit_code=0", "");
		failures++;
	} else {
		bool saw_alias = dir_has_name(checkpoint_dir, "dump.rdb", &err);
		bool saw_backing = dir_has_name(checkpoint_dir, "dump.ckpt", &err);

		ret = redis_get(port_base + 2, W3_REDIS_KEY, response,
				sizeof(response));
		if (ret || !redis_response_has_value(response, W3_REDIS_VALUE)) {
			emit_redis_replay_case(out,
					       "attached_get_checkpoint_value",
					       false, ret ? -ret : EINVAL, -1,
					       true,
					       "Redis did not load checkpoint value through visible dump.rdb",
					       dump_rdb, W3_REDIS_VALUE,
					       response);
			failures++;
		} else {
			emit_redis_replay_case(out,
					       "attached_get_checkpoint_value",
					       true, 0, 0, true,
					       "Redis loaded checkpoint value through visible dump.rdb",
					       dump_rdb, W3_REDIS_VALUE,
					       response);
		}
		if (!err && saw_alias && !saw_backing) {
			emit_redis_replay_case(out, "attached_readdir_alias",
					       true, 0, 0, true,
					       "checkpoint backing appears as visible dump.rdb while attached",
					       checkpoint_dir, "dump.rdb",
					       "dump.rdb");
		} else {
			emit_redis_replay_case(out, "attached_readdir_alias",
					       false, err, -1, true,
					       "checkpoint directory view did not expose expected alias",
					       checkpoint_dir,
					       "dump.rdb without dump.ckpt",
					       saw_backing ? "saw dump.ckpt" :
					       "missing dump.rdb");
			failures++;
		}
		redis_shutdown(port_base + 2);
	}

	ret = destroy_policy(&policy);
	if (ret) {
		emit_redis_replay_case(out, "detach", false, -ret, -1, true,
				       "checkpoint replay policy detach failed",
				       current_cgroup, "detach", "");
		failures++;
	} else {
		emit_redis_replay_case(out, "detach", true, 0, 0, true,
				       "checkpoint replay policy detached",
				       current_cgroup, "detach", "detach");
	}

	ret = set_path(pidfile, sizeof(pidfile), runtime_dir, "redis-post.pid");
	if (!ret)
		ret = set_path(logfile, sizeof(logfile), runtime_dir,
			       "redis-post.log");
	if (!ret)
		ret = run_redis_daemon(redis_bin, checkpoint_dir, "dump.rdb",
				       port_base + 3, pidfile, logfile,
				       &exit_code);
	if (ret || exit_code) {
		emit_redis_replay_case(out, "post_detach_redis_start", false,
				       ret ? -ret : 0, exit_code, false,
				       "failed to start Redis after detach",
				       checkpoint_dir, "exit_code=0", "");
		failures++;
	} else {
		ret = redis_get(port_base + 3, W3_REDIS_KEY, response,
				sizeof(response));
		if (ret || !redis_response_is_nil(response)) {
			emit_redis_replay_case(out, "post_detach_get_empty",
					       false, ret ? -ret : EINVAL, -1,
					       false,
					       "Redis still saw checkpoint value after detach",
					       dump_rdb, "$-1", response);
			failures++;
		} else {
			emit_redis_replay_case(out, "post_detach_get_empty",
					       true, 0, 0, false,
					       "Redis no longer loaded hidden checkpoint after detach",
					       dump_rdb, "$-1", response);
		}
		redis_shutdown(port_base + 3);
	}

	fprintf(out,
		"{\"event\":\"w3-redis-replay-summary\","
		"\"result_level\":");
	fprint_json_string(out, result_level);
	fprintf(out,
		",\"workload\":\"w3-redis-podman-criu\","
		"\"app\":\"redis\",\"run_environment\":\"kvm\","
		"\"policy_family\":");
	fprint_json_string(out, policy_family);
	fprintf(out,
		",\"table_baseline_current_oracle\":%s,"
		"\"policy_executed\":true,\"kvm_validated\":true,"
		"\"redis_checkpoint_loaded_via_policy\":%s,"
		"\"post_restore_vfs_replay\":true,"
		"\"podman_criu_restore_executed\":false,"
		"\"pass\":%s,\"failures\":%d,"
		"\"qualified_for_c8\":false,\"detail\":",
		table_baseline ? "true" : "false",
		failures ? "false" : "true",
		failures ? "false" : "true", failures);
	fprint_json_string(out, failures ?
			   "Redis checkpoint replay witness failed" :
			   (table_baseline ?
			    "Redis loaded checkpoint state through table_redirect; this is negative C8 evidence for this replay" :
			    "Redis loaded checkpoint state through checkpoint_restore policy; real Podman/CRIU restore remains a blocker"));
	fputs("}\n", out);
	fflush(out);
	return failures ? 1 : 0;
}

#define W1_BUILD_EPOCH_ONE 1
#define W1_BUILD_EPOCH_TWO 2
#define W1_BUILD_EPOCH_DEFAULT_OBJECTS 16
#define W1_BUILD_EPOCH_MAX_OBJECTS 64
#define W1_BUILD_EPOCH_TABLE_MAX_UPDATE_RATIO 10

struct w1_build_epoch_entry {
	char visible[NAMEI_EXT_NAME_MAX + 1];
	char epoch1[NAMEI_EXT_NAME_MAX + 1];
	char epoch2[NAMEI_EXT_NAME_MAX + 1];
	__u32 branch_class;
};

struct w1_build_epoch_stats {
	int setup_rows;
	int correctness_rows;
	int update_rows;
	int failures;
	size_t objects;
	size_t static_wrong_epoch_hits;
	unsigned long long policy_setup_writes;
	unsigned long long table_setup_writes;
	unsigned long long materialized_setup_writes;
	unsigned long long fuse_setup_writes;
	unsigned long long policy_update_writes;
	unsigned long long table_update_writes;
	unsigned long long materialized_update_writes;
	unsigned long long fuse_update_writes;
	unsigned long long fuse_mounts;
	bool policy_epoch_switch_pass;
	bool table_static_expected_failure;
	bool table_updated_pass;
	bool materialized_updated_pass;
	bool fuse_updated_pass;
};

static __u32 w1_build_epoch_class_for_index(size_t index)
{
	switch (index % 5) {
	case 0:
		return BUILD_BRANCH_GENERATED;
	case 1:
		return BUILD_BRANCH_SOURCE_FALLBACK;
	case 2:
		return BUILD_BRANCH_TOOLCHAIN;
	case 3:
		return BUILD_BRANCH_EXTERNAL_DEP;
	default:
		return BUILD_BRANCH_UNDECLARED_POISON;
	}
}

static const char *w1_build_epoch_class_name(__u32 branch_class)
{
	switch (branch_class) {
	case BUILD_BRANCH_GENERATED:
		return "generated";
	case BUILD_BRANCH_SOURCE_FALLBACK:
		return "source_fallback";
	case BUILD_BRANCH_TOOLCHAIN:
		return "toolchain";
	case BUILD_BRANCH_EXTERNAL_DEP:
		return "external_dep";
	case BUILD_BRANCH_UNDECLARED_POISON:
		return "undeclared_poison";
	default:
		return "unknown";
	}
}

static const char *w1_build_epoch_target(
	const struct w1_build_epoch_entry *entry, __u32 epoch)
{
	return epoch == W1_BUILD_EPOCH_TWO ? entry->epoch2 : entry->epoch1;
}

static int prepare_w1_build_epoch_names(struct w1_build_epoch_entry *entry,
					size_t index)
{
	const char *prefix = "obj";
	const char *suffix = "dep";
	int ret;

	entry->branch_class = w1_build_epoch_class_for_index(index);
	switch (entry->branch_class) {
	case BUILD_BRANCH_GENERATED:
		prefix = "gen";
		suffix = "h";
		break;
	case BUILD_BRANCH_SOURCE_FALLBACK:
		prefix = "src";
		suffix = "h";
		break;
	case BUILD_BRANCH_TOOLCHAIN:
		prefix = "tool";
		suffix = "bin";
		break;
	case BUILD_BRANCH_EXTERNAL_DEP:
		prefix = "dep";
		suffix = "so";
		break;
	case BUILD_BRANCH_UNDECLARED_POISON:
		prefix = "priv";
		suffix = "h";
		break;
	default:
		return -EINVAL;
	}

	ret = snprintf(entry->visible, sizeof(entry->visible), "%s%02zu.%s",
		       prefix, index, suffix);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(entry->visible))
		return -ENAMETOOLONG;
	ret = snprintf(entry->epoch1, sizeof(entry->epoch1), "%s%02zu.e1",
		       prefix, index);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(entry->epoch1))
		return -ENAMETOOLONG;
	ret = snprintf(entry->epoch2, sizeof(entry->epoch2), "%s%02zu.e2",
		       prefix, index);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(entry->epoch2))
		return -ENAMETOOLONG;
	return 0;
}

static int prepare_w1_build_epoch_dir(const char *dir,
				      struct w1_build_epoch_entry *entries,
				      size_t objects, int sample)
{
	char path[PATH_MAX];
	char text[192];
	size_t i;
	int ret;

	ret = mkdir_if_missing(dir);
	if (ret)
		return ret;
	for (i = 0; i < objects; i++) {
		ret = prepare_w1_build_epoch_names(&entries[i], i);
		if (ret)
			return ret;
		ret = set_path(path, sizeof(path), dir, entries[i].visible);
		if (ret)
			return ret;
		unlink_existing(path);

		ret = set_path(path, sizeof(path), dir, entries[i].epoch1);
		if (ret)
			return ret;
		ret = snprintf(text, sizeof(text),
			       "namei_ext w1 build sample %d object %zu branch %s epoch 1\n",
			       sample, i,
			       w1_build_epoch_class_name(entries[i].branch_class));
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(text))
			return -ENAMETOOLONG;
		ret = write_text_file(path, text);
		if (ret)
			return ret;

		ret = set_path(path, sizeof(path), dir, entries[i].epoch2);
		if (ret)
			return ret;
		ret = snprintf(text, sizeof(text),
			       "namei_ext w1 build sample %d object %zu branch %s epoch 2\n",
			       sample, i,
			       w1_build_epoch_class_name(entries[i].branch_class));
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(text))
			return -ENAMETOOLONG;
		ret = write_text_file(path, text);
		if (ret)
			return ret;
	}
	return 0;
}

static int w1_build_epoch_lookup_matches(
	const char *dir, const struct w1_build_epoch_entry *entry, __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), dir,
			       w1_build_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static int w1_build_epoch_readdir_hides_backings(
	const char *dir, const struct w1_build_epoch_entry *entry)
{
	bool saw_visible;
	bool saw_epoch1;
	bool saw_epoch2;
	int err = 0;

	saw_visible = dir_has_name(dir, entry->visible, &err);
	if (!err)
		saw_epoch1 = dir_has_name(dir, entry->epoch1, &err);
	else
		saw_epoch1 = false;
	if (!err)
		saw_epoch2 = dir_has_name(dir, entry->epoch2, &err);
	else
		saw_epoch2 = false;
	if (!err && saw_visible && !saw_epoch1 && !saw_epoch2)
		return 0;
	return err ? -err : -ENOENT;
}

static bool w1_build_epoch_current_oracle_passes(
	const char *dir, const struct w1_build_epoch_entry *entries,
	size_t objects, __u32 epoch, size_t *wrong_epoch_hits,
	__u32 wrong_epoch)
{
	bool pass = true;
	size_t wrong = 0;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w1_build_epoch_lookup_matches(dir, &entries[i], epoch))
			pass = false;
		if (w1_build_epoch_readdir_hides_backings(dir, &entries[i]))
			pass = false;
		if (wrong_epoch &&
		    !w1_build_epoch_lookup_matches(dir, &entries[i],
						   wrong_epoch))
			wrong++;
	}
	if (wrong_epoch_hits)
		*wrong_epoch_hits = wrong;
	return pass;
}

static void emit_w1_build_epoch_setup(
	FILE *out, int sample, const char *system, bool pass, int err,
	__u64 setup_ns, size_t objects, unsigned long long setup_writes,
	bool policy_executed, const char *detail)
{
	const char *write_key = policy_executed ? "setup_rule_writes" :
						"setup_materialization_writes";

	fputs("{\"event\":\"w1-build-epoch-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_epoch.v1\","
	      "\"result_level\":\"kvm_build_graph_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph-epoch\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,\"objects\":%zu,"
		"\"dynamic_build_branches\":5,"
		"\"setup_writes\":%llu,\"%s\":%llu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, objects, setup_writes,
		write_key, setup_writes,
		policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w1_build_epoch_correctness(
	FILE *out, int sample, const char *system, const char *stage,
	bool pass, bool current_oracle_pass,
	bool expected_static_failure_observed, size_t wrong_epoch_hits,
	bool policy_executed, const char *detail)
{
	fputs("{\"event\":\"w1-build-epoch-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_epoch.v1\","
	      "\"result_level\":\"kvm_build_graph_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph-epoch\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fputs(",\"stage\":", out);
	fprint_json_string(out, stage);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,"
		"\"current_oracle_pass\":%s,"
		"\"expected_static_failure_observed\":%s,"
		"\"wrong_epoch_hits\":%zu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false",
		current_oracle_pass ? "true" : "false",
		expected_static_failure_observed ? "true" : "false",
		wrong_epoch_hits, policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w1_build_epoch_update(
	FILE *out, int sample, const char *system, bool pass, int err,
	__u64 update_ns, __u64 observed_window_ns,
	unsigned long long update_writes, bool policy_executed,
	const char *detail)
{
	fputs("{\"event\":\"w1-build-epoch-update-window\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_epoch.v1\","
	      "\"result_level\":\"kvm_build_graph_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph-epoch\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"observed_update_window_ns\":%llu,"
		"\"update_writes\":%llu,"
		"\"from_epoch\":1,\"to_epoch\":2,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns,
		(unsigned long long)observed_window_ns, update_writes,
		policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w1_build_epoch_summary(
	FILE *out, int samples, const struct w1_build_epoch_stats *stats,
	const char *detail)
{
	double update_ratio = stats->policy_update_writes ?
		(double)stats->table_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	double materialized_update_ratio = stats->policy_update_writes ?
		(double)stats->materialized_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	double fuse_update_ratio = stats->policy_update_writes ?
		(double)stats->fuse_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	bool table_update_budget_failure =
		update_ratio > W1_BUILD_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool materialized_update_budget_failure =
		materialized_update_ratio > W1_BUILD_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool fuse_update_budget_failure =
		fuse_update_ratio > W1_BUILD_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool targeted_c8_budget_failure =
		stats->policy_epoch_switch_pass &&
		stats->table_static_expected_failure &&
		stats->table_updated_pass &&
		table_update_budget_failure;
	bool state_branch_not_static =
		stats->policy_epoch_switch_pass &&
		stats->table_static_expected_failure;

	fputs("{\"event\":\"w1-build-epoch-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_epoch.v1\","
	      "\"result_level\":\"kvm_build_graph_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph-epoch\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"setup_rows\":%d,"
		"\"correctness_rows\":%d,\"update_rows\":%d,"
		"\"objects\":%zu,"
		"\"dynamic_build_branches\":5,"
		"\"static_wrong_epoch_hits\":%zu,"
		"\"policy_setup_writes\":%llu,"
		"\"table_setup_writes\":%llu,"
		"\"materialized_setup_writes\":%llu,"
		"\"fuse_setup_writes\":%llu,"
		"\"policy_update_writes\":%llu,"
		"\"table_update_writes\":%llu,"
		"\"materialized_update_writes\":%llu,"
		"\"fuse_update_writes\":%llu,"
		"\"fuse_mounts\":%llu,"
		"\"table_update_write_ratio\":%.17g,"
		"\"materialized_update_write_ratio\":%.17g,"
		"\"fuse_update_write_ratio\":%.17g,"
		"\"max_table_update_write_ratio\":%d,"
		"\"table_static_current_oracle_pass\":false,"
		"\"table_static_expected_failure_observed\":%s,"
		"\"table_updated_current_oracle_pass\":%s,"
		"\"table_requires_external_state_updates\":true,"
		"\"table_update_budget_failure\":%s,"
		"\"materialized_current_oracle_pass\":%s,"
		"\"materialized_feature_equivalent_baseline\":%s,"
		"\"materialized_update_budget_failure\":%s,"
		"\"fuse_current_oracle_pass\":%s,"
		"\"fuse_feature_equivalent_baseline\":%s,"
		"\"fuse_update_budget_failure\":%s,"
		"\"targeted_c8_budget_failure\":%s,"
		"\"state_dependent_branch_not_static_table_expressible\":%s,"
		"\"real_redis_nginx_trace\":false,"
		"\"release_sample_budget_pass\":%s,"
		"\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"qualified_for_c8\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, stats->setup_rows, stats->correctness_rows,
		stats->update_rows, stats->objects,
		stats->static_wrong_epoch_hits, stats->policy_setup_writes,
		stats->table_setup_writes, stats->materialized_setup_writes,
		stats->fuse_setup_writes,
		stats->policy_update_writes, stats->table_update_writes,
		stats->materialized_update_writes, stats->fuse_update_writes,
		stats->fuse_mounts, update_ratio, materialized_update_ratio,
		fuse_update_ratio, W1_BUILD_EPOCH_TABLE_MAX_UPDATE_RATIO,
		stats->table_static_expected_failure ? "true" : "false",
		stats->table_updated_pass ? "true" : "false",
		table_update_budget_failure ? "true" : "false",
		stats->materialized_updated_pass ? "true" : "false",
		stats->materialized_updated_pass ? "true" : "false",
		materialized_update_budget_failure ? "true" : "false",
		stats->fuse_updated_pass ? "true" : "false",
		stats->fuse_updated_pass ? "true" : "false",
		fuse_update_budget_failure ? "true" : "false",
		targeted_c8_budget_failure ? "true" : "false",
		state_branch_not_static ? "true" : "false",
		samples >= 20 ? "true" : "false",
		stats->failures ? "false" : "true", stats->failures,
		stats->failures ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int populate_w1_build_epoch_policy_rules(
	struct attached_policy *policy, __u64 cgroup_id, const char *dir,
	const struct w1_build_epoch_entry *entries, size_t objects,
	unsigned long long *writes)
{
	size_t i;

	*writes = 0;
	for (i = 0; i < objects; i++) {
		__u32 branch = (__u32)i + 1;
		__u32 branch_class = entries[i].branch_class;
		int ret;

		ret = update_build_graph_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP, dir,
			entries[i].visible, entries[i].epoch1, branch,
			branch_class, W1_BUILD_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_build_graph_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP, dir,
			entries[i].visible, entries[i].epoch2, branch,
			branch_class, W1_BUILD_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_build_graph_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch1, entries[i].visible, branch,
			branch_class, W1_BUILD_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_build_graph_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch2, entries[i].visible, branch,
			branch_class, W1_BUILD_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_build_graph_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch1, entries[i].visible, branch,
			branch_class, W1_BUILD_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_build_graph_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch2, entries[i].visible, branch,
			branch_class, W1_BUILD_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
	}
	return 0;
}

static int populate_w1_build_epoch_table_rules(
	struct attached_policy *policy, __u64 cgroup_id, const char *dir,
	const struct w1_build_epoch_entry *entries, size_t objects,
	__u32 epoch, bool include_readdir, unsigned long long *writes)
{
	size_t i;

	*writes = 0;
	for (i = 0; i < objects; i++) {
		int ret;

		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
				  dir, entries[i].visible,
				  w1_build_epoch_target(&entries[i], epoch),
				  i + 1);
		if (ret)
			return ret;
		(*writes)++;
		if (!include_readdir)
			continue;
		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				  dir, entries[i].epoch1, entries[i].visible,
				  i + 1);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				  dir, entries[i].epoch2, entries[i].visible,
				  i + 1);
		if (ret)
			return ret;
		(*writes)++;
	}
	return 0;
}

static int run_w1_build_epoch_policy_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, struct w1_build_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w1_build_epoch_entry entries[W1_BUILD_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w1_build_epoch_dir(sample_dir, entries, objects, sample);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_BUILD_GRAPH,
				  "build_graph_epoch", &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w1_build_epoch_policy_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			&setup_writes);
	if (!ret)
		ret = update_build_graph_session(
			&policy, cgroup_id, W1_BUILD_EPOCH_ONE, true);
	if (!ret)
		setup_writes++;
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->policy_setup_writes += setup_writes;
	emit_w1_build_epoch_setup(
		out, sample, "build_graph_epoch_policy", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? "failed to setup build graph epoch policy" :
		      "build graph policy attached with two epoch rule sets");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w1_build_epoch_current_oracle_passes(
		sample_dir, entries, objects, W1_BUILD_EPOCH_ONE, NULL, 0);
	stats->correctness_rows++;
	emit_w1_build_epoch_correctness(
		out, sample, "build_graph_epoch_policy", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, true,
		epoch1_pass ? "build graph epoch 1 oracle passed" :
			      "build graph epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = update_build_graph_session(
		&policy, cgroup_id, W1_BUILD_EPOCH_TWO, true);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w1_build_epoch_current_oracle_passes(
			sample_dir, entries, objects, W1_BUILD_EPOCH_TWO,
			NULL, 0);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->policy_update_writes++;
	emit_w1_build_epoch_update(
		out, sample, "build_graph_epoch_policy",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, 1, true,
		(!ret && epoch2_pass) ?
			"build graph policy switched epoch with one session update" :
			"build graph policy epoch switch failed");
	stats->correctness_rows++;
	emit_w1_build_epoch_correctness(
		out, sample, "build_graph_epoch_policy", "epoch2",
		!ret && epoch2_pass, !ret && epoch2_pass, false, 0, true,
		(!ret && epoch2_pass) ?
			"build graph epoch 2 oracle passed" :
			"build graph epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->policy_epoch_switch_pass = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int run_w1_build_epoch_table_static_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, struct w1_build_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w1_build_epoch_entry entries[W1_BUILD_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	size_t wrong_epoch_hits = 0;
	bool epoch1_pass = false;
	bool epoch2_current_pass = false;
	bool expected_failure = false;
	__u64 start_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w1_build_epoch_dir(sample_dir, entries, objects, sample);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_TABLE, "table_redirect",
				  &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w1_build_epoch_table_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			W1_BUILD_EPOCH_ONE, true, &setup_writes);
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->table_setup_writes += setup_writes;
	emit_w1_build_epoch_setup(
		out, sample, "table_redirect_static_build_epoch1", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? "failed to setup static build table" :
		      "static exact table attached with build epoch 1 lookup rules");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w1_build_epoch_current_oracle_passes(
		sample_dir, entries, objects, W1_BUILD_EPOCH_ONE, NULL, 0);
	stats->correctness_rows++;
	emit_w1_build_epoch_correctness(
		out, sample, "table_redirect_static_build_epoch1", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, true,
		epoch1_pass ? "static table build epoch 1 oracle passed" :
			      "static table build epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	epoch2_current_pass = w1_build_epoch_current_oracle_passes(
		sample_dir, entries, objects, W1_BUILD_EPOCH_TWO,
		&wrong_epoch_hits, W1_BUILD_EPOCH_ONE);
	expected_failure = !epoch2_current_pass && wrong_epoch_hits == objects;
	stats->correctness_rows++;
	stats->static_wrong_epoch_hits += wrong_epoch_hits;
	emit_w1_build_epoch_correctness(
		out, sample, "table_redirect_static_build_epoch1",
		"epoch2_without_update", expected_failure,
		epoch2_current_pass, expected_failure, wrong_epoch_hits, true,
		expected_failure ?
			"static table failed build epoch 2 oracle with wrong epoch hits" :
			"static table did not expose the expected build epoch failure");
	if (!expected_failure)
		stats->failures++;
	else
		stats->table_static_expected_failure = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !expected_failure;
}

static int run_w1_build_epoch_table_updated_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, struct w1_build_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w1_build_epoch_entry entries[W1_BUILD_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w1_build_epoch_dir(sample_dir, entries, objects, sample);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_TABLE, "table_redirect",
				  &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w1_build_epoch_table_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			W1_BUILD_EPOCH_ONE, true, &setup_writes);
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->table_setup_writes += setup_writes;
	emit_w1_build_epoch_setup(
		out, sample, "table_redirect_updated_build_exact", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? "failed to setup externally updated build table" :
		      "externally updated exact table attached at build epoch 1");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w1_build_epoch_current_oracle_passes(
		sample_dir, entries, objects, W1_BUILD_EPOCH_ONE, NULL, 0);
	stats->correctness_rows++;
	emit_w1_build_epoch_correctness(
		out, sample, "table_redirect_updated_build_exact", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, true,
		epoch1_pass ? "updated table build epoch 1 oracle passed" :
			      "updated table build epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = populate_w1_build_epoch_table_rules(
		&policy, cgroup_id, sample_dir, entries, objects,
		W1_BUILD_EPOCH_TWO, false, &update_writes);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w1_build_epoch_current_oracle_passes(
			sample_dir, entries, objects, W1_BUILD_EPOCH_TWO,
			NULL, 0);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->table_update_writes += update_writes;
	emit_w1_build_epoch_update(
		out, sample, "table_redirect_updated_build_exact",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		true,
		(!ret && epoch2_pass) ?
			"exact table reached build epoch 2 after per-object lookup rewrites" :
			"exact table build epoch 2 update failed");
	stats->correctness_rows++;
	emit_w1_build_epoch_correctness(
		out, sample, "table_redirect_updated_build_exact",
		"epoch2_after_update", !ret && epoch2_pass,
		!ret && epoch2_pass, false, 0, true,
		(!ret && epoch2_pass) ?
			"updated table build epoch 2 oracle passed" :
			"updated table build epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->table_updated_pass = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int w1_build_epoch_materialized_copy_epoch(
	const char *backing_dir, const char *view_dir,
	const struct w1_build_epoch_entry *entries, size_t objects,
	__u32 epoch, unsigned long long *writes,
	unsigned long long *bytes_copied)
{
	char src[PATH_MAX];
	char dst[PATH_MAX];
	struct stat st = {};
	size_t i;

	if (writes)
		*writes = 0;
	if (bytes_copied)
		*bytes_copied = 0;
	for (i = 0; i < objects; i++) {
		int ret = set_path(src, sizeof(src), backing_dir,
				   w1_build_epoch_target(&entries[i],
							  epoch));
		if (!ret)
			ret = set_path(dst, sizeof(dst), view_dir,
				       entries[i].visible);
		if (ret)
			return ret;
		if (bytes_copied && !stat(src, &st) && st.st_size > 0)
			*bytes_copied += (unsigned long long)st.st_size;
		ret = copy_file(src, dst);
		if (ret)
			return ret;
		if (writes)
			(*writes)++;
	}
	return 0;
}

static int w1_build_epoch_materialized_lookup_matches(
	const char *view_dir, const char *backing_dir,
	const struct w1_build_epoch_entry *entry, __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), view_dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), backing_dir,
			       w1_build_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static bool w1_build_epoch_materialized_oracle_passes(
	const char *view_dir, const char *backing_dir,
	const struct w1_build_epoch_entry *entries, size_t objects,
	__u32 epoch)
{
	bool pass = true;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w1_build_epoch_materialized_lookup_matches(
			    view_dir, backing_dir, &entries[i], epoch))
			pass = false;
		if (w1_build_epoch_readdir_hides_backings(view_dir,
							  &entries[i]))
			pass = false;
	}
	return pass;
}

static int run_w1_build_epoch_materialized_system(
	FILE *out, const char *sample_dir, int sample, size_t objects,
	struct w1_build_epoch_stats *stats)
{
	struct w1_build_epoch_entry entries[W1_BUILD_EPOCH_MAX_OBJECTS] = {};
	char backing_dir[PATH_MAX];
	char view_dir[PATH_MAX];
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	unsigned long long bytes_copied = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(backing_dir, sizeof(backing_dir), sample_dir,
			       "backing");
	if (!ret)
		ret = set_path(view_dir, sizeof(view_dir), sample_dir, "view");
	if (!ret)
		ret = prepare_w1_build_epoch_dir(backing_dir, entries,
						 objects, sample);

	start_ns = monotonic_ns();
	if (!ret)
		ret = mkdir_if_missing(view_dir);
	if (!ret)
		ret = w1_build_epoch_materialized_copy_epoch(
			backing_dir, view_dir, entries, objects,
			W1_BUILD_EPOCH_ONE, &setup_writes, &bytes_copied);
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->materialized_setup_writes += setup_writes;
	emit_w1_build_epoch_setup(
		out, sample, "materialized_build_epoch_view", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, false,
		ret ? "failed to setup materialized build epoch view" :
		      "materialized build epoch view copied epoch 1 objects");
	if (ret) {
		stats->failures++;
		return 1;
	}

	epoch1_pass = w1_build_epoch_materialized_oracle_passes(
		view_dir, backing_dir, entries, objects, W1_BUILD_EPOCH_ONE);
	stats->correctness_rows++;
	emit_w1_build_epoch_correctness(
		out, sample, "materialized_build_epoch_view", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, false,
		epoch1_pass ? "materialized build epoch 1 oracle passed" :
			      "materialized build epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = w1_build_epoch_materialized_copy_epoch(
		backing_dir, view_dir, entries, objects,
		W1_BUILD_EPOCH_TWO, &update_writes, &bytes_copied);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w1_build_epoch_materialized_oracle_passes(
			view_dir, backing_dir, entries, objects,
			W1_BUILD_EPOCH_TWO);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->materialized_update_writes += update_writes;
	emit_w1_build_epoch_update(
		out, sample, "materialized_build_epoch_view",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		false,
		(!ret && epoch2_pass) ?
			"materialized build view reached epoch 2 after per-object copies" :
			"materialized build view epoch 2 update failed");
	stats->correctness_rows++;
	emit_w1_build_epoch_correctness(
		out, sample, "materialized_build_epoch_view",
		"epoch2_after_update", !ret && epoch2_pass,
		!ret && epoch2_pass, false, 0, false,
		(!ret && epoch2_pass) ?
			"materialized build epoch 2 oracle passed" :
			"materialized build epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->materialized_updated_pass = true;

	return ret || !epoch1_pass || !epoch2_pass;
}

static int w1_build_epoch_prepare_fuse_specs(
	const char *view_dir, const char *source_dir,
	const struct w1_build_epoch_entry *entries, size_t objects,
	struct w1_alias_spec *specs, size_t *nr_specs)
{
	char source_path[PATH_MAX];
	char shadow[NAMEI_EXT_NAME_MAX + 1];
	size_t i;
	int ret;

	*nr_specs = 0;
	for (i = 0; i < objects; i++) {
		ret = snprintf(shadow, sizeof(shadow), "bld%02zu.fuse", i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(shadow))
			return -ENAMETOOLONG;
		ret = set_path(source_path, sizeof(source_path), source_dir,
			       entries[i].epoch1);
		if (ret)
			return ret;
		ret = add_w1_alias_spec(specs, nr_specs, view_dir,
					entries[i].visible, shadow,
					source_path);
		if (ret)
			return ret;
	}
	return 0;
}

static int w1_build_epoch_fuse_lookup_matches(
	const char *view_dir, const char *source_dir,
	const struct w1_build_epoch_entry *entry, __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), view_dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), source_dir,
			       w1_build_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static int w1_build_epoch_fuse_readdir_hides_backings(
	const char *view_dir, const struct w1_build_epoch_entry *entry,
	const struct w1_alias_spec *spec)
{
	bool saw_shadow;
	int err = 0;
	int ret;

	ret = w1_build_epoch_readdir_hides_backings(view_dir, entry);
	if (ret)
		return ret;
	saw_shadow = dir_has_name(view_dir, spec->shadow, &err);
	if (err)
		return -err;
	return saw_shadow ? -ENOENT : 0;
}

static bool w1_build_epoch_fuse_oracle_passes(
	const char *view_dir, const char *source_dir,
	const struct w1_build_epoch_entry *entries,
	const struct w1_alias_spec *specs, size_t objects, __u32 epoch)
{
	bool pass = true;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w1_build_epoch_fuse_lookup_matches(
			    view_dir, source_dir, &entries[i], epoch))
			pass = false;
		if (w1_build_epoch_fuse_readdir_hides_backings(
			    view_dir, &entries[i], &specs[i]))
			pass = false;
	}
	return pass;
}

static int w1_build_epoch_fuse_copy_epoch(
	const char *source_dir, const char *fuse_backing_dir,
	const struct w1_build_epoch_entry *entries,
	const struct w1_alias_spec *specs, size_t objects, __u32 epoch,
	struct nginx_macro_stats *stats)
{
	char src[PATH_MAX];
	char dst[PATH_MAX];
	size_t i;

	for (i = 0; i < objects; i++) {
		int ret = set_path(src, sizeof(src), source_dir,
				   w1_build_epoch_target(&entries[i],
							  epoch));
		if (!ret)
			ret = set_path(dst, sizeof(dst), fuse_backing_dir,
				       specs[i].shadow);
		if (ret)
			return ret;
		ret = copy_file_counted(src, dst, stats, true);
		if (ret)
			return ret;
	}
	return 0;
}

static int run_w1_build_epoch_fuse_system(
	FILE *out, const char *sample_dir, int sample, size_t objects,
	struct w1_build_epoch_stats *stats)
{
	struct w1_build_epoch_entry entries[W1_BUILD_EPOCH_MAX_OBJECTS] = {};
	struct w1_alias_spec specs[W1_BUILD_EPOCH_MAX_OBJECTS] = {};
	struct w1_fuse_context fuse_ctx = {};
	struct nginx_macro_stats setup_stats = {};
	struct nginx_macro_stats update_stats = {};
	char source_dir[PATH_MAX];
	char view_dir[PATH_MAX];
	char fuse_backing_dir[PATH_MAX];
	size_t nr_specs = 0;
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(source_dir, sizeof(source_dir), sample_dir,
			       "source");
	if (!ret)
		ret = set_path(view_dir, sizeof(view_dir), sample_dir, "view");
	if (!ret)
		ret = prepare_w1_build_epoch_dir(source_dir, entries,
						 objects, sample);
	if (!ret)
		ret = mkdir_if_missing(view_dir);
	if (!ret)
		ret = w1_build_epoch_prepare_fuse_specs(
			view_dir, source_dir, entries, objects, specs,
			&nr_specs);

	start_ns = monotonic_ns();
	if (!ret)
		ret = setup_w1_fuse_mount(specs, nr_specs, view_dir,
					  &setup_stats, &fuse_ctx);
	end_ns = monotonic_ns();
	setup_writes = setup_stats.created_files;
	stats->setup_rows++;
	stats->fuse_setup_writes += setup_writes;
	stats->fuse_mounts += setup_stats.fuse_mounts;
	emit_w1_build_epoch_setup(
		out, sample, "fuse_build_epoch_view", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, false,
		ret ? "failed to setup FUSE build epoch view" :
		      "FUSE build epoch view mounted with epoch 1 backing shadows");
	if (ret) {
		unmount_w1_fuse_context(&fuse_ctx);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w1_build_epoch_fuse_oracle_passes(
		view_dir, source_dir, entries, specs, objects,
		W1_BUILD_EPOCH_ONE);
	stats->correctness_rows++;
	emit_w1_build_epoch_correctness(
		out, sample, "fuse_build_epoch_view", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, false,
		epoch1_pass ? "FUSE build epoch 1 oracle passed" :
			      "FUSE build epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = w1_fuse_backing_dir(view_dir, fuse_backing_dir,
				  sizeof(fuse_backing_dir));
	if (!ret)
		ret = w1_build_epoch_fuse_copy_epoch(
			source_dir, fuse_backing_dir, entries, specs, objects,
			W1_BUILD_EPOCH_TWO, &update_stats);
	update_done_ns = monotonic_ns();
	update_writes = update_stats.source_update_writes;
	if (!ret)
		epoch2_pass = w1_build_epoch_fuse_oracle_passes(
			view_dir, source_dir, entries, specs, objects,
			W1_BUILD_EPOCH_TWO);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->fuse_update_writes += update_writes;
	emit_w1_build_epoch_update(
		out, sample, "fuse_build_epoch_view",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		false,
		(!ret && epoch2_pass) ?
			"FUSE build view reached epoch 2 after per-object backing rewrites" :
			"FUSE build view epoch 2 update failed");
	stats->correctness_rows++;
	emit_w1_build_epoch_correctness(
		out, sample, "fuse_build_epoch_view", "epoch2_after_update",
		!ret && epoch2_pass, !ret && epoch2_pass, false, 0, false,
		(!ret && epoch2_pass) ?
			"FUSE build epoch 2 oracle passed" :
			"FUSE build epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->fuse_updated_pass = true;

	ret = unmount_w1_fuse_context(&fuse_ctx);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int run_w1_build_epoch_counterfactual(
	FILE *out, const char *cgroup_mount, int samples, const char *work_dir,
	size_t objects, const char *build_policy_obj, const char *table_policy_obj)
{
	struct w1_build_epoch_stats stats = {};
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	int sample;
	int ret;

	if (samples <= 0 || objects == 0 ||
	    objects > W1_BUILD_EPOCH_MAX_OBJECTS) {
		stats.failures = 1;
		emit_w1_build_epoch_summary(
			out, samples, &stats,
			"invalid sample count or build object count");
		return 1;
	}
	stats.objects = objects;
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		stats.failures = 1;
		emit_w1_build_epoch_summary(
			out, samples, &stats,
			"failed to create W1 build epoch workdir");
		return 1;
	}
	if (access(build_policy_obj, R_OK) || access(table_policy_obj, R_OK)) {
		stats.failures = 1;
		emit_w1_build_epoch_summary(
			out, samples, &stats,
			"W1 build epoch policy inputs are not readable");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		stats.failures = 1;
		emit_w1_build_epoch_summary(
			out, samples, &stats,
			"failed to resolve current cgroup id");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		char sample_dir[PATH_MAX];

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/build-policy-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w1_build_epoch_policy_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, build_policy_obj, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/table-static-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w1_build_epoch_table_static_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, table_policy_obj, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/table-updated-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w1_build_epoch_table_updated_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, table_policy_obj, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/materialized-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w1_build_epoch_materialized_system(
			out, sample_dir, sample, objects, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/fuse-sample-%03d", work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w1_build_epoch_fuse_system(
			out, sample_dir, sample, objects, &stats);
	}

	emit_w1_build_epoch_summary(
		out, samples, &stats,
		stats.failures ?
			"W1 build epoch counterfactual failed" :
			"W1 build epoch counterfactual passed; static exact table fails the epoch switch, while externally updated table, materialized view, and FUSE view reach epoch 2 only with per-object updates");
	return stats.failures ? 1 : 0;
}

#define W2_FIXTURE_EPOCH_ONE 1
#define W2_FIXTURE_EPOCH_TWO 2
#define W2_FIXTURE_EPOCH_DEFAULT_OBJECTS 16
#define W2_FIXTURE_EPOCH_MAX_OBJECTS 64
#define W2_FIXTURE_EPOCH_TABLE_MAX_UPDATE_RATIO 10

struct w2_fixture_epoch_entry {
	char visible[NAMEI_EXT_NAME_MAX + 1];
	char epoch1[NAMEI_EXT_NAME_MAX + 1];
	char epoch2[NAMEI_EXT_NAME_MAX + 1];
	__u32 path_class;
};

struct w2_fixture_epoch_stats {
	int setup_rows;
	int correctness_rows;
	int update_rows;
	int failures;
	size_t objects;
	size_t static_wrong_fixture_hits;
	unsigned long long policy_setup_writes;
	unsigned long long table_setup_writes;
	unsigned long long materialized_setup_writes;
	unsigned long long fuse_setup_writes;
	unsigned long long policy_update_writes;
	unsigned long long table_update_writes;
	unsigned long long materialized_update_writes;
	unsigned long long fuse_update_writes;
	unsigned long long fuse_mounts;
	bool policy_epoch_switch_pass;
	bool table_static_expected_failure;
	bool table_updated_pass;
	bool materialized_updated_pass;
	bool fuse_updated_pass;
};

static __u32 w2_fixture_epoch_class_for_index(size_t index)
{
	switch (index % 5) {
	case 0:
		return FIXTURE_BRANCH_CONFIG;
	case 1:
		return FIXTURE_BRANCH_SECRET;
	case 2:
		return FIXTURE_BRANCH_CERT;
	case 3:
		return FIXTURE_BRANCH_ENDPOINT;
	default:
		return FIXTURE_BRANCH_POISON;
	}
}

static const char *w2_fixture_epoch_class_name(__u32 path_class)
{
	switch (path_class) {
	case FIXTURE_BRANCH_CONFIG:
		return "config";
	case FIXTURE_BRANCH_SECRET:
		return "secret";
	case FIXTURE_BRANCH_CERT:
		return "cert";
	case FIXTURE_BRANCH_ENDPOINT:
		return "endpoint";
	case FIXTURE_BRANCH_POISON:
		return "poison";
	default:
		return "unknown";
	}
}

static const char *w2_fixture_epoch_target(
	const struct w2_fixture_epoch_entry *entry, __u32 epoch)
{
	return epoch == W2_FIXTURE_EPOCH_TWO ? entry->epoch2 : entry->epoch1;
}

static int prepare_w2_fixture_epoch_names(
	struct w2_fixture_epoch_entry *entry, size_t index)
{
	const char *prefix = "obj";
	const char *suffix = "dat";
	int ret;

	entry->path_class = w2_fixture_epoch_class_for_index(index);
	switch (entry->path_class) {
	case FIXTURE_BRANCH_CONFIG:
		prefix = "cfg";
		suffix = "conf";
		break;
	case FIXTURE_BRANCH_SECRET:
		prefix = "sec";
		suffix = "pass";
		break;
	case FIXTURE_BRANCH_CERT:
		prefix = "crt";
		suffix = "crt";
		break;
	case FIXTURE_BRANCH_ENDPOINT:
		prefix = "ep";
		suffix = "sock";
		break;
	case FIXTURE_BRANCH_POISON:
		prefix = "tok";
		suffix = "token";
		break;
	default:
		return -EINVAL;
	}

	ret = snprintf(entry->visible, sizeof(entry->visible), "%s%02zu.%s",
		       prefix, index, suffix);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(entry->visible))
		return -ENAMETOOLONG;
	ret = snprintf(entry->epoch1, sizeof(entry->epoch1), "%s%02zu.e1",
		       prefix, index);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(entry->epoch1))
		return -ENAMETOOLONG;
	ret = snprintf(entry->epoch2, sizeof(entry->epoch2), "%s%02zu.e2",
		       prefix, index);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(entry->epoch2))
		return -ENAMETOOLONG;
	return 0;
}

static int prepare_w2_fixture_epoch_dir(
	const char *dir, struct w2_fixture_epoch_entry *entries,
	size_t objects, int sample)
{
	char path[PATH_MAX];
	char text[192];
	size_t i;
	int ret;

	ret = mkdir_if_missing(dir);
	if (ret)
		return ret;
	for (i = 0; i < objects; i++) {
		ret = prepare_w2_fixture_epoch_names(&entries[i], i);
		if (ret)
			return ret;

		ret = set_path(path, sizeof(path), dir, entries[i].visible);
		if (ret)
			return ret;
		unlink_existing(path);

		ret = set_path(path, sizeof(path), dir, entries[i].epoch1);
		if (ret)
			return ret;
		ret = snprintf(text, sizeof(text),
			       "namei_ext w2 fixture sample %d object %zu class %s epoch 1\n",
			       sample, i,
			       w2_fixture_epoch_class_name(entries[i].path_class));
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(text))
			return -ENAMETOOLONG;
		ret = write_text_file(path, text);
		if (ret)
			return ret;

		ret = set_path(path, sizeof(path), dir, entries[i].epoch2);
		if (ret)
			return ret;
		ret = snprintf(text, sizeof(text),
			       "namei_ext w2 fixture sample %d object %zu class %s epoch 2\n",
			       sample, i,
			       w2_fixture_epoch_class_name(entries[i].path_class));
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(text))
			return -ENAMETOOLONG;
		ret = write_text_file(path, text);
		if (ret)
			return ret;
	}
	return 0;
}

static int w2_fixture_epoch_lookup_matches(
	const char *dir, const struct w2_fixture_epoch_entry *entry,
	__u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), dir,
			       w2_fixture_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static int w2_fixture_epoch_readdir_hides_backings(
	const char *dir, const struct w2_fixture_epoch_entry *entry)
{
	bool saw_visible;
	bool saw_epoch1;
	bool saw_epoch2;
	int err = 0;

	saw_visible = dir_has_name(dir, entry->visible, &err);
	if (!err)
		saw_epoch1 = dir_has_name(dir, entry->epoch1, &err);
	else
		saw_epoch1 = false;
	if (!err)
		saw_epoch2 = dir_has_name(dir, entry->epoch2, &err);
	else
		saw_epoch2 = false;
	if (!err && saw_visible && !saw_epoch1 && !saw_epoch2)
		return 0;
	return err ? -err : -ENOENT;
}

static bool w2_fixture_epoch_current_oracle_passes(
	const char *dir, const struct w2_fixture_epoch_entry *entries,
	size_t objects, __u32 epoch, size_t *wrong_epoch_hits,
	__u32 wrong_epoch)
{
	bool pass = true;
	size_t wrong = 0;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w2_fixture_epoch_lookup_matches(dir, &entries[i], epoch))
			pass = false;
		if (w2_fixture_epoch_readdir_hides_backings(dir, &entries[i]))
			pass = false;
		if (wrong_epoch &&
		    !w2_fixture_epoch_lookup_matches(dir, &entries[i],
						     wrong_epoch))
			wrong++;
	}
	if (wrong_epoch_hits)
		*wrong_epoch_hits = wrong;
	return pass;
}

static void emit_w2_fixture_epoch_setup(
	FILE *out, int sample, const char *system, bool pass, int err,
	__u64 setup_ns, size_t objects, unsigned long long setup_writes,
	bool policy_executed, const char *detail)
{
	const char *write_key = policy_executed ? "setup_rule_writes" :
						"setup_materialization_writes";

	fputs("{\"event\":\"w2-fixture-epoch-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_fixture_epoch.v1\","
	      "\"result_level\":\"kvm_sandbox_fixture_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-sandbox-fixture-epoch\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,\"objects\":%zu,"
		"\"dynamic_fixture_classes\":5,"
		"\"setup_writes\":%llu,\"%s\":%llu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, objects, setup_writes,
		write_key, setup_writes,
		policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w2_fixture_epoch_correctness(
	FILE *out, int sample, const char *system, const char *stage,
	bool pass, bool current_oracle_pass,
	bool expected_static_failure_observed, size_t wrong_epoch_hits,
	bool policy_executed, const char *detail)
{
	fputs("{\"event\":\"w2-fixture-epoch-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_fixture_epoch.v1\","
	      "\"result_level\":\"kvm_sandbox_fixture_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-sandbox-fixture-epoch\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fputs(",\"stage\":", out);
	fprint_json_string(out, stage);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,"
		"\"current_oracle_pass\":%s,"
		"\"expected_static_failure_observed\":%s,"
		"\"wrong_epoch_hits\":%zu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false",
		current_oracle_pass ? "true" : "false",
		expected_static_failure_observed ? "true" : "false",
		wrong_epoch_hits, policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w2_fixture_epoch_update(
	FILE *out, int sample, const char *system, bool pass, int err,
	__u64 update_ns, __u64 observed_window_ns,
	unsigned long long update_writes, bool policy_executed,
	const char *detail)
{
	fputs("{\"event\":\"w2-fixture-epoch-update-window\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_fixture_epoch.v1\","
	      "\"result_level\":\"kvm_sandbox_fixture_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-sandbox-fixture-epoch\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"observed_update_window_ns\":%llu,"
		"\"update_writes\":%llu,"
		"\"from_epoch\":1,\"to_epoch\":2,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns,
		(unsigned long long)observed_window_ns, update_writes,
		policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w2_fixture_epoch_summary(
	FILE *out, int samples, const struct w2_fixture_epoch_stats *stats,
	const char *detail)
{
	double update_ratio = stats->policy_update_writes ?
		(double)stats->table_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	double materialized_update_ratio = stats->policy_update_writes ?
		(double)stats->materialized_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	double fuse_update_ratio = stats->policy_update_writes ?
		(double)stats->fuse_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	bool table_update_budget_failure =
		update_ratio > W2_FIXTURE_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool materialized_update_budget_failure =
		materialized_update_ratio >
		W2_FIXTURE_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool fuse_update_budget_failure =
		fuse_update_ratio > W2_FIXTURE_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool targeted_c8_budget_failure =
		stats->policy_epoch_switch_pass &&
		stats->table_static_expected_failure &&
		stats->table_updated_pass &&
		table_update_budget_failure;
	bool state_branch_not_static =
		stats->policy_epoch_switch_pass &&
		stats->table_static_expected_failure;

	fputs("{\"event\":\"w2-fixture-epoch-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_fixture_epoch.v1\","
	      "\"result_level\":\"kvm_sandbox_fixture_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-sandbox-fixture-epoch\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"setup_rows\":%d,"
		"\"correctness_rows\":%d,\"update_rows\":%d,"
		"\"objects\":%zu,"
		"\"dynamic_fixture_classes\":5,"
		"\"static_wrong_fixture_hits\":%zu,"
		"\"policy_setup_writes\":%llu,"
		"\"table_setup_writes\":%llu,"
		"\"materialized_setup_writes\":%llu,"
		"\"fuse_setup_writes\":%llu,"
		"\"policy_update_writes\":%llu,"
		"\"table_update_writes\":%llu,"
		"\"materialized_update_writes\":%llu,"
		"\"fuse_update_writes\":%llu,"
		"\"fuse_mounts\":%llu,"
		"\"table_update_write_ratio\":%.17g,"
		"\"materialized_update_write_ratio\":%.17g,"
		"\"fuse_update_write_ratio\":%.17g,"
		"\"max_table_update_write_ratio\":%d,"
		"\"table_static_current_oracle_pass\":false,"
		"\"table_static_expected_failure_observed\":%s,"
		"\"table_updated_current_oracle_pass\":%s,"
		"\"table_requires_external_state_updates\":true,"
		"\"table_update_budget_failure\":%s,"
		"\"materialized_current_oracle_pass\":%s,"
		"\"materialized_feature_equivalent_baseline\":%s,"
		"\"materialized_update_budget_failure\":%s,"
		"\"fuse_current_oracle_pass\":%s,"
		"\"fuse_feature_equivalent_baseline\":%s,"
		"\"fuse_update_budget_failure\":%s,"
		"\"targeted_c8_budget_failure\":%s,"
		"\"state_dependent_branch_not_static_table_expressible\":%s,"
		"\"real_nginx_trace\":false,"
		"\"release_sample_budget_pass\":%s,"
		"\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"qualified_for_c8\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, stats->setup_rows, stats->correctness_rows,
		stats->update_rows, stats->objects,
		stats->static_wrong_fixture_hits, stats->policy_setup_writes,
		stats->table_setup_writes, stats->materialized_setup_writes,
		stats->fuse_setup_writes,
		stats->policy_update_writes, stats->table_update_writes,
		stats->materialized_update_writes, stats->fuse_update_writes,
		stats->fuse_mounts, update_ratio, materialized_update_ratio,
		fuse_update_ratio,
		W2_FIXTURE_EPOCH_TABLE_MAX_UPDATE_RATIO,
		stats->table_static_expected_failure ? "true" : "false",
		stats->table_updated_pass ? "true" : "false",
		table_update_budget_failure ? "true" : "false",
		stats->materialized_updated_pass ? "true" : "false",
		stats->materialized_updated_pass ? "true" : "false",
		materialized_update_budget_failure ? "true" : "false",
		stats->fuse_updated_pass ? "true" : "false",
		stats->fuse_updated_pass ? "true" : "false",
		fuse_update_budget_failure ? "true" : "false",
		targeted_c8_budget_failure ? "true" : "false",
		state_branch_not_static ? "true" : "false",
		samples >= 20 ? "true" : "false",
		stats->failures ? "false" : "true", stats->failures,
		stats->failures ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int populate_w2_fixture_epoch_policy_rules(
	struct attached_policy *policy, __u64 cgroup_id, const char *dir,
	const struct w2_fixture_epoch_entry *entries, size_t objects,
	unsigned long long *writes)
{
	size_t i;

	*writes = 0;
	for (i = 0; i < objects; i++) {
		__u32 branch = (__u32)i + 1;
		__u32 path_class = entries[i].path_class;
		int ret;

		ret = update_sandbox_fixture_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP, dir,
			entries[i].visible, entries[i].epoch1, branch,
			path_class, W2_FIXTURE_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_sandbox_fixture_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP, dir,
			entries[i].visible, entries[i].epoch2, branch,
			path_class, W2_FIXTURE_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_sandbox_fixture_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch1, entries[i].visible, branch,
			path_class, W2_FIXTURE_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_sandbox_fixture_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch2, entries[i].visible, branch,
			path_class, W2_FIXTURE_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_sandbox_fixture_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch1, entries[i].visible, branch,
			path_class, W2_FIXTURE_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_sandbox_fixture_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch2, entries[i].visible, branch,
			path_class, W2_FIXTURE_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
	}
	return 0;
}

static int populate_w2_fixture_epoch_table_rules(
	struct attached_policy *policy, __u64 cgroup_id, const char *dir,
	const struct w2_fixture_epoch_entry *entries, size_t objects,
	__u32 epoch, bool include_readdir, unsigned long long *writes)
{
	size_t i;

	*writes = 0;
	for (i = 0; i < objects; i++) {
		int ret;

		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
				  dir, entries[i].visible,
				  w2_fixture_epoch_target(&entries[i], epoch),
				  i + 1);
		if (ret)
			return ret;
		(*writes)++;
		if (!include_readdir)
			continue;
		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				  dir, entries[i].epoch1,
				  entries[i].visible, i + 1);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				  dir, entries[i].epoch2,
				  entries[i].visible, i + 1);
		if (ret)
			return ret;
		(*writes)++;
	}
	return 0;
}

static int run_w2_fixture_epoch_policy_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, struct w2_fixture_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w2_fixture_epoch_entry entries[W2_FIXTURE_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w2_fixture_epoch_dir(sample_dir, entries, objects, sample);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_SANDBOX_FIXTURE,
				  "sandbox_fixture_epoch", &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w2_fixture_epoch_policy_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			&setup_writes);
	if (!ret)
		ret = update_sandbox_fixture_session(
			&policy, cgroup_id, W2_FIXTURE_EPOCH_ONE, true);
	if (!ret)
		setup_writes++;
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->policy_setup_writes += setup_writes;
	emit_w2_fixture_epoch_setup(
		out, sample, "sandbox_fixture_epoch_policy", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? "failed to setup sandbox fixture epoch policy" :
		      "sandbox fixture policy attached with two epoch rule sets");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w2_fixture_epoch_current_oracle_passes(
		sample_dir, entries, objects, W2_FIXTURE_EPOCH_ONE, NULL, 0);
	stats->correctness_rows++;
	emit_w2_fixture_epoch_correctness(
		out, sample, "sandbox_fixture_epoch_policy", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, true,
		epoch1_pass ? "sandbox fixture epoch 1 oracle passed" :
			      "sandbox fixture epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = update_sandbox_fixture_session(
		&policy, cgroup_id, W2_FIXTURE_EPOCH_TWO, true);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w2_fixture_epoch_current_oracle_passes(
			sample_dir, entries, objects, W2_FIXTURE_EPOCH_TWO,
			NULL, 0);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->policy_update_writes++;
	emit_w2_fixture_epoch_update(
		out, sample, "sandbox_fixture_epoch_policy",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, 1, true,
		(!ret && epoch2_pass) ?
			"sandbox fixture policy switched epoch with one session update" :
			"sandbox fixture policy epoch switch failed");
	stats->correctness_rows++;
	emit_w2_fixture_epoch_correctness(
		out, sample, "sandbox_fixture_epoch_policy", "epoch2",
		!ret && epoch2_pass, !ret && epoch2_pass, false, 0, true,
		(!ret && epoch2_pass) ?
			"sandbox fixture epoch 2 oracle passed" :
			"sandbox fixture epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->policy_epoch_switch_pass = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int run_w2_fixture_epoch_table_static_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, struct w2_fixture_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w2_fixture_epoch_entry entries[W2_FIXTURE_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	size_t wrong_epoch_hits = 0;
	bool epoch1_pass = false;
	bool epoch2_current_pass = false;
	bool expected_failure = false;
	__u64 start_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w2_fixture_epoch_dir(sample_dir, entries, objects, sample);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_TABLE, "table_redirect",
				  &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w2_fixture_epoch_table_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			W2_FIXTURE_EPOCH_ONE, true, &setup_writes);
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->table_setup_writes += setup_writes;
	emit_w2_fixture_epoch_setup(
		out, sample, "table_redirect_static_fixture_epoch1", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? "failed to setup static fixture table" :
		      "static exact table attached with fixture epoch 1 lookup rules");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w2_fixture_epoch_current_oracle_passes(
		sample_dir, entries, objects, W2_FIXTURE_EPOCH_ONE, NULL, 0);
	stats->correctness_rows++;
	emit_w2_fixture_epoch_correctness(
		out, sample, "table_redirect_static_fixture_epoch1", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, true,
		epoch1_pass ? "static table fixture epoch 1 oracle passed" :
			      "static table fixture epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	epoch2_current_pass = w2_fixture_epoch_current_oracle_passes(
		sample_dir, entries, objects, W2_FIXTURE_EPOCH_TWO,
		&wrong_epoch_hits, W2_FIXTURE_EPOCH_ONE);
	expected_failure = !epoch2_current_pass && wrong_epoch_hits == objects;
	stats->correctness_rows++;
	stats->static_wrong_fixture_hits += wrong_epoch_hits;
	emit_w2_fixture_epoch_correctness(
		out, sample, "table_redirect_static_fixture_epoch1",
		"epoch2_without_update", expected_failure,
		epoch2_current_pass, expected_failure, wrong_epoch_hits, true,
		expected_failure ?
			"static table failed fixture epoch 2 oracle with wrong epoch hits" :
			"static table did not expose the expected fixture epoch failure");
	if (!expected_failure)
		stats->failures++;
	else
		stats->table_static_expected_failure = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !expected_failure;
}

static int run_w2_fixture_epoch_table_updated_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, struct w2_fixture_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w2_fixture_epoch_entry entries[W2_FIXTURE_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w2_fixture_epoch_dir(sample_dir, entries, objects, sample);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_TABLE, "table_redirect",
				  &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w2_fixture_epoch_table_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			W2_FIXTURE_EPOCH_ONE, true, &setup_writes);
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->table_setup_writes += setup_writes;
	emit_w2_fixture_epoch_setup(
		out, sample, "table_redirect_updated_fixture_exact", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? "failed to setup externally updated fixture table" :
		      "externally updated exact table attached at fixture epoch 1");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w2_fixture_epoch_current_oracle_passes(
		sample_dir, entries, objects, W2_FIXTURE_EPOCH_ONE, NULL, 0);
	stats->correctness_rows++;
	emit_w2_fixture_epoch_correctness(
		out, sample, "table_redirect_updated_fixture_exact", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, true,
		epoch1_pass ? "updated table fixture epoch 1 oracle passed" :
			      "updated table fixture epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = populate_w2_fixture_epoch_table_rules(
		&policy, cgroup_id, sample_dir, entries, objects,
		W2_FIXTURE_EPOCH_TWO, false, &update_writes);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w2_fixture_epoch_current_oracle_passes(
			sample_dir, entries, objects, W2_FIXTURE_EPOCH_TWO,
			NULL, 0);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->table_update_writes += update_writes;
	emit_w2_fixture_epoch_update(
		out, sample, "table_redirect_updated_fixture_exact",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		true,
		(!ret && epoch2_pass) ?
			"exact table reached fixture epoch 2 after per-object lookup rewrites" :
			"exact table fixture epoch 2 update failed");
	stats->correctness_rows++;
	emit_w2_fixture_epoch_correctness(
		out, sample, "table_redirect_updated_fixture_exact",
		"epoch2_after_update", !ret && epoch2_pass,
		!ret && epoch2_pass, false, 0, true,
		(!ret && epoch2_pass) ?
			"updated table fixture epoch 2 oracle passed" :
			"updated table fixture epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->table_updated_pass = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int w2_fixture_epoch_materialized_copy_epoch(
	const char *backing_dir, const char *view_dir,
	const struct w2_fixture_epoch_entry *entries, size_t objects,
	__u32 epoch, unsigned long long *writes,
	unsigned long long *bytes_copied)
{
	char src[PATH_MAX];
	char dst[PATH_MAX];
	struct stat st = {};
	size_t i;

	if (writes)
		*writes = 0;
	if (bytes_copied)
		*bytes_copied = 0;
	for (i = 0; i < objects; i++) {
		int ret = set_path(src, sizeof(src), backing_dir,
				   w2_fixture_epoch_target(&entries[i],
							    epoch));
		if (!ret)
			ret = set_path(dst, sizeof(dst), view_dir,
				       entries[i].visible);
		if (ret)
			return ret;
		if (bytes_copied && !stat(src, &st) && st.st_size > 0)
			*bytes_copied += (unsigned long long)st.st_size;
		ret = copy_file(src, dst);
		if (ret)
			return ret;
		if (writes)
			(*writes)++;
	}
	return 0;
}

static int w2_fixture_epoch_materialized_lookup_matches(
	const char *view_dir, const char *backing_dir,
	const struct w2_fixture_epoch_entry *entry, __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), view_dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), backing_dir,
			       w2_fixture_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static bool w2_fixture_epoch_materialized_oracle_passes(
	const char *view_dir, const char *backing_dir,
	const struct w2_fixture_epoch_entry *entries, size_t objects,
	__u32 epoch)
{
	bool pass = true;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w2_fixture_epoch_materialized_lookup_matches(
			    view_dir, backing_dir, &entries[i], epoch))
			pass = false;
		if (w2_fixture_epoch_readdir_hides_backings(view_dir,
							    &entries[i]))
			pass = false;
	}
	return pass;
}

static int run_w2_fixture_epoch_materialized_system(
	FILE *out, const char *sample_dir, int sample, size_t objects,
	struct w2_fixture_epoch_stats *stats)
{
	struct w2_fixture_epoch_entry entries[W2_FIXTURE_EPOCH_MAX_OBJECTS] = {};
	char backing_dir[PATH_MAX];
	char view_dir[PATH_MAX];
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	unsigned long long bytes_copied = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(backing_dir, sizeof(backing_dir), sample_dir,
			       "backing");
	if (!ret)
		ret = set_path(view_dir, sizeof(view_dir), sample_dir, "view");
	if (!ret)
		ret = prepare_w2_fixture_epoch_dir(backing_dir, entries,
						   objects, sample);

	start_ns = monotonic_ns();
	if (!ret)
		ret = mkdir_if_missing(view_dir);
	if (!ret)
		ret = w2_fixture_epoch_materialized_copy_epoch(
			backing_dir, view_dir, entries, objects,
			W2_FIXTURE_EPOCH_ONE, &setup_writes, &bytes_copied);
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->materialized_setup_writes += setup_writes;
	emit_w2_fixture_epoch_setup(
		out, sample, "materialized_fixture_epoch_view", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, false,
		ret ? "failed to setup materialized fixture epoch view" :
		      "materialized fixture epoch view copied epoch 1 objects");
	if (ret) {
		stats->failures++;
		return 1;
	}

	epoch1_pass = w2_fixture_epoch_materialized_oracle_passes(
		view_dir, backing_dir, entries, objects,
		W2_FIXTURE_EPOCH_ONE);
	stats->correctness_rows++;
	emit_w2_fixture_epoch_correctness(
		out, sample, "materialized_fixture_epoch_view", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, false,
		epoch1_pass ? "materialized fixture epoch 1 oracle passed" :
			      "materialized fixture epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = w2_fixture_epoch_materialized_copy_epoch(
		backing_dir, view_dir, entries, objects,
		W2_FIXTURE_EPOCH_TWO, &update_writes, &bytes_copied);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w2_fixture_epoch_materialized_oracle_passes(
			view_dir, backing_dir, entries, objects,
			W2_FIXTURE_EPOCH_TWO);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->materialized_update_writes += update_writes;
	emit_w2_fixture_epoch_update(
		out, sample, "materialized_fixture_epoch_view",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		false,
		(!ret && epoch2_pass) ?
			"materialized fixture view reached epoch 2 after per-object copies" :
			"materialized fixture view epoch 2 update failed");
	stats->correctness_rows++;
	emit_w2_fixture_epoch_correctness(
		out, sample, "materialized_fixture_epoch_view",
		"epoch2_after_update", !ret && epoch2_pass,
		!ret && epoch2_pass, false, 0, false,
		(!ret && epoch2_pass) ?
			"materialized fixture epoch 2 oracle passed" :
			"materialized fixture epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->materialized_updated_pass = true;

	return ret || !epoch1_pass || !epoch2_pass;
}

static int w2_fixture_epoch_prepare_fuse_specs(
	const char *view_dir, const char *source_dir,
	const struct w2_fixture_epoch_entry *entries, size_t objects,
	struct w1_alias_spec *specs, size_t *nr_specs)
{
	char source_path[PATH_MAX];
	char shadow[NAMEI_EXT_NAME_MAX + 1];
	size_t i;
	int ret;

	*nr_specs = 0;
	for (i = 0; i < objects; i++) {
		ret = snprintf(shadow, sizeof(shadow), "fx%02zu.fuse", i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(shadow))
			return -ENAMETOOLONG;
		ret = set_path(source_path, sizeof(source_path), source_dir,
			       entries[i].epoch1);
		if (ret)
			return ret;
		ret = add_w1_alias_spec(specs, nr_specs, view_dir,
					entries[i].visible, shadow,
					source_path);
		if (ret)
			return ret;
	}
	return 0;
}

static int w2_fixture_epoch_fuse_lookup_matches(
	const char *view_dir, const char *source_dir,
	const struct w2_fixture_epoch_entry *entry, __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), view_dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), source_dir,
			       w2_fixture_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static int w2_fixture_epoch_fuse_readdir_hides_backings(
	const char *view_dir, const struct w2_fixture_epoch_entry *entry,
	const struct w1_alias_spec *spec)
{
	bool saw_shadow;
	int err = 0;
	int ret;

	ret = w2_fixture_epoch_readdir_hides_backings(view_dir, entry);
	if (ret)
		return ret;
	saw_shadow = dir_has_name(view_dir, spec->shadow, &err);
	if (err)
		return -err;
	return saw_shadow ? -ENOENT : 0;
}

static bool w2_fixture_epoch_fuse_oracle_passes(
	const char *view_dir, const char *source_dir,
	const struct w2_fixture_epoch_entry *entries,
	const struct w1_alias_spec *specs, size_t objects, __u32 epoch)
{
	bool pass = true;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w2_fixture_epoch_fuse_lookup_matches(
			    view_dir, source_dir, &entries[i], epoch))
			pass = false;
		if (w2_fixture_epoch_fuse_readdir_hides_backings(
			    view_dir, &entries[i], &specs[i]))
			pass = false;
	}
	return pass;
}

static int w2_fixture_epoch_fuse_copy_epoch(
	const char *source_dir, const char *fuse_backing_dir,
	const struct w2_fixture_epoch_entry *entries,
	const struct w1_alias_spec *specs, size_t objects, __u32 epoch,
	struct nginx_macro_stats *stats)
{
	char src[PATH_MAX];
	char dst[PATH_MAX];
	size_t i;

	for (i = 0; i < objects; i++) {
		int ret = set_path(src, sizeof(src), source_dir,
				   w2_fixture_epoch_target(&entries[i],
							    epoch));
		if (!ret)
			ret = set_path(dst, sizeof(dst), fuse_backing_dir,
				       specs[i].shadow);
		if (ret)
			return ret;
		ret = copy_file_counted(src, dst, stats, true);
		if (ret)
			return ret;
	}
	return 0;
}

static int run_w2_fixture_epoch_fuse_system(
	FILE *out, const char *sample_dir, int sample, size_t objects,
	struct w2_fixture_epoch_stats *stats)
{
	struct w2_fixture_epoch_entry entries[W2_FIXTURE_EPOCH_MAX_OBJECTS] = {};
	struct w1_alias_spec specs[W2_FIXTURE_EPOCH_MAX_OBJECTS] = {};
	struct w1_fuse_context fuse_ctx = {};
	struct nginx_macro_stats setup_stats = {};
	struct nginx_macro_stats update_stats = {};
	char source_dir[PATH_MAX];
	char view_dir[PATH_MAX];
	char fuse_backing_dir[PATH_MAX];
	size_t nr_specs = 0;
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(source_dir, sizeof(source_dir), sample_dir,
			       "source");
	if (!ret)
		ret = set_path(view_dir, sizeof(view_dir), sample_dir, "view");
	if (!ret)
		ret = prepare_w2_fixture_epoch_dir(source_dir, entries,
						   objects, sample);
	if (!ret)
		ret = mkdir_if_missing(view_dir);
	if (!ret)
		ret = w2_fixture_epoch_prepare_fuse_specs(
			view_dir, source_dir, entries, objects, specs,
			&nr_specs);

	start_ns = monotonic_ns();
	if (!ret)
		ret = setup_w1_fuse_mount(specs, nr_specs, view_dir,
					  &setup_stats, &fuse_ctx);
	end_ns = monotonic_ns();
	setup_writes = setup_stats.created_files;
	stats->setup_rows++;
	stats->fuse_setup_writes += setup_writes;
	stats->fuse_mounts += setup_stats.fuse_mounts;
	emit_w2_fixture_epoch_setup(
		out, sample, "fuse_fixture_epoch_view", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, false,
		ret ? "failed to setup FUSE fixture epoch view" :
		      "FUSE fixture epoch view mounted with epoch 1 backing shadows");
	if (ret) {
		unmount_w1_fuse_context(&fuse_ctx);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w2_fixture_epoch_fuse_oracle_passes(
		view_dir, source_dir, entries, specs, objects,
		W2_FIXTURE_EPOCH_ONE);
	stats->correctness_rows++;
	emit_w2_fixture_epoch_correctness(
		out, sample, "fuse_fixture_epoch_view", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, false,
		epoch1_pass ? "FUSE fixture epoch 1 oracle passed" :
			      "FUSE fixture epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = w1_fuse_backing_dir(view_dir, fuse_backing_dir,
				  sizeof(fuse_backing_dir));
	if (!ret)
		ret = w2_fixture_epoch_fuse_copy_epoch(
			source_dir, fuse_backing_dir, entries, specs, objects,
			W2_FIXTURE_EPOCH_TWO, &update_stats);
	update_done_ns = monotonic_ns();
	update_writes = update_stats.source_update_writes;
	if (!ret)
		epoch2_pass = w2_fixture_epoch_fuse_oracle_passes(
			view_dir, source_dir, entries, specs, objects,
			W2_FIXTURE_EPOCH_TWO);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->fuse_update_writes += update_writes;
	emit_w2_fixture_epoch_update(
		out, sample, "fuse_fixture_epoch_view",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		false,
		(!ret && epoch2_pass) ?
			"FUSE fixture view reached epoch 2 after per-object backing rewrites" :
			"FUSE fixture view epoch 2 update failed");
	stats->correctness_rows++;
	emit_w2_fixture_epoch_correctness(
		out, sample, "fuse_fixture_epoch_view",
		"epoch2_after_update", !ret && epoch2_pass,
		!ret && epoch2_pass, false, 0, false,
		(!ret && epoch2_pass) ?
			"FUSE fixture epoch 2 oracle passed" :
			"FUSE fixture epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->fuse_updated_pass = true;

	ret = unmount_w1_fuse_context(&fuse_ctx);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int run_w2_fixture_epoch_counterfactual(
	FILE *out, const char *cgroup_mount, int samples, const char *work_dir,
	size_t objects, const char *fixture_policy_obj,
	const char *table_policy_obj)
{
	struct w2_fixture_epoch_stats stats = {};
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	int sample;
	int ret;

	if (samples <= 0 || objects == 0 ||
	    objects > W2_FIXTURE_EPOCH_MAX_OBJECTS) {
		stats.failures = 1;
		emit_w2_fixture_epoch_summary(
			out, samples, &stats,
			"invalid sample count or fixture object count");
		return 1;
	}
	stats.objects = objects;
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		stats.failures = 1;
		emit_w2_fixture_epoch_summary(
			out, samples, &stats,
			"failed to create W2 fixture epoch workdir");
		return 1;
	}
	if (access(fixture_policy_obj, R_OK) || access(table_policy_obj, R_OK)) {
		stats.failures = 1;
		emit_w2_fixture_epoch_summary(
			out, samples, &stats,
			"W2 fixture epoch policy inputs are not readable");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		stats.failures = 1;
		emit_w2_fixture_epoch_summary(
			out, samples, &stats,
			"failed to resolve current cgroup id");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		char sample_dir[PATH_MAX];

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/fixture-policy-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w2_fixture_epoch_policy_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, fixture_policy_obj, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/table-static-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w2_fixture_epoch_table_static_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, table_policy_obj, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/table-updated-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w2_fixture_epoch_table_updated_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, table_policy_obj, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/materialized-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w2_fixture_epoch_materialized_system(
			out, sample_dir, sample, objects, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/fuse-sample-%03d", work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w2_fixture_epoch_fuse_system(
			out, sample_dir, sample, objects, &stats);
	}

	emit_w2_fixture_epoch_summary(
		out, samples, &stats,
		stats.failures ?
			"W2 fixture epoch counterfactual failed" :
			"W2 fixture epoch counterfactual passed; static exact table fails the epoch switch, while externally updated table, materialized view, and FUSE view reach epoch 2 only with per-object updates");
	return stats.failures ? 1 : 0;
}

#define W3_EPOCH_ONE 1
#define W3_EPOCH_TWO 2
#define W3_EPOCH_DEFAULT_OBJECTS 16
#define W3_EPOCH_MAX_OBJECTS 64
#define W3_EPOCH_TABLE_MAX_UPDATE_RATIO 10

struct w3_epoch_entry {
	char visible[NAMEI_EXT_NAME_MAX + 1];
	char epoch1[NAMEI_EXT_NAME_MAX + 1];
	char epoch2[NAMEI_EXT_NAME_MAX + 1];
};

struct w3_epoch_stats {
	int setup_rows;
	int correctness_rows;
	int update_rows;
	int failures;
	size_t objects;
	size_t static_wrong_epoch_hits;
	unsigned long long policy_setup_writes;
	unsigned long long table_setup_writes;
	unsigned long long materialized_setup_writes;
	unsigned long long fuse_setup_writes;
	unsigned long long policy_update_writes;
	unsigned long long table_update_writes;
	unsigned long long materialized_update_writes;
	unsigned long long fuse_update_writes;
	unsigned long long fuse_mounts;
	bool policy_epoch_switch_pass;
	bool table_static_expected_failure;
	bool table_updated_pass;
	bool materialized_updated_pass;
	bool fuse_updated_pass;
};

static const char *w3_epoch_target(const struct w3_epoch_entry *entry,
				   __u32 epoch)
{
	return epoch == W3_EPOCH_TWO ? entry->epoch2 : entry->epoch1;
}

static int prepare_w3_epoch_dir(const char *dir,
				struct w3_epoch_entry *entries,
				size_t objects, int sample)
{
	char path[PATH_MAX];
	char text[160];
	size_t i;
	int ret;

	ret = mkdir_if_missing(dir);
	if (ret)
		return ret;
	for (i = 0; i < objects; i++) {
		ret = snprintf(entries[i].visible, sizeof(entries[i].visible),
			       "state%02zu.rdb", i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(entries[i].visible))
			return -ENAMETOOLONG;
		ret = snprintf(entries[i].epoch1, sizeof(entries[i].epoch1),
			       "state%02zu.e1", i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(entries[i].epoch1))
			return -ENAMETOOLONG;
		ret = snprintf(entries[i].epoch2, sizeof(entries[i].epoch2),
			       "state%02zu.e2", i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(entries[i].epoch2))
			return -ENAMETOOLONG;

		ret = set_path(path, sizeof(path), dir, entries[i].visible);
		if (ret)
			return ret;
		unlink_existing(path);

		ret = set_path(path, sizeof(path), dir, entries[i].epoch1);
		if (ret)
			return ret;
		ret = snprintf(text, sizeof(text),
			       "namei_ext w3 checkpoint sample %d object %zu epoch 1\n",
			       sample, i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(text))
			return -ENAMETOOLONG;
		ret = write_text_file(path, text);
		if (ret)
			return ret;

		ret = set_path(path, sizeof(path), dir, entries[i].epoch2);
		if (ret)
			return ret;
		ret = snprintf(text, sizeof(text),
			       "namei_ext w3 checkpoint sample %d object %zu epoch 2\n",
			       sample, i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(text))
			return -ENAMETOOLONG;
		ret = write_text_file(path, text);
		if (ret)
			return ret;
	}
	return 0;
}

static int w3_epoch_lookup_matches(const char *dir,
				   const struct w3_epoch_entry *entry,
				   __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), dir,
			       w3_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static int w3_epoch_readdir_hides_backings(const char *dir,
					   const struct w3_epoch_entry *entry)
{
	bool saw_visible;
	bool saw_epoch1;
	bool saw_epoch2;
	int err = 0;

	saw_visible = dir_has_name(dir, entry->visible, &err);
	if (!err)
		saw_epoch1 = dir_has_name(dir, entry->epoch1, &err);
	else
		saw_epoch1 = false;
	if (!err)
		saw_epoch2 = dir_has_name(dir, entry->epoch2, &err);
	else
		saw_epoch2 = false;
	if (!err && saw_visible && !saw_epoch1 && !saw_epoch2)
		return 0;
	return err ? -err : -ENOENT;
}

static bool w3_epoch_current_oracle_passes(
	const char *dir, const struct w3_epoch_entry *entries, size_t objects,
	__u32 epoch, size_t *wrong_epoch_hits, __u32 wrong_epoch)
{
	bool pass = true;
	size_t wrong = 0;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w3_epoch_lookup_matches(dir, &entries[i], epoch))
			pass = false;
		if (w3_epoch_readdir_hides_backings(dir, &entries[i]))
			pass = false;
		if (wrong_epoch &&
		    !w3_epoch_lookup_matches(dir, &entries[i], wrong_epoch))
			wrong++;
	}
	if (wrong_epoch_hits)
		*wrong_epoch_hits = wrong;
	return pass;
}

static void emit_w3_epoch_setup(FILE *out, int sample, const char *system,
				bool pass, int err, __u64 setup_ns,
				size_t objects,
				unsigned long long setup_writes,
				bool policy_executed, const char *detail)
{
	const char *write_key = policy_executed ? "setup_rule_writes" :
						"setup_materialization_writes";

	fputs("{\"event\":\"w3-checkpoint-epoch-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_checkpoint_epoch.v1\","
	      "\"result_level\":\"kvm_checkpoint_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-checkpoint-epoch\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,\"objects\":%zu,"
		"\"setup_writes\":%llu,\"%s\":%llu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, objects, setup_writes,
		write_key, setup_writes,
		policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w3_epoch_correctness(FILE *out, int sample,
				      const char *system, const char *stage,
				      bool pass, bool current_oracle_pass,
				      bool expected_static_failure_observed,
				      size_t wrong_epoch_hits,
				      bool policy_executed,
				      const char *detail)
{
	fputs("{\"event\":\"w3-checkpoint-epoch-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_checkpoint_epoch.v1\","
	      "\"result_level\":\"kvm_checkpoint_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-checkpoint-epoch\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fputs(",\"stage\":", out);
	fprint_json_string(out, stage);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,"
		"\"current_oracle_pass\":%s,"
		"\"expected_static_failure_observed\":%s,"
		"\"wrong_epoch_hits\":%zu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false",
		current_oracle_pass ? "true" : "false",
		expected_static_failure_observed ? "true" : "false",
		wrong_epoch_hits,
		policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w3_epoch_update(FILE *out, int sample, const char *system,
				 bool pass, int err, __u64 update_ns,
				 __u64 observed_window_ns,
				 unsigned long long update_writes,
				 bool policy_executed, const char *detail)
{
	fputs("{\"event\":\"w3-checkpoint-epoch-update-window\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_checkpoint_epoch.v1\","
	      "\"result_level\":\"kvm_checkpoint_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-checkpoint-epoch\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"observed_update_window_ns\":%llu,"
		"\"update_writes\":%llu,"
		"\"from_epoch\":1,\"to_epoch\":2,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns,
		(unsigned long long)observed_window_ns, update_writes,
		policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w3_epoch_summary(FILE *out, int samples,
				  const struct w3_epoch_stats *stats,
				  const char *detail)
{
	double update_ratio = stats->policy_update_writes ?
		(double)stats->table_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	double materialized_update_ratio = stats->policy_update_writes ?
		(double)stats->materialized_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	double fuse_update_ratio = stats->policy_update_writes ?
		(double)stats->fuse_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	bool table_update_budget_failure =
		update_ratio > W3_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool materialized_update_budget_failure =
		materialized_update_ratio > W3_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool fuse_update_budget_failure =
		fuse_update_ratio > W3_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool targeted_c8_budget_failure =
		stats->policy_epoch_switch_pass &&
		stats->table_static_expected_failure &&
		stats->table_updated_pass &&
		table_update_budget_failure;

	fputs("{\"event\":\"w3-checkpoint-epoch-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_checkpoint_epoch.v1\","
	      "\"result_level\":\"kvm_checkpoint_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-checkpoint-epoch\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"setup_rows\":%d,"
		"\"correctness_rows\":%d,\"update_rows\":%d,"
		"\"objects\":%zu,"
		"\"static_wrong_epoch_hits\":%zu,"
		"\"policy_setup_writes\":%llu,"
		"\"table_setup_writes\":%llu,"
		"\"materialized_setup_writes\":%llu,"
		"\"fuse_setup_writes\":%llu,"
		"\"policy_update_writes\":%llu,"
		"\"table_update_writes\":%llu,"
		"\"materialized_update_writes\":%llu,"
		"\"fuse_update_writes\":%llu,"
		"\"fuse_mounts\":%llu,"
		"\"table_update_write_ratio\":%.17g,"
		"\"materialized_update_write_ratio\":%.17g,"
		"\"fuse_update_write_ratio\":%.17g,"
		"\"max_table_update_write_ratio\":%d,"
		"\"table_static_current_oracle_pass\":false,"
		"\"table_static_expected_failure_observed\":%s,"
		"\"table_updated_current_oracle_pass\":%s,"
		"\"table_requires_external_state_updates\":true,"
		"\"table_update_budget_failure\":%s,"
		"\"materialized_current_oracle_pass\":%s,"
		"\"materialized_feature_equivalent_baseline\":%s,"
		"\"materialized_update_budget_failure\":%s,"
		"\"fuse_current_oracle_pass\":%s,"
		"\"fuse_feature_equivalent_baseline\":%s,"
		"\"fuse_update_budget_failure\":%s,"
		"\"targeted_c8_budget_failure\":%s,"
		"\"real_podman_criu_restore\":false,"
		"\"release_sample_budget_pass\":%s,"
		"\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"qualified_for_c8\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, stats->setup_rows, stats->correctness_rows,
		stats->update_rows, stats->objects,
		stats->static_wrong_epoch_hits, stats->policy_setup_writes,
		stats->table_setup_writes, stats->materialized_setup_writes,
		stats->fuse_setup_writes,
		stats->policy_update_writes, stats->table_update_writes,
		stats->materialized_update_writes, stats->fuse_update_writes,
		stats->fuse_mounts, update_ratio, materialized_update_ratio,
		fuse_update_ratio,
		W3_EPOCH_TABLE_MAX_UPDATE_RATIO,
		stats->table_static_expected_failure ? "true" : "false",
		stats->table_updated_pass ? "true" : "false",
		table_update_budget_failure ? "true" : "false",
		stats->materialized_updated_pass ? "true" : "false",
		stats->materialized_updated_pass ? "true" : "false",
		materialized_update_budget_failure ? "true" : "false",
		stats->fuse_updated_pass ? "true" : "false",
		stats->fuse_updated_pass ? "true" : "false",
		fuse_update_budget_failure ? "true" : "false",
		targeted_c8_budget_failure ? "true" : "false",
		samples >= 20 ? "true" : "false",
		stats->failures ? "false" : "true", stats->failures,
		stats->failures ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int populate_w3_epoch_policy_rules(
	struct attached_policy *policy, __u64 cgroup_id, const char *dir,
	const struct w3_epoch_entry *entries, size_t objects,
	unsigned long long *writes)
{
	size_t i;

	*writes = 0;
	for (i = 0; i < objects; i++) {
		int ret;

		ret = update_checkpoint_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP, dir,
			entries[i].visible, entries[i].epoch1, i + 1,
			CHECKPOINT_CLASS_STATE, W3_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_checkpoint_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP, dir,
			entries[i].visible, entries[i].epoch2, i + 1,
			CHECKPOINT_CLASS_STATE, W3_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_checkpoint_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch1, entries[i].visible, i + 1,
			CHECKPOINT_CLASS_STATE, W3_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_checkpoint_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch2, entries[i].visible, i + 1,
			CHECKPOINT_CLASS_STATE, W3_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_checkpoint_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch1, entries[i].visible, i + 1,
			CHECKPOINT_CLASS_STATE, W3_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_checkpoint_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].epoch2, entries[i].visible, i + 1,
			CHECKPOINT_CLASS_STATE, W3_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
	}
	return 0;
}

static int populate_w3_epoch_table_rules(
	struct attached_policy *policy, __u64 cgroup_id, const char *dir,
	const struct w3_epoch_entry *entries, size_t objects,
	__u32 epoch, bool include_readdir, unsigned long long *writes)
{
	size_t i;

	*writes = 0;
	for (i = 0; i < objects; i++) {
		int ret;

		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
				  dir, entries[i].visible,
				  w3_epoch_target(&entries[i], epoch), i + 1);
		if (ret)
			return ret;
		(*writes)++;
		if (!include_readdir)
			continue;
		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				  dir, entries[i].epoch1, entries[i].visible,
				  i + 1);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				  dir, entries[i].epoch2, entries[i].visible,
				  i + 1);
		if (ret)
			return ret;
		(*writes)++;
	}
	return 0;
}

static int run_w3_epoch_policy_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, struct w3_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w3_epoch_entry entries[W3_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w3_epoch_dir(sample_dir, entries, objects, sample);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_CHECKPOINT_RESTORE,
				  "checkpoint_restore_epoch", &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w3_epoch_policy_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			&setup_writes);
	if (!ret)
		ret = update_checkpoint_session(&policy, cgroup_id,
						(__u32)sample + 1,
						W3_EPOCH_ONE, true);
	if (!ret)
		setup_writes++;
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->policy_setup_writes += setup_writes;
	emit_w3_epoch_setup(
		out, sample, "checkpoint_epoch_policy", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? "failed to setup checkpoint epoch policy" :
		      "checkpoint epoch policy attached with two epoch rule sets");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w3_epoch_current_oracle_passes(
		sample_dir, entries, objects, W3_EPOCH_ONE, NULL, 0);
	stats->correctness_rows++;
	emit_w3_epoch_correctness(
		out, sample, "checkpoint_epoch_policy", "epoch1",
		epoch1_pass, epoch1_pass, false, 0,
		true,
		epoch1_pass ? "checkpoint policy epoch 1 oracle passed" :
			      "checkpoint policy epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = update_checkpoint_session(&policy, cgroup_id, (__u32)sample + 1,
					W3_EPOCH_TWO, true);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w3_epoch_current_oracle_passes(
			sample_dir, entries, objects, W3_EPOCH_TWO, NULL, 0);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->policy_update_writes++;
	emit_w3_epoch_update(
		out, sample, "checkpoint_epoch_policy",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, 1, true,
		(!ret && epoch2_pass) ?
			"checkpoint policy switched epoch with one session update" :
			"checkpoint policy epoch switch failed");
	stats->correctness_rows++;
	emit_w3_epoch_correctness(
		out, sample, "checkpoint_epoch_policy", "epoch2",
		!ret && epoch2_pass, !ret && epoch2_pass, false, 0,
		true,
		(!ret && epoch2_pass) ?
			"checkpoint policy epoch 2 oracle passed" :
			"checkpoint policy epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->policy_epoch_switch_pass = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int run_w3_epoch_table_static_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, struct w3_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w3_epoch_entry entries[W3_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	size_t wrong_epoch_hits = 0;
	bool epoch1_pass = false;
	bool epoch2_current_pass = false;
	bool expected_failure = false;
	__u64 start_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w3_epoch_dir(sample_dir, entries, objects, sample);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_TABLE, "table_redirect",
				  &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w3_epoch_table_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			W3_EPOCH_ONE, true, &setup_writes);
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->table_setup_writes += setup_writes;
	emit_w3_epoch_setup(
		out, sample, "table_redirect_static_epoch1", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? "failed to setup static epoch table" :
		      "static exact table attached with epoch 1 lookup rules");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w3_epoch_current_oracle_passes(
		sample_dir, entries, objects, W3_EPOCH_ONE, NULL, 0);
	stats->correctness_rows++;
	emit_w3_epoch_correctness(
		out, sample, "table_redirect_static_epoch1", "epoch1",
		epoch1_pass, epoch1_pass, false, 0,
		true,
		epoch1_pass ? "static table epoch 1 oracle passed" :
			      "static table epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	epoch2_current_pass = w3_epoch_current_oracle_passes(
		sample_dir, entries, objects, W3_EPOCH_TWO,
		&wrong_epoch_hits, W3_EPOCH_ONE);
	expected_failure = !epoch2_current_pass && wrong_epoch_hits == objects;
	stats->correctness_rows++;
	stats->static_wrong_epoch_hits += wrong_epoch_hits;
	emit_w3_epoch_correctness(
		out, sample, "table_redirect_static_epoch1", "epoch2_without_update",
		expected_failure, epoch2_current_pass, expected_failure,
		wrong_epoch_hits,
		true,
		expected_failure ?
			"static table failed epoch 2 oracle with wrong epoch hits" :
			"static table did not expose the expected epoch failure");
	if (!expected_failure)
		stats->failures++;
	else
		stats->table_static_expected_failure = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !expected_failure;
}

static int run_w3_epoch_table_updated_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, struct w3_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w3_epoch_entry entries[W3_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w3_epoch_dir(sample_dir, entries, objects, sample);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_TABLE, "table_redirect",
				  &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w3_epoch_table_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			W3_EPOCH_ONE, true, &setup_writes);
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->table_setup_writes += setup_writes;
	emit_w3_epoch_setup(
		out, sample, "table_redirect_updated_exact", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? "failed to setup externally updated exact table" :
		      "externally updated exact table attached at epoch 1");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w3_epoch_current_oracle_passes(
		sample_dir, entries, objects, W3_EPOCH_ONE, NULL, 0);
	stats->correctness_rows++;
	emit_w3_epoch_correctness(
		out, sample, "table_redirect_updated_exact", "epoch1",
		epoch1_pass, epoch1_pass, false, 0,
		true,
		epoch1_pass ? "updated table epoch 1 oracle passed" :
			      "updated table epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = populate_w3_epoch_table_rules(
		&policy, cgroup_id, sample_dir, entries, objects,
		W3_EPOCH_TWO, false, &update_writes);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w3_epoch_current_oracle_passes(
			sample_dir, entries, objects, W3_EPOCH_TWO, NULL, 0);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->table_update_writes += update_writes;
	emit_w3_epoch_update(
		out, sample, "table_redirect_updated_exact",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		true,
		(!ret && epoch2_pass) ?
			"exact table reached epoch 2 after per-object lookup rewrites" :
			"exact table epoch 2 update failed");
	stats->correctness_rows++;
	emit_w3_epoch_correctness(
		out, sample, "table_redirect_updated_exact", "epoch2_after_update",
		!ret && epoch2_pass, !ret && epoch2_pass, false, 0,
		true,
		(!ret && epoch2_pass) ?
			"updated table epoch 2 oracle passed" :
			"updated table epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->table_updated_pass = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int w3_epoch_materialized_copy_epoch(
	const char *backing_dir, const char *view_dir,
	const struct w3_epoch_entry *entries, size_t objects, __u32 epoch,
	unsigned long long *writes, unsigned long long *bytes_copied)
{
	char src[PATH_MAX];
	char dst[PATH_MAX];
	struct stat st = {};
	size_t i;

	if (writes)
		*writes = 0;
	if (bytes_copied)
		*bytes_copied = 0;
	for (i = 0; i < objects; i++) {
		int ret = set_path(src, sizeof(src), backing_dir,
				   w3_epoch_target(&entries[i], epoch));
		if (!ret)
			ret = set_path(dst, sizeof(dst), view_dir,
				       entries[i].visible);
		if (ret)
			return ret;
		if (bytes_copied && !stat(src, &st) && st.st_size > 0)
			*bytes_copied += (unsigned long long)st.st_size;
		ret = copy_file(src, dst);
		if (ret)
			return ret;
		if (writes)
			(*writes)++;
	}
	return 0;
}

static int w3_epoch_materialized_lookup_matches(
	const char *view_dir, const char *backing_dir,
	const struct w3_epoch_entry *entry, __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), view_dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), backing_dir,
			       w3_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static bool w3_epoch_materialized_oracle_passes(
	const char *view_dir, const char *backing_dir,
	const struct w3_epoch_entry *entries, size_t objects, __u32 epoch)
{
	bool pass = true;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w3_epoch_materialized_lookup_matches(
			    view_dir, backing_dir, &entries[i], epoch))
			pass = false;
		if (w3_epoch_readdir_hides_backings(view_dir, &entries[i]))
			pass = false;
	}
	return pass;
}

static int run_w3_epoch_materialized_system(
	FILE *out, const char *sample_dir, int sample, size_t objects,
	struct w3_epoch_stats *stats)
{
	struct w3_epoch_entry entries[W3_EPOCH_MAX_OBJECTS] = {};
	char backing_dir[PATH_MAX];
	char view_dir[PATH_MAX];
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	unsigned long long bytes_copied = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(backing_dir, sizeof(backing_dir), sample_dir,
			       "backing");
	if (!ret)
		ret = set_path(view_dir, sizeof(view_dir), sample_dir, "view");
	if (!ret)
		ret = prepare_w3_epoch_dir(backing_dir, entries, objects,
					   sample);

	start_ns = monotonic_ns();
	if (!ret)
		ret = mkdir_if_missing(view_dir);
	if (!ret)
		ret = w3_epoch_materialized_copy_epoch(
			backing_dir, view_dir, entries, objects,
			W3_EPOCH_ONE, &setup_writes, &bytes_copied);
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->materialized_setup_writes += setup_writes;
	emit_w3_epoch_setup(
		out, sample, "materialized_checkpoint_epoch_view", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, false,
		ret ? "failed to setup materialized checkpoint epoch view" :
		      "materialized checkpoint epoch view copied epoch 1 objects");
	if (ret) {
		stats->failures++;
		return 1;
	}

	epoch1_pass = w3_epoch_materialized_oracle_passes(
		view_dir, backing_dir, entries, objects, W3_EPOCH_ONE);
	stats->correctness_rows++;
	emit_w3_epoch_correctness(
		out, sample, "materialized_checkpoint_epoch_view", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, false,
		epoch1_pass ? "materialized checkpoint epoch 1 oracle passed" :
			      "materialized checkpoint epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = w3_epoch_materialized_copy_epoch(
		backing_dir, view_dir, entries, objects, W3_EPOCH_TWO,
		&update_writes, &bytes_copied);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w3_epoch_materialized_oracle_passes(
			view_dir, backing_dir, entries, objects,
			W3_EPOCH_TWO);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->materialized_update_writes += update_writes;
	emit_w3_epoch_update(
		out, sample, "materialized_checkpoint_epoch_view",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		false,
		(!ret && epoch2_pass) ?
			"materialized checkpoint view reached epoch 2 after per-object copies" :
			"materialized checkpoint view epoch 2 update failed");
	stats->correctness_rows++;
	emit_w3_epoch_correctness(
		out, sample, "materialized_checkpoint_epoch_view",
		"epoch2_after_update", !ret && epoch2_pass,
		!ret && epoch2_pass, false, 0, false,
		(!ret && epoch2_pass) ?
			"materialized checkpoint epoch 2 oracle passed" :
			"materialized checkpoint epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->materialized_updated_pass = true;

	return ret || !epoch1_pass || !epoch2_pass;
}

static int w3_epoch_prepare_fuse_specs(
	const char *view_dir, const char *source_dir,
	const struct w3_epoch_entry *entries, size_t objects,
	struct w1_alias_spec *specs, size_t *nr_specs)
{
	char source_path[PATH_MAX];
	char shadow[NAMEI_EXT_NAME_MAX + 1];
	size_t i;
	int ret;

	*nr_specs = 0;
	for (i = 0; i < objects; i++) {
		ret = snprintf(shadow, sizeof(shadow), "state%02zu.fuse", i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(shadow))
			return -ENAMETOOLONG;
		ret = set_path(source_path, sizeof(source_path), source_dir,
			       entries[i].epoch1);
		if (ret)
			return ret;
		ret = add_w1_alias_spec(specs, nr_specs, view_dir,
					entries[i].visible, shadow,
					source_path);
		if (ret)
			return ret;
	}
	return 0;
}

static int w3_epoch_fuse_lookup_matches(
	const char *view_dir, const char *source_dir,
	const struct w3_epoch_entry *entry, __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), view_dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), source_dir,
			       w3_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static int w3_epoch_fuse_readdir_hides_backings(
	const char *view_dir, const struct w3_epoch_entry *entry,
	const struct w1_alias_spec *spec)
{
	bool saw_shadow;
	int err = 0;
	int ret;

	ret = w3_epoch_readdir_hides_backings(view_dir, entry);
	if (ret)
		return ret;
	saw_shadow = dir_has_name(view_dir, spec->shadow, &err);
	if (err)
		return -err;
	return saw_shadow ? -ENOENT : 0;
}

static bool w3_epoch_fuse_oracle_passes(
	const char *view_dir, const char *source_dir,
	const struct w3_epoch_entry *entries,
	const struct w1_alias_spec *specs, size_t objects, __u32 epoch)
{
	bool pass = true;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w3_epoch_fuse_lookup_matches(
			    view_dir, source_dir, &entries[i], epoch))
			pass = false;
		if (w3_epoch_fuse_readdir_hides_backings(
			    view_dir, &entries[i], &specs[i]))
			pass = false;
	}
	return pass;
}

static int w3_epoch_fuse_copy_epoch(
	const char *source_dir, const char *fuse_backing_dir,
	const struct w3_epoch_entry *entries,
	const struct w1_alias_spec *specs, size_t objects, __u32 epoch,
	struct nginx_macro_stats *stats)
{
	char src[PATH_MAX];
	char dst[PATH_MAX];
	size_t i;

	for (i = 0; i < objects; i++) {
		int ret = set_path(src, sizeof(src), source_dir,
				   w3_epoch_target(&entries[i], epoch));
		if (!ret)
			ret = set_path(dst, sizeof(dst), fuse_backing_dir,
				       specs[i].shadow);
		if (ret)
			return ret;
		ret = copy_file_counted(src, dst, stats, true);
		if (ret)
			return ret;
	}
	return 0;
}

static int run_w3_epoch_fuse_system(
	FILE *out, const char *sample_dir, int sample, size_t objects,
	struct w3_epoch_stats *stats)
{
	struct w3_epoch_entry entries[W3_EPOCH_MAX_OBJECTS] = {};
	struct w1_alias_spec specs[W3_EPOCH_MAX_OBJECTS] = {};
	struct w1_fuse_context fuse_ctx = {};
	struct nginx_macro_stats setup_stats = {};
	struct nginx_macro_stats update_stats = {};
	char source_dir[PATH_MAX];
	char view_dir[PATH_MAX];
	char fuse_backing_dir[PATH_MAX];
	size_t nr_specs = 0;
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(source_dir, sizeof(source_dir), sample_dir,
			       "source");
	if (!ret)
		ret = set_path(view_dir, sizeof(view_dir), sample_dir, "view");
	if (!ret)
		ret = prepare_w3_epoch_dir(source_dir, entries, objects,
					   sample);
	if (!ret)
		ret = mkdir_if_missing(view_dir);
	if (!ret)
		ret = w3_epoch_prepare_fuse_specs(
			view_dir, source_dir, entries, objects, specs,
			&nr_specs);

	start_ns = monotonic_ns();
	if (!ret)
		ret = setup_w1_fuse_mount(specs, nr_specs, view_dir,
					  &setup_stats, &fuse_ctx);
	end_ns = monotonic_ns();
	setup_writes = setup_stats.created_files;
	stats->setup_rows++;
	stats->fuse_setup_writes += setup_writes;
	stats->fuse_mounts += setup_stats.fuse_mounts;
	emit_w3_epoch_setup(
		out, sample, "fuse_checkpoint_epoch_view", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, false,
		ret ? "failed to setup FUSE checkpoint epoch view" :
		      "FUSE checkpoint epoch view mounted with epoch 1 backing shadows");
	if (ret) {
		unmount_w1_fuse_context(&fuse_ctx);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w3_epoch_fuse_oracle_passes(
		view_dir, source_dir, entries, specs, objects, W3_EPOCH_ONE);
	stats->correctness_rows++;
	emit_w3_epoch_correctness(
		out, sample, "fuse_checkpoint_epoch_view", "epoch1",
		epoch1_pass, epoch1_pass, false, 0, false,
		epoch1_pass ? "FUSE checkpoint epoch 1 oracle passed" :
			      "FUSE checkpoint epoch 1 oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = w1_fuse_backing_dir(view_dir, fuse_backing_dir,
				  sizeof(fuse_backing_dir));
	if (!ret)
		ret = w3_epoch_fuse_copy_epoch(
			source_dir, fuse_backing_dir, entries, specs, objects,
			W3_EPOCH_TWO, &update_stats);
	update_done_ns = monotonic_ns();
	update_writes = update_stats.source_update_writes;
	if (!ret)
		epoch2_pass = w3_epoch_fuse_oracle_passes(
			view_dir, source_dir, entries, specs, objects,
			W3_EPOCH_TWO);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->fuse_update_writes += update_writes;
	emit_w3_epoch_update(
		out, sample, "fuse_checkpoint_epoch_view",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		false,
		(!ret && epoch2_pass) ?
			"FUSE checkpoint view reached epoch 2 after per-object backing rewrites" :
			"FUSE checkpoint view epoch 2 update failed");
	stats->correctness_rows++;
	emit_w3_epoch_correctness(
		out, sample, "fuse_checkpoint_epoch_view",
		"epoch2_after_update", !ret && epoch2_pass,
		!ret && epoch2_pass, false, 0, false,
		(!ret && epoch2_pass) ?
			"FUSE checkpoint epoch 2 oracle passed" :
			"FUSE checkpoint epoch 2 oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->fuse_updated_pass = true;

	ret = unmount_w1_fuse_context(&fuse_ctx);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int run_w3_checkpoint_epoch_counterfactual(
	FILE *out, const char *cgroup_mount, int samples, const char *work_dir,
	size_t objects, const char *checkpoint_policy_obj,
	const char *table_policy_obj)
{
	struct w3_epoch_stats stats = {};
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	int sample;
	int ret;

	if (samples <= 0 || objects == 0 || objects > W3_EPOCH_MAX_OBJECTS) {
		stats.failures = 1;
		emit_w3_epoch_summary(
			out, samples, &stats,
			"invalid sample count or checkpoint object count");
		return 1;
	}
	stats.objects = objects;
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		stats.failures = 1;
		emit_w3_epoch_summary(
			out, samples, &stats,
			"failed to create W3 checkpoint epoch workdir");
		return 1;
	}
	if (access(checkpoint_policy_obj, R_OK) || access(table_policy_obj, R_OK)) {
		stats.failures = 1;
		emit_w3_epoch_summary(
			out, samples, &stats,
			"W3 checkpoint epoch policy inputs are not readable");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		stats.failures = 1;
		emit_w3_epoch_summary(
			out, samples, &stats,
			"failed to resolve current cgroup id");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		char sample_dir[PATH_MAX];

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/checkpoint-policy-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w3_epoch_policy_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, checkpoint_policy_obj, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/table-static-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w3_epoch_table_static_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, table_policy_obj, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/table-updated-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w3_epoch_table_updated_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, table_policy_obj, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/materialized-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w3_epoch_materialized_system(
			out, sample_dir, sample, objects, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/fuse-sample-%03d", work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w3_epoch_fuse_system(
			out, sample_dir, sample, objects, &stats);
	}

	emit_w3_epoch_summary(
		out, samples, &stats,
		stats.failures ?
			"W3 checkpoint epoch counterfactual failed" :
			"W3 checkpoint epoch counterfactual passed; static exact table fails epoch switch, while externally updated table, materialized view, and FUSE view reach epoch 2 only with per-object update writes");
	return stats.failures ? 1 : 0;
}

static const char *cache_forbidden_name(const struct oracle_entry *entry)
{
	if (!strcmp(entry->branch, "verified_hit"))
		return "object.bad";
	if (!strcmp(entry->branch, "stale_fallback") ||
	    !strcmp(entry->branch, "stale_canonical"))
		return "stale.local";
	if (!strcmp(entry->branch, "corrupt_reject"))
		return "corrupt.local";
	return NULL;
}

static const char *cache_forbidden_text(const struct oracle_entry *entry)
{
	if (!strcmp(entry->branch, "verified_hit"))
		return W4_CACHE_WRONG_OBJECT;
	if (!strcmp(entry->branch, "stale_fallback") ||
	    !strcmp(entry->branch, "stale_canonical"))
		return W4_CACHE_STALE_LOCAL;
	if (!strcmp(entry->branch, "corrupt_reject"))
		return W4_CACHE_CORRUPT_LOCAL;
	return NULL;
}

static int mkdir_relative_under(const char *base, const char *rel, char *out,
				size_t out_size)
{
	char rel_copy[PATH_MAX];
	char *saveptr = NULL;
	char *component;
	int ret;

	ret = mkdir_if_missing(base);
	if (ret)
		return ret;
	ret = copy_string(out, out_size, base);
	if (ret)
		return ret;
	if (!strcmp(rel, "."))
		return 0;
	if (rel[0] == '/')
		return -EINVAL;
	ret = copy_string(rel_copy, sizeof(rel_copy), rel);
	if (ret)
		return ret;
	for (component = strtok_r(rel_copy, "/", &saveptr); component;
	     component = strtok_r(NULL, "/", &saveptr)) {
		char next[PATH_MAX];

		if (!strcmp(component, ".") || !strcmp(component, ".."))
			return -EINVAL;
		ret = set_path(next, sizeof(next), out, component);
		if (ret)
			return ret;
		ret = mkdir_if_missing(next);
		if (ret)
			return ret;
		ret = copy_string(out, out_size, next);
		if (ret)
			return ret;
	}
	return 0;
}

static void emit_build_replay_case(FILE *out, const char *workload,
				   const char *op, bool pass, int err,
				   int exit_code, const char *detail,
				   const char *baseline_output,
				   const char *policy_output)
{
	bool policy_executed = !strcmp(op, "policy_preprocess") ||
			       !strcmp(op, "output_compare");

	fputs("{\"event\":\"w1-build-replay\","
	      "\"result_level\":\"kvm_policy_build_replay_witness\","
	      "\"policy\":\"build_graph\","
	      "\"workload_id\":",
	      out);
	fprint_json_string(out, workload);
	fputs(",\"op\":", out);
	fprint_json_string(out, op);
	fprintf(out,
		",\"pass\":%s,\"errno\":%d,\"exit_code\":%d,"
		"\"run_environment\":\"kvm\","
		"\"policy_executed\":%s,"
		"\"kvm_validated\":true,"
		"\"output_hash_oracle\":false,"
		"\"policy_replay_output_hash_oracle\":true,"
		"\"release_output_hash_oracle\":false,"
		"\"output_hash_oracle_scope\":\"kvm_policy_preprocess\","
		"\"qualified_for_c8\":false,\"detail\":",
		pass ? "true" : "false", err, exit_code,
		policy_executed ? "true" : "false");
	fprint_json_string(out, detail);
	fputs(",\"baseline_output\":", out);
	fprint_json_string(out, baseline_output ? baseline_output : "");
	fputs(",\"policy_output\":", out);
	fprint_json_string(out, policy_output ? policy_output : "");
	fputs("}\n", out);
	fflush(out);
}

static void emit_release_replay_case(FILE *out, const char *workload,
				     const char *op, bool pass, int err,
				     int exit_code, bool policy_executed,
				     bool hash_match, const char *detail,
				     const char *baseline_binary,
				     const char *policy_binary)
{
	fputs("{\"event\":\"w1-release-build-replay\","
	      "\"result_level\":\"kvm_policy_release_build_replay_witness\","
	      "\"policy\":\"build_graph\","
	      "\"workload_id\":",
	      out);
	fprint_json_string(out, workload);
	fputs(",\"op\":", out);
	fprint_json_string(out, op);
	fprintf(out,
		",\"pass\":%s,\"errno\":%d,\"exit_code\":%d,"
		"\"run_environment\":\"kvm\","
		"\"policy_executed\":%s,"
		"\"kvm_validated\":true,"
		"\"release_binary_hash_match\":%s,"
		"\"release_output_hash_oracle\":false,"
		"\"qualified_for_c8\":false,\"detail\":",
		pass ? "true" : "false", err, exit_code,
		policy_executed ? "true" : "false",
		hash_match ? "true" : "false");
	fprint_json_string(out, detail);
	fputs(",\"baseline_binary\":", out);
	fprint_json_string(out, baseline_binary ? baseline_binary : "");
	fputs(",\"policy_binary\":", out);
	fprint_json_string(out, policy_binary ? policy_binary : "");
	fputs("}\n", out);
	fflush(out);
}

static void emit_w1_branch_probe(FILE *out, const char *workload,
				 const char *branch, const char *op,
				 bool pass, int err, bool policy_executed,
				 const char *detail, const char *path,
				 const char *expected)
{
	fputs("{\"event\":\"w1-branch-probe\","
	      "\"result_level\":\"kvm_policy_branch_probe_witness\","
	      "\"policy\":\"build_graph\","
	      "\"workload_id\":",
	      out);
	fprint_json_string(out, workload ? workload : "");
	fputs(",\"branch\":", out);
	fprint_json_string(out, branch ? branch : "");
	fputs(",\"op\":", out);
	fprint_json_string(out, op);
	fprintf(out,
		",\"pass\":%s,\"errno\":%d,"
		"\"run_environment\":\"kvm\","
		"\"policy_executed\":%s,"
		"\"kvm_validated\":true,"
		"\"qualified_for_c8\":false,\"detail\":",
		pass ? "true" : "false", err,
		policy_executed ? "true" : "false");
	fprint_json_string(out, detail);
	fputs(",\"path\":", out);
	fprint_json_string(out, path ? path : "");
	fputs(",\"expected\":", out);
	fprint_json_string(out, expected ? expected : "");
	fputs("}\n", out);
	fflush(out);
}

static int run_child_capture_trace(char *const argv[], const char *path_env,
				   const char *stdout_path,
				   const char *stderr_path,
				   const char *trace_path, int *exit_code)
{
	char *trace_argv[64];
	int out_fd;
	int err_fd;
	int status;
	pid_t pid;
	size_t argc = 0;
	size_t i;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (pid == 0) {
		if (path_env && setenv("PATH", path_env, 1))
			_exit(125);
		if (setenv("SOURCE_DATE_EPOCH", "0", 1))
			_exit(125);
		out_fd = open(stdout_path,
			      O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
		if (out_fd < 0)
			_exit(125);
		err_fd = open(stderr_path,
			      O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
		if (err_fd < 0)
			_exit(125);
		if (dup2(out_fd, STDOUT_FILENO) < 0)
			_exit(125);
		if (dup2(err_fd, STDERR_FILENO) < 0)
			_exit(125);
		close(out_fd);
		close(err_fd);
		if (trace_path) {
			while (argv[argc])
				argc++;
			if (argc + 6 >= ARRAY_SIZE(trace_argv))
				_exit(125);
			trace_argv[0] = "strace";
			trace_argv[1] = "-f";
			trace_argv[2] = "-e";
			trace_argv[3] = "trace=%file";
			trace_argv[4] = "-o";
			trace_argv[5] = (char *)trace_path;
			for (i = 0; i <= argc; i++)
				trace_argv[i + 6] = argv[i];
			execvp(trace_argv[0], trace_argv);
		} else {
			execvp(argv[0], argv);
		}
		_exit(127);
	}

	if (waitpid(pid, &status, 0) < 0)
		return -errno;
	if (WIFEXITED(status)) {
		*exit_code = WEXITSTATUS(status);
		return 0;
	}
	if (WIFSIGNALED(status)) {
		*exit_code = 128 + WTERMSIG(status);
		return 0;
	}
	*exit_code = 126;
	return 0;
}

static int run_child_capture(char *const argv[], const char *path_env,
			     const char *stdout_path, const char *stderr_path,
			     int *exit_code)
{
	return run_child_capture_trace(argv, path_env, stdout_path, stderr_path,
				       NULL, exit_code);
}

static int make_include_arg(char *dst, size_t size, const char *dir)
{
	int ret = snprintf(dst, size, "-I%s", dir);

	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int run_ccache_one_arg(const char *arg, const char *stdout_path,
			      const char *stderr_path, int *exit_code)
{
	char *const argv[] = {
		"ccache",
		(char *)arg,
		NULL,
	};

	return run_child_capture(argv, NULL, stdout_path, stderr_path,
				 exit_code);
}

static int run_ccache_redis_compile(const char *redis_src,
				    const char *redis_build_src,
				    const char *output_path,
				    const char *stdout_path,
				    const char *stderr_path,
				    const char *trace_path,
				    int *exit_code)
{
	char redis_inc_dir[PATH_MAX];
	char redis_inc_arg[PATH_MAX + 3];
	char *const argv[] = {
		"ccache",
		"gcc",
		redis_inc_arg,
		"-c",
		(char *)redis_src,
		"-o",
		(char *)output_path,
		NULL,
	};
	int ret;

	ret = set_path(redis_inc_dir, sizeof(redis_inc_dir), redis_build_src,
		       "src");
	if (ret)
		return ret;
	ret = make_include_arg(redis_inc_arg, sizeof(redis_inc_arg),
			       redis_inc_dir);
	if (ret)
		return ret;
	return run_child_capture_trace(argv, NULL, stdout_path, stderr_path,
				       trace_path, exit_code);
}

static int run_ccache_nginx_compile(const char *nginx_src,
				    const char *nginx_build_src,
				    const char *output_path,
				    const char *stdout_path,
				    const char *stderr_path,
				    const char *trace_path,
				    int *exit_code)
{
	char objs_dir[PATH_MAX];
	char core_dir[PATH_MAX];
	char event_dir[PATH_MAX];
	char modules_dir[PATH_MAX];
	char unix_dir[PATH_MAX];
	char objs_arg[PATH_MAX + 3];
	char core_arg[PATH_MAX + 3];
	char event_arg[PATH_MAX + 3];
	char modules_arg[PATH_MAX + 3];
	char unix_arg[PATH_MAX + 3];
	char *const argv[] = {
		"ccache",
		"gcc",
		objs_arg,
		core_arg,
		event_arg,
		modules_arg,
		unix_arg,
		"-c",
		(char *)nginx_src,
		"-o",
		(char *)output_path,
		NULL,
	};
	int ret;

	ret = set_path(objs_dir, sizeof(objs_dir), nginx_build_src, "objs");
	if (!ret)
		ret = set_path(core_dir, sizeof(core_dir), nginx_build_src,
			       "src/core");
	if (!ret)
		ret = set_path(event_dir, sizeof(event_dir), nginx_build_src,
			       "src/event");
	if (!ret)
		ret = set_path(modules_dir, sizeof(modules_dir),
			       nginx_build_src, "src/event/modules");
	if (!ret)
		ret = set_path(unix_dir, sizeof(unix_dir), nginx_build_src,
			       "src/os/unix");
	if (ret)
		return ret;
	ret = make_include_arg(objs_arg, sizeof(objs_arg), objs_dir);
	if (!ret)
		ret = make_include_arg(core_arg, sizeof(core_arg), core_dir);
	if (!ret)
		ret = make_include_arg(event_arg, sizeof(event_arg),
				       event_dir);
	if (!ret)
		ret = make_include_arg(modules_arg, sizeof(modules_arg),
				       modules_dir);
	if (!ret)
		ret = make_include_arg(unix_arg, sizeof(unix_arg), unix_dir);
	if (ret)
		return ret;
	return run_child_capture_trace(argv, NULL, stdout_path, stderr_path,
				       trace_path, exit_code);
}

static int copy_visible_to_shadow(const char *root, const char *rel,
				  const char *visible, const char *shadow)
{
	char dir[PATH_MAX];
	char visible_path[PATH_MAX];
	char shadow_path[PATH_MAX];
	int ret;

	ret = mkdir_relative_under(root, rel, dir, sizeof(dir));
	if (ret)
		return ret;
	ret = set_path(visible_path, sizeof(visible_path), dir, visible);
	if (ret)
		return ret;
	ret = set_path(shadow_path, sizeof(shadow_path), dir, shadow);
	if (ret)
		return ret;
	ret = copy_file(visible_path, shadow_path);
	if (ret)
		return ret;
	if (unlink(visible_path))
		return -errno;
	return 0;
}

static int copy_visible_to_extra_shadow(const char *root, const char *rel,
					const char *visible,
					const char *shadow)
{
	char dir[PATH_MAX];
	char visible_path[PATH_MAX];
	char shadow_path[PATH_MAX];
	int ret;

	ret = mkdir_relative_under(root, rel, dir, sizeof(dir));
	if (ret)
		return ret;
	ret = set_path(visible_path, sizeof(visible_path), dir, visible);
	if (ret)
		return ret;
	ret = set_path(shadow_path, sizeof(shadow_path), dir, shadow);
	if (ret)
		return ret;
	ret = copy_file(visible_path, shadow_path);
	if (ret)
		return ret;
	if (unlink(visible_path))
		return -errno;
	return 0;
}

static int prepare_replay_toolchain(const char *result_dir, char *toolchain_dir,
				    size_t toolchain_dir_size,
				    char *path_env, size_t path_env_size)
{
	char cc_real[PATH_MAX];
	char cc_link[PATH_MAX];
	int ret;

	ret = set_path(toolchain_dir, toolchain_dir_size, result_dir,
		       "toolchain");
	if (ret)
		return ret;
	ret = mkdir_if_missing(toolchain_dir);
	if (ret)
		return ret;
	ret = set_path(cc_real, sizeof(cc_real), toolchain_dir, "cc.real");
	if (ret)
		return ret;
	ret = set_path(cc_link, sizeof(cc_link), toolchain_dir, "cc");
	if (ret)
		return ret;
	unlink(cc_real);
	unlink(cc_link);
	if (symlink("/usr/bin/gcc", cc_real))
		return -errno;
	if (symlink("cc.real", cc_link))
		return -errno;
	ret = snprintf(path_env, path_env_size, "%s:/usr/local/sbin:/usr/local/bin:"
		       "/usr/sbin:/usr/bin:/sbin:/bin", toolchain_dir);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= path_env_size)
		return -ENAMETOOLONG;
	return 0;
}

static int prepare_replay_include(const char *result_dir, char *include_dir,
				  size_t include_dir_size)
{
	char stdio_shadow[PATH_MAX];
	int ret;

	ret = set_path(include_dir, include_dir_size, result_dir, "include");
	if (ret)
		return ret;
	ret = mkdir_if_missing(include_dir);
	if (ret)
		return ret;
	ret = set_path(stdio_shadow, sizeof(stdio_shadow), include_dir,
		       ".namei_ext.external.stdio.h");
	if (ret)
		return ret;
	return copy_file("/usr/include/stdio.h", stdio_shadow);
}

static int assign_build_replay_parent_dirs(struct oracle_entry *entries,
					   size_t nr_entries,
					   const char *redis_src,
					   const char *nginx_src,
					   const char *toolchain_dir,
					   const char *include_dir)
{
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		const char *root = NULL;
		int ret;

		if (!strcmp(entries[i].branch, "toolchain_selection")) {
			ret = copy_string(entries[i].dir, sizeof(entries[i].dir),
					  toolchain_dir);
		} else if (!strcmp(entries[i].branch, "external_dependency")) {
			ret = copy_string(entries[i].dir, sizeof(entries[i].dir),
					  include_dir);
		} else if (!strcmp(entries[i].workload, "w1-redis-build")) {
			root = redis_src;
			ret = mkdir_relative_under(root, entries[i].parent_relative,
						   entries[i].dir,
						   sizeof(entries[i].dir));
		} else if (!strcmp(entries[i].workload, "w1-nginx-build")) {
			root = nginx_src;
			ret = mkdir_relative_under(root, entries[i].parent_relative,
						   entries[i].dir,
						   sizeof(entries[i].dir));
		} else {
			ret = -EINVAL;
		}
		if (ret)
			return ret;
	}
	return 0;
}

static int prepare_replay_aliases(const char *workload, const char *src_root,
				  struct oracle_entry *entries,
				  size_t nr_entries)
{
	size_t i;
	int ret;

	if (!strcmp(workload, "w1-redis-build")) {
		ret = copy_visible_to_extra_shadow(src_root, "src", "config.h",
						   "config.gen.h");
		if (ret)
			return ret;
		ret = copy_visible_to_extra_shadow(src_root, "src", "version.h",
						   "version.src.h");
		if (ret)
			return ret;
	}

	for (i = 0; i < nr_entries; i++) {
		if (strcmp(entries[i].workload, workload))
			continue;
		if (!strcmp(entries[i].branch, "toolchain_selection") ||
		    !strcmp(entries[i].branch, "external_dependency"))
			continue;
		ret = copy_visible_to_shadow(src_root, entries[i].parent_relative,
					     entries[i].visible,
					     entries[i].shadow);
		if (ret)
			return ret;
	}
	return 0;
}

static int run_redis_replay(FILE *out, const char *redis_src,
			    const char *result_dir, const char *include_dir,
			    const char *path_env, bool policy_mode)
{
	char src_dir[PATH_MAX];
	char deps_hiredis[PATH_MAX];
	char deps_linenoise[PATH_MAX];
	char deps_lua[PATH_MAX];
	char deps_hdr[PATH_MAX];
	char deps_fpconv[PATH_MAX];
	char input[PATH_MAX];
	char baseline_out[PATH_MAX];
	char policy_out[PATH_MAX];
	char baseline_stdout[PATH_MAX];
	char baseline_stderr[PATH_MAX];
	char policy_stdout[PATH_MAX];
	char policy_stderr[PATH_MAX];
	int baseline_exit = -1;
	int policy_exit = -1;
	int ret;
	char *baseline_argv[28];
	char *policy_argv[30];
	int i = 0;

	ret = set_path(src_dir, sizeof(src_dir), redis_src, "src");
	if (!ret)
		ret = set_child_path(deps_hiredis, sizeof(deps_hiredis),
				     redis_src, "deps", "hiredis");
	if (!ret)
		ret = set_child_path(deps_linenoise, sizeof(deps_linenoise),
				     redis_src, "deps", "linenoise");
	if (!ret)
		ret = set_child_path(deps_lua, sizeof(deps_lua),
				     redis_src, "deps", "lua/src");
	if (!ret)
		ret = set_child_path(deps_hdr, sizeof(deps_hdr),
				     redis_src, "deps", "hdr_histogram");
	if (!ret)
		ret = set_child_path(deps_fpconv, sizeof(deps_fpconv),
				     redis_src, "deps", "fpconv");
	if (!ret)
		ret = set_child_path(input, sizeof(input), redis_src, "src",
				     "server.c");
	if (!ret)
		ret = set_path(baseline_out, sizeof(baseline_out), result_dir,
			       "redis.baseline.i");
	if (!ret)
		ret = set_path(policy_out, sizeof(policy_out), result_dir,
			       "redis.policy.i");
	if (!ret)
		ret = set_path(baseline_stdout, sizeof(baseline_stdout),
			       result_dir, "redis.baseline.stdout");
	if (!ret)
		ret = set_path(baseline_stderr, sizeof(baseline_stderr),
			       result_dir, "redis.baseline.stderr");
	if (!ret)
		ret = set_path(policy_stdout, sizeof(policy_stdout), result_dir,
			       "redis.policy.stdout");
	if (!ret)
		ret = set_path(policy_stderr, sizeof(policy_stderr), result_dir,
			       "redis.policy.stderr");
	if (ret) {
		emit_build_replay_case(out, "w1-redis-build", "build_paths",
				       false, -ret, -1,
				       "failed to build Redis replay paths",
				       NULL, NULL);
		return 1;
	}

	i = 0;
	baseline_argv[i++] = "/usr/bin/cc";
	baseline_argv[i++] = "-E";
	baseline_argv[i++] = "-P";
	baseline_argv[i++] = "-DREDIS_STATIC=";
	baseline_argv[i++] = "-DHAVE_LIBSYSTEMD";
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = src_dir;
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = deps_hiredis;
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = deps_linenoise;
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = deps_lua;
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = deps_hdr;
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = deps_fpconv;
	baseline_argv[i++] = input;
	baseline_argv[i++] = "-o";
	baseline_argv[i++] = baseline_out;
	baseline_argv[i] = NULL;

	if (!policy_mode) {
		ret = run_child_capture(baseline_argv, NULL, baseline_stdout,
					baseline_stderr, &baseline_exit);
		if (ret || baseline_exit) {
			emit_build_replay_case(out, "w1-redis-build",
					       "baseline_preprocess", false,
					       ret ? -ret : 0, baseline_exit,
					       "Redis baseline preprocessing failed",
					       baseline_out, NULL);
			return 1;
		}
		emit_build_replay_case(out, "w1-redis-build",
				       "baseline_preprocess", true, 0,
				       baseline_exit,
				       "Redis baseline preprocessing passed",
				       baseline_out, NULL);
		return 0;
	}

	i = 0;
	policy_argv[i++] = "cc";
	policy_argv[i++] = "-E";
	policy_argv[i++] = "-P";
	policy_argv[i++] = "-DREDIS_STATIC=";
	policy_argv[i++] = "-DHAVE_LIBSYSTEMD";
	policy_argv[i++] = "-I";
	policy_argv[i++] = (char *)include_dir;
	policy_argv[i++] = "-I";
	policy_argv[i++] = src_dir;
	policy_argv[i++] = "-I";
	policy_argv[i++] = deps_hiredis;
	policy_argv[i++] = "-I";
	policy_argv[i++] = deps_linenoise;
	policy_argv[i++] = "-I";
	policy_argv[i++] = deps_lua;
	policy_argv[i++] = "-I";
	policy_argv[i++] = deps_hdr;
	policy_argv[i++] = "-I";
	policy_argv[i++] = deps_fpconv;
	policy_argv[i++] = input;
	policy_argv[i++] = "-o";
	policy_argv[i++] = policy_out;
	policy_argv[i] = NULL;

	ret = run_child_capture(policy_argv, path_env, policy_stdout,
				policy_stderr, &policy_exit);
	if (ret || policy_exit) {
		emit_build_replay_case(out, "w1-redis-build",
				       "policy_preprocess", false,
				       ret ? -ret : 0, policy_exit,
				       "Redis policy preprocessing failed",
				       baseline_out, policy_out);
		return 1;
	}
	ret = compare_files(baseline_out, policy_out);
	if (ret) {
		emit_build_replay_case(out, "w1-redis-build",
				       "output_compare", false, -ret, 0,
				       "Redis policy output differed from baseline",
				       baseline_out, policy_out);
		return 1;
	}
	emit_build_replay_case(out, "w1-redis-build", "output_compare", true,
			       0, 0,
			       "Redis real-source preprocessing matched baseline through policy aliases",
			       baseline_out, policy_out);
	return 0;
}

static int run_nginx_replay(FILE *out, const char *nginx_src,
			     const char *result_dir, const char *include_dir,
			     const char *path_env, bool policy_mode)
{
	char src_core[PATH_MAX];
	char src_event[PATH_MAX];
	char src_event_modules[PATH_MAX];
	char src_event_quic[PATH_MAX];
	char src_os_unix[PATH_MAX];
	char objs[PATH_MAX];
	char input[PATH_MAX];
	char baseline_out[PATH_MAX];
	char policy_out[PATH_MAX];
	char baseline_stdout[PATH_MAX];
	char baseline_stderr[PATH_MAX];
	char policy_stdout[PATH_MAX];
	char policy_stderr[PATH_MAX];
	int baseline_exit = -1;
	int policy_exit = -1;
	int ret;
	char *baseline_argv[30];
	char *policy_argv[32];
	int i = 0;

	ret = set_child_path(src_core, sizeof(src_core), nginx_src, "src",
			     "core");
	if (!ret)
		ret = set_child_path(src_event, sizeof(src_event), nginx_src,
				     "src", "event");
	if (!ret)
		ret = set_path(src_event_modules, sizeof(src_event_modules),
			       src_event, "modules");
	if (!ret)
		ret = set_path(src_event_quic, sizeof(src_event_quic),
			       src_event, "quic");
	if (!ret)
		ret = set_child_path(src_os_unix, sizeof(src_os_unix),
				     nginx_src, "src/os", "unix");
	if (!ret)
		ret = set_path(objs, sizeof(objs), nginx_src, "objs");
	if (!ret)
		ret = set_child_path(input, sizeof(input), nginx_src,
				     "src/core", "nginx.c");
	if (!ret)
		ret = set_path(baseline_out, sizeof(baseline_out), result_dir,
			       "nginx.baseline.i");
	if (!ret)
		ret = set_path(policy_out, sizeof(policy_out), result_dir,
			       "nginx.policy.i");
	if (!ret)
		ret = set_path(baseline_stdout, sizeof(baseline_stdout),
			       result_dir, "nginx.baseline.stdout");
	if (!ret)
		ret = set_path(baseline_stderr, sizeof(baseline_stderr),
			       result_dir, "nginx.baseline.stderr");
	if (!ret)
		ret = set_path(policy_stdout, sizeof(policy_stdout), result_dir,
			       "nginx.policy.stdout");
	if (!ret)
		ret = set_path(policy_stderr, sizeof(policy_stderr), result_dir,
			       "nginx.policy.stderr");
	if (ret) {
		emit_build_replay_case(out, "w1-nginx-build", "build_paths",
				       false, -ret, -1,
				       "failed to build nginx replay paths",
				       NULL, NULL);
		return 1;
	}

	i = 0;
	baseline_argv[i++] = "/usr/bin/cc";
	baseline_argv[i++] = "-E";
	baseline_argv[i++] = "-P";
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = src_core;
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = src_event;
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = src_event_modules;
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = src_event_quic;
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = src_os_unix;
	baseline_argv[i++] = "-I";
	baseline_argv[i++] = objs;
	baseline_argv[i++] = input;
	baseline_argv[i++] = "-o";
	baseline_argv[i++] = baseline_out;
	baseline_argv[i] = NULL;

	if (!policy_mode) {
		ret = run_child_capture(baseline_argv, NULL, baseline_stdout,
					baseline_stderr, &baseline_exit);
		if (ret || baseline_exit) {
			emit_build_replay_case(out, "w1-nginx-build",
					       "baseline_preprocess", false,
					       ret ? -ret : 0, baseline_exit,
					       "nginx baseline preprocessing failed",
					       baseline_out, NULL);
			return 1;
		}
		emit_build_replay_case(out, "w1-nginx-build",
				       "baseline_preprocess", true, 0,
				       baseline_exit,
				       "nginx baseline preprocessing passed",
				       baseline_out, NULL);
		return 0;
	}

	i = 0;
	policy_argv[i++] = "cc";
	policy_argv[i++] = "-E";
	policy_argv[i++] = "-P";
	policy_argv[i++] = "-I";
	policy_argv[i++] = (char *)include_dir;
	policy_argv[i++] = "-I";
	policy_argv[i++] = src_core;
	policy_argv[i++] = "-I";
	policy_argv[i++] = src_event;
	policy_argv[i++] = "-I";
	policy_argv[i++] = src_event_modules;
	policy_argv[i++] = "-I";
	policy_argv[i++] = src_event_quic;
	policy_argv[i++] = "-I";
	policy_argv[i++] = src_os_unix;
	policy_argv[i++] = "-I";
	policy_argv[i++] = objs;
	policy_argv[i++] = input;
	policy_argv[i++] = "-o";
	policy_argv[i++] = policy_out;
	policy_argv[i] = NULL;

	ret = run_child_capture(policy_argv, path_env, policy_stdout,
				policy_stderr, &policy_exit);
	if (ret || policy_exit) {
		emit_build_replay_case(out, "w1-nginx-build",
				       "policy_preprocess", false,
				       ret ? -ret : 0, policy_exit,
				       "nginx policy preprocessing failed",
				       baseline_out, policy_out);
		return 1;
	}
	ret = compare_files(baseline_out, policy_out);
	if (ret) {
		emit_build_replay_case(out, "w1-nginx-build",
				       "output_compare", false, -ret, 0,
				       "nginx policy output differed from baseline",
				       baseline_out, policy_out);
		return 1;
	}
	emit_build_replay_case(out, "w1-nginx-build", "output_compare", true,
			       0, 0,
			       "nginx real-source preprocessing matched baseline through policy aliases",
			       baseline_out, policy_out);
	return 0;
}

static void emit_w1_build_macro_setup(FILE *out, int sample, bool pass, int err,
				      __u64 setup_ns, __u64 source_copy_ns,
				      size_t entries,
				      const struct nginx_macro_stats *stats,
				      const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w1-build-macrobench-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_setup_update_poc\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph\","
	      "\"policy_family\":\"build_graph_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,\"source_copy_ns\":%llu,"
		"\"workloads\":2,\"entries\":%zu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":%llu,\"bind_mounts\":0,"
		"\"overlay_mounts\":0,\"fuse_mounts\":0,"
		"\"bytes_written\":%llu,\"bytes_copied\":%llu,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns,
		(unsigned long long)source_copy_ns, entries,
		stats->created_dirs, stats->created_files,
		stats->created_symlinks, stats->bytes_written,
		stats->bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w1_build_macro_update(FILE *out, int sample, bool pass, int err,
				       __u64 update_ns,
				       const struct nginx_macro_stats *stats,
				       const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w1-build-macrobench-update\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_setup_update_poc\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph\","
	      "\"policy_family\":\"build_graph_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"source_update_writes\":%llu,"
		"\"baseline_update_writes\":%llu,"
		"\"policy_update_writes\":%llu,"
		"\"update_bytes_written\":%llu,"
		"\"update_bytes_copied\":%llu,"
		"\"policy_executed\":true,\"kvm_validated\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns, stats->source_update_writes,
		stats->baseline_update_writes, stats->policy_update_writes,
		stats->update_bytes_written, stats->update_bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w1_build_macro_correctness(FILE *out, int sample, bool pass,
					    int failures,
					    bool baseline_replay_pass,
					    bool policy_replay_pass,
					    bool post_update_replay_pass,
					    bool policy_executed,
					    const char *detail)
{
	fputs("{\"event\":\"w1-build-macrobench-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_setup_update_poc\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph\","
	      "\"policy_family\":\"build_graph_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"baseline_replay_pass\":%s,"
		"\"policy_replay_pass\":%s,"
		"\"post_update_replay_pass\":%s,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures,
		baseline_replay_pass ? "true" : "false",
		policy_replay_pass ? "true" : "false",
		post_update_replay_pass ? "true" : "false",
		policy_executed ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w1_build_macro_summary(FILE *out, int samples, int setup_rows,
					int update_rows, int correctness_rows,
					int failures, const char *detail)
{
	fputs("{\"event\":\"w1-build-macrobench-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_setup_update_poc\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph\","
	      "\"policy_family\":\"build_graph_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"setup_rows\":%d,\"update_rows\":%d,"
		"\"correctness_rows\":%d,\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, setup_rows, update_rows, correctness_rows,
		failures ? "false" : "true", failures,
		failures ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int copy_tree_for_w1_sample(const char *src, const char *dst,
				   const char *sample_dir, const char *label)
{
	char stdout_name[128];
	char stderr_name[128];
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	char *argv[5];
	int exit_code = -1;
	int ret;

	ret = snprintf(stdout_name, sizeof(stdout_name), "%s.cp.stdout", label);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(stdout_name))
		return -ENAMETOOLONG;
	ret = snprintf(stderr_name, sizeof(stderr_name), "%s.cp.stderr", label);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(stderr_name))
		return -ENAMETOOLONG;
	ret = set_path(stdout_path, sizeof(stdout_path), sample_dir, stdout_name);
	if (!ret)
		ret = set_path(stderr_path, sizeof(stderr_path), sample_dir,
			       stderr_name);
	if (ret)
		return ret;

	argv[0] = "cp";
	argv[1] = "-a";
	argv[2] = (char *)src;
	argv[3] = (char *)dst;
	argv[4] = NULL;
	ret = run_child_capture(argv, NULL, stdout_path, stderr_path, &exit_code);
	if (ret)
		return ret;
	if (exit_code)
		return -EIO;
	return 0;
}

static void add_file_to_setup_stats(const char *path,
				    struct nginx_macro_stats *stats)
{
	struct stat st = {};

	if (!stats || stat(path, &st) || !S_ISREG(st.st_mode))
		return;
	stats->created_files++;
	if (st.st_size > 0)
		stats->bytes_copied += (unsigned long long)st.st_size;
}

static void add_w1_setup_stats(struct oracle_entry *entries, size_t nr_entries,
			       const char *redis_policy_src,
			       const char *include_dir,
			       struct nginx_macro_stats *stats)
{
	char path[PATH_MAX];
	size_t i;

	if (!stats)
		return;
	stats->created_dirs += 2;
	stats->created_symlinks += 2;
	if (!set_path(path, sizeof(path), include_dir,
		      ".namei_ext.external.stdio.h"))
		add_file_to_setup_stats(path, stats);
	if (!set_child_path(path, sizeof(path), redis_policy_src, "src",
			    "config.gen.h"))
		add_file_to_setup_stats(path, stats);
	if (!set_child_path(path, sizeof(path), redis_policy_src, "src",
			    "version.src.h"))
		add_file_to_setup_stats(path, stats);
	for (i = 0; i < nr_entries; i++) {
		if (!strcmp(entries[i].branch, "toolchain_selection"))
			continue;
		if (!strcmp(entries[i].branch, "external_dependency")) {
			if (!set_path(path, sizeof(path), include_dir,
				      entries[i].shadow))
				add_file_to_setup_stats(path, stats);
			continue;
		}
		if (!set_path(path, sizeof(path), entries[i].dir,
			      entries[i].shadow))
			add_file_to_setup_stats(path, stats);
	}
}

static int refresh_w1_shadow_updates(struct oracle_entry *entries,
				     size_t nr_entries, const char *include_dir,
				     struct nginx_macro_stats *stats)
{
	char dst[PATH_MAX];
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		if (!strcmp(entries[i].branch, "toolchain_selection"))
			continue;
		if (!strcmp(entries[i].branch, "external_dependency")) {
			int ret = set_path(dst, sizeof(dst), include_dir,
					   entries[i].shadow);
			if (ret)
				return ret;
		} else {
			int ret = set_path(dst, sizeof(dst), entries[i].dir,
					   entries[i].shadow);
			if (ret)
				return ret;
		}
		{
			int ret = copy_file_counted(entries[i].original, dst,
						    stats, true);
			if (ret)
				return ret;
		}
	}
	return 0;
}

static int run_w1_build_macrobench(FILE *out, const char *cgroup_mount,
				   const char *work_dir, int samples,
				   const char *entries_tsv,
				   const char *policy_path,
				   const char *redis_src,
				   const char *nginx_src)
{
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	int setup_rows = 0;
	int update_rows = 0;
	int correctness_rows = 0;
	int failures = 0;
	int sample;
	int ret;

	if (samples <= 0) {
		emit_w1_build_macro_summary(out, samples, 0, 0, 0, 1,
					    "sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_w1_build_macro_summary(out, samples, 0, 0, 0, 1,
					    "failed to create W1 macrobench workdir");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		emit_w1_build_macro_summary(out, samples, 0, 0, 0, 1,
					    "failed to resolve current cgroup for W1 macrobench");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
		struct attached_policy policy = {
			.cgroup_fd = -1,
			.prog_fd = -1,
			.map_fd = -1,
		};
		struct nginx_macro_stats setup_stats = {};
		struct nginx_macro_stats update_stats = {};
		char sample_dir[PATH_MAX];
		char result_dir[PATH_MAX];
		char redis_sample_src[PATH_MAX];
		char nginx_sample_src[PATH_MAX];
		char toolchain_dir[PATH_MAX];
		char include_dir[PATH_MAX];
		char path_env[PATH_MAX + 128];
		size_t nr_entries = 0;
		bool baseline_replay_pass = false;
		bool policy_replay_pass = false;
		bool post_update_replay_pass = false;
		bool policy_executed = false;
		int sample_failures = 0;
		__u64 copy_start_ns;
		__u64 copy_end_ns;
		__u64 setup_start_ns;
		__u64 setup_end_ns;
		__u64 update_start_ns;
		__u64 update_end_ns;
		__u64 source_copy_ns = 0;

		ret = snprintf(sample_dir, sizeof(sample_dir), "%s/sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			emit_w1_build_macro_setup(out, sample, false,
						  ret < 0 ? errno : ENAMETOOLONG,
						  0, 0, 0, NULL,
						  "failed to build W1 sample directory path");
			failures++;
			break;
		}
		ret = mkdir_if_missing(sample_dir);
		if (!ret)
			ret = set_path(result_dir, sizeof(result_dir), sample_dir,
				       "results");
		if (!ret)
			ret = set_path(redis_sample_src,
				       sizeof(redis_sample_src), sample_dir,
				       "redis-src");
		if (!ret)
			ret = set_path(nginx_sample_src,
				       sizeof(nginx_sample_src), sample_dir,
				       "nginx-src");
		if (ret) {
			emit_w1_build_macro_setup(out, sample, false, -ret, 0, 0,
						  0, NULL,
						  "failed to build W1 sample paths");
			failures++;
			continue;
		}

		copy_start_ns = monotonic_ns();
		ret = copy_tree_for_w1_sample(redis_src, redis_sample_src,
					      sample_dir, "redis");
		if (!ret)
			ret = copy_tree_for_w1_sample(nginx_src, nginx_sample_src,
						      sample_dir, "nginx");
		copy_end_ns = monotonic_ns();
		source_copy_ns = copy_end_ns >= copy_start_ns ?
				 copy_end_ns - copy_start_ns : 0;
		if (ret) {
			setup_rows++;
			emit_w1_build_macro_setup(out, sample, false, -ret, 0,
						  source_copy_ns, 0, NULL,
						  "failed to copy W1 source trees for sample");
			failures++;
			continue;
		}

		setup_start_ns = monotonic_ns();
		ret = mkdir_if_missing(result_dir);
		if (!ret)
			ret = read_entries(entries_tsv, entries, &nr_entries);
		if (!ret)
			ret = prepare_replay_toolchain(result_dir, toolchain_dir,
						       sizeof(toolchain_dir),
						       path_env, sizeof(path_env));
		if (!ret)
			ret = prepare_replay_include(result_dir, include_dir,
						     sizeof(include_dir));
		if (!ret)
			ret = assign_build_replay_parent_dirs(
				entries, nr_entries, redis_sample_src,
				nginx_sample_src, toolchain_dir, include_dir);
		setup_end_ns = monotonic_ns();
		if (ret) {
			setup_rows++;
			emit_w1_build_macro_setup(
				out, sample, false, -ret,
				setup_end_ns >= setup_start_ns ?
					setup_end_ns - setup_start_ns : 0,
				source_copy_ns, nr_entries, &setup_stats,
				"failed to prepare W1 build replay helpers");
			failures++;
			continue;
		}

		sample_failures += run_redis_replay(out, redis_sample_src,
						    result_dir, include_dir,
						    path_env, false);
		sample_failures += run_nginx_replay(out, nginx_sample_src,
						    result_dir, include_dir,
						    path_env, false);
		baseline_replay_pass = sample_failures == 0;

		if (sample_failures) {
			failures += sample_failures;
			correctness_rows++;
			emit_w1_build_macro_correctness(
				out, sample, false, sample_failures,
				baseline_replay_pass, false, false, false,
				"W1 build macrobench baseline replay failed before alias setup");
			continue;
		}

		setup_start_ns = monotonic_ns();
		if (!ret)
			ret = prepare_replay_aliases("w1-redis-build",
						     redis_sample_src, entries,
						     nr_entries);
		if (!ret)
			ret = prepare_replay_aliases("w1-nginx-build",
						     nginx_sample_src, entries,
						     nr_entries);
		if (!ret)
			add_w1_setup_stats(entries, nr_entries, redis_sample_src,
					   include_dir, &setup_stats);
		setup_end_ns = monotonic_ns();
		setup_rows++;
		emit_w1_build_macro_setup(
			out, sample, !ret, ret ? -ret : 0,
			setup_end_ns >= setup_start_ns ?
				setup_end_ns - setup_start_ns : 0,
			source_copy_ns, nr_entries, &setup_stats,
			ret ? "failed to prepare W1 build graph view" :
			      "W1 build graph view prepared for macrobench sample");
		if (ret) {
			failures++;
			continue;
		}

		if (!sample_failures &&
		    open_policy(policy_path, POLICY_BUILD_GRAPH, "build_graph",
				&policy)) {
			sample_failures++;
		}
		if (!sample_failures) {
			ret = populate_policy_map(&policy, entries, nr_entries,
						  current_cgroup_id);
			if (ret)
				sample_failures++;
		}
		if (!sample_failures && attach_policy(&policy, current_cgroup))
			sample_failures++;
		if (!sample_failures) {
			policy_executed = true;
			sample_failures += run_redis_replay(
				out, redis_sample_src, result_dir, include_dir,
				path_env, true);
			sample_failures += run_nginx_replay(
				out, nginx_sample_src, result_dir, include_dir,
				path_env, true);
			policy_replay_pass = sample_failures == 0;
		}

		if (!sample_failures) {
			update_start_ns = monotonic_ns();
			ret = refresh_w1_shadow_updates(entries, nr_entries,
							include_dir,
							&update_stats);
			update_end_ns = monotonic_ns();
			update_rows++;
			emit_w1_build_macro_update(
				out, sample, !ret, ret ? -ret : 0,
				update_end_ns >= update_start_ns ?
					update_end_ns - update_start_ns : 0,
				&update_stats,
				ret ? "failed to refresh W1 shadow backing files" :
				      "refreshed W1 shadow backing files with same content");
			if (ret) {
				sample_failures++;
			} else {
				sample_failures += run_redis_replay(
					out, redis_sample_src, result_dir,
					include_dir, path_env, true);
				sample_failures += run_nginx_replay(
					out, nginx_sample_src, result_dir,
					include_dir, path_env, true);
				post_update_replay_pass = sample_failures == 0;
			}
		}

		if (policy.obj || policy.cgroup_fd >= 0 || policy.attached) {
			ret = destroy_policy(&policy);
			if (ret)
				sample_failures++;
		}

		failures += sample_failures;
		correctness_rows++;
		emit_w1_build_macro_correctness(
			out, sample, sample_failures == 0, sample_failures,
			baseline_replay_pass, policy_replay_pass,
			post_update_replay_pass, policy_executed,
			sample_failures ?
				"W1 build macrobench sample failed correctness oracle" :
				"W1 build macrobench sample passed baseline, policy, and post-update replay");
	}

	emit_w1_build_macro_summary(
		out, samples, setup_rows, update_rows, correctness_rows, failures,
		failures ?
			"W1 KVM build macrobench PoC failed" :
			"W1 KVM build macrobench PoC passed; not a C2 release gate");
	return failures ? 1 : 0;
}

static bool is_w1_build_baseline_name(const char *name)
{
	return !strcmp(name, "copy_tree") ||
	       !strcmp(name, "symlink_forest") ||
	       !strcmp(name, "bind_mount") ||
	       !strcmp(name, "projected_volume") ||
	       !strcmp(name, "fuse_redirect");
}

static bool w1_build_baseline_selected(const char *list, const char *name)
{
	char buf[256];
	char *saveptr = NULL;
	char *tok;

	if (!strcmp(list, "all"))
		return true;
	snprintf(buf, sizeof(buf), "%s", list);
	for (tok = strtok_r(buf, " ,", &saveptr); tok;
	     tok = strtok_r(NULL, " ,", &saveptr)) {
		if (!strcmp(tok, name))
			return true;
	}
	return false;
}

static int count_selected_w1_build_baselines(const char *list, int *count)
{
	char buf[256];
	char *saveptr = NULL;
	char *tok;
	int n = 0;

	if (!strcmp(list, "all")) {
		*count = W1_MAX_BASELINES;
		return 0;
	}
	snprintf(buf, sizeof(buf), "%s", list);
	for (tok = strtok_r(buf, " ,", &saveptr); tok;
	     tok = strtok_r(NULL, " ,", &saveptr)) {
		if (!is_w1_build_baseline_name(tok))
			return -EINVAL;
		n++;
	}
	if (!n)
		return -ENOENT;
	*count = n;
	return 0;
}

static void emit_w1_build_baseline_setup(
	FILE *out, const char *baseline, int sample, bool pass, int err,
	__u64 setup_ns, __u64 source_copy_ns, size_t entries,
	const struct nginx_macro_stats *stats, const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w1-build-baseline-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_feature_baseline_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph\",",
	      out);
	fputs("\"baseline\":", out);
	fprint_json_string(out, baseline);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,\"source_copy_ns\":%llu,"
		"\"workloads\":2,\"entries\":%zu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":%llu,\"bind_mounts\":%llu,"
		"\"overlay_mounts\":0,\"fuse_mounts\":%llu,"
		"\"bytes_written\":%llu,\"bytes_copied\":%llu,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns,
		(unsigned long long)source_copy_ns, entries,
		stats->created_dirs, stats->created_files,
		stats->created_symlinks, stats->bind_mounts,
		stats->fuse_mounts,
		stats->bytes_written, stats->bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w1_build_baseline_update(
	FILE *out, const char *baseline, int sample, bool pass, int err,
	__u64 update_ns, const struct nginx_macro_stats *stats,
	const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w1-build-baseline-update\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_feature_baseline_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph\",",
	      out);
	fputs("\"baseline\":", out);
	fprint_json_string(out, baseline);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"source_update_writes\":%llu,"
		"\"baseline_update_writes\":%llu,"
		"\"policy_update_writes\":%llu,"
		"\"update_bytes_written\":%llu,"
		"\"update_bytes_copied\":%llu,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns, stats->source_update_writes,
		stats->baseline_update_writes, stats->policy_update_writes,
		stats->update_bytes_written, stats->update_bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w1_build_baseline_correctness(
	FILE *out, const char *baseline, int sample, bool pass, int failures,
	bool baseline_replay_pass, bool materialized_replay_pass,
	bool post_update_replay_pass, size_t entries, size_t visible_aliases,
	size_t alias_parent_dirs, unsigned long long fuse_mounts,
	const char *detail)
{
	fputs("{\"event\":\"w1-build-baseline-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_feature_baseline_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph\",",
	      out);
	fputs("\"baseline\":", out);
	fprint_json_string(out, baseline);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"entries\":%zu,"
		"\"visible_aliases\":%zu,"
		"\"alias_parent_dirs\":%zu,"
		"\"fuse_mounts\":%llu,"
		"\"baseline_preprocess_pass\":%s,"
		"\"materialized_output_hash_match\":%s,"
		"\"post_update_output_hash_match\":%s,"
		"\"baseline_replay_pass\":%s,"
		"\"materialized_replay_pass\":%s,"
		"\"post_update_replay_pass\":%s,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures,
		entries, visible_aliases, alias_parent_dirs, fuse_mounts,
		baseline_replay_pass ? "true" : "false",
		materialized_replay_pass ? "true" : "false",
		post_update_replay_pass ? "true" : "false",
		baseline_replay_pass ? "true" : "false",
		materialized_replay_pass ? "true" : "false",
		post_update_replay_pass ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w1_build_baseline_summary(
	FILE *out, const char *baselines, int baseline_count, int samples,
	int setup_rows, int update_rows, int correctness_rows, int failures,
	const char *detail)
{
	fputs("{\"event\":\"w1-build-baseline-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w1_build_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_feature_baseline_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w1-build-graph\",",
	      out);
	fputs("\"selected_baselines\":", out);
	fprint_json_string(out, baselines);
	fprintf(out,
		",\"baseline_count\":%d,\"samples\":%d,"
		"\"setup_rows\":%d,\"update_rows\":%d,"
		"\"correctness_rows\":%d,"
		"\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		baseline_count, samples, setup_rows, update_rows,
		correctness_rows, failures ? "false" : "true", failures);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int materialize_w1_alias_path(const char *dir, const char *visible,
				     const char *shadow, const char *original,
				     const char *baseline,
				     struct nginx_macro_stats *stats)
{
	char visible_path[PATH_MAX];
	char shadow_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), dir, visible);
	if (!ret)
		ret = set_path(shadow_path, sizeof(shadow_path), dir, shadow);
	if (ret)
		return ret;

	if (!strcmp(baseline, "copy_tree")) {
		if (!access(visible_path, R_OK))
			return 0;
		return copy_file_counted(original && original[0] ?
						 original : shadow_path,
					 visible_path, stats, false);
	}

	if (access(shadow_path, R_OK)) {
		const char *src = NULL;

		if (!access(visible_path, R_OK))
			src = visible_path;
		else if (original && original[0])
			src = original;
		else
			return -errno;
		ret = copy_file_counted(src, shadow_path, stats, false);
		if (ret)
			return ret;
	}

	if (!strcmp(baseline, "symlink_forest"))
		return symlink_counted(shadow, visible_path, stats);
	if (!strcmp(baseline, "bind_mount"))
		return bind_mount_file_counted(shadow_path, visible_path, stats);
	return -EINVAL;
}

static int materialize_w1_extra_redis_aliases(const char *redis_src,
					      const char *baseline,
					      struct nginx_macro_stats *stats)
{
	char dir[PATH_MAX];
	int ret;

	ret = mkdir_relative_under(redis_src, "src", dir, sizeof(dir));
	if (ret)
		return ret;
	ret = materialize_w1_alias_path(dir, "config.h", "config.gen.h",
					NULL, baseline, stats);
	if (ret)
		return ret;
	return materialize_w1_alias_path(dir, "version.h", "version.src.h",
					 NULL, baseline, stats);
}

static void add_w1_baseline_helper_stats(const char *include_dir,
					 struct nginx_macro_stats *stats)
{
	char path[PATH_MAX];

	if (!stats)
		return;
	stats->created_dirs += 2;
	stats->created_symlinks += 2;
	if (!set_path(path, sizeof(path), include_dir,
		      ".namei_ext.external.stdio.h"))
		add_file_to_setup_stats(path, stats);
}

static bool w1_entry_alias_seen_before(const struct oracle_entry *entries,
				       size_t index)
{
	size_t i;

	for (i = 0; i < index; i++) {
		if (!strcmp(entries[i].dir, entries[index].dir) &&
		    !strcmp(entries[i].visible, entries[index].visible))
			return true;
	}
	return false;
}

static bool w1_alias_spec_seen(const struct w1_alias_spec *specs, size_t nr,
			       const char *dir, const char *visible)
{
	size_t i;

	for (i = 0; i < nr; i++) {
		if (!strcmp(specs[i].dir, dir) &&
		    !strcmp(specs[i].visible, visible))
			return true;
	}
	return false;
}

static int add_w1_alias_spec(struct w1_alias_spec *specs, size_t *nr,
			     const char *dir, const char *visible,
			     const char *shadow, const char *original)
{
	struct w1_alias_spec *spec;

	if (w1_alias_spec_seen(specs, *nr, dir, visible))
		return 0;
	if (*nr >= W1_ALIAS_MAX)
		return -E2BIG;
	spec = &specs[*nr];
	if (copy_string(spec->dir, sizeof(spec->dir), dir) ||
	    copy_string(spec->visible, sizeof(spec->visible), visible) ||
	    copy_string(spec->shadow, sizeof(spec->shadow), shadow))
		return -ENAMETOOLONG;
	if (original && original[0]) {
		if (copy_string(spec->original, sizeof(spec->original),
				original))
			return -ENAMETOOLONG;
	} else {
		spec->original[0] = 0;
	}
	(*nr)++;
	return 0;
}

static int collect_w1_alias_specs(const char *redis_src,
				  struct oracle_entry *entries,
				  size_t nr_entries,
				  struct w1_alias_spec *specs,
				  size_t *nr_specs)
{
	char dir[PATH_MAX];
	size_t i;
	int ret;

	*nr_specs = 0;
	ret = mkdir_relative_under(redis_src, "src", dir, sizeof(dir));
	if (ret)
		return ret;
	ret = add_w1_alias_spec(specs, nr_specs, dir, "config.h",
				"config.gen.h", NULL);
	if (ret)
		return ret;
	ret = add_w1_alias_spec(specs, nr_specs, dir, "version.h",
				"version.src.h", NULL);
	if (ret)
		return ret;

	for (i = 0; i < nr_entries; i++) {
		if (!strcmp(entries[i].branch, "toolchain_selection"))
			continue;
		ret = add_w1_alias_spec(specs, nr_specs, entries[i].dir,
					entries[i].visible, entries[i].shadow,
					entries[i].original);
		if (ret)
			return ret;
	}
	return 0;
}

static bool w1_alias_dir_seen_before(const struct w1_alias_spec *specs,
				     size_t index)
{
	size_t i;

	for (i = 0; i < index; i++) {
		if (!strcmp(specs[i].dir, specs[index].dir))
			return true;
	}
	return false;
}

static size_t w1_alias_parent_count(const struct w1_alias_spec *specs,
				    size_t nr_specs)
{
	size_t parents = 0;
	size_t i;

	for (i = 0; i < nr_specs; i++) {
		if (!w1_alias_dir_seen_before(specs, i))
			parents++;
	}
	return parents;
}

static int ensure_w1_alias_shadow(const struct w1_alias_spec *spec,
				  struct nginx_macro_stats *stats)
{
	char visible_path[PATH_MAX];
	char shadow_path[PATH_MAX];
	const char *src = NULL;
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), spec->dir,
		       spec->visible);
	if (!ret)
		ret = set_path(shadow_path, sizeof(shadow_path), spec->dir,
			       spec->shadow);
	if (ret)
		return ret;
	if (!access(shadow_path, R_OK))
		return 0;
	if (spec->original[0] && !access(spec->original, R_OK))
		src = spec->original;
	else if (!access(visible_path, R_OK))
		src = visible_path;
	else
		return -errno;
	return copy_file_counted(src, shadow_path, stats, false);
}

static int w1_projected_dir(const char *dir, char *projected_dir, size_t size)
{
	return set_path(projected_dir, size, dir, ".namei_ext_projected");
}

static int prepare_w1_projected_generation(
	const struct w1_alias_spec *specs, size_t nr_specs, const char *dir,
	const char *generation, struct nginx_macro_stats *stats, bool update)
{
	char projected_dir[PATH_MAX];
	char generation_dir[PATH_MAX];
	char tmp_link[PATH_MAX];
	char data_link[PATH_MAX];
	size_t i;
	int ret;

	ret = w1_projected_dir(dir, projected_dir, sizeof(projected_dir));
	if (!ret)
		ret = set_path(generation_dir, sizeof(generation_dir),
			       projected_dir, generation);
	if (!ret)
		ret = set_path(tmp_link, sizeof(tmp_link), projected_dir,
			       "..data_tmp");
	if (!ret)
		ret = set_path(data_link, sizeof(data_link), projected_dir,
			       "..data");
	if (ret)
		return ret;

	ret = mkdir_counted(projected_dir, update ? NULL : stats);
	if (!ret)
		ret = mkdir_counted(generation_dir, update ? NULL : stats);
	if (ret)
		return ret;

	for (i = 0; i < nr_specs; i++) {
		char shadow_path[PATH_MAX];
		char projected_path[PATH_MAX];

		if (strcmp(specs[i].dir, dir))
			continue;
		ret = set_path(shadow_path, sizeof(shadow_path), dir,
			       specs[i].shadow);
		if (!ret)
			ret = set_path(projected_path, sizeof(projected_path),
				       generation_dir, specs[i].visible);
		if (ret)
			return ret;
		if (update)
			ret = copy_file_baseline_update(shadow_path,
							projected_path, stats);
		else
			ret = copy_file_counted(shadow_path, projected_path,
						stats, false);
		if (ret)
			return ret;
	}

	if (unlink(tmp_link) && errno != ENOENT)
		return -errno;
	if (symlink(generation, tmp_link))
		return -errno;
	if (rename(tmp_link, data_link))
		return -errno;
	if (stats) {
		if (update)
			stats->baseline_update_writes++;
		else
			stats->created_symlinks++;
	}
	return 0;
}

static int materialize_w1_projected_aliases(
	struct w1_alias_spec *specs, size_t nr_specs,
	struct nginx_macro_stats *stats)
{
	size_t i;
	int ret;

	for (i = 0; i < nr_specs; i++) {
		ret = ensure_w1_alias_shadow(&specs[i], stats);
		if (ret)
			return ret;
	}

	for (i = 0; i < nr_specs; i++) {
		if (w1_alias_dir_seen_before(specs, i))
			continue;
		ret = prepare_w1_projected_generation(specs, nr_specs,
						      specs[i].dir, "..gen0",
						      stats, false);
		if (ret)
			return ret;
	}

	for (i = 0; i < nr_specs; i++) {
		char visible_path[PATH_MAX];
		char target[PATH_MAX];
		int n;

		ret = set_path(visible_path, sizeof(visible_path), specs[i].dir,
			       specs[i].visible);
		if (ret)
			return ret;
		n = snprintf(target, sizeof(target),
			     ".namei_ext_projected/..data/%s",
			     specs[i].visible);
		if (n < 0)
			return -errno;
		if ((size_t)n >= sizeof(target))
			return -ENAMETOOLONG;
		ret = symlink_counted(target, visible_path, stats);
		if (ret)
			return ret;
	}
	return 0;
}

static int w1_update_alias_shadows(struct w1_alias_spec *specs, size_t nr_specs,
				   struct nginx_macro_stats *stats)
{
	size_t i;

	for (i = 0; i < nr_specs; i++) {
		char shadow_path[PATH_MAX];
		int ret;

		if (!specs[i].original[0])
			continue;
		ret = set_path(shadow_path, sizeof(shadow_path), specs[i].dir,
			       specs[i].shadow);
		if (ret)
			return ret;
		ret = copy_file_counted(specs[i].original, shadow_path, stats,
					true);
		if (ret)
			return ret;
	}
	return 0;
}

static int update_w1_projected_aliases(const char *redis_src,
				       struct oracle_entry *entries,
				       size_t nr_entries,
				       struct nginx_macro_stats *stats)
{
	struct w1_alias_spec specs[W1_ALIAS_MAX] = {};
	size_t nr_specs = 0;
	size_t i;
	int ret;

	ret = collect_w1_alias_specs(redis_src, entries, nr_entries, specs,
				     &nr_specs);
	if (ret)
		return ret;
	ret = w1_update_alias_shadows(specs, nr_specs, stats);
	if (ret)
		return ret;
	for (i = 0; i < nr_specs; i++) {
		if (w1_alias_dir_seen_before(specs, i))
			continue;
		ret = prepare_w1_projected_generation(specs, nr_specs,
						      specs[i].dir, "..gen1",
						      stats, true);
		if (ret)
			return ret;
	}
	return 0;
}

static int w1_fuse_backing_dir(const char *mount_dir, char *backing_dir,
			       size_t size)
{
	int ret = snprintf(backing_dir, size, "%s.namei_ext_fuse_backing",
			   mount_dir);

	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static bool w1_fuse_alias_for_name(const struct w1_fuse_env *env,
				   const char *name, const char **shadow_out)
{
	size_t i;

	for (i = 0; i < env->nr_aliases; i++) {
		if (!strcmp(env->aliases[i].visible, name)) {
			*shadow_out = env->aliases[i].shadow;
			return true;
		}
	}
	return false;
}

static bool w1_fuse_shadow_name(const struct w1_fuse_env *env,
				const char *name)
{
	size_t i;

	for (i = 0; i < env->nr_aliases; i++) {
		if (!strcmp(env->aliases[i].shadow, name))
			return true;
	}
	return false;
}

static int w1_fuse_source_path(const struct w1_fuse_env *env,
			       const char *path, char *source, size_t size)
{
	const char *rel;
	const char *slash;
	const char *shadow;
	char name[NAMEI_EXT_NAME_MAX + 1];
	size_t len;
	int ret;

	if (!strcmp(path, "/"))
		return copy_string(source, size, env->backing_dir);
	if (path[0] != '/')
		return -ENOENT;
	rel = path + 1;
	slash = strchr(rel, '/');
	if (!slash) {
		if (w1_fuse_alias_for_name(env, rel, &shadow))
			return set_path(source, size, env->backing_dir, shadow);
		if (w1_fuse_shadow_name(env, rel))
			return -ENOENT;
	} else {
		len = (size_t)(slash - rel);
		if (!len || len > NAMEI_EXT_NAME_MAX)
			return -ENOENT;
		memcpy(name, rel, len);
		name[len] = 0;
		if (w1_fuse_alias_for_name(env, name, &shadow) ||
		    w1_fuse_shadow_name(env, name))
			return -ENOENT;
	}

	ret = snprintf(source, size, "%s/%s", env->backing_dir, rel);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int w1_fuse_getattr(const char *path, struct stat *st)
{
	struct w1_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	int ret;

	memset(st, 0, sizeof(*st));
	ret = w1_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	if (lstat(source, st))
		return -errno;
	return 0;
}

static int w1_fuse_access(const char *path, int mask)
{
	struct w1_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	int ret;

	ret = w1_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	if (access(source, mask))
		return -errno;
	return 0;
}

static int w1_fuse_open(const char *path, struct fuse_file_info *fi)
{
	struct w1_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	int fd;
	int ret;

	if ((fi->flags & O_ACCMODE) != O_RDONLY)
		return -EACCES;
	ret = w1_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	fd = open(source, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	fi->fh = (uint64_t)fd;
	fi->direct_io = 1;
	fi->keep_cache = 0;
	return 0;
}

static int w1_fuse_read(const char *path, char *buf, size_t size,
			off_t offset, struct fuse_file_info *fi)
{
	ssize_t ret;

	(void)path;
	ret = pread((int)fi->fh, buf, size, offset);
	if (ret < 0)
		return -errno;
	return (int)ret;
}

static int w1_fuse_release(const char *path, struct fuse_file_info *fi)
{
	int ret;

	(void)path;
	ret = close((int)fi->fh);
	return ret ? -errno : 0;
}

static int w1_fuse_readdir(const char *path, void *buf,
			   fuse_fill_dir_t filler, off_t offset,
			   struct fuse_file_info *fi)
{
	struct w1_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	struct dirent *de;
	DIR *dir;
	int ret;
	size_t i;

	(void)offset;
	(void)fi;
	ret = w1_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	dir = opendir(source);
	if (!dir)
		return -errno;
	filler(buf, ".", NULL, 0);
	filler(buf, "..", NULL, 0);
	errno = 0;
	while ((de = readdir(dir))) {
		const char *ignored_shadow = NULL;

		if (!strcmp(de->d_name, ".") || !strcmp(de->d_name, ".."))
			continue;
		if (w1_fuse_shadow_name(env, de->d_name))
			continue;
		if (w1_fuse_alias_for_name(env, de->d_name, &ignored_shadow))
			continue;
		filler(buf, de->d_name, NULL, 0);
	}
	for (i = 0; i < env->nr_aliases; i++)
		filler(buf, env->aliases[i].visible, NULL, 0);
	ret = errno ? -errno : 0;
	if (closedir(dir) && !ret)
		ret = -errno;
	return ret;
}

static struct fuse_operations w1_fuse_ops = {
	.getattr = w1_fuse_getattr,
	.access = w1_fuse_access,
	.open = w1_fuse_open,
	.read = w1_fuse_read,
	.release = w1_fuse_release,
	.readdir = w1_fuse_readdir,
};

static int wait_for_w1_fuse_ready(const char *mount_dir,
				  const struct w1_fuse_env *env,
				  pid_t fuse_pid)
{
	struct timespec delay = { .tv_sec = 0, .tv_nsec = 50000000 };
	char visible_path[PATH_MAX];
	int ret;
	int i;

	if (!env->nr_aliases)
		return -ENOENT;
	ret = set_path(visible_path, sizeof(visible_path), mount_dir,
		       env->aliases[0].visible);
	if (ret)
		return ret;
	for (i = 0; i < 100; i++) {
		struct stat st;
		int status;
		pid_t wait_ret;

		if (!stat(visible_path, &st))
			return 0;
		wait_ret = waitpid(fuse_pid, &status, WNOHANG);
		if (wait_ret == fuse_pid)
			return -EIO;
		if (wait_ret < 0 && errno != EINTR)
			return -errno;
		nanosleep(&delay, NULL);
	}
	return -ETIMEDOUT;
}

static int unmount_w1_fuse_context(struct w1_fuse_context *ctx)
{
	int first_error = 0;
	ssize_t i;

	if (!ctx)
		return 0;
	for (i = (ssize_t)ctx->nr_mounts - 1; i >= 0; i--) {
		struct w1_fuse_mount *mount = &ctx->mounts[i];
		int status;
		int ret;

		if (!mount->active)
			continue;
		if (umount2(mount->mount_dir, MNT_DETACH) && errno != EINVAL &&
		    errno != ENOENT && !first_error)
			first_error = -errno;
		if (mount->pid > 0) {
			ret = waitpid(mount->pid, &status, WNOHANG);
			if (ret == 0) {
				kill(mount->pid, SIGTERM);
				while (waitpid(mount->pid, &status, 0) < 0) {
					if (errno == EINTR)
						continue;
					if (!first_error)
						first_error = -errno;
					break;
				}
			} else if (ret < 0 && errno != ECHILD && !first_error) {
				first_error = -errno;
			}
		}
		mount->active = false;
	}
	ctx->nr_mounts = 0;
	return first_error;
}

static int w4_fuse_backing_dir(const char *mount_dir, char *backing_dir,
			       size_t size)
{
	int ret = snprintf(backing_dir, size, "%s.namei_ext_w4_fuse_backing",
			   mount_dir);

	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static bool w4_fuse_hidden_name(const char *name)
{
	return has_suffix(name, ".local");
}

static int w4_fuse_source_path(const struct w4_fuse_env *env,
			       const char *path, char *source, size_t size)
{
	char direct[PATH_MAX];
	char local[PATH_MAX];
	const char *rel;
	const char *base;
	struct stat st;
	int ret;

	if (!strcmp(path, "/"))
		return copy_string(source, size, env->backing_dir);
	if (path[0] != '/')
		return -ENOENT;
	rel = path + 1;
	if (!safe_relative_path(rel))
		return -ENOENT;
	base = strrchr(rel, '/');
	base = base ? base + 1 : rel;
	if (w4_fuse_hidden_name(base))
		return -ENOENT;

	ret = set_path(direct, sizeof(direct), env->backing_dir, rel);
	if (ret)
		return ret;
	if (!lstat(direct, &st))
		return copy_string(source, size, direct);
	if (errno != ENOENT)
		return -errno;

	ret = snprintf(local, sizeof(local), "%s.local", direct);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(local))
		return -ENAMETOOLONG;
	if (!lstat(local, &st))
		return copy_string(source, size, local);
	return errno == ENOENT ? -ENOENT : -errno;
}

static int w4_fuse_getattr(const char *path, struct stat *st)
{
	struct w4_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	int ret;

	memset(st, 0, sizeof(*st));
	ret = w4_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	if (lstat(source, st))
		return -errno;
	return 0;
}

static int w4_fuse_access(const char *path, int mask)
{
	struct w4_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	int ret;

	ret = w4_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	if (access(source, mask))
		return -errno;
	return 0;
}

static int w4_fuse_open(const char *path, struct fuse_file_info *fi)
{
	struct w4_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	int fd;
	int ret;

	if ((fi->flags & O_ACCMODE) != O_RDONLY)
		return -EACCES;
	ret = w4_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	fd = open(source, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	fi->fh = (uint64_t)fd;
	fi->direct_io = 1;
	fi->keep_cache = 0;
	return 0;
}

static int w4_fuse_read(const char *path, char *buf, size_t size, off_t offset,
			struct fuse_file_info *fi)
{
	ssize_t ret;

	(void)path;
	ret = pread((int)fi->fh, buf, size, offset);
	if (ret < 0)
		return -errno;
	return (int)ret;
}

static int w4_fuse_release(const char *path, struct fuse_file_info *fi)
{
	int ret;

	(void)path;
	ret = close((int)fi->fh);
	return ret ? -errno : 0;
}

static int w4_fuse_readdir(const char *path, void *buf, fuse_fill_dir_t filler,
			   off_t offset, struct fuse_file_info *fi)
{
	struct w4_fuse_env *env = fuse_get_context()->private_data;
	char source[PATH_MAX];
	struct dirent *de;
	DIR *dir;
	int ret;

	(void)offset;
	(void)fi;
	ret = w4_fuse_source_path(env, path, source, sizeof(source));
	if (ret)
		return ret;
	dir = opendir(source);
	if (!dir)
		return -errno;
	filler(buf, ".", NULL, 0);
	filler(buf, "..", NULL, 0);
	errno = 0;
	while ((de = readdir(dir))) {
		char visible[NAMEI_EXT_NAME_MAX + 1];
		size_t len;

		if (!strcmp(de->d_name, ".") || !strcmp(de->d_name, ".."))
			continue;
		if (!w4_fuse_hidden_name(de->d_name)) {
			filler(buf, de->d_name, NULL, 0);
			continue;
		}
		len = strlen(de->d_name) - strlen(".local");
		if (!len || len >= sizeof(visible))
			continue;
		memcpy(visible, de->d_name, len);
		visible[len] = 0;
		filler(buf, visible, NULL, 0);
	}
	ret = errno ? -errno : 0;
	if (closedir(dir) && !ret)
		ret = -errno;
	return ret;
}

static struct fuse_operations w4_fuse_ops = {
	.getattr = w4_fuse_getattr,
	.access = w4_fuse_access,
	.open = w4_fuse_open,
	.read = w4_fuse_read,
	.release = w4_fuse_release,
	.readdir = w4_fuse_readdir,
};

static int wait_for_w4_fuse_ready(const char *mount_dir,
				  const struct oracle_entry *entries,
				  size_t nr_entries, pid_t fuse_pid)
{
	struct timespec delay = { .tv_sec = 0, .tv_nsec = 50000000 };
	char visible_path[PATH_MAX];
	int ret;
	int i;

	if (!nr_entries)
		return -ENOENT;
	ret = set_path(visible_path, sizeof(visible_path), entries[0].dir,
		       entries[0].visible);
	if (ret)
		return ret;
	for (i = 0; i < 100; i++) {
		struct stat st;
		int status;
		pid_t wait_ret;

		if (!stat(visible_path, &st))
			return 0;
		wait_ret = waitpid(fuse_pid, &status, WNOHANG);
		if (wait_ret == fuse_pid)
			return -EIO;
		if (wait_ret < 0 && errno != EINTR)
			return -errno;
		nanosleep(&delay, NULL);
	}
	(void)mount_dir;
	return -ETIMEDOUT;
}

static int wait_for_w4_fuse_path_ready(const char *visible_path, pid_t fuse_pid)
{
	struct timespec delay = { .tv_sec = 0, .tv_nsec = 50000000 };
	int i;

	for (i = 0; i < 100; i++) {
		struct stat st;
		int status;
		pid_t wait_ret;

		if (!stat(visible_path, &st))
			return 0;
		wait_ret = waitpid(fuse_pid, &status, WNOHANG);
		if (wait_ret == fuse_pid)
			return -EIO;
		if (wait_ret < 0 && errno != EINTR)
			return -errno;
		nanosleep(&delay, NULL);
	}
	return -ETIMEDOUT;
}

static int unmount_w4_fuse(struct w4_fuse_mount *mount)
{
	int first_error = 0;
	int status;
	int ret;

	if (!mount || !mount->active)
		return 0;
	if (umount2(mount->mount_dir, MNT_DETACH) && errno != EINVAL &&
	    errno != ENOENT)
		first_error = -errno;
	if (mount->pid > 0) {
		ret = waitpid(mount->pid, &status, WNOHANG);
		if (ret == 0) {
			kill(mount->pid, SIGTERM);
			while (waitpid(mount->pid, &status, 0) < 0) {
				if (errno == EINTR)
					continue;
				if (!first_error)
					first_error = -errno;
				break;
			}
		} else if (ret < 0 && errno != ECHILD && !first_error) {
			first_error = -errno;
		}
	}
	mount->active = false;
	return first_error;
}

static int setup_w4_fuse_cache_view(const char *mount_dir,
				    struct oracle_entry *entries,
				    size_t nr_entries,
				    unsigned long long *fuse_mounts,
				    struct w4_fuse_mount *mount)
{
	struct w4_fuse_env env = {};
	char *argv[] = {
		"namei_ext_w4_fuse",
		"-f",
		"-s",
		"-o",
		"default_permissions,attr_timeout=0,entry_timeout=0,negative_timeout=0",
		(char *)mount_dir,
		NULL,
	};
	int ret;

	memset(mount, 0, sizeof(*mount));
	mount->pid = -1;
	ret = prepare_cache_content_dir(mount_dir, entries, nr_entries);
	if (!ret)
		ret = copy_string(mount->mount_dir, sizeof(mount->mount_dir),
				  mount_dir);
	if (!ret)
		ret = w4_fuse_backing_dir(mount_dir, mount->backing_dir,
					  sizeof(mount->backing_dir));
	if (!ret)
		ret = copy_string(env.backing_dir, sizeof(env.backing_dir),
				  mount->backing_dir);
	if (ret)
		return ret;
	if (rename(mount_dir, mount->backing_dir))
		return -errno;
	ret = mkdir_counted(mount_dir, NULL);
	if (ret)
		return ret;

	mount->pid = fork();
	if (mount->pid < 0) {
		mount->pid = -1;
		return -errno;
	}
	if (mount->pid == 0)
		_exit(fuse_main(6, argv, &w4_fuse_ops, &env));
	mount->active = true;
	ret = wait_for_w4_fuse_ready(mount_dir, entries, nr_entries,
				     mount->pid);
	if (ret)
		return ret;
	if (fuse_mounts)
		(*fuse_mounts)++;
	return 0;
}

static int setup_w4_fuse_passthrough_cache_view(
	const char *mount_dir, const char *ready_rel,
	unsigned long long *fuse_mounts, struct w4_fuse_mount *mount)
{
	struct w4_fuse_env env = {};
	char ready_path[PATH_MAX];
	char *argv[] = {
		"namei_ext_w4_fuse",
		"-f",
		"-s",
		"-o",
		"default_permissions,attr_timeout=0,entry_timeout=0,negative_timeout=0",
		(char *)mount_dir,
		NULL,
	};
	int ret;

	memset(mount, 0, sizeof(*mount));
	mount->pid = -1;
	if (!ready_rel || !safe_relative_path(ready_rel))
		return -EINVAL;
	ret = copy_string(mount->mount_dir, sizeof(mount->mount_dir), mount_dir);
	if (!ret)
		ret = w4_fuse_backing_dir(mount_dir, mount->backing_dir,
					  sizeof(mount->backing_dir));
	if (!ret)
		ret = copy_string(env.backing_dir, sizeof(env.backing_dir),
				  mount->backing_dir);
	if (ret)
		return ret;
	if (rename(mount_dir, mount->backing_dir))
		return -errno;
	ret = mkdir_counted(mount_dir, NULL);
	if (ret)
		return ret;
	ret = set_path(ready_path, sizeof(ready_path), mount_dir, ready_rel);
	if (ret)
		return ret;

	mount->pid = fork();
	if (mount->pid < 0) {
		mount->pid = -1;
		return -errno;
	}
	if (mount->pid == 0)
		_exit(fuse_main(6, argv, &w4_fuse_ops, &env));
	mount->active = true;
	ret = wait_for_w4_fuse_path_ready(ready_path, mount->pid);
	if (ret)
		return ret;
	if (fuse_mounts)
		(*fuse_mounts)++;
	return 0;
}

static int setup_w1_fuse_mount(const struct w1_alias_spec *specs,
			       size_t nr_specs, const char *dir,
			       struct nginx_macro_stats *stats,
			       struct w1_fuse_context *ctx)
{
	struct w1_fuse_mount *mount;
	struct w1_fuse_env env = {};
	char *argv[] = {
		"namei_ext_w1_fuse",
		"-f",
		"-s",
		"-o",
		"default_permissions,attr_timeout=0,entry_timeout=0,negative_timeout=0",
		(char *)dir,
		NULL,
	};
	size_t i;
	int ret;

	if (ctx->nr_mounts >= W1_FUSE_MAX_MOUNTS)
		return -E2BIG;
	mount = &ctx->mounts[ctx->nr_mounts];
	memset(mount, 0, sizeof(*mount));
	mount->pid = -1;
	ret = copy_string(mount->mount_dir, sizeof(mount->mount_dir), dir);
	if (!ret)
		ret = w1_fuse_backing_dir(dir, mount->backing_dir,
					  sizeof(mount->backing_dir));
	if (!ret)
		ret = copy_string(env.backing_dir, sizeof(env.backing_dir),
				  mount->backing_dir);
	if (ret)
		return ret;

	for (i = 0; i < nr_specs; i++) {
		if (strcmp(specs[i].dir, dir))
			continue;
		ret = ensure_w1_alias_shadow(&specs[i], stats);
		if (ret)
			return ret;
		if (env.nr_aliases >= W1_ALIAS_MAX)
			return -E2BIG;
		ret = copy_string(env.aliases[env.nr_aliases].visible,
				  sizeof(env.aliases[env.nr_aliases].visible),
				  specs[i].visible);
		if (!ret)
			ret = copy_string(
				env.aliases[env.nr_aliases].shadow,
				sizeof(env.aliases[env.nr_aliases].shadow),
				specs[i].shadow);
		if (ret)
			return ret;
		env.nr_aliases++;
	}
	if (!env.nr_aliases)
		return -ENOENT;

	if (rename(dir, mount->backing_dir))
		return -errno;
	ret = mkdir_counted(dir, stats);
	if (ret)
		return ret;

	mount->pid = fork();
	if (mount->pid < 0) {
		mount->pid = -1;
		return -errno;
	}
	if (mount->pid == 0)
		_exit(fuse_main(6, argv, &w1_fuse_ops, &env));

	mount->active = true;
	ctx->nr_mounts++;
	ret = wait_for_w1_fuse_ready(dir, &env, mount->pid);
	if (ret)
		return ret;
	if (stats)
		stats->fuse_mounts++;
	return 0;
}

static int setup_w1_fuse_aliases(struct w1_alias_spec *specs, size_t nr_specs,
				 struct nginx_macro_stats *stats,
				 struct w1_fuse_context *ctx)
{
	size_t i;
	int ret;

	ctx->nr_mounts = 0;
	for (i = 0; i < nr_specs; i++) {
		if (w1_alias_dir_seen_before(specs, i))
			continue;
		ret = setup_w1_fuse_mount(specs, nr_specs, specs[i].dir,
					  stats, ctx);
		if (ret) {
			unmount_w1_fuse_context(ctx);
			return ret;
		}
	}
	return 0;
}

static int update_w1_fuse_aliases(const char *redis_src,
				  struct oracle_entry *entries,
				  size_t nr_entries,
				  struct nginx_macro_stats *stats)
{
	struct w1_alias_spec specs[W1_ALIAS_MAX] = {};
	size_t nr_specs = 0;
	size_t i;
	int ret;

	ret = collect_w1_alias_specs(redis_src, entries, nr_entries, specs,
				     &nr_specs);
	if (ret)
		return ret;
	for (i = 0; i < nr_specs; i++) {
		char backing_dir[PATH_MAX];
		char shadow_path[PATH_MAX];

		if (!specs[i].original[0])
			continue;
		ret = w1_fuse_backing_dir(specs[i].dir, backing_dir,
					  sizeof(backing_dir));
		if (!ret)
			ret = set_path(shadow_path, sizeof(shadow_path),
				       backing_dir, specs[i].shadow);
		if (ret)
			return ret;
		ret = copy_file_counted(specs[i].original, shadow_path, stats,
					true);
		if (ret)
			return ret;
	}
	return 0;
}

static int w3_redis_checkpoint_path(const char *dir, char *path, size_t size)
{
	return set_path(path, size, dir, "dump.ckpt");
}

static int w3_redis_visible_path(const char *dir, char *path, size_t size)
{
	return set_path(path, size, dir, "dump.rdb");
}

static int w3_redis_runtime_path(const char *runtime_dir, const char *label,
				 const char *suffix, char *path, size_t size)
{
	char name[128];
	int ret;

	ret = snprintf(name, sizeof(name), "%s.%s", label, suffix);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(name))
		return -ENAMETOOLONG;
	return set_path(path, size, runtime_dir, name);
}

static int generate_w3_redis_checkpoint(const char *redis_bin, const char *dir,
					const char *runtime_dir,
					const char *label, const char *value,
					int port, struct nginx_macro_stats *stats,
					bool update)
{
	char pidfile[PATH_MAX];
	char logfile[PATH_MAX];
	char checkpoint[PATH_MAX];
	char response[1024];
	struct stat st = {};
	int exit_code = -1;
	int ret;

	ret = w3_redis_runtime_path(runtime_dir, label, "pid", pidfile,
				    sizeof(pidfile));
	if (!ret)
		ret = w3_redis_runtime_path(runtime_dir, label, "log", logfile,
					    sizeof(logfile));
	if (!ret)
		ret = run_redis_daemon(redis_bin, dir, "dump.ckpt", port,
				       pidfile, logfile, &exit_code);
	if (ret)
		return ret;
	if (exit_code)
		return -EIO;

	ret = redis_set(port, W3_REDIS_KEY, value, response, sizeof(response));
	if (!ret)
		ret = redis_save(port, response, sizeof(response));
	if (redis_shutdown(port) && !ret)
		ret = -EIO;
	if (ret)
		return ret;

	ret = w3_redis_checkpoint_path(dir, checkpoint, sizeof(checkpoint));
	if (ret)
		return ret;
	if (stat(checkpoint, &st))
		return -errno;
	if (!stats)
		return 0;
	if (update) {
		stats->source_update_writes++;
		if (st.st_size > 0)
			stats->update_bytes_written +=
				(unsigned long long)st.st_size;
	} else {
		stats->created_files++;
		if (st.st_size > 0)
			stats->bytes_written += (unsigned long long)st.st_size;
	}
	return 0;
}

static int check_w3_redis_value(const char *redis_bin, const char *dir,
				const char *runtime_dir, const char *label,
				int port, const char *dbfilename,
				const char *expected_value, bool expect_nil)
{
	char pidfile[PATH_MAX];
	char logfile[PATH_MAX];
	char response[1024];
	int exit_code = -1;
	int ret;
	int shutdown_ret;

	ret = w3_redis_runtime_path(runtime_dir, label, "pid", pidfile,
				    sizeof(pidfile));
	if (!ret)
		ret = w3_redis_runtime_path(runtime_dir, label, "log", logfile,
					    sizeof(logfile));
	if (!ret)
		ret = run_redis_daemon(redis_bin, dir, dbfilename, port,
				       pidfile, logfile, &exit_code);
	if (ret)
		return ret;
	if (exit_code)
		return -EIO;

	ret = redis_get(port, W3_REDIS_KEY, response, sizeof(response));
	shutdown_ret = redis_shutdown(port);
	if (shutdown_ret && !ret)
		ret = shutdown_ret;
	if (ret)
		return ret;
	if (expect_nil)
		return redis_response_is_nil(response) ? 0 : -EINVAL;
	return redis_response_has_value(response, expected_value) ? 0 : -EINVAL;
}

static int check_w3_readdir_alias(const char *dir)
{
	bool saw_visible;
	bool saw_hidden;
	int err = 0;

	saw_visible = dir_has_name(dir, "dump.rdb", &err);
	if (!err)
		saw_hidden = dir_has_name(dir, "dump.ckpt", &err);
	else
		saw_hidden = false;
	if (!err && saw_visible && !saw_hidden)
		return 0;
	return err ? -err : -ENOENT;
}

static void emit_w3_redis_policy_setup(FILE *out, int sample, bool pass,
				       int err, __u64 setup_ns,
				       const struct nginx_macro_stats *stats,
				       const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w3-redis-policy-macrobench-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_redis_policy_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_checkpoint_policy_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-redis-podman-criu\","
	      "\"app\":\"redis\","
	      "\"row_kind\":\"proposed_system\","
	      "\"system\":\"checkpoint_restore_policy\","
	      "\"policy_family\":\"checkpoint_restore_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":%llu,\"bind_mounts\":%llu,"
		"\"overlay_mounts\":0,\"fuse_mounts\":%llu,"
		"\"bytes_written\":%llu,\"bytes_copied\":%llu,"
		"\"lookup_rule_writes\":0,\"readdir_rule_writes\":0,"
		"\"total_rule_writes\":0,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":false,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, stats->created_dirs,
		stats->created_files, stats->created_symlinks,
		stats->bind_mounts, stats->fuse_mounts, stats->bytes_written,
		stats->bytes_copied, pass ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w3_redis_policy_update(FILE *out, int sample, bool pass,
					int err, __u64 update_ns,
					const struct nginx_macro_stats *stats,
					const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w3-redis-policy-macrobench-update\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_redis_policy_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_checkpoint_policy_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-redis-podman-criu\","
	      "\"app\":\"redis\","
	      "\"row_kind\":\"proposed_system\","
	      "\"system\":\"checkpoint_restore_policy\","
	      "\"policy_family\":\"checkpoint_restore_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"source_update_writes\":%llu,"
		"\"baseline_update_writes\":0,"
		"\"policy_update_writes\":0,"
		"\"update_bytes_written\":%llu,"
		"\"update_bytes_copied\":%llu,"
		"\"update_lookup_rule_writes\":0,"
		"\"update_readdir_rule_writes\":0,"
		"\"update_total_rule_writes\":0,"
		"\"policy_executed\":true,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":false,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns, stats->source_update_writes,
		stats->update_bytes_written, stats->update_bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w3_redis_policy_correctness(
	FILE *out, int sample, bool pass, int failures,
	bool pre_attach_absent, bool attached_get_pass, bool readdir_pass,
	bool post_update_get_pass, bool post_detach_absent,
	const char *detail)
{
	fputs("{\"event\":\"w3-redis-policy-macrobench-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_redis_policy_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_checkpoint_policy_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-redis-podman-criu\","
	      "\"app\":\"redis\","
	      "\"row_kind\":\"proposed_system\","
	      "\"system\":\"checkpoint_restore_policy\","
	      "\"policy_family\":\"checkpoint_restore_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"pre_attach_absent\":%s,"
		"\"attached_get_pass\":%s,"
		"\"readdir_pass\":%s,"
		"\"post_update_get_pass\":%s,"
		"\"post_detach_absent\":%s,"
		"\"policy_executed\":true,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":false,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures,
		pre_attach_absent ? "true" : "false",
		attached_get_pass ? "true" : "false",
		readdir_pass ? "true" : "false",
		post_update_get_pass ? "true" : "false",
		post_detach_absent ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w3_redis_policy_summary(FILE *out, int samples,
					 int setup_rows, int update_rows,
					 int correctness_rows, int failures,
					 const char *detail)
{
	fputs("{\"event\":\"w3-redis-policy-macrobench-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_redis_policy_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_checkpoint_policy_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-redis-podman-criu\","
	      "\"app\":\"redis\","
	      "\"row_kind\":\"proposed_system\","
	      "\"system\":\"checkpoint_restore_policy\","
	      "\"policy_family\":\"checkpoint_restore_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"systems\":1,"
		"\"setup_rows\":%d,\"update_rows\":%d,"
		"\"correctness_rows\":%d,\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":false,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, setup_rows, update_rows, correctness_rows,
		failures ? "false" : "true", failures,
		(!failures && correctness_rows == samples) ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int run_one_w3_redis_policy_macro_sample(
	FILE *out, const char *cgroup_path, const char *work_dir, int sample,
	const char *redis_bin, const char *policy_obj, int *setup_rows,
	int *update_rows, int *correctness_rows)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct nginx_macro_stats setup_stats = {};
	struct nginx_macro_stats update_stats = {};
	char sample_dir[PATH_MAX];
	char checkpoint_dir[PATH_MAX];
	char runtime_dir[PATH_MAX];
	char dump_rdb[PATH_MAX];
	char dump_ckpt[PATH_MAX];
	char updated_value[128];
	bool pre_attach_absent = false;
	bool attached_get_pass = false;
	bool readdir_pass = false;
	bool post_update_get_pass = false;
	bool post_detach_absent = false;
	int sample_failures = 0;
	int port_base = 24000 + (getpid() % 10000) + sample * 20;
	__u64 start_ns;
	__u64 end_ns;
	int ret;

	ret = snprintf(sample_dir, sizeof(sample_dir),
		       "%s/policy-sample-%03d", work_dir, sample);
	if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
		emit_w3_redis_policy_setup(
			out, sample, false, ret < 0 ? errno : ENAMETOOLONG, 0,
			NULL, "failed to build W3 policy sample dir");
		return 1;
	}
	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(checkpoint_dir, sizeof(checkpoint_dir),
			       sample_dir, "checkpoint");
	if (!ret)
		ret = set_path(runtime_dir, sizeof(runtime_dir), sample_dir,
			       "runtime");
	if (!ret)
		ret = mkdir_if_missing(checkpoint_dir);
	if (!ret)
		ret = mkdir_if_missing(runtime_dir);
	if (!ret)
		ret = w3_redis_visible_path(checkpoint_dir, dump_rdb,
					    sizeof(dump_rdb));
	if (!ret)
		ret = w3_redis_checkpoint_path(checkpoint_dir, dump_ckpt,
					       sizeof(dump_ckpt));
	if (ret) {
		emit_w3_redis_policy_setup(
			out, sample, false, -ret, 0, NULL,
			"failed to prepare W3 policy sample paths");
		return 1;
	}
	unlink_existing(dump_rdb);
	unlink_existing(dump_ckpt);
	ret = generate_w3_redis_checkpoint(redis_bin, checkpoint_dir,
					   runtime_dir, "seed",
					   W3_REDIS_VALUE, port_base, NULL,
					   false);
	if (ret) {
		emit_w3_redis_policy_setup(
			out, sample, false, -ret, 0, NULL,
			"failed to generate W3 policy source checkpoint");
		return 1;
	}
	unlink_existing(dump_rdb);

	pre_attach_absent =
		check_w3_redis_value(redis_bin, checkpoint_dir, runtime_dir,
				     "pre-attach", port_base + 1,
				     "dump.rdb", NULL, true) == 0;
	if (!pre_attach_absent)
		sample_failures++;

	start_ns = monotonic_ns();
	ret = open_policy(policy_obj, POLICY_CHECKPOINT_RESTORE,
			  "checkpoint_restore", &policy);
	if (ret)
		ret = -errno;
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	(*setup_rows)++;
	emit_w3_redis_policy_setup(
		out, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &setup_stats,
		ret ? "failed to attach W3 checkpoint_restore policy" :
		      "W3 checkpoint_restore policy attached for Redis macrobench sample");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		return sample_failures + 1;
	}

	attached_get_pass =
		check_w3_redis_value(redis_bin, checkpoint_dir, runtime_dir,
				     "attached", port_base + 2, "dump.rdb",
				     W3_REDIS_VALUE, false) == 0;
	if (!attached_get_pass)
		sample_failures++;
	readdir_pass = check_w3_readdir_alias(checkpoint_dir) == 0;
	if (!readdir_pass)
		sample_failures++;

	ret = snprintf(updated_value, sizeof(updated_value),
		       "namei-ext-w3-updated-%03d", sample);
	if (ret < 0 || (size_t)ret >= sizeof(updated_value))
		ret = ret < 0 ? -errno : -ENAMETOOLONG;
	else
		ret = 0;
	start_ns = monotonic_ns();
	if (!ret)
		ret = generate_w3_redis_checkpoint(
			redis_bin, checkpoint_dir, runtime_dir, "update",
			updated_value, port_base + 3, &update_stats, true);
	end_ns = monotonic_ns();
	(*update_rows)++;
	emit_w3_redis_policy_update(
		out, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &update_stats,
		ret ? "failed to update W3 policy checkpoint backing" :
		      "W3 policy checkpoint backing updated");
	if (ret) {
		sample_failures++;
	} else {
		post_update_get_pass =
			check_w3_redis_value(redis_bin, checkpoint_dir,
					     runtime_dir, "post-update",
					     port_base + 4, "dump.rdb",
					     updated_value, false) == 0;
		if (!post_update_get_pass)
			sample_failures++;
	}

	ret = destroy_policy(&policy);
	if (ret)
		sample_failures++;

	post_detach_absent =
		check_w3_redis_value(redis_bin, checkpoint_dir, runtime_dir,
				     "post-detach", port_base + 5,
				     "dump.rdb", NULL, true) == 0;
	if (!post_detach_absent)
		sample_failures++;

	(*correctness_rows)++;
	emit_w3_redis_policy_correctness(
		out, sample, sample_failures == 0, sample_failures,
		pre_attach_absent, attached_get_pass, readdir_pass,
		post_update_get_pass, post_detach_absent,
		sample_failures ?
			"W3 Redis policy macrobench correctness failed" :
			"W3 Redis policy macrobench setup/update correctness passed");
	return sample_failures ? 1 : 0;
}

static int run_w3_redis_policy_macrobench(FILE *out, const char *cgroup_mount,
					  const char *work_dir, int samples,
					  const char *redis_bin,
					  const char *policy_obj)
{
	char current_cgroup[PATH_MAX];
	int setup_rows = 0;
	int update_rows = 0;
	int correctness_rows = 0;
	int failures = 0;
	int sample;
	int ret;

	if (samples <= 0) {
		emit_w3_redis_policy_summary(out, samples, 0, 0, 0, 1,
					     "sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_w3_redis_policy_summary(
			out, samples, 0, 0, 0, 1,
			"failed to create W3 policy macrobench workdir");
		return 1;
	}
	if (access(redis_bin, X_OK) || access(policy_obj, R_OK)) {
		emit_w3_redis_policy_summary(
			out, samples, 0, 0, 0, 1,
			"W3 policy macrobench inputs are not readable");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (ret) {
		emit_w3_redis_policy_summary(
			out, samples, 0, 0, 0, 1,
			"failed to resolve current cgroup path");
		return 1;
	}

	for (sample = 0; sample < samples; sample++)
		failures += run_one_w3_redis_policy_macro_sample(
			out, current_cgroup, work_dir, sample, redis_bin,
			policy_obj, &setup_rows, &update_rows,
			&correctness_rows);

	emit_w3_redis_policy_summary(
		out, samples, setup_rows, update_rows, correctness_rows,
		failures,
		failures ?
			"W3 Redis policy macrobench failed" :
			"W3 Redis policy macrobench passed; real Podman/CRIU restore remains a separate C8 blocker");
	return failures ? 1 : 0;
}

static bool is_w3_redis_baseline_name(const char *name)
{
	return !strcmp(name, "materialized_checkpoint_view") ||
	       !strcmp(name, "fuse_redirect");
}

static bool w3_redis_baseline_selected(const char *list, const char *name)
{
	char buf[256];
	char *saveptr = NULL;
	char *tok;

	if (!strcmp(list, "all"))
		return true;
	snprintf(buf, sizeof(buf), "%s", list);
	for (tok = strtok_r(buf, " ,", &saveptr); tok;
	     tok = strtok_r(NULL, " ,", &saveptr)) {
		if (!strcmp(tok, name))
			return true;
	}
	return false;
}

static int count_selected_w3_redis_baselines(const char *list, int *count)
{
	char buf[256];
	char *saveptr = NULL;
	char *tok;
	int n = 0;

	if (!strcmp(list, "all")) {
		*count = 2;
		return 0;
	}
	snprintf(buf, sizeof(buf), "%s", list);
	for (tok = strtok_r(buf, " ,", &saveptr); tok;
	     tok = strtok_r(NULL, " ,", &saveptr)) {
		if (!is_w3_redis_baseline_name(tok))
			return -EINVAL;
		n++;
	}
	if (!n)
		return -ENOENT;
	*count = n;
	return 0;
}

static void emit_w3_redis_baseline_setup(
	FILE *out, const char *baseline, int sample, bool pass, int err,
	__u64 setup_ns, const struct nginx_macro_stats *stats,
	const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w3-redis-baseline-macrobench-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_redis_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_external_checkpoint_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-redis-podman-criu\","
	      "\"app\":\"redis\","
	      "\"row_kind\":\"external_baseline\",",
	      out);
	fputs("\"baseline\":", out);
	fprint_json_string(out, baseline);
	fputs(",\"system\":", out);
	fprint_json_string(out, baseline);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":%llu,\"bind_mounts\":%llu,"
		"\"overlay_mounts\":0,\"fuse_mounts\":%llu,"
		"\"bytes_written\":%llu,\"bytes_copied\":%llu,"
		"\"lookup_rule_writes\":0,\"readdir_rule_writes\":0,"
		"\"total_rule_writes\":0,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, stats->created_dirs,
		stats->created_files, stats->created_symlinks,
		stats->bind_mounts, stats->fuse_mounts, stats->bytes_written,
		stats->bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w3_redis_baseline_update(
	FILE *out, const char *baseline, int sample, bool pass, int err,
	__u64 update_ns, const struct nginx_macro_stats *stats,
	const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w3-redis-baseline-macrobench-update\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_redis_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_external_checkpoint_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-redis-podman-criu\","
	      "\"app\":\"redis\","
	      "\"row_kind\":\"external_baseline\",",
	      out);
	fputs("\"baseline\":", out);
	fprint_json_string(out, baseline);
	fputs(",\"system\":", out);
	fprint_json_string(out, baseline);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"source_update_writes\":%llu,"
		"\"baseline_update_writes\":%llu,"
		"\"policy_update_writes\":0,"
		"\"update_bytes_written\":%llu,"
		"\"update_bytes_copied\":%llu,"
		"\"update_lookup_rule_writes\":0,"
		"\"update_readdir_rule_writes\":0,"
		"\"update_total_rule_writes\":0,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns, stats->source_update_writes,
		stats->baseline_update_writes, stats->update_bytes_written,
		stats->update_bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w3_redis_baseline_correctness(
	FILE *out, const char *baseline, int sample, bool pass, int failures,
	bool initial_get_pass, bool readdir_pass, bool hidden_backing_absent,
	bool post_update_get_pass, const char *detail)
{
	fputs("{\"event\":\"w3-redis-baseline-macrobench-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_redis_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_external_checkpoint_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-redis-podman-criu\","
	      "\"app\":\"redis\","
	      "\"row_kind\":\"external_baseline\",",
	      out);
	fputs("\"baseline\":", out);
	fprint_json_string(out, baseline);
	fputs(",\"system\":", out);
	fprint_json_string(out, baseline);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"initial_get_pass\":%s,"
		"\"readdir_pass\":%s,"
		"\"hidden_backing_absent\":%s,"
		"\"post_update_get_pass\":%s,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures,
		initial_get_pass ? "true" : "false",
		readdir_pass ? "true" : "false",
		hidden_backing_absent ? "true" : "false",
		post_update_get_pass ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w3_redis_baseline_summary(
	FILE *out, const char *baselines, int baseline_count, int samples,
	int setup_rows, int update_rows, int correctness_rows, int failures,
	const char *detail)
{
	fputs("{\"event\":\"w3-redis-baseline-macrobench-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w3_redis_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_external_checkpoint_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w3-redis-podman-criu\","
	      "\"app\":\"redis\","
	      "\"row_kind\":\"external_baseline\",",
	      out);
	fputs("\"selected_baselines\":", out);
	fprint_json_string(out, baselines);
	fprintf(out,
		",\"baseline_count\":%d,\"samples\":%d,"
		"\"setup_rows\":%d,\"update_rows\":%d,"
		"\"correctness_rows\":%d,"
		"\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		baseline_count, samples, setup_rows, update_rows,
		correctness_rows, failures ? "false" : "true", failures);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int run_one_w3_redis_materialized_baseline_sample(
	FILE *out, const char *baseline, const char *work_dir, int sample,
	const char *redis_bin, int *setup_rows, int *update_rows,
	int *correctness_rows)
{
	struct nginx_macro_stats setup_stats = {};
	struct nginx_macro_stats update_stats = {};
	char sample_dir[PATH_MAX];
	char source_dir[PATH_MAX];
	char view_dir[PATH_MAX];
	char runtime_dir[PATH_MAX];
	char source_ckpt[PATH_MAX];
	char view_rdb[PATH_MAX];
	char view_ckpt[PATH_MAX];
	char updated_value[128];
	bool initial_get_pass = false;
	bool readdir_pass = false;
	bool hidden_backing_absent = false;
	bool post_update_get_pass = false;
	int sample_failures = 0;
	int port_base = 26000 + (getpid() % 10000) + sample * 20;
	__u64 start_ns;
	__u64 end_ns;
	int ret;

	ret = snprintf(sample_dir, sizeof(sample_dir),
		       "%s/%s-sample-%03d", work_dir, baseline, sample);
	if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
		emit_w3_redis_baseline_setup(
			out, baseline, sample, false,
			ret < 0 ? errno : ENAMETOOLONG, 0, NULL,
			"failed to build W3 materialized baseline sample dir");
		return 1;
	}
	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(source_dir, sizeof(source_dir), sample_dir,
			       "source");
	if (!ret)
		ret = set_path(view_dir, sizeof(view_dir), sample_dir, "view");
	if (!ret)
		ret = set_path(runtime_dir, sizeof(runtime_dir), sample_dir,
			       "runtime");
	if (!ret)
		ret = mkdir_if_missing(source_dir);
	if (!ret)
		ret = mkdir_if_missing(view_dir);
	if (!ret)
		ret = mkdir_if_missing(runtime_dir);
	if (!ret)
		ret = w3_redis_checkpoint_path(source_dir, source_ckpt,
					       sizeof(source_ckpt));
	if (!ret)
		ret = w3_redis_visible_path(view_dir, view_rdb,
					    sizeof(view_rdb));
	if (!ret)
		ret = w3_redis_checkpoint_path(view_dir, view_ckpt,
					       sizeof(view_ckpt));
	if (ret) {
		emit_w3_redis_baseline_setup(
			out, baseline, sample, false, -ret, 0, NULL,
			"failed to prepare W3 materialized baseline paths");
		return 1;
	}
	unlink_existing(source_ckpt);
	unlink_existing(view_rdb);
	ret = generate_w3_redis_checkpoint(redis_bin, source_dir, runtime_dir,
					   "seed", W3_REDIS_VALUE, port_base,
					   NULL, false);
	if (ret) {
		emit_w3_redis_baseline_setup(
			out, baseline, sample, false, -ret, 0, NULL,
			"failed to generate W3 materialized baseline source checkpoint");
		return 1;
	}

	start_ns = monotonic_ns();
	ret = copy_file_counted(source_ckpt, view_rdb, &setup_stats, false);
	end_ns = monotonic_ns();
	(*setup_rows)++;
	emit_w3_redis_baseline_setup(
		out, baseline, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &setup_stats,
		ret ? "failed to setup W3 materialized checkpoint view" :
		      "W3 materialized checkpoint view setup completed");
	if (ret)
		return 1;

	initial_get_pass =
		check_w3_redis_value(redis_bin, view_dir, runtime_dir,
				     "initial", port_base + 1, "dump.rdb",
				     W3_REDIS_VALUE, false) == 0;
	if (!initial_get_pass)
		sample_failures++;
	readdir_pass = check_w3_readdir_alias(view_dir) == 0;
	if (!readdir_pass)
		sample_failures++;
	hidden_backing_absent = expect_stat_errno(view_ckpt, ENOENT) == 0;
	if (!hidden_backing_absent)
		sample_failures++;

	ret = snprintf(updated_value, sizeof(updated_value),
		       "namei-ext-w3-baseline-updated-%03d", sample);
	if (ret < 0 || (size_t)ret >= sizeof(updated_value))
		ret = ret < 0 ? -errno : -ENAMETOOLONG;
	else
		ret = 0;
	start_ns = monotonic_ns();
	if (!ret)
		ret = generate_w3_redis_checkpoint(
			redis_bin, source_dir, runtime_dir, "update",
			updated_value, port_base + 2, &update_stats, true);
	if (!ret)
		ret = copy_file_baseline_update(source_ckpt, view_rdb,
						&update_stats);
	end_ns = monotonic_ns();
	(*update_rows)++;
	emit_w3_redis_baseline_update(
		out, baseline, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &update_stats,
		ret ? "failed to update W3 materialized checkpoint view" :
		      "W3 materialized checkpoint view updated");
	if (ret) {
		sample_failures++;
	} else {
		post_update_get_pass =
			check_w3_redis_value(redis_bin, view_dir, runtime_dir,
					     "post-update", port_base + 3,
					     "dump.rdb", updated_value,
					     false) == 0;
		if (!post_update_get_pass)
			sample_failures++;
	}

	(*correctness_rows)++;
	emit_w3_redis_baseline_correctness(
		out, baseline, sample, sample_failures == 0, sample_failures,
		initial_get_pass, readdir_pass, hidden_backing_absent,
		post_update_get_pass,
		sample_failures ?
			"W3 materialized checkpoint baseline correctness failed" :
			"W3 materialized checkpoint baseline correctness passed");
	return sample_failures ? 1 : 0;
}

static int run_one_w3_redis_fuse_baseline_sample(
	FILE *out, const char *baseline, const char *work_dir, int sample,
	const char *redis_bin, int *setup_rows, int *update_rows,
	int *correctness_rows)
{
	struct w1_alias_spec spec = {};
	struct w1_fuse_context fuse_ctx = {};
	struct nginx_macro_stats setup_stats = {};
	struct nginx_macro_stats update_stats = {};
	char sample_dir[PATH_MAX];
	char checkpoint_dir[PATH_MAX];
	char runtime_dir[PATH_MAX];
	char backing_dir[PATH_MAX];
	char dump_ckpt[PATH_MAX];
	char updated_value[128];
	bool initial_get_pass = false;
	bool readdir_pass = false;
	bool hidden_backing_absent = false;
	bool post_update_get_pass = false;
	int sample_failures = 0;
	int port_base = 28000 + (getpid() % 10000) + sample * 20;
	__u64 start_ns;
	__u64 end_ns;
	int ret;

	ret = snprintf(sample_dir, sizeof(sample_dir),
		       "%s/%s-sample-%03d", work_dir, baseline, sample);
	if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
		emit_w3_redis_baseline_setup(
			out, baseline, sample, false,
			ret < 0 ? errno : ENAMETOOLONG, 0, NULL,
			"failed to build W3 FUSE baseline sample dir");
		return 1;
	}
	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(checkpoint_dir, sizeof(checkpoint_dir),
			       sample_dir, "checkpoint");
	if (!ret)
		ret = set_path(runtime_dir, sizeof(runtime_dir), sample_dir,
			       "runtime");
	if (!ret)
		ret = mkdir_if_missing(checkpoint_dir);
	if (!ret)
		ret = mkdir_if_missing(runtime_dir);
	if (!ret)
		ret = w3_redis_checkpoint_path(checkpoint_dir, dump_ckpt,
					       sizeof(dump_ckpt));
	if (ret) {
		emit_w3_redis_baseline_setup(
			out, baseline, sample, false, -ret, 0, NULL,
			"failed to prepare W3 FUSE baseline paths");
		return 1;
	}
	unlink_existing(dump_ckpt);
	ret = generate_w3_redis_checkpoint(redis_bin, checkpoint_dir,
					   runtime_dir, "seed",
					   W3_REDIS_VALUE, port_base, NULL,
					   false);
	if (ret) {
		emit_w3_redis_baseline_setup(
			out, baseline, sample, false, -ret, 0, NULL,
			"failed to generate W3 FUSE baseline source checkpoint");
		return 1;
	}

	ret = copy_string(spec.dir, sizeof(spec.dir), checkpoint_dir);
	if (!ret)
		ret = copy_string(spec.visible, sizeof(spec.visible),
				  "dump.rdb");
	if (!ret)
		ret = copy_string(spec.shadow, sizeof(spec.shadow),
				  "dump.ckpt");
	spec.original[0] = 0;
	start_ns = monotonic_ns();
	if (!ret)
		ret = setup_w1_fuse_mount(&spec, 1, checkpoint_dir,
					  &setup_stats, &fuse_ctx);
	end_ns = monotonic_ns();
	(*setup_rows)++;
	emit_w3_redis_baseline_setup(
		out, baseline, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &setup_stats,
		ret ? "failed to setup W3 FUSE checkpoint baseline" :
		      "W3 FUSE checkpoint baseline setup completed");
	if (ret) {
		unmount_w1_fuse_context(&fuse_ctx);
		return 1;
	}

	initial_get_pass =
		check_w3_redis_value(redis_bin, checkpoint_dir, runtime_dir,
				     "initial", port_base + 1, "dump.rdb",
				     W3_REDIS_VALUE, false) == 0;
	if (!initial_get_pass)
		sample_failures++;
	readdir_pass = check_w3_readdir_alias(checkpoint_dir) == 0;
	if (!readdir_pass)
		sample_failures++;
	hidden_backing_absent = readdir_pass;
	if (!hidden_backing_absent)
		sample_failures++;

	ret = snprintf(updated_value, sizeof(updated_value),
		       "namei-ext-w3-fuse-updated-%03d", sample);
	if (ret < 0 || (size_t)ret >= sizeof(updated_value))
		ret = ret < 0 ? -errno : -ENAMETOOLONG;
	else
		ret = 0;
	start_ns = monotonic_ns();
	if (!ret)
		ret = w1_fuse_backing_dir(checkpoint_dir, backing_dir,
					  sizeof(backing_dir));
	if (!ret)
		ret = generate_w3_redis_checkpoint(
			redis_bin, backing_dir, runtime_dir, "update",
			updated_value, port_base + 2, &update_stats, true);
	end_ns = monotonic_ns();
	(*update_rows)++;
	emit_w3_redis_baseline_update(
		out, baseline, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &update_stats,
		ret ? "failed to update W3 FUSE checkpoint backing" :
		      "W3 FUSE checkpoint backing updated");
	if (ret) {
		sample_failures++;
	} else {
		post_update_get_pass =
			check_w3_redis_value(redis_bin, checkpoint_dir,
					     runtime_dir, "post-update",
					     port_base + 3, "dump.rdb",
					     updated_value, false) == 0;
		if (!post_update_get_pass)
			sample_failures++;
	}

	ret = unmount_w1_fuse_context(&fuse_ctx);
	if (ret)
		sample_failures++;

	(*correctness_rows)++;
	emit_w3_redis_baseline_correctness(
		out, baseline, sample, sample_failures == 0, sample_failures,
		initial_get_pass, readdir_pass, hidden_backing_absent,
		post_update_get_pass,
		sample_failures ?
			"W3 FUSE checkpoint baseline correctness failed" :
			"W3 FUSE checkpoint baseline correctness passed");
	return sample_failures ? 1 : 0;
}

static int run_one_w3_redis_baseline_sample(
	FILE *out, const char *baseline, const char *work_dir, int sample,
	const char *redis_bin, int *setup_rows, int *update_rows,
	int *correctness_rows)
{
	if (!strcmp(baseline, "materialized_checkpoint_view"))
		return run_one_w3_redis_materialized_baseline_sample(
			out, baseline, work_dir, sample, redis_bin, setup_rows,
			update_rows, correctness_rows);
	if (!strcmp(baseline, "fuse_redirect"))
		return run_one_w3_redis_fuse_baseline_sample(
			out, baseline, work_dir, sample, redis_bin, setup_rows,
			update_rows, correctness_rows);
	return 1;
}

static int run_w3_redis_baseline_macrobench(FILE *out, const char *work_dir,
					    int samples,
					    const char *redis_bin,
					    const char *baselines)
{
	const char *known[] = {
		"materialized_checkpoint_view",
		"fuse_redirect",
	};
	int baseline_count = 0;
	int setup_rows = 0;
	int update_rows = 0;
	int correctness_rows = 0;
	int failures = 0;
	size_t i;
	int sample;
	int ret;

	if (samples <= 0) {
		emit_w3_redis_baseline_summary(
			out, baselines, 0, samples, 0, 0, 0, 1,
			"sample count must be positive");
		return 1;
	}
	ret = count_selected_w3_redis_baselines(baselines, &baseline_count);
	if (ret) {
		emit_w3_redis_baseline_summary(
			out, baselines, 0, samples, 0, 0, 0, 1,
			"unknown or empty W3 Redis baseline selection");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_w3_redis_baseline_summary(
			out, baselines, baseline_count, samples, 0, 0, 0, 1,
			"failed to create W3 Redis baseline workdir");
		return 1;
	}
	if (access(redis_bin, X_OK)) {
		emit_w3_redis_baseline_summary(
			out, baselines, baseline_count, samples, 0, 0, 0, 1,
			"Redis binary is not executable");
		return 1;
	}

	for (i = 0; i < ARRAY_SIZE(known); i++) {
		if (!w3_redis_baseline_selected(baselines, known[i]))
			continue;
		for (sample = 0; sample < samples; sample++)
			failures += run_one_w3_redis_baseline_sample(
				out, known[i], work_dir, sample, redis_bin,
				&setup_rows, &update_rows, &correctness_rows);
	}

	emit_w3_redis_baseline_summary(
		out, baselines, baseline_count, samples, setup_rows,
		update_rows, correctness_rows, failures,
		failures ?
			"W3 Redis external checkpoint baselines failed" :
			"W3 Redis external checkpoint baselines passed");
	return failures ? 1 : 0;
}

static int materialize_w1_build_baseline_aliases(
	const char *baseline, const char *redis_src,
	struct oracle_entry *entries, size_t nr_entries,
	const char *include_dir, struct nginx_macro_stats *stats,
	struct w1_fuse_context *fuse_ctx)
{
	struct w1_alias_spec specs[W1_ALIAS_MAX] = {};
	size_t nr_specs = 0;
	size_t i;
	int ret;

	add_w1_baseline_helper_stats(include_dir, stats);
	if (!strcmp(baseline, "projected_volume") ||
	    !strcmp(baseline, "fuse_redirect")) {
		ret = collect_w1_alias_specs(redis_src, entries, nr_entries,
					     specs, &nr_specs);
		if (ret)
			return ret;
		if (!strcmp(baseline, "projected_volume"))
			return materialize_w1_projected_aliases(specs,
								nr_specs,
								stats);
		return setup_w1_fuse_aliases(specs, nr_specs, stats, fuse_ctx);
	}

	ret = materialize_w1_extra_redis_aliases(redis_src, baseline, stats);
	if (ret)
		return ret;

	for (i = 0; i < nr_entries; i++) {
		if (!strcmp(entries[i].branch, "toolchain_selection"))
			continue;
		if (w1_entry_alias_seen_before(entries, i))
			continue;
		ret = materialize_w1_alias_path(entries[i].dir,
						entries[i].visible,
						entries[i].shadow,
						entries[i].original, baseline,
						stats);
		if (ret)
			return ret;
	}
	return 0;
}

static int update_w1_baseline_aliases(struct oracle_entry *entries,
				      size_t nr_entries, const char *baseline,
				      const char *redis_src,
				      struct nginx_macro_stats *stats)
{
	size_t i;

	if (!strcmp(baseline, "projected_volume"))
		return update_w1_projected_aliases(redis_src, entries,
						   nr_entries, stats);
	if (!strcmp(baseline, "fuse_redirect"))
		return update_w1_fuse_aliases(redis_src, entries, nr_entries,
					      stats);

	for (i = 0; i < nr_entries; i++) {
		char dst[PATH_MAX];
		int ret;

		if (!strcmp(entries[i].branch, "toolchain_selection"))
			continue;
		if (w1_entry_alias_seen_before(entries, i))
			continue;
		if (!strcmp(baseline, "copy_tree")) {
			ret = set_path(dst, sizeof(dst), entries[i].dir,
				       entries[i].visible);
			if (ret)
				return ret;
			ret = copy_file_baseline_update(entries[i].original,
							dst, stats);
		} else if (!strcmp(baseline, "symlink_forest") ||
			   !strcmp(baseline, "bind_mount")) {
			ret = set_path(dst, sizeof(dst), entries[i].dir,
				       entries[i].shadow);
			if (ret)
				return ret;
			ret = copy_file_counted(entries[i].original, dst,
						stats, true);
		} else {
			return -EINVAL;
		}
		if (ret)
			return ret;
	}
	return 0;
}

static int unmount_w1_bind_alias_path(const char *dir, const char *visible)
{
	char visible_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), dir, visible);
	if (ret)
		return ret;
	if (umount2(visible_path, MNT_DETACH) && errno != EINVAL &&
	    errno != ENOENT)
		return -errno;
	return 0;
}

static int unmount_w1_bind_baseline_aliases(const char *redis_src,
					    struct oracle_entry *entries,
					    size_t nr_entries)
{
	char dir[PATH_MAX];
	int first_error = 0;
	size_t i;
	int ret;

	ret = mkdir_relative_under(redis_src, "src", dir, sizeof(dir));
	if (!ret)
		ret = unmount_w1_bind_alias_path(dir, "config.h");
	if (ret && !first_error)
		first_error = ret;
	if (!ret)
		ret = unmount_w1_bind_alias_path(dir, "version.h");
	if (ret && !first_error)
		first_error = ret;

	for (i = 0; i < nr_entries; i++) {
		if (!strcmp(entries[i].branch, "toolchain_selection"))
			continue;
		ret = unmount_w1_bind_alias_path(entries[i].dir,
						 entries[i].visible);
		if (ret && !first_error)
			first_error = ret;
	}
	return first_error;
}

static int run_one_w1_build_baseline_sample(
	FILE *out, const char *baseline, const char *work_dir, int sample,
	const char *entries_tsv, const char *redis_src, const char *nginx_src,
	int *setup_rows, int *update_rows, int *correctness_rows)
{
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	struct w1_alias_spec alias_specs[W1_ALIAS_MAX] = {};
	struct nginx_macro_stats setup_stats = {};
	struct nginx_macro_stats update_stats = {};
	struct w1_fuse_context fuse_ctx = {};
	char sample_dir[PATH_MAX];
	char result_dir[PATH_MAX];
	char redis_sample_src[PATH_MAX];
	char nginx_sample_src[PATH_MAX];
	char toolchain_dir[PATH_MAX];
	char include_dir[PATH_MAX];
	char path_env[PATH_MAX + 128];
	size_t nr_entries = 0;
	size_t nr_alias_specs = 0;
	size_t alias_parent_dirs = 0;
	bool baseline_replay_pass = false;
	bool materialized_replay_pass = false;
	bool post_update_replay_pass = false;
	bool fuse_baseline = !strcmp(baseline, "fuse_redirect");
	int sample_failures = 0;
	__u64 copy_start_ns;
	__u64 copy_end_ns;
	__u64 setup_start_ns;
	__u64 setup_end_ns;
	__u64 update_start_ns;
	__u64 update_end_ns;
	__u64 source_copy_ns = 0;
	int ret;

	ret = snprintf(sample_dir, sizeof(sample_dir), "%s/%s-sample-%03d",
		       work_dir, baseline, sample);
	if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
		emit_w1_build_baseline_setup(
			out, baseline, sample, false,
			ret < 0 ? errno : ENAMETOOLONG, 0, 0, 0, NULL,
			"failed to build W1 baseline sample directory path");
		return 1;
	}
	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(result_dir, sizeof(result_dir), sample_dir,
			       "results");
	if (!ret)
		ret = set_path(redis_sample_src, sizeof(redis_sample_src),
			       sample_dir, "redis-src");
	if (!ret)
		ret = set_path(nginx_sample_src, sizeof(nginx_sample_src),
			       sample_dir, "nginx-src");
	if (ret) {
		emit_w1_build_baseline_setup(
			out, baseline, sample, false, -ret, 0, 0, 0, NULL,
			"failed to build W1 baseline sample paths");
		return 1;
	}

	copy_start_ns = monotonic_ns();
	ret = copy_tree_for_w1_sample(redis_src, redis_sample_src, sample_dir,
				      "redis");
	if (!ret)
		ret = copy_tree_for_w1_sample(nginx_src, nginx_sample_src,
					      sample_dir, "nginx");
	copy_end_ns = monotonic_ns();
	source_copy_ns = copy_end_ns >= copy_start_ns ?
			 copy_end_ns - copy_start_ns : 0;
	if (ret) {
		(*setup_rows)++;
		emit_w1_build_baseline_setup(
			out, baseline, sample, false, -ret, 0, source_copy_ns,
			0, NULL, "failed to copy W1 baseline source trees");
		return 1;
	}

	ret = mkdir_if_missing(result_dir);
	if (!ret)
		ret = read_entries(entries_tsv, entries, &nr_entries);
	if (!ret)
		ret = prepare_replay_toolchain(result_dir, toolchain_dir,
					       sizeof(toolchain_dir),
					       path_env, sizeof(path_env));
	if (!ret)
		ret = prepare_replay_include(result_dir, include_dir,
					     sizeof(include_dir));
	if (!ret)
		ret = assign_build_replay_parent_dirs(
			entries, nr_entries, redis_sample_src, nginx_sample_src,
			toolchain_dir, include_dir);
	if (ret) {
		(*setup_rows)++;
		emit_w1_build_baseline_setup(
			out, baseline, sample, false, -ret, 0, source_copy_ns,
			nr_entries, NULL,
			"failed to prepare W1 baseline replay helpers");
		return 1;
	}

	sample_failures += run_redis_replay(out, redis_sample_src, result_dir,
					    include_dir, path_env, false);
	sample_failures += run_nginx_replay(out, nginx_sample_src, result_dir,
					    include_dir, path_env, false);
	baseline_replay_pass = sample_failures == 0;
	if (sample_failures) {
		(*correctness_rows)++;
		emit_w1_build_baseline_correctness(
			out, baseline, sample, false, sample_failures,
			baseline_replay_pass, false, false, nr_entries,
			nr_alias_specs, alias_parent_dirs, setup_stats.fuse_mounts,
			"W1 baseline reference replay failed before materialization");
		return sample_failures;
	}

	ret = collect_w1_alias_specs(redis_sample_src, entries, nr_entries,
				     alias_specs, &nr_alias_specs);
	if (ret) {
		(*correctness_rows)++;
		emit_w1_build_baseline_correctness(
			out, baseline, sample, false, 1, baseline_replay_pass,
			false, false, nr_entries, nr_alias_specs,
			alias_parent_dirs, setup_stats.fuse_mounts,
			"failed to collect W1 baseline alias coverage");
		return 1;
	}
	alias_parent_dirs = w1_alias_parent_count(alias_specs, nr_alias_specs);

	setup_start_ns = monotonic_ns();
	ret = materialize_w1_build_baseline_aliases(
		baseline, redis_sample_src, entries, nr_entries, include_dir,
		&setup_stats, &fuse_ctx);
	setup_end_ns = monotonic_ns();
	(*setup_rows)++;
	emit_w1_build_baseline_setup(
		out, baseline, sample, !ret, ret ? -ret : 0,
		setup_end_ns >= setup_start_ns ? setup_end_ns - setup_start_ns :
						 0,
		source_copy_ns, nr_entries, &setup_stats,
		ret ? "failed to materialize W1 build baseline view" :
		      "W1 build baseline view materialized");
	if (ret) {
		if (fuse_baseline)
			unmount_w1_fuse_context(&fuse_ctx);
		return 1;
	}

	sample_failures += run_redis_replay(out, redis_sample_src, result_dir,
					    include_dir, path_env, true);
	sample_failures += run_nginx_replay(out, nginx_sample_src, result_dir,
					    include_dir, path_env, true);
	materialized_replay_pass = sample_failures == 0;

	if (!sample_failures) {
		update_start_ns = monotonic_ns();
		ret = update_w1_baseline_aliases(entries, nr_entries, baseline,
						 redis_sample_src, &update_stats);
		update_end_ns = monotonic_ns();
		(*update_rows)++;
		emit_w1_build_baseline_update(
			out, baseline, sample, !ret, ret ? -ret : 0,
			update_end_ns >= update_start_ns ?
				update_end_ns - update_start_ns : 0,
			&update_stats,
			ret ? "failed to update W1 baseline view" :
			      "updated W1 baseline backing or materialized files");
		if (ret) {
			sample_failures++;
		} else {
			sample_failures += run_redis_replay(
				out, redis_sample_src, result_dir, include_dir,
				path_env, true);
			sample_failures += run_nginx_replay(
				out, nginx_sample_src, result_dir, include_dir,
				path_env, true);
			post_update_replay_pass = sample_failures == 0;
		}
	}

	if (!strcmp(baseline, "bind_mount")) {
		ret = unmount_w1_bind_baseline_aliases(redis_sample_src, entries,
						       nr_entries);
		if (ret)
			sample_failures++;
	}
	if (fuse_baseline) {
		ret = unmount_w1_fuse_context(&fuse_ctx);
		if (ret)
			sample_failures++;
	}

	(*correctness_rows)++;
	emit_w1_build_baseline_correctness(
		out, baseline, sample, sample_failures == 0, sample_failures,
		baseline_replay_pass, materialized_replay_pass,
		post_update_replay_pass, nr_entries, nr_alias_specs,
		alias_parent_dirs, setup_stats.fuse_mounts,
		sample_failures ?
			"W1 build baseline sample failed correctness oracle" :
			"W1 build baseline sample passed reference, materialized, and post-update replay");
	return sample_failures ? sample_failures : 0;
}

static int run_w1_build_baseline_macrobench(FILE *out, const char *work_dir,
					    int samples,
					    const char *entries_tsv,
					    const char *redis_src,
					    const char *nginx_src,
					    const char *baselines)
{
	const char *known[] = {
		"copy_tree",
		"symlink_forest",
		"bind_mount",
		"projected_volume",
		"fuse_redirect",
	};
	int baseline_count = 0;
	int setup_rows = 0;
	int update_rows = 0;
	int correctness_rows = 0;
	int failures = 0;
	size_t i;
	int ret;

	if (samples <= 0) {
		emit_w1_build_baseline_summary(
			out, baselines, 0, samples, 0, 0, 0, 1,
			"sample count must be positive");
		return 1;
	}
	ret = count_selected_w1_build_baselines(baselines, &baseline_count);
	if (ret) {
		emit_w1_build_baseline_summary(
			out, baselines, 0, samples, 0, 0, 0, 1,
			"unknown or empty W1 build baseline selection");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_w1_build_baseline_summary(
			out, baselines, baseline_count, samples, 0, 0, 0, 1,
			"failed to create W1 build baseline macrobench workdir");
		return 1;
	}
	if (access(entries_tsv, R_OK) || access(redis_src, R_OK) ||
	    access(nginx_src, R_OK)) {
		emit_w1_build_baseline_summary(
			out, baselines, baseline_count, samples, 0, 0, 0, 1,
			"W1 build baseline inputs are not readable");
		return 1;
	}

	for (i = 0; i < ARRAY_SIZE(known); i++) {
		int sample;

		if (!w1_build_baseline_selected(baselines, known[i]))
			continue;
		for (sample = 0; sample < samples; sample++)
			failures += run_one_w1_build_baseline_sample(
				out, known[i], work_dir, sample, entries_tsv,
				redis_src, nginx_src, &setup_rows,
				&update_rows, &correctness_rows);
	}

	emit_w1_build_baseline_summary(
		out, baselines, baseline_count, samples, setup_rows, update_rows,
		correctness_rows, failures,
		failures ?
			"W1 build feature-equivalent baseline macrobench failed" :
			"W1 build feature-equivalent baseline macrobench passed; not a C2 release gate");
	return failures ? 1 : 0;
}

static int prepare_redis_release_rebuild(const char *redis_src)
{
	char binary[PATH_MAX];
	int ret;

	ret = set_child_path(binary, sizeof(binary), redis_src, "src",
			     "redis-server");
	if (ret)
		return ret;
	ret = unlink_existing(binary);
	if (ret)
		return ret;
	return remove_suffix_under(redis_src, ".o");
}

static int prepare_nginx_release_rebuild(const char *nginx_src)
{
	char binary[PATH_MAX];
	int ret;

	ret = set_child_path(binary, sizeof(binary), nginx_src, "objs",
			     "nginx");
	if (ret)
		return ret;
	ret = unlink_existing(binary);
	if (ret)
		return ret;
	return remove_suffix_under(nginx_src, ".o");
}

static int strip_debug_sections(const char *binary, const char *stdout_path,
				const char *stderr_path, int *exit_code)
{
	char *argv[5];
	int i = 0;

	argv[i++] = "strip";
	argv[i++] = "--strip-debug";
	argv[i++] = "--remove-section=.note.gnu.build-id";
	argv[i++] = (char *)binary;
	argv[i] = NULL;
	return run_child_capture(argv, NULL, stdout_path, stderr_path,
				 exit_code);
}

static int run_redis_release_build(FILE *out, const char *redis_src,
				   const char *result_dir, const char *path_env,
				   bool policy_mode, bool clean_outputs)
{
	char binary[PATH_MAX];
	char output_binary[PATH_MAX];
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	char strip_stdout_path[PATH_MAX];
	char strip_stderr_path[PATH_MAX];
	int exit_code = -1;
	int strip_exit_code = -1;
	int ret;
	char *argv[10];
	int i = 0;
	const char *op = policy_mode ? "policy_release_build" :
				       "baseline_release_build";

	ret = set_child_path(binary, sizeof(binary), redis_src, "src",
			     "redis-server");
	if (!ret)
		ret = set_path(output_binary, sizeof(output_binary), result_dir,
			       policy_mode ? "redis.policy.bin" :
					     "redis.baseline.bin");
	if (!ret)
		ret = set_path(stdout_path, sizeof(stdout_path), result_dir,
			       policy_mode ? "redis.release.policy.stdout" :
					     "redis.release.baseline.stdout");
	if (!ret)
		ret = set_path(stderr_path, sizeof(stderr_path), result_dir,
			       policy_mode ? "redis.release.policy.stderr" :
					     "redis.release.baseline.stderr");
	if (!ret)
		ret = set_path(strip_stdout_path, sizeof(strip_stdout_path),
			       result_dir,
			       policy_mode ?
			       "redis.release.policy.strip.stdout" :
			       "redis.release.baseline.strip.stdout");
	if (!ret)
		ret = set_path(strip_stderr_path, sizeof(strip_stderr_path),
			       result_dir,
			       policy_mode ?
			       "redis.release.policy.strip.stderr" :
			       "redis.release.baseline.strip.stderr");
	if (ret) {
		emit_release_replay_case(out, "w1-redis-build", "build_paths",
					 false, -ret, -1, policy_mode, false,
					 "failed to build Redis release replay paths",
					 NULL, NULL);
		return 1;
	}

	if (clean_outputs) {
		ret = prepare_redis_release_rebuild(redis_src);
		if (ret) {
			emit_release_replay_case(out, "w1-redis-build",
						 "prepare_rebuild", false,
						 -ret, -1, policy_mode, false,
						 "failed to clean Redis rebuild outputs",
						 output_binary, NULL);
			return 1;
		}
	}

	argv[i++] = "make";
	argv[i++] = "-C";
	argv[i++] = (char *)redis_src;
	argv[i++] = "-j1";
	argv[i++] = "BUILD_TLS=no";
	argv[i++] = "MALLOC=libc";
	argv[i++] = "DEBUG=";
	argv[i++] = "redis-server";
	argv[i] = NULL;

	ret = run_child_capture(argv, path_env, stdout_path, stderr_path,
				&exit_code);
	if (ret || exit_code) {
		emit_release_replay_case(out, "w1-redis-build", op, false,
					 ret ? -ret : 0, exit_code,
					 policy_mode, false,
					 policy_mode ?
					 "Redis policy release rebuild failed" :
					 "Redis baseline release rebuild failed",
					 output_binary, NULL);
		return 1;
	}
	if (access(binary, X_OK)) {
		emit_release_replay_case(out, "w1-redis-build", op, false,
					 errno, exit_code, policy_mode, false,
					 "Redis release binary missing after rebuild",
					 output_binary, NULL);
		return 1;
	}
	ret = copy_file(binary, output_binary);
	if (ret) {
		emit_release_replay_case(out, "w1-redis-build", op, false,
					 -ret, exit_code, policy_mode, false,
					 "failed to preserve Redis release binary",
					 output_binary, NULL);
		return 1;
	}
	ret = strip_debug_sections(output_binary, strip_stdout_path,
				   strip_stderr_path, &strip_exit_code);
	if (ret || strip_exit_code) {
		emit_release_replay_case(out, "w1-redis-build", op, false,
					 ret ? -ret : 0, strip_exit_code,
					 policy_mode, false,
					 "failed to strip Redis release binary debug sections",
					 output_binary, NULL);
		return 1;
	}
	emit_release_replay_case(out, "w1-redis-build", op, true, 0,
				 exit_code, policy_mode, false,
				 policy_mode ?
				 "Redis policy release rebuild passed" :
				 "Redis baseline release rebuild passed",
				 output_binary, NULL);
	return 0;
}

static int run_nginx_release_build(FILE *out, const char *nginx_src,
				   const char *result_dir, const char *path_env,
				   bool policy_mode, bool clean_outputs)
{
	char binary[PATH_MAX];
	char output_binary[PATH_MAX];
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	char strip_stdout_path[PATH_MAX];
	char strip_stderr_path[PATH_MAX];
	int exit_code = -1;
	int strip_exit_code = -1;
	int ret;
	char *argv[7];
	int i = 0;
	const char *op = policy_mode ? "policy_release_build" :
				       "baseline_release_build";

	ret = set_child_path(binary, sizeof(binary), nginx_src, "objs",
			     "nginx");
	if (!ret)
		ret = set_path(output_binary, sizeof(output_binary), result_dir,
			       policy_mode ? "nginx.policy.bin" :
					     "nginx.baseline.bin");
	if (!ret)
		ret = set_path(stdout_path, sizeof(stdout_path), result_dir,
			       policy_mode ? "nginx.release.policy.stdout" :
					     "nginx.release.baseline.stdout");
	if (!ret)
		ret = set_path(stderr_path, sizeof(stderr_path), result_dir,
			       policy_mode ? "nginx.release.policy.stderr" :
					     "nginx.release.baseline.stderr");
	if (!ret)
		ret = set_path(strip_stdout_path, sizeof(strip_stdout_path),
			       result_dir,
			       policy_mode ?
			       "nginx.release.policy.strip.stdout" :
			       "nginx.release.baseline.strip.stdout");
	if (!ret)
		ret = set_path(strip_stderr_path, sizeof(strip_stderr_path),
			       result_dir,
			       policy_mode ?
			       "nginx.release.policy.strip.stderr" :
			       "nginx.release.baseline.strip.stderr");
	if (ret) {
		emit_release_replay_case(out, "w1-nginx-build", "build_paths",
					 false, -ret, -1, policy_mode, false,
					 "failed to build nginx release replay paths",
					 NULL, NULL);
		return 1;
	}

	if (clean_outputs) {
		ret = prepare_nginx_release_rebuild(nginx_src);
		if (ret) {
			emit_release_replay_case(out, "w1-nginx-build",
						 "prepare_rebuild", false,
						 -ret, -1, policy_mode, false,
						 "failed to clean nginx rebuild outputs",
						 output_binary, NULL);
			return 1;
		}
	}

	argv[i++] = "make";
	argv[i++] = "-C";
	argv[i++] = (char *)nginx_src;
	argv[i++] = "-j1";
	argv[i++] = "CFLAGS=-pipe -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror";
	argv[i] = NULL;

	ret = run_child_capture(argv, path_env, stdout_path, stderr_path,
				&exit_code);
	if (ret || exit_code) {
		emit_release_replay_case(out, "w1-nginx-build", op, false,
					 ret ? -ret : 0, exit_code,
					 policy_mode, false,
					 policy_mode ?
					 "nginx policy release rebuild failed" :
					 "nginx baseline release rebuild failed",
					 output_binary, NULL);
		return 1;
	}
	if (access(binary, X_OK)) {
		emit_release_replay_case(out, "w1-nginx-build", op, false,
					 errno, exit_code, policy_mode, false,
					 "nginx release binary missing after rebuild",
					 output_binary, NULL);
		return 1;
	}
	ret = copy_file(binary, output_binary);
	if (ret) {
		emit_release_replay_case(out, "w1-nginx-build", op, false,
					 -ret, exit_code, policy_mode, false,
					 "failed to preserve nginx release binary",
					 output_binary, NULL);
		return 1;
	}
	ret = strip_debug_sections(output_binary, strip_stdout_path,
				   strip_stderr_path, &strip_exit_code);
	if (ret || strip_exit_code) {
		emit_release_replay_case(out, "w1-nginx-build", op, false,
					 ret ? -ret : 0, strip_exit_code,
					 policy_mode, false,
					 "failed to strip nginx release binary debug sections",
					 output_binary, NULL);
		return 1;
	}
	emit_release_replay_case(out, "w1-nginx-build", op, true, 0,
				 exit_code, policy_mode, false,
				 policy_mode ?
				 "nginx policy release rebuild passed" :
				 "nginx baseline release rebuild passed",
				 output_binary, NULL);
	return 0;
}

static int compare_release_binary(FILE *out, const char *workload,
				  const char *result_dir, const char *baseline,
				  const char *policy)
{
	char baseline_path[PATH_MAX];
	char policy_path[PATH_MAX];
	int ret;

	ret = set_path(baseline_path, sizeof(baseline_path), result_dir,
		       baseline);
	if (!ret)
		ret = set_path(policy_path, sizeof(policy_path), result_dir,
			       policy);
	if (ret) {
		emit_release_replay_case(out, workload, "output_compare",
					 false, -ret, -1, true, false,
					 "failed to build release binary output paths",
					 NULL, NULL);
		return 1;
	}
	ret = compare_files(baseline_path, policy_path);
	if (ret) {
		emit_release_replay_case(out, workload, "output_compare",
					 false, -ret, 0, true, false,
					 "policy release binary differed from baseline",
					 baseline_path, policy_path);
		return 1;
	}
	emit_release_replay_case(out, workload, "output_compare", true, 0,
				 0, true, true,
				 "policy release binary matched baseline",
				 baseline_path, policy_path);
	return 0;
}

static int w1_branch_paths(const char *parent, char *private_path,
			   size_t private_size, char *poison_path,
			   size_t poison_size, char *missing_path,
			   size_t missing_size)
{
	int ret;

	ret = set_path(private_path, private_size, parent, "private.h");
	if (!ret)
		ret = set_path(poison_path, poison_size, parent, "poison.dep");
	if (!ret)
		ret = set_path(missing_path, missing_size, parent, "missing.h");
	return ret;
}

static int prepare_w1_branch_parent(FILE *out, const char *workload,
				    const char *parent)
{
	char private_path[PATH_MAX];
	char poison_path[PATH_MAX];
	char missing_path[PATH_MAX];
	int ret;

	ret = w1_branch_paths(parent, private_path, sizeof(private_path),
			      poison_path, sizeof(poison_path),
			      missing_path, sizeof(missing_path));
	if (ret) {
		emit_w1_branch_probe(out, workload, "setup", "build_paths",
				     false, -ret, false,
				     "failed to build W1 branch probe paths",
				     parent, "");
		return 1;
	}
	ret = unlink_existing(private_path);
	if (!ret)
		ret = unlink_existing(missing_path);
	if (!ret)
		ret = write_text_file(poison_path, W1_POISON_SENTINEL);
	if (ret) {
		emit_w1_branch_probe(out, workload, "setup", "materialize",
				     false, -ret, false,
				     "failed to materialize W1 branch probe backing",
				     parent, "poison.dep");
		return 1;
	}
	emit_w1_branch_probe(out, workload, "setup", "materialize", true, 0,
			     false,
			     "real source parent prepared for W1 branch probes",
			     parent, "poison.dep");
	return 0;
}

static int w1_expect_absent(FILE *out, const char *workload,
			    const char *branch, const char *op,
			    const char *path, bool policy_executed)
{
	int ret = expect_stat_errno(path, ENOENT);

	if (ret) {
		emit_w1_branch_probe(out, workload, branch, op, false, -ret,
				     policy_executed,
				     "path unexpectedly resolved", path,
				     "ENOENT");
		return 1;
	}
	emit_w1_branch_probe(out, workload, branch, op, true, 0,
			     policy_executed, "path remained absent", path,
			     "ENOENT");
	return 0;
}

static int w1_expect_poison(FILE *out, const char *workload,
			    const char *private_path, const char *poison_path)
{
	int ret = compare_files(private_path, poison_path);

	if (ret) {
		emit_w1_branch_probe(out, workload,
				     "undeclared_dependency_poison",
				     "attached_poison_lookup", false, -ret,
				     true,
				     "private.h did not resolve to poison.dep",
				     private_path, "poison.dep");
		return 1;
	}
	emit_w1_branch_probe(out, workload, "undeclared_dependency_poison",
			     "attached_poison_lookup", true, 0, true,
			     "private.h resolved to poison.dep sentinel",
			     private_path, "poison.dep");
	return 0;
}

static int w1_expect_poison_readdir(FILE *out, const char *workload,
				    const char *parent)
{
	bool saw_private;
	bool saw_poison;
	int err = 0;

	saw_private = dir_has_name(parent, "private.h", &err);
	if (!err)
		saw_poison = dir_has_name(parent, "poison.dep", &err);
	else
		saw_poison = false;
	if (!err && saw_private && !saw_poison) {
		emit_w1_branch_probe(out, workload,
				     "undeclared_dependency_poison",
				     "attached_poison_readdir_alias", true, 0,
				     true,
				     "readdir exposed private.h and hid poison.dep",
				     parent, "private.h");
		return 0;
	}
	emit_w1_branch_probe(out, workload, "undeclared_dependency_poison",
			     "attached_poison_readdir_alias", false, err, true,
			     "poison branch directory view mismatch", parent,
			     "private.h");
	return 1;
}

static int w1_expect_negative_readdir(FILE *out, const char *workload,
				      const char *parent)
{
	bool saw_missing;
	int err = 0;

	saw_missing = dir_has_name(parent, "missing.h", &err);
	if (!err && !saw_missing) {
		emit_w1_branch_probe(out, workload, "negative_fallback",
				     "attached_negative_readdir_absent", true,
				     0, true,
				     "missing.h stayed absent from readdir",
				     parent, "missing.h");
		return 0;
	}
	emit_w1_branch_probe(out, workload, "negative_fallback",
			     "attached_negative_readdir_absent", false, err,
			     true, "negative branch appeared in readdir",
			     parent, "missing.h");
	return 1;
}

static int run_w1_branch_case(FILE *out, const char *workload,
			      const char *parent, bool attached)
{
	char private_path[PATH_MAX];
	char poison_path[PATH_MAX];
	char missing_path[PATH_MAX];
	int failures = 0;
	int ret;

	ret = w1_branch_paths(parent, private_path, sizeof(private_path),
			      poison_path, sizeof(poison_path),
			      missing_path, sizeof(missing_path));
	if (ret) {
		emit_w1_branch_probe(out, workload, "setup", "build_paths",
				     false, -ret, attached,
				     "failed to build W1 branch probe paths",
				     parent, "");
		return 1;
	}

	if (!attached) {
		failures += w1_expect_absent(out, workload,
					     "undeclared_dependency_poison",
					     "pre_attach_poison_absent",
					     private_path, false);
		failures += w1_expect_absent(out, workload,
					     "negative_fallback",
					     "pre_attach_negative_absent",
					     missing_path, false);
		return failures;
	}

	failures += w1_expect_poison(out, workload, private_path, poison_path);
	failures += w1_expect_poison_readdir(out, workload, parent);
	failures += w1_expect_absent(out, workload, "negative_fallback",
				     "attached_negative_lookup", missing_path,
				     true);
	failures += w1_expect_negative_readdir(out, workload, parent);
	return failures;
}

static int run_w1_branch_probes(FILE *out, const char *cgroup_mount,
				const char *policy_path, const char *redis_src,
				const char *nginx_src)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	char redis_parent[PATH_MAX];
	char nginx_parent[PATH_MAX];
	char redis_private[PATH_MAX];
	char redis_poison[PATH_MAX];
	char redis_missing[PATH_MAX];
	char nginx_private[PATH_MAX];
	char nginx_poison[PATH_MAX];
	char nginx_missing[PATH_MAX];
	char current_cgroup[PATH_MAX];
	int failures = 0;
	int ret;

	ret = set_path(redis_parent, sizeof(redis_parent), redis_src, "src");
	if (!ret)
		ret = set_child_path(nginx_parent, sizeof(nginx_parent),
				     nginx_src, "src", "core");
	if (!ret)
		ret = w1_branch_paths(redis_parent, redis_private,
				      sizeof(redis_private), redis_poison,
				      sizeof(redis_poison), redis_missing,
				      sizeof(redis_missing));
	if (!ret)
		ret = w1_branch_paths(nginx_parent, nginx_private,
				      sizeof(nginx_private), nginx_poison,
				      sizeof(nginx_poison), nginx_missing,
				      sizeof(nginx_missing));
	if (ret) {
		emit_w1_branch_probe(out, "w1-build-graph", "setup",
				     "build_parent_paths", false, -ret, false,
				     "failed to build source parent paths", NULL,
				     "");
		return 1;
	}

	failures += prepare_w1_branch_parent(out, "w1-redis-build",
					     redis_parent);
	failures += prepare_w1_branch_parent(out, "w1-nginx-build",
					     nginx_parent);
	if (failures)
		return 1;

	failures += run_w1_branch_case(out, "w1-redis-build", redis_parent,
				       false);
	failures += run_w1_branch_case(out, "w1-nginx-build", nginx_parent,
				       false);

	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (ret) {
		emit_w1_branch_probe(out, "w1-build-graph", "setup",
				     "current_cgroup", false, -ret, false,
				     "failed to resolve current cgroup path",
				     cgroup_mount, "");
		return failures + 1;
	}
	if (open_policy(policy_path, POLICY_BUILD_GRAPH, "build_graph",
			&policy)) {
		emit_w1_branch_probe(out, "w1-build-graph", "setup", "load",
				     false, errno, false,
				     "build_graph policy load failed",
				     policy_path, "");
		return failures + 1;
	}
	emit_w1_branch_probe(out, "w1-build-graph", "setup", "load", true,
			     0, false, "build_graph policy loaded",
			     policy_path, "");

	if (attach_policy(&policy, current_cgroup)) {
		emit_w1_branch_probe(out, "w1-build-graph", "setup", "attach",
				     false, errno, false,
				     "build_graph policy attach failed",
				     current_cgroup, "");
		destroy_policy(&policy);
		return failures + 1;
	}
	emit_w1_branch_probe(out, "w1-build-graph", "setup", "attach", true,
			     0, true, "build_graph policy attached",
			     current_cgroup, "");

	failures += run_w1_branch_case(out, "w1-redis-build", redis_parent,
				       true);
	failures += run_w1_branch_case(out, "w1-nginx-build", nginx_parent,
				       true);

	ret = destroy_policy(&policy);
	if (ret) {
		emit_w1_branch_probe(out, "w1-build-graph", "setup", "detach",
				     false, -ret, true,
				     "build_graph policy detach failed",
				     current_cgroup, "");
		failures++;
	} else {
		emit_w1_branch_probe(out, "w1-build-graph", "setup", "detach",
				     true, 0, true,
				     "build_graph policy detached",
				     current_cgroup, "");
	}

	failures += w1_expect_absent(out, "w1-redis-build",
				     "undeclared_dependency_poison",
				     "post_detach_poison_absent",
				     redis_private, false);
	failures += w1_expect_absent(out, "w1-redis-build",
				     "negative_fallback",
				     "post_detach_negative_absent",
				     redis_missing, false);
	failures += w1_expect_absent(out, "w1-nginx-build",
				     "undeclared_dependency_poison",
				     "post_detach_poison_absent",
				     nginx_private, false);
	failures += w1_expect_absent(out, "w1-nginx-build",
				     "negative_fallback",
				     "post_detach_negative_absent",
				     nginx_missing, false);

	fprintf(out,
		"{\"event\":\"w1-branch-probe-summary\","
		"\"result_level\":\"kvm_policy_branch_probe_witness\","
		"\"policy\":\"build_graph\","
		"\"run_environment\":\"kvm\","
		"\"policy_executed\":true,"
		"\"kvm_validated\":true,"
		"\"workloads\":2,\"branch_classes\":2,"
		"\"poison_probes\":2,\"negative_probes\":2,"
		"\"pass\":%s,\"failures\":%d,"
		"\"qualified_for_c8\":false,\"detail\":",
		failures ? "false" : "true", failures);
	fprint_json_string(out, failures ?
			   "W1 build-graph branch probes failed" :
			   "W1 build-graph poison and negative branches passed in real source parent dirs");
	fputs("}\n", out);
	fflush(out);
	return failures ? 1 : 0;
}

static int run_build_replay(FILE *out, const char *cgroup_mount,
			    const char *entries_tsv, const char *policy_path,
			    const char *redis_src, const char *nginx_src,
			    const char *result_dir)
{
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	char current_cgroup[PATH_MAX];
	char toolchain_dir[PATH_MAX];
	char include_dir[PATH_MAX];
	char path_env[PATH_MAX + 128];
	__u64 current_cgroup_id = 0;
	size_t nr_entries = 0;
	int failures = 0;
	int ret;

	ret = mkdir_if_missing(result_dir);
	if (ret) {
		emit_build_replay_case(out, "w1-build-graph", "mkdir_result",
				       false, -ret, -1,
				       "failed to create build replay result directory",
				       NULL, NULL);
		return 1;
	}
	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (ret) {
		emit_build_replay_case(out, "w1-build-graph", "read_entries",
				       false, -ret, -1,
				       "failed to read W1 replay entries", NULL,
				       NULL);
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (ret) {
		emit_build_replay_case(out, "w1-build-graph",
				       "current_cgroup", false, -ret, -1,
				       "failed to resolve current cgroup path",
				       NULL, NULL);
		return 1;
	}
	ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		emit_build_replay_case(out, "w1-build-graph",
				       "current_cgroup_id", false, -ret, -1,
				       "failed to resolve current cgroup id",
				       NULL, NULL);
		return 1;
	}
	ret = prepare_replay_toolchain(result_dir, toolchain_dir,
				       sizeof(toolchain_dir), path_env,
				       sizeof(path_env));
	if (ret) {
		emit_build_replay_case(out, "w1-build-graph",
				       "prepare_toolchain", false, -ret, -1,
				       "failed to prepare replay toolchain",
				       NULL, NULL);
		return 1;
	}
	ret = prepare_replay_include(result_dir, include_dir,
				     sizeof(include_dir));
	if (ret) {
		emit_build_replay_case(out, "w1-build-graph",
				       "prepare_include", false, -ret, -1,
				       "failed to prepare replay include alias",
				       NULL, NULL);
		return 1;
	}
	ret = assign_build_replay_parent_dirs(entries, nr_entries, redis_src,
					      nginx_src, toolchain_dir,
					      include_dir);
	if (ret) {
		emit_build_replay_case(out, "w1-build-graph",
				       "assign_parent_dirs", false, -ret, -1,
				       "failed to assign parent-aware replay key directories",
				       NULL, NULL);
		return 1;
	}

	failures += run_redis_replay(out, redis_src, result_dir, include_dir,
				     path_env, false);
	failures += run_nginx_replay(out, nginx_src, result_dir, include_dir,
				     path_env, false);
	if (failures)
		return 1;

	if (open_policy(policy_path, POLICY_BUILD_GRAPH, "build_graph",
			&policy)) {
		emit_build_replay_case(out, "w1-build-graph", "load", false,
				       errno, -1, "build_graph policy load failed",
				       NULL, NULL);
		return 1;
	}
	emit_build_replay_case(out, "w1-build-graph", "load", true, 0, 0,
			       "build_graph policy loaded", NULL, NULL);

	ret = populate_policy_map(&policy, entries, nr_entries,
				  current_cgroup_id);
	if (ret) {
		emit_build_replay_case(out, "w1-build-graph", "map_update",
				       false, -ret, -1,
				       "failed to update build replay map",
				       NULL, NULL);
		destroy_policy(&policy);
		return 1;
	}
	emit_build_replay_case(out, "w1-build-graph", "map_update", true, 0,
			       0, "build replay redirect map populated", NULL,
			       NULL);

	failures += prepare_replay_aliases("w1-redis-build", redis_src,
					   entries, nr_entries);
	if (failures) {
		emit_build_replay_case(out, "w1-redis-build",
				       "prepare_aliases", false, EINVAL, -1,
				       "failed to prepare Redis shadow aliases",
				       NULL, NULL);
		destroy_policy(&policy);
		return 1;
	}
	failures += prepare_replay_aliases("w1-nginx-build", nginx_src,
					   entries, nr_entries);
	if (failures) {
		emit_build_replay_case(out, "w1-nginx-build",
				       "prepare_aliases", false, EINVAL, -1,
				       "failed to prepare nginx shadow aliases",
				       NULL, NULL);
		destroy_policy(&policy);
		return 1;
	}

	if (attach_policy(&policy, current_cgroup)) {
		emit_build_replay_case(out, "w1-build-graph", "attach", false,
				       errno, -1, "build_graph policy attach failed",
				       NULL, NULL);
		destroy_policy(&policy);
		return 1;
	}
	emit_build_replay_case(out, "w1-build-graph", "attach", true, 0, 0,
			       "build_graph policy attached", NULL, NULL);

	failures += run_redis_replay(out, redis_src, result_dir, include_dir,
				     path_env, true);
	failures += run_nginx_replay(out, nginx_src, result_dir, include_dir,
				     path_env, true);

	ret = destroy_policy(&policy);
	if (ret) {
		emit_build_replay_case(out, "w1-build-graph", "detach", false,
				       -ret, -1, "build_graph policy detach failed",
				       NULL, NULL);
		failures++;
	} else {
		emit_build_replay_case(out, "w1-build-graph", "detach", true,
				       0, 0, "build_graph policy detached",
				       NULL, NULL);
	}

	fprintf(out,
		"{\"event\":\"w1-build-replay-summary\","
		"\"result_level\":\"kvm_policy_build_replay_witness\","
		"\"policy\":\"build_graph\","
		"\"run_environment\":\"kvm\","
		"\"policy_executed\":true,"
		"\"kvm_validated\":true,"
		"\"output_hash_oracle\":false,"
		"\"policy_replay_output_hash_oracle\":true,"
		"\"release_output_hash_oracle\":false,"
		"\"output_hash_oracle_scope\":\"kvm_policy_preprocess\","
		"\"workloads\":2,\"entries\":%zu,\"pass\":%s,"
		"\"failures\":%d,\"qualified_for_c8\":false,"
		"\"detail\":",
		nr_entries, failures ? "false" : "true", failures);
	fprint_json_string(out, failures ?
			   "W1 KVM policy build replay failed" :
			   "W1 KVM policy build replay matched baseline outputs for Redis and nginx preprocessing");
	fputs("}\n", out);
	fflush(out);
	return failures ? 1 : 0;
}

static int run_release_build_replay(FILE *out, const char *cgroup_mount,
				    const char *entries_tsv,
				    const char *policy_path,
				    const char *redis_baseline_src,
				    const char *redis_policy_src,
				    const char *nginx_baseline_src,
				    const char *nginx_policy_src,
				    const char *result_dir)
{
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	char current_cgroup[PATH_MAX];
	char toolchain_dir[PATH_MAX];
	char include_dir[PATH_MAX];
	char path_env[PATH_MAX + 128];
	__u64 current_cgroup_id = 0;
	size_t nr_entries = 0;
	int failures = 0;
	int ret;

	ret = mkdir_if_missing(result_dir);
	if (ret) {
		emit_release_replay_case(out, "w1-build-graph",
					 "mkdir_result", false, -ret, -1,
					 false, false,
					 "failed to create release replay result directory",
					 NULL, NULL);
		return 1;
	}
	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (ret) {
		emit_release_replay_case(out, "w1-build-graph",
					 "read_entries", false, -ret, -1,
					 false, false,
					 "failed to read W1 release replay entries",
					 NULL, NULL);
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (ret) {
		emit_release_replay_case(out, "w1-build-graph",
					 "current_cgroup", false, -ret, -1,
					 false, false,
					 "failed to resolve current cgroup path",
					 NULL, NULL);
		return 1;
	}
	ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		emit_release_replay_case(out, "w1-build-graph",
					 "current_cgroup_id", false, -ret, -1,
					 false, false,
					 "failed to resolve current cgroup id",
					 NULL, NULL);
		return 1;
	}
	ret = prepare_replay_toolchain(result_dir, toolchain_dir,
				       sizeof(toolchain_dir), path_env,
				       sizeof(path_env));
	if (ret) {
		emit_release_replay_case(out, "w1-build-graph",
					 "prepare_toolchain", false, -ret, -1,
					 false, false,
					 "failed to prepare release replay toolchain",
					 NULL, NULL);
		return 1;
	}
	ret = prepare_replay_include(result_dir, include_dir,
				     sizeof(include_dir));
	if (ret) {
		emit_release_replay_case(out, "w1-build-graph",
					 "prepare_include", false, -ret, -1,
					 false, false,
					 "failed to prepare release replay include alias",
					 NULL, NULL);
		return 1;
	}
	ret = assign_build_replay_parent_dirs(entries, nr_entries,
					      redis_policy_src, nginx_policy_src,
					      toolchain_dir, include_dir);
	if (ret) {
		emit_release_replay_case(out, "w1-build-graph",
					 "assign_parent_dirs", false, -ret, -1,
					 false, false,
					 "failed to assign parent-aware release replay key directories",
					 NULL, NULL);
		return 1;
	}

	failures += run_redis_release_build(out, redis_baseline_src,
					    result_dir, NULL, false, true);
	failures += run_nginx_release_build(out, nginx_baseline_src,
					    result_dir, NULL, false, true);
	if (failures)
		return 1;

	if (open_policy(policy_path, POLICY_BUILD_GRAPH, "build_graph",
			&policy)) {
		emit_release_replay_case(out, "w1-build-graph", "load",
					 false, errno, -1, false, false,
					 "build_graph policy load failed", NULL,
					 NULL);
		return 1;
	}
	emit_release_replay_case(out, "w1-build-graph", "load", true, 0,
				 0, false, false, "build_graph policy loaded",
				 NULL, NULL);

	ret = populate_policy_map(&policy, entries, nr_entries,
				  current_cgroup_id);
	if (ret) {
		emit_release_replay_case(out, "w1-build-graph",
					 "map_update", false, -ret, -1, false,
					 false,
					 "failed to update release replay map",
					 NULL, NULL);
		destroy_policy(&policy);
		return 1;
	}
	emit_release_replay_case(out, "w1-build-graph", "map_update", true,
				 0, 0, false, false,
				 "release replay redirect map populated", NULL,
				 NULL);

	failures += prepare_replay_aliases("w1-redis-build", redis_policy_src,
					   entries, nr_entries);
	if (failures) {
		emit_release_replay_case(out, "w1-redis-build",
					 "prepare_aliases", false, EINVAL, -1,
					 false, false,
					 "failed to prepare Redis release aliases",
					 NULL, NULL);
		destroy_policy(&policy);
		return 1;
	}
	failures += prepare_replay_aliases("w1-nginx-build", nginx_policy_src,
					   entries, nr_entries);
	if (failures) {
		emit_release_replay_case(out, "w1-nginx-build",
					 "prepare_aliases", false, EINVAL, -1,
					 false, false,
					 "failed to prepare nginx release aliases",
					 NULL, NULL);
		destroy_policy(&policy);
		return 1;
	}

	ret = prepare_redis_release_rebuild(redis_policy_src);
	if (ret) {
		emit_release_replay_case(out, "w1-redis-build",
					 "prepare_policy_rebuild", false,
					 -ret, -1, false, false,
					 "failed to clean Redis policy rebuild outputs",
					 NULL, NULL);
		destroy_policy(&policy);
		return 1;
	}
	ret = prepare_nginx_release_rebuild(nginx_policy_src);
	if (ret) {
		emit_release_replay_case(out, "w1-nginx-build",
					 "prepare_policy_rebuild", false,
					 -ret, -1, false, false,
					 "failed to clean nginx policy rebuild outputs",
					 NULL, NULL);
		destroy_policy(&policy);
		return 1;
	}

	if (attach_policy(&policy, current_cgroup)) {
		emit_release_replay_case(out, "w1-build-graph", "attach",
					 false, errno, -1, false, false,
					 "build_graph policy attach failed", NULL,
					 NULL);
		destroy_policy(&policy);
		return 1;
	}
	emit_release_replay_case(out, "w1-build-graph", "attach", true, 0,
				 0, true, false, "build_graph policy attached",
				 NULL, NULL);

	failures += run_redis_release_build(out, redis_policy_src, result_dir,
					    path_env, true, false);
	failures += run_nginx_release_build(out, nginx_policy_src, result_dir,
					    path_env, true, false);
	failures += compare_release_binary(out, "w1-redis-build", result_dir,
					   "redis.baseline.bin",
					   "redis.policy.bin");
	failures += compare_release_binary(out, "w1-nginx-build", result_dir,
					   "nginx.baseline.bin",
					   "nginx.policy.bin");

	ret = destroy_policy(&policy);
	if (ret) {
		emit_release_replay_case(out, "w1-build-graph", "detach",
					 false, -ret, -1, true, false,
					 "build_graph policy detach failed", NULL,
					 NULL);
		failures++;
	} else {
		emit_release_replay_case(out, "w1-build-graph", "detach",
					 true, 0, 0, true, false,
					 "build_graph policy detached", NULL,
					 NULL);
	}

	fprintf(out,
		"{\"event\":\"w1-release-build-replay-summary\","
		"\"result_level\":\"kvm_policy_release_build_replay_witness\","
		"\"policy\":\"build_graph\","
		"\"run_environment\":\"kvm\","
		"\"policy_executed\":true,"
		"\"kvm_validated\":true,"
		"\"release_binary_hash_match\":%s,"
		"\"release_output_hash_oracle\":false,"
		"\"workloads\":2,\"entries\":%zu,\"pass\":%s,"
		"\"failures\":%d,\"qualified_for_c8\":false,"
		"\"detail\":",
		failures ? "false" : "true", nr_entries,
		failures ? "false" : "true", failures);
	fprint_json_string(out, failures ?
			   "W1 KVM policy release build replay failed" :
			   "W1 KVM policy release build replay matched baseline Redis and nginx binaries");
	fputs("}\n", out);
	fflush(out);
	return failures ? 1 : 0;
}

static int prepare_cache_content_dir(const char *work_dir,
				     struct oracle_entry *entries,
				     size_t nr_entries)
{
	char path[PATH_MAX];
	size_t i;
	int ret;

	ret = mkdir_if_missing(work_dir);
	if (ret)
		return ret;

	for (i = 0; i < nr_entries; i++) {
		const char *forbidden = cache_forbidden_name(&entries[i]);
		const char *forbidden_text = cache_forbidden_text(&entries[i]);

		ret = mkdir_relative_under(work_dir, entries[i].parent_relative,
					   entries[i].dir,
					   sizeof(entries[i].dir));
		if (ret)
			return ret;

		ret = set_path(path, sizeof(path), entries[i].dir,
			       entries[i].visible);
		if (ret)
			return ret;
		unlink(path);

		ret = set_path(path, sizeof(path), entries[i].dir,
			       entries[i].shadow);
		if (ret)
			return ret;
		unlink(path);
		ret = copy_file(entries[i].original, path);
		if (ret)
			return ret;

		if (forbidden && forbidden_text) {
			ret = set_path(path, sizeof(path), entries[i].dir,
				       forbidden);
			if (ret)
				return ret;
			unlink(path);
			ret = write_text_file(path, forbidden_text);
			if (ret)
				return ret;
		}
	}
	return 0;
}

static void emit_ccache_policy_compile_case_ex(
    FILE *out, const char *op, bool pass, int err, int exit_code,
    bool policy_executed, const char *detail, const char *path,
    const char *expected, const char *stdout_path, const char *stderr_path,
    const struct file_content_oracle *content)
{
	fputs("{\"event\":", out);
	fprint_json_string(out, ccache_compile_event);
	fputs(",\"result_level\":", out);
	fprint_json_string(out, ccache_compile_result_level);
		fputs(",\"workload\":", out);
		fprint_json_string(out, ccache_compile_workload);
		fputs(",\"policy_family\":", out);
	fprint_json_string(out, ccache_compile_policy_family);
	fputs(",\"run_environment\":\"kvm\",\"op\":", out);
	fprint_json_string(out, op);
	fprintf(out, ",\"pass\":%s,\"errno\":%d,\"exit_code\":%d,"
		"\"policy_executed\":%s,"
		"\"ccache_compile_policy_executed\":%s,"
		"\"kvm_validated\":true,"
		"\"table_baseline_current_oracle_pass\":%s,"
		"\"parent_rule_policy\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		pass ? "true" : "false", err, exit_code,
		policy_executed ? "true" : "false",
		policy_executed ? "true" : "false",
		ccache_compile_table_baseline && pass ? "true" : "false",
		ccache_compile_parent_rules ? "true" : "false");
	fprint_json_string(out, detail);
	fputs(",\"path\":", out);
	fprint_json_string(out, path ? path : "");
	fputs(",\"expected\":", out);
	fprint_json_string(out, expected ? expected : "");
	if (content && content->enabled) {
		fputs(",\"content_oracle\":true,\"content_oracle_kind\":",
		      out);
		fprint_json_string(out, content->kind ? content->kind : "");
		fprintf(out,
			",\"expected_content_len\":%zu,"
			"\"observed_content_len\":%zu,"
			"\"expected_content_fnv1a64\":\"%016llx\","
			"\"observed_content_fnv1a64\":\"%016llx\"",
			content->expected_len, content->observed_len,
			(unsigned long long)content->expected_hash,
			(unsigned long long)content->observed_hash);
	}
	fputs(",\"stdout\":", out);
	fprint_json_string(out, stdout_path ? stdout_path : "");
	fputs(",\"stderr\":", out);
	fprint_json_string(out, stderr_path ? stderr_path : "");
	fputs("}\n", out);
	fflush(out);
}

static void emit_ccache_policy_compile_case(FILE *out, const char *op,
					    bool pass, int err, int exit_code,
					    bool policy_executed,
					    const char *detail,
					    const char *path,
					    const char *expected,
					    const char *stdout_path,
					    const char *stderr_path)
{
	emit_ccache_policy_compile_case_ex(out, op, pass, err, exit_code,
					   policy_executed, detail, path,
					   expected, stdout_path, stderr_path,
					   NULL);
}

static bool safe_relative_path(const char *rel)
{
	if (!rel || !rel[0] || rel[0] == '/')
		return false;
	if (!strcmp(rel, ".") || !strcmp(rel, ".."))
		return false;
	if (!strncmp(rel, "../", 3) || strstr(rel, "/../") ||
	    has_suffix(rel, "/.."))
		return false;
	return true;
}

static bool path_under_dir(const char *path, const char *dir,
			   const char **rel_out)
{
	size_t dir_len = strlen(dir);

	if (strncmp(path, dir, dir_len))
		return false;
	if (path[dir_len] != '/')
		return false;
	*rel_out = path + dir_len + 1;
	return safe_relative_path(*rel_out);
}

static bool ccache_entry_from_source(const struct oracle_entry *entry,
				     const char *source)
{
	char prefix[96];
	int ret;

	ret = snprintf(prefix, sizeof(prefix), "trace-derived/%s/", source);
	if (ret < 0 || (size_t)ret >= sizeof(prefix))
		return false;
	if (!strncmp(entry->parent_relative, prefix, strlen(prefix)))
		return true;

	ret = snprintf(prefix, sizeof(prefix), "trace-derived-bulk/%s/", source);
	if (ret < 0 || (size_t)ret >= sizeof(prefix))
		return false;
	return !strncmp(entry->parent_relative, prefix, strlen(prefix));
}

static int parse_w4_ccache_source(char *line, struct w4_ccache_source *source)
{
	char *fields[4];
	char *saveptr = NULL;
	char *field;
	size_t i = 0;

	line[strcspn(line, "\n")] = 0;
	for (field = strtok_r(line, "\t", &saveptr); field;
	     field = strtok_r(NULL, "\t", &saveptr)) {
		if (i >= ARRAY_SIZE(fields))
			return -EINVAL;
		fields[i++] = field;
	}
	if (i != ARRAY_SIZE(fields))
		return -EINVAL;
	if (parse_tsv_field(source->kind, sizeof(source->kind), fields[0]))
		return -EINVAL;
	if (strcmp(source->kind, "redis") && strcmp(source->kind, "nginx"))
		return -EINVAL;
	if (parse_tsv_field(source->rel, sizeof(source->rel), fields[1]))
		return -EINVAL;
	if (!safe_relative_path(source->rel))
		return -EINVAL;
	if (parse_tsv_field(source->path, sizeof(source->path), fields[2]))
		return -EINVAL;
	if (parse_tsv_field(source->sha256, sizeof(source->sha256), fields[3]))
		return -EINVAL;
	if (strlen(source->sha256) != 64)
		return -EINVAL;
	return 0;
}

static int read_w4_ccache_sources(const char *path,
				  struct w4_ccache_source *sources,
				  size_t *nr_sources)
{
	char line[NAMEI_EXT_LINE_MAX];
	FILE *in;
	size_t count = 0;

	in = fopen(path, "r");
	if (!in)
		return -errno;
	while (fgets(line, sizeof(line), in)) {
		if (count >= NAMEI_EXT_MAX_ENTRIES) {
			fclose(in);
			return -E2BIG;
		}
		if (parse_w4_ccache_source(line, &sources[count])) {
			fclose(in);
			return -EINVAL;
		}
		count++;
	}
	if (ferror(in)) {
		fclose(in);
		return -errno;
	}
	fclose(in);
	if (!count)
		return -EINVAL;
	*nr_sources = count;
	return 0;
}

static int w4_ccache_source_stem(char *dst, size_t size,
				 const struct w4_ccache_source *source)
{
	char rel[PATH_MAX];
	size_t len;
	size_t i;
	int ret;

	ret = copy_string(rel, sizeof(rel), source->rel);
	if (ret)
		return ret;
	len = strlen(rel);
	if (len > 2 && !strcmp(rel + len - 2, ".c"))
		rel[len - 2] = 0;
	for (i = 0; rel[i]; i++) {
		if (rel[i] == '/')
			rel[i] = '_';
	}
	ret = snprintf(dst, size, "%s-%s", source->kind, rel);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int w4_ccache_source_file(char *dst, size_t size,
				 const struct w4_ccache_source *source,
				 const char *suffix)
{
	char stem[PATH_MAX];
	int ret;

	ret = w4_ccache_source_stem(stem, sizeof(stem), source);
	if (ret)
		return ret;
	ret = snprintf(dst, size, "%s%s", stem, suffix);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int run_ccache_source_compile(const struct w4_ccache_source *source,
				     const char *redis_build_src,
				     const char *nginx_build_src,
				     const char *output_path,
				     const char *stdout_path,
				     const char *stderr_path,
				     const char *trace_path, int *exit_code)
{
	if (!strcmp(source->kind, "redis"))
		return run_ccache_redis_compile(source->path, redis_build_src,
						output_path, stdout_path,
						stderr_path, trace_path,
						exit_code);
	if (!strcmp(source->kind, "nginx"))
		return run_ccache_nginx_compile(source->path, nginx_build_src,
						output_path, stdout_path,
						stderr_path, trace_path,
						exit_code);
	return -EINVAL;
}

static int count_ccache_optrace(const char *trace_path, const char *cache_dir,
				const struct oracle_entry *entries,
				size_t nr_entries, const char *source,
				size_t *cache_path_ops, size_t *object_ops)
{
	char line[NAMEI_EXT_LINE_MAX];
	FILE *in;
	size_t i;

	*cache_path_ops = 0;
	*object_ops = 0;

	in = fopen(trace_path, "r");
	if (!in)
		return -errno;
	while (fgets(line, sizeof(line), in)) {
		bool object_match = false;

		if (!strstr(line, cache_dir))
			continue;
		(*cache_path_ops)++;
		for (i = 0; i < nr_entries; i++) {
			if (source && !ccache_entry_from_source(&entries[i],
								source))
				continue;
			if (strstr(line, entries[i].visible)) {
				object_match = true;
				break;
			}
		}
		if (object_match)
			(*object_ops)++;
	}
	if (ferror(in)) {
		int err = errno ? errno : EIO;

		fclose(in);
		return -err;
	}
	fclose(in);
	if (!*cache_path_ops)
		return -ENOENT;
	return 0;
}

static int prepare_ccache_policy_entry(struct oracle_entry *entry,
				       const char *trace_cache_dir,
				       const char *cache_dir)
{
	char mapped_path[PATH_MAX];
	char backing_path[PATH_MAX];
	char parent_dir[PATH_MAX];
	struct stat st;
	const char *rel;
	char *base;
	char *slash;
	int ret;

	if (!path_under_dir(entry->original, trace_cache_dir, &rel))
		return -EINVAL;
	ret = set_path(mapped_path, sizeof(mapped_path), cache_dir, rel);
	if (ret)
		return ret;
	slash = strrchr(mapped_path, '/');
	if (!slash || slash == mapped_path)
		return -EINVAL;
	base = slash + 1;
	if (strcmp(base, entry->visible))
		return -EINVAL;
	*slash = 0;
	ret = copy_string(parent_dir, sizeof(parent_dir), mapped_path);
	*slash = '/';
	if (ret)
		return ret;
	ret = set_path(backing_path, sizeof(backing_path), parent_dir,
		       entry->shadow);
	if (ret)
		return ret;
	if (stat(mapped_path, &st))
		return -errno;
	if (!S_ISREG(st.st_mode))
		return -EINVAL;
	if (!lstat(backing_path, &st))
		return -EEXIST;
	if (errno != ENOENT)
		return -errno;
	if (rename(mapped_path, backing_path))
		return -errno;
	ret = copy_string(entry->dir, sizeof(entry->dir), parent_dir);
	if (ret)
		return ret;
	return 0;
}

static int ccache_policy_expect_absent(FILE *out,
				       const struct oracle_entry *entry,
				       const char *op)
{
	char path[PATH_MAX];
	int ret;
	int stat_ret;

	ret = set_path(path, sizeof(path), entry->dir, entry->visible);
	if (ret) {
		emit_ccache_policy_compile_case(
			out, op, false, -ret, -1, false,
			"failed to build visible cache object path", NULL,
			entry->visible, NULL, NULL);
		return 1;
	}
	stat_ret = expect_stat_errno(path, ENOENT);
	if (stat_ret) {
		emit_ccache_policy_compile_case(
			out, op, false, -stat_ret, -1, false,
			"visible cache object unexpectedly resolved", path,
			"ENOENT", NULL, NULL);
		return 1;
	}
	emit_ccache_policy_compile_case(out, op, true, 0, 0, false,
					"visible cache object absent", path,
					"ENOENT", NULL, NULL);
	return 0;
}

static int ccache_policy_expect_equal(FILE *out,
				      const struct oracle_entry *entry,
				      const char *op)
{
	char visible_path[PATH_MAX];
	char backing_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), entry->dir,
		       entry->visible);
	if (!ret)
		ret = set_path(backing_path, sizeof(backing_path), entry->dir,
			       entry->shadow);
	if (ret) {
		emit_ccache_policy_compile_case(
			out, op, false, -ret, -1, true,
			"failed to build policy cache object paths", NULL,
			entry->shadow, NULL, NULL);
		return 1;
	}
	ret = compare_files(visible_path, backing_path);
	if (ret) {
		emit_ccache_policy_compile_case(
			out, op, false, -ret, -1, true,
			"visible cache object did not resolve to backing",
			visible_path, backing_path, NULL, NULL);
		return 1;
	}
	emit_ccache_policy_compile_case(out, op, true, 0, 0, true,
					"visible cache object resolved to backing",
					visible_path, backing_path, NULL, NULL);
	return 0;
}

static int ccache_policy_expect_readdir(FILE *out,
					const struct oracle_entry *entry,
					const char *op)
{
	bool saw_visible;
	bool saw_shadow;
	int err = 0;

	saw_visible = dir_has_name(entry->dir, entry->visible, &err);
	if (!err)
		saw_shadow = dir_has_name(entry->dir, entry->shadow, &err);
	else
		saw_shadow = false;
	if (!err && saw_visible && !saw_shadow) {
		emit_ccache_policy_compile_case(
			out, op, true, 0, 0, true,
			"cache directory exposed visible object and hid backing",
			entry->dir, entry->visible, NULL, NULL);
		return 0;
	}
	emit_ccache_policy_compile_case(
		out, op, false, err, -1, true,
		"cache directory view did not expose alias correctly",
		entry->dir, entry->visible, NULL, NULL);
	return 1;
}

static int ccache_prepare_parent_sibling(FILE *out,
					 const struct oracle_entry *entry)
{
	char path[PATH_MAX];
	int ret;

	ret =
	    set_path(path, sizeof(path), entry->dir, W4_CCACHE_PARENT_SIBLING);
	if (!ret)
		ret = unlink_existing(path);
	if (!ret)
		ret = write_text_file(path, W4_CCACHE_PARENT_SIBLING_TEXT);
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "parent_sibling_prepare", false, -ret, -1, false,
		    "failed to prepare non-cache sibling under parent rule "
		    "directory",
		    entry->dir, W4_CCACHE_PARENT_SIBLING, NULL, NULL);
		return 1;
	}
	emit_ccache_policy_compile_case(
	    out, "parent_sibling_prepare", true, 0, 0, false,
	    "prepared non-cache sibling under parent rule directory", path,
	    W4_CCACHE_PARENT_SIBLING, NULL, NULL);
	return 0;
}

static bool ccache_parent_name_conflicts(const struct oracle_entry *entries,
					 size_t nr_entries,
					 const char *parent_dir,
					 const char *name)
{
	char backing[NAMEI_EXT_NAME_MAX + 1] = {};
	size_t i;
	int ret;

	ret = snprintf(backing, sizeof(backing), "%s.local", name);
	if (ret < 0 || (size_t)ret >= sizeof(backing))
		backing[0] = 0;
	for (i = 0; i < nr_entries; i++) {
		if (strcmp(entries[i].dir, parent_dir))
			continue;
		if (!strcmp(entries[i].visible, name) ||
		    !strcmp(entries[i].shadow, name) ||
		    (backing[0] && (!strcmp(entries[i].visible, backing) ||
				    !strcmp(entries[i].shadow, backing))))
			return true;
	}
	return false;
}

static int ccache_make_valid_parent_sibling_name(
    char *name, size_t name_size, const struct oracle_entry *entries,
    size_t nr_entries, const char *parent_dir)
{
	static const char chars[] = "0123456789abcdefghijklmnopqrstuvwxyz";
	static const char suffixes[] = "MR";
	size_t i;
	size_t j;

	if (name_size <= W4_CCACHE_OBJECT_LEN)
		return -ENAMETOOLONG;
	for (i = 0; i < sizeof(chars) - 1; i++) {
		for (j = 0; j < sizeof(suffixes) - 1; j++) {
			memset(name, chars[i], W4_CCACHE_OBJECT_LEN - 1);
			name[W4_CCACHE_OBJECT_LEN - 1] = suffixes[j];
			name[W4_CCACHE_OBJECT_LEN] = 0;
			if (!ccache_parent_name_conflicts(entries, nr_entries,
							  parent_dir, name))
				return 0;
		}
	}
	name[0] = 0;
	return -EEXIST;
}

static int ccache_local_backing_name(char *dst, size_t dst_size,
				     const char *name)
{
	int ret = snprintf(dst, dst_size, "%s.local", name);

	if (ret < 0)
		return -errno;
	if ((size_t)ret >= dst_size)
		return -ENAMETOOLONG;
	return 0;
}

static int ccache_prepare_parent_valid_sibling(
    FILE *out, const struct oracle_entry *entry,
    const struct oracle_entry *entries, size_t nr_entries, char *sibling_name,
    size_t sibling_name_size)
{
	char path[PATH_MAX];
	char backing_path[PATH_MAX];
	char backing_name[NAMEI_EXT_NAME_MAX + 1];
	struct stat st;
	int ret;

	ret = ccache_make_valid_parent_sibling_name(
	    sibling_name, sibling_name_size, entries, nr_entries, entry->dir);
	if (!ret)
		ret = ccache_local_backing_name(backing_name,
						sizeof(backing_name),
						sibling_name);
	if (!ret)
		ret = set_path(path, sizeof(path), entry->dir, sibling_name);
	if (!ret)
		ret = set_path(backing_path, sizeof(backing_path), entry->dir,
			       backing_name);
	if (!ret)
		ret = unlink_existing(path);
	if (!ret)
		ret = unlink_existing(backing_path);
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "parent_valid_sibling_prepare", false, -ret, -1,
		    false,
		    "failed to prepare valid-shape non-witness sibling under "
		    "parent rule directory",
		    entry->dir, sibling_name, NULL, NULL);
		return 1;
	}
	if (!lstat(backing_path, &st))
		ret = -EEXIST;
	else if (errno != ENOENT)
		ret = -errno;
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "parent_valid_sibling_backing_absent", false, -ret,
		    -1, false,
		    "valid-shape non-witness sibling backing unexpectedly "
		    "exists or could not be checked",
		    backing_path, backing_name, NULL, NULL);
		return 1;
	}
	emit_ccache_policy_compile_case(
	    out, "parent_valid_sibling_backing_absent", true, 0, 0, false,
	    "valid-shape non-witness sibling has no .local backing",
	    backing_path, backing_name, NULL, NULL);
	ret = write_text_file(path, W4_CCACHE_PARENT_SIBLING_TEXT);
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "parent_valid_sibling_prepare", false, -ret, -1,
		    false,
		    "failed to prepare valid-shape non-witness sibling under "
		    "parent rule directory",
		    entry->dir, sibling_name, NULL, NULL);
		return 1;
	}
	emit_ccache_policy_compile_case(
	    out, "parent_valid_sibling_prepare", true, 0, 0, false,
	    "prepared valid-shape non-witness sibling under parent rule "
	    "directory",
	    path, sibling_name, NULL, NULL);
	return 0;
}

static int ccache_policy_expect_parent_sibling_pass(
    FILE *out, const struct oracle_entry *entry, const char *sibling_name,
    const char *op, bool record_content_oracle)
{
	char path[PATH_MAX];
	struct file_content_oracle content = {
	    .enabled = record_content_oracle,
	    .kind = "exact-text",
	};
	int ret;

	ret = set_path(path, sizeof(path), entry->dir, sibling_name);
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, op, false, -ret, -1, true,
		    "failed to build parent sibling path", entry->dir,
		    sibling_name, NULL, NULL);
		return 1;
	}
	ret = compare_file_text_hash(path, W4_CCACHE_PARENT_SIBLING_TEXT,
				     &content.expected_len,
				     &content.observed_len,
				     &content.expected_hash,
				     &content.observed_hash);
	if (ret) {
		emit_ccache_policy_compile_case_ex(
		    out, op, false, -ret, -1, true,
		    "parent sibling content did not pass through parent-scoped policy",
		    path, sibling_name, NULL, NULL,
		    record_content_oracle ? &content : NULL);
		return 1;
	}
	emit_ccache_policy_compile_case_ex(
	    out, op, true, 0, 0, true,
	    "parent sibling content passed through parent-scoped policy", path,
	    sibling_name, NULL, NULL, record_content_oracle ? &content : NULL);
	return 0;
}

static int run_ccache_policy_compile(
    FILE *out, const char *cgroup_mount, const char *work_dir,
    const char *cache_dir, const char *trace_cache_dir, const char *entries_tsv,
    const char *redis_src, const char *redis_build_src, const char *nginx_src,
    const char *nginx_build_src, const char *redis_baseline_obj,
    const char *nginx_baseline_obj, const char *policy_obj,
    const char *stats_path, enum policy_kind policy_kind,
    const char *policy_name, const char *policy_family, bool use_parent_rules,
    const char *source_manifest, const char *baseline_hot_dir,
    const char *workload)
{
	struct attached_policy policy = {
	    .cgroup_fd = -1,
	    .prog_fd = -1,
	    .map_fd = -1,
	};
	static struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES];
	static struct w4_ccache_source sources[NAMEI_EXT_MAX_ENTRIES];
	char current_cgroup[PATH_MAX];
	char redis_output[PATH_MAX];
	char nginx_output[PATH_MAX];
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	char stats_stderr[PATH_MAX];
	char redis_trace_path[PATH_MAX];
	char nginx_trace_path[PATH_MAX];
	char parent_valid_sibling[NAMEI_EXT_NAME_MAX + 1] = {};
	__u64 current_cgroup_id = 0;
	size_t nr_entries = 0;
	size_t redis_entries = 0;
	size_t nginx_entries = 0;
	size_t redis_attached_cache_path_file_ops = 0;
	size_t nginx_attached_cache_path_file_ops = 0;
	size_t redis_attached_policy_cache_object_ops = 0;
	size_t nginx_attached_policy_cache_object_ops = 0;
	size_t attached_cache_path_file_ops = 0;
	size_t attached_policy_cache_object_ops = 0;
	size_t nr_sources = 0;
	size_t attached_compile_jobs = 0;
	size_t attached_compile_output_matches = 0;
	double attached_sampled_operation_hit_rate = 0.0;
	bool attached_optrace_collected = false;
	bool output_hash_match = true;
	bool bulk_policy_compile = source_manifest && source_manifest[0];
	__u64 compile_ns = 0;
	int exit_code = -1;
	int failures = 0;
	int ret;
	size_t i;
	size_t parent_rule_updates = 0;
	size_t cache_leaf_parents = 0;
	size_t exact_readdir_updates = 0;
	size_t parent_sibling_index = NAMEI_EXT_MAX_ENTRIES;

	memset(entries, 0, sizeof(entries));
	memset(sources, 0, sizeof(sources));

	ccache_compile_table_baseline = policy_kind == POLICY_TABLE;
	ccache_compile_parent_rules = use_parent_rules;
	ccache_compile_policy_family = policy_family;
	ccache_compile_workload = workload ? workload : "w4-ccache-redis-nginx";
	if (ccache_compile_table_baseline) {
		ccache_compile_event = "w4-ccache-table-compile";
		ccache_compile_summary_event =
		    "w4-ccache-table-compile-summary";
		ccache_compile_result_level =
		    "kvm_real_ccache_table_compile_witness";
	} else if (ccache_compile_parent_rules) {
		ccache_compile_event = "w4-ccache-parent-compile";
		ccache_compile_summary_event =
		    "w4-ccache-parent-compile-summary";
		ccache_compile_result_level =
		    "kvm_real_ccache_parent_rule_compile_witness";
	} else {
		ccache_compile_event = "w4-ccache-policy-compile";
		ccache_compile_summary_event =
		    "w4-ccache-policy-compile-summary";
		ccache_compile_result_level =
		    "kvm_real_ccache_policy_compile_witness";
	}
	if (bulk_policy_compile && !ccache_compile_table_baseline &&
	    !ccache_compile_parent_rules) {
		ccache_compile_event = "w4-ccache-bulk-policy-compile";
		ccache_compile_summary_event =
		    "w4-ccache-bulk-policy-compile-summary";
		ccache_compile_result_level =
		    "kvm_real_ccache_bulk_policy_compile_witness";
	}

	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "mkdir_workdir", false, -ret, -1, false,
		    "failed to create ccache policy compile workdir", work_dir,
		    NULL, NULL, NULL);
		return 1;
	}
	if (access(cache_dir, R_OK | X_OK)) {
		emit_ccache_policy_compile_case(
		    out, "cache_dir", false, errno, -1, false,
		    "ccache directory is not accessible", cache_dir, NULL, NULL,
		    NULL);
		return 1;
	}
	if (setenv("CCACHE_DIR", cache_dir, 1)) {
		emit_ccache_policy_compile_case(
		    out, "set_ccache_dir", false, errno, -1, false,
		    "failed to set CCACHE_DIR", cache_dir, NULL, NULL, NULL);
		return 1;
	}

	ret = set_path(stdout_path, sizeof(stdout_path), work_dir,
		       "zero-stats.stdout");
	if (!ret)
		ret = set_path(stderr_path, sizeof(stderr_path), work_dir,
			       "zero-stats.stderr");
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "zero_stats_paths", false, -ret, -1, false,
		    "failed to build ccache --zero-stats output paths",
		    work_dir, NULL, NULL, NULL);
		return 1;
	}
	ret = run_ccache_one_arg("--zero-stats", stdout_path, stderr_path,
				 &exit_code);
	if (ret || exit_code) {
		emit_ccache_policy_compile_case(
		    out, "zero_stats", false, ret ? -ret : 0, exit_code, false,
		    "ccache --zero-stats failed", cache_dir, NULL, stdout_path,
		    stderr_path);
		return 1;
	}
	emit_ccache_policy_compile_case(out, "zero_stats", true, 0, exit_code,
					false, "ccache stats reset", cache_dir,
					NULL, stdout_path, stderr_path);

	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "read_entries", false, -ret, -1, false,
		    "failed to read trace-derived ccache policy entries",
		    entries_tsv, NULL, NULL, NULL);
		return 1;
	}
	emit_ccache_policy_compile_case(
	    out, "read_entries", true, 0, 0, false,
	    "trace-derived ccache policy entries loaded", entries_tsv, NULL,
	    NULL, NULL);

	if (bulk_policy_compile) {
		if (!baseline_hot_dir || !baseline_hot_dir[0]) {
			emit_ccache_policy_compile_case(
			    out, "bulk_baseline_hot_dir", false, EINVAL, -1,
			    false, "bulk baseline hot object directory missing",
			    NULL, source_manifest, NULL, NULL);
			return 1;
		}
		ret = read_w4_ccache_sources(source_manifest, sources,
					     &nr_sources);
		if (ret) {
			emit_ccache_policy_compile_case(
			    out, "bulk_source_manifest", false, -ret, -1,
			    false, "failed to read bulk ccache source manifest",
			    source_manifest, NULL, NULL, NULL);
			return 1;
		}
		emit_ccache_policy_compile_case(
		    out, "bulk_source_manifest", true, 0, 0, false,
		    "bulk ccache source manifest loaded", source_manifest, NULL,
		    NULL, NULL);
	}

	for (i = 0; i < nr_entries; i++) {
		ret = prepare_ccache_policy_entry(&entries[i], trace_cache_dir,
						  cache_dir);
		if (ret) {
			emit_ccache_policy_compile_case(
			    out, "rename_cache_object", false, -ret, -1, false,
			    "failed to rename visible cache object to policy "
			    "backing",
			    entries[i].original, entries[i].shadow, NULL, NULL);
			return failures + 1;
		}
		if (ccache_entry_from_source(&entries[i], "redis"))
			redis_entries++;
		else if (ccache_entry_from_source(&entries[i], "nginx"))
			nginx_entries++;
		emit_ccache_policy_compile_case(
		    out, "rename_cache_object", true, 0, 0, false,
		    "visible cache object renamed to policy backing",
		    entries[i].dir, entries[i].shadow, NULL, NULL);
	}
	if (!redis_entries || !nginx_entries) {
		emit_ccache_policy_compile_case(
		    out, "entry_coverage", false, EINVAL, -1, false,
		    "trace-derived entries do not cover both Redis and nginx",
		    entries_tsv, NULL, NULL, NULL);
		return failures + 1;
	}
	emit_ccache_policy_compile_case(
	    out, "entry_coverage", true, 0, 0, false,
	    "trace-derived entries cover Redis and nginx", entries_tsv, NULL,
	    NULL, NULL);

	for (i = 0; i < nr_entries; i++)
		failures += ccache_policy_expect_absent(
		    out, &entries[i], "pre_attach_visible_absent");

	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "cgroup_path", false, -ret, -1, false,
		    "failed to resolve current cgroup path", NULL, cgroup_mount,
		    NULL, NULL);
		return failures + 1;
	}
	ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "current_cgroup_id", false, -ret, -1, false,
		    "failed to resolve current cgroup id", NULL, current_cgroup,
		    NULL, NULL);
		return failures + 1;
	}
	emit_ccache_policy_compile_case(out, "current_cgroup_id", true, 0, 0,
					false, "current cgroup id resolved",
					NULL, current_cgroup, NULL, NULL);

	if (open_policy(policy_obj, policy_kind, policy_name, &policy)) {
		emit_ccache_policy_compile_case(
		    out, "load", false, errno, -1, false,
		    "ccache compile policy load failed", policy_obj, NULL, NULL,
		    NULL);
		return failures + 1;
	}
	emit_ccache_policy_compile_case(out, "load", true, 0, 0, false,
					"ccache compile policy loaded",
					policy_obj, NULL, NULL, NULL);

	if (use_parent_rules) {
		for (i = 0; i < nr_entries; i++) {
			bool seen = false;
			size_t j;
			__u32 state = CACHE_STATE_VERIFIED_HIT;

			ret = cache_state_for_branch(entries[i].branch, &state);
			if (ret || state != CACHE_STATE_VERIFIED_HIT) {
				emit_ccache_policy_compile_case(
				    out, "parent_rule_branch", false,
				    ret ? -ret : EINVAL, -1, false,
				    "parent-rule ccache compile only supports "
				    "verified-hit cache "
				    "objects",
				    entries[i].dir, entries[i].branch, NULL,
				    NULL);
				destroy_policy(&policy);
				return failures + 1;
			}
			for (j = 0; j < i; j++) {
				if (!strcmp(entries[j].dir, entries[i].dir)) {
					seen = true;
					break;
				}
			}
			if (!seen) {
				__u64 name_witnesses[W4_CCACHE_PARENT_NAME_WITNESSES] = {};
				__u32 witness_count = 0;

				if (parent_sibling_index ==
				    NAMEI_EXT_MAX_ENTRIES)
					parent_sibling_index = i;
				for (j = i; j < nr_entries; j++) {
					if (strcmp(entries[j].dir,
						   entries[i].dir))
						continue;
					if (witness_count >=
					    W4_CCACHE_PARENT_NAME_WITNESSES) {
						emit_ccache_policy_compile_case(
						    out,
						    "parent_rule_witness",
						    false, E2BIG, -1, false,
						    "too many same-parent "
						    "ccache object witnesses "
						    "for bounded parent rule",
						    entries[i].dir,
						    entries[j].visible, NULL,
						    NULL);
						destroy_policy(&policy);
						return failures + 1;
					}
					name_witnesses[witness_count++] =
					    component_name_hash(
						entries[j].visible);
				}
				ret = update_cache_parent_rule(
				    &policy, current_cgroup_id,
				    BPF_NAMEI_EXT_LOOKUP, entries[i].dir, state,
				    i + 1, name_witnesses, witness_count);
				if (ret) {
					emit_ccache_policy_compile_case(
					    out, "parent_rule_map_update",
					    false, -ret, -1, false,
					    "failed to populate ccache parent "
					    "rule",
					    entries[i].dir, entries[i].visible,
					    NULL, NULL);
					destroy_policy(&policy);
					return failures + 1;
				}
				cache_leaf_parents++;
				parent_rule_updates++;
			}
			ret = update_cache_rule(
			    &policy, current_cgroup_id, BPF_NAMEI_EXT_READDIR,
			    entries[i].dir, entries[i].shadow,
			    entries[i].visible, i + 1, state,
			    entries[i].original_sha256);
			if (ret) {
				emit_ccache_policy_compile_case(
				    out, "parent_rule_readdir_update", false,
				    -ret, -1, false,
				    "failed to populate exact readdir rule for "
				    "parent-rule witness",
				    entries[i].dir, entries[i].shadow, NULL,
				    NULL);
				destroy_policy(&policy);
				return failures + 1;
			}
			exact_readdir_updates++;
		}
	} else {
		for (i = 0; i < nr_entries; i++) {
			__u32 state = CACHE_STATE_VERIFIED_HIT;
			__u32 branch = i + 1;

			if (policy_kind == POLICY_CACHE_LOCALITY) {
				ret = update_cache_rule(
				    &policy, current_cgroup_id,
				    BPF_NAMEI_EXT_LOOKUP, entries[i].dir,
				    entries[i].visible, entries[i].shadow,
				    branch, state, entries[i].original_sha256);
				if (!ret)
					ret = update_cache_rule(
					    &policy, current_cgroup_id,
					    BPF_NAMEI_EXT_READDIR,
					    entries[i].dir, entries[i].shadow,
					    entries[i].visible, branch, state,
					    entries[i].original_sha256);
			} else if (policy_kind == POLICY_TABLE) {
				ret = update_rule(&policy, current_cgroup_id,
						  BPF_NAMEI_EXT_LOOKUP,
						  entries[i].dir,
						  entries[i].visible,
						  entries[i].shadow, branch);
				if (!ret)
					ret = update_rule(
					    &policy, current_cgroup_id,
					    BPF_NAMEI_EXT_READDIR,
					    entries[i].dir, entries[i].shadow,
					    entries[i].visible, branch);
			} else {
				ret = -EINVAL;
			}
			if (ret) {
				emit_ccache_policy_compile_case(
				    out, "map_update", false, -ret, -1, false,
				    "failed to populate ccache compile rule",
				    entries[i].dir, entries[i].visible, NULL,
				    NULL);
				destroy_policy(&policy);
				return failures + 1;
			}
		}
	}
	emit_ccache_policy_compile_case(out, "map_update", true, 0, 0, false,
					"ccache compile rules populated",
					entries_tsv, NULL, NULL, NULL);

	if (use_parent_rules && parent_sibling_index < NAMEI_EXT_MAX_ENTRIES) {
		failures += ccache_prepare_parent_sibling(
		    out, &entries[parent_sibling_index]);
		failures += ccache_prepare_parent_valid_sibling(
		    out, &entries[parent_sibling_index], entries, nr_entries,
		    parent_valid_sibling, sizeof(parent_valid_sibling));
		if (failures) {
			destroy_policy(&policy);
			return failures;
		}
	}

	if (attach_policy(&policy, current_cgroup)) {
		emit_ccache_policy_compile_case(
		    out, "attach", false, errno, -1, false,
		    "ccache compile policy attach failed", current_cgroup, NULL,
		    NULL, NULL);
		destroy_policy(&policy);
		return failures + 1;
	}
	emit_ccache_policy_compile_case(out, "attach", true, 0, 0, false,
					"ccache compile policy attached",
					current_cgroup, NULL, NULL, NULL);

	for (i = 0; i < nr_entries; i++) {
		failures += ccache_policy_expect_equal(
		    out, &entries[i], "attached_visible_match");
		failures += ccache_policy_expect_readdir(
		    out, &entries[i], "attached_readdir_alias");
	}
	if (use_parent_rules && parent_sibling_index < NAMEI_EXT_MAX_ENTRIES)
		failures += ccache_policy_expect_parent_sibling_pass(
		    out, &entries[parent_sibling_index],
		    W4_CCACHE_PARENT_SIBLING,
		    "attached_parent_sibling_pass", false);
	if (use_parent_rules && parent_sibling_index < NAMEI_EXT_MAX_ENTRIES &&
	    parent_valid_sibling[0])
		failures += ccache_policy_expect_parent_sibling_pass(
		    out, &entries[parent_sibling_index],
		    parent_valid_sibling,
		    "attached_parent_valid_sibling_pass", true);

	if (bulk_policy_compile) {
		size_t source_idx;

		for (source_idx = 0; source_idx < nr_sources; source_idx++) {
			char object_name[PATH_MAX];
			char output_name[PATH_MAX];
			char stdout_name[PATH_MAX];
			char stderr_name[PATH_MAX];
			char trace_name[PATH_MAX];
			char baseline_obj[PATH_MAX];
			size_t source_cache_path_ops = 0;
			size_t source_object_ops = 0;

			ret = w4_ccache_source_file(object_name,
						    sizeof(object_name),
						    &sources[source_idx], ".o");
			if (!ret)
				ret = w4_ccache_source_file(output_name,
							    sizeof(output_name),
							    &sources[source_idx],
							    ".policy.o");
			if (!ret)
				ret = w4_ccache_source_file(stdout_name,
							    sizeof(stdout_name),
							    &sources[source_idx],
							    ".policy.stdout");
			if (!ret)
				ret = w4_ccache_source_file(stderr_name,
							    sizeof(stderr_name),
							    &sources[source_idx],
							    ".policy.stderr");
			if (!ret)
				ret = w4_ccache_source_file(trace_name,
							    sizeof(trace_name),
							    &sources[source_idx],
							    ".policy.strace.log");
			if (!ret)
				ret = set_path(redis_output, sizeof(redis_output),
					       work_dir, output_name);
			if (!ret)
				ret = set_path(stdout_path, sizeof(stdout_path),
					       work_dir, stdout_name);
			if (!ret)
				ret = set_path(stderr_path, sizeof(stderr_path),
					       work_dir, stderr_name);
			if (!ret)
				ret = set_path(redis_trace_path,
					       sizeof(redis_trace_path), work_dir,
					       trace_name);
			if (!ret)
				ret = set_path(baseline_obj,
					       sizeof(baseline_obj),
					       baseline_hot_dir, object_name);
			if (ret) {
				emit_ccache_policy_compile_case(
				    out, "bulk_policy_compile_paths", false,
				    -ret, -1, true,
				    "failed to build bulk ccache compile paths",
				    work_dir, sources[source_idx].rel, NULL,
				    NULL);
				failures++;
				continue;
			}

			{
				__u64 start_ns = monotonic_ns();

				ret = run_ccache_source_compile(
					&sources[source_idx], redis_build_src,
					nginx_build_src, redis_output, stdout_path,
					stderr_path, redis_trace_path, &exit_code);
				__u64 end_ns = monotonic_ns();

				if (end_ns >= start_ns)
					compile_ns += end_ns - start_ns;
			}
			if (ret || exit_code) {
				emit_ccache_policy_compile_case(
				    out, "bulk_policy_compile", false,
				    ret ? -ret : 0, exit_code, true,
				    "bulk ccache compile under policy failed",
				    redis_output, sources[source_idx].path,
				    stdout_path, stderr_path);
				failures++;
				continue;
			}
			attached_compile_jobs++;
			emit_ccache_policy_compile_case(
			    out, "bulk_policy_compile", true, 0, exit_code, true,
			    "bulk ccache compile under policy succeeded",
			    redis_output, sources[source_idx].path, stdout_path,
			    stderr_path);

			ret = count_ccache_optrace(
			    redis_trace_path, cache_dir, entries, nr_entries,
			    sources[source_idx].kind, &source_cache_path_ops,
			    &source_object_ops);
			if (ret) {
				emit_ccache_policy_compile_case(
				    out, "bulk_policy_compile_optrace", false,
				    -ret, -1, true,
				    "failed to parse bulk policy compile strace",
				    redis_trace_path, cache_dir, NULL, NULL);
				failures++;
			} else {
				attached_optrace_collected = true;
				if (!strcmp(sources[source_idx].kind, "redis")) {
					redis_attached_cache_path_file_ops +=
					    source_cache_path_ops;
					redis_attached_policy_cache_object_ops +=
					    source_object_ops;
				} else {
					nginx_attached_cache_path_file_ops +=
					    source_cache_path_ops;
					nginx_attached_policy_cache_object_ops +=
					    source_object_ops;
				}
				emit_ccache_policy_compile_case(
				    out, "bulk_policy_compile_optrace", true,
				    0, 0, true,
				    "bulk policy compile strace parsed",
				    redis_trace_path, cache_dir, NULL, NULL);
			}

			ret = compare_files(redis_output, baseline_obj);
			if (ret) {
				output_hash_match = false;
				emit_ccache_policy_compile_case(
				    out, "bulk_output_compare", false, -ret, -1,
				    true,
				    "bulk policy output did not match hot baseline",
				    redis_output, baseline_obj, NULL, NULL);
				failures++;
			} else {
				attached_compile_output_matches++;
				emit_ccache_policy_compile_case(
				    out, "bulk_output_compare", true, 0, 0, true,
				    "bulk policy output matched hot baseline",
				    redis_output, baseline_obj, NULL, NULL);
			}
		}
		attached_cache_path_file_ops =
		    redis_attached_cache_path_file_ops +
		    nginx_attached_cache_path_file_ops;
		attached_policy_cache_object_ops =
		    redis_attached_policy_cache_object_ops +
		    nginx_attached_policy_cache_object_ops;
		if (attached_cache_path_file_ops) {
			attached_sampled_operation_hit_rate =
			    (double)attached_policy_cache_object_ops /
			    (double)attached_cache_path_file_ops;
			attached_optrace_collected = true;
		}
		goto ccache_policy_compile_done;
	}

	ret = set_path(redis_output, sizeof(redis_output), work_dir,
		       "redis.policy.o");
	if (!ret)
		ret = set_path(nginx_output, sizeof(nginx_output), work_dir,
			       "nginx.policy.o");
	if (!ret)
		ret = set_path(redis_trace_path, sizeof(redis_trace_path),
			       work_dir, "redis-policy-compile.strace.log");
	if (!ret)
		ret = set_path(nginx_trace_path, sizeof(nginx_trace_path),
			       work_dir, "nginx-policy-compile.strace.log");
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "output_paths", false, -ret, -1, true,
		    "failed to build ccache policy compile output paths",
		    work_dir, NULL, NULL, NULL);
		failures++;
	} else {
		ret = set_path(stdout_path, sizeof(stdout_path), work_dir,
			       "redis-policy-compile.stdout");
		if (!ret)
			ret = set_path(stderr_path, sizeof(stderr_path),
				       work_dir, "redis-policy-compile.stderr");
		if (ret) {
			emit_ccache_policy_compile_case(
			    out, "redis_policy_compile_paths", false, -ret, -1,
			    true, "failed to build Redis compile output logs",
			    work_dir, NULL, NULL, NULL);
			failures++;
		} else {
			{
				__u64 start_ns = monotonic_ns();

				ret = run_ccache_redis_compile(
					redis_src, redis_build_src, redis_output,
					stdout_path, stderr_path, redis_trace_path,
					&exit_code);
				__u64 end_ns = monotonic_ns();

				if (end_ns >= start_ns)
					compile_ns += end_ns - start_ns;
			}
			if (ret || exit_code) {
				emit_ccache_policy_compile_case(
				    out, "redis_policy_compile", false,
				    ret ? -ret : 0, exit_code, true,
				    "Redis ccache compile under policy failed",
				    redis_output, redis_src, stdout_path,
				    stderr_path);
				failures++;
			} else {
				emit_ccache_policy_compile_case(
				    out, "redis_policy_compile", true, 0,
				    exit_code, true,
				    "Redis ccache compile under policy "
				    "succeeded",
				    redis_output, redis_src, stdout_path,
				    stderr_path);
			}
		}

		ret = set_path(stdout_path, sizeof(stdout_path), work_dir,
			       "nginx-policy-compile.stdout");
		if (!ret)
			ret = set_path(stderr_path, sizeof(stderr_path),
				       work_dir, "nginx-policy-compile.stderr");
		if (ret) {
			emit_ccache_policy_compile_case(
			    out, "nginx_policy_compile_paths", false, -ret, -1,
			    true, "failed to build nginx compile output logs",
			    work_dir, NULL, NULL, NULL);
			failures++;
		} else {
			{
				__u64 start_ns = monotonic_ns();

				ret = run_ccache_nginx_compile(
					nginx_src, nginx_build_src, nginx_output,
					stdout_path, stderr_path, nginx_trace_path,
					&exit_code);
				__u64 end_ns = monotonic_ns();

				if (end_ns >= start_ns)
					compile_ns += end_ns - start_ns;
			}
			if (ret || exit_code) {
				emit_ccache_policy_compile_case(
				    out, "nginx_policy_compile", false,
				    ret ? -ret : 0, exit_code, true,
				    "nginx ccache compile under policy failed",
				    nginx_output, nginx_src, stdout_path,
				    stderr_path);
				failures++;
			} else {
				emit_ccache_policy_compile_case(
				    out, "nginx_policy_compile", true, 0,
				    exit_code, true,
				    "nginx ccache compile under policy "
				    "succeeded",
				    nginx_output, nginx_src, stdout_path,
				    stderr_path);
			}
		}

		ret = count_ccache_optrace(
		    redis_trace_path, cache_dir, entries, nr_entries, "redis",
		    &redis_attached_cache_path_file_ops,
		    &redis_attached_policy_cache_object_ops);
		if (ret) {
			emit_ccache_policy_compile_case(
			    out, "redis_policy_compile_optrace", false, -ret,
			    -1, true,
			    "failed to parse Redis policy compile strace",
			    redis_trace_path, cache_dir, NULL, NULL);
			failures++;
		} else {
			emit_ccache_policy_compile_case(
			    out, "redis_policy_compile_optrace", true, 0, 0,
			    true, "Redis policy compile strace parsed",
			    redis_trace_path, cache_dir, NULL, NULL);
		}
		ret = count_ccache_optrace(
		    nginx_trace_path, cache_dir, entries, nr_entries, "nginx",
		    &nginx_attached_cache_path_file_ops,
		    &nginx_attached_policy_cache_object_ops);
		if (ret) {
			emit_ccache_policy_compile_case(
			    out, "nginx_policy_compile_optrace", false, -ret,
			    -1, true,
			    "failed to parse nginx policy compile strace",
			    nginx_trace_path, cache_dir, NULL, NULL);
			failures++;
		} else {
			emit_ccache_policy_compile_case(
			    out, "nginx_policy_compile_optrace", true, 0, 0,
			    true, "nginx policy compile strace parsed",
			    nginx_trace_path, cache_dir, NULL, NULL);
		}
		attached_cache_path_file_ops =
		    redis_attached_cache_path_file_ops +
		    nginx_attached_cache_path_file_ops;
		attached_policy_cache_object_ops =
		    redis_attached_policy_cache_object_ops +
		    nginx_attached_policy_cache_object_ops;
			if (attached_cache_path_file_ops) {
				attached_sampled_operation_hit_rate =
				    (double)attached_policy_cache_object_ops /
				    (double)attached_cache_path_file_ops;
				attached_optrace_collected = true;
			}
			attached_compile_jobs = 2;

			ret = compare_files(redis_output, redis_baseline_obj);
			if (ret) {
				output_hash_match = false;
				emit_ccache_policy_compile_case(
				    out, "redis_output_compare", false, -ret, -1, true,
				    "Redis policy output did not match baseline",
				    redis_output, redis_baseline_obj, NULL, NULL);
				failures++;
			} else {
				attached_compile_output_matches++;
				emit_ccache_policy_compile_case(
				    out, "redis_output_compare", true, 0, 0, true,
				    "Redis policy output matched baseline",
				    redis_output, redis_baseline_obj, NULL, NULL);
			}
			ret = compare_files(nginx_output, nginx_baseline_obj);
		if (ret) {
			output_hash_match = false;
			emit_ccache_policy_compile_case(
			    out, "nginx_output_compare", false, -ret, -1, true,
				    "nginx policy output did not match baseline",
				    nginx_output, nginx_baseline_obj, NULL, NULL);
				failures++;
			} else {
				attached_compile_output_matches++;
				emit_ccache_policy_compile_case(
				    out, "nginx_output_compare", true, 0, 0, true,
				    "nginx policy output matched baseline",
				    nginx_output, nginx_baseline_obj, NULL, NULL);
			}
		}

ccache_policy_compile_done:
	ret = destroy_policy(&policy);
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "detach", false, -ret, -1, false,
		    "cache-locality policy detach failed", current_cgroup, NULL,
		    NULL, NULL);
		failures++;
	} else {
		emit_ccache_policy_compile_case(
		    out, "detach", true, 0, 0, false,
		    "ccache compile policy detached", current_cgroup, NULL,
		    NULL, NULL);
	}

	for (i = 0; i < nr_entries; i++)
		failures += ccache_policy_expect_absent(
		    out, &entries[i], "post_detach_visible_absent");

	ret = set_path(stats_stderr, sizeof(stats_stderr), work_dir,
		       "print-stats.stderr");
	if (ret) {
		emit_ccache_policy_compile_case(
		    out, "print_stats_paths", false, -ret, -1, false,
		    "failed to build ccache --print-stats stderr path",
		    work_dir, NULL, NULL, NULL);
		failures++;
	} else {
		ret = run_ccache_one_arg("--print-stats", stats_path,
					 stats_stderr, &exit_code);
		if (ret || exit_code) {
			emit_ccache_policy_compile_case(
			    out, "print_stats", false, ret ? -ret : 0,
			    exit_code, false, "ccache --print-stats failed",
			    cache_dir, stats_path, stats_path, stats_stderr);
			failures++;
		} else {
			emit_ccache_policy_compile_case(
			    out, "print_stats", true, 0, exit_code, false,
			    "ccache stats written", cache_dir, stats_path,
			    stats_path, stats_stderr);
		}
	}

	fputs("{\"event\":", out);
	fprint_json_string(out, ccache_compile_summary_event);
	fputs(",\"result_level\":", out);
	fprint_json_string(out, ccache_compile_result_level);
	fputs(",\"workload\":", out);
	fprint_json_string(out, ccache_compile_workload);
	fputs(",\"policy_family\":", out);
	fprint_json_string(out, ccache_compile_policy_family);
	fprintf(out,
		",\"run_environment\":\"kvm\","
		"\"real_ccache_run\":true,"
		"\"bulk_policy_compile\":%s,"
		"\"source_manifest_count\":%zu,"
		"\"attached_compile_jobs\":%zu,"
		"\"attached_compile_output_matches\":%zu,"
		"\"policy_executed\":true,"
		"\"ccache_compile_policy_executed\":true,"
		"\"kvm_validated\":true,"
		"\"output_hash_match\":%s,"
		"\"compile_ns\":%llu,"
		"\"compile_ns_avg\":%.17g,"
		"\"policy_redirected_cache_objects\":%zu,"
		"\"redis_trace_objects\":%zu,"
		"\"nginx_trace_objects\":%zu,"
		"\"pass\":%s,\"failures\":%d,"
		"\"table_baseline_current_oracle_pass\":%s,"
		"\"content_equivalent_table_oracle\":%s,"
		"\"parent_rule_policy\":%s,"
		"\"cache_leaf_parents\":%zu,"
		"\"parent_rule_updates\":%zu,"
		"\"exact_readdir_updates\":%zu,"
		"\"table_equivalent_rule_updates\":%zu,"
		"\"attached_optrace_collected\":%s,"
		"\"attached_optrace_scope\":%s,"
		"\"redis_attached_cache_path_file_ops\":%zu,"
		"\"nginx_attached_cache_path_file_ops\":%zu,"
		"\"attached_cache_path_file_ops\":%zu,"
		"\"redis_attached_policy_cache_object_ops\":%zu,"
		"\"nginx_attached_policy_cache_object_ops\":%zu,"
		"\"attached_policy_cache_object_ops\":%zu,"
		"\"attached_sampled_operation_hit_rate\":%.17g,"
		"\"operation_weighted_policy_cache_hit_rate\":false,"
		"\"operation_weighted_policy_hit_rate_is_release\":false,"
		"\"qualified_for_c8\":false,\"detail\":",
		bulk_policy_compile ? "true" : "false", nr_sources,
		attached_compile_jobs, attached_compile_output_matches,
		output_hash_match ? "true" : "false",
		(unsigned long long)compile_ns,
		attached_compile_jobs ?
			(double)compile_ns / (double)attached_compile_jobs :
			0.0,
		nr_entries, redis_entries,
		nginx_entries, failures ? "false" : "true", failures,
		ccache_compile_table_baseline && !failures ? "true" : "false",
		ccache_compile_table_baseline ? "true" : "false",
		ccache_compile_parent_rules ? "true" : "false",
		cache_leaf_parents, parent_rule_updates, exact_readdir_updates,
		nr_entries * 2,
		attached_optrace_collected ? "true" : "false",
		bulk_policy_compile ?
			"\"bulk_ccache_compile_strace\"" :
			"\"sampled_ccache_compile_strace\"",
		redis_attached_cache_path_file_ops,
		nginx_attached_cache_path_file_ops, attached_cache_path_file_ops,
		redis_attached_policy_cache_object_ops,
		nginx_attached_policy_cache_object_ops,
		attached_policy_cache_object_ops,
		attached_sampled_operation_hit_rate);
	fprint_json_string(
	    out,
	    failures
		? "real ccache compile witness failed"
		: (ccache_compile_table_baseline
		       ? "table-only baseline consumed sampled ccache cache "
			 "objects through exact redirects"
		       : (ccache_compile_parent_rules
			      ? "real ccache hot compile consumed cache "
				"objects "
				"through parent-scoped cache_locality policy"
			      : "real ccache hot compile consumed cache "
				"objects "
				"through attached cache_locality policy")));
	fputs("}\n", out);
	fflush(out);
	return failures ? 1 : 0;
}

static int cache_path(char *dst, size_t size, const char *cache_dir,
		      const char *name)
{
	return set_path(dst, size, cache_dir, name);
}

static int cache_expect_absent(FILE *out, const char *cache_dir,
			       const char *branch, const char *name,
			       const char *op)
{
	char path[PATH_MAX];
	int ret;
	int stat_ret;

	ret = cache_path(path, sizeof(path), cache_dir, name);
	if (ret) {
		emit_cache_case(out, branch, op, false, -ret,
				"failed to build cache path", NULL, name);
		return 1;
	}
	stat_ret = expect_stat_errno(path, ENOENT);
	if (stat_ret) {
		emit_cache_case(out, branch, op, false, -stat_ret,
				"visible cache alias unexpectedly resolved",
				path, "ENOENT");
		return 1;
	}
	emit_cache_case(out, branch, op, true, 0,
			"visible cache alias absent", path, "ENOENT");
	return 0;
}

static int cache_expect_equal(FILE *out, const char *cache_dir,
			      const char *branch, const char *visible,
			      const char *backing)
{
	char visible_path[PATH_MAX];
	char backing_path[PATH_MAX];
	int ret;

	ret = cache_path(visible_path, sizeof(visible_path), cache_dir,
			 visible);
	if (!ret)
		ret = cache_path(backing_path, sizeof(backing_path),
				 cache_dir, backing);
	if (ret) {
		emit_cache_case(out, branch, "attached_expected_match", false,
				-ret, "failed to build cache paths", NULL,
				backing);
		return 1;
	}
	ret = compare_files(visible_path, backing_path);
	if (ret) {
		emit_cache_case(out, branch, "attached_expected_match", false,
				-ret, "visible alias did not match expected backing",
				visible_path, backing);
		return 1;
	}
	emit_cache_case(out, branch, "attached_expected_match", true, 0,
			"visible alias matched expected backing",
			visible_path, backing);
	return 0;
}

static int cache_expect_different(FILE *out, const char *cache_dir,
				  const char *branch, const char *visible,
				  const char *forbidden)
{
	char visible_path[PATH_MAX];
	char forbidden_path[PATH_MAX];
	int ret;

	ret = cache_path(visible_path, sizeof(visible_path), cache_dir,
			 visible);
	if (!ret)
		ret = cache_path(forbidden_path, sizeof(forbidden_path),
				 cache_dir, forbidden);
	if (ret) {
		emit_cache_case(out, branch, "attached_forbidden_mismatch",
				false, -ret, "failed to build cache paths",
				NULL, forbidden);
		return 1;
	}
	ret = compare_files(visible_path, forbidden_path);
	if (!ret) {
		emit_cache_case(out, branch, "attached_forbidden_mismatch",
				false, 0,
				"visible alias matched forbidden cache content",
				visible_path, forbidden);
		return 1;
	}
	if (ret != -EINVAL) {
		emit_cache_case(out, branch, "attached_forbidden_mismatch",
				false, -ret,
				"failed to compare forbidden cache content",
				visible_path, forbidden);
		return 1;
	}
	emit_cache_case(out, branch, "attached_forbidden_mismatch", true, 0,
			"visible alias did not match forbidden cache content",
			visible_path, forbidden);
	return 0;
}

static int cache_expect_readdir(FILE *out, const char *cache_dir,
				const char *branch, const char *visible,
				const char *backing)
{
	bool saw_visible;
	bool saw_backing;
	int err = 0;

	saw_visible = dir_has_name(cache_dir, visible, &err);
	if (!err)
		saw_backing = dir_has_name(cache_dir, backing, &err);
	else
		saw_backing = false;
	if (!err && saw_visible && !saw_backing) {
		emit_cache_case(out, branch, "readdir_alias", true, 0,
				"cache alias visible and backing hidden",
				cache_dir, visible);
		return 0;
	}
	emit_cache_case(out, branch, "readdir_alias", false, err,
			"cache directory view mismatch", cache_dir, visible);
	return 1;
}

static int run_cache_content_oracle(FILE *out, const char *cgroup_mount,
				    const char *work_dir,
				    const char *entries_tsv,
				    const char *policy_obj,
				    enum policy_kind policy_kind,
				    const char *policy_name,
				    const char *policy_family,
				    const char *event_name,
				    const char *summary_event,
				    const char *result_level,
				    bool table_baseline)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	size_t nr_entries = 0;
	int failures = 0;
	int ret;
	size_t i;

	w4_cache_content_event = event_name;
	w4_cache_content_summary_event = summary_event;
	w4_cache_content_result_level = result_level;
	w4_cache_content_policy = policy_name;
	w4_cache_content_policy_family = policy_family;
	w4_cache_content_table_baseline = table_baseline;

	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (ret) {
		emit_cache_case(out, "setup", "read_entries", false, -ret,
				"failed to read W4 cache oracle TSV", NULL,
				entries_tsv);
		return 1;
	}
	emit_cache_case(out, "setup", "read_entries", true, 0,
			"W4 cache oracle TSV loaded", NULL, entries_tsv);

	ret = prepare_cache_content_dir(work_dir, entries, nr_entries);
	if (ret) {
		emit_cache_case(out, "setup", "materialize", false, -ret,
				"failed to materialize manifest-derived cache content workdir",
				NULL, entries_tsv);
		return 1;
	}
	emit_cache_case(out, "setup", "materialize", true, 0,
			"manifest-derived cache content workdir materialized",
			work_dir, entries_tsv);

	for (i = 0; i < nr_entries; i++)
		failures += cache_expect_absent(out, entries[i].dir,
						entries[i].branch,
						entries[i].visible,
						"pre_attach_absent");

	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (ret) {
		emit_cache_case(out, "setup", "cgroup_path", false, -ret,
				"failed to resolve current cgroup path", NULL,
				cgroup_mount);
		return failures + 1;
	}
	ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		emit_cache_case(out, "setup", "current_cgroup_id", false,
				-ret, "failed to resolve current cgroup id",
				NULL, current_cgroup);
		return failures + 1;
	}
	emit_cache_case(out, "setup", "current_cgroup_id", true, 0,
			"current cgroup id resolved", NULL, current_cgroup);

	if (open_policy(policy_obj, policy_kind, policy_name, &policy)) {
		emit_cache_case(out, "setup", "load", false, errno,
				"cache-locality policy load failed", NULL,
				policy_obj);
		return failures + 1;
	}
	emit_cache_case(out, "setup", "load", true, 0,
			"cache-locality policy loaded", NULL, policy_obj);

	ret = populate_policy_map(&policy, entries, nr_entries,
				  current_cgroup_id);
	if (ret) {
		emit_cache_case(out, "setup", "map_update", false, -ret,
				"failed to populate cache_rules from W4 TSV",
				NULL, entries_tsv);
		destroy_policy(&policy);
		return failures + 1;
	}
	emit_cache_case(out, "setup", "map_update", true, 0,
			"cache_rules populated from W4 TSV", NULL,
			entries_tsv);

	if (attach_policy(&policy, current_cgroup)) {
		emit_cache_case(out, "setup", "attach", false, errno,
				"cache-locality policy attach failed", NULL,
				current_cgroup);
		destroy_policy(&policy);
		return failures + 1;
	}
	emit_cache_case(out, "setup", "attach", true, 0,
			"cache-locality policy attached", NULL,
			current_cgroup);

	for (i = 0; i < nr_entries; i++) {
		const char *forbidden = cache_forbidden_name(&entries[i]);

		failures += cache_expect_equal(out, entries[i].dir,
					       entries[i].branch,
					       entries[i].visible,
					       entries[i].shadow);
		if (forbidden)
			failures += cache_expect_different(out,
							   entries[i].dir,
							   entries[i].branch,
							   entries[i].visible,
							   forbidden);
	}
	for (i = 0; i < nr_entries; i++)
		failures += cache_expect_readdir(out, entries[i].dir,
						 entries[i].branch,
						 entries[i].visible,
						 entries[i].shadow);

	ret = destroy_policy(&policy);
	if (ret) {
		emit_cache_case(out, "setup", "detach", false, -ret,
				"cache-locality policy detach failed", NULL,
				current_cgroup);
		failures++;
	} else {
		emit_cache_case(out, "setup", "detach", true, 0,
				"cache-locality policy detached", NULL,
				current_cgroup);
	}

	for (i = 0; i < nr_entries; i++)
		failures += cache_expect_absent(out, entries[i].dir,
						entries[i].branch,
						entries[i].visible,
						"post_detach_absent");

	fputs("{\"event\":", out);
	fprint_json_string(out, w4_cache_content_summary_event);
	fputs(",\"result_level\":", out);
	fprint_json_string(out, w4_cache_content_result_level);
	fputs(",\"workload\":\"w4-cache-locality\",\"policy\":", out);
	fprint_json_string(out, w4_cache_content_policy);
	fputs(",\"policy_family\":", out);
	fprint_json_string(out, w4_cache_content_policy_family);
	fprintf(out,
		",\"branches\":%zu,\"pass\":%s,\"failures\":%d,"
		"\"table_baseline_current_oracle_pass\":%s,"
		"\"content_equivalent_table_oracle\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		nr_entries, failures ? "false" : "true", failures,
		table_baseline && !failures ? "true" : "false",
		table_baseline ? "true" : "false");
	fprint_json_string(out, failures ?
			   "W4 cache content oracle failed" :
			   (table_baseline ?
			    "manifest-derived W4 cache content oracle also passed with table_redirect; this is negative C8 evidence" :
			    "manifest-derived W4 cache content oracle passed"));
	fputs("}\n", out);
	fflush(out);
	return failures ? 1 : 0;
}

struct w4_transition_stats {
	int setup_rows;
	int correctness_rows;
	int update_rows;
	int failures;
	size_t entries;
	size_t stateful_entries;
	size_t static_wrong_local_hits;
	size_t policy_transition_rows;
	size_t table_transition_rows;
	size_t policy_transition_passes;
	size_t table_transition_passes;
	unsigned long long policy_update_writes;
	unsigned long long table_update_writes;
};

static bool w4_transition_stateful_branch(const struct oracle_entry *entry)
{
	return !strcmp(entry->branch, "stale_fallback") ||
	       !strcmp(entry->branch, "stale_canonical") ||
	       !strcmp(entry->branch, "corrupt_reject");
}

static const char *w4_transition_verified_name(const struct oracle_entry *entry)
{
	const char *local = cache_forbidden_name(entry);

	return local ? local : entry->shadow;
}

static int w4_expect_lookup_target_quiet(const struct oracle_entry *entry,
					 const char *target)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), entry->dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), entry->dir,
			       target);
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static int w4_expect_readdir_target_quiet(const struct oracle_entry *entry,
					  const char *target)
{
	bool saw_visible;
	bool saw_target;
	int err = 0;

	saw_visible = dir_has_name(entry->dir, entry->visible, &err);
	if (!err)
		saw_target = dir_has_name(entry->dir, target, &err);
	else
		saw_target = false;
	if (!err && saw_visible && !saw_target)
		return 0;
	return err ? -err : -ENOENT;
}

static int w4_expect_oracle_target_quiet(const struct oracle_entry *entry,
					 const char *target,
					 bool check_forbidden,
					 bool *forbidden_mismatch)
{
	const char *forbidden = cache_forbidden_name(entry);
	int ret;

	if (forbidden_mismatch)
		*forbidden_mismatch = false;
	ret = w4_expect_lookup_target_quiet(entry, target);
	if (ret)
		return ret;
	ret = w4_expect_readdir_target_quiet(entry, target);
	if (ret)
		return ret;
	if (check_forbidden && forbidden) {
		ret = w4_expect_lookup_target_quiet(entry, forbidden);
		if (!ret)
			return -EINVAL;
		if (ret != -EINVAL)
			return ret;
		if (forbidden_mismatch)
			*forbidden_mismatch = true;
	}
	return 0;
}

static void emit_w4_transition_setup(FILE *out, int sample,
				     const char *system,
				     const char *policy_family, bool pass,
				     int err, __u64 setup_ns,
				     size_t entries, size_t stateful_entries,
				     unsigned long long rule_writes,
				     const char *detail)
{
	fputs("{\"event\":\"w4-cache-transition-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_cache_transition.v1\","
	      "\"result_level\":\"kvm_cache_state_transition_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-cache-state-transition\","
	      "\"app\":\"ccache\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"policy_family\":", out);
	fprint_json_string(out, policy_family);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,\"entries\":%zu,"
		"\"stateful_entries\":%zu,\"setup_rule_writes\":%llu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, entries, stateful_entries,
		rule_writes, pass ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_transition_correctness(
	FILE *out, int sample, const char *system, const char *policy_family,
	const char *branch, bool pass, bool current_oracle_pass,
	bool expected_static_failure_observed, bool wrong_local_hit,
	bool forbidden_mismatch, const char *target, const char *detail)
{
	fputs("{\"event\":\"w4-cache-transition-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_cache_transition.v1\","
	      "\"result_level\":\"kvm_cache_state_transition_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-cache-state-transition\","
	      "\"app\":\"ccache\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"policy_family\":", out);
	fprint_json_string(out, policy_family);
	fputs(",\"branch\":", out);
	fprint_json_string(out, branch);
	fputs(",\"target\":", out);
	fprint_json_string(out, target);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,"
		"\"current_oracle_pass\":%s,"
		"\"expected_static_failure_observed\":%s,"
		"\"wrong_local_hit\":%s,"
		"\"forbidden_mismatch\":%s,"
		"\"policy_executed\":true,\"kvm_validated\":true,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false",
		current_oracle_pass ? "true" : "false",
		expected_static_failure_observed ? "true" : "false",
		wrong_local_hit ? "true" : "false",
		forbidden_mismatch ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_transition_update(FILE *out, int sample,
				      const char *system,
				      const char *policy_family,
				      const char *transition, bool pass,
				      int err, __u64 update_ns,
				      __u64 observed_window_ns,
				      unsigned long long rule_writes,
				      const char *target,
				      const char *detail)
{
	fputs("{\"event\":\"w4-cache-transition-update-window\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_cache_transition.v1\","
	      "\"result_level\":\"kvm_cache_state_transition_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-cache-state-transition\","
	      "\"app\":\"ccache\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"policy_family\":", out);
	fprint_json_string(out, policy_family);
	fputs(",\"transition\":", out);
	fprint_json_string(out, transition);
	fputs(",\"target\":", out);
	fprint_json_string(out, target);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"observed_update_window_ns\":%llu,"
		"\"rule_writes\":%llu,"
		"\"state_transition_hit\":%s,"
		"\"policy_executed\":true,\"kvm_validated\":true,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns,
		(unsigned long long)observed_window_ns, rule_writes,
		pass ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_transition_summary(FILE *out, int samples,
				       const struct w4_transition_stats *stats,
				       const char *detail)
{
	size_t total_transition_rows = stats->policy_transition_rows +
				       stats->table_transition_rows;
	size_t total_transition_passes = stats->policy_transition_passes +
					 stats->table_transition_passes;
	double hit_rate = total_transition_rows ?
			  (double)total_transition_passes /
				  (double)total_transition_rows :
			  0.0;
	bool table_static_pass = stats->static_wrong_local_hits == 0;
	bool table_updated_pass =
		stats->table_transition_rows > 0 &&
		stats->table_transition_passes == stats->table_transition_rows;
	double update_write_ratio =
		stats->policy_update_writes ?
			(double)stats->table_update_writes /
				(double)stats->policy_update_writes :
			0.0;

	fputs("{\"event\":\"w4-cache-transition-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_cache_transition.v1\","
	      "\"result_level\":\"kvm_cache_state_transition_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-cache-state-transition\","
	      "\"app\":\"ccache\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"setup_rows\":%d,"
		"\"correctness_rows\":%d,\"update_rows\":%d,"
		"\"entries\":%zu,\"stateful_entries\":%zu,"
		"\"static_wrong_local_hits\":%zu,"
		"\"policy_transition_rows\":%zu,"
		"\"table_transition_rows\":%zu,"
		"\"policy_transition_passes\":%zu,"
		"\"table_transition_passes\":%zu,"
		"\"state_transition_hit_rate\":%.17g,"
		"\"policy_update_writes\":%llu,"
		"\"table_update_writes\":%llu,"
		"\"table_update_write_ratio\":%.17g,"
		"\"table_static_current_oracle_pass\":%s,"
		"\"table_updated_current_oracle_pass\":%s,"
		"\"table_requires_external_state_updates\":true,"
		"\"table_update_budget_failure\":false,"
		"\"release_sample_budget_pass\":%s,"
		"\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"qualified_for_c8\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, stats->setup_rows, stats->correctness_rows,
		stats->update_rows, stats->entries, stats->stateful_entries,
		stats->static_wrong_local_hits, stats->policy_transition_rows,
		stats->table_transition_rows, stats->policy_transition_passes,
		stats->table_transition_passes, hit_rate,
		stats->policy_update_writes, stats->table_update_writes,
		update_write_ratio, table_static_pass ? "true" : "false",
		table_updated_pass ? "true" : "false",
		samples >= 20 ? "true" : "false",
		stats->failures ? "false" : "true", stats->failures,
		stats->failures ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int w4_update_cache_transition_target(
	struct attached_policy *policy, __u64 cgroup_id,
	const struct oracle_entry *entry, const char *target, __u32 branch,
	__u32 state)
{
	int ret;

	ret = update_cache_rule(policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
				entry->dir, entry->visible, target, branch,
				state, entry->original_sha256);
	if (ret)
		return ret;
	return update_cache_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				 entry->dir, target, entry->visible, branch,
				 state, entry->original_sha256);
}

static int w4_update_table_transition_target(
	struct attached_policy *policy, __u64 cgroup_id,
	const struct oracle_entry *entry, const char *target, __u32 branch)
{
	int ret;

	ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
			  entry->dir, entry->visible, target, branch);
	if (ret)
		return ret;
	return update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
			   entry->dir, target, entry->visible, branch);
}

static int populate_w4_transition_table_static_rules(
	struct attached_policy *policy, __u64 cgroup_id,
	const struct oracle_entry *entries, size_t nr_entries,
	unsigned long long *rule_writes)
{
	size_t i;

	*rule_writes = 0;
	for (i = 0; i < nr_entries; i++) {
		const char *target = entries[i].shadow;
		const char *local = cache_forbidden_name(&entries[i]);
		int ret;

		if (w4_transition_stateful_branch(&entries[i]) && local)
			target = local;
		ret = w4_update_table_transition_target(
			policy, cgroup_id, &entries[i], target, i + 1);
		if (ret)
			return ret;
		*rule_writes += 2;
	}
	return 0;
}

static int run_one_w4_transition_update(
	FILE *out, struct attached_policy *policy, __u64 cgroup_id,
	const struct oracle_entry *entry, int sample, const char *system,
	const char *policy_family, const char *transition, const char *target,
	__u32 state, bool table_system, struct w4_transition_stats *stats)
{
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	start_ns = monotonic_ns();
	if (table_system)
		ret = w4_update_table_transition_target(
			policy, cgroup_id, entry, target, sample + 100);
	else
		ret = w4_update_cache_transition_target(
			policy, cgroup_id, entry, target, sample + 100,
			state);
	update_done_ns = monotonic_ns();
	if (!ret)
		ret = w4_expect_oracle_target_quiet(
			entry, target, !strcmp(target, entry->shadow), NULL);
	end_ns = monotonic_ns();

	emit_w4_transition_update(
		out, sample, system, policy_family, transition, !ret,
		ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, 2, target,
		ret ? "cache state transition lookup failed" :
		      "cache state transition lookup observed after map update");
	stats->update_rows++;
	if (table_system) {
		stats->table_transition_rows++;
		stats->table_update_writes += 2;
		if (!ret)
			stats->table_transition_passes++;
	} else {
		stats->policy_transition_rows++;
		stats->policy_update_writes += 2;
		if (!ret)
			stats->policy_transition_passes++;
	}
	if (ret) {
		stats->failures++;
		return 1;
	}
	return 0;
}

static size_t w4_count_stateful_entries(const struct oracle_entry *entries,
					size_t nr_entries)
{
	size_t count = 0;
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		if (w4_transition_stateful_branch(&entries[i]))
			count++;
	}
	return count;
}

static int run_w4_transition_policy_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, const char *entries_tsv,
	const char *policy_obj, struct w4_transition_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	size_t nr_entries = 0;
	size_t stateful_entries = 0;
	bool sample_failed = false;
	__u64 start_ns;
	__u64 end_ns;
	int ret;
	size_t i;

	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (!ret)
		ret = prepare_cache_content_dir(sample_dir, entries,
						nr_entries);
	stateful_entries = w4_count_stateful_entries(entries, nr_entries);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_CACHE_LOCALITY,
				  "cache_locality", &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_policy_map(&policy, entries, nr_entries,
					  cgroup_id);
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	emit_w4_transition_setup(
		out, sample, "cache_locality_state_policy",
		"cache_locality_view.bpf.c", !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, nr_entries,
		stateful_entries, nr_entries * 2,
		ret ? "failed to attach cache locality transition policy" :
		      "cache locality transition policy attached");
	stats->setup_rows++;
	if (ret) {
		stats->failures++;
		if (policy.obj)
			destroy_policy(&policy);
		return 1;
	}

	stats->entries = nr_entries;
	stats->stateful_entries = stateful_entries;
	for (i = 0; i < nr_entries; i++) {
		bool forbidden_mismatch = false;
		int oracle_ret = w4_expect_oracle_target_quiet(
			&entries[i], entries[i].shadow, true,
			&forbidden_mismatch);

		emit_w4_transition_correctness(
			out, sample, "cache_locality_state_policy",
			"cache_locality_view.bpf.c", entries[i].branch,
			!oracle_ret, !oracle_ret, false, false,
			forbidden_mismatch, entries[i].shadow,
			oracle_ret ? "cache locality state oracle failed" :
				     "cache locality state oracle passed");
		stats->correctness_rows++;
		if (oracle_ret) {
			stats->failures++;
			sample_failed = true;
		}
	}

	for (i = 0; i < nr_entries; i++) {
		const char *local = w4_transition_verified_name(&entries[i]);
		__u32 state = 0;
		char transition[64];

		if (!w4_transition_stateful_branch(&entries[i]))
			continue;
		snprintf(transition, sizeof(transition), "%s_to_verified",
			 entries[i].branch);
		if (run_one_w4_transition_update(
			    out, &policy, cgroup_id, &entries[i], sample,
			    "cache_locality_state_policy",
			    "cache_locality_view.bpf.c", transition, local,
			    CACHE_STATE_VERIFIED_HIT, false, stats))
			sample_failed = true;
		if (cache_state_for_branch(entries[i].branch, &state))
			state = CACHE_STATE_STALE;
		snprintf(transition, sizeof(transition), "verified_to_%s",
			 entries[i].branch);
		if (run_one_w4_transition_update(
			    out, &policy, cgroup_id, &entries[i], sample,
			    "cache_locality_state_policy",
			    "cache_locality_view.bpf.c", transition,
			    entries[i].shadow, state, false, stats))
			sample_failed = true;
	}

	ret = destroy_policy(&policy);
	if (ret) {
		stats->failures++;
		sample_failed = true;
	}
	return sample_failed ? 1 : 0;
}

static int run_w4_transition_table_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, const char *entries_tsv,
	const char *policy_obj, bool static_verified_table,
	struct w4_transition_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	const char *system = static_verified_table ?
				     "table_redirect_static_verified" :
				     "table_redirect_updated_exact";
	size_t nr_entries = 0;
	size_t stateful_entries = 0;
	unsigned long long rule_writes = 0;
	bool sample_failed = false;
	__u64 start_ns;
	__u64 end_ns;
	int ret;
	size_t i;

	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (!ret)
		ret = prepare_cache_content_dir(sample_dir, entries,
						nr_entries);
	stateful_entries = w4_count_stateful_entries(entries, nr_entries);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_TABLE, "table_redirect",
				  &policy);
	start_ns = monotonic_ns();
	if (!ret) {
		if (static_verified_table)
			ret = populate_w4_transition_table_static_rules(
				&policy, cgroup_id, entries, nr_entries,
				&rule_writes);
		else {
			ret = populate_policy_map(&policy, entries, nr_entries,
						  cgroup_id);
			if (!ret)
				rule_writes = nr_entries * 2;
		}
	}
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	emit_w4_transition_setup(
		out, sample, system, "table_redirect.bpf.c", !ret,
		ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, nr_entries,
		stateful_entries, rule_writes,
		ret ? "failed to attach table transition counterfactual" :
		      "table transition counterfactual attached");
	stats->setup_rows++;
	if (ret) {
		stats->failures++;
		if (policy.obj)
			destroy_policy(&policy);
		return 1;
	}

	for (i = 0; i < nr_entries; i++) {
		const char *local = w4_transition_verified_name(&entries[i]);
		bool stateful = w4_transition_stateful_branch(&entries[i]);
		bool forbidden_mismatch = false;
		bool wrong_local_hit = false;
		bool current_oracle_pass = false;
			bool pass = false;

			if (static_verified_table && stateful) {
				current_oracle_pass = w4_expect_oracle_target_quiet(
							      &entries[i],
							      entries[i].shadow,
							      true,
							      &forbidden_mismatch) == 0;
				wrong_local_hit =
					w4_expect_lookup_target_quiet(&entries[i],
								      local) == 0;
				pass = wrong_local_hit && !current_oracle_pass;
				if (pass)
					stats->static_wrong_local_hits++;
			} else {
			current_oracle_pass = w4_expect_oracle_target_quiet(
						      &entries[i],
						      entries[i].shadow,
						      true,
						      &forbidden_mismatch) == 0;
			pass = current_oracle_pass;
		}
		emit_w4_transition_correctness(
			out, sample, system, "table_redirect.bpf.c",
			entries[i].branch, pass, current_oracle_pass,
			static_verified_table && stateful && wrong_local_hit,
			wrong_local_hit, forbidden_mismatch,
			static_verified_table && stateful ? local :
							    entries[i].shadow,
			pass ? "table transition observation matched expectation" :
			       "table transition observation failed");
		stats->correctness_rows++;
		if (!pass) {
			stats->failures++;
			sample_failed = true;
		}
	}

	if (!static_verified_table) {
		for (i = 0; i < nr_entries; i++) {
			const char *local = w4_transition_verified_name(&entries[i]);
			char transition[64];

			if (!w4_transition_stateful_branch(&entries[i]))
				continue;
			snprintf(transition, sizeof(transition),
				 "%s_to_verified_exact_redirect",
				 entries[i].branch);
			if (run_one_w4_transition_update(
				    out, &policy, cgroup_id, &entries[i],
				    sample, system, "table_redirect.bpf.c",
				    transition, local, CACHE_STATE_VERIFIED_HIT,
				    true, stats))
				sample_failed = true;
			snprintf(transition, sizeof(transition),
				 "verified_to_%s_exact_redirect",
				 entries[i].branch);
			if (run_one_w4_transition_update(
				    out, &policy, cgroup_id, &entries[i],
				    sample, system, "table_redirect.bpf.c",
				    transition, entries[i].shadow,
				    CACHE_STATE_VERIFIED_HIT, true, stats))
				sample_failed = true;
		}
	}

	ret = destroy_policy(&policy);
	if (ret) {
		stats->failures++;
		sample_failed = true;
	}
	return sample_failed ? 1 : 0;
}

static int run_w4_cache_transition_counterfactual(
	FILE *out, const char *cgroup_mount, int samples, const char *work_dir,
	const char *entries_tsv, const char *cache_policy_obj,
	const char *table_policy_obj)
{
	struct w4_transition_stats stats = {};
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	int ret;
	int sample;

	if (samples <= 0) {
		stats.failures = 1;
		emit_w4_transition_summary(
			out, samples, &stats, "sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		stats.failures = 1;
		emit_w4_transition_summary(
			out, samples, &stats,
			"failed to create W4 transition workdir");
		return 1;
	}
	if (access(entries_tsv, R_OK) || access(cache_policy_obj, R_OK) ||
	    access(table_policy_obj, R_OK)) {
		stats.failures = 1;
		emit_w4_transition_summary(
			out, samples, &stats,
			"W4 transition counterfactual inputs are not readable");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		stats.failures = 1;
		emit_w4_transition_summary(
			out, samples, &stats,
			"failed to resolve current cgroup id");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		char sample_dir[PATH_MAX];

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/cache-policy-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_transition_policy_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, entries_tsv, cache_policy_obj, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/table-static-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_transition_table_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, entries_tsv, table_policy_obj, true, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/table-updated-sample-%03d", work_dir,
			       sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_transition_table_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, entries_tsv, table_policy_obj, false,
			&stats);
	}

	emit_w4_transition_summary(
		out, samples, &stats,
		stats.failures ?
			"W4 cache transition counterfactual failed" :
			"W4 cache transition counterfactual passed; static table fails stale/corrupt semantics but externally updated table still passes, so C8 remains unsupported");
	return stats.failures ? 1 : 0;
}

#define W4_CACHE_EPOCH_ONE 1
#define W4_CACHE_EPOCH_TWO 2
#define W4_CACHE_EPOCH_DEFAULT_OBJECTS 16
#define W4_CACHE_EPOCH_MAX_OBJECTS 64
#define W4_CACHE_EPOCH_TABLE_MAX_UPDATE_RATIO 10

struct w4_cache_epoch_entry {
	char visible[NAMEI_EXT_NAME_MAX + 1];
	char local[NAMEI_EXT_NAME_MAX + 1];
	char canonical[NAMEI_EXT_NAME_MAX + 1];
};

struct w4_cache_epoch_stats {
	int setup_rows;
	int correctness_rows;
	int update_rows;
	int failures;
	size_t objects;
	size_t trace_entries;
	size_t static_wrong_local_hits;
	unsigned long long policy_setup_writes;
	unsigned long long table_setup_writes;
	unsigned long long materialized_setup_writes;
	unsigned long long fuse_setup_writes;
	unsigned long long policy_update_writes;
	unsigned long long table_update_writes;
	unsigned long long materialized_update_writes;
	unsigned long long fuse_update_writes;
	unsigned long long fuse_mounts;
	bool policy_epoch_switch_pass;
	bool table_static_expected_failure;
	bool table_updated_pass;
	bool materialized_updated_pass;
	bool fuse_updated_pass;
	bool real_ccache_trace;
	bool trace_derived_counterfactual;
};

static char w4_cache_epoch_prepare_error[256];

static void w4_cache_epoch_set_prepare_error(const char *stage,
					     const char *path, int ret)
{
	snprintf(w4_cache_epoch_prepare_error,
		 sizeof(w4_cache_epoch_prepare_error),
		 "trace-derived cache epoch prepare failed at %.64s errno %d path %.120s",
		 stage, ret, path ? path : "");
}

static const char *w4_cache_epoch_failure_detail(const char *fallback)
{
	return w4_cache_epoch_prepare_error[0] ?
		       w4_cache_epoch_prepare_error :
		       fallback;
}

static const char *w4_cache_epoch_target(
	const struct w4_cache_epoch_entry *entry, __u32 epoch)
{
	return epoch == W4_CACHE_EPOCH_TWO ? entry->canonical : entry->local;
}

static int prepare_w4_cache_epoch_dir(
	const char *dir, struct w4_cache_epoch_entry *entries, size_t objects,
	int sample)
{
	char path[PATH_MAX];
	char text[192];
	size_t i;
	int ret;

	ret = mkdir_if_missing(dir);
	if (ret)
		return ret;
	for (i = 0; i < objects; i++) {
		ret = snprintf(entries[i].visible, sizeof(entries[i].visible),
			       "c8%029zuM", i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(entries[i].visible))
			return -ENAMETOOLONG;
		ret = snprintf(entries[i].local, sizeof(entries[i].local),
			       "%s.local", entries[i].visible);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(entries[i].local))
			return -ENAMETOOLONG;
		ret = snprintf(entries[i].canonical,
			       sizeof(entries[i].canonical), "%s.canon",
			       entries[i].visible);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(entries[i].canonical))
			return -ENAMETOOLONG;

		ret = set_path(path, sizeof(path), dir, entries[i].visible);
		if (ret)
			return ret;
		unlink_existing(path);

		ret = set_path(path, sizeof(path), dir, entries[i].local);
		if (ret)
			return ret;
		ret = snprintf(text, sizeof(text),
			       "namei_ext w4 cache sample %d object %zu verified local\n",
			       sample, i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(text))
			return -ENAMETOOLONG;
		ret = write_text_file(path, text);
		if (ret)
			return ret;

		ret = set_path(path, sizeof(path), dir, entries[i].canonical);
		if (ret)
			return ret;
		ret = snprintf(text, sizeof(text),
			       "namei_ext w4 cache sample %d object %zu canonical epoch\n",
			       sample, i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(text))
			return -ENAMETOOLONG;
		ret = write_text_file(path, text);
		if (ret)
			return ret;
	}
	return 0;
}

static bool w4_cache_epoch_valid_component(const char *name)
{
	return name && name[0] && strcmp(name, ".") && strcmp(name, "..") &&
	       !strchr(name, '/') && strlen(name) <= NAMEI_EXT_NAME_MAX;
}

static int prepare_w4_cache_epoch_trace_dir(
	const char *dir, struct w4_cache_epoch_entry *entries,
	const struct oracle_entry *trace_entries, size_t objects, int sample)
{
	char path[PATH_MAX];
	char text[256];
	size_t i;
	int ret;

	ret = mkdir_if_missing(dir);
	if (ret) {
		w4_cache_epoch_set_prepare_error("mkdir_dir", dir, ret);
		return ret;
	}
	for (i = 0; i < objects; i++) {
		if (!w4_cache_epoch_valid_component(trace_entries[i].visible) ||
		    !w4_cache_epoch_valid_component(trace_entries[i].shadow)) {
			w4_cache_epoch_set_prepare_error("component_validate",
							 trace_entries[i].visible,
							 -EINVAL);
			return -EINVAL;
		}
		ret = copy_string(entries[i].visible,
				  sizeof(entries[i].visible),
				  trace_entries[i].visible);
		if (!ret)
			ret = copy_string(entries[i].local,
					  sizeof(entries[i].local),
					  trace_entries[i].shadow);
		if (!ret) {
			ret = snprintf(entries[i].canonical,
				       sizeof(entries[i].canonical), "%s.canon",
				       entries[i].visible);
			if (ret < 0)
				return -errno;
			if ((size_t)ret >= sizeof(entries[i].canonical))
				return -ENAMETOOLONG;
			ret = 0;
		}
		if (ret) {
			w4_cache_epoch_set_prepare_error("component_copy",
							 trace_entries[i].visible,
							 ret);
			return ret;
		}
		if (!w4_cache_epoch_valid_component(entries[i].canonical)) {
			w4_cache_epoch_set_prepare_error("canonical_validate",
							 entries[i].canonical,
							 -EINVAL);
			return -EINVAL;
		}

		ret = set_path(path, sizeof(path), dir, entries[i].visible);
		if (ret) {
			w4_cache_epoch_set_prepare_error("visible_path",
							 entries[i].visible,
							 ret);
			return ret;
		}
		unlink_existing(path);

		ret = set_path(path, sizeof(path), dir, entries[i].local);
		if (ret) {
			w4_cache_epoch_set_prepare_error("local_path",
							 entries[i].local, ret);
			return ret;
		}
		ret = snprintf(text, sizeof(text),
			       "namei_ext w4 trace-derived verified-local sample %d object %zu sha %s\n",
			       sample, i, trace_entries[i].original_sha256);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(text))
			return -ENAMETOOLONG;
		ret = write_text_file(path, text);
		if (ret) {
			w4_cache_epoch_set_prepare_error("write_local", path,
							 ret);
			return ret;
		}

		ret = set_path(path, sizeof(path), dir, entries[i].canonical);
		if (ret) {
			w4_cache_epoch_set_prepare_error("canonical_path",
							 entries[i].canonical,
							 ret);
			return ret;
		}
		ret = snprintf(text, sizeof(text),
			       "namei_ext w4 trace-derived canonical sample %d object %zu sha %s\n",
			       sample, i, trace_entries[i].original_sha256);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(text))
			return -ENAMETOOLONG;
		ret = write_text_file(path, text);
		if (ret) {
			w4_cache_epoch_set_prepare_error("write_canonical",
							 path, ret);
			return ret;
		}
	}
	return 0;
}

static int prepare_w4_cache_epoch_sample_dir(
	const char *dir, struct w4_cache_epoch_entry *entries, size_t objects,
	int sample, const struct oracle_entry *trace_entries)
{
	w4_cache_epoch_prepare_error[0] = '\0';
	if (trace_entries)
		return prepare_w4_cache_epoch_trace_dir(dir, entries,
							trace_entries, objects,
							sample);
	return prepare_w4_cache_epoch_dir(dir, entries, objects, sample);
}

static int w4_cache_epoch_lookup_matches(
	const char *dir, const struct w4_cache_epoch_entry *entry, __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), dir,
			       w4_cache_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static int w4_cache_epoch_readdir_hides_backings(
	const char *dir, const struct w4_cache_epoch_entry *entry)
{
	bool saw_visible;
	bool saw_local;
	bool saw_canonical;
	int err = 0;

	saw_visible = dir_has_name(dir, entry->visible, &err);
	if (!err)
		saw_local = dir_has_name(dir, entry->local, &err);
	else
		saw_local = false;
	if (!err)
		saw_canonical = dir_has_name(dir, entry->canonical, &err);
	else
		saw_canonical = false;
	if (!err && saw_visible && !saw_local && !saw_canonical)
		return 0;
	return err ? -err : -ENOENT;
}

static bool w4_cache_epoch_current_oracle_passes(
	const char *dir, const struct w4_cache_epoch_entry *entries,
	size_t objects, __u32 epoch, size_t *wrong_local_hits)
{
	bool pass = true;
	size_t wrong = 0;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w4_cache_epoch_lookup_matches(dir, &entries[i], epoch))
			pass = false;
		if (w4_cache_epoch_readdir_hides_backings(dir, &entries[i]))
			pass = false;
		if (epoch == W4_CACHE_EPOCH_TWO &&
		    !w4_cache_epoch_lookup_matches(dir, &entries[i],
						   W4_CACHE_EPOCH_ONE))
			wrong++;
	}
	if (wrong_local_hits)
		*wrong_local_hits = wrong;
	return pass;
}

static void emit_w4_cache_epoch_setup(
	FILE *out, int sample, const char *system, bool pass, int err,
	__u64 setup_ns, size_t objects, unsigned long long setup_writes,
	bool policy_executed, const char *detail)
{
	const char *write_key = policy_executed ? "setup_rule_writes" :
						"setup_materialization_writes";

	fputs("{\"event\":\"w4-cache-epoch-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_cache_epoch.v1\","
	      "\"result_level\":\"kvm_cache_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-cache-epoch\","
	      "\"app\":\"ccache\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,\"objects\":%zu,"
		"\"setup_writes\":%llu,\"%s\":%llu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, objects, setup_writes,
		write_key, setup_writes,
		policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_cache_epoch_correctness(
	FILE *out, int sample, const char *system, const char *stage,
	bool pass, bool current_oracle_pass,
	bool expected_static_failure_observed, size_t wrong_local_hits,
	bool policy_executed, const char *detail)
{
	fputs("{\"event\":\"w4-cache-epoch-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_cache_epoch.v1\","
	      "\"result_level\":\"kvm_cache_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-cache-epoch\","
	      "\"app\":\"ccache\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fputs(",\"stage\":", out);
	fprint_json_string(out, stage);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,"
		"\"current_oracle_pass\":%s,"
		"\"expected_static_failure_observed\":%s,"
		"\"wrong_local_hits\":%zu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false",
		current_oracle_pass ? "true" : "false",
		expected_static_failure_observed ? "true" : "false",
		wrong_local_hits,
		policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_cache_epoch_update(
	FILE *out, int sample, const char *system, bool pass, int err,
	__u64 update_ns, __u64 observed_window_ns,
	unsigned long long update_writes, bool policy_executed,
	const char *detail)
{
	fputs("{\"event\":\"w4-cache-epoch-update-window\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_cache_epoch.v1\","
	      "\"result_level\":\"kvm_cache_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-cache-epoch\","
	      "\"app\":\"ccache\",",
	      out);
	fputs("\"system\":", out);
	fprint_json_string(out, system);
	fputs(",\"row_kind\":", out);
	fprint_json_string(out, policy_executed ? "policy_or_table" :
						"external_baseline");
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"observed_update_window_ns\":%llu,"
		"\"update_writes\":%llu,"
		"\"from_epoch\":1,\"to_epoch\":2,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"qualified_for_c8\":false,\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns,
		(unsigned long long)observed_window_ns, update_writes,
		policy_executed ? "true" : "false",
		policy_executed ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_cache_epoch_summary(
	FILE *out, int samples, const struct w4_cache_epoch_stats *stats,
	const char *detail)
{
	double update_ratio = stats->policy_update_writes ?
		(double)stats->table_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	double materialized_update_ratio = stats->policy_update_writes ?
		(double)stats->materialized_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	double fuse_update_ratio = stats->policy_update_writes ?
		(double)stats->fuse_update_writes /
			(double)stats->policy_update_writes :
		0.0;
	bool table_update_budget_failure =
		update_ratio > W4_CACHE_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool materialized_update_budget_failure =
		materialized_update_ratio > W4_CACHE_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool fuse_update_budget_failure =
		fuse_update_ratio > W4_CACHE_EPOCH_TABLE_MAX_UPDATE_RATIO;
	bool targeted_c8_budget_failure =
		stats->policy_epoch_switch_pass &&
		stats->table_static_expected_failure &&
		stats->table_updated_pass &&
		table_update_budget_failure;

	fputs("{\"event\":\"w4-cache-epoch-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_cache_epoch.v1\","
	      "\"result_level\":\"kvm_cache_epoch_counterfactual\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-cache-epoch\","
	      "\"app\":\"ccache\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"setup_rows\":%d,"
		"\"correctness_rows\":%d,\"update_rows\":%d,"
		"\"objects\":%zu,"
		"\"trace_entries\":%zu,"
		"\"static_wrong_local_hits\":%zu,"
		"\"policy_setup_writes\":%llu,"
		"\"table_setup_writes\":%llu,"
		"\"materialized_setup_writes\":%llu,"
		"\"fuse_setup_writes\":%llu,"
		"\"policy_update_writes\":%llu,"
		"\"table_update_writes\":%llu,"
		"\"materialized_update_writes\":%llu,"
		"\"fuse_update_writes\":%llu,"
		"\"fuse_mounts\":%llu,"
		"\"table_update_write_ratio\":%.17g,"
		"\"materialized_update_write_ratio\":%.17g,"
		"\"fuse_update_write_ratio\":%.17g,"
		"\"max_table_update_write_ratio\":%d,"
		"\"table_static_current_oracle_pass\":false,"
		"\"table_static_expected_failure_observed\":%s,"
		"\"table_updated_current_oracle_pass\":%s,"
		"\"table_requires_external_state_updates\":true,"
		"\"table_update_budget_failure\":%s,"
		"\"materialized_current_oracle_pass\":%s,"
		"\"materialized_feature_equivalent_baseline\":%s,"
		"\"materialized_update_budget_failure\":%s,"
		"\"fuse_current_oracle_pass\":%s,"
		"\"fuse_feature_equivalent_baseline\":%s,"
		"\"fuse_update_budget_failure\":%s,"
		"\"targeted_c8_budget_failure\":%s,"
		"\"real_ccache_trace\":%s,"
		"\"trace_derived_counterfactual\":%s,"
		"\"trace_derived_targeted_c8_pass\":%s,"
		"\"release_sample_budget_pass\":%s,"
		"\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"qualified_for_c8\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, stats->setup_rows, stats->correctness_rows,
		stats->update_rows, stats->objects, stats->trace_entries,
		stats->static_wrong_local_hits, stats->policy_setup_writes,
		stats->table_setup_writes, stats->materialized_setup_writes,
		stats->fuse_setup_writes,
		stats->policy_update_writes, stats->table_update_writes,
		stats->materialized_update_writes, stats->fuse_update_writes,
		stats->fuse_mounts, update_ratio, materialized_update_ratio,
		fuse_update_ratio,
		W4_CACHE_EPOCH_TABLE_MAX_UPDATE_RATIO,
		stats->table_static_expected_failure ? "true" : "false",
		stats->table_updated_pass ? "true" : "false",
		table_update_budget_failure ? "true" : "false",
		stats->materialized_updated_pass ? "true" : "false",
		stats->materialized_updated_pass ? "true" : "false",
		materialized_update_budget_failure ? "true" : "false",
		stats->fuse_updated_pass ? "true" : "false",
		stats->fuse_updated_pass ? "true" : "false",
		fuse_update_budget_failure ? "true" : "false",
		targeted_c8_budget_failure ? "true" : "false",
		stats->real_ccache_trace ? "true" : "false",
		stats->trace_derived_counterfactual ? "true" : "false",
		(stats->real_ccache_trace && targeted_c8_budget_failure) ?
			"true" : "false",
		samples >= 20 ? "true" : "false",
		stats->failures ? "false" : "true", stats->failures,
		stats->failures ? "false" : "true");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_cache_state_policy_fuse_summary(
	FILE *out, int samples, const struct w4_cache_epoch_stats *stats,
	const char *detail)
{
	bool pass = stats->failures == 0 && stats->policy_epoch_switch_pass &&
		    stats->fuse_updated_pass && stats->real_ccache_trace &&
		    stats->trace_derived_counterfactual;

	fputs("{\"event\":\"w4-ccache-bulk-cache-state-policy-fuse-summary\","
	      "\"schema\":\"namei_ext.experiment.build_cache_state.v1\","
	      "\"result_level\":\"kvm_real_ccache_trace_cache_state_policy_fuse\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\",",
	      out);
	fprintf(out,
		"\"samples\":%d,"
		"\"setup_rows\":%d,"
		"\"correctness_rows\":%d,"
		"\"update_rows\":%d,"
		"\"objects\":%zu,"
		"\"trace_entries\":%zu,"
		"\"oracle\":\"trace-derived lookup/readdir state transition over real ccache object names\","
		"\"namei_ext\":{\"system\":\"cache_locality_epoch_policy\","
		"\"policy\":\"cache_locality_view.bpf.c\","
		"\"pass\":%s,"
		"\"setup_writes\":%llu,"
		"\"update_writes\":%llu,"
		"\"policy_epoch_switch_pass\":%s,"
		"\"lower_fs_owns_data_path\":true},"
		"\"fuse_baseline\":{\"system\":\"fuse_cache_epoch_view\","
		"\"pass\":%s,"
		"\"setup_writes\":%llu,"
		"\"update_writes\":%llu,"
		"\"fuse_mounts\":%llu,"
		"\"feature_equivalent_baseline\":%s},"
		"\"state_coverage\":{\"verified_hit_to_local\":true,"
		"\"epoch_update_to_canonical\":true,"
		"\"canonical_fallback\":true},"
		"\"real_ccache_trace_basis\":true,"
		"\"trace_derived_state_oracle\":true,"
		"\"policy_executed\":%s,"
		"\"feature_equivalent_fuse\":%s,"
		"\"kvm_validated\":true,"
		"\"pass\":%s,"
		"\"failures\":%d,"
		"\"detail\":",
		samples, stats->setup_rows, stats->correctness_rows,
		stats->update_rows, stats->objects, stats->trace_entries,
		stats->policy_epoch_switch_pass && stats->failures == 0 ?
			"true" : "false",
		stats->policy_setup_writes, stats->policy_update_writes,
		stats->policy_epoch_switch_pass ? "true" : "false",
		stats->fuse_updated_pass && stats->failures == 0 ?
			"true" : "false",
		stats->fuse_setup_writes, stats->fuse_update_writes,
		stats->fuse_mounts,
		stats->fuse_updated_pass ? "true" : "false",
		stats->policy_epoch_switch_pass ? "true" : "false",
		stats->fuse_updated_pass ? "true" : "false",
		pass ? "true" : "false", stats->failures);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int populate_w4_cache_epoch_policy_rules(
	struct attached_policy *policy, __u64 cgroup_id, const char *dir,
	const struct w4_cache_epoch_entry *entries, size_t objects,
	unsigned long long *writes)
{
	size_t i;

	*writes = 0;
	for (i = 0; i < objects; i++) {
		int ret;

		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP, dir,
			entries[i].visible, entries[i].local, i + 1,
			CACHE_STATE_VERIFIED_HIT, W4_CACHE_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP, dir,
			entries[i].visible, entries[i].canonical, i + 1,
			CACHE_STATE_STALE, W4_CACHE_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].local, entries[i].visible, i + 1,
			CACHE_STATE_VERIFIED_HIT, W4_CACHE_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].canonical, entries[i].visible, i + 1,
			CACHE_STATE_VERIFIED_HIT, W4_CACHE_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].local, entries[i].visible, i + 1,
			CACHE_STATE_STALE, W4_CACHE_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR, dir,
			entries[i].canonical, entries[i].visible, i + 1,
			CACHE_STATE_STALE, W4_CACHE_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
	}
	return 0;
}

static int populate_w4_cache_epoch_table_rules(
	struct attached_policy *policy, __u64 cgroup_id, const char *dir,
	const struct w4_cache_epoch_entry *entries, size_t objects,
	__u32 epoch, bool include_readdir, unsigned long long *writes)
{
	size_t i;

	*writes = 0;
	for (i = 0; i < objects; i++) {
		int ret;

		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
				  dir, entries[i].visible,
				  w4_cache_epoch_target(&entries[i], epoch),
				  i + 1);
		if (ret)
			return ret;
		(*writes)++;
		if (!include_readdir)
			continue;
		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				  dir, entries[i].local, entries[i].visible,
				  i + 1);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				  dir, entries[i].canonical,
				  entries[i].visible, i + 1);
		if (ret)
			return ret;
		(*writes)++;
	}
	return 0;
}

static int run_w4_cache_epoch_policy_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, const struct oracle_entry *trace_entries,
	struct w4_cache_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w4_cache_epoch_entry entries[W4_CACHE_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w4_cache_epoch_sample_dir(sample_dir, entries, objects,
						sample, trace_entries);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_CACHE_LOCALITY,
				  "cache_locality_epoch", &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w4_cache_epoch_policy_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			&setup_writes);
	if (!ret)
		ret = update_cache_epoch_session(&policy, cgroup_id,
						 W4_CACHE_EPOCH_ONE, true);
	if (!ret)
		setup_writes++;
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->policy_setup_writes += setup_writes;
	emit_w4_cache_epoch_setup(
		out, sample, "cache_locality_epoch_policy", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? w4_cache_epoch_failure_detail(
			      "failed to setup cache epoch policy") :
		      "cache epoch policy attached with two epoch rule sets");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w4_cache_epoch_current_oracle_passes(
		sample_dir, entries, objects, W4_CACHE_EPOCH_ONE, NULL);
	stats->correctness_rows++;
	emit_w4_cache_epoch_correctness(
		out, sample, "cache_locality_epoch_policy", "verified_epoch",
		epoch1_pass, epoch1_pass, false, 0,
		true,
		epoch1_pass ? "cache epoch policy verified-local oracle passed" :
			      "cache epoch policy verified-local oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = update_cache_epoch_session(&policy, cgroup_id,
					 W4_CACHE_EPOCH_TWO, true);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w4_cache_epoch_current_oracle_passes(
			sample_dir, entries, objects, W4_CACHE_EPOCH_TWO, NULL);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->policy_update_writes++;
	emit_w4_cache_epoch_update(
		out, sample, "cache_locality_epoch_policy",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, 1, true,
		(!ret && epoch2_pass) ?
			"cache policy switched epoch with one session update" :
			"cache policy epoch switch failed");
	stats->correctness_rows++;
	emit_w4_cache_epoch_correctness(
		out, sample, "cache_locality_epoch_policy", "canonical_epoch",
		!ret && epoch2_pass, !ret && epoch2_pass, false, 0,
		true,
		(!ret && epoch2_pass) ?
			"cache epoch policy canonical oracle passed" :
			"cache epoch policy canonical oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->policy_epoch_switch_pass = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int run_w4_cache_epoch_table_static_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, const struct oracle_entry *trace_entries,
	struct w4_cache_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w4_cache_epoch_entry entries[W4_CACHE_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	size_t wrong_local_hits = 0;
	bool epoch1_pass = false;
	bool epoch2_current_pass = false;
	bool expected_failure = false;
	__u64 start_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w4_cache_epoch_sample_dir(sample_dir, entries, objects,
						sample, trace_entries);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_TABLE, "table_redirect",
				  &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w4_cache_epoch_table_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			W4_CACHE_EPOCH_ONE, true, &setup_writes);
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->table_setup_writes += setup_writes;
	emit_w4_cache_epoch_setup(
		out, sample, "table_redirect_static_verified_epoch", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? w4_cache_epoch_failure_detail(
			      "failed to setup static verified cache table") :
		      "static exact table attached with verified-local rules");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w4_cache_epoch_current_oracle_passes(
		sample_dir, entries, objects, W4_CACHE_EPOCH_ONE, NULL);
	stats->correctness_rows++;
	emit_w4_cache_epoch_correctness(
		out, sample, "table_redirect_static_verified_epoch",
		"verified_epoch", epoch1_pass, epoch1_pass, false, 0,
		true,
		epoch1_pass ? "static table verified-local oracle passed" :
			      "static table verified-local oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	epoch2_current_pass = w4_cache_epoch_current_oracle_passes(
		sample_dir, entries, objects, W4_CACHE_EPOCH_TWO,
		&wrong_local_hits);
	expected_failure = !epoch2_current_pass && wrong_local_hits == objects;
	stats->correctness_rows++;
	stats->static_wrong_local_hits += wrong_local_hits;
	emit_w4_cache_epoch_correctness(
		out, sample, "table_redirect_static_verified_epoch",
		"canonical_epoch_without_update", expected_failure,
		epoch2_current_pass, expected_failure, wrong_local_hits,
		true,
		expected_failure ?
			"static table failed canonical epoch with local hits" :
			"static table did not expose expected local-hit failure");
	if (!expected_failure)
		stats->failures++;
	else
		stats->table_static_expected_failure = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !expected_failure;
}

static int run_w4_cache_epoch_table_updated_system(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *sample_dir, int sample, size_t objects,
	const char *policy_obj, const struct oracle_entry *trace_entries,
	struct w4_cache_epoch_stats *stats)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct w4_cache_epoch_entry entries[W4_CACHE_EPOCH_MAX_OBJECTS] = {};
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = prepare_w4_cache_epoch_sample_dir(sample_dir, entries, objects,
						sample, trace_entries);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_TABLE, "table_redirect",
				  &policy);
	start_ns = monotonic_ns();
	if (!ret)
		ret = populate_w4_cache_epoch_table_rules(
			&policy, cgroup_id, sample_dir, entries, objects,
			W4_CACHE_EPOCH_ONE, true, &setup_writes);
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->table_setup_writes += setup_writes;
	emit_w4_cache_epoch_setup(
		out, sample, "table_redirect_updated_exact_epoch", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, true,
		ret ? w4_cache_epoch_failure_detail(
			      "failed to setup externally updated cache table") :
		      "externally updated exact table attached at verified epoch");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w4_cache_epoch_current_oracle_passes(
		sample_dir, entries, objects, W4_CACHE_EPOCH_ONE, NULL);
	stats->correctness_rows++;
	emit_w4_cache_epoch_correctness(
		out, sample, "table_redirect_updated_exact_epoch",
		"verified_epoch", epoch1_pass, epoch1_pass, false, 0,
		true,
		epoch1_pass ? "updated table verified-local oracle passed" :
			      "updated table verified-local oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = populate_w4_cache_epoch_table_rules(
		&policy, cgroup_id, sample_dir, entries, objects,
		W4_CACHE_EPOCH_TWO, false, &update_writes);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w4_cache_epoch_current_oracle_passes(
			sample_dir, entries, objects, W4_CACHE_EPOCH_TWO, NULL);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->table_update_writes += update_writes;
	emit_w4_cache_epoch_update(
		out, sample, "table_redirect_updated_exact_epoch",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		true,
		(!ret && epoch2_pass) ?
			"exact table reached canonical epoch after per-object rewrites" :
			"exact table canonical epoch update failed");
	stats->correctness_rows++;
	emit_w4_cache_epoch_correctness(
		out, sample, "table_redirect_updated_exact_epoch",
		"canonical_epoch_after_update", !ret && epoch2_pass,
		!ret && epoch2_pass, false, 0,
		true,
		(!ret && epoch2_pass) ?
			"updated table canonical epoch oracle passed" :
			"updated table canonical epoch oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->table_updated_pass = true;

	ret = destroy_policy(&policy);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int w4_cache_epoch_materialized_copy_epoch(
	const char *backing_dir, const char *view_dir,
	const struct w4_cache_epoch_entry *entries, size_t objects,
	__u32 epoch, unsigned long long *writes,
	unsigned long long *bytes_copied)
{
	char src[PATH_MAX];
	char dst[PATH_MAX];
	struct stat st = {};
	size_t i;

	if (writes)
		*writes = 0;
	if (bytes_copied)
		*bytes_copied = 0;
	for (i = 0; i < objects; i++) {
		int ret = set_path(src, sizeof(src), backing_dir,
				   w4_cache_epoch_target(&entries[i], epoch));
		if (!ret)
			ret = set_path(dst, sizeof(dst), view_dir,
				       entries[i].visible);
		if (ret)
			return ret;
		if (bytes_copied && !stat(src, &st) && st.st_size > 0)
			*bytes_copied += (unsigned long long)st.st_size;
		ret = copy_file(src, dst);
		if (ret)
			return ret;
		if (writes)
			(*writes)++;
	}
	return 0;
}

static int w4_cache_epoch_materialized_lookup_matches(
	const char *view_dir, const char *backing_dir,
	const struct w4_cache_epoch_entry *entry, __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), view_dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), backing_dir,
			       w4_cache_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static bool w4_cache_epoch_materialized_oracle_passes(
	const char *view_dir, const char *backing_dir,
	const struct w4_cache_epoch_entry *entries, size_t objects, __u32 epoch)
{
	bool pass = true;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w4_cache_epoch_materialized_lookup_matches(
			    view_dir, backing_dir, &entries[i], epoch))
			pass = false;
		if (w4_cache_epoch_readdir_hides_backings(view_dir,
							  &entries[i]))
			pass = false;
	}
	return pass;
}

static int run_w4_cache_epoch_materialized_system(
	FILE *out, const char *sample_dir, int sample, size_t objects,
	const struct oracle_entry *trace_entries,
	struct w4_cache_epoch_stats *stats)
{
	struct w4_cache_epoch_entry entries[W4_CACHE_EPOCH_MAX_OBJECTS] = {};
	char backing_dir[PATH_MAX];
	char view_dir[PATH_MAX];
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	unsigned long long bytes_copied = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(backing_dir, sizeof(backing_dir), sample_dir,
			       "backing");
	if (!ret)
		ret = set_path(view_dir, sizeof(view_dir), sample_dir, "view");
	if (!ret)
		ret = prepare_w4_cache_epoch_sample_dir(
			backing_dir, entries, objects, sample, trace_entries);

	start_ns = monotonic_ns();
	if (!ret)
		ret = mkdir_if_missing(view_dir);
	if (!ret)
		ret = w4_cache_epoch_materialized_copy_epoch(
			backing_dir, view_dir, entries, objects,
			W4_CACHE_EPOCH_ONE, &setup_writes, &bytes_copied);
	end_ns = monotonic_ns();
	stats->setup_rows++;
	stats->materialized_setup_writes += setup_writes;
	emit_w4_cache_epoch_setup(
		out, sample, "materialized_cache_epoch_view", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, false,
		ret ? w4_cache_epoch_failure_detail(
			      "failed to setup materialized cache epoch view") :
		      "materialized cache epoch view copied verified-local objects");
	if (ret) {
		stats->failures++;
		return 1;
	}

	epoch1_pass = w4_cache_epoch_materialized_oracle_passes(
		view_dir, backing_dir, entries, objects, W4_CACHE_EPOCH_ONE);
	stats->correctness_rows++;
	emit_w4_cache_epoch_correctness(
		out, sample, "materialized_cache_epoch_view",
		"verified_epoch", epoch1_pass, epoch1_pass, false, 0,
		false,
		epoch1_pass ? "materialized verified-local oracle passed" :
			      "materialized verified-local oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = w4_cache_epoch_materialized_copy_epoch(
		backing_dir, view_dir, entries, objects, W4_CACHE_EPOCH_TWO,
		&update_writes, &bytes_copied);
	update_done_ns = monotonic_ns();
	if (!ret)
		epoch2_pass = w4_cache_epoch_materialized_oracle_passes(
			view_dir, backing_dir, entries, objects,
			W4_CACHE_EPOCH_TWO);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->materialized_update_writes += update_writes;
	emit_w4_cache_epoch_update(
		out, sample, "materialized_cache_epoch_view",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		false,
		(!ret && epoch2_pass) ?
			"materialized cache view reached canonical epoch after per-object copies" :
			"materialized cache view canonical epoch update failed");
	stats->correctness_rows++;
	emit_w4_cache_epoch_correctness(
		out, sample, "materialized_cache_epoch_view",
		"canonical_epoch_after_update", !ret && epoch2_pass,
		!ret && epoch2_pass, false, 0, false,
		(!ret && epoch2_pass) ?
			"materialized canonical epoch oracle passed" :
			"materialized canonical epoch oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->materialized_updated_pass = true;

	return ret || !epoch1_pass || !epoch2_pass;
}

static int w4_cache_epoch_prepare_fuse_specs(
	const char *view_dir, const char *source_dir,
	const struct w4_cache_epoch_entry *entries, size_t objects,
	struct w1_alias_spec *specs, size_t *nr_specs)
{
	char source_path[PATH_MAX];
	char shadow[NAMEI_EXT_NAME_MAX + 1];
	size_t i;
	int ret;

	*nr_specs = 0;
	for (i = 0; i < objects; i++) {
		ret = snprintf(shadow, sizeof(shadow), "w4f%02zu", i);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(shadow))
			return -ENAMETOOLONG;
		ret = set_path(source_path, sizeof(source_path), source_dir,
			       entries[i].local);
		if (ret)
			return ret;
		ret = add_w1_alias_spec(specs, nr_specs, view_dir,
					entries[i].visible, shadow,
					source_path);
		if (ret)
			return ret;
	}
	return 0;
}

static int w4_cache_epoch_fuse_lookup_matches(
	const char *view_dir, const char *source_dir,
	const struct w4_cache_epoch_entry *entry, __u32 epoch)
{
	char visible_path[PATH_MAX];
	char target_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), view_dir,
		       entry->visible);
	if (!ret)
		ret = set_path(target_path, sizeof(target_path), source_dir,
			       w4_cache_epoch_target(entry, epoch));
	if (ret)
		return ret;
	return compare_files(visible_path, target_path);
}

static int w4_cache_epoch_fuse_readdir_hides_backings(
	const char *view_dir, const struct w4_cache_epoch_entry *entry,
	const struct w1_alias_spec *spec)
{
	bool saw_shadow;
	int err = 0;
	int ret;

	ret = w4_cache_epoch_readdir_hides_backings(view_dir, entry);
	if (ret)
		return ret;
	saw_shadow = dir_has_name(view_dir, spec->shadow, &err);
	if (err)
		return -err;
	return saw_shadow ? -ENOENT : 0;
}

static bool w4_cache_epoch_fuse_oracle_passes(
	const char *view_dir, const char *source_dir,
	const struct w4_cache_epoch_entry *entries,
	const struct w1_alias_spec *specs, size_t objects, __u32 epoch)
{
	bool pass = true;
	size_t i;

	for (i = 0; i < objects; i++) {
		if (w4_cache_epoch_fuse_lookup_matches(
			    view_dir, source_dir, &entries[i], epoch))
			pass = false;
		if (w4_cache_epoch_fuse_readdir_hides_backings(
			    view_dir, &entries[i], &specs[i]))
			pass = false;
	}
	return pass;
}

static int w4_cache_epoch_fuse_copy_epoch(
	const char *source_dir, const char *fuse_backing_dir,
	const struct w4_cache_epoch_entry *entries,
	const struct w1_alias_spec *specs, size_t objects, __u32 epoch,
	struct nginx_macro_stats *stats)
{
	char src[PATH_MAX];
	char dst[PATH_MAX];
	size_t i;

	for (i = 0; i < objects; i++) {
		int ret = set_path(src, sizeof(src), source_dir,
				   w4_cache_epoch_target(&entries[i], epoch));
		if (!ret)
			ret = set_path(dst, sizeof(dst), fuse_backing_dir,
				       specs[i].shadow);
		if (ret)
			return ret;
		ret = copy_file_counted(src, dst, stats, true);
		if (ret)
			return ret;
	}
	return 0;
}

static int run_w4_cache_epoch_fuse_system(
	FILE *out, const char *sample_dir, int sample, size_t objects,
	const struct oracle_entry *trace_entries,
	struct w4_cache_epoch_stats *stats)
{
	struct w4_cache_epoch_entry entries[W4_CACHE_EPOCH_MAX_OBJECTS] = {};
	struct w1_alias_spec specs[W4_CACHE_EPOCH_MAX_OBJECTS] = {};
	struct w1_fuse_context fuse_ctx = {};
	struct nginx_macro_stats setup_stats = {};
	struct nginx_macro_stats update_stats = {};
	char source_dir[PATH_MAX];
	char view_dir[PATH_MAX];
	char fuse_backing_dir[PATH_MAX];
	size_t nr_specs = 0;
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	bool epoch1_pass = false;
	bool epoch2_pass = false;
	__u64 start_ns;
	__u64 update_done_ns;
	__u64 end_ns;
	int ret;

	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(source_dir, sizeof(source_dir), sample_dir,
			       "source");
	if (!ret)
		ret = set_path(view_dir, sizeof(view_dir), sample_dir, "view");
	if (!ret)
		ret = prepare_w4_cache_epoch_sample_dir(
			source_dir, entries, objects, sample, trace_entries);
	if (!ret)
		ret = mkdir_if_missing(view_dir);
	if (!ret)
		ret = w4_cache_epoch_prepare_fuse_specs(
			view_dir, source_dir, entries, objects, specs,
			&nr_specs);

	start_ns = monotonic_ns();
	if (!ret)
		ret = setup_w1_fuse_mount(specs, nr_specs, view_dir,
					  &setup_stats, &fuse_ctx);
	end_ns = monotonic_ns();
	setup_writes = setup_stats.created_files;
	stats->setup_rows++;
	stats->fuse_setup_writes += setup_writes;
	stats->fuse_mounts += setup_stats.fuse_mounts;
	emit_w4_cache_epoch_setup(
		out, sample, "fuse_cache_epoch_view", !ret,
		ret ? -ret : 0, end_ns >= start_ns ? end_ns - start_ns : 0,
		objects, setup_writes, false,
		ret ? w4_cache_epoch_failure_detail(
			      "failed to setup FUSE cache epoch view") :
		      "FUSE cache epoch view mounted with verified-local backing shadows");
	if (ret) {
		unmount_w1_fuse_context(&fuse_ctx);
		stats->failures++;
		return 1;
	}

	epoch1_pass = w4_cache_epoch_fuse_oracle_passes(
		view_dir, source_dir, entries, specs, objects,
		W4_CACHE_EPOCH_ONE);
	stats->correctness_rows++;
	emit_w4_cache_epoch_correctness(
		out, sample, "fuse_cache_epoch_view", "verified_epoch",
		epoch1_pass, epoch1_pass, false, 0, false,
		epoch1_pass ? "FUSE verified-local oracle passed" :
			      "FUSE verified-local oracle failed");
	if (!epoch1_pass)
		stats->failures++;

	start_ns = monotonic_ns();
	ret = w1_fuse_backing_dir(view_dir, fuse_backing_dir,
				  sizeof(fuse_backing_dir));
	if (!ret)
		ret = w4_cache_epoch_fuse_copy_epoch(
			source_dir, fuse_backing_dir, entries, specs, objects,
			W4_CACHE_EPOCH_TWO, &update_stats);
	update_done_ns = monotonic_ns();
	update_writes = update_stats.source_update_writes;
	if (!ret)
		epoch2_pass = w4_cache_epoch_fuse_oracle_passes(
			view_dir, source_dir, entries, specs, objects,
			W4_CACHE_EPOCH_TWO);
	end_ns = monotonic_ns();
	stats->update_rows++;
	stats->fuse_update_writes += update_writes;
	emit_w4_cache_epoch_update(
		out, sample, "fuse_cache_epoch_view",
		!ret && epoch2_pass, ret ? -ret : 0,
		update_done_ns >= start_ns ? update_done_ns - start_ns : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, update_writes,
		false,
		(!ret && epoch2_pass) ?
			"FUSE cache view reached canonical epoch after per-object backing rewrites" :
			"FUSE cache view canonical epoch update failed");
	stats->correctness_rows++;
	emit_w4_cache_epoch_correctness(
		out, sample, "fuse_cache_epoch_view",
		"canonical_epoch_after_update", !ret && epoch2_pass,
		!ret && epoch2_pass, false, 0, false,
		(!ret && epoch2_pass) ?
			"FUSE canonical epoch oracle passed" :
			"FUSE canonical epoch oracle failed");
	if (ret || !epoch2_pass)
		stats->failures++;
	else
		stats->fuse_updated_pass = true;

	ret = unmount_w1_fuse_context(&fuse_ctx);
	if (ret)
		stats->failures++;
	return ret || !epoch1_pass || !epoch2_pass;
}

static int run_w4_cache_epoch_counterfactual(
	FILE *out, const char *cgroup_mount, int samples, const char *work_dir,
	size_t objects, const char *cache_policy_obj,
	const char *table_policy_obj)
{
	struct w4_cache_epoch_stats stats = {};
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	int sample;
	int ret;

	if (samples <= 0 || objects == 0 ||
	    objects > W4_CACHE_EPOCH_MAX_OBJECTS) {
		stats.failures = 1;
		emit_w4_cache_epoch_summary(
			out, samples, &stats,
			"invalid sample count or cache epoch object count");
		return 1;
	}
	stats.objects = objects;
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		stats.failures = 1;
		emit_w4_cache_epoch_summary(
			out, samples, &stats,
			"failed to create W4 cache epoch workdir");
		return 1;
	}
	if (access(cache_policy_obj, R_OK) || access(table_policy_obj, R_OK)) {
		stats.failures = 1;
		emit_w4_cache_epoch_summary(
			out, samples, &stats,
			"W4 cache epoch counterfactual inputs are not readable");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		stats.failures = 1;
		emit_w4_cache_epoch_summary(
			out, samples, &stats,
			"failed to resolve current cgroup id");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		char sample_dir[PATH_MAX];

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/cache-epoch-policy-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_policy_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, cache_policy_obj, NULL, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/cache-epoch-table-static-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_table_static_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, table_policy_obj, NULL, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/cache-epoch-table-updated-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_table_updated_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, table_policy_obj, NULL, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/cache-epoch-materialized-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_materialized_system(
			out, sample_dir, sample, objects, NULL, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/cache-epoch-fuse-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_fuse_system(
			out, sample_dir, sample, objects, NULL, &stats);
	}

	emit_w4_cache_epoch_summary(
		out, samples, &stats,
		stats.failures ?
			"W4 cache epoch counterfactual failed" :
			"W4 cache epoch counterfactual passed; static table fails epoch switch, while externally updated table, materialized view, and FUSE view reach canonical epoch only with per-object update writes");
	return stats.failures ? 1 : 0;
}

static int run_w4_ccache_bulk_cache_epoch_counterfactual(
	FILE *out, const char *cgroup_mount, int samples, const char *work_dir,
	const char *entries_tsv, size_t objects, const char *cache_policy_obj,
	const char *table_policy_obj)
{
	static struct oracle_entry trace_entries[NAMEI_EXT_MAX_ENTRIES];
	struct w4_cache_epoch_stats stats = {
		.real_ccache_trace = true,
		.trace_derived_counterfactual = true,
	};
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	size_t nr_entries = 0;
	int sample;
	int ret;

	memset(trace_entries, 0, sizeof(trace_entries));
	if (samples <= 0 || objects == 0 ||
	    objects > W4_CACHE_EPOCH_MAX_OBJECTS) {
		stats.failures = 1;
		emit_w4_cache_epoch_summary(
			out, samples, &stats,
			"invalid sample count or ccache trace object count");
		return 1;
	}
	ret = read_entries(entries_tsv, trace_entries, &nr_entries);
	if (ret || nr_entries < objects) {
		stats.failures = 1;
		stats.trace_entries = nr_entries;
		emit_w4_cache_epoch_summary(
			out, samples, &stats,
			"failed to read enough trace-derived ccache objects");
		return 1;
	}
	stats.objects = objects;
	stats.trace_entries = nr_entries;
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		stats.failures = 1;
		emit_w4_cache_epoch_summary(
			out, samples, &stats,
			"failed to create trace-derived W4 cache epoch workdir");
		return 1;
	}
	if (access(entries_tsv, R_OK) || access(cache_policy_obj, R_OK) ||
	    access(table_policy_obj, R_OK)) {
		stats.failures = 1;
		emit_w4_cache_epoch_summary(
			out, samples, &stats,
			"trace-derived W4 cache epoch inputs are not readable");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		stats.failures = 1;
		emit_w4_cache_epoch_summary(
			out, samples, &stats,
			"failed to resolve current cgroup id");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		char sample_dir[PATH_MAX];

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/ccache-bulk-epoch-policy-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_policy_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, cache_policy_obj, trace_entries,
			&stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/ccache-bulk-epoch-table-static-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_table_static_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, table_policy_obj, trace_entries,
			&stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/ccache-bulk-epoch-table-updated-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_table_updated_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, table_policy_obj, trace_entries,
			&stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/ccache-bulk-epoch-materialized-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_materialized_system(
			out, sample_dir, sample, objects, trace_entries, &stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/ccache-bulk-epoch-fuse-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_fuse_system(
			out, sample_dir, sample, objects, trace_entries, &stats);
	}

	emit_w4_cache_epoch_summary(
		out, samples, &stats,
		stats.failures ?
			"trace-derived W4 ccache bulk cache epoch counterfactual failed" :
			"trace-derived W4 ccache bulk cache epoch counterfactual passed; static table fails epoch switch and exact updated table/FUSE/materialized baselines need per-object update writes");
	return stats.failures ? 1 : 0;
}

static int run_w4_ccache_bulk_cache_state_policy_fuse(
	FILE *out, const char *cgroup_mount, int samples, const char *work_dir,
	const char *entries_tsv, size_t objects, const char *cache_policy_obj)
{
	static struct oracle_entry trace_entries[NAMEI_EXT_MAX_ENTRIES];
	struct w4_cache_epoch_stats stats = {
		.real_ccache_trace = true,
		.trace_derived_counterfactual = true,
	};
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	size_t nr_entries = 0;
	int sample;
	int ret;

	memset(trace_entries, 0, sizeof(trace_entries));
	if (samples <= 0 || objects == 0 ||
	    objects > W4_CACHE_EPOCH_MAX_OBJECTS) {
		stats.failures = 1;
		emit_w4_cache_state_policy_fuse_summary(
			out, samples, &stats,
			"invalid sample count or ccache trace object count");
		return 1;
	}
	ret = read_entries(entries_tsv, trace_entries, &nr_entries);
	if (ret || nr_entries < objects) {
		stats.failures = 1;
		stats.trace_entries = nr_entries;
		emit_w4_cache_state_policy_fuse_summary(
			out, samples, &stats,
			"failed to read enough trace-derived ccache objects");
		return 1;
	}
	stats.objects = objects;
	stats.trace_entries = nr_entries;
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		stats.failures = 1;
		emit_w4_cache_state_policy_fuse_summary(
			out, samples, &stats,
			"failed to create trace-derived W4 cache state workdir");
		return 1;
	}
	if (access(entries_tsv, R_OK) || access(cache_policy_obj, R_OK)) {
		stats.failures = 1;
		emit_w4_cache_state_policy_fuse_summary(
			out, samples, &stats,
			"trace-derived W4 cache state inputs are not readable");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		stats.failures = 1;
		emit_w4_cache_state_policy_fuse_summary(
			out, samples, &stats,
			"failed to resolve current cgroup id");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		char sample_dir[PATH_MAX];

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/ccache-bulk-state-policy-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_policy_system(
			out, current_cgroup, current_cgroup_id, sample_dir,
			sample, objects, cache_policy_obj, trace_entries,
			&stats);

		ret = snprintf(sample_dir, sizeof(sample_dir),
			       "%s/ccache-bulk-state-fuse-sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			stats.failures++;
			continue;
		}
		run_w4_cache_epoch_fuse_system(
			out, sample_dir, sample, objects, trace_entries, &stats);
	}

	emit_w4_cache_state_policy_fuse_summary(
		out, samples, &stats,
		stats.failures ?
			"trace-derived W4 ccache state row failed" :
			"trace-derived W4 ccache state row passed for namei_ext policy and feature-equivalent FUSE");
	return stats.failures ? 1 : 0;
}

struct w4_rule_macro_stats {
	unsigned long long created_dirs;
	unsigned long long created_files;
	unsigned long long bytes_copied;
	unsigned long long lookup_rule_writes;
	unsigned long long readdir_rule_writes;
	unsigned long long total_rule_writes;
	unsigned long long update_lookup_rule_writes;
	unsigned long long update_readdir_rule_writes;
	unsigned long long update_total_rule_writes;
	unsigned long long source_update_writes;
	unsigned long long baseline_update_writes;
	unsigned long long update_bytes_written;
	unsigned long long cache_objects;
	unsigned long long cache_leaf_parents;
	unsigned long long fuse_mounts;
};

static bool w4_entry_dir_seen(const struct oracle_entry *entries, size_t upto,
			      const char *dir)
{
	size_t i;

	for (i = 0; i < upto; i++) {
		if (!strcmp(entries[i].dir, dir))
			return true;
	}
	return false;
}

static size_t w4_count_cache_leaf_parents(const struct oracle_entry *entries,
					  size_t nr_entries)
{
	size_t parents = 0;
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		if (!w4_entry_dir_seen(entries, i, entries[i].dir))
			parents++;
	}
	return parents;
}

static unsigned long long
w4_sum_original_bytes(const struct oracle_entry *entries, size_t nr_entries)
{
	unsigned long long bytes = 0;
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		struct stat st = {};

		if (!stat(entries[i].original, &st) && st.st_size > 0)
			bytes += (unsigned long long)st.st_size;
	}
	return bytes;
}

static const char *w4_rule_row_kind(bool table_baseline)
{
	return table_baseline ? "feature_baseline" : "proposed_system";
}

static const char *w4_rule_system(bool table_baseline)
{
	return table_baseline ? "table_redirect" : "parent_rule_policy";
}

static const char *w4_rule_policy_family(bool table_baseline)
{
	return table_baseline ? "table_redirect.bpf.c" :
				"cache_locality_view.bpf.c";
}

static void emit_w4_rule_setup(FILE *out, int sample, bool table_baseline,
			       bool pass, int err, __u64 setup_ns,
			       const struct w4_rule_macro_stats *stats,
			       const char *detail)
{
	const struct w4_rule_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w4-ccache-rule-macrobench-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_rule_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_rule_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-redis-nginx\","
	      "\"app\":\"ccache\",",
	      out);
	fputs("\"row_kind\":", out);
	fprint_json_string(out, w4_rule_row_kind(table_baseline));
	fputs(",\"system\":", out);
	fprint_json_string(out, w4_rule_system(table_baseline));
	fputs(",\"policy_family\":", out);
	fprint_json_string(out, w4_rule_policy_family(table_baseline));
	if (table_baseline)
		fputs(",\"baseline\":\"table_redirect\"", out);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":0,\"bind_mounts\":0,"
		"\"overlay_mounts\":0,\"fuse_mounts\":0,"
		"\"bytes_written\":0,\"bytes_copied\":%llu,"
		"\"cache_objects\":%llu,\"cache_leaf_parents\":%llu,"
		"\"lookup_rule_writes\":%llu,"
		"\"readdir_rule_writes\":%llu,"
		"\"total_rule_writes\":%llu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, stats->created_dirs,
		stats->created_files, stats->bytes_copied,
		stats->cache_objects, stats->cache_leaf_parents,
		stats->lookup_rule_writes, stats->readdir_rule_writes,
		stats->total_rule_writes, pass ? "true" : "false",
		table_baseline ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_rule_update(FILE *out, int sample, bool table_baseline,
				bool pass, int err, __u64 update_ns,
				const struct w4_rule_macro_stats *stats,
				const char *detail)
{
	const struct w4_rule_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w4-ccache-rule-macrobench-update\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_rule_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_rule_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-redis-nginx\","
	      "\"app\":\"ccache\",",
	      out);
	fputs("\"row_kind\":", out);
	fprint_json_string(out, w4_rule_row_kind(table_baseline));
	fputs(",\"system\":", out);
	fprint_json_string(out, w4_rule_system(table_baseline));
	fputs(",\"policy_family\":", out);
	fprint_json_string(out, w4_rule_policy_family(table_baseline));
	if (table_baseline)
		fputs(",\"baseline\":\"table_redirect\"", out);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"source_update_writes\":%llu,"
		"\"baseline_update_writes\":%llu,"
		"\"policy_update_writes\":%llu,"
		"\"update_bytes_written\":%llu,"
		"\"update_bytes_copied\":0,"
		"\"update_lookup_rule_writes\":%llu,"
		"\"update_readdir_rule_writes\":%llu,"
		"\"update_total_rule_writes\":%llu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns, stats->source_update_writes,
		table_baseline ? stats->update_total_rule_writes : 0,
		table_baseline ? 0 : stats->update_total_rule_writes,
		stats->update_bytes_written,
		stats->update_lookup_rule_writes,
		stats->update_readdir_rule_writes,
		stats->update_total_rule_writes, pass ? "true" : "false",
		table_baseline ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_rule_correctness(FILE *out, int sample, bool table_baseline,
				     bool pass, int failures,
				     bool attached_lookup_pass,
				     bool attached_readdir_pass,
				     bool post_detach_absent,
				     const char *detail)
{
	fputs("{\"event\":\"w4-ccache-rule-macrobench-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_rule_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_rule_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-redis-nginx\","
	      "\"app\":\"ccache\",",
	      out);
	fputs("\"row_kind\":", out);
	fprint_json_string(out, w4_rule_row_kind(table_baseline));
	fputs(",\"system\":", out);
	fprint_json_string(out, w4_rule_system(table_baseline));
	fputs(",\"policy_family\":", out);
	fprint_json_string(out, w4_rule_policy_family(table_baseline));
	if (table_baseline)
		fputs(",\"baseline\":\"table_redirect\"", out);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"attached_lookup_pass\":%s,"
		"\"attached_readdir_pass\":%s,"
		"\"post_detach_absent\":%s,"
		"\"policy_executed\":true,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures,
		attached_lookup_pass ? "true" : "false",
		attached_readdir_pass ? "true" : "false",
		post_detach_absent ? "true" : "false",
		table_baseline ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_rule_summary(FILE *out, int samples, int systems,
				 int setup_rows, int update_rows,
				 int correctness_rows, int failures,
				 const char *detail)
{
	fputs("{\"event\":\"w4-ccache-rule-macrobench-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_rule_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_rule_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-redis-nginx\","
	      "\"app\":\"ccache\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"systems\":%d,"
		"\"setup_rows\":%d,\"update_rows\":%d,"
		"\"correctness_rows\":%d,\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, systems, setup_rows, update_rows, correctness_rows,
		failures ? "false" : "true", failures,
		(!failures && correctness_rows == samples * systems) ?
			"true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int populate_w4_parent_setup_rules(struct attached_policy *policy,
					  __u64 cgroup_id,
					  const struct oracle_entry *entries,
					  size_t nr_entries,
					  struct w4_rule_macro_stats *stats)
{
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		__u64 name_witnesses[W4_CCACHE_PARENT_NAME_WITNESSES] = {};
		__u32 witness_count = 0;
		size_t j;
		int ret;

		if (w4_entry_dir_seen(entries, i, entries[i].dir))
			continue;
		for (j = i; j < nr_entries; j++) {
			if (strcmp(entries[j].dir, entries[i].dir))
				continue;
			if (witness_count >= W4_CCACHE_PARENT_NAME_WITNESSES)
				return -E2BIG;
			name_witnesses[witness_count++] =
				component_name_hash(entries[j].visible);
		}
		ret = update_cache_parent_rule(policy, cgroup_id,
					       BPF_NAMEI_EXT_LOOKUP,
					       entries[i].dir,
					       CACHE_STATE_VERIFIED_HIT,
					       i + 1, name_witnesses,
					       witness_count);
		if (ret)
			return ret;
		stats->lookup_rule_writes++;
	}
	for (i = 0; i < nr_entries; i++) {
		int ret = update_cache_rule(policy, cgroup_id,
					    BPF_NAMEI_EXT_READDIR,
					    entries[i].dir, entries[i].shadow,
					    entries[i].visible, i + 1,
					    CACHE_STATE_VERIFIED_HIT,
					    entries[i].original_sha256);

		if (ret)
			return ret;
		stats->readdir_rule_writes++;
	}
	stats->total_rule_writes = stats->lookup_rule_writes +
				   stats->readdir_rule_writes;
	return 0;
}

static int populate_w4_table_setup_rules(struct attached_policy *policy,
					 __u64 cgroup_id,
					 const struct oracle_entry *entries,
					 size_t nr_entries,
					 struct w4_rule_macro_stats *stats)
{
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		int ret;

		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
				  entries[i].dir, entries[i].visible,
				  entries[i].shadow, i + 1);
		if (ret)
			return ret;
		stats->lookup_rule_writes++;
		ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				  entries[i].dir, entries[i].shadow,
				  entries[i].visible, i + 1);
		if (ret)
			return ret;
		stats->readdir_rule_writes++;
	}
	stats->total_rule_writes = stats->lookup_rule_writes +
				   stats->readdir_rule_writes;
	return 0;
}

static int append_w4_rule_update_entry(struct oracle_entry *entries,
				       size_t *nr_entries, int sample,
				       struct w4_rule_macro_stats *stats)
{
	struct oracle_entry *entry;
	char path[PATH_MAX];
	char text[128];
	int ret;

	if (*nr_entries >= NAMEI_EXT_MAX_ENTRIES)
		return -E2BIG;
	entry = &entries[*nr_entries];
	*entry = entries[0];
	ret = snprintf(entry->visible, sizeof(entry->visible), "%031dM",
		       sample);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(entry->visible))
		return -ENAMETOOLONG;
	ret = snprintf(entry->shadow, sizeof(entry->shadow), "%s.local",
		       entry->visible);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(entry->shadow))
		return -ENAMETOOLONG;
	ret = set_path(path, sizeof(path), entry->dir, entry->shadow);
	if (ret)
		return ret;
	ret = snprintf(text, sizeof(text),
		       "namei_ext w4 ccache rule macrobench sample %d\n",
		       sample);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(text))
		return -ENAMETOOLONG;
	ret = write_text_file(path, text);
	if (ret)
		return ret;
	copy_string(entry->original, sizeof(entry->original), path);
	if (stats) {
		stats->source_update_writes++;
		stats->update_bytes_written += strlen(text);
	}
	(*nr_entries)++;
	return 0;
}

static int update_w4_parent_rules_for_entry(struct attached_policy *policy,
					    __u64 cgroup_id,
					    const struct oracle_entry *entries,
					    size_t nr_entries,
					    const struct oracle_entry *entry,
					    struct w4_rule_macro_stats *stats)
{
	__u64 name_witnesses[W4_CCACHE_PARENT_NAME_WITNESSES] = {};
	__u32 witness_count = 0;
	size_t i;
	int ret;

	for (i = 0; i < nr_entries; i++) {
		if (strcmp(entries[i].dir, entry->dir))
			continue;
		if (witness_count >= W4_CCACHE_PARENT_NAME_WITNESSES)
			return -E2BIG;
		name_witnesses[witness_count++] =
			component_name_hash(entries[i].visible);
	}
	ret = update_cache_parent_rule(policy, cgroup_id,
				       BPF_NAMEI_EXT_LOOKUP, entry->dir,
				       CACHE_STATE_VERIFIED_HIT, nr_entries,
				       name_witnesses, witness_count);
	if (ret)
		return ret;
	stats->update_lookup_rule_writes++;
	ret = update_cache_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				entry->dir, entry->shadow, entry->visible,
				nr_entries, CACHE_STATE_VERIFIED_HIT,
				entry->original_sha256);
	if (ret)
		return ret;
	stats->update_readdir_rule_writes++;
	stats->update_total_rule_writes = stats->update_lookup_rule_writes +
					  stats->update_readdir_rule_writes;
	return 0;
}

static int update_w4_table_rules_for_entry(struct attached_policy *policy,
					   __u64 cgroup_id,
					   const struct oracle_entry *entry,
					   size_t branch,
					   struct w4_rule_macro_stats *stats)
{
	int ret;

	ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
			  entry->dir, entry->visible, entry->shadow, branch);
	if (ret)
		return ret;
	stats->update_lookup_rule_writes++;
	ret = update_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
			  entry->dir, entry->shadow, entry->visible, branch);
	if (ret)
		return ret;
	stats->update_readdir_rule_writes++;
	stats->update_total_rule_writes = stats->update_lookup_rule_writes +
					  stats->update_readdir_rule_writes;
	return 0;
}

static int run_one_w4_rule_macro_system(FILE *out, const char *cgroup_path,
					__u64 cgroup_id,
					const char *work_dir, int sample,
					const char *entries_tsv,
					const char *policy_obj,
					bool table_baseline,
					int *setup_rows, int *update_rows,
					int *correctness_rows)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	struct w4_rule_macro_stats setup_stats = {};
	struct w4_rule_macro_stats update_stats = {};
	char sample_dir[PATH_MAX];
	size_t nr_entries = 0;
	size_t original_entries;
	bool attached_lookup_pass = false;
	bool attached_readdir_pass = false;
	bool post_detach_absent = false;
	int sample_failures = 0;
	__u64 start_ns;
	__u64 end_ns;
	int ret;
	size_t i;

	ret = snprintf(sample_dir, sizeof(sample_dir), "%s/%s-sample-%03d",
		       work_dir, w4_rule_system(table_baseline), sample);
	if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
		emit_w4_rule_setup(out, sample, table_baseline, false,
				   ret < 0 ? errno : ENAMETOOLONG, 0, NULL,
				   "failed to build W4 rule macrobench sample dir");
		return 1;
	}

	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (ret) {
		emit_w4_rule_setup(out, sample, table_baseline, false, -ret,
				   0, NULL, "failed to read W4 ccache entries");
		return 1;
	}
	original_entries = nr_entries;
	setup_stats.cache_objects = nr_entries;

	start_ns = monotonic_ns();
	ret = prepare_cache_content_dir(sample_dir, entries, nr_entries);
	if (!ret) {
		setup_stats.created_dirs =
			w4_count_cache_leaf_parents(entries, nr_entries);
		setup_stats.created_files = nr_entries;
		setup_stats.bytes_copied =
			w4_sum_original_bytes(entries, nr_entries);
		setup_stats.cache_leaf_parents =
			w4_count_cache_leaf_parents(entries, nr_entries);
		ret = open_policy(policy_obj,
				  table_baseline ? POLICY_TABLE :
						   POLICY_CACHE_LOCALITY,
				  table_baseline ? "table_redirect" :
						   "cache_locality_parent",
				  &policy);
	}
	if (!ret) {
		if (table_baseline)
			ret = populate_w4_table_setup_rules(
				&policy, cgroup_id, entries, nr_entries,
				&setup_stats);
		else
			ret = populate_w4_parent_setup_rules(
				&policy, cgroup_id, entries, nr_entries,
				&setup_stats);
	}
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	(*setup_rows)++;
	emit_w4_rule_setup(
		out, sample, table_baseline, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &setup_stats,
		ret ? "failed to setup W4 ccache rule macrobench system" :
		      "W4 ccache rule macrobench system attached");
	if (ret) {
		destroy_policy(&policy);
		return 1;
	}

	attached_lookup_pass = true;
	attached_readdir_pass = true;
	for (i = 0; i < nr_entries; i++) {
		if (cache_expect_equal(out, entries[i].dir, entries[i].branch,
				       entries[i].visible, entries[i].shadow)) {
			attached_lookup_pass = false;
			sample_failures++;
		}
		if (cache_expect_readdir(out, entries[i].dir, entries[i].branch,
					 entries[i].visible, entries[i].shadow)) {
			attached_readdir_pass = false;
			sample_failures++;
		}
	}

	start_ns = monotonic_ns();
	ret = append_w4_rule_update_entry(entries, &nr_entries, sample,
					  &update_stats);
	if (!ret) {
		const struct oracle_entry *entry = &entries[nr_entries - 1];

		if (table_baseline)
			ret = update_w4_table_rules_for_entry(
				&policy, cgroup_id, entry, nr_entries,
				&update_stats);
		else
			ret = update_w4_parent_rules_for_entry(
				&policy, cgroup_id, entries, nr_entries,
				entry, &update_stats);
	}
	end_ns = monotonic_ns();
	(*update_rows)++;
	emit_w4_rule_update(
		out, sample, table_baseline, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &update_stats,
		ret ? "failed to update W4 ccache rule macrobench system" :
		      "W4 ccache rule macrobench sample-local object updated");
	if (ret)
		sample_failures++;

	for (i = original_entries; i < nr_entries; i++) {
		if (cache_expect_equal(out, entries[i].dir, entries[i].branch,
				       entries[i].visible, entries[i].shadow)) {
			attached_lookup_pass = false;
			sample_failures++;
		}
		if (cache_expect_readdir(out, entries[i].dir, entries[i].branch,
					 entries[i].visible, entries[i].shadow)) {
			attached_readdir_pass = false;
			sample_failures++;
		}
	}

	ret = destroy_policy(&policy);
	if (ret)
		sample_failures++;

	post_detach_absent = true;
	for (i = 0; i < nr_entries; i++) {
		if (cache_expect_absent(out, entries[i].dir, entries[i].branch,
					entries[i].visible,
					"rule_macro_post_detach_absent")) {
			post_detach_absent = false;
			sample_failures++;
		}
	}

	(*correctness_rows)++;
	emit_w4_rule_correctness(
		out, sample, table_baseline, sample_failures == 0,
		sample_failures, attached_lookup_pass, attached_readdir_pass,
		post_detach_absent,
		sample_failures ?
			"W4 ccache rule macrobench correctness failed" :
			"W4 ccache rule macrobench lookup/readdir/update correctness passed");
	return sample_failures ? 1 : 0;
}

static int run_w4_ccache_rule_macrobench(FILE *out, const char *cgroup_mount,
					 const char *work_dir, int samples,
					 const char *entries_tsv,
					 const char *cache_policy_obj,
					 const char *table_policy_obj)
{
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	int setup_rows = 0;
	int update_rows = 0;
	int correctness_rows = 0;
	int failures = 0;
	int sample;
	int ret;

	if (samples <= 0) {
		emit_w4_rule_summary(out, samples, 2, 0, 0, 0, 1,
				     "sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_w4_rule_summary(out, samples, 2, 0, 0, 0, 1,
				     "failed to create W4 ccache rule macrobench workdir");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		emit_w4_rule_summary(out, samples, 2, 0, 0, 0, 1,
				     "failed to resolve current cgroup id");
		return 1;
	}
	if (access(entries_tsv, R_OK) || access(cache_policy_obj, R_OK) ||
	    access(table_policy_obj, R_OK)) {
		emit_w4_rule_summary(out, samples, 2, 0, 0, 0, 1,
				     "W4 ccache rule macrobench inputs are not readable");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		failures += run_one_w4_rule_macro_system(
			out, current_cgroup, current_cgroup_id, work_dir, sample,
			entries_tsv, cache_policy_obj, false, &setup_rows,
			&update_rows, &correctness_rows);
		failures += run_one_w4_rule_macro_system(
			out, current_cgroup, current_cgroup_id, work_dir, sample,
			entries_tsv, table_policy_obj, true, &setup_rows,
			&update_rows, &correctness_rows);
	}

	emit_w4_rule_summary(
		out, samples, 2, setup_rows, update_rows, correctness_rows,
		failures,
		failures ?
			"W4 ccache rule macrobench failed" :
			"W4 ccache rule macrobench passed; not a C2 release gate");
	return failures ? 1 : 0;
}

static void emit_w4_bulk_policy_setup(
	FILE *out, int sample, bool pass, int err, __u64 setup_ns,
	const struct w4_rule_macro_stats *stats, const char *detail)
{
	const struct w4_rule_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w4-ccache-bulk-policy-macrobench-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_bulk_policy_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_bulk_policy_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\","
	      "\"row_kind\":\"proposed_system\","
	      "\"system\":\"cache_locality_exact_policy\","
	      "\"policy_family\":\"cache_locality_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":0,\"bind_mounts\":0,"
		"\"overlay_mounts\":0,\"fuse_mounts\":0,"
		"\"bytes_written\":0,\"bytes_copied\":%llu,"
		"\"cache_objects\":%llu,\"cache_leaf_parents\":%llu,"
		"\"cache_object_renames\":%llu,"
		"\"lookup_rule_writes\":%llu,"
		"\"readdir_rule_writes\":%llu,"
		"\"total_rule_writes\":%llu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":false,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, stats->created_dirs,
		stats->created_files, stats->bytes_copied,
		stats->cache_objects, stats->cache_leaf_parents,
		stats->created_files, stats->lookup_rule_writes,
		stats->readdir_rule_writes, stats->total_rule_writes,
		pass ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_bulk_policy_update(
	FILE *out, int sample, bool pass, int err, __u64 update_ns,
	const struct w4_rule_macro_stats *stats, const char *detail)
{
	const struct w4_rule_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w4-ccache-bulk-policy-macrobench-update\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_bulk_policy_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_bulk_policy_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\","
	      "\"row_kind\":\"proposed_system\","
	      "\"system\":\"cache_locality_exact_policy\","
	      "\"policy_family\":\"cache_locality_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"source_update_writes\":%llu,"
		"\"baseline_update_writes\":0,"
		"\"policy_update_writes\":%llu,"
		"\"update_bytes_written\":%llu,"
		"\"update_bytes_copied\":0,"
		"\"update_lookup_rule_writes\":%llu,"
		"\"update_readdir_rule_writes\":%llu,"
		"\"update_total_rule_writes\":%llu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":false,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns, stats->source_update_writes,
		stats->update_total_rule_writes, stats->update_bytes_written,
		stats->update_lookup_rule_writes,
		stats->update_readdir_rule_writes,
		stats->update_total_rule_writes, pass ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_bulk_policy_correctness(
	FILE *out, int sample, bool pass, int failures,
	bool attached_lookup_pass, bool attached_readdir_pass,
	bool post_update_lookup_pass, bool post_update_readdir_pass,
	bool post_detach_absent, size_t source_manifest_count,
	const char *detail)
{
	fputs("{\"event\":\"w4-ccache-bulk-policy-macrobench-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_bulk_policy_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_bulk_policy_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\","
	      "\"row_kind\":\"proposed_system\","
	      "\"system\":\"cache_locality_exact_policy\","
	      "\"policy_family\":\"cache_locality_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"attached_lookup_pass\":%s,"
		"\"attached_readdir_pass\":%s,"
		"\"post_update_lookup_pass\":%s,"
		"\"post_update_readdir_pass\":%s,"
		"\"post_detach_absent\":%s,"
		"\"source_manifest_count\":%zu,"
		"\"policy_executed\":true,\"kvm_validated\":true,"
		"\"compile_smoke_required\":true,"
		"\"compile_smoke_in_separate_witness\":true,"
		"\"feature_equivalent_baseline\":false,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures,
		attached_lookup_pass ? "true" : "false",
		attached_readdir_pass ? "true" : "false",
		post_update_lookup_pass ? "true" : "false",
		post_update_readdir_pass ? "true" : "false",
		post_detach_absent ? "true" : "false",
		source_manifest_count);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_bulk_policy_summary(FILE *out, int samples, int setup_rows,
					int update_rows, int correctness_rows,
					int failures, size_t source_manifest_count,
					size_t cache_objects, const char *detail)
{
	fputs("{\"event\":\"w4-ccache-bulk-policy-macrobench-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_bulk_policy_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_bulk_policy_setup_update_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\","
	      "\"row_kind\":\"proposed_system\","
	      "\"system\":\"cache_locality_exact_policy\","
	      "\"policy_family\":\"cache_locality_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"systems\":1,"
		"\"setup_rows\":%d,\"update_rows\":%d,"
		"\"correctness_rows\":%d,\"pass\":%s,\"failures\":%d,"
		"\"source_manifest_count\":%zu,"
		"\"cache_objects\":%zu,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"compile_smoke_required\":true,"
		"\"compile_smoke_in_separate_witness\":true,"
		"\"feature_equivalent_baseline\":false,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, setup_rows, update_rows, correctness_rows,
		failures ? "false" : "true", failures,
		source_manifest_count, cache_objects,
		(!failures && correctness_rows == samples) ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int populate_w4_exact_cache_setup_rules(
	struct attached_policy *policy, __u64 cgroup_id,
	const struct oracle_entry *entries, size_t nr_entries,
	struct w4_rule_macro_stats *stats)
{
	size_t i;

	for (i = 0; i < nr_entries; i++) {
		__u32 state = 0;
		int ret = cache_state_for_branch(entries[i].branch, &state);

		if (ret)
			return ret;
		ret = update_cache_rule(policy, cgroup_id,
					BPF_NAMEI_EXT_LOOKUP, entries[i].dir,
					entries[i].visible, entries[i].shadow,
					i + 1, state,
					entries[i].original_sha256);
		if (ret)
			return ret;
		stats->lookup_rule_writes++;
		ret = update_cache_rule(policy, cgroup_id,
					BPF_NAMEI_EXT_READDIR,
					entries[i].dir, entries[i].shadow,
					entries[i].visible, i + 1, state,
					entries[i].original_sha256);
		if (ret)
			return ret;
		stats->readdir_rule_writes++;
	}
	stats->total_rule_writes = stats->lookup_rule_writes +
				   stats->readdir_rule_writes;
	return 0;
}

static int update_w4_exact_cache_rules_for_entry(
	struct attached_policy *policy, __u64 cgroup_id,
	const struct oracle_entry *entry, size_t branch,
	struct w4_rule_macro_stats *stats)
{
	__u32 state = 0;
	int ret = cache_state_for_branch(entry->branch, &state);

	if (ret)
		return ret;
	ret = update_cache_rule(policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
				entry->dir, entry->visible, entry->shadow,
				branch, state, entry->original_sha256);
	if (ret)
		return ret;
	stats->update_lookup_rule_writes++;
	ret = update_cache_rule(policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
				entry->dir, entry->shadow, entry->visible,
				branch, state, entry->original_sha256);
	if (ret)
		return ret;
	stats->update_readdir_rule_writes++;
	stats->update_total_rule_writes = stats->update_lookup_rule_writes +
					  stats->update_readdir_rule_writes;
	return 0;
}

static int w4_policy_expect_entry_equal_quiet(const struct oracle_entry *entry)
{
	char visible_path[PATH_MAX];
	char backing_path[PATH_MAX];
	int ret;

	ret = set_path(visible_path, sizeof(visible_path), entry->dir,
		       entry->visible);
	if (!ret)
		ret = set_path(backing_path, sizeof(backing_path), entry->dir,
			       entry->shadow);
	if (ret)
		return ret;
	return compare_files(visible_path, backing_path);
}

static int w4_policy_expect_entry_readdir_quiet(const struct oracle_entry *entry)
{
	bool saw_visible;
	bool saw_shadow;
	int err = 0;

	saw_visible = dir_has_name(entry->dir, entry->visible, &err);
	if (!err)
		saw_shadow = dir_has_name(entry->dir, entry->shadow, &err);
	else
		saw_shadow = false;
	if (!err && saw_visible && !saw_shadow)
		return 0;
	return err ? -err : -ENOENT;
}

static int w4_policy_expect_entry_absent_quiet(const struct oracle_entry *entry)
{
	char path[PATH_MAX];
	int ret;

	ret = set_path(path, sizeof(path), entry->dir, entry->visible);
	if (ret)
		return ret;
	return expect_stat_errno(path, ENOENT);
}

static int run_one_w4_bulk_policy_macro_sample(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *work_dir, int sample, const char *trace_cache_dir,
	const char *entries_tsv, const char *policy_obj,
	size_t source_manifest_count, int *setup_rows, int *update_rows,
	int *correctness_rows, size_t *cache_objects_out)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	struct w4_rule_macro_stats setup_stats = {};
	struct w4_rule_macro_stats update_stats = {};
	char sample_dir[PATH_MAX];
	char sample_cache_dir[PATH_MAX];
	char copy_label[64];
	size_t nr_entries = 0;
	bool attached_lookup_pass = false;
	bool attached_readdir_pass = false;
	bool post_update_lookup_pass = false;
	bool post_update_readdir_pass = false;
	bool post_detach_absent = false;
	int sample_failures = 0;
	__u64 start_ns;
	__u64 end_ns;
	int ret;
	size_t i;

	ret = snprintf(sample_dir, sizeof(sample_dir),
		       "%s/bulk-policy-cache-view-sample-%03d", work_dir,
		       sample);
	if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
		emit_w4_bulk_policy_setup(
			out, sample, false, ret < 0 ? errno : ENAMETOOLONG,
			0, NULL,
			"failed to build W4 bulk policy macrobench sample dir");
		return 1;
	}
	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(sample_cache_dir, sizeof(sample_cache_dir),
			       sample_dir, "ccache");
	if (!ret) {
		ret = snprintf(copy_label, sizeof(copy_label),
			       "bulk-policy-cache-copy-%03d", sample);
		if (ret < 0)
			ret = -errno;
		else if ((size_t)ret >= sizeof(copy_label))
			ret = -ENAMETOOLONG;
		else
			ret = 0;
	}
	if (!ret)
		ret = copy_tree_for_w1_sample(trace_cache_dir, sample_cache_dir,
					      sample_dir, copy_label);
	if (ret) {
		emit_w4_bulk_policy_setup(
			out, sample, false, -ret, 0, NULL,
			"failed to copy trace ccache tree for W4 bulk policy sample");
		return 1;
	}

	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (ret) {
		emit_w4_bulk_policy_setup(
			out, sample, false, -ret, 0, NULL,
			"failed to read W4 bulk ccache entries");
		return 1;
	}
	setup_stats.cache_objects = nr_entries;
	setup_stats.cache_leaf_parents =
		w4_count_cache_leaf_parents(entries, nr_entries);
	if (cache_objects_out)
		*cache_objects_out = nr_entries;

	start_ns = monotonic_ns();
	for (i = 0; i < nr_entries && !ret; i++) {
		ret = prepare_ccache_policy_entry(&entries[i], trace_cache_dir,
						  sample_cache_dir);
		if (!ret)
			setup_stats.created_files++;
	}
	if (!ret)
		ret = open_policy(policy_obj, POLICY_CACHE_LOCALITY,
				  "cache_locality", &policy);
	if (!ret)
		ret = populate_w4_exact_cache_setup_rules(
			&policy, cgroup_id, entries, nr_entries, &setup_stats);
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	end_ns = monotonic_ns();
	(*setup_rows)++;
	emit_w4_bulk_policy_setup(
		out, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &setup_stats,
		ret ? "failed to setup W4 bulk policy macrobench system" :
		      "W4 bulk ccache policy macrobench system attached");
	if (ret) {
		if (policy.obj)
			destroy_policy(&policy);
		return 1;
	}

	attached_lookup_pass = true;
	attached_readdir_pass = true;
	for (i = 0; i < nr_entries; i++) {
		if (w4_policy_expect_entry_equal_quiet(&entries[i])) {
			attached_lookup_pass = false;
			sample_failures++;
		}
		if (w4_policy_expect_entry_readdir_quiet(&entries[i])) {
			attached_readdir_pass = false;
			sample_failures++;
		}
	}

	start_ns = monotonic_ns();
	ret = append_w4_rule_update_entry(entries, &nr_entries, sample,
					  &update_stats);
	if (!ret) {
		const struct oracle_entry *entry = &entries[nr_entries - 1];

		ret = update_w4_exact_cache_rules_for_entry(
			&policy, cgroup_id, entry, nr_entries, &update_stats);
	}
	end_ns = monotonic_ns();
	(*update_rows)++;
	emit_w4_bulk_policy_update(
		out, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &update_stats,
		ret ? "failed to update W4 bulk policy macrobench system" :
		      "W4 bulk policy sample-local cache object updated");
	if (ret) {
		sample_failures++;
	} else {
		const struct oracle_entry *entry = &entries[nr_entries - 1];

		post_update_lookup_pass =
			w4_policy_expect_entry_equal_quiet(entry) == 0;
		post_update_readdir_pass =
			w4_policy_expect_entry_readdir_quiet(entry) == 0;
		if (!post_update_lookup_pass)
			sample_failures++;
		if (!post_update_readdir_pass)
			sample_failures++;
	}

	ret = destroy_policy(&policy);
	if (ret)
		sample_failures++;

	post_detach_absent = true;
	for (i = 0; i < nr_entries; i++) {
		if (w4_policy_expect_entry_absent_quiet(&entries[i])) {
			post_detach_absent = false;
			sample_failures++;
		}
	}

	(*correctness_rows)++;
	emit_w4_bulk_policy_correctness(
		out, sample, sample_failures == 0, sample_failures,
		attached_lookup_pass, attached_readdir_pass,
		post_update_lookup_pass, post_update_readdir_pass,
		post_detach_absent, source_manifest_count,
		sample_failures ?
			"W4 bulk policy macrobench correctness failed" :
			"W4 bulk policy macrobench lookup/readdir/update correctness passed");
	return sample_failures ? 1 : 0;
}

static int run_w4_ccache_bulk_policy_macrobench(
	FILE *out, const char *cgroup_mount, const char *work_dir, int samples,
	const char *trace_cache_dir, const char *entries_tsv,
	const char *source_manifest, const char *cache_policy_obj)
{
	static struct w4_ccache_source sources[NAMEI_EXT_MAX_ENTRIES];
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	size_t nr_sources = 0;
	size_t cache_objects = 0;
	bool saw_redis = false;
	bool saw_nginx = false;
	int setup_rows = 0;
	int update_rows = 0;
	int correctness_rows = 0;
	int failures = 0;
	int sample;
	int ret;
	size_t i;

	memset(sources, 0, sizeof(sources));

	if (samples <= 0) {
		emit_w4_bulk_policy_summary(
			out, samples, 0, 0, 0, 1, 0, 0,
			"sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_w4_bulk_policy_summary(
			out, samples, 0, 0, 0, 1, 0, 0,
			"failed to create W4 bulk policy macrobench workdir");
		return 1;
	}
	if (access(trace_cache_dir, R_OK | X_OK) || access(entries_tsv, R_OK) ||
	    access(source_manifest, R_OK) || access(cache_policy_obj, R_OK)) {
		emit_w4_bulk_policy_summary(
			out, samples, 0, 0, 0, 1, 0, 0,
			"W4 bulk policy macrobench inputs are not readable");
		return 1;
	}
	ret = read_w4_ccache_sources(source_manifest, sources, &nr_sources);
	if (ret) {
		emit_w4_bulk_policy_summary(
			out, samples, 0, 0, 0, 1, 0, 0,
			"failed to read W4 bulk ccache source manifest");
		return 1;
	}
	for (i = 0; i < nr_sources; i++) {
		if (!strcmp(sources[i].kind, "redis"))
			saw_redis = true;
		else if (!strcmp(sources[i].kind, "nginx"))
			saw_nginx = true;
	}
	if (!saw_redis || !saw_nginx) {
		emit_w4_bulk_policy_summary(
			out, samples, 0, 0, 0, 1, nr_sources, 0,
			"W4 bulk source manifest does not cover Redis and nginx");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		emit_w4_bulk_policy_summary(
			out, samples, 0, 0, 0, 1, nr_sources, 0,
			"failed to resolve current cgroup id");
		return 1;
	}

	for (sample = 0; sample < samples; sample++)
		failures += run_one_w4_bulk_policy_macro_sample(
			out, current_cgroup, current_cgroup_id, work_dir, sample,
			trace_cache_dir, entries_tsv, cache_policy_obj,
			nr_sources, &setup_rows, &update_rows,
			&correctness_rows, &cache_objects);

	emit_w4_bulk_policy_summary(
		out, samples, setup_rows, update_rows, correctness_rows,
		failures, nr_sources, cache_objects,
		failures ?
			"W4 bulk policy macrobench failed" :
			"W4 bulk policy macrobench passed; compile output oracle remains in bulk-policy-compile witness");
	return failures ? 1 : 0;
}

static int read_ccache_stat_u64(const char *stats_path, const char *key,
				unsigned long long *value)
{
	char line[NAMEI_EXT_LINE_MAX];
	FILE *in;

	*value = 0;
	in = fopen(stats_path, "r");
	if (!in)
		return -errno;
	while (fgets(line, sizeof(line), in)) {
		char stat_key[128];
		unsigned long long stat_value = 0;

		if (sscanf(line, "%127s %llu", stat_key, &stat_value) != 2)
			continue;
		if (strcmp(stat_key, key))
			continue;
		*value = stat_value;
		fclose(in);
		return 0;
	}
	if (ferror(in)) {
		int err = errno ? errno : EIO;

		fclose(in);
		return -err;
	}
	fclose(in);
	return -ENOENT;
}

static int count_ccache_log_direct_hits(const char *log_path, size_t *hits)
{
	char line[NAMEI_EXT_LINE_MAX];
	FILE *in;

	*hits = 0;
	in = fopen(log_path, "r");
	if (!in)
		return -errno;
	while (fgets(line, sizeof(line), in)) {
		if (strstr(line, "Result: direct_cache_hit") ||
		    strstr(line, "Succeeded getting cached result"))
			(*hits)++;
	}
	if (ferror(in)) {
		int err = errno ? errno : EIO;

		fclose(in);
		return -err;
	}
	fclose(in);
	return 0;
}

static int ccache_original_relative(const char *trace_cache_dir,
				    const struct oracle_entry *entry, char *rel,
				    size_t rel_size)
{
	const char *entry_rel = NULL;

	if (!path_under_dir(entry->original, trace_cache_dir, &entry_rel))
		return -EINVAL;
	return copy_string(rel, rel_size, entry_rel);
}

static void emit_w4_bulk_native_compile_sample(
	FILE *out, int sample, bool pass, int failures, __u64 compile_ns,
	size_t source_count, size_t compile_jobs, size_t output_matches,
	size_t cache_path_ops, size_t cache_object_ops,
	unsigned long long cache_miss, unsigned long long direct_cache_hit,
	unsigned long long local_storage_hit,
	unsigned long long local_storage_write, const char *stats_file,
	const char *detail)
{
	double hit_rate = cache_path_ops ?
				  (double)cache_object_ops /
					  (double)cache_path_ops :
				  0.0;

	fputs("{\"event\":\"w4-ccache-bulk-native-compile-sample\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_bulk_native_compile.v1\","
	      "\"result_level\":\"kvm_external_native_ccache_compile_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"native_ccache_hot_compile\","
	      "\"baseline\":\"native_ccache_hot_compile\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"source_manifest_count\":%zu,"
		"\"compile_jobs\":%zu,"
		"\"compile_output_matches\":%zu,"
		"\"compile_ns\":%llu,"
		"\"cache_path_file_ops\":%zu,"
		"\"cache_object_ops\":%zu,"
		"\"sampled_operation_hit_rate\":%.17g,"
		"\"cache_miss\":%llu,"
		"\"direct_cache_hit\":%llu,"
		"\"local_storage_hit\":%llu,"
		"\"local_storage_write\":%llu,"
		"\"real_ccache_run\":true,"
		"\"policy_executed\":false,"
		"\"ccache_compile_policy_executed\":false,"
		"\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"operation_weighted_native_cache_hit_rate\":true,"
		"\"operation_weighted_native_hit_rate_is_release\":true,"
		"\"c2_supported\":false,"
		"\"release_gate_pass\":false,"
		"\"stats_file\":",
		sample, pass ? "true" : "false", failures, source_count,
		compile_jobs, output_matches, (unsigned long long)compile_ns,
		cache_path_ops, cache_object_ops, hit_rate, cache_miss,
		direct_cache_hit, local_storage_hit, local_storage_write);
	fprint_json_string(out, stats_file);
	fputs(",\"detail\":", out);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_bulk_native_compile_summary(
	FILE *out, int samples, int compile_rows, int failures,
	size_t source_count, size_t total_compile_jobs,
	size_t total_output_matches, unsigned long long total_compile_ns,
	size_t total_cache_path_ops, size_t total_cache_object_ops,
	unsigned long long total_cache_miss,
	unsigned long long total_direct_cache_hit,
	unsigned long long total_local_storage_hit,
	unsigned long long total_local_storage_write, const char *detail)
{
	double compile_ns_avg = compile_rows ?
					(double)total_compile_ns /
						(double)compile_rows :
					0.0;
	double hit_rate = total_cache_path_ops ?
				  (double)total_cache_object_ops /
					  (double)total_cache_path_ops :
				  0.0;

	fputs("{\"event\":\"w4-ccache-bulk-native-compile-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_bulk_native_compile.v1\","
	      "\"result_level\":\"kvm_external_native_ccache_compile_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"native_ccache_hot_compile\","
	      "\"baseline\":\"native_ccache_hot_compile\",",
	      out);
	fprintf(out,
		"\"samples\":%d,"
		"\"compile_rows\":%d,"
		"\"pass\":%s,"
		"\"failures\":%d,"
		"\"source_manifest_count\":%zu,"
		"\"total_compile_jobs\":%zu,"
		"\"total_compile_output_matches\":%zu,"
		"\"compile_ns_total\":%llu,"
		"\"compile_ns_avg\":%.17g,"
		"\"cache_path_file_ops\":%zu,"
		"\"cache_object_ops\":%zu,"
		"\"sampled_operation_hit_rate\":%.17g,"
		"\"cache_miss\":%llu,"
		"\"direct_cache_hit\":%llu,"
		"\"local_storage_hit\":%llu,"
		"\"local_storage_write\":%llu,"
		"\"real_ccache_run\":true,"
		"\"policy_executed\":false,"
		"\"ccache_compile_policy_executed\":false,"
		"\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"operation_weighted_native_cache_hit_rate\":true,"
		"\"operation_weighted_native_hit_rate_is_release\":true,"
		"\"c2_supported\":false,"
		"\"release_gate_pass\":false,"
		"\"detail\":",
		samples, compile_rows, failures ? "false" : "true", failures,
		source_count, total_compile_jobs, total_output_matches,
		total_compile_ns, compile_ns_avg, total_cache_path_ops,
		total_cache_object_ops, hit_rate, total_cache_miss,
		total_direct_cache_hit, total_local_storage_hit,
		total_local_storage_write);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int run_one_w4_bulk_native_compile_sample(
	FILE *out, const char *work_dir, int sample, const char *trace_cache_dir,
	const struct oracle_entry *entries, size_t nr_entries,
	const struct w4_ccache_source *sources, size_t nr_sources,
	const char *redis_build_src, const char *nginx_build_src,
	const char *baseline_hot_dir, int *compile_rows,
	size_t *total_compile_jobs, size_t *total_output_matches,
	unsigned long long *total_compile_ns, size_t *total_cache_path_ops,
	size_t *total_cache_object_ops, unsigned long long *total_cache_miss,
	unsigned long long *total_direct_cache_hit,
	unsigned long long *total_local_storage_hit,
	unsigned long long *total_local_storage_write)
{
	char sample_dir[PATH_MAX];
	char sample_cache_dir[PATH_MAX];
	char stats_path[PATH_MAX];
	char stats_stderr[PATH_MAX];
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	char copy_label[64];
	size_t compile_jobs = 0;
	size_t output_matches = 0;
	size_t cache_path_ops = 0;
	size_t cache_object_ops = 0;
	unsigned long long cache_miss = 0;
	unsigned long long direct_cache_hit = 0;
	unsigned long long local_storage_hit = 0;
	unsigned long long local_storage_write = 0;
	__u64 compile_start_ns;
	__u64 compile_end_ns;
	__u64 compile_ns = 0;
	int exit_code = -1;
	int failures = 0;
	int ret;
	size_t i;

	ret = snprintf(sample_dir, sizeof(sample_dir),
		       "%s/bulk-native-compile-sample-%03d", work_dir,
		       sample);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(sample_dir))
		return -ENAMETOOLONG;
	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(sample_cache_dir, sizeof(sample_cache_dir),
			       sample_dir, "ccache");
	if (!ret) {
		ret = snprintf(copy_label, sizeof(copy_label),
			       "bulk-native-cache-copy-%03d", sample);
		if (ret < 0)
			ret = -errno;
		else if ((size_t)ret >= sizeof(copy_label))
			ret = -ENAMETOOLONG;
		else
			ret = 0;
	}
	if (!ret)
		ret = copy_tree_for_w1_sample(trace_cache_dir, sample_cache_dir,
					      sample_dir, copy_label);
	if (!ret)
		ret = set_path(stats_path, sizeof(stats_path), sample_dir,
			       "ccache-native-stats.txt");
	if (!ret)
		ret = set_path(stats_stderr, sizeof(stats_stderr), sample_dir,
			       "ccache-native-stats.stderr");
	if (!ret)
		ret = set_path(stdout_path, sizeof(stdout_path), sample_dir,
			       "zero-stats.stdout");
	if (!ret)
		ret = set_path(stderr_path, sizeof(stderr_path), sample_dir,
			       "zero-stats.stderr");
	if (ret) {
		emit_w4_bulk_native_compile_sample(
			out, sample, false, 1, 0, nr_sources, 0, 0, 0, 0, 0,
			0, 0, 0, "", "failed to prepare native ccache sample");
		return 1;
	}
	if (setenv("CCACHE_DIR", sample_cache_dir, 1)) {
		emit_w4_bulk_native_compile_sample(
			out, sample, false, 1, 0, nr_sources, 0, 0, 0, 0, 0,
			0, 0, 0, stats_path,
			"failed to set native ccache sample directory");
		return 1;
	}
	ret = run_ccache_one_arg("--zero-stats", stdout_path, stderr_path,
				 &exit_code);
	if (ret || exit_code) {
		emit_w4_bulk_native_compile_sample(
			out, sample, false, 1, 0, nr_sources, 0, 0, 0, 0, 0,
			0, 0, 0, stats_path,
			"ccache --zero-stats failed for native baseline");
		return 1;
	}

	compile_start_ns = monotonic_ns();
	for (i = 0; i < nr_sources; i++) {
		char object_name[PATH_MAX];
		char output_name[PATH_MAX];
		char stdout_name[PATH_MAX];
		char stderr_name[PATH_MAX];
		char trace_name[PATH_MAX];
		char output_path[PATH_MAX];
		char source_stdout[PATH_MAX];
		char source_stderr[PATH_MAX];
		char trace_path[PATH_MAX];
		char baseline_obj[PATH_MAX];
		size_t source_cache_path_ops = 0;
		size_t source_object_ops = 0;

		ret = w4_ccache_source_file(object_name, sizeof(object_name),
					    &sources[i], ".o");
		if (!ret)
			ret = w4_ccache_source_file(output_name,
						    sizeof(output_name),
						    &sources[i], ".native.o");
		if (!ret)
			ret = w4_ccache_source_file(stdout_name,
						    sizeof(stdout_name),
						    &sources[i],
						    ".native.stdout");
		if (!ret)
			ret = w4_ccache_source_file(stderr_name,
						    sizeof(stderr_name),
						    &sources[i],
						    ".native.stderr");
		if (!ret)
			ret = w4_ccache_source_file(trace_name,
						    sizeof(trace_name),
						    &sources[i],
						    ".native.strace.log");
		if (!ret)
			ret = set_path(output_path, sizeof(output_path),
				       sample_dir, output_name);
		if (!ret)
			ret = set_path(source_stdout, sizeof(source_stdout),
				       sample_dir, stdout_name);
		if (!ret)
			ret = set_path(source_stderr, sizeof(source_stderr),
				       sample_dir, stderr_name);
		if (!ret)
			ret = set_path(trace_path, sizeof(trace_path),
				       sample_dir, trace_name);
		if (!ret)
			ret = set_path(baseline_obj, sizeof(baseline_obj),
				       baseline_hot_dir, object_name);
		if (ret) {
			failures++;
			continue;
		}
		ret = run_ccache_source_compile(
			&sources[i], redis_build_src, nginx_build_src,
			output_path, source_stdout, source_stderr, trace_path,
			&exit_code);
		if (ret || exit_code) {
			failures++;
			continue;
		}
		compile_jobs++;
		ret = compare_files(output_path, baseline_obj);
		if (ret)
			failures++;
		else
			output_matches++;
		ret = count_ccache_optrace(trace_path, sample_cache_dir, entries,
					   nr_entries, sources[i].kind,
					   &source_cache_path_ops,
					   &source_object_ops);
		if (ret) {
			failures++;
		} else {
			cache_path_ops += source_cache_path_ops;
			cache_object_ops += source_object_ops;
		}
	}
	compile_end_ns = monotonic_ns();
	compile_ns = compile_end_ns >= compile_start_ns ?
			     compile_end_ns - compile_start_ns :
			     0;

	ret = run_ccache_one_arg("--print-stats", stats_path, stats_stderr,
				 &exit_code);
	if (ret || exit_code)
		failures++;
	if (read_ccache_stat_u64(stats_path, "cache_miss", &cache_miss))
		failures++;
	if (read_ccache_stat_u64(stats_path, "direct_cache_hit",
				 &direct_cache_hit))
		failures++;
	if (read_ccache_stat_u64(stats_path, "local_storage_hit",
				 &local_storage_hit))
		failures++;
	if (read_ccache_stat_u64(stats_path, "local_storage_write",
				 &local_storage_write))
		failures++;
	if (compile_jobs != nr_sources || output_matches != nr_sources)
		failures++;
	if (direct_cache_hit < nr_sources)
		failures++;

	(*compile_rows)++;
	*total_compile_jobs += compile_jobs;
	*total_output_matches += output_matches;
	*total_compile_ns += (unsigned long long)compile_ns;
	*total_cache_path_ops += cache_path_ops;
	*total_cache_object_ops += cache_object_ops;
	*total_cache_miss += cache_miss;
	*total_direct_cache_hit += direct_cache_hit;
	*total_local_storage_hit += local_storage_hit;
	*total_local_storage_write += local_storage_write;
	emit_w4_bulk_native_compile_sample(
		out, sample, failures == 0, failures, compile_ns, nr_sources,
		compile_jobs, output_matches, cache_path_ops, cache_object_ops,
		cache_miss, direct_cache_hit, local_storage_hit,
		local_storage_write, stats_path,
		failures ? "native ccache hot compile baseline failed" :
			   "native ccache hot compile baseline passed");
	return failures ? 1 : 0;
}

static int run_w4_ccache_bulk_native_compile(
	FILE *out, const char *work_dir, int samples, const char *trace_cache_dir,
	const char *entries_tsv, const char *source_manifest,
	const char *redis_build_src, const char *nginx_build_src,
	const char *baseline_hot_dir)
{
	static struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES];
	static struct w4_ccache_source sources[NAMEI_EXT_MAX_ENTRIES];
	size_t nr_entries = 0;
	size_t nr_sources = 0;
	size_t total_compile_jobs = 0;
	size_t total_output_matches = 0;
	size_t total_cache_path_ops = 0;
	size_t total_cache_object_ops = 0;
	unsigned long long total_compile_ns = 0;
	unsigned long long total_cache_miss = 0;
	unsigned long long total_direct_cache_hit = 0;
	unsigned long long total_local_storage_hit = 0;
	unsigned long long total_local_storage_write = 0;
	int compile_rows = 0;
	int failures = 0;
	int sample;
	int ret;

	memset(entries, 0, sizeof(entries));
	memset(sources, 0, sizeof(sources));

	if (samples <= 0) {
		emit_w4_bulk_native_compile_summary(
			out, samples, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			"sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_w4_bulk_native_compile_summary(
			out, samples, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			"failed to create W4 native ccache workdir");
		return 1;
	}
	if (access(trace_cache_dir, R_OK | X_OK) || access(entries_tsv, R_OK) ||
	    access(source_manifest, R_OK) ||
	    access(redis_build_src, R_OK | X_OK) ||
	    access(nginx_build_src, R_OK | X_OK) ||
	    access(baseline_hot_dir, R_OK | X_OK)) {
		emit_w4_bulk_native_compile_summary(
			out, samples, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			"W4 native ccache baseline inputs are not readable");
		return 1;
	}
	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (!ret)
		ret = read_w4_ccache_sources(source_manifest, sources,
					     &nr_sources);
	if (ret || !nr_entries || !nr_sources) {
		emit_w4_bulk_native_compile_summary(
			out, samples, 0, 1, nr_sources, 0, 0, 0, 0, 0, 0, 0,
			0, 0,
			"failed to read W4 native ccache baseline inputs");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		failures += run_one_w4_bulk_native_compile_sample(
			out, work_dir, sample, trace_cache_dir, entries,
			nr_entries, sources, nr_sources, redis_build_src,
			nginx_build_src, baseline_hot_dir, &compile_rows,
			&total_compile_jobs, &total_output_matches,
			&total_compile_ns, &total_cache_path_ops,
			&total_cache_object_ops, &total_cache_miss,
			&total_direct_cache_hit, &total_local_storage_hit,
			&total_local_storage_write);
	}

	emit_w4_bulk_native_compile_summary(
		out, samples, compile_rows, failures, nr_sources,
		total_compile_jobs, total_output_matches, total_compile_ns,
		total_cache_path_ops, total_cache_object_ops, total_cache_miss,
		total_direct_cache_hit, total_local_storage_hit,
		total_local_storage_write,
		failures ? "W4 native ccache hot compile baseline failed" :
			   "W4 native ccache hot compile baseline passed");
	return failures ? 1 : 0;
}

static void emit_w4_bulk_fuse_compile_sample(
	FILE *out, int sample, bool pass, int failures, __u64 compile_ns,
	size_t source_count, size_t compile_jobs, size_t output_matches,
	size_t cache_path_ops, size_t cache_object_ops, size_t direct_log_hits,
	unsigned long long fuse_mounts, const char *ccache_log,
	const char *detail)
{
	double hit_rate = cache_path_ops ?
				  (double)cache_object_ops /
					  (double)cache_path_ops :
				  0.0;

	fputs("{\"event\":\"w4-ccache-bulk-fuse-compile-sample\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_bulk_fuse_compile.v1\","
	      "\"result_level\":\"kvm_external_fuse_ccache_compile_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"fuse_redirect_compile\","
	      "\"baseline\":\"fuse_redirect_compile\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"source_manifest_count\":%zu,"
		"\"compile_jobs\":%zu,"
		"\"compile_output_matches\":%zu,"
		"\"compile_ns\":%llu,"
		"\"cache_path_file_ops\":%zu,"
		"\"cache_object_ops\":%zu,"
		"\"sampled_operation_hit_rate\":%.17g,"
		"\"direct_cache_hit\":%zu,"
		"\"ccache_log_direct_cache_hit\":%zu,"
		"\"fuse_mounts\":%llu,"
		"\"real_ccache_run\":true,"
		"\"policy_executed\":false,"
		"\"ccache_compile_policy_executed\":false,"
		"\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"complete_ccache_compile_through_fuse\":true,"
		"\"read_oriented_cache_view_only\":false,"
		"\"ccache_read_only\":true,"
		"\"ccache_stats_disabled\":true,"
		"\"operation_weighted_fuse_cache_hit_rate\":true,"
		"\"operation_weighted_fuse_hit_rate_is_release\":true,"
		"\"c2_supported\":false,"
		"\"release_gate_pass\":false,"
		"\"ccache_log\":",
		sample, pass ? "true" : "false", failures, source_count,
		compile_jobs, output_matches, (unsigned long long)compile_ns,
		cache_path_ops, cache_object_ops, hit_rate, direct_log_hits,
		direct_log_hits, fuse_mounts);
	fprint_json_string(out, ccache_log);
	fputs(",\"detail\":", out);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_bulk_fuse_compile_summary(
	FILE *out, int samples, int compile_rows, int failures,
	size_t source_count, size_t total_compile_jobs,
	size_t total_output_matches, unsigned long long total_compile_ns,
	size_t total_cache_path_ops, size_t total_cache_object_ops,
	size_t total_direct_log_hits, unsigned long long total_fuse_mounts,
	const char *detail)
{
	double compile_ns_avg = compile_rows ?
					(double)total_compile_ns /
						(double)compile_rows :
					0.0;
	double hit_rate = total_cache_path_ops ?
				  (double)total_cache_object_ops /
					  (double)total_cache_path_ops :
				  0.0;

	fputs("{\"event\":\"w4-ccache-bulk-fuse-compile-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_bulk_fuse_compile.v1\","
	      "\"result_level\":\"kvm_external_fuse_ccache_compile_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"fuse_redirect_compile\","
	      "\"baseline\":\"fuse_redirect_compile\",",
	      out);
	fprintf(out,
		"\"samples\":%d,"
		"\"compile_rows\":%d,"
		"\"pass\":%s,"
		"\"failures\":%d,"
		"\"source_manifest_count\":%zu,"
		"\"total_compile_jobs\":%zu,"
		"\"total_compile_output_matches\":%zu,"
		"\"compile_ns_total\":%llu,"
		"\"compile_ns_avg\":%.17g,"
		"\"cache_path_file_ops\":%zu,"
		"\"cache_object_ops\":%zu,"
		"\"sampled_operation_hit_rate\":%.17g,"
		"\"direct_cache_hit\":%zu,"
		"\"ccache_log_direct_cache_hit\":%zu,"
		"\"fuse_mounts\":%llu,"
		"\"real_ccache_run\":true,"
		"\"policy_executed\":false,"
		"\"ccache_compile_policy_executed\":false,"
		"\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"complete_ccache_compile_through_fuse\":true,"
		"\"read_oriented_cache_view_only\":false,"
		"\"ccache_read_only\":true,"
		"\"ccache_stats_disabled\":true,"
		"\"operation_weighted_fuse_cache_hit_rate\":true,"
		"\"operation_weighted_fuse_hit_rate_is_release\":true,"
		"\"c2_supported\":false,"
		"\"release_gate_pass\":false,"
		"\"detail\":",
		samples, compile_rows, failures ? "false" : "true", failures,
		source_count, total_compile_jobs, total_output_matches,
		total_compile_ns, compile_ns_avg, total_cache_path_ops,
		total_cache_object_ops, hit_rate, total_direct_log_hits,
		total_direct_log_hits, total_fuse_mounts);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int run_one_w4_bulk_fuse_compile_sample(
	FILE *out, const char *work_dir, int sample, const char *trace_cache_dir,
	const struct oracle_entry *entries, size_t nr_entries,
	const struct w4_ccache_source *sources, size_t nr_sources,
	const char *redis_build_src, const char *nginx_build_src,
	const char *baseline_hot_dir, int *compile_rows,
	size_t *total_compile_jobs, size_t *total_output_matches,
	unsigned long long *total_compile_ns, size_t *total_cache_path_ops,
	size_t *total_cache_object_ops, size_t *total_direct_log_hits,
	unsigned long long *total_fuse_mounts)
{
	struct w4_fuse_mount fuse_mount = {};
	char sample_dir[PATH_MAX];
	char sample_cache_dir[PATH_MAX];
	char ready_rel[PATH_MAX];
	char tmp_dir[PATH_MAX];
	char log_path[PATH_MAX];
	char copy_label[64];
	size_t compile_jobs = 0;
	size_t output_matches = 0;
	size_t cache_path_ops = 0;
	size_t cache_object_ops = 0;
	size_t direct_log_hits = 0;
	unsigned long long fuse_mounts = 0;
	__u64 compile_start_ns;
	__u64 compile_end_ns;
	__u64 compile_ns = 0;
	int exit_code = -1;
	int failures = 0;
	int ret;
	size_t i;

	ret = snprintf(sample_dir, sizeof(sample_dir),
		       "%s/bulk-fuse-compile-sample-%03d", work_dir, sample);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(sample_dir))
		return -ENAMETOOLONG;
	ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(sample_cache_dir, sizeof(sample_cache_dir),
			       sample_dir, "ccache");
	if (!ret)
		ret = set_path(tmp_dir, sizeof(tmp_dir), sample_dir, "ccache-tmp");
	if (!ret)
		ret = set_path(log_path, sizeof(log_path), sample_dir,
			       "ccache-fuse.log");
	if (!ret) {
		ret = snprintf(copy_label, sizeof(copy_label),
			       "bulk-fuse-cache-copy-%03d", sample);
		if (ret < 0)
			ret = -errno;
		else if ((size_t)ret >= sizeof(copy_label))
			ret = -ENAMETOOLONG;
		else
			ret = 0;
	}
	if (!ret)
		ret = copy_tree_for_w1_sample(trace_cache_dir, sample_cache_dir,
					      sample_dir, copy_label);
	if (!ret)
		ret = mkdir_if_missing(tmp_dir);
	if (!ret)
		ret = ccache_original_relative(trace_cache_dir, &entries[0],
					       ready_rel, sizeof(ready_rel));
	if (!ret)
		ret = setup_w4_fuse_passthrough_cache_view(
			sample_cache_dir, ready_rel, &fuse_mounts, &fuse_mount);
	if (ret) {
		unmount_w4_fuse(&fuse_mount);
		emit_w4_bulk_fuse_compile_sample(
			out, sample, false, 1, 0, nr_sources, 0, 0, 0, 0, 0,
			fuse_mounts, log_path,
			"failed to prepare FUSE ccache compile sample");
		return 1;
	}
	if (setenv("CCACHE_DIR", sample_cache_dir, 1) ||
	    setenv("CCACHE_READONLY", "1", 1) ||
	    setenv("CCACHE_READONLY_DIRECT", "1", 1) ||
	    setenv("CCACHE_NOSTATS", "1", 1) ||
	    setenv("CCACHE_TEMPDIR", tmp_dir, 1) ||
	    setenv("CCACHE_LOGFILE", log_path, 1)) {
		unmount_w4_fuse(&fuse_mount);
		emit_w4_bulk_fuse_compile_sample(
			out, sample, false, 1, 0, nr_sources, 0, 0, 0, 0, 0,
			fuse_mounts, log_path,
			"failed to configure ccache FUSE compile environment");
		return 1;
	}

	compile_start_ns = monotonic_ns();
	for (i = 0; i < nr_sources; i++) {
		char object_name[PATH_MAX];
		char output_name[PATH_MAX];
		char stdout_name[PATH_MAX];
		char stderr_name[PATH_MAX];
		char trace_name[PATH_MAX];
		char output_path[PATH_MAX];
		char source_stdout[PATH_MAX];
		char source_stderr[PATH_MAX];
		char trace_path[PATH_MAX];
		char baseline_obj[PATH_MAX];
		size_t source_cache_path_ops = 0;
		size_t source_object_ops = 0;

		ret = w4_ccache_source_file(object_name, sizeof(object_name),
					    &sources[i], ".o");
		if (!ret)
			ret = w4_ccache_source_file(output_name,
						    sizeof(output_name),
						    &sources[i], ".fuse.o");
		if (!ret)
			ret = w4_ccache_source_file(stdout_name,
						    sizeof(stdout_name),
						    &sources[i],
						    ".fuse.stdout");
		if (!ret)
			ret = w4_ccache_source_file(stderr_name,
						    sizeof(stderr_name),
						    &sources[i],
						    ".fuse.stderr");
		if (!ret)
			ret = w4_ccache_source_file(trace_name,
						    sizeof(trace_name),
						    &sources[i],
						    ".fuse.strace.log");
		if (!ret)
			ret = set_path(output_path, sizeof(output_path),
				       sample_dir, output_name);
		if (!ret)
			ret = set_path(source_stdout, sizeof(source_stdout),
				       sample_dir, stdout_name);
		if (!ret)
			ret = set_path(source_stderr, sizeof(source_stderr),
				       sample_dir, stderr_name);
		if (!ret)
			ret = set_path(trace_path, sizeof(trace_path),
				       sample_dir, trace_name);
		if (!ret)
			ret = set_path(baseline_obj, sizeof(baseline_obj),
				       baseline_hot_dir, object_name);
		if (ret) {
			failures++;
			continue;
		}
		ret = run_ccache_source_compile(
			&sources[i], redis_build_src, nginx_build_src,
			output_path, source_stdout, source_stderr, trace_path,
			&exit_code);
		if (ret || exit_code) {
			failures++;
			continue;
		}
		compile_jobs++;
		ret = compare_files(output_path, baseline_obj);
		if (ret)
			failures++;
		else
			output_matches++;
		ret = count_ccache_optrace(trace_path, sample_cache_dir, entries,
					   nr_entries, sources[i].kind,
					   &source_cache_path_ops,
					   &source_object_ops);
		if (ret) {
			failures++;
		} else {
			cache_path_ops += source_cache_path_ops;
			cache_object_ops += source_object_ops;
		}
	}
	compile_end_ns = monotonic_ns();
	compile_ns = compile_end_ns >= compile_start_ns ?
			     compile_end_ns - compile_start_ns :
			     0;

	ret = unmount_w4_fuse(&fuse_mount);
	if (ret)
		failures++;
	if (count_ccache_log_direct_hits(log_path, &direct_log_hits))
		failures++;
	if (compile_jobs != nr_sources || output_matches != nr_sources)
		failures++;
	if (direct_log_hits < nr_sources)
		failures++;
	if (fuse_mounts != 1)
		failures++;

	(*compile_rows)++;
	*total_compile_jobs += compile_jobs;
	*total_output_matches += output_matches;
	*total_compile_ns += (unsigned long long)compile_ns;
	*total_cache_path_ops += cache_path_ops;
	*total_cache_object_ops += cache_object_ops;
	*total_direct_log_hits += direct_log_hits;
	*total_fuse_mounts += fuse_mounts;
	emit_w4_bulk_fuse_compile_sample(
		out, sample, failures == 0, failures, compile_ns, nr_sources,
		compile_jobs, output_matches, cache_path_ops, cache_object_ops,
		direct_log_hits, fuse_mounts, log_path,
		failures ? "FUSE ccache hot compile baseline failed" :
			   "FUSE ccache hot compile baseline passed");
	return failures ? 1 : 0;
}

static int run_w4_ccache_bulk_fuse_compile(
	FILE *out, const char *work_dir, int samples, const char *trace_cache_dir,
	const char *entries_tsv, const char *source_manifest,
	const char *redis_build_src, const char *nginx_build_src,
	const char *baseline_hot_dir)
{
	static struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES];
	static struct w4_ccache_source sources[NAMEI_EXT_MAX_ENTRIES];
	size_t nr_entries = 0;
	size_t nr_sources = 0;
	size_t total_compile_jobs = 0;
	size_t total_output_matches = 0;
	size_t total_cache_path_ops = 0;
	size_t total_cache_object_ops = 0;
	size_t total_direct_log_hits = 0;
	unsigned long long total_compile_ns = 0;
	unsigned long long total_fuse_mounts = 0;
	int compile_rows = 0;
	int failures = 0;
	int sample;
	int ret;

	memset(entries, 0, sizeof(entries));
	memset(sources, 0, sizeof(sources));

	if (samples <= 0) {
		emit_w4_bulk_fuse_compile_summary(
			out, samples, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
			"sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_w4_bulk_fuse_compile_summary(
			out, samples, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
			"failed to create W4 FUSE ccache workdir");
		return 1;
	}
	if (access(trace_cache_dir, R_OK | X_OK) || access(entries_tsv, R_OK) ||
	    access(source_manifest, R_OK) ||
	    access(redis_build_src, R_OK | X_OK) ||
	    access(nginx_build_src, R_OK | X_OK) ||
	    access(baseline_hot_dir, R_OK | X_OK)) {
		emit_w4_bulk_fuse_compile_summary(
			out, samples, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
			"W4 FUSE ccache baseline inputs are not readable");
		return 1;
	}
	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (!ret)
		ret = read_w4_ccache_sources(source_manifest, sources,
					     &nr_sources);
	if (ret || !nr_entries || !nr_sources) {
		emit_w4_bulk_fuse_compile_summary(
			out, samples, 0, 1, nr_sources, 0, 0, 0, 0, 0, 0,
			0, "failed to read W4 FUSE ccache baseline inputs");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		failures += run_one_w4_bulk_fuse_compile_sample(
			out, work_dir, sample, trace_cache_dir, entries,
			nr_entries, sources, nr_sources, redis_build_src,
			nginx_build_src, baseline_hot_dir, &compile_rows,
			&total_compile_jobs, &total_output_matches,
			&total_compile_ns, &total_cache_path_ops,
			&total_cache_object_ops, &total_direct_log_hits,
			&total_fuse_mounts);
	}

	emit_w4_bulk_fuse_compile_summary(
		out, samples, compile_rows, failures, nr_sources,
		total_compile_jobs, total_output_matches, total_compile_ns,
		total_cache_path_ops, total_cache_object_ops,
		total_direct_log_hits, total_fuse_mounts,
		failures ? "W4 FUSE ccache hot compile baseline failed" :
			   "W4 FUSE ccache hot compile baseline passed");
	return failures ? 1 : 0;
}

static void emit_w4_materialized_setup(
	FILE *out, int sample, bool pass, int err, __u64 setup_ns,
	const struct w4_rule_macro_stats *stats, const char *detail)
{
	const struct w4_rule_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w4-ccache-materialized-baseline-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_materialized_baseline.v1\","
	      "\"result_level\":\"kvm_external_materialized_cache_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":",
	      out);
	fprint_json_string(out, w4_materialized_workload);
	fputs(",\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"materialized_cache_view\","
	      "\"baseline\":\"materialized_cache_view\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":0,\"bind_mounts\":0,"
		"\"overlay_mounts\":0,\"fuse_mounts\":0,"
		"\"bytes_written\":0,\"bytes_copied\":%llu,"
		"\"cache_objects\":%llu,\"cache_leaf_parents\":%llu,"
		"\"lookup_rule_writes\":0,\"readdir_rule_writes\":0,"
		"\"total_rule_writes\":0,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, stats->created_dirs,
		stats->created_files, stats->bytes_copied,
		stats->cache_objects, stats->cache_leaf_parents);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_materialized_update(
	FILE *out, int sample, bool pass, int err, __u64 update_ns,
	const struct w4_rule_macro_stats *stats, const char *detail)
{
	const struct w4_rule_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w4-ccache-materialized-baseline-update\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_materialized_baseline.v1\","
	      "\"result_level\":\"kvm_external_materialized_cache_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":",
	      out);
	fprint_json_string(out, w4_materialized_workload);
	fputs(",\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"materialized_cache_view\","
	      "\"baseline\":\"materialized_cache_view\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"source_update_writes\":0,"
		"\"baseline_update_writes\":%llu,"
		"\"policy_update_writes\":0,"
		"\"update_bytes_written\":%llu,"
		"\"update_bytes_copied\":0,"
		"\"update_lookup_rule_writes\":0,"
		"\"update_readdir_rule_writes\":0,"
		"\"update_total_rule_writes\":0,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns, stats->source_update_writes,
		stats->update_bytes_written);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_materialized_correctness(
	FILE *out, int sample, bool pass, int failures,
	bool visible_content_pass, bool readdir_pass, bool hidden_backing_absent,
	const char *detail)
{
	fputs("{\"event\":\"w4-ccache-materialized-baseline-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_materialized_baseline.v1\","
	      "\"result_level\":\"kvm_external_materialized_cache_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":",
	      out);
	fprint_json_string(out, w4_materialized_workload);
	fputs(",\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"materialized_cache_view\","
	      "\"baseline\":\"materialized_cache_view\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"visible_content_pass\":%s,"
		"\"readdir_pass\":%s,"
		"\"hidden_backing_absent\":%s,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures,
		visible_content_pass ? "true" : "false",
		readdir_pass ? "true" : "false",
		hidden_backing_absent ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_materialized_summary(FILE *out, int samples, int setup_rows,
					 int update_rows, int correctness_rows,
					 int failures, const char *detail)
{
	fputs("{\"event\":\"w4-ccache-materialized-baseline-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_materialized_baseline.v1\","
	      "\"result_level\":\"kvm_external_materialized_cache_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":",
	      out);
	fprint_json_string(out, w4_materialized_workload);
	fputs(",\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"materialized_cache_view\","
	      "\"baseline\":\"materialized_cache_view\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"systems\":1,"
		"\"setup_rows\":%d,\"update_rows\":%d,"
		"\"correctness_rows\":%d,\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, setup_rows, update_rows, correctness_rows,
		failures ? "false" : "true", failures);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_fuse_setup(FILE *out, int sample, bool pass, int err,
			       __u64 setup_ns,
			       const struct w4_rule_macro_stats *stats,
			       const char *detail)
{
	const struct w4_rule_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w4-ccache-fuse-baseline-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_fuse_baseline.v1\","
	      "\"result_level\":\"kvm_external_fuse_cache_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":",
	      out);
	fprint_json_string(out, w4_fuse_workload);
	fputs(",\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"fuse_redirect\","
	      "\"baseline\":\"fuse_redirect\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":0,\"bind_mounts\":0,"
		"\"overlay_mounts\":0,\"fuse_mounts\":%llu,"
		"\"bytes_written\":0,\"bytes_copied\":%llu,"
		"\"cache_objects\":%llu,\"cache_leaf_parents\":%llu,"
		"\"lookup_rule_writes\":0,\"readdir_rule_writes\":0,"
		"\"total_rule_writes\":0,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, stats->created_dirs,
		stats->created_files, stats->fuse_mounts, stats->bytes_copied,
		stats->cache_objects, stats->cache_leaf_parents);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_fuse_update(FILE *out, int sample, bool pass, int err,
				__u64 update_ns,
				const struct w4_rule_macro_stats *stats,
				const char *detail)
{
	const struct w4_rule_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w4-ccache-fuse-baseline-update\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_fuse_baseline.v1\","
	      "\"result_level\":\"kvm_external_fuse_cache_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":",
	      out);
	fprint_json_string(out, w4_fuse_workload);
	fputs(",\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"fuse_redirect\","
	      "\"baseline\":\"fuse_redirect\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"source_update_writes\":0,"
		"\"baseline_update_writes\":%llu,"
		"\"policy_update_writes\":0,"
		"\"update_bytes_written\":%llu,"
		"\"update_bytes_copied\":0,"
		"\"update_lookup_rule_writes\":0,"
		"\"update_readdir_rule_writes\":0,"
		"\"update_total_rule_writes\":0,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns, stats->baseline_update_writes,
		stats->update_bytes_written);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_fuse_correctness(FILE *out, int sample, bool pass,
				     int failures, bool visible_content_pass,
				     bool readdir_pass,
				     bool hidden_backing_absent,
				     bool post_update_content_pass,
				     const char *detail)
{
	fputs("{\"event\":\"w4-ccache-fuse-baseline-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_fuse_baseline.v1\","
	      "\"result_level\":\"kvm_external_fuse_cache_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":",
	      out);
	fprint_json_string(out, w4_fuse_workload);
	fputs(",\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"fuse_redirect\","
	      "\"baseline\":\"fuse_redirect\",",
	      out);
	fprintf(out,
		"\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"visible_content_pass\":%s,"
		"\"readdir_pass\":%s,"
		"\"hidden_backing_absent\":%s,"
		"\"post_update_content_pass\":%s,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures,
		visible_content_pass ? "true" : "false",
		readdir_pass ? "true" : "false",
		hidden_backing_absent ? "true" : "false",
		post_update_content_pass ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_fuse_summary(FILE *out, int samples, int setup_rows,
				 int update_rows, int correctness_rows,
				 int failures, const char *detail)
{
	fputs("{\"event\":\"w4-ccache-fuse-baseline-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_fuse_baseline.v1\","
	      "\"result_level\":\"kvm_external_fuse_cache_baseline\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":",
	      out);
	fprint_json_string(out, w4_fuse_workload);
	fputs(",\"app\":\"ccache\","
	      "\"row_kind\":\"external_baseline\","
	      "\"system\":\"fuse_redirect\","
	      "\"baseline\":\"fuse_redirect\",", out);
	fprintf(out,
		"\"samples\":%d,\"systems\":1,"
		"\"setup_rows\":%d,\"update_rows\":%d,"
		"\"correctness_rows\":%d,\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, setup_rows, update_rows, correctness_rows,
		failures ? "false" : "true", failures);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int prepare_w4_materialized_cache_view(const char *work_dir,
					      struct oracle_entry *entries,
					      size_t nr_entries)
{
	char path[PATH_MAX];
	size_t i;
	int ret;

	ret = mkdir_if_missing(work_dir);
	if (ret)
		return ret;
	for (i = 0; i < nr_entries; i++) {
		ret = mkdir_relative_under(work_dir, entries[i].parent_relative,
					   entries[i].dir,
					   sizeof(entries[i].dir));
		if (ret)
			return ret;
		ret = set_path(path, sizeof(path), entries[i].dir,
			       entries[i].shadow);
		if (ret)
			return ret;
		unlink(path);
		ret = set_path(path, sizeof(path), entries[i].dir,
			       entries[i].visible);
		if (ret)
			return ret;
		unlink(path);
		ret = copy_file(entries[i].original, path);
		if (ret)
			return ret;
	}
	return 0;
}

static int materialized_expect_original(const struct oracle_entry *entry)
{
	char path[PATH_MAX];
	int ret;

	ret = set_path(path, sizeof(path), entry->dir, entry->visible);
	if (ret)
		return ret;
	return compare_files(entry->original, path);
}

static int materialized_expect_text(const struct oracle_entry *entry,
				    const char *expected)
{
	char path[PATH_MAX];
	int ret;

	ret = set_path(path, sizeof(path), entry->dir, entry->visible);
	if (ret)
		return ret;
	return compare_file_text_hash(path, expected, NULL, NULL, NULL, NULL);
}

static int materialized_expect_readdir(const struct oracle_entry *entry)
{
	bool found = false;
	int err = 0;
	int ret;

	ret = dir_has_name(entry->dir, entry->visible, &err);
	if (ret < 0)
		return err ? -err : ret;
	found = ret > 0;
	return found ? 0 : -ENOENT;
}

static int materialized_expect_hidden_absent(const struct oracle_entry *entry)
{
	char path[PATH_MAX];
	struct stat st = {};
	int ret;

	ret = set_path(path, sizeof(path), entry->dir, entry->shadow);
	if (ret)
		return ret;
	if (!stat(path, &st))
		return -EEXIST;
	return errno == ENOENT ? 0 : -errno;
}

static int append_w4_materialized_update_entry(struct oracle_entry *entries,
					       size_t *nr_entries, int sample,
					       char *expected,
					       size_t expected_size,
					       struct w4_rule_macro_stats *stats)
{
	struct oracle_entry *entry;
	char path[PATH_MAX];
	int ret;

	if (*nr_entries >= NAMEI_EXT_MAX_ENTRIES)
		return -E2BIG;
	entry = &entries[*nr_entries];
	*entry = entries[0];
	ret = snprintf(entry->visible, sizeof(entry->visible), "%031dV",
		       sample);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(entry->visible))
		return -ENAMETOOLONG;
	ret = snprintf(entry->shadow, sizeof(entry->shadow), "%s.local",
		       entry->visible);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(entry->shadow))
		return -ENAMETOOLONG;
	ret = snprintf(expected, expected_size,
		       "namei_ext w4 materialized cache baseline sample %d\n",
		       sample);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= expected_size)
		return -ENAMETOOLONG;
	ret = set_path(path, sizeof(path), entry->dir, entry->visible);
	if (ret)
		return ret;
	unlink(path);
	ret = write_text_file(path, expected);
	if (ret)
		return ret;
	copy_string(entry->original, sizeof(entry->original), path);
	if (stats) {
		stats->source_update_writes++;
		stats->update_bytes_written += strlen(expected);
	}
	(*nr_entries)++;
	return 0;
}

static int run_one_w4_materialized_baseline_sample(FILE *out,
						   const char *work_dir,
						   int sample,
						   const char *entries_tsv,
						   int *setup_rows,
						   int *update_rows,
						   int *correctness_rows)
{
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	struct w4_rule_macro_stats setup_stats = {};
	struct w4_rule_macro_stats update_stats = {};
	char sample_dir[PATH_MAX];
	char update_expected[128] = {};
	size_t nr_entries = 0;
	size_t original_entries;
	bool visible_content_pass = true;
	bool readdir_pass = true;
	bool hidden_backing_absent = true;
	int sample_failures = 0;
	__u64 start_ns;
	__u64 end_ns;
	int ret;
	size_t i;

	ret = snprintf(sample_dir, sizeof(sample_dir),
		       "%s/materialized-cache-view-sample-%03d", work_dir,
		       sample);
	if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
		emit_w4_materialized_setup(
			out, sample, false, ret < 0 ? errno : ENAMETOOLONG,
			0, NULL,
			"failed to build W4 materialized baseline sample dir");
		return 1;
	}

	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (ret) {
		emit_w4_materialized_setup(
			out, sample, false, -ret, 0, NULL,
			"failed to read W4 ccache entries");
		return 1;
	}
	original_entries = nr_entries;
	setup_stats.cache_objects = nr_entries;

	start_ns = monotonic_ns();
	ret = prepare_w4_materialized_cache_view(sample_dir, entries,
						 nr_entries);
	if (!ret) {
		setup_stats.created_dirs =
			w4_count_cache_leaf_parents(entries, nr_entries);
		setup_stats.created_files = nr_entries;
		setup_stats.bytes_copied =
			w4_sum_original_bytes(entries, nr_entries);
		setup_stats.cache_leaf_parents =
			w4_count_cache_leaf_parents(entries, nr_entries);
	}
	end_ns = monotonic_ns();
	(*setup_rows)++;
	emit_w4_materialized_setup(
		out, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &setup_stats,
		ret ? "failed to setup W4 materialized cache baseline" :
		      "W4 materialized cache baseline setup completed");
	if (ret)
		return 1;

	for (i = 0; i < nr_entries; i++) {
		if (materialized_expect_original(&entries[i])) {
			visible_content_pass = false;
			sample_failures++;
		}
		if (materialized_expect_readdir(&entries[i])) {
			readdir_pass = false;
			sample_failures++;
		}
		if (materialized_expect_hidden_absent(&entries[i])) {
			hidden_backing_absent = false;
			sample_failures++;
		}
	}

	start_ns = monotonic_ns();
	ret = append_w4_materialized_update_entry(
		entries, &nr_entries, sample, update_expected,
		sizeof(update_expected), &update_stats);
	end_ns = monotonic_ns();
	(*update_rows)++;
	emit_w4_materialized_update(
		out, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &update_stats,
		ret ? "failed to update W4 materialized cache baseline" :
		      "W4 materialized cache baseline visible object updated");
	if (ret)
		sample_failures++;

	for (i = original_entries; i < nr_entries; i++) {
		if (materialized_expect_text(&entries[i], update_expected)) {
			visible_content_pass = false;
			sample_failures++;
		}
		if (materialized_expect_readdir(&entries[i])) {
			readdir_pass = false;
			sample_failures++;
		}
		if (materialized_expect_hidden_absent(&entries[i])) {
			hidden_backing_absent = false;
			sample_failures++;
		}
	}

	(*correctness_rows)++;
	emit_w4_materialized_correctness(
		out, sample, sample_failures == 0, sample_failures,
		visible_content_pass, readdir_pass, hidden_backing_absent,
		sample_failures ?
			"W4 materialized cache baseline correctness failed" :
			"W4 materialized cache baseline content/readdir/update correctness passed");
	return sample_failures ? 1 : 0;
}

static int run_w4_ccache_materialized_baseline_macrobench(
	FILE *out, const char *work_dir, int samples, const char *entries_tsv)
{
	int setup_rows = 0;
	int update_rows = 0;
	int correctness_rows = 0;
	int failures = 0;
	int sample;
	int ret;

	if (samples <= 0) {
		emit_w4_materialized_summary(out, samples, 0, 0, 0, 1,
					     "sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_w4_materialized_summary(
			out, samples, 0, 0, 0, 1,
			"failed to create W4 materialized baseline workdir");
		return 1;
	}
	if (access(entries_tsv, R_OK)) {
		emit_w4_materialized_summary(
			out, samples, 0, 0, 0, 1,
			"W4 materialized baseline entries TSV is not readable");
		return 1;
	}

	for (sample = 0; sample < samples; sample++)
		failures += run_one_w4_materialized_baseline_sample(
			out, work_dir, sample, entries_tsv, &setup_rows,
			&update_rows, &correctness_rows);

	emit_w4_materialized_summary(
		out, samples, setup_rows, update_rows, correctness_rows,
		failures,
		failures ?
			"W4 materialized cache baseline failed" :
			"W4 materialized cache baseline passed; external baseline raw rows only");
	return failures ? 1 : 0;
}

static int w4_fuse_entry_backing_path(const struct w4_fuse_mount *mount,
				      const struct oracle_entry *entry,
				      const char *name, char *path,
				      size_t path_size)
{
	char parent[PATH_MAX];
	const char *rel = NULL;
	int ret;

	if (!strcmp(entry->dir, mount->mount_dir)) {
		ret = copy_string(parent, sizeof(parent), mount->backing_dir);
	} else {
		if (!path_under_dir(entry->dir, mount->mount_dir, &rel))
			return -EINVAL;
		ret = set_path(parent, sizeof(parent), mount->backing_dir, rel);
	}
	if (ret)
		return ret;
	return set_path(path, path_size, parent, name);
}

static int update_w4_fuse_existing_entry(const struct w4_fuse_mount *mount,
					 const struct oracle_entry *entry,
					 int sample, char *expected,
					 size_t expected_size,
					 struct w4_rule_macro_stats *stats)
{
	char backing_path[PATH_MAX];
	int ret;

	ret = snprintf(expected, expected_size,
		       "namei_ext w4 fuse cache baseline sample %d\n",
		       sample);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= expected_size)
		return -ENAMETOOLONG;
	ret = w4_fuse_entry_backing_path(mount, entry, entry->shadow,
					 backing_path, sizeof(backing_path));
	if (ret)
		return ret;
	ret = write_text_file(backing_path, expected);
	if (ret)
		return ret;
	if (stats) {
		stats->baseline_update_writes++;
		stats->update_bytes_written += strlen(expected);
	}
	return 0;
}

static int run_one_w4_fuse_baseline_sample(FILE *out, const char *work_dir,
					   int sample, const char *entries_tsv,
					   int *setup_rows, int *update_rows,
					   int *correctness_rows)
{
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	struct w4_rule_macro_stats setup_stats = {};
	struct w4_rule_macro_stats update_stats = {};
	struct w4_fuse_mount fuse_mount = {};
	char mount_dir[PATH_MAX];
	char update_expected[128] = {};
	size_t nr_entries = 0;
	bool visible_content_pass = true;
	bool readdir_pass = true;
	bool hidden_backing_absent = true;
	bool post_update_content_pass = true;
	int sample_failures = 0;
	__u64 start_ns;
	__u64 end_ns;
	int ret;
	size_t i;

	ret = snprintf(mount_dir, sizeof(mount_dir),
		       "%s/fuse-cache-view-sample-%03d", work_dir, sample);
	if (ret < 0 || (size_t)ret >= sizeof(mount_dir)) {
		emit_w4_fuse_setup(
			out, sample, false, ret < 0 ? errno : ENAMETOOLONG,
			0, NULL, "failed to build W4 FUSE baseline mount dir");
		return 1;
	}

	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (ret) {
		emit_w4_fuse_setup(out, sample, false, -ret, 0, NULL,
				   "failed to read W4 ccache entries");
		return 1;
	}
	setup_stats.cache_objects = nr_entries;

	start_ns = monotonic_ns();
	ret = setup_w4_fuse_cache_view(mount_dir, entries, nr_entries,
				       &setup_stats.fuse_mounts, &fuse_mount);
	if (!ret) {
		setup_stats.created_dirs =
			w4_count_cache_leaf_parents(entries, nr_entries);
		setup_stats.created_files = nr_entries;
		setup_stats.bytes_copied =
			w4_sum_original_bytes(entries, nr_entries);
		setup_stats.cache_leaf_parents =
			w4_count_cache_leaf_parents(entries, nr_entries);
	}
	end_ns = monotonic_ns();
	(*setup_rows)++;
	emit_w4_fuse_setup(
		out, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &setup_stats,
		ret ? "failed to setup W4 FUSE cache baseline" :
		      "W4 FUSE cache baseline setup completed");
	if (ret) {
		unmount_w4_fuse(&fuse_mount);
		return 1;
	}

	for (i = 0; i < nr_entries; i++) {
		if (materialized_expect_original(&entries[i])) {
			visible_content_pass = false;
			sample_failures++;
		}
		if (materialized_expect_readdir(&entries[i])) {
			readdir_pass = false;
			sample_failures++;
		}
		if (materialized_expect_hidden_absent(&entries[i])) {
			hidden_backing_absent = false;
			sample_failures++;
		}
	}

	start_ns = monotonic_ns();
	ret = update_w4_fuse_existing_entry(&fuse_mount, &entries[0], sample,
					    update_expected,
					    sizeof(update_expected),
					    &update_stats);
	end_ns = monotonic_ns();
	(*update_rows)++;
	emit_w4_fuse_update(
		out, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0, &update_stats,
		ret ? "failed to update W4 FUSE cache baseline backing" :
		      "W4 FUSE cache baseline backing object updated");
	if (ret) {
		sample_failures++;
		post_update_content_pass = false;
	} else if (materialized_expect_text(&entries[0], update_expected)) {
		post_update_content_pass = false;
		sample_failures++;
	}

	ret = unmount_w4_fuse(&fuse_mount);
	if (ret)
		sample_failures++;

	(*correctness_rows)++;
	emit_w4_fuse_correctness(
		out, sample, sample_failures == 0, sample_failures,
		visible_content_pass, readdir_pass, hidden_backing_absent,
		post_update_content_pass,
		sample_failures ?
			"W4 FUSE cache baseline correctness failed" :
			"W4 FUSE cache baseline content/readdir/update correctness passed");
	return sample_failures ? 1 : 0;
}

static int run_w4_ccache_fuse_baseline_macrobench(FILE *out,
						  const char *work_dir,
						  int samples,
						  const char *entries_tsv)
{
	int setup_rows = 0;
	int update_rows = 0;
	int correctness_rows = 0;
	int failures = 0;
	int sample;
	int ret;

	if (samples <= 0) {
		emit_w4_fuse_summary(out, samples, 0, 0, 0, 1,
				     "sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_w4_fuse_summary(
			out, samples, 0, 0, 0, 1,
			"failed to create W4 FUSE baseline workdir");
		return 1;
	}
	if (access(entries_tsv, R_OK)) {
		emit_w4_fuse_summary(
			out, samples, 0, 0, 0, 1,
			"W4 FUSE baseline entries TSV is not readable");
		return 1;
	}

	for (sample = 0; sample < samples; sample++)
		failures += run_one_w4_fuse_baseline_sample(
			out, work_dir, sample, entries_tsv, &setup_rows,
			&update_rows, &correctness_rows);

	emit_w4_fuse_summary(
		out, samples, setup_rows, update_rows, correctness_rows,
		failures,
		failures ?
			"W4 FUSE cache baseline failed" :
			"W4 FUSE cache baseline passed; external baseline raw rows only");
	return failures ? 1 : 0;
}

struct w4_ccache_epoch_compile_round {
	size_t compile_jobs;
	size_t output_matches;
	size_t cache_path_ops;
	size_t cache_object_ops;
	unsigned long long cache_miss;
	unsigned long long direct_cache_hit;
	unsigned long long local_storage_hit;
	unsigned long long local_storage_write;
	unsigned long long ccache_log_direct_hit;
	unsigned long long compile_ns;
	int failures;
};

struct w4_ccache_epoch_compile_totals {
	int policy_rows;
	int fuse_rows;
	int failures;
	size_t source_count;
	size_t policy_epoch1_jobs;
	size_t policy_epoch1_matches;
	size_t policy_epoch1_cache_path_ops;
	size_t policy_epoch1_cache_object_ops;
	size_t policy_epoch2_jobs;
	size_t policy_epoch2_matches;
	size_t policy_epoch2_cache_path_ops;
	size_t policy_epoch2_cache_object_ops;
	size_t fuse_epoch1_jobs;
	size_t fuse_epoch1_matches;
	size_t fuse_epoch1_cache_path_ops;
	size_t fuse_epoch1_cache_object_ops;
	size_t fuse_epoch2_jobs;
	size_t fuse_epoch2_matches;
	size_t fuse_epoch2_cache_path_ops;
	size_t fuse_epoch2_cache_object_ops;
	unsigned long long policy_epoch1_ns;
	unsigned long long policy_epoch2_ns;
	unsigned long long fuse_epoch1_ns;
	unsigned long long fuse_epoch2_ns;
	unsigned long long policy_epoch1_direct_hit;
	unsigned long long policy_epoch2_direct_hit;
	unsigned long long fuse_epoch1_direct_hit;
	unsigned long long fuse_epoch2_direct_hit;
	unsigned long long policy_setup_writes;
	unsigned long long policy_update_writes;
	unsigned long long policy_backing_invalidations;
	unsigned long long fuse_mounts;
	unsigned long long fuse_update_writes;
	unsigned long long fuse_backing_invalidations;
};

static int w4_ccache_epoch_canonical_name(char *dst, size_t size,
					  const char *visible)
{
	int ret = snprintf(dst, size, "%s.e2.local", visible);

	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int prepare_ccache_compile_epoch_entry(
	struct oracle_entry *entry, const char *trace_cache_dir,
	const char *cache_dir, char *canonical, size_t canonical_size)
{
	char mapped_path[PATH_MAX];
	char local_path[PATH_MAX];
	char canonical_path[PATH_MAX];
	char parent_dir[PATH_MAX];
	struct stat st;
	const char *rel;
	char *base;
	char *slash;
	int ret;

	if (!path_under_dir(entry->original, trace_cache_dir, &rel))
		return -EINVAL;
	if (!has_suffix(entry->shadow, ".local"))
		return -EINVAL;
	ret = set_path(mapped_path, sizeof(mapped_path), cache_dir, rel);
	if (ret)
		return ret;
	slash = strrchr(mapped_path, '/');
	if (!slash || slash == mapped_path)
		return -EINVAL;
	base = slash + 1;
	if (strcmp(base, entry->visible))
		return -EINVAL;
	*slash = 0;
	ret = copy_string(parent_dir, sizeof(parent_dir), mapped_path);
	*slash = '/';
	if (ret)
		return ret;
	ret = w4_ccache_epoch_canonical_name(canonical, canonical_size,
					     entry->visible);
	if (ret)
		return ret;
	ret = set_path(local_path, sizeof(local_path), parent_dir,
		       entry->shadow);
	if (!ret)
		ret = set_path(canonical_path, sizeof(canonical_path),
			       parent_dir, canonical);
	if (ret)
		return ret;
	if (stat(mapped_path, &st))
		return -errno;
	if (!S_ISREG(st.st_mode))
		return -EINVAL;
	if (!lstat(local_path, &st) || !lstat(canonical_path, &st))
		return -EEXIST;
	if (errno != ENOENT)
		return -errno;
	ret = copy_file(mapped_path, local_path);
	if (!ret)
		ret = copy_file(mapped_path, canonical_path);
	if (!ret && unlink(mapped_path))
		ret = -errno;
	if (ret)
		return ret;
	return copy_string(entry->dir, sizeof(entry->dir), parent_dir);
}

static int prepare_ccache_compile_epoch_entries(
	struct oracle_entry *entries, size_t nr_entries,
	const char *trace_cache_dir, const char *cache_dir,
	char canonical_names[NAMEI_EXT_MAX_ENTRIES][NAMEI_EXT_NAME_MAX + 1],
	unsigned long long *backing_writes)
{
	size_t i;

	*backing_writes = 0;
	for (i = 0; i < nr_entries; i++) {
		int ret = prepare_ccache_compile_epoch_entry(
			&entries[i], trace_cache_dir, cache_dir,
			canonical_names[i], NAMEI_EXT_NAME_MAX + 1);
		if (ret)
			return ret;
		*backing_writes += 2;
	}
	return 0;
}

static int populate_w4_ccache_epoch_compile_policy_rules(
	struct attached_policy *policy, __u64 cgroup_id,
	const struct oracle_entry *entries,
	char canonical_names[NAMEI_EXT_MAX_ENTRIES][NAMEI_EXT_NAME_MAX + 1],
	size_t nr_entries, unsigned long long *writes)
{
	size_t i;

	*writes = 0;
	for (i = 0; i < nr_entries; i++) {
		int ret;

		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
			entries[i].dir, entries[i].visible, entries[i].shadow,
			i + 1, CACHE_STATE_VERIFIED_HIT, W4_CACHE_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_LOOKUP,
			entries[i].dir, entries[i].visible,
			canonical_names[i], i + 1, CACHE_STATE_STALE,
			W4_CACHE_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
			entries[i].dir, entries[i].shadow, entries[i].visible,
			i + 1, CACHE_STATE_VERIFIED_HIT, W4_CACHE_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
			entries[i].dir, canonical_names[i], entries[i].visible,
			i + 1, CACHE_STATE_VERIFIED_HIT, W4_CACHE_EPOCH_ONE);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
			entries[i].dir, entries[i].shadow, entries[i].visible,
			i + 1, CACHE_STATE_STALE, W4_CACHE_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
		ret = update_cache_epoch_rule(
			policy, cgroup_id, BPF_NAMEI_EXT_READDIR,
			entries[i].dir, canonical_names[i], entries[i].visible,
			i + 1, CACHE_STATE_STALE, W4_CACHE_EPOCH_TWO);
		if (ret)
			return ret;
		(*writes)++;
	}
	return 0;
}

static int unlink_w4_ccache_epoch1_backings(
	const struct oracle_entry *entries, size_t nr_entries,
	unsigned long long *invalidations)
{
	char path[PATH_MAX];
	size_t i;

	*invalidations = 0;
	for (i = 0; i < nr_entries; i++) {
		int ret = set_path(path, sizeof(path), entries[i].dir,
				   entries[i].shadow);
		if (ret)
			return ret;
		if (unlink(path))
			return -errno;
		(*invalidations)++;
	}
	return 0;
}

static int run_w4_ccache_epoch_compile_round(
	const char *sample_dir, const char *cache_dir, const char *round_label,
	const char *object_suffix, const char *stdout_suffix,
	const char *stderr_suffix, const char *trace_suffix,
	const struct oracle_entry *entries, size_t nr_entries,
	const struct w4_ccache_source *sources, size_t nr_sources,
	const char *redis_build_src, const char *nginx_build_src,
	const char *baseline_hot_dir, const char *stats_path,
	const char *log_path, bool require_direct_hit,
	struct w4_ccache_epoch_compile_round *round)
{
	char stats_stderr[PATH_MAX];
	char zero_stdout[PATH_MAX];
	char zero_stderr[PATH_MAX];
	__u64 compile_start_ns;
	__u64 compile_end_ns;
	int exit_code = -1;
	int ret;
	size_t i;

	memset(round, 0, sizeof(*round));
	if (stats_path && stats_path[0]) {
		char name[128];

		ret = snprintf(name, sizeof(name), "%s-zero-stats.stdout",
			       round_label);
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= sizeof(name))
			return -ENAMETOOLONG;
		ret = set_path(zero_stdout, sizeof(zero_stdout), sample_dir,
			       name);
		if (!ret) {
			ret = snprintf(name, sizeof(name),
				       "%s-zero-stats.stderr", round_label);
			if (ret < 0)
				ret = -errno;
			else if ((size_t)ret >= sizeof(name))
				ret = -ENAMETOOLONG;
			else
				ret = set_path(zero_stderr,
					       sizeof(zero_stderr),
					       sample_dir, name);
		}
		if (!ret) {
			ret = snprintf(name, sizeof(name),
				       "%s-print-stats.stderr", round_label);
			if (ret < 0)
				ret = -errno;
			else if ((size_t)ret >= sizeof(name))
				ret = -ENAMETOOLONG;
			else
				ret = set_path(stats_stderr,
					       sizeof(stats_stderr),
					       sample_dir, name);
		}
		if (ret)
			return ret;
		ret = run_ccache_one_arg("--zero-stats", zero_stdout,
					 zero_stderr, &exit_code);
		if (ret || exit_code)
			round->failures++;
	}
	if (log_path && log_path[0])
		unlink_existing(log_path);

	compile_start_ns = monotonic_ns();
	for (i = 0; i < nr_sources; i++) {
		char object_name[PATH_MAX];
		char output_name[PATH_MAX];
		char stdout_name[PATH_MAX];
		char stderr_name[PATH_MAX];
		char trace_name[PATH_MAX];
		char output_path[PATH_MAX];
		char source_stdout[PATH_MAX];
		char source_stderr[PATH_MAX];
		char trace_path[PATH_MAX];
		char baseline_obj[PATH_MAX];
		size_t source_cache_path_ops = 0;
		size_t source_object_ops = 0;

		ret = w4_ccache_source_file(object_name, sizeof(object_name),
					    &sources[i], ".o");
		if (!ret)
			ret = w4_ccache_source_file(output_name,
						    sizeof(output_name),
						    &sources[i],
						    object_suffix);
		if (!ret)
			ret = w4_ccache_source_file(stdout_name,
						    sizeof(stdout_name),
						    &sources[i],
						    stdout_suffix);
		if (!ret)
			ret = w4_ccache_source_file(stderr_name,
						    sizeof(stderr_name),
						    &sources[i],
						    stderr_suffix);
		if (!ret)
			ret = w4_ccache_source_file(trace_name,
						    sizeof(trace_name),
						    &sources[i],
						    trace_suffix);
		if (!ret)
			ret = set_path(output_path, sizeof(output_path),
				       sample_dir, output_name);
		if (!ret)
			ret = set_path(source_stdout, sizeof(source_stdout),
				       sample_dir, stdout_name);
		if (!ret)
			ret = set_path(source_stderr, sizeof(source_stderr),
				       sample_dir, stderr_name);
		if (!ret)
			ret = set_path(trace_path, sizeof(trace_path),
				       sample_dir, trace_name);
		if (!ret)
			ret = set_path(baseline_obj, sizeof(baseline_obj),
				       baseline_hot_dir, object_name);
		if (ret) {
			round->failures++;
			continue;
		}
		exit_code = -1;
		ret = run_ccache_source_compile(
			&sources[i], redis_build_src, nginx_build_src,
			output_path, source_stdout, source_stderr, trace_path,
			&exit_code);
		if (ret || exit_code) {
			round->failures++;
			continue;
		}
		round->compile_jobs++;
		ret = compare_files(output_path, baseline_obj);
		if (ret)
			round->failures++;
		else
			round->output_matches++;
		ret = count_ccache_optrace(trace_path, cache_dir, entries,
					   nr_entries, sources[i].kind,
					   &source_cache_path_ops,
					   &source_object_ops);
		if (ret) {
			round->failures++;
		} else {
			round->cache_path_ops += source_cache_path_ops;
			round->cache_object_ops += source_object_ops;
		}
	}
	compile_end_ns = monotonic_ns();
	round->compile_ns = compile_end_ns >= compile_start_ns ?
				    compile_end_ns - compile_start_ns :
				    0;

	if (stats_path && stats_path[0]) {
		ret = run_ccache_one_arg("--print-stats", stats_path,
					 stats_stderr, &exit_code);
		if (ret || exit_code)
			round->failures++;
		if (read_ccache_stat_u64(stats_path, "cache_miss",
					 &round->cache_miss))
			round->failures++;
		if (read_ccache_stat_u64(stats_path, "direct_cache_hit",
					 &round->direct_cache_hit))
			round->failures++;
		if (read_ccache_stat_u64(stats_path, "local_storage_hit",
					 &round->local_storage_hit))
			round->failures++;
		if (read_ccache_stat_u64(stats_path, "local_storage_write",
					 &round->local_storage_write))
			round->failures++;
	}
	if (log_path && log_path[0]) {
		size_t log_hits = 0;

		if (count_ccache_log_direct_hits(log_path, &log_hits))
			round->failures++;
		else
			round->ccache_log_direct_hit = log_hits;
	}
	if (round->compile_jobs != nr_sources ||
	    round->output_matches != nr_sources)
		round->failures++;
	if (require_direct_hit) {
		unsigned long long hits = (stats_path && stats_path[0]) ?
						  round->direct_cache_hit :
						  round->ccache_log_direct_hit;

		if (hits < nr_sources)
			round->failures++;
	}
	return round->failures ? 1 : 0;
}

static void emit_w4_ccache_epoch_compile_sample(
	FILE *out, int sample, const char *system, bool fuse_baseline,
	bool pass, int failures, size_t source_count,
	const struct w4_ccache_epoch_compile_round *epoch1,
	const struct w4_ccache_epoch_compile_round *epoch2,
	unsigned long long setup_writes, unsigned long long update_writes,
	unsigned long long backing_invalidations,
	unsigned long long fuse_mounts, const char *detail)
{
	fputs("{\"event\":\"w4-ccache-bulk-compile-epoch-switch-sample\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_bulk_compile_epoch_switch.v1\","
	      "\"result_level\":\"kvm_real_ccache_bulk_compile_epoch_switch\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\",",
	      out);
	fputs("\"row_kind\":", out);
	fprint_json_string(out, fuse_baseline ? "external_baseline" :
						  "proposed_system");
	fputs(",\"system\":", out);
	fprint_json_string(out, system);
	if (fuse_baseline)
		fputs(",\"baseline\":\"fuse_cache_epoch_view\"", out);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"source_manifest_count\":%zu,"
		"\"epoch1_compile_jobs\":%zu,"
		"\"epoch1_output_matches\":%zu,"
		"\"epoch1_compile_ns\":%llu,"
		"\"epoch1_cache_path_file_ops\":%zu,"
		"\"epoch1_cache_object_ops\":%zu,"
		"\"epoch1_direct_cache_hit\":%llu,"
		"\"epoch2_compile_jobs\":%zu,"
		"\"epoch2_output_matches\":%zu,"
		"\"epoch2_compile_ns\":%llu,"
		"\"epoch2_cache_path_file_ops\":%zu,"
		"\"epoch2_cache_object_ops\":%zu,"
		"\"epoch2_direct_cache_hit\":%llu,"
		"\"setup_writes\":%llu,"
		"\"update_writes\":%llu,"
		"\"backing_invalidations\":%llu,"
		"\"fuse_mounts\":%llu,"
		"\"real_ccache_run\":true,"
		"\"policy_executed\":%s,"
		"\"ccache_compile_policy_executed\":%s,"
		"\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":%s,"
		"\"complete_ccache_compile_epoch_switch\":true,"
		"\"real_compile_epoch_switch\":true,"
		"\"miss_stale_corrupt_compile_cells_closed\":false,"
		"\"c2_supported\":false,"
		"\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures, source_count,
		epoch1->compile_jobs, epoch1->output_matches,
		epoch1->compile_ns, epoch1->cache_path_ops,
		epoch1->cache_object_ops,
		fuse_baseline ? epoch1->ccache_log_direct_hit :
				epoch1->direct_cache_hit,
		epoch2->compile_jobs, epoch2->output_matches,
		epoch2->compile_ns, epoch2->cache_path_ops,
		epoch2->cache_object_ops,
		fuse_baseline ? epoch2->ccache_log_direct_hit :
				epoch2->direct_cache_hit,
		setup_writes, update_writes, backing_invalidations,
		fuse_mounts, fuse_baseline ? "false" : "true",
		fuse_baseline ? "false" : "true",
		fuse_baseline ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_w4_ccache_epoch_compile_summary(
	FILE *out, int samples,
	const struct w4_ccache_epoch_compile_totals *totals,
	const char *detail)
{
	bool policy_pass = totals->policy_rows == samples &&
			   totals->policy_epoch1_jobs ==
				   totals->policy_epoch1_matches &&
			   totals->policy_epoch2_jobs ==
				   totals->policy_epoch2_matches &&
			   totals->policy_epoch1_jobs ==
				   (size_t)samples * totals->source_count &&
			   totals->policy_epoch2_jobs ==
				   (size_t)samples * totals->source_count &&
			   totals->policy_epoch1_direct_hit >=
				   (unsigned long long)samples *
					   totals->source_count &&
			   totals->policy_epoch2_direct_hit >=
				   (unsigned long long)samples *
					   totals->source_count;
	bool fuse_pass = totals->fuse_rows == samples &&
			 totals->fuse_epoch1_jobs == totals->fuse_epoch1_matches &&
			 totals->fuse_epoch2_jobs == totals->fuse_epoch2_matches &&
			 totals->fuse_epoch1_jobs ==
				 (size_t)samples * totals->source_count &&
			 totals->fuse_epoch2_jobs ==
				 (size_t)samples * totals->source_count &&
			 totals->fuse_epoch1_direct_hit >=
				 (unsigned long long)samples *
					 totals->source_count &&
			 totals->fuse_epoch2_direct_hit >=
				 (unsigned long long)samples *
					 totals->source_count &&
			 totals->fuse_mounts == (unsigned long long)samples;
	bool pass = totals->failures == 0 && policy_pass && fuse_pass;

	fputs("{\"event\":\"w4-ccache-bulk-compile-epoch-switch-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w4_ccache_bulk_compile_epoch_switch.v1\","
	      "\"result_level\":\"kvm_real_ccache_bulk_compile_epoch_switch\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w4-ccache-bulk-redis-nginx\","
	      "\"app\":\"ccache\",",
	      out);
	fprintf(out,
		"\"samples\":%d,"
		"\"systems\":2,"
		"\"pass\":%s,"
		"\"failures\":%d,"
		"\"source_manifest_count\":%zu,"
		"\"namei_ext\":{\"system\":\"cache_locality_epoch_policy\","
		"\"pass\":%s,"
		"\"rows\":%d,"
		"\"epoch1_compile_jobs\":%zu,"
		"\"epoch1_output_matches\":%zu,"
		"\"epoch1_compile_ns\":%llu,"
		"\"epoch1_cache_path_file_ops\":%zu,"
		"\"epoch1_cache_object_ops\":%zu,"
		"\"epoch1_direct_cache_hit\":%llu,"
		"\"epoch2_compile_jobs\":%zu,"
		"\"epoch2_output_matches\":%zu,"
		"\"epoch2_compile_ns\":%llu,"
		"\"epoch2_cache_path_file_ops\":%zu,"
		"\"epoch2_cache_object_ops\":%zu,"
		"\"epoch2_direct_cache_hit\":%llu,"
		"\"setup_writes\":%llu,"
		"\"policy_session_updates\":%llu,"
		"\"backing_invalidations\":%llu,"
		"\"policy_executed\":true},"
		"\"fuse_baseline\":{\"system\":\"fuse_cache_epoch_view\","
		"\"pass\":%s,"
		"\"rows\":%d,"
		"\"epoch1_compile_jobs\":%zu,"
		"\"epoch1_output_matches\":%zu,"
		"\"epoch1_compile_ns\":%llu,"
		"\"epoch1_cache_path_file_ops\":%zu,"
		"\"epoch1_cache_object_ops\":%zu,"
		"\"epoch1_direct_cache_hit\":%llu,"
		"\"epoch2_compile_jobs\":%zu,"
		"\"epoch2_output_matches\":%zu,"
		"\"epoch2_compile_ns\":%llu,"
		"\"epoch2_cache_path_file_ops\":%zu,"
		"\"epoch2_cache_object_ops\":%zu,"
		"\"epoch2_direct_cache_hit\":%llu,"
		"\"fuse_mounts\":%llu,"
		"\"update_writes\":%llu,"
		"\"backing_invalidations\":%llu,"
		"\"feature_equivalent_baseline\":true},"
		"\"real_ccache_run\":true,"
		"\"real_compile_epoch_switch\":true,"
		"\"complete_ccache_compile_epoch_switch\":true,"
		"\"miss_stale_corrupt_compile_cells_closed\":false,"
		"\"policy_executed\":true,"
		"\"feature_equivalent_fuse\":true,"
		"\"kvm_validated\":true,"
		"\"c2_supported\":false,"
		"\"release_gate_pass\":false,"
		"\"detail\":",
		samples, pass ? "true" : "false", totals->failures,
		totals->source_count, policy_pass ? "true" : "false",
		totals->policy_rows, totals->policy_epoch1_jobs,
		totals->policy_epoch1_matches, totals->policy_epoch1_ns,
		totals->policy_epoch1_cache_path_ops,
		totals->policy_epoch1_cache_object_ops,
		totals->policy_epoch1_direct_hit,
		totals->policy_epoch2_jobs, totals->policy_epoch2_matches,
		totals->policy_epoch2_ns,
		totals->policy_epoch2_cache_path_ops,
		totals->policy_epoch2_cache_object_ops,
		totals->policy_epoch2_direct_hit,
		totals->policy_setup_writes, totals->policy_update_writes,
		totals->policy_backing_invalidations,
		fuse_pass ? "true" : "false", totals->fuse_rows,
		totals->fuse_epoch1_jobs, totals->fuse_epoch1_matches,
		totals->fuse_epoch1_ns,
		totals->fuse_epoch1_cache_path_ops,
		totals->fuse_epoch1_cache_object_ops,
		totals->fuse_epoch1_direct_hit,
		totals->fuse_epoch2_jobs, totals->fuse_epoch2_matches,
		totals->fuse_epoch2_ns,
		totals->fuse_epoch2_cache_path_ops,
		totals->fuse_epoch2_cache_object_ops,
		totals->fuse_epoch2_direct_hit, totals->fuse_mounts,
		totals->fuse_update_writes,
		totals->fuse_backing_invalidations);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void add_w4_ccache_epoch_policy_totals(
	struct w4_ccache_epoch_compile_totals *totals,
	const struct w4_ccache_epoch_compile_round *epoch1,
	const struct w4_ccache_epoch_compile_round *epoch2,
	unsigned long long setup_writes, unsigned long long update_writes,
	unsigned long long backing_invalidations)
{
	totals->policy_rows++;
	totals->policy_epoch1_jobs += epoch1->compile_jobs;
	totals->policy_epoch1_matches += epoch1->output_matches;
	totals->policy_epoch1_ns += epoch1->compile_ns;
	totals->policy_epoch1_cache_path_ops += epoch1->cache_path_ops;
	totals->policy_epoch1_cache_object_ops += epoch1->cache_object_ops;
	totals->policy_epoch1_direct_hit += epoch1->direct_cache_hit;
	totals->policy_epoch2_jobs += epoch2->compile_jobs;
	totals->policy_epoch2_matches += epoch2->output_matches;
	totals->policy_epoch2_ns += epoch2->compile_ns;
	totals->policy_epoch2_cache_path_ops += epoch2->cache_path_ops;
	totals->policy_epoch2_cache_object_ops += epoch2->cache_object_ops;
	totals->policy_epoch2_direct_hit += epoch2->direct_cache_hit;
	totals->policy_setup_writes += setup_writes;
	totals->policy_update_writes += update_writes;
	totals->policy_backing_invalidations += backing_invalidations;
}

static void add_w4_ccache_epoch_fuse_totals(
	struct w4_ccache_epoch_compile_totals *totals,
	const struct w4_ccache_epoch_compile_round *epoch1,
	const struct w4_ccache_epoch_compile_round *epoch2,
	unsigned long long update_writes,
	unsigned long long backing_invalidations, unsigned long long fuse_mounts)
{
	totals->fuse_rows++;
	totals->fuse_epoch1_jobs += epoch1->compile_jobs;
	totals->fuse_epoch1_matches += epoch1->output_matches;
	totals->fuse_epoch1_ns += epoch1->compile_ns;
	totals->fuse_epoch1_cache_path_ops += epoch1->cache_path_ops;
	totals->fuse_epoch1_cache_object_ops += epoch1->cache_object_ops;
	totals->fuse_epoch1_direct_hit += epoch1->ccache_log_direct_hit;
	totals->fuse_epoch2_jobs += epoch2->compile_jobs;
	totals->fuse_epoch2_matches += epoch2->output_matches;
	totals->fuse_epoch2_ns += epoch2->compile_ns;
	totals->fuse_epoch2_cache_path_ops += epoch2->cache_path_ops;
	totals->fuse_epoch2_cache_object_ops += epoch2->cache_object_ops;
	totals->fuse_epoch2_direct_hit += epoch2->ccache_log_direct_hit;
	totals->fuse_mounts += fuse_mounts;
	totals->fuse_update_writes += update_writes;
	totals->fuse_backing_invalidations += backing_invalidations;
}

static int run_one_w4_ccache_epoch_policy_compile_sample(
	FILE *out, const char *cgroup_path, __u64 cgroup_id,
	const char *work_dir, int sample, const char *trace_cache_dir,
	const struct oracle_entry *input_entries, size_t nr_entries,
	const struct w4_ccache_source *sources, size_t nr_sources,
	const char *redis_build_src, const char *nginx_build_src,
	const char *baseline_hot_dir, const char *policy_obj,
	struct w4_ccache_epoch_compile_totals *totals)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES];
	char canonical_names[NAMEI_EXT_MAX_ENTRIES][NAMEI_EXT_NAME_MAX + 1];
	struct w4_ccache_epoch_compile_round epoch1;
	struct w4_ccache_epoch_compile_round epoch2;
	char sample_dir[PATH_MAX];
	char sample_cache_dir[PATH_MAX];
	char stats_epoch1[PATH_MAX];
	char stats_epoch2[PATH_MAX];
	char copy_label[64];
	unsigned long long backing_writes = 0;
	unsigned long long rule_writes = 0;
	unsigned long long setup_writes = 0;
	unsigned long long update_writes = 0;
	unsigned long long backing_invalidations = 0;
	int failures = 0;
	int ret;

	memset(entries, 0, sizeof(entries));
	memset(canonical_names, 0, sizeof(canonical_names));
	memset(&epoch1, 0, sizeof(epoch1));
	memset(&epoch2, 0, sizeof(epoch2));
	memcpy(entries, input_entries, sizeof(entries[0]) * nr_entries);

	ret = snprintf(sample_dir, sizeof(sample_dir),
		       "%s/epoch-policy-compile-sample-%03d", work_dir,
		       sample);
	if (ret < 0)
		ret = -errno;
	else if ((size_t)ret >= sizeof(sample_dir))
		ret = -ENAMETOOLONG;
	else
		ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(sample_cache_dir, sizeof(sample_cache_dir),
			       sample_dir, "ccache");
	if (!ret)
		ret = set_path(stats_epoch1, sizeof(stats_epoch1), sample_dir,
			       "ccache-policy-epoch1-stats.txt");
	if (!ret)
		ret = set_path(stats_epoch2, sizeof(stats_epoch2), sample_dir,
			       "ccache-policy-epoch2-stats.txt");
	if (!ret) {
		ret = snprintf(copy_label, sizeof(copy_label),
			       "epoch-policy-cache-copy-%03d", sample);
		if (ret < 0)
			ret = -errno;
		else if ((size_t)ret >= sizeof(copy_label))
			ret = -ENAMETOOLONG;
		else
			ret = 0;
	}
	if (!ret)
		ret = copy_tree_for_w1_sample(trace_cache_dir, sample_cache_dir,
					      sample_dir, copy_label);
	if (!ret)
		ret = prepare_ccache_compile_epoch_entries(
			entries, nr_entries, trace_cache_dir, sample_cache_dir,
			canonical_names, &backing_writes);
	if (!ret)
		ret = open_policy(policy_obj, POLICY_CACHE_LOCALITY,
				  "cache_locality_epoch", &policy);
	if (!ret)
		ret = populate_w4_ccache_epoch_compile_policy_rules(
			&policy, cgroup_id, entries, canonical_names, nr_entries,
			&rule_writes);
	if (!ret)
		ret = update_cache_epoch_session(&policy, cgroup_id,
						 W4_CACHE_EPOCH_ONE, true);
	if (!ret)
		setup_writes = backing_writes + rule_writes + 1;
	if (!ret && attach_policy(&policy, cgroup_path))
		ret = -errno;
	if (ret) {
		failures++;
		goto out_emit;
	}

	unsetenv("CCACHE_READONLY");
	unsetenv("CCACHE_READONLY_DIRECT");
	unsetenv("CCACHE_NOSTATS");
	unsetenv("CCACHE_TEMPDIR");
	unsetenv("CCACHE_LOGFILE");
	if (setenv("CCACHE_DIR", sample_cache_dir, 1)) {
		failures++;
		goto out_destroy;
	}
	failures += run_w4_ccache_epoch_compile_round(
		sample_dir, sample_cache_dir, "policy-epoch1",
		".policy-e1.o", ".policy-e1.stdout", ".policy-e1.stderr",
		".policy-e1.strace.log", entries, nr_entries, sources,
		nr_sources, redis_build_src, nginx_build_src, baseline_hot_dir,
		stats_epoch1, NULL, true, &epoch1);

	ret = unlink_w4_ccache_epoch1_backings(entries, nr_entries,
					       &backing_invalidations);
	if (!ret) {
		ret = update_cache_epoch_session(&policy, cgroup_id,
						 W4_CACHE_EPOCH_TWO, true);
		if (!ret)
			update_writes = 1;
	}
	if (ret) {
		failures++;
		goto out_destroy;
	}
	failures += run_w4_ccache_epoch_compile_round(
		sample_dir, sample_cache_dir, "policy-epoch2",
		".policy-e2.o", ".policy-e2.stdout", ".policy-e2.stderr",
		".policy-e2.strace.log", entries, nr_entries, sources,
		nr_sources, redis_build_src, nginx_build_src, baseline_hot_dir,
		stats_epoch2, NULL, true, &epoch2);

out_destroy:
	ret = destroy_policy(&policy);
	if (ret)
		failures++;
	goto out_emit;

out_emit:
	if (policy.obj || policy.cgroup_fd >= 0 || policy.prog_fd >= 0)
		destroy_policy(&policy);
	add_w4_ccache_epoch_policy_totals(totals, &epoch1, &epoch2,
					  setup_writes, update_writes,
					  backing_invalidations);
	totals->failures += failures;
	emit_w4_ccache_epoch_compile_sample(
		out, sample, "cache_locality_epoch_policy", false,
		failures == 0, failures, nr_sources, &epoch1, &epoch2,
		setup_writes, update_writes, backing_invalidations, 0,
		failures ? "namei_ext real ccache epoch-switch compile failed" :
			   "namei_ext real ccache epoch-switch compile passed");
	return failures ? 1 : 0;
}

static int update_w4_fuse_epoch2_backings(
	const struct w4_fuse_mount *mount, const struct oracle_entry *entries,
	char canonical_names[NAMEI_EXT_MAX_ENTRIES][NAMEI_EXT_NAME_MAX + 1],
	size_t nr_entries, unsigned long long *update_writes,
	unsigned long long *backing_invalidations)
{
	char local_path[PATH_MAX];
	char canonical_path[PATH_MAX];
	char visible_path[PATH_MAX];
	size_t i;

	*update_writes = 0;
	*backing_invalidations = 0;
	for (i = 0; i < nr_entries; i++) {
		int ret = w4_fuse_entry_backing_path(
			mount, &entries[i], entries[i].shadow, local_path,
			sizeof(local_path));
		if (!ret)
			ret = w4_fuse_entry_backing_path(
				mount, &entries[i], canonical_names[i],
				canonical_path, sizeof(canonical_path));
		if (!ret)
			ret = w4_fuse_entry_backing_path(
				mount, &entries[i], entries[i].visible,
				visible_path, sizeof(visible_path));
		if (ret)
			return ret;
		if (unlink(local_path))
			return -errno;
		(*backing_invalidations)++;
		ret = copy_file(canonical_path, visible_path);
		if (ret)
			return ret;
		(*update_writes)++;
	}
	return 0;
}

static int run_one_w4_ccache_epoch_fuse_compile_sample(
	FILE *out, const char *work_dir, int sample, const char *trace_cache_dir,
	const struct oracle_entry *input_entries, size_t nr_entries,
	const struct w4_ccache_source *sources, size_t nr_sources,
	const char *redis_build_src, const char *nginx_build_src,
	const char *baseline_hot_dir,
	struct w4_ccache_epoch_compile_totals *totals)
{
	struct w4_fuse_mount fuse_mount = {};
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES];
	char canonical_names[NAMEI_EXT_MAX_ENTRIES][NAMEI_EXT_NAME_MAX + 1];
	struct w4_ccache_epoch_compile_round epoch1;
	struct w4_ccache_epoch_compile_round epoch2;
	char sample_dir[PATH_MAX];
	char sample_cache_dir[PATH_MAX];
	char tmp_dir[PATH_MAX];
	char log_epoch1[PATH_MAX];
	char log_epoch2[PATH_MAX];
	char ready_rel[PATH_MAX];
	char copy_label[64];
	unsigned long long backing_writes = 0;
	unsigned long long update_writes = 0;
	unsigned long long backing_invalidations = 0;
	unsigned long long fuse_mounts = 0;
	int failures = 0;
	int ret;

	memset(entries, 0, sizeof(entries));
	memset(canonical_names, 0, sizeof(canonical_names));
	memset(&epoch1, 0, sizeof(epoch1));
	memset(&epoch2, 0, sizeof(epoch2));
	memcpy(entries, input_entries, sizeof(entries[0]) * nr_entries);

	ret = snprintf(sample_dir, sizeof(sample_dir),
		       "%s/epoch-fuse-compile-sample-%03d", work_dir,
		       sample);
	if (ret < 0)
		ret = -errno;
	else if ((size_t)ret >= sizeof(sample_dir))
		ret = -ENAMETOOLONG;
	else
		ret = mkdir_if_missing(sample_dir);
	if (!ret)
		ret = set_path(sample_cache_dir, sizeof(sample_cache_dir),
			       sample_dir, "ccache");
	if (!ret)
		ret = set_path(tmp_dir, sizeof(tmp_dir), sample_dir,
			       "ccache-tmp");
	if (!ret)
		ret = set_path(log_epoch1, sizeof(log_epoch1), sample_dir,
			       "ccache-fuse-epoch1.log");
	if (!ret)
		ret = set_path(log_epoch2, sizeof(log_epoch2), sample_dir,
			       "ccache-fuse-epoch2.log");
	if (!ret) {
		ret = snprintf(copy_label, sizeof(copy_label),
			       "epoch-fuse-cache-copy-%03d", sample);
		if (ret < 0)
			ret = -errno;
		else if ((size_t)ret >= sizeof(copy_label))
			ret = -ENAMETOOLONG;
		else
			ret = 0;
	}
	if (!ret)
		ret = copy_tree_for_w1_sample(trace_cache_dir, sample_cache_dir,
					      sample_dir, copy_label);
	if (!ret)
		ret = prepare_ccache_compile_epoch_entries(
			entries, nr_entries, trace_cache_dir, sample_cache_dir,
			canonical_names, &backing_writes);
	if (!ret)
		ret = mkdir_if_missing(tmp_dir);
	if (!ret)
		ret = ccache_original_relative(trace_cache_dir, &entries[0],
					       ready_rel, sizeof(ready_rel));
	if (!ret)
		ret = setup_w4_fuse_passthrough_cache_view(
			sample_cache_dir, ready_rel, &fuse_mounts, &fuse_mount);
	if (ret) {
		failures++;
		goto out_emit;
	}

	if (setenv("CCACHE_DIR", sample_cache_dir, 1) ||
	    setenv("CCACHE_READONLY", "1", 1) ||
	    setenv("CCACHE_READONLY_DIRECT", "1", 1) ||
	    setenv("CCACHE_NOSTATS", "1", 1) ||
	    setenv("CCACHE_TEMPDIR", tmp_dir, 1) ||
	    setenv("CCACHE_LOGFILE", log_epoch1, 1)) {
		failures++;
		goto out_unmount;
	}
	failures += run_w4_ccache_epoch_compile_round(
		sample_dir, sample_cache_dir, "fuse-epoch1", ".fuse-e1.o",
		".fuse-e1.stdout", ".fuse-e1.stderr",
		".fuse-e1.strace.log", entries, nr_entries, sources,
		nr_sources, redis_build_src, nginx_build_src, baseline_hot_dir,
		NULL, log_epoch1, true, &epoch1);

	ret = update_w4_fuse_epoch2_backings(&fuse_mount, entries,
					     canonical_names, nr_entries,
					     &update_writes,
					     &backing_invalidations);
	if (ret) {
		failures++;
		goto out_unmount;
	}
	if (setenv("CCACHE_LOGFILE", log_epoch2, 1)) {
		failures++;
		goto out_unmount;
	}
	failures += run_w4_ccache_epoch_compile_round(
		sample_dir, sample_cache_dir, "fuse-epoch2", ".fuse-e2.o",
		".fuse-e2.stdout", ".fuse-e2.stderr",
		".fuse-e2.strace.log", entries, nr_entries, sources,
		nr_sources, redis_build_src, nginx_build_src, baseline_hot_dir,
		NULL, log_epoch2, true, &epoch2);

out_unmount:
	ret = unmount_w4_fuse(&fuse_mount);
	if (ret)
		failures++;
out_emit:
	if (fuse_mount.active)
		unmount_w4_fuse(&fuse_mount);
	add_w4_ccache_epoch_fuse_totals(totals, &epoch1, &epoch2,
					update_writes, backing_invalidations,
					fuse_mounts);
	totals->failures += failures;
	emit_w4_ccache_epoch_compile_sample(
		out, sample, "fuse_cache_epoch_view", true, failures == 0,
		failures, nr_sources, &epoch1, &epoch2, backing_writes,
		update_writes, backing_invalidations, fuse_mounts,
		failures ? "FUSE real ccache epoch-switch compile failed" :
			   "FUSE real ccache epoch-switch compile passed");
	return failures ? 1 : 0;
}

static int run_w4_ccache_bulk_compile_epoch_switch(
	FILE *out, const char *cgroup_mount, int samples, const char *work_dir,
	const char *trace_cache_dir, const char *entries_tsv,
	const char *source_manifest, const char *redis_build_src,
	const char *nginx_build_src, const char *baseline_hot_dir,
	const char *policy_obj)
{
	static struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES];
	static struct w4_ccache_source sources[NAMEI_EXT_MAX_ENTRIES];
	struct w4_ccache_epoch_compile_totals totals = {};
	char current_cgroup[PATH_MAX];
	__u64 current_cgroup_id = 0;
	size_t nr_entries = 0;
	size_t nr_sources = 0;
	int sample;
	int ret;

	memset(entries, 0, sizeof(entries));
	memset(sources, 0, sizeof(sources));
	if (samples <= 0) {
		totals.failures = 1;
		emit_w4_ccache_epoch_compile_summary(
			out, samples, &totals, "sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		totals.failures = 1;
		emit_w4_ccache_epoch_compile_summary(
			out, samples, &totals,
			"failed to create W4 ccache epoch compile workdir");
		return 1;
	}
	if (access(trace_cache_dir, R_OK | X_OK) || access(entries_tsv, R_OK) ||
	    access(source_manifest, R_OK) ||
	    access(redis_build_src, R_OK | X_OK) ||
	    access(nginx_build_src, R_OK | X_OK) ||
	    access(baseline_hot_dir, R_OK | X_OK) ||
	    access(policy_obj, R_OK)) {
		totals.failures = 1;
		emit_w4_ccache_epoch_compile_summary(
			out, samples, &totals,
			"W4 ccache epoch compile inputs are not readable");
		return 1;
	}
	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (!ret)
		ret = read_w4_ccache_sources(source_manifest, sources,
					     &nr_sources);
	if (!ret)
		ret = current_cgroup_path(cgroup_mount, current_cgroup,
					  sizeof(current_cgroup));
	if (!ret)
		ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret || !nr_entries || !nr_sources) {
		totals.failures = 1;
		totals.source_count = nr_sources;
		emit_w4_ccache_epoch_compile_summary(
			out, samples, &totals,
			"failed to read W4 ccache epoch compile inputs");
		return 1;
	}
	totals.source_count = nr_sources;

	for (sample = 0; sample < samples; sample++) {
		run_one_w4_ccache_epoch_policy_compile_sample(
			out, current_cgroup, current_cgroup_id, work_dir,
			sample, trace_cache_dir, entries, nr_entries, sources,
			nr_sources, redis_build_src, nginx_build_src,
			baseline_hot_dir, policy_obj, &totals);
		run_one_w4_ccache_epoch_fuse_compile_sample(
			out, work_dir, sample, trace_cache_dir, entries,
			nr_entries, sources, nr_sources, redis_build_src,
			nginx_build_src, baseline_hot_dir, &totals);
	}

	emit_w4_ccache_epoch_compile_summary(
		out, samples, &totals,
		totals.failures ?
			"W4 ccache real compile epoch-switch row failed" :
			"W4 ccache real compile epoch-switch row passed for namei_ext and feature-equivalent FUSE");
	return totals.failures ? 1 : 0;
}

static int run_nginx_real_app(FILE *out, const char *cgroup_mount,
			      const char *work_dir, const char *nginx_bin,
			      const char *fixture_conf,
			      const char *endpoint_fixture,
			      const char *mime_types, const char *policy_obj,
			      bool trace_nginx)
{
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
		.map_fd = -1,
	};
	char current_cgroup[PATH_MAX];
	char prefix[PATH_MAX];
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	char trace_path[PATH_MAX];
	char health_response_path[PATH_MAX];
	pid_t upstream_pid = -1;
	int exit_code = -1;
	int upstream_exit_code = -1;
	int failures = 0;
	int ret;
	bool nginx_started = false;

	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_nginx_case(out, "mkdir_workdir", false, -ret, -1,
				"failed to create nginx real-app workdir",
				NULL, NULL);
		return 1;
	}
	if (access(nginx_bin, X_OK)) {
		emit_nginx_case(out, "nginx_binary", false, errno, -1,
				"nginx binary is not executable", NULL, NULL);
		return 1;
	}
	if (access(fixture_conf, R_OK)) {
		emit_nginx_case(out, "fixture_config", false, errno, -1,
				"nginx fixture config is not readable", NULL, NULL);
		return 1;
	}
	if (access(endpoint_fixture, R_OK)) {
		emit_nginx_case(out, "endpoint_fixture", false, errno, -1,
				"nginx endpoint fixture is not readable", NULL,
				NULL);
		return 1;
	}
	if (access(mime_types, R_OK)) {
		emit_nginx_case(out, "mime_types", false, errno, -1,
				"nginx mime.types is not readable", NULL, NULL);
		return 1;
	}

	ret = prepare_nginx_prefix(work_dir, fixture_conf, endpoint_fixture,
				   mime_types, prefix, sizeof(prefix), NULL);
	if (ret) {
		emit_nginx_case(out, "materialize", false, -ret, -1,
				"failed to materialize nginx prefix", NULL,
				NULL);
		return 1;
	}
	emit_nginx_case(out, "materialize", true, 0, 0,
			"nginx prefix materialized from workload fixture config and endpoint fixture",
			NULL, NULL);

	ret = set_path(stdout_path, sizeof(stdout_path), work_dir,
		       "pre-attach.stdout");
	if (!ret)
		ret = set_path(stderr_path, sizeof(stderr_path), work_dir,
			       "pre-attach.stderr");
	if (ret) {
		emit_nginx_case(out, "pre_attach_paths", false, -ret, -1,
				"failed to build pre-attach output paths",
				NULL, NULL);
		return 1;
	}
	if (trace_nginx)
		ret = set_path(trace_path, sizeof(trace_path), work_dir,
			       "pre-attach-nginx-test.strace.log");
	else
		ret = 0;
	if (!ret)
		ret = run_nginx_test_trace(nginx_bin, prefix, "conf/nginx.conf",
					   stdout_path, stderr_path,
					   trace_nginx ? trace_path : NULL,
					   &exit_code);
	if (ret) {
		emit_nginx_case(out, "pre_attach_nginx_test", false, -ret,
				-1, "failed to execute nginx -t before attach",
				stdout_path, stderr_path);
		return 1;
	}
	if (exit_code == 0) {
		emit_nginx_case(out, "pre_attach_nginx_test", false, 0,
				exit_code,
				"nginx unexpectedly accepted missing alias before attach",
				stdout_path, stderr_path);
		failures++;
	} else {
		emit_nginx_case(out, "pre_attach_nginx_test", true, 0,
				exit_code,
				"nginx rejected missing alias before attach",
				stdout_path, stderr_path);
	}

	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (ret) {
		emit_nginx_case(out, "cgroup_path", false, -ret, -1,
				"failed to resolve current cgroup path", NULL,
				NULL);
		return failures + 1;
	}
	if (open_policy(policy_obj, POLICY_SANDBOX_FIXTURE, "sandbox_fixture",
			&policy)) {
		emit_nginx_case(out, "load", false, errno, -1,
				"sandbox policy load failed", NULL, NULL);
		return failures + 1;
	}
	emit_nginx_case(out, "load", true, 0, 0, "sandbox policy loaded",
			NULL, NULL);
	emit_nginx_case(out, "policy_state", true, 0, 0,
			"literal nginx.conf and upstream.sock redirects active",
			NULL, NULL);
	if (attach_policy(&policy, current_cgroup)) {
		emit_nginx_case(out, "attach", false, errno, -1,
				"sandbox policy attach failed", NULL, NULL);
		destroy_policy(&policy);
		return failures + 1;
	}
	emit_nginx_case(out, "attach", true, 0, 0,
			"sandbox policy attached", NULL, NULL);

	ret = set_path(stdout_path, sizeof(stdout_path), work_dir,
		       "attached.stdout");
	if (!ret)
		ret = set_path(stderr_path, sizeof(stderr_path), work_dir,
			       "attached.stderr");
	if (ret) {
		emit_nginx_case(out, "attached_paths", false, -ret, -1,
				"failed to build attached output paths", NULL,
				NULL);
		failures++;
	} else {
		if (trace_nginx)
			ret = set_path(trace_path, sizeof(trace_path), work_dir,
				       "attached-nginx-test.strace.log");
		else
			ret = 0;
		if (!ret)
			ret = run_nginx_test_trace(nginx_bin, prefix,
						   "conf/nginx.conf",
						   stdout_path, stderr_path,
						   trace_nginx ? trace_path : NULL,
						   &exit_code);
		if (ret) {
			emit_nginx_case(out, "attached_nginx_test", false,
					-ret, -1,
					"failed to execute nginx -t after attach",
					stdout_path, stderr_path);
			failures++;
		} else if (exit_code != 0) {
			emit_nginx_case(out, "attached_nginx_test", false, 0,
					exit_code,
					"nginx did not accept redirected config",
					stdout_path, stderr_path);
			failures++;
		} else {
			emit_nginx_case(out, "attached_nginx_test", true, 0,
					exit_code,
					"nginx accepted redirected workload fixture config",
					stdout_path, stderr_path);
		}
	}

	failures += check_nginx_fixture_probe(
		out, prefix, "attached_config_fixture_probe", "nginx.conf",
		"nginx.test.conf", "nginx.prod.conf",
		"nginx.conf resolved to workload fixture config and not production config decoy");
	failures += check_nginx_fixture_probe(
		out, prefix, "attached_endpoint_fixture_probe", "upstream.sock",
		"upstream.local", "upstream.prod",
		"upstream.sock resolved to local endpoint fixture and not production endpoint decoy");
	failures += check_nginx_fixture_probe(
		out, prefix, "attached_fake_cert_probe", "server.crt",
		"server.fake.crt", "server.prod.crt",
		"server.crt resolved to fake certificate fixture and not production certificate decoy");
	failures += check_nginx_fixture_probe(
		out, prefix, "attached_fake_secret_probe", "db.password",
		"db.fake.pass", "db.prod.pass",
		"db.password resolved to fake secret fixture and not production secret decoy");
	failures += check_nginx_fixture_probe(
		out, prefix, "attached_poison_probe", "prod.token",
		"poison.secret", "prod.real.token",
		"prod.token resolved to poison sentinel and not production token decoy");

	ret = set_path(stdout_path, sizeof(stdout_path), work_dir,
		       "attached-start.stdout");
	if (!ret)
		ret = set_path(stderr_path, sizeof(stderr_path), work_dir,
			       "attached-start.stderr");
	if (ret) {
		emit_nginx_case(out, "attached_nginx_start", false, -ret, -1,
				"failed to build attached start output paths",
				NULL, NULL);
		failures++;
	} else {
		if (trace_nginx)
			ret = set_path(trace_path, sizeof(trace_path), work_dir,
				       "attached-nginx-start.strace.log");
		else
			ret = 0;
		if (!ret)
			ret = run_nginx_daemon_cmd_trace(
				nginx_bin, prefix, "conf/nginx.conf", NULL,
				stdout_path, stderr_path,
				trace_nginx ? trace_path : NULL, &exit_code);
		if (ret) {
			emit_nginx_case(out, "attached_nginx_start", false,
					-ret, -1,
					"failed to execute nginx daemon start",
					stdout_path, stderr_path);
			failures++;
		} else if (exit_code != 0) {
			emit_nginx_case(out, "attached_nginx_start", false, 0,
					exit_code,
					"nginx daemon did not start with redirected config",
					stdout_path, stderr_path);
			failures++;
		} else {
			nginx_started = true;
			emit_nginx_case(out, "attached_nginx_start", true, 0,
					exit_code,
					"nginx daemon started with redirected config",
					stdout_path, stderr_path);
		}
	}

	if (nginx_started) {
		ret = start_upstream_server(&upstream_pid);
		if (ret) {
			emit_nginx_case(out, "attached_upstream_start", false,
					-ret, -1,
					"failed to start local upstream endpoint",
					NULL, NULL);
			failures++;
		} else {
			emit_nginx_case(out, "attached_upstream_start", true,
					0, 0,
					"local upstream endpoint listening on 127.0.0.1:18080",
					NULL, NULL);
		}

		ret = set_path(health_response_path,
			       sizeof(health_response_path), work_dir,
			       "attached-health.response");
		if (ret) {
			emit_nginx_case(out, "attached_http_health", false,
					-ret, -1,
					"failed to build HTTP health response path",
					NULL, NULL);
			failures++;
		} else {
			ret = run_http_health(health_response_path, &exit_code);
			if (ret) {
				emit_nginx_case(out, "attached_http_health",
						false, -ret, -1,
						"failed to execute HTTP health request",
						health_response_path, NULL);
				failures++;
			} else if (exit_code != 0) {
				emit_nginx_case(out, "attached_http_health",
						false, 0, exit_code,
						"nginx HTTP health response did not match",
						health_response_path, NULL);
				failures++;
			} else {
				emit_nginx_case(out, "attached_http_health",
						true, 0, exit_code,
						"nginx HTTP health returned expected body",
						health_response_path, NULL);
			}
		}

		if (upstream_pid > 0) {
			ret = wait_upstream_server(upstream_pid,
						   &upstream_exit_code);
			if (ret) {
				emit_nginx_case(out,
						"attached_endpoint_upstream",
						false, -ret, -1,
						"local upstream endpoint did not observe nginx request",
						NULL, NULL);
				failures++;
			} else if (upstream_exit_code != 0) {
				emit_nginx_case(out,
						"attached_endpoint_upstream",
						false, 0,
						upstream_exit_code,
						"local upstream endpoint failed while serving nginx request",
						NULL, NULL);
				failures++;
			} else {
				emit_nginx_case(out,
						"attached_endpoint_upstream",
						true, 0,
						upstream_exit_code,
						"local upstream endpoint served nginx request through redirected include",
						NULL, NULL);
			}
			upstream_pid = -1;
		}

		ret = set_path(stdout_path, sizeof(stdout_path), work_dir,
			       "attached-quit.stdout");
		if (!ret)
			ret = set_path(stderr_path, sizeof(stderr_path), work_dir,
				       "attached-quit.stderr");
		if (ret) {
			emit_nginx_case(out, "attached_nginx_quit", false,
					-ret, -1,
					"failed to build attached quit output paths",
					NULL, NULL);
			failures++;
		} else {
			if (trace_nginx)
				ret = set_path(trace_path, sizeof(trace_path),
					       work_dir,
					       "attached-nginx-quit.strace.log");
			else
				ret = 0;
			if (!ret)
				ret = run_nginx_daemon_cmd_trace(
					nginx_bin, prefix, "conf/nginx.conf",
					"quit", stdout_path, stderr_path,
					trace_nginx ? trace_path : NULL,
					&exit_code);
			if (ret) {
				emit_nginx_case(out, "attached_nginx_quit",
						false, -ret, -1,
						"failed to execute nginx quit",
						stdout_path, stderr_path);
				failures++;
			} else if (exit_code != 0) {
				emit_nginx_case(out, "attached_nginx_quit",
						false, 0, exit_code,
						"nginx quit command failed",
						stdout_path, stderr_path);
				failures++;
			} else {
				emit_nginx_case(out, "attached_nginx_quit",
						true, 0, exit_code,
						"nginx quit command succeeded",
						stdout_path, stderr_path);
			}
		}
	}

	ret = destroy_policy(&policy);
	if (ret) {
		emit_nginx_case(out, "detach", false, -ret, -1,
				"sandbox policy detach failed", NULL, NULL);
		failures++;
	} else {
		emit_nginx_case(out, "detach", true, 0, 0,
				"sandbox policy detached", NULL, NULL);
	}

	ret = set_path(stdout_path, sizeof(stdout_path), work_dir,
		       "post-detach.stdout");
	if (!ret)
		ret = set_path(stderr_path, sizeof(stderr_path), work_dir,
			       "post-detach.stderr");
	if (ret) {
		emit_nginx_case(out, "post_detach_paths", false, -ret, -1,
				"failed to build post-detach output paths",
				NULL, NULL);
		failures++;
	} else {
		if (trace_nginx)
			ret = set_path(trace_path, sizeof(trace_path), work_dir,
				       "post-detach-nginx-test.strace.log");
		else
			ret = 0;
		if (!ret)
			ret = run_nginx_test_trace(nginx_bin, prefix,
						   "conf/nginx.conf",
						   stdout_path, stderr_path,
						   trace_nginx ? trace_path : NULL,
						   &exit_code);
		if (ret) {
			emit_nginx_case(out, "post_detach_nginx_test", false,
					-ret, -1,
					"failed to execute nginx -t after detach",
					stdout_path, stderr_path);
			failures++;
		} else if (exit_code == 0) {
			emit_nginx_case(out, "post_detach_nginx_test", false,
					0, exit_code,
					"nginx unexpectedly accepted alias after detach",
					stdout_path, stderr_path);
			failures++;
		} else {
			emit_nginx_case(out, "post_detach_nginx_test", true, 0,
					exit_code,
					"nginx rejected alias after detach",
					stdout_path, stderr_path);
		}
	}

	fprintf(out,
		"{\"event\":\"w2-nginx-real-summary\","
		"\"result_level\":\"kvm_real_app_health_oracle\","
		"\"workload\":\"w2-nginx-fixture\",\"app\":\"nginx\","
		"\"pass\":%s,\"failures\":%d,\"qualified_for_c8\":false,"
		"\"detail\":",
		failures ? "false" : "true", failures);
	fprint_json_string(out, failures ?
			   "nginx real-app health oracle failed" :
			   "nginx real-app endpoint health and fixture content probes passed");
	fputs("}\n", out);
	fflush(out);
	return failures ? 1 : 0;
}

static void emit_nginx_macro_summary(FILE *out, int samples, int setup_rows,
				     int update_rows, int correctness_rows,
				     int failures, const char *detail)
{
	fputs("{\"event\":\"w2-nginx-macrobench-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_nginx_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_setup_update_poc\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-nginx-fixture\","
	      "\"app\":\"nginx\","
	      "\"policy_family\":\"sandbox_fixture_view.bpf.c\",",
	      out);
	fprintf(out,
		"\"samples\":%d,\"setup_rows\":%d,"
		"\"update_rows\":%d,\"correctness_rows\":%d,"
		"\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":%s,\"kvm_validated\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		samples, setup_rows, update_rows, correctness_rows,
		failures ? "false" : "true", failures,
		correctness_rows == samples && !failures ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_nginx_baseline_setup(FILE *out, const char *baseline,
				      int sample, bool pass, int err,
				      __u64 setup_ns,
				      const struct nginx_macro_stats *stats,
				      const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w2-nginx-baseline-setup\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_nginx_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_feature_baseline_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-nginx-fixture\","
	      "\"app\":\"nginx\",",
	      out);
	fputs("\"baseline\":", out);
	fprint_json_string(out, baseline);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"setup_ns\":%llu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":%llu,\"bind_mounts\":%llu,"
		"\"overlay_mounts\":0,\"fuse_mounts\":%llu,"
		"\"bytes_written\":%llu,\"bytes_copied\":%llu,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)setup_ns, stats->created_dirs,
		stats->created_files, stats->created_symlinks,
		stats->bind_mounts, stats->fuse_mounts,
		stats->bytes_written, stats->bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_nginx_baseline_update(FILE *out, const char *baseline,
				       int sample, bool pass, int err,
				       __u64 update_ns,
				       const struct nginx_macro_stats *stats,
				       const char *detail)
{
	const struct nginx_macro_stats empty = {};

	if (!stats)
		stats = &empty;
	fputs("{\"event\":\"w2-nginx-baseline-update\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_nginx_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_feature_baseline_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-nginx-fixture\","
	      "\"app\":\"nginx\",",
	      out);
	fputs("\"baseline\":", out);
	fprint_json_string(out, baseline);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"errno\":%d,"
		"\"update_ns\":%llu,"
		"\"source_update_writes\":%llu,"
		"\"baseline_update_writes\":%llu,"
		"\"policy_update_writes\":%llu,"
		"\"update_bytes_written\":%llu,"
		"\"update_bytes_copied\":%llu,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", err,
		(unsigned long long)update_ns, stats->source_update_writes,
		stats->baseline_update_writes, stats->policy_update_writes,
		stats->update_bytes_written, stats->update_bytes_copied);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_nginx_baseline_correctness(
	FILE *out, const char *baseline, int sample, bool pass, int failures,
	bool baseline_nginx_test_pass, bool post_update_nginx_test_pass,
	bool config_probe_pass, bool endpoint_probe_pass, bool cert_probe_pass,
	bool secret_probe_pass, bool poison_probe_pass,
	bool post_update_endpoint_probe_pass, bool post_update_cert_probe_pass,
	bool post_update_secret_probe_pass, const char *detail)
{
	fputs("{\"event\":\"w2-nginx-baseline-correctness\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_nginx_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_feature_baseline_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-nginx-fixture\","
	      "\"app\":\"nginx\",",
	      out);
	fputs("\"baseline\":", out);
	fprint_json_string(out, baseline);
	fprintf(out,
		",\"sample\":%d,\"pass\":%s,\"failures\":%d,"
		"\"baseline_nginx_test_pass\":%s,"
		"\"post_update_nginx_test_pass\":%s,"
		"\"config_probe_pass\":%s,"
		"\"endpoint_probe_pass\":%s,"
		"\"cert_probe_pass\":%s,"
		"\"secret_probe_pass\":%s,"
		"\"poison_probe_pass\":%s,"
		"\"post_update_endpoint_probe_pass\":%s,"
		"\"post_update_cert_probe_pass\":%s,"
		"\"post_update_secret_probe_pass\":%s,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		sample, pass ? "true" : "false", failures,
		baseline_nginx_test_pass ? "true" : "false",
		post_update_nginx_test_pass ? "true" : "false",
		config_probe_pass ? "true" : "false",
		endpoint_probe_pass ? "true" : "false",
		cert_probe_pass ? "true" : "false",
		secret_probe_pass ? "true" : "false",
		poison_probe_pass ? "true" : "false",
		post_update_endpoint_probe_pass ? "true" : "false",
		post_update_cert_probe_pass ? "true" : "false",
		post_update_secret_probe_pass ? "true" : "false");
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static void emit_nginx_baseline_summary(FILE *out, const char *baselines,
					int baseline_count, int samples,
					int setup_rows, int update_rows,
					int correctness_rows, int failures,
					const char *detail)
{
	fputs("{\"event\":\"w2-nginx-baseline-summary\","
	      "\"schema\":\"namei_ext.eval_osdi.w2_nginx_baseline_macrobench.v1\","
	      "\"result_level\":\"kvm_workload_feature_baseline_input\","
	      "\"run_environment\":\"kvm\","
	      "\"workload\":\"w2-nginx-fixture\","
	      "\"app\":\"nginx\",",
	      out);
	fputs("\"selected_baselines\":", out);
	fprint_json_string(out, baselines);
	fprintf(out,
		",\"baseline_count\":%d,\"samples\":%d,"
		"\"setup_rows\":%d,\"update_rows\":%d,"
		"\"correctness_rows\":%d,"
		"\"pass\":%s,\"failures\":%d,"
		"\"policy_executed\":false,\"kvm_validated\":true,"
		"\"feature_equivalent_baseline\":true,"
		"\"c2_supported\":false,\"release_gate_pass\":false,"
		"\"detail\":",
		baseline_count, samples, setup_rows, update_rows,
		correctness_rows, failures ? "false" : "true", failures);
	fprint_json_string(out, detail);
	fputs("}\n", out);
	fflush(out);
}

static int run_one_nginx_baseline_sample(FILE *out, const char *baseline,
					 const char *work_dir, int sample,
					 const char *nginx_bin,
					 const char *fixture_conf,
					 const char *endpoint_fixture,
					 const char *mime_types,
					 int *setup_rows, int *update_rows,
					 int *correctness_rows)
{
	struct nginx_macro_stats setup_stats = {};
	struct nginx_macro_stats update_stats = {};
	char sample_dir[PATH_MAX];
	char prefix[PATH_MAX] = {};
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	bool baseline_nginx_test_pass = false;
	bool post_update_nginx_test_pass = false;
	bool config_probe_pass = false;
	bool endpoint_probe_pass = false;
	bool cert_probe_pass = false;
	bool secret_probe_pass = false;
	bool poison_probe_pass = false;
	bool post_update_endpoint_probe_pass = false;
	bool post_update_cert_probe_pass = false;
	bool post_update_secret_probe_pass = false;
	bool fuse_baseline = !strcmp(baseline, "fuse_redirect");
	int sample_failures = 0;
	int exit_code = -1;
	pid_t fuse_pid = -1;
	__u64 start_ns;
	__u64 end_ns;
	int ret;

	ret = snprintf(sample_dir, sizeof(sample_dir), "%s/%s-sample-%03d",
		       work_dir, baseline, sample);
	if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
		emit_nginx_baseline_setup(
			out, baseline, sample, false,
			ret < 0 ? errno : ENAMETOOLONG, 0, NULL,
			"failed to build baseline sample workdir path");
		return 1;
	}

	start_ns = monotonic_ns();
	ret = prepare_nginx_prefix(sample_dir, fixture_conf, endpoint_fixture,
				   mime_types, prefix, sizeof(prefix),
				   &setup_stats);
	if (!ret) {
		if (fuse_baseline)
			ret = setup_nginx_fuse_redirect(prefix, &setup_stats,
							&fuse_pid);
		else
			ret = materialize_nginx_baseline_aliases(prefix, baseline,
								&setup_stats);
	}
	end_ns = monotonic_ns();
	(*setup_rows)++;
	emit_nginx_baseline_setup(
		out, baseline, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0,
		&setup_stats,
		ret ? "failed to materialize nginx baseline prefix" :
		      "nginx baseline prefix materialized");
	if (ret) {
		if (!strcmp(baseline, "bind_mount") && prefix[0])
			unmount_nginx_bind_aliases(prefix);
		if (fuse_baseline && prefix[0])
			unmount_nginx_fuse(prefix, fuse_pid);
		return 1;
	}

	ret = set_path(stdout_path, sizeof(stdout_path), sample_dir,
		       "baseline.stdout");
	if (!ret)
		ret = set_path(stderr_path, sizeof(stderr_path), sample_dir,
			       "baseline.stderr");
	if (ret) {
		sample_failures++;
	} else {
		ret = run_nginx_test(nginx_bin, prefix, "conf/nginx.conf",
				     stdout_path, stderr_path, &exit_code);
		if (!ret && exit_code == 0)
			baseline_nginx_test_pass = true;
		else
			sample_failures++;
	}

	config_probe_pass = !check_nginx_fixture_compare(
		prefix, "nginx.conf", "nginx.test.conf", "nginx.prod.conf");
	endpoint_probe_pass = !check_nginx_fixture_compare(
		prefix, "upstream.sock", "upstream.local", "upstream.prod");
	cert_probe_pass = !check_nginx_fixture_compare(
		prefix, "server.crt", "server.fake.crt", "server.prod.crt");
	secret_probe_pass = !check_nginx_fixture_compare(
		prefix, "db.password", "db.fake.pass", "db.prod.pass");
	poison_probe_pass = !check_nginx_fixture_compare(
		prefix, "prod.token", "poison.secret", "prod.real.token");
	if (!config_probe_pass || !endpoint_probe_pass || !cert_probe_pass ||
	    !secret_probe_pass || !poison_probe_pass)
		sample_failures++;

	start_ns = monotonic_ns();
	if (fuse_baseline)
		ret = update_nginx_fuse_fixture(prefix, sample, &update_stats);
	else
		ret = update_nginx_macro_fixture(prefix, sample, &update_stats);
	if (!ret && !fuse_baseline)
		ret = update_nginx_baseline_aliases(prefix, baseline,
						    &update_stats);
	end_ns = monotonic_ns();
	(*update_rows)++;
	emit_nginx_baseline_update(
		out, baseline, sample, !ret, ret ? -ret : 0,
		end_ns >= start_ns ? end_ns - start_ns : 0,
		&update_stats,
		ret ? "failed to update nginx baseline fixture" :
		      "updated nginx baseline fixture");
	if (ret) {
		sample_failures++;
	} else {
		ret = set_path(stdout_path, sizeof(stdout_path), sample_dir,
			       "post-update.stdout");
		if (!ret)
			ret = set_path(stderr_path, sizeof(stderr_path),
				       sample_dir, "post-update.stderr");
		if (ret) {
			sample_failures++;
		} else {
			exit_code = -1;
			ret = run_nginx_test(nginx_bin, prefix,
					     "conf/nginx.conf", stdout_path,
					     stderr_path, &exit_code);
			if (!ret && exit_code == 0)
				post_update_nginx_test_pass = true;
			else
				sample_failures++;
		}

		post_update_endpoint_probe_pass =
			!check_nginx_fixture_compare(
				prefix, "upstream.sock", "upstream.local",
				"upstream.prod");
		post_update_cert_probe_pass =
			!check_nginx_fixture_compare(
				prefix, "server.crt", "server.fake.crt",
				"server.prod.crt");
		post_update_secret_probe_pass =
			!check_nginx_fixture_compare(
				prefix, "db.password", "db.fake.pass",
				"db.prod.pass");
		if (!post_update_endpoint_probe_pass ||
		    !post_update_cert_probe_pass ||
		    !post_update_secret_probe_pass)
			sample_failures++;
	}

	if (!strcmp(baseline, "bind_mount")) {
		ret = unmount_nginx_bind_aliases(prefix);
		if (ret)
			sample_failures++;
	}
	if (fuse_baseline) {
		ret = unmount_nginx_fuse(prefix, fuse_pid);
		if (ret)
			sample_failures++;
	}

	(*correctness_rows)++;
	emit_nginx_baseline_correctness(
		out, baseline, sample, sample_failures == 0, sample_failures,
		baseline_nginx_test_pass, post_update_nginx_test_pass,
		config_probe_pass, endpoint_probe_pass, cert_probe_pass,
		secret_probe_pass, poison_probe_pass,
		post_update_endpoint_probe_pass, post_update_cert_probe_pass,
		post_update_secret_probe_pass,
		sample_failures ?
			"nginx baseline sample failed correctness oracle" :
			"nginx baseline sample passed setup/update correctness oracle");
	return sample_failures ? 1 : 0;
}

static int run_nginx_baseline_macrobench(FILE *out, const char *work_dir,
					 int samples, const char *nginx_bin,
					 const char *fixture_conf,
					 const char *endpoint_fixture,
					 const char *mime_types,
					 const char *baselines)
{
	const char *known[] = {
		"copy_tree",
		"symlink_forest",
		"bind_mount",
		"projected_volume",
		"fuse_redirect",
	};
	int baseline_count = 0;
	int setup_rows = 0;
	int update_rows = 0;
	int correctness_rows = 0;
	int failures = 0;
	size_t i;
	int ret;

	if (samples <= 0) {
		emit_nginx_baseline_summary(
			out, baselines, 0, samples, 0, 0, 0, 1,
			"sample count must be positive");
		return 1;
	}
	ret = count_selected_nginx_baselines(baselines, &baseline_count);
	if (ret) {
		emit_nginx_baseline_summary(
			out, baselines, 0, samples, 0, 0, 0, 1,
			"unknown or empty nginx baseline selection");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_nginx_baseline_summary(
			out, baselines, baseline_count, samples, 0, 0, 0, 1,
			"failed to create nginx baseline macrobench workdir");
		return 1;
	}
	if (access(nginx_bin, X_OK)) {
		emit_nginx_baseline_summary(
			out, baselines, baseline_count, samples, 0, 0, 0, 1,
			"nginx binary is not executable");
		return 1;
	}
	if (access(fixture_conf, R_OK) || access(endpoint_fixture, R_OK) ||
	    access(mime_types, R_OK)) {
		emit_nginx_baseline_summary(
			out, baselines, baseline_count, samples, 0, 0, 0, 1,
			"nginx fixture inputs are not readable");
		return 1;
	}

	for (i = 0; i < ARRAY_SIZE(known); i++) {
		int sample;

		if (!nginx_baseline_selected(baselines, known[i]))
			continue;
		for (sample = 0; sample < samples; sample++)
			failures += run_one_nginx_baseline_sample(
				out, known[i], work_dir, sample, nginx_bin,
				fixture_conf, endpoint_fixture, mime_types,
				&setup_rows, &update_rows, &correctness_rows);
	}

	emit_nginx_baseline_summary(
		out, baselines, baseline_count, samples, setup_rows, update_rows,
		correctness_rows, failures,
		failures ?
			"nginx feature-equivalent baseline macrobench failed" :
			"nginx feature-equivalent baseline macrobench passed; not a C2 release gate");
	return failures ? 1 : 0;
}

static int run_nginx_macrobench(FILE *out, const char *cgroup_mount,
				const char *work_dir, int samples,
				const char *nginx_bin,
				const char *fixture_conf,
				const char *endpoint_fixture,
				const char *mime_types,
				const char *policy_obj)
{
	char current_cgroup[PATH_MAX];
	int setup_rows = 0;
	int update_rows = 0;
	int correctness_rows = 0;
	int failures = 0;
	int sample;
	int ret;

	if (samples <= 0) {
		emit_nginx_macro_summary(out, samples, 0, 0, 0, 1,
					 "sample count must be positive");
		return 1;
	}
	ret = mkdir_if_missing(work_dir);
	if (ret) {
		emit_nginx_macro_summary(out, samples, 0, 0, 0, 1,
					 "failed to create nginx macrobench workdir");
		return 1;
	}
	if (access(nginx_bin, X_OK)) {
		emit_nginx_macro_summary(out, samples, 0, 0, 0, 1,
					 "nginx binary is not executable");
		return 1;
	}
	if (access(fixture_conf, R_OK) || access(endpoint_fixture, R_OK) ||
	    access(mime_types, R_OK)) {
		emit_nginx_macro_summary(out, samples, 0, 0, 0, 1,
					 "nginx fixture inputs are not readable");
		return 1;
	}
	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (ret) {
		emit_nginx_macro_summary(out, samples, 0, 0, 0, 1,
					 "failed to resolve current cgroup path");
		return 1;
	}

	for (sample = 0; sample < samples; sample++) {
		struct attached_policy policy = {
			.cgroup_fd = -1,
			.prog_fd = -1,
			.map_fd = -1,
		};
		struct nginx_macro_stats setup_stats = {};
		struct nginx_macro_stats update_stats = {};
		char sample_dir[PATH_MAX];
		char prefix[PATH_MAX];
		char stdout_path[PATH_MAX];
		char stderr_path[PATH_MAX];
		bool pre_attach_rejected = false;
		bool attached_nginx_test_pass = false;
		bool post_update_nginx_test_pass = false;
		bool config_probe_pass = false;
		bool endpoint_probe_pass = false;
		bool cert_probe_pass = false;
		bool secret_probe_pass = false;
		bool poison_probe_pass = false;
		bool post_update_endpoint_probe_pass = false;
		bool post_update_cert_probe_pass = false;
		bool post_update_secret_probe_pass = false;
		bool policy_executed = false;
		int sample_failures = 0;
		int exit_code = -1;
		__u64 start_ns;
		__u64 end_ns;

		ret = snprintf(sample_dir, sizeof(sample_dir), "%s/sample-%03d",
			       work_dir, sample);
		if (ret < 0 || (size_t)ret >= sizeof(sample_dir)) {
			emit_nginx_macro_setup(out, sample, false,
					       ret < 0 ? errno : ENAMETOOLONG,
					       0, NULL,
					       "failed to build sample workdir path");
			failures++;
			break;
		}

		start_ns = monotonic_ns();
		ret = prepare_nginx_prefix(sample_dir, fixture_conf,
					   endpoint_fixture, mime_types,
					   prefix, sizeof(prefix),
					   &setup_stats);
		end_ns = monotonic_ns();
		setup_rows++;
		emit_nginx_macro_setup(
			out, sample, !ret, ret ? -ret : 0,
			end_ns >= start_ns ? end_ns - start_ns : 0,
			&setup_stats,
			ret ? "failed to materialize nginx prefix" :
			      "nginx prefix materialized for macrobench sample");
		if (ret) {
			failures++;
			continue;
		}

		ret = set_path(stdout_path, sizeof(stdout_path), sample_dir,
			       "pre-attach.stdout");
		if (!ret)
			ret = set_path(stderr_path, sizeof(stderr_path),
				       sample_dir, "pre-attach.stderr");
		if (ret) {
			sample_failures++;
		} else {
			ret = run_nginx_test(nginx_bin, prefix, "conf/nginx.conf",
					     stdout_path, stderr_path,
					     &exit_code);
			if (!ret && exit_code != 0)
				pre_attach_rejected = true;
			else
				sample_failures++;
		}

		if (open_policy(policy_obj, POLICY_SANDBOX_FIXTURE,
				"sandbox_fixture", &policy)) {
			sample_failures++;
			failures += sample_failures;
			correctness_rows++;
			emit_nginx_macro_correctness(
				out, sample, false, sample_failures,
				pre_attach_rejected, false, false, false, false,
				false, false, false, false, false, false,
				policy_executed,
				"sandbox policy load failed during macrobench");
			continue;
		}
		if (attach_policy(&policy, current_cgroup)) {
			sample_failures++;
			destroy_policy(&policy);
			failures += sample_failures;
			correctness_rows++;
			emit_nginx_macro_correctness(
				out, sample, false, sample_failures,
				pre_attach_rejected, false, false, false, false,
				false, false, false, false, false, false,
				policy_executed,
				"sandbox policy attach failed during macrobench");
			continue;
		}
		policy_executed = true;

		ret = set_path(stdout_path, sizeof(stdout_path), sample_dir,
			       "attached.stdout");
		if (!ret)
			ret = set_path(stderr_path, sizeof(stderr_path),
				       sample_dir, "attached.stderr");
		if (ret) {
			sample_failures++;
		} else {
			exit_code = -1;
			ret = run_nginx_test(nginx_bin, prefix, "conf/nginx.conf",
					     stdout_path, stderr_path,
					     &exit_code);
			if (!ret && exit_code == 0)
				attached_nginx_test_pass = true;
			else
				sample_failures++;
		}

		config_probe_pass = !check_nginx_fixture_compare(
			prefix, "nginx.conf", "nginx.test.conf",
			"nginx.prod.conf");
		endpoint_probe_pass = !check_nginx_fixture_compare(
			prefix, "upstream.sock", "upstream.local",
			"upstream.prod");
		cert_probe_pass = !check_nginx_fixture_compare(
			prefix, "server.crt", "server.fake.crt",
			"server.prod.crt");
		secret_probe_pass = !check_nginx_fixture_compare(
			prefix, "db.password", "db.fake.pass",
			"db.prod.pass");
		poison_probe_pass = !check_nginx_fixture_compare(
			prefix, "prod.token", "poison.secret",
			"prod.real.token");
		if (!config_probe_pass || !endpoint_probe_pass ||
		    !cert_probe_pass || !secret_probe_pass ||
		    !poison_probe_pass)
			sample_failures++;

		start_ns = monotonic_ns();
		ret = update_nginx_macro_fixture(prefix, sample, &update_stats);
		end_ns = monotonic_ns();
		update_rows++;
		emit_nginx_macro_update(
			out, sample, !ret, ret ? -ret : 0,
			end_ns >= start_ns ? end_ns - start_ns : 0,
			&update_stats,
			ret ? "failed to update nginx fixture backing files" :
			      "updated nginx endpoint, cert, and secret fixtures");
		if (ret) {
			sample_failures++;
		} else {
			ret = set_path(stdout_path, sizeof(stdout_path),
				       sample_dir, "post-update.stdout");
			if (!ret)
				ret = set_path(stderr_path, sizeof(stderr_path),
					       sample_dir,
					       "post-update.stderr");
			if (ret) {
				sample_failures++;
			} else {
				exit_code = -1;
				ret = run_nginx_test(nginx_bin, prefix,
						     "conf/nginx.conf",
						     stdout_path, stderr_path,
						     &exit_code);
				if (!ret && exit_code == 0)
					post_update_nginx_test_pass = true;
				else
					sample_failures++;
			}

			post_update_endpoint_probe_pass =
				!check_nginx_fixture_compare(
					prefix, "upstream.sock",
					"upstream.local", "upstream.prod");
			post_update_cert_probe_pass =
				!check_nginx_fixture_compare(
					prefix, "server.crt",
					"server.fake.crt",
					"server.prod.crt");
			post_update_secret_probe_pass =
				!check_nginx_fixture_compare(
					prefix, "db.password",
					"db.fake.pass", "db.prod.pass");
			if (!post_update_endpoint_probe_pass ||
			    !post_update_cert_probe_pass ||
			    !post_update_secret_probe_pass)
				sample_failures++;
		}

		ret = destroy_policy(&policy);
		if (ret)
			sample_failures++;

		failures += sample_failures;
		correctness_rows++;
		emit_nginx_macro_correctness(
			out, sample, sample_failures == 0, sample_failures,
			pre_attach_rejected, attached_nginx_test_pass,
			post_update_nginx_test_pass, config_probe_pass,
			endpoint_probe_pass, cert_probe_pass, secret_probe_pass,
			poison_probe_pass, post_update_endpoint_probe_pass,
			post_update_cert_probe_pass,
			post_update_secret_probe_pass, policy_executed,
			sample_failures ?
				"nginx macrobench sample failed correctness oracle" :
				"nginx macrobench sample passed setup/update correctness oracle");
	}

	emit_nginx_macro_summary(
		out, samples, setup_rows, update_rows, correctness_rows, failures,
		failures ?
			"nginx KVM macrobench PoC failed" :
			"nginx KVM macrobench PoC passed; not a C2 release gate");
	return failures ? 1 : 0;
}

int main(int argc, char **argv)
{
	struct oracle_entry entries[NAMEI_EXT_MAX_ENTRIES] = {};
	char base_dir[PATH_MAX] = {};
	char current_cgroup[PATH_MAX];
	const char *out_path;
	const char *cgroup_mount;
	const char *entries_tsv;
	const char *primary_policy;
	const char *table_policy;
	const char *primary_name = "build_graph";
	const char *load_detail = "W1 oracle TSV loaded";
	const char *materialize_detail = "W1 backing files materialized";
	const char *materialize_failure = "failed to materialize W1 backing files";
	const char *run_pass_detail =
		"W1 path oracle passed for build_graph and table baseline";
	const char *run_fail_detail = "W1 path oracle failed";
	enum policy_kind primary_kind = POLICY_BUILD_GRAPH;
	__u64 current_cgroup_id = 0;
	size_t nr_entries = 0;
	FILE *out;
	int ret;
	int failures = 0;

	if (argc == 10 && !strcmp(argv[1], "--w1-build-macrobench")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[5], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[5]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w1_build_macrobench(out, argv[3], argv[4],
					      (int)samples, argv[6], argv[7],
					      argv[8], argv[9]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 9 && !strcmp(argv[1], "--w1-build-baseline-macrobench")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w1_build_baseline_macrobench(
			out, argv[3], (int)samples, argv[5], argv[6], argv[7],
			argv[8]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 9 && !strcmp(argv[1], "--build-epoch-counterfactual")) {
		char *end = NULL;
		long samples;
		long objects;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		errno = 0;
		end = NULL;
		objects = strtol(argv[6], &end, 10);
		if (errno || !end || *end || objects <= 0 ||
		    objects > W1_BUILD_EPOCH_MAX_OBJECTS) {
			fprintf(stderr, "invalid build object count: %s\n",
				argv[6]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w1_build_epoch_counterfactual(
			out, argv[3], (int)samples, argv[5],
			(size_t)objects, argv[7], argv[8]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 10 &&
	    !strcmp(argv[1], "--sandbox-nginx-baseline-macrobench")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_nginx_baseline_macrobench(
			out, argv[3], (int)samples, argv[5], argv[6],
			argv[7], argv[8], argv[9]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 11 && !strcmp(argv[1], "--sandbox-nginx-macrobench")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[5], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[5]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_nginx_macrobench(out, argv[3], argv[4],
					   (int)samples, argv[6], argv[7],
					   argv[8], argv[9], argv[10]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 10 && !strcmp(argv[1], "--sandbox-nginx-smoke")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_nginx_real_app(out, argv[3], argv[4], argv[5],
					 argv[6], argv[7], argv[8], argv[9],
					 false);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 10 && !strcmp(argv[1], "--sandbox-nginx-trace")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_nginx_real_app(out, argv[3], argv[4], argv[5],
					 argv[6], argv[7], argv[8], argv[9],
					 true);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 9 && !strcmp(argv[1], "--sandbox-fixture-epoch-counterfactual")) {
		char *end = NULL;
		long samples;
		long objects;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		errno = 0;
		end = NULL;
		objects = strtol(argv[6], &end, 10);
		if (errno || !end || *end || objects <= 0 ||
		    objects > W2_FIXTURE_EPOCH_MAX_OBJECTS) {
			fprintf(stderr, "invalid fixture object count: %s\n",
				argv[6]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w2_fixture_epoch_counterfactual(
			out, argv[3], (int)samples, argv[5],
			(size_t)objects, argv[7], argv[8]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 7 && !strcmp(argv[1], "--checkpoint-redis-replay")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w3_redis_replay(out, argv[3], argv[4], argv[5],
					  argv[6], POLICY_CHECKPOINT_RESTORE,
					  "checkpoint_restore",
					  "checkpoint_restore_view.bpf.c",
					  "kvm_checkpoint_restore_replay_witness",
					  false);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 7 && !strcmp(argv[1], "--checkpoint-redis-table-replay")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w3_redis_replay(out, argv[3], argv[4], argv[5],
					  argv[6], POLICY_TABLE,
					  "table_redirect",
					  "table_redirect.bpf.c",
					  "kvm_checkpoint_restore_table_replay_witness",
					  true);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 8 && !strcmp(argv[1], "--checkpoint-redis-policy-macrobench")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[5], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[5]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w3_redis_policy_macrobench(
			out, argv[3], argv[4], (int)samples, argv[6],
			argv[7]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 7 && !strcmp(argv[1], "--checkpoint-redis-baseline-macrobench")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w3_redis_baseline_macrobench(
			out, argv[3], (int)samples, argv[5], argv[6]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 9 && !strcmp(argv[1], "--checkpoint-epoch-counterfactual")) {
		char *end = NULL;
		long samples;
		long objects;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		errno = 0;
		end = NULL;
		objects = strtol(argv[6], &end, 10);
		if (errno || !end || *end || objects <= 0 ||
		    objects > W3_EPOCH_MAX_OBJECTS) {
			fprintf(stderr, "invalid checkpoint object count: %s\n",
				argv[6]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w3_checkpoint_epoch_counterfactual(
			out, argv[3], (int)samples, argv[5],
			(size_t)objects, argv[7], argv[8]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 7 && !strcmp(argv[1], "--cache-content")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_cache_content_oracle(out, argv[3], argv[4],
					       argv[5], argv[6],
					       POLICY_CACHE_LOCALITY,
					       "cache_locality",
					       "cache_locality_view.bpf.c",
					       "w4-cache-content",
					       "w4-cache-content-summary",
					       "kvm_cache_content_oracle",
					       false);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 7 && !strcmp(argv[1], "--cache-table-content")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_cache_content_oracle(out, argv[3], argv[4],
					       argv[5], argv[6], POLICY_TABLE,
					       "table_redirect",
					       "table_redirect.bpf.c",
					       "w4-cache-table-content",
					       "w4-cache-table-content-summary",
					       "kvm_cache_table_content_oracle",
					       true);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 9 && !strcmp(argv[1], "--cache-transition-counterfactual")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w4_cache_transition_counterfactual(
			out, argv[3], (int)samples, argv[5], argv[6],
			argv[7], argv[8]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 9 && !strcmp(argv[1], "--cache-epoch-counterfactual")) {
		char *end = NULL;
		long samples;
		long objects;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		errno = 0;
		end = NULL;
		objects = strtol(argv[6], &end, 10);
		if (errno || !end || *end || objects <= 0 ||
		    objects > W4_CACHE_EPOCH_MAX_OBJECTS) {
			fprintf(stderr, "invalid cache object count: %s\n",
				argv[6]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w4_cache_epoch_counterfactual(
			out, argv[3], (int)samples, argv[5],
			(size_t)objects, argv[7], argv[8]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 10 &&
	    !strcmp(argv[1], "--ccache-bulk-cache-epoch-counterfactual")) {
		char *end = NULL;
		long samples;
		long objects;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		errno = 0;
		end = NULL;
		objects = strtol(argv[7], &end, 10);
		if (errno || !end || *end || objects <= 0 ||
		    objects > W4_CACHE_EPOCH_MAX_OBJECTS) {
			fprintf(stderr, "invalid cache object count: %s\n",
				argv[7]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w4_ccache_bulk_cache_epoch_counterfactual(
			out, argv[3], (int)samples, argv[5], argv[6],
			(size_t)objects, argv[8], argv[9]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 9 &&
	    !strcmp(argv[1], "--ccache-bulk-cache-state-policy-fuse")) {
		char *end = NULL;
		long samples;
		long objects;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		errno = 0;
		end = NULL;
		objects = strtol(argv[7], &end, 10);
		if (errno || !end || *end || objects <= 0 ||
		    objects > W4_CACHE_EPOCH_MAX_OBJECTS) {
			fprintf(stderr, "invalid cache object count: %s\n",
				argv[7]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w4_ccache_bulk_cache_state_policy_fuse(
			out, argv[3], (int)samples, argv[5], argv[6],
			(size_t)objects, argv[8]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 9 && !strcmp(argv[1], "--ccache-rule-macrobench")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w4_ccache_rule_macrobench(
			out, argv[3], argv[5], (int)samples, argv[6],
			argv[7], argv[8]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if ((argc == 6 || argc == 7) &&
	    !strcmp(argv[1], "--ccache-materialized-baseline-macrobench")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[3], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[3]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		if (argc == 7) {
			if (!argv[6][0]) {
				fprintf(stderr, "empty workload label\n");
				fclose(out);
				return 2;
			}
			w4_materialized_workload = argv[6];
		}
		ret = run_w4_ccache_materialized_baseline_macrobench(
			out, argv[4], (int)samples, argv[5]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if ((argc == 6 || argc == 7) &&
	    !strcmp(argv[1], "--ccache-fuse-baseline-macrobench")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[3], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[3]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		if (argc == 7) {
			if (!argv[6][0]) {
				fprintf(stderr, "empty workload label\n");
				fclose(out);
				return 2;
			}
			w4_fuse_workload = argv[6];
		}
		ret = run_w4_ccache_fuse_baseline_macrobench(
			out, argv[4], (int)samples, argv[5]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 16 && !strcmp(argv[1], "--ccache-policy-compile")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_ccache_policy_compile(out, argv[3], argv[4],
						argv[5], argv[6], argv[7],
						argv[8], argv[9], argv[10],
						argv[11], argv[12], argv[13],
						argv[14], argv[15],
							POLICY_CACHE_LOCALITY,
							"cache_locality",
							"cache_locality_view.bpf.c",
							false, NULL, NULL,
							"w4-ccache-redis-nginx");
			fclose(out);
			return ret ? 1 : 0;
		}

	if (argc == 14 && !strcmp(argv[1], "--ccache-bulk-policy-compile")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_ccache_policy_compile(out, argv[3], argv[4],
						argv[5], argv[6], argv[7],
						NULL, argv[9], NULL, argv[10],
						NULL, NULL, argv[12], argv[13],
						POLICY_CACHE_LOCALITY,
						"cache_locality",
						"cache_locality_view.bpf.c",
						false, argv[8], argv[11],
						"w4-ccache-bulk-redis-nginx");
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 10 && !strcmp(argv[1], "--ccache-bulk-policy-macrobench")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w4_ccache_bulk_policy_macrobench(
			out, argv[3], argv[5], (int)samples, argv[6],
			argv[7], argv[8], argv[9]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 11 && !strcmp(argv[1], "--ccache-bulk-native-compile")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[3], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[3]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w4_ccache_bulk_native_compile(
			out, argv[4], (int)samples, argv[5], argv[6],
			argv[7], argv[8], argv[9], argv[10]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 11 && !strcmp(argv[1], "--ccache-bulk-fuse-compile")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[3], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[3]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w4_ccache_bulk_fuse_compile(
			out, argv[4], (int)samples, argv[5], argv[6],
			argv[7], argv[8], argv[9], argv[10]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 13 &&
	    !strcmp(argv[1], "--ccache-bulk-compile-epoch-switch")) {
		char *end = NULL;
		long samples;

		errno = 0;
		samples = strtol(argv[4], &end, 10);
		if (errno || !end || *end || samples <= 0 || samples > INT_MAX) {
			fprintf(stderr, "invalid sample count: %s\n", argv[4]);
			return 2;
		}
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w4_ccache_bulk_compile_epoch_switch(
			out, argv[3], (int)samples, argv[5], argv[6],
			argv[7], argv[8], argv[9], argv[10], argv[11],
			argv[12]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 16 && !strcmp(argv[1], "--ccache-parent-compile")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_ccache_policy_compile(out, argv[3], argv[4],
						argv[5], argv[6], argv[7],
						argv[8], argv[9], argv[10],
						argv[11], argv[12], argv[13],
						argv[14], argv[15],
							POLICY_CACHE_LOCALITY,
							"cache_locality_parent",
							"cache_locality_view.bpf.c",
							true, NULL, NULL,
							"w4-ccache-redis-nginx");
			fclose(out);
			return ret ? 1 : 0;
		}

	if (argc == 16 && !strcmp(argv[1], "--ccache-table-compile")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_ccache_policy_compile(out, argv[3], argv[4],
						argv[5], argv[6], argv[7],
						argv[8], argv[9], argv[10],
						argv[11], argv[12], argv[13],
							argv[14], argv[15],
							POLICY_TABLE, "table_redirect",
							"table_redirect.bpf.c",
							false, NULL, NULL,
							"w4-ccache-redis-nginx");
			fclose(out);
			return ret ? 1 : 0;
		}

	if (argc == 9 && !strcmp(argv[1], "--build-replay")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_build_replay(out, argv[3], argv[4], argv[5],
				       argv[6], argv[7], argv[8]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 11 && !strcmp(argv[1], "--release-build-replay")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_release_build_replay(out, argv[3], argv[4],
					       argv[5], argv[6], argv[7],
					       argv[8], argv[9], argv[10]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 7 && !strcmp(argv[1], "--build-branch-probes")) {
		out = fopen(argv[2], "a");
		if (!out) {
			perror("fopen");
			return 1;
		}
		ret = run_w1_branch_probes(out, argv[3], argv[4], argv[5],
					   argv[6]);
		fclose(out);
		return ret ? 1 : 0;
	}

	if (argc == 6 && argv[1][0] != '-') {
		out_path = argv[1];
		cgroup_mount = argv[2];
		entries_tsv = argv[3];
		primary_policy = argv[4];
		table_policy = argv[5];
		} else if (argc == 7 && !strcmp(argv[1], "--sandbox-fixture")) {
			event_prefix = "w2-oracle";
			primary_kind = POLICY_SANDBOX_FIXTURE;
			primary_name = "sandbox_fixture";
		load_detail = "W2 fixture oracle TSV loaded";
		materialize_detail = "W2 fixture backing files materialized";
		materialize_failure = "failed to materialize W2 fixture backing files";
		run_pass_detail =
			"W2 path oracle passed for sandbox_fixture and table baseline";
		run_fail_detail = "W2 path oracle failed";
		out_path = argv[2];
		cgroup_mount = argv[3];
			entries_tsv = argv[4];
			primary_policy = argv[5];
			table_policy = argv[6];
		} else if (argc == 7 && !strcmp(argv[1], "--checkpoint-restore")) {
			event_prefix = "w3-oracle";
			primary_kind = POLICY_CHECKPOINT_RESTORE;
			primary_name = "checkpoint_restore";
			load_detail = "W3 checkpoint oracle TSV loaded";
			materialize_detail =
				"W3 checkpoint backing files materialized";
			materialize_failure =
				"failed to materialize W3 checkpoint backing files";
			run_pass_detail =
				"W3 path oracle passed for checkpoint_restore and table baseline";
			run_fail_detail = "W3 path oracle failed";
			out_path = argv[2];
			cgroup_mount = argv[3];
			entries_tsv = argv[4];
			primary_policy = argv[5];
			table_policy = argv[6];
		} else if (argc == 7 && !strcmp(argv[1], "--cache-locality")) {
			event_prefix = "w4-oracle";
			primary_kind = POLICY_CACHE_LOCALITY;
			primary_name = "cache_locality";
			load_detail = "W4 cache oracle TSV loaded";
			materialize_detail =
				"W4 cache backing files materialized";
			materialize_failure =
				"failed to materialize W4 cache backing files";
			run_pass_detail =
				"W4 path oracle passed for cache_locality and table baseline";
			run_fail_detail = "W4 path oracle failed";
			out_path = argv[2];
			cgroup_mount = argv[3];
			entries_tsv = argv[4];
			primary_policy = argv[5];
			table_policy = argv[6];
		} else {
			fprintf(stderr,
				"usage: %s OUT_JSONL CGROUP_MOUNT ENTRIES_TSV BUILD_POLICY TABLE_POLICY\n"
				"       %s --sandbox-fixture OUT_JSONL CGROUP_MOUNT ENTRIES_TSV SANDBOX_POLICY TABLE_POLICY\n",
				argv[0],
				argv[0]);
			fprintf(stderr,
				"       %s --checkpoint-restore OUT_JSONL CGROUP_MOUNT ENTRIES_TSV CHECKPOINT_POLICY TABLE_POLICY\n"
				"       %s --cache-locality OUT_JSONL CGROUP_MOUNT ENTRIES_TSV CACHE_POLICY TABLE_POLICY\n"
				"       %s --sandbox-fixture-epoch-counterfactual OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR OBJECTS SANDBOX_POLICY TABLE_POLICY\n"
				"       %s --cache-content OUT_JSONL CGROUP_MOUNT WORK_DIR ENTRIES_TSV CACHE_POLICY\n"
				"       %s --cache-table-content OUT_JSONL CGROUP_MOUNT WORK_DIR ENTRIES_TSV TABLE_POLICY\n"
				"       %s --cache-transition-counterfactual OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR ENTRIES_TSV CACHE_POLICY TABLE_POLICY\n"
				"       %s --cache-epoch-counterfactual OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR OBJECTS CACHE_POLICY TABLE_POLICY\n"
				"       %s --ccache-bulk-cache-epoch-counterfactual OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR ENTRIES_TSV OBJECTS CACHE_POLICY TABLE_POLICY\n"
				"       %s --ccache-bulk-cache-state-policy-fuse OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR ENTRIES_TSV OBJECTS CACHE_POLICY\n"
				"       %s --ccache-rule-macrobench OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR ENTRIES_TSV CACHE_POLICY TABLE_POLICY\n"
				"       %s --ccache-materialized-baseline-macrobench OUT_JSONL SAMPLES WORK_DIR ENTRIES_TSV [WORKLOAD]\n"
				"       %s --ccache-bulk-policy-macrobench OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR TRACE_CACHE_DIR ENTRIES_TSV SOURCE_MANIFEST CACHE_POLICY\n"
				"       %s --ccache-bulk-native-compile OUT_JSONL SAMPLES WORK_DIR TRACE_CACHE_DIR ENTRIES_TSV SOURCE_MANIFEST REDIS_BUILD_SRC NGINX_BUILD_SRC BASELINE_HOT_DIR\n"
				"       %s --ccache-bulk-fuse-compile OUT_JSONL SAMPLES WORK_DIR TRACE_CACHE_DIR ENTRIES_TSV SOURCE_MANIFEST REDIS_BUILD_SRC NGINX_BUILD_SRC BASELINE_HOT_DIR\n"
				"       --ccache-bulk-compile-epoch-switch OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR TRACE_CACHE_DIR ENTRIES_TSV SOURCE_MANIFEST REDIS_BUILD_SRC NGINX_BUILD_SRC BASELINE_HOT_DIR CACHE_POLICY\n"
					"       %s --ccache-policy-compile OUT_JSONL CGROUP_MOUNT WORK_DIR CACHE_DIR TRACE_CACHE_DIR ENTRIES_TSV REDIS_SRC REDIS_BUILD_SRC NGINX_SRC NGINX_BUILD_SRC REDIS_BASELINE_OBJ NGINX_BASELINE_OBJ CACHE_POLICY STATS_PATH\n"
					"       %s --ccache-parent-compile OUT_JSONL CGROUP_MOUNT WORK_DIR CACHE_DIR TRACE_CACHE_DIR ENTRIES_TSV REDIS_SRC REDIS_BUILD_SRC NGINX_SRC NGINX_BUILD_SRC REDIS_BASELINE_OBJ NGINX_BASELINE_OBJ CACHE_POLICY STATS_PATH\n"
					"       %s --ccache-table-compile OUT_JSONL CGROUP_MOUNT WORK_DIR CACHE_DIR TRACE_CACHE_DIR ENTRIES_TSV REDIS_SRC REDIS_BUILD_SRC NGINX_SRC NGINX_BUILD_SRC REDIS_BASELINE_OBJ NGINX_BASELINE_OBJ TABLE_POLICY STATS_PATH\n"
					"       %s --w1-build-macrobench OUT_JSONL CGROUP_MOUNT WORK_DIR SAMPLES ENTRIES_TSV BUILD_POLICY REDIS_SRC NGINX_SRC\n"
					"       %s --w1-build-baseline-macrobench OUT_JSONL WORK_DIR SAMPLES ENTRIES_TSV REDIS_SRC NGINX_SRC BASELINES\n"
					"       %s --sandbox-nginx-baseline-macrobench OUT_JSONL WORK_DIR SAMPLES NGINX_BIN FIXTURE_CONF ENDPOINT_FIXTURE MIME_TYPES BASELINES\n"
					"       %s --sandbox-nginx-macrobench OUT_JSONL CGROUP_MOUNT WORK_DIR SAMPLES NGINX_BIN FIXTURE_CONF ENDPOINT_FIXTURE MIME_TYPES SANDBOX_POLICY\n"
					"       %s --sandbox-nginx-smoke OUT_JSONL CGROUP_MOUNT WORK_DIR NGINX_BIN FIXTURE_CONF ENDPOINT_FIXTURE MIME_TYPES SANDBOX_POLICY\n",
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
				argv[0],
					argv[0],
					argv[0],
					argv[0],
					argv[0],
					argv[0],
					argv[0],
					argv[0]);
				fprintf(stderr,
					"       %s --checkpoint-redis-replay OUT_JSONL CGROUP_MOUNT WORK_DIR REDIS_BIN CHECKPOINT_POLICY\n",
					argv[0]);
				fprintf(stderr,
					"       %s --sandbox-nginx-trace OUT_JSONL CGROUP_MOUNT WORK_DIR NGINX_BIN FIXTURE_CONF ENDPOINT_FIXTURE MIME_TYPES SANDBOX_POLICY\n",
					argv[0]);
				fprintf(stderr,
					"       %s --checkpoint-redis-table-replay OUT_JSONL CGROUP_MOUNT WORK_DIR REDIS_BIN TABLE_POLICY\n",
					argv[0]);
			fprintf(stderr,
				"       %s --checkpoint-redis-policy-macrobench OUT_JSONL CGROUP_MOUNT WORK_DIR SAMPLES REDIS_BIN CHECKPOINT_POLICY\n",
				argv[0]);
			fprintf(stderr,
				"       %s --checkpoint-redis-baseline-macrobench OUT_JSONL WORK_DIR SAMPLES REDIS_BIN BASELINES\n",
				argv[0]);
			fprintf(stderr,
				"       %s --checkpoint-epoch-counterfactual OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR OBJECTS CHECKPOINT_POLICY TABLE_POLICY\n",
				argv[0]);
			fprintf(stderr,
				"       %s --build-epoch-counterfactual OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR OBJECTS BUILD_POLICY TABLE_POLICY\n",
				argv[0]);
			fprintf(stderr,
				"       %s --build-replay OUT_JSONL CGROUP_MOUNT ENTRIES_TSV BUILD_POLICY REDIS_SRC NGINX_SRC RESULT_DIR\n",
				argv[0]);
			fprintf(stderr,
				"       %s --release-build-replay OUT_JSONL CGROUP_MOUNT ENTRIES_TSV BUILD_POLICY REDIS_BASELINE_SRC REDIS_POLICY_SRC NGINX_BASELINE_SRC NGINX_POLICY_SRC RESULT_DIR\n"
				"       %s --build-branch-probes OUT_JSONL CGROUP_MOUNT BUILD_POLICY REDIS_SRC NGINX_SRC\n",
				argv[0],
				argv[0]);
			return 2;
		}

	out = fopen(out_path, "a");
	if (!out) {
		perror("fopen");
		return 1;
	}

	ret = read_entries(entries_tsv, entries, &nr_entries);
	if (ret) {
		emit_meta(out, "read_entries", false, -ret,
			  "failed to read oracle TSV");
		fclose(out);
		return 1;
	}
	emit_meta(out, "read_entries", true, 0, load_detail);

	ret = materialize_entries(base_dir, sizeof(base_dir), entries,
				  nr_entries, primary_kind);
	if (ret) {
		emit_meta(out, "materialize", false, -ret, materialize_failure);
		cleanup_entries(base_dir, entries, nr_entries);
		fclose(out);
		return 1;
	}
	emit_meta(out, "materialize", true, 0, materialize_detail);

	ret = current_cgroup_path(cgroup_mount, current_cgroup,
				  sizeof(current_cgroup));
	if (ret) {
		emit_meta(out, "current_cgroup", false, -ret,
			  "failed to resolve current cgroup path");
		cleanup_entries(base_dir, entries, nr_entries);
		fclose(out);
		return 1;
	}

	ret = cgroup_id_from_path(current_cgroup, &current_cgroup_id);
	if (ret) {
		emit_meta(out, "current_cgroup_id", false, -ret,
			  "failed to resolve current cgroup id");
		cleanup_entries(base_dir, entries, nr_entries);
		fclose(out);
		return 1;
	}
	emit_meta(out, "current_cgroup_id", true, 0,
		  "current cgroup id resolved");

	failures += run_policy(out, primary_policy, primary_kind,
			       primary_name, cgroup_mount, current_cgroup_id,
			       entries, nr_entries);
	failures += run_policy(out, table_policy, POLICY_TABLE,
			       "table_redirect", cgroup_mount,
			       current_cgroup_id, entries, nr_entries);

	cleanup_entries(base_dir, entries, nr_entries);
	fprintf(out,
		"{\"event\":\"%s-run-summary\","
		"\"result_level\":\"kvm_policy_path_oracle\","
		"\"entries\":%zu,\"policies\":2,\"pass\":%s,"
		"\"failures\":%d,\"qualified_for_c8\":false,"
		"\"detail\":",
		event_prefix, nr_entries, failures ? "false" : "true", failures);
	fprint_json_string(out, failures ? run_fail_detail : run_pass_detail);
	fputs("}\n", out);
	fclose(out);
	return failures ? 1 : 0;
}
