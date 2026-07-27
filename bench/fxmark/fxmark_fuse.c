// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE
#define FUSE_USE_VERSION 26

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <fuse.h>
#include <limits.h>
#include <sched.h>
#include <signal.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/types.h>
#include <unistd.h>

enum request_counter {
	REQUEST_GETATTR = 0,
	REQUEST_ACCESS,
	REQUEST_MKDIR,
	REQUEST_CREATE,
	REQUEST_OPEN,
	REQUEST_RELEASE,
	REQUEST_READ,
	REQUEST_WRITE,
	REQUEST_OPENDIR,
	REQUEST_READDIR,
	REQUEST_RELEASEDIR,
	REQUEST_MAX,
};

enum request_phase {
	PHASE_SETUP = 0,
	PHASE_MEASURED,
	PHASE_AFTER,
	PHASE_MAX,
};

static char lower_root[PATH_MAX];
static char stats_path[PATH_MAX];
static volatile sig_atomic_t current_phase = PHASE_SETUP;
static unsigned long long counters[PHASE_MAX][REQUEST_MAX];

static void set_measured(int signo)
{
	(void)signo;
	current_phase = PHASE_MEASURED;
}

static void set_after(int signo)
{
	(void)signo;
	current_phase = PHASE_AFTER;
}

static void count_request(enum request_counter counter)
{
	int phase = current_phase;

	if (phase < PHASE_SETUP || phase >= PHASE_MAX)
		phase = PHASE_AFTER;
	__sync_fetch_and_add(&counters[phase][counter], 1);
}

static int lower_path(char *out, size_t size, const char *path)
{
	int ret;

	if (!path || path[0] != '/' || strstr(path, "/../") ||
	    !strcmp(path, "/.."))
		return -EINVAL;
	ret = snprintf(out, size, "%s%s", lower_root, path);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int fx_getattr(const char *path, struct stat *st)
{
	char lower[PATH_MAX];
	int ret;

	count_request(REQUEST_GETATTR);
	ret = lower_path(lower, sizeof(lower), path);
	if (ret)
		return ret;
	if (lstat(lower, st))
		return -errno;
	return 0;
}

static int fx_access(const char *path, int mask)
{
	char lower[PATH_MAX];
	int ret;

	count_request(REQUEST_ACCESS);
	ret = lower_path(lower, sizeof(lower), path);
	if (ret)
		return ret;
	if (access(lower, mask))
		return -errno;
	return 0;
}

static int fx_mkdir(const char *path, mode_t mode)
{
	char lower[PATH_MAX];
	int ret;

	count_request(REQUEST_MKDIR);
	ret = lower_path(lower, sizeof(lower), path);
	if (ret)
		return ret;
	if (mkdir(lower, mode))
		return -errno;
	return 0;
}

static int fx_create(const char *path, mode_t mode, struct fuse_file_info *fi)
{
	char lower[PATH_MAX];
	int fd;
	int ret;

	count_request(REQUEST_CREATE);
	ret = lower_path(lower, sizeof(lower), path);
	if (ret)
		return ret;
	fd = open(lower, fi->flags | O_CLOEXEC, mode);
	if (fd < 0)
		return -errno;
	fi->fh = fd;
	return 0;
}

static int fx_open(const char *path, struct fuse_file_info *fi)
{
	char lower[PATH_MAX];
	int fd;
	int ret;

	count_request(REQUEST_OPEN);
	ret = lower_path(lower, sizeof(lower), path);
	if (ret)
		return ret;
	fd = open(lower, fi->flags | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	fi->fh = fd;
	return 0;
}

static int fx_release(const char *path, struct fuse_file_info *fi)
{
	(void)path;
	count_request(REQUEST_RELEASE);
	if (close((int)fi->fh))
		return -errno;
	return 0;
}

static int fx_read(const char *path, char *buf, size_t size, off_t offset,
		   struct fuse_file_info *fi)
{
	ssize_t ret;

	(void)path;
	count_request(REQUEST_READ);
	ret = pread((int)fi->fh, buf, size, offset);
	return ret < 0 ? -errno : (int)ret;
}

static int fx_write(const char *path, const char *buf, size_t size,
		    off_t offset, struct fuse_file_info *fi)
{
	ssize_t ret;

	(void)path;
	count_request(REQUEST_WRITE);
	ret = pwrite((int)fi->fh, buf, size, offset);
	return ret < 0 ? -errno : (int)ret;
}

static int fx_opendir(const char *path, struct fuse_file_info *fi)
{
	char lower[PATH_MAX];
	DIR *dir;
	int ret;

	count_request(REQUEST_OPENDIR);
	ret = lower_path(lower, sizeof(lower), path);
	if (ret)
		return ret;
	dir = opendir(lower);
	if (!dir)
		return -errno;
	fi->fh = (uintptr_t)dir;
	return 0;
}

static int fx_readdir(const char *path, void *buf, fuse_fill_dir_t filler,
		      off_t offset, struct fuse_file_info *fi)
{
	DIR *dir = (DIR *)(uintptr_t)fi->fh;
	struct dirent *entry;

	(void)path;
	(void)offset;
	count_request(REQUEST_READDIR);
	errno = 0;
	while ((entry = readdir(dir))) {
		struct stat st = {
			.st_ino = entry->d_ino,
			.st_mode = entry->d_type << 12,
		};

		if (filler(buf, entry->d_name, &st, 0))
			break;
	}
	return errno ? -errno : 0;
}

static int fx_releasedir(const char *path, struct fuse_file_info *fi)
{
	(void)path;
	count_request(REQUEST_RELEASEDIR);
	if (closedir((DIR *)(uintptr_t)fi->fh))
		return -errno;
	return 0;
}

static int fx_statfs(const char *path, struct statvfs *st)
{
	char lower[PATH_MAX];
	int ret;

	ret = lower_path(lower, sizeof(lower), path);
	if (ret)
		return ret;
	if (statvfs(lower, st))
		return -errno;
	return 0;
}

static struct fuse_operations fx_ops = {
	.getattr = fx_getattr,
	.access = fx_access,
	.mkdir = fx_mkdir,
	.create = fx_create,
	.open = fx_open,
	.release = fx_release,
	.read = fx_read,
	.write = fx_write,
	.opendir = fx_opendir,
	.readdir = fx_readdir,
	.releasedir = fx_releasedir,
	.statfs = fx_statfs,
};

static unsigned long long timeval_ns(struct timeval value)
{
	return (unsigned long long)value.tv_sec * 1000000000ull +
	       (unsigned long long)value.tv_usec * 1000ull;
}

static int write_stats(int fuse_status)
{
	static const char *const phase_names[] = {
		"setup", "measured", "after"
	};
	static const char *const counter_names[] = {
		"getattr", "access", "mkdir", "create", "open", "release",
		"read", "write", "opendir", "readdir", "releasedir"
	};
	struct rusage usage;
	unsigned long long phase_totals[PHASE_MAX] = {};
	FILE *out;
	int phase;
	int counter;

	if (getrusage(RUSAGE_SELF, &usage))
		return -errno;
	out = fopen(stats_path, "w");
	if (!out)
		return -errno;
	fprintf(out, "{\"fuse_status\":%d", fuse_status);
	for (phase = 0; phase < PHASE_MAX; ++phase) {
		fprintf(out, ",\"%s\":{", phase_names[phase]);
		for (counter = 0; counter < REQUEST_MAX; ++counter) {
			phase_totals[phase] += counters[phase][counter];
			fprintf(out, "%s\"%s\":%llu", counter ? "," : "",
				counter_names[counter],
				counters[phase][counter]);
		}
		fputc('}', out);
	}
	fprintf(out,
		",\"setup_total\":%llu,\"measured_total\":%llu,"
		"\"after_total\":%llu"
		",\"user_ns\":%llu,\"system_ns\":%llu,"
		"\"voluntary_context_switches\":%ld,"
		"\"involuntary_context_switches\":%ld}\n",
		phase_totals[PHASE_SETUP], phase_totals[PHASE_MEASURED],
		phase_totals[PHASE_AFTER],
		timeval_ns(usage.ru_utime), timeval_ns(usage.ru_stime),
		usage.ru_nvcsw, usage.ru_nivcsw);
	if (fclose(out))
		return -errno;
	return 0;
}

int main(int argc, char **argv)
{
	char *fuse_argv[6];
	cpu_set_t cpus;
	struct sigaction action = {};
	int fuse_status;
	int i;

	if (argc != 4) {
		fprintf(stderr, "usage: %s LOWER_ROOT MOUNTPOINT STATS_JSON\n",
			argv[0]);
		return 2;
	}
	if (snprintf(lower_root, sizeof(lower_root), "%s", argv[1]) >=
	    (int)sizeof(lower_root) ||
	    snprintf(stats_path, sizeof(stats_path), "%s", argv[3]) >=
	    (int)sizeof(stats_path)) {
		fprintf(stderr, "path too long\n");
		return 2;
	}

	CPU_ZERO(&cpus);
	for (i = 0; i < 4; ++i)
		CPU_SET(i, &cpus);
	if (sched_setaffinity(0, sizeof(cpus), &cpus)) {
		perror("sched_setaffinity");
		return 1;
	}
	action.sa_handler = set_measured;
	action.sa_flags = SA_RESTART;
	sigemptyset(&action.sa_mask);
	if (sigaction(SIGUSR1, &action, NULL)) {
		perror("sigaction SIGUSR1");
		return 1;
	}
	action.sa_handler = set_after;
	if (sigaction(SIGUSR2, &action, NULL)) {
		perror("sigaction SIGUSR2");
		return 1;
	}

	fuse_argv[0] = argv[0];
	fuse_argv[1] = "-f";
	fuse_argv[2] = "-o";
	fuse_argv[3] =
		"default_permissions,kernel_cache,attr_timeout=3600,"
		"entry_timeout=3600,negative_timeout=3600";
	fuse_argv[4] = argv[2];
	fuse_argv[5] = NULL;
	fuse_status = fuse_main(5, fuse_argv, &fx_ops, NULL);
	if (write_stats(fuse_status)) {
		perror("write_stats");
		return 1;
	}
	return fuse_status ? 1 : 0;
}
