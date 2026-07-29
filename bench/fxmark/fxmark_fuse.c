// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE
#define FUSE_USE_VERSION 26

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <fuse.h>
#include <limits.h>
#include <poll.h>
#include <pthread.h>
#include <sched.h>
#include <stdatomic.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/types.h>
#include <sys/un.h>
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
static char control_path[sizeof(((struct sockaddr_un *)0)->sun_path)];
static _Atomic int current_phase = PHASE_SETUP;
static _Atomic bool control_stop;
static int control_fd = -1;
static pthread_t control_thread;
static unsigned long long phase_measured_acks;
static unsigned long long phase_after_acks;
static unsigned long long phase_invalid_commands;
static unsigned long long counters[PHASE_MAX][REQUEST_MAX];

static int read_byte(int fd, char *value)
{
	for (;;) {
		ssize_t received = read(fd, value, 1);

		if (received == 1)
			return 0;
		if (!received)
			return -EPIPE;
		if (errno != EINTR)
			return -errno;
	}
}

static int write_byte(int fd, char value)
{
	for (;;) {
		ssize_t written = send(fd, &value, 1, MSG_NOSIGNAL);

		if (written == 1)
			return 0;
		if (!written)
			return -EIO;
		if (errno != EINTR)
			return -errno;
	}
}

static void *serve_control(void *unused)
{
	(void)unused;
	while (!atomic_load_explicit(&control_stop, memory_order_acquire)) {
		struct pollfd descriptor = {
			.fd = control_fd,
			.events = POLLIN,
		};
		int ready = poll(&descriptor, 1, 100);
		int client;
		char command;
		char reply = 'E';

		if (ready < 0) {
			if (errno == EINTR)
				continue;
			break;
		}
		if (!ready)
			continue;
		client = accept4(control_fd, NULL, NULL, SOCK_CLOEXEC);
		if (client < 0) {
			if (errno == EINTR)
				continue;
			break;
		}
		if (!read_byte(client, &command)) {
			int phase = atomic_load_explicit(&current_phase,
							memory_order_acquire);

			if (command == 'M' && phase == PHASE_SETUP) {
				atomic_store_explicit(&current_phase, PHASE_MEASURED,
						     memory_order_release);
				phase_measured_acks++;
				reply = 'O';
			} else if (command == 'A' && phase == PHASE_MEASURED) {
				atomic_store_explicit(&current_phase, PHASE_AFTER,
						     memory_order_release);
				phase_after_acks++;
				reply = 'O';
			} else {
				phase_invalid_commands++;
			}
		}
		write_byte(client, reply);
		close(client);
	}
	return NULL;
}

static int start_control(const char *path)
{
	struct sockaddr_un address = {
		.sun_family = AF_UNIX,
	};
	int ret;

	if (snprintf(control_path, sizeof(control_path), "%s", path) >=
	    (int)sizeof(control_path))
		return -ENAMETOOLONG;
	if (snprintf(address.sun_path, sizeof(address.sun_path), "%s", path) >=
	    (int)sizeof(address.sun_path))
		return -ENAMETOOLONG;
	control_fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
	if (control_fd < 0)
		return -errno;
	if (unlink(path) && errno != ENOENT) {
		ret = -errno;
		goto error;
	}
	if (bind(control_fd, (struct sockaddr *)&address, sizeof(address)) ||
	    listen(control_fd, 4)) {
		ret = -errno;
		goto error;
	}
	atomic_store_explicit(&control_stop, false, memory_order_release);
	ret = pthread_create(&control_thread, NULL, serve_control, NULL);
	if (ret) {
		ret = -ret;
		goto error;
	}
	return 0;

error:
	close(control_fd);
	control_fd = -1;
	unlink(path);
	return ret;
}

static int stop_control(void)
{
	int ret;

	atomic_store_explicit(&control_stop, true, memory_order_release);
	ret = pthread_join(control_thread, NULL);
	if (close(control_fd) && !ret)
		ret = errno;
	control_fd = -1;
	if (unlink(control_path) && errno != ENOENT && !ret)
		ret = errno;
	return ret ? -ret : 0;
}

static int send_phase(const char *path, const char *phase)
{
	struct sockaddr_un address = {
		.sun_family = AF_UNIX,
	};
	char command;
	char reply;
	int fd;
	int ret;

	if (!strcmp(phase, "measured"))
		command = 'M';
	else if (!strcmp(phase, "after"))
		command = 'A';
	else
		return -EINVAL;
	if (snprintf(address.sun_path, sizeof(address.sun_path), "%s", path) >=
	    (int)sizeof(address.sun_path))
		return -ENAMETOOLONG;
	fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
	if (fd < 0)
		return -errno;
	if (connect(fd, (struct sockaddr *)&address, sizeof(address))) {
		ret = -errno;
		goto out;
	}
	ret = write_byte(fd, command);
	if (!ret)
		ret = read_byte(fd, &reply);
	if (!ret && reply != 'O')
		ret = -EPROTO;
out:
	if (close(fd) && !ret)
		ret = -errno;
	return ret;
}

static void count_request(enum request_counter counter)
{
	int phase = atomic_load_explicit(&current_phase, memory_order_acquire);

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
	count_request(REQUEST_READDIR);
	if (offset)
		seekdir(dir, offset);
	for (;;) {
		struct stat st = {
			.st_ino = 0,
			.st_mode = 0,
		};
		off_t next;

		errno = 0;
		entry = readdir(dir);
		if (!entry)
			return errno ? -errno : 0;
		st.st_ino = entry->d_ino;
		st.st_mode = entry->d_type << 12;
		errno = 0;
		next = telldir(dir);
		if (next < 0)
			return errno ? -errno : -EIO;
		if (filler(buf, entry->d_name, &st, next))
			break;
	}
	return 0;
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
			"\"after_total\":%llu,"
			"\"measured_opendir\":%llu,"
			"\"measured_readdir\":%llu,"
			"\"measured_releasedir\":%llu"
			",\"phase_measured_acks\":%llu,"
			"\"phase_after_acks\":%llu,"
			"\"phase_invalid_commands\":%llu"
			",\"user_ns\":%llu,\"system_ns\":%llu,"
			"\"voluntary_context_switches\":%ld,"
			"\"involuntary_context_switches\":%ld}\n",
			phase_totals[PHASE_SETUP], phase_totals[PHASE_MEASURED],
			phase_totals[PHASE_AFTER],
			counters[PHASE_MEASURED][REQUEST_OPENDIR],
			counters[PHASE_MEASURED][REQUEST_READDIR],
			counters[PHASE_MEASURED][REQUEST_RELEASEDIR],
			phase_measured_acks, phase_after_acks,
			phase_invalid_commands,
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
	bool control_started = false;
	int fuse_status;
	int control_status;
	int i;

	if (argc == 4 && !strcmp(argv[1], "--phase")) {
		int ret = send_phase(argv[2], argv[3]);

		if (ret) {
			errno = -ret;
			perror("send phase");
			return 1;
		}
		return 0;
	}
	if (argc != 5) {
		fprintf(stderr,
			"usage: %s LOWER_ROOT MOUNTPOINT STATS_JSON CONTROL_SOCKET\n",
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
	control_status = start_control(argv[4]);
	if (control_status) {
		errno = -control_status;
		perror("start control");
		return 1;
	}
	control_started = true;

	fuse_argv[0] = argv[0];
	fuse_argv[1] = "-f";
	fuse_argv[2] = "-o";
	fuse_argv[3] =
		"default_permissions,kernel_cache,attr_timeout=3600,"
		"entry_timeout=3600,negative_timeout=3600";
	fuse_argv[4] = argv[2];
	fuse_argv[5] = NULL;
	fuse_status = fuse_main(5, fuse_argv, &fx_ops, NULL);
	control_status = control_started ? stop_control() : 0;
	if (write_stats(fuse_status)) {
		perror("write_stats");
		return 1;
	}
	if (control_status) {
		errno = -control_status;
		perror("stop control");
		return 1;
	}
	return fuse_status ? 1 : 0;
}
