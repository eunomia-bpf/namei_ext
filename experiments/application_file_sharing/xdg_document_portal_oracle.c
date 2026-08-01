// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include "rq2_fuse_counter.h"
#include "rq2_measurement.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <ftw.h>
#include <gio/gio.h>
#include <gio/gunixfdlist.h>
#include <inttypes.h>
#include <limits.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define APP_A "org.namei.SourceA"
#define APP_B "org.namei.SourceB"
#define DOCUMENT_BASENAME "payload.txt"
#define DOCUMENT_PAYLOAD "xdg-portal-existing-object\n"
struct portal_paths {
	const char *parent;
	const char *document;
	const char *payload;
	const char *host_payload;
	const char *listed_name;
};

struct state_observation {
	int document_errno;
	int payload_stat_errno;
	int payload_read_errno;
	int opendir_errno;
	int readdir_errno;
	int closedir_errno;
	int host_errno;
	bool document_listed;
	bool payload_bytes_expected;
	bool host_bytes_expected;
};

static void emit_case(FILE *out, const char *name, bool pass, int err,
		      const char *detail)
{
	fprintf(out,
		"{\"event\":\"application-file-sharing-source-case\","
		"\"mechanism\":\"xdg-document-portal\","
		"\"case\":\"%s\",\"pass\":%s,\"errno\":%d,"
		"\"detail\":\"%s\"}\n",
		name, pass ? "true" : "false", err, detail);
	fflush(out);
}

static int make_directory(const char *path)
{
	if (!mkdir(path, 0700) || errno == EEXIST)
		return 0;
	return -errno;
}

static int join_path(char *destination, size_t size,
		     const char *parent, const char *child)
{
	int written = snprintf(destination, size, "%s/%s", parent, child);

	if (written < 0 || (size_t)written >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int write_text(const char *path, const char *text)
{
	size_t remaining = strlen(text);
	const char *cursor = text;
	int fd;

	fd = open(path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0644);
	if (fd < 0)
		return -errno;
	while (remaining) {
		ssize_t written = write(fd, cursor, remaining);

		if (written < 0) {
			int saved_errno = errno;

			if (saved_errno == EINTR)
				continue;
			close(fd);
			return -saved_errno;
		}
		cursor += written;
		remaining -= (size_t)written;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static int copy_file(const char *source, const char *destination)
{
	char buffer[4096];
	int input = -1;
	int output = -1;
	int ret = 0;

	input = open(source, O_RDONLY | O_CLOEXEC);
	if (input < 0)
		return -errno;
	output = open(destination, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC,
		      0644);
	if (output < 0) {
		ret = -errno;
		goto out;
	}
	for (;;) {
		ssize_t bytes = read(input, buffer, sizeof(buffer));

		if (bytes < 0) {
			if (errno == EINTR)
				continue;
			ret = -errno;
			goto out;
		}
		if (!bytes)
			break;
		for (ssize_t offset = 0; offset < bytes;) {
			ssize_t written = write(output, buffer + offset,
						(size_t)(bytes - offset));

			if (written < 0) {
				if (errno == EINTR)
					continue;
				ret = -errno;
				goto out;
			}
			offset += written;
		}
	}
out:
	if (output >= 0 && close(output) && !ret)
		ret = -errno;
	if (close(input) && !ret)
		ret = -errno;
	return ret;
}

static int observe_text(const char *path, const char *expected,
			bool *bytes_expected)
{
	char buffer[4096];
	size_t expected_length = strlen(expected);
	size_t offset = 0;
	bool matches = true;
	int fd;

	*bytes_expected = false;
	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return errno;
	for (;;) {
		ssize_t bytes = read(fd, buffer, sizeof(buffer));

		if (bytes < 0) {
			int saved_errno = errno;

			if (saved_errno == EINTR)
				continue;
			close(fd);
			return saved_errno;
		}
		if (!bytes)
			break;
		if (offset > expected_length ||
		    (size_t)bytes > expected_length - offset ||
		    memcmp(buffer, expected + offset, (size_t)bytes))
			matches = false;
		if (SIZE_MAX - offset < (size_t)bytes) {
			close(fd);
			return EOVERFLOW;
		}
		offset += (size_t)bytes;
	}
	if (close(fd))
		return errno;
	*bytes_expected = matches && offset == expected_length;
	return 0;
}

static void observe_directory(const char *path, const char *name,
			      struct state_observation *observation)
{
	struct dirent *entry;
	DIR *directory;

	observation->document_listed = false;
	directory = opendir(path);
	if (!directory) {
		observation->opendir_errno = errno;
		return;
	}
	errno = 0;
	while ((entry = readdir(directory))) {
		if (!strcmp(entry->d_name, name))
			observation->document_listed = true;
	}
	observation->readdir_errno = errno;
	if (closedir(directory))
		observation->closedir_errno = errno;
}

static bool emit_state(FILE *out, const char *state, bool expected_visible,
		       const struct portal_paths *paths)
{
	struct state_observation observation = {};
	struct stat ignored;
	bool pass;

	if (stat(paths->document, &ignored))
		observation.document_errno = errno;
	if (stat(paths->payload, &ignored))
		observation.payload_stat_errno = errno;
	observation.payload_read_errno = observe_text(
		paths->payload, DOCUMENT_PAYLOAD,
		&observation.payload_bytes_expected);
	observe_directory(paths->parent, paths->listed_name, &observation);
	observation.host_errno = observe_text(
		paths->host_payload, DOCUMENT_PAYLOAD,
		&observation.host_bytes_expected);

	if (expected_visible) {
		pass = !observation.document_errno &&
		       !observation.payload_stat_errno &&
		       !observation.payload_read_errno &&
		       !observation.opendir_errno &&
		       !observation.readdir_errno &&
		       !observation.closedir_errno &&
		       !observation.host_errno &&
		       observation.document_listed &&
		       observation.payload_bytes_expected &&
		       observation.host_bytes_expected;
	} else {
		pass = observation.document_errno == ENOENT &&
		       observation.payload_stat_errno == ENOENT &&
		       observation.payload_read_errno == ENOENT &&
		       !observation.opendir_errno &&
		       !observation.readdir_errno &&
		       !observation.closedir_errno &&
		       !observation.host_errno &&
		       !observation.document_listed &&
		       observation.host_bytes_expected;
	}

	fprintf(out,
		"{\"event\":\"application-file-sharing-source-state\","
		"\"mechanism\":\"xdg-document-portal\","
		"\"state\":\"%s\",\"expected_visible\":%s,"
		"\"document_errno\":%d,\"payload_stat_errno\":%d,"
		"\"payload_read_errno\":%d,\"opendir_errno\":%d,"
		"\"readdir_errno\":%d,\"closedir_errno\":%d,"
		"\"document_listed\":%s,\"payload_bytes_expected\":%s,"
		"\"host_errno\":%d,\"host_bytes_expected\":%s,"
		"\"pass\":%s}\n",
		state, expected_visible ? "true" : "false",
		observation.document_errno, observation.payload_stat_errno,
		observation.payload_read_errno, observation.opendir_errno,
		observation.readdir_errno, observation.closedir_errno,
		observation.document_listed ? "true" : "false",
		observation.payload_bytes_expected ? "true" : "false",
		observation.host_errno,
		observation.host_bytes_expected ? "true" : "false",
		pass ? "true" : "false");
	fflush(out);
	return pass;
}

static pid_t spawn_logged(const char *program, const char *stdout_path,
			  const char *stderr_path)
{
	pid_t pid = fork();

	if (pid)
		return pid;
	int stdout_fd = open(stdout_path,
			     O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
	int stderr_fd = open(stderr_path,
			     O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);

	if (stdout_fd < 0 || stderr_fd < 0)
		_exit(126);
	if (dup2(stdout_fd, STDOUT_FILENO) < 0 ||
	    dup2(stderr_fd, STDERR_FILENO) < 0)
		_exit(126);
	close(stdout_fd);
	close(stderr_fd);
	execl(program, program, "--replace", NULL);
	_exit(errno == ENOENT ? 127 : 126);
}

static bool process_running(pid_t pid)
{
	if (pid <= 0)
		return false;
	if (!kill(pid, 0))
		return true;
	return errno == EPERM;
}

static int stop_process(pid_t pid, int *wait_status, bool *status_valid)
{
	struct timespec delay = {
		.tv_nsec = 10000000,
	};
	int status;

	*wait_status = 0;
	*status_valid = false;
	if (pid <= 0)
		return 0;
	if (kill(pid, SIGTERM) && errno != ESRCH)
		return -errno;
	for (int attempt = 0; attempt < 500; attempt++) {
		pid_t result = waitpid(pid, &status, WNOHANG);

		if (result == pid) {
			*wait_status = status;
			*status_valid = true;
			return 0;
		}
		if (result < 0)
			return -errno;
		nanosleep(&delay, NULL);
	}
	if (kill(pid, SIGKILL) && errno != ESRCH)
		return -errno;
	if (waitpid(pid, &status, 0) < 0) {
		return -errno;
	} else {
		*wait_status = status;
		*status_valid = true;
	}
	return -ETIMEDOUT;
}

static bool emit_process_exit(FILE *out, const char *name, pid_t pid, int ret,
			      int wait_status, bool status_valid)
{
	bool exited = status_valid && WIFEXITED(wait_status);
	bool signaled = status_valid && WIFSIGNALED(wait_status);
	bool expected_status = (exited && WEXITSTATUS(wait_status) == 0) ||
			       (signaled && WTERMSIG(wait_status) == SIGTERM);
	bool pass = !ret && (pid <= 0 || (status_valid && expected_status));

	fprintf(out,
		"{\"event\":\"application-file-sharing-source-process\","
		"\"mechanism\":\"xdg-document-portal\","
		"\"process\":\"%s\",\"pid\":%jd,\"started\":%s,"
		"\"stop_errno\":%d,\"status_valid\":%s,\"raw_status\":%d,"
		"\"exited\":%s,\"exit_code\":%d,"
		"\"signaled\":%s,\"term_signal\":%d,\"pass\":%s}\n",
		name, (intmax_t)pid, pid > 0 ? "true" : "false",
		ret ? -ret : 0, status_valid ? "true" : "false", wait_status,
		exited ? "true" : "false", exited ? WEXITSTATUS(wait_status) : -1,
		signaled ? "true" : "false",
		signaled ? WTERMSIG(wait_status) : 0,
		pass ? "true" : "false");
	fflush(out);
	return pass;
}

static void log_gerror(const char *operation, const GError *error)
{
	const char *domain;
	char *remote;

	if (!error)
		return;
	domain = g_quark_to_string(error->domain);
	remote = g_dbus_error_get_remote_error(error);
	fprintf(stderr,
		"%s failed: domain=%s code=%d remote=%s message=%s\n",
		operation, domain ? domain : "unknown", error->code,
		remote ? remote : "none",
		error->message ? error->message : "none");
	g_free(remote);
}

static int wait_for_bus_name(GDBusConnection *connection, const char *name)
{
	struct timespec delay = {
		.tv_nsec = 10000000,
	};

	for (int attempt = 0; attempt < 500; attempt++) {
		GError *error = NULL;
		GVariant *reply = g_dbus_connection_call_sync(
			connection, "org.freedesktop.DBus",
			"/org/freedesktop/DBus", "org.freedesktop.DBus",
			"NameHasOwner", g_variant_new("(s)", name),
			G_VARIANT_TYPE("(b)"), G_DBUS_CALL_FLAGS_NONE,
			1000, NULL, &error);

		if (reply) {
			gboolean owned = false;

			g_variant_get(reply, "(b)", &owned);
			g_variant_unref(reply);
			if (owned)
				return 0;
		}
		if (error) {
			fprintf(stderr, "NameHasOwner(%s), attempt %d: ",
				name, attempt + 1);
			log_gerror("D-Bus readiness", error);
		}
		g_clear_error(&error);
		nanosleep(&delay, NULL);
	}
	return -ETIMEDOUT;
}

static int call_permissions(GDBusConnection *connection, const char *method,
			    const char *document_id, const char *application)
{
	const char *permissions[] = { "read", NULL };
	GError *error = NULL;
	GVariant *reply;
	int ret = 0;

	reply = g_dbus_connection_call_sync(
		connection, "org.freedesktop.portal.Documents",
		"/org/freedesktop/portal/documents",
		"org.freedesktop.portal.Documents", method,
		g_variant_new("(ss^as)", document_id, application, permissions),
		G_VARIANT_TYPE("()"), G_DBUS_CALL_FLAGS_NONE, 30000,
		NULL, &error);
	if (!reply) {
		log_gerror(method, error);
		ret = error ? -EIO : -EINVAL;
	}
	if (reply)
		g_variant_unref(reply);
	g_clear_error(&error);
	return ret;
}

static int add_document(GDBusConnection *connection, const char *host_path,
			char **document_id)
{
	GUnixFDList *fd_list = NULL;
	GVariant *reply = NULL;
	GError *error = NULL;
	int fd_index;
	int fd = -1;
	int ret = 0;

	fd = open(host_path, O_PATH | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	fd_list = g_unix_fd_list_new();
	fd_index = g_unix_fd_list_append(fd_list, fd, &error);
	close(fd);
	if (fd_index < 0) {
		log_gerror("g_unix_fd_list_append", error);
		ret = -EIO;
		goto out;
	}
	reply = g_dbus_connection_call_with_unix_fd_list_sync(
		connection, "org.freedesktop.portal.Documents",
		"/org/freedesktop/portal/documents",
		"org.freedesktop.portal.Documents", "Add",
		g_variant_new("(hbb)", fd_index, FALSE, FALSE),
		G_VARIANT_TYPE("(s)"), G_DBUS_CALL_FLAGS_NONE, 30000,
		fd_list, NULL, NULL, &error);
	if (!reply) {
		log_gerror("Documents.Add", error);
		ret = -EIO;
		goto out;
	}
	g_variant_get(reply, "(s)", document_id);
	if (!*document_id || !**document_id)
		ret = -EINVAL;
out:
	if (reply)
		g_variant_unref(reply);
	if (fd_list)
		g_object_unref(fd_list);
	g_clear_error(&error);
	return ret;
}

static int get_mountpoint(GDBusConnection *connection, char **mountpoint)
{
	GError *error = NULL;
	GVariant *reply;
	GVariant *bytes;
	gsize length = 0;
	const guint8 *data;
	int ret = 0;

	reply = g_dbus_connection_call_sync(
		connection, "org.freedesktop.portal.Documents",
		"/org/freedesktop/portal/documents",
		"org.freedesktop.portal.Documents", "GetMountPoint", NULL,
		G_VARIANT_TYPE("(ay)"), G_DBUS_CALL_FLAGS_NONE, 30000,
		NULL, &error);
	if (!reply) {
		log_gerror("Documents.GetMountPoint", error);
		g_clear_error(&error);
		return -EIO;
	}
	bytes = g_variant_get_child_value(reply, 0);
	data = g_variant_get_fixed_array(bytes, &length, sizeof(guint8));
	if (!data || !length || data[length - 1] != '\0')
		ret = -EINVAL;
	else
		*mountpoint = strndup((const char *)data, length - 1);
	g_variant_unref(bytes);
	g_variant_unref(reply);
	if (!ret && !*mountpoint)
		ret = -ENOMEM;
	return ret;
}

static bool same_timespec(const struct timespec *left,
			  const struct timespec *right)
{
	return left->tv_sec == right->tv_sec &&
	       left->tv_nsec == right->tv_nsec;
}

static bool same_metadata(const struct stat *before,
			  const struct stat *after)
{
	return before->st_dev == after->st_dev &&
	       before->st_ino == after->st_ino &&
	       before->st_mode == after->st_mode &&
	       before->st_uid == after->st_uid &&
	       before->st_gid == after->st_gid &&
	       before->st_size == after->st_size &&
	       same_timespec(&before->st_mtim, &after->st_mtim) &&
	       same_timespec(&before->st_ctim, &after->st_ctim);
}

static bool emit_lower(FILE *out, const struct stat *before,
		       const struct stat *after, int after_errno,
		       bool bytes_expected)
{
	bool metadata_unchanged = !after_errno &&
				  same_metadata(before, after);
	bool pass = metadata_unchanged && bytes_expected;

	fprintf(out,
		"{\"event\":\"application-file-sharing-source-lower\","
		"\"mechanism\":\"xdg-document-portal\","
		"\"after_errno\":%d,"
		"\"before_dev\":\"%" PRIuMAX "\","
		"\"before_ino\":\"%" PRIuMAX "\","
		"\"before_mode\":\"%" PRIoMAX "\","
		"\"before_uid\":%" PRIuMAX ",\"before_gid\":%" PRIuMAX ","
		"\"before_size\":\"%" PRIdMAX "\","
		"\"before_mtime_sec\":\"%" PRIdMAX "\","
		"\"before_mtime_nsec\":%ld,"
		"\"before_ctime_sec\":\"%" PRIdMAX "\","
		"\"before_ctime_nsec\":%ld,"
		"\"after_dev\":\"%" PRIuMAX "\","
		"\"after_ino\":\"%" PRIuMAX "\","
		"\"after_mode\":\"%" PRIoMAX "\","
		"\"after_uid\":%" PRIuMAX ",\"after_gid\":%" PRIuMAX ","
		"\"after_size\":\"%" PRIdMAX "\","
		"\"after_mtime_sec\":\"%" PRIdMAX "\","
		"\"after_mtime_nsec\":%ld,"
		"\"after_ctime_sec\":\"%" PRIdMAX "\","
		"\"after_ctime_nsec\":%ld,"
		"\"metadata_unchanged\":%s,\"bytes_expected\":%s,"
		"\"pass\":%s}\n",
		after_errno,
		(uintmax_t)before->st_dev, (uintmax_t)before->st_ino,
		(uintmax_t)before->st_mode, (uintmax_t)before->st_uid,
		(uintmax_t)before->st_gid, (intmax_t)before->st_size,
		(intmax_t)before->st_mtim.tv_sec, before->st_mtim.tv_nsec,
		(intmax_t)before->st_ctim.tv_sec, before->st_ctim.tv_nsec,
		(uintmax_t)after->st_dev, (uintmax_t)after->st_ino,
		(uintmax_t)after->st_mode, (uintmax_t)after->st_uid,
		(uintmax_t)after->st_gid, (intmax_t)after->st_size,
		(intmax_t)after->st_mtim.tv_sec, after->st_mtim.tv_nsec,
		(intmax_t)after->st_ctim.tv_sec, after->st_ctim.tv_nsec,
		metadata_unchanged ? "true" : "false",
		bytes_expected ? "true" : "false",
		pass ? "true" : "false");
	fflush(out);
	return pass;
}

static int remove_entry(const char *path, const struct stat *status,
			int type, struct FTW *state)
{
	(void)status;
	(void)type;
	(void)state;
	return remove(path);
}

static int remove_tree(const char *path)
{
	if (!path || !*path)
		return -EINVAL;
	if (!nftw(path, remove_entry, 32, FTW_DEPTH | FTW_PHYS))
		return 0;
	return errno == ENOENT ? 0 : -errno;
}

static int portal_mount_status(const char *mountpoint, bool *mounted)
{
	char *line = NULL;
	size_t capacity = 0;
	FILE *mountinfo;
	int ret = 0;

	*mounted = false;
	mountinfo = fopen("/proc/self/mountinfo", "re");
	if (!mountinfo)
		return -errno;
	while (getline(&line, &capacity, mountinfo) >= 0) {
		char *saveptr = NULL;
		char *mount_field = NULL;
		char *filesystem = NULL;
		char *token;
		int field = 0;

		for (token = strtok_r(line, " \n", &saveptr); token;
		     token = strtok_r(NULL, " \n", &saveptr)) {
			field++;
			if (field == 5)
				mount_field = token;
			if (!strcmp(token, "-")) {
				filesystem = strtok_r(NULL, " \n", &saveptr);
				break;
			}
		}
		if (mount_field && filesystem &&
		    !strcmp(mount_field, mountpoint) &&
		    !strcmp(filesystem, "fuse.portal")) {
			*mounted = true;
			break;
		}
	}
	if (ferror(mountinfo))
		ret = -EIO;
	free(line);
	if (fclose(mountinfo) && !ret)
		ret = -errno;
	return ret;
}

static int run_rq2_direct_control(FILE *out, const char *root,
				  uint32_t warmup_count,
				  uint32_t sample_count)
{
	char parent[PATH_MAX];
	char document[PATH_MAX];
	char payload[PATH_MAX];
	int parent_fd = -1;
	int ret;

	ret = afs_rq2_join_path(parent, sizeof(parent), root, "direct-ext4");
	if (!ret)
		ret = afs_rq2_join_path(document, sizeof(document), parent,
					AFS_RQ2_DOCUMENT_ID);
	if (!ret)
		ret = afs_rq2_join_path(payload, sizeof(payload), document,
					AFS_RQ2_DOCUMENT_BASENAME);
	if (!ret && mkdir(parent, 0700))
		ret = -errno;
	if (!ret && mkdir(document, 0700))
		ret = -errno;
	if (!ret)
		ret = afs_rq2_write_payload(payload);
	if (!ret) {
		parent_fd = open(parent, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
		if (parent_fd < 0)
			ret = -errno;
	}
	if (!ret)
		ret = afs_rq2_emit_single_oracle(
			out, "xdg-document-portal", "direct-ext4",
			"direct-before-warmup", parent_fd,
			AFS_RQ2_DOCUMENT_ID);
	if (!ret)
		ret = afs_rq2_run_warmup(parent_fd, AFS_RQ2_DOCUMENT_ID,
					 warmup_count);
	if (!ret)
		ret = afs_rq2_run_measured(
			out, "xdg-document-portal", "direct-ext4", parent_fd,
			AFS_RQ2_DOCUMENT_ID, sample_count);
	if (parent_fd >= 0 && close(parent_fd) && !ret)
		ret = -errno;
	return ret;
}

static int run_rq2_portal_measurement(
	FILE *out, const char *fuse_counter_object,
	const struct stat *mount_status, const char *app_parent,
	const char *document_id, pid_t portal_pid, uint32_t warmup_count,
	uint32_t sample_count, int *preserved_parent_fd)
{
	struct afs_rq2_batch batch = {};
	struct afs_rq2_process_snapshot portal_before = {};
	struct afs_rq2_process_snapshot portal_after = {};
	struct afs_rq2_process_snapshot client_before = {};
	struct afs_rq2_process_snapshot client_after = {};
	struct afs_rq2_fuse_counter counter;
	uint64_t fuse_before = 0;
	uint64_t fuse_after = 0;
	bool counter_open = false;
	int parent_fd = -1;
	int ret;
	int cleanup_ret;

	*preserved_parent_fd = -1;
	if (strlen(document_id) != 22 ||
	    (uint64_t)mount_status->st_dev > UINT32_MAX)
		return -EINVAL;
	parent_fd = open(app_parent, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (parent_fd < 0)
		return -errno;
	ret = afs_rq2_fuse_counter_open(
		&counter, fuse_counter_object, (uint32_t)mount_status->st_dev);
	if (ret)
		goto out;
	counter_open = true;
	fprintf(out,
		"{\"event\":\"application-file-sharing-rq2-fuse-connection\","
		"\"mechanism\":\"xdg-document-portal\","
		"\"connection\":%u,\"major\":%u,\"minor\":%u}\n",
		(uint32_t)mount_status->st_dev,
		major(mount_status->st_dev), minor(mount_status->st_dev));
	ret = afs_rq2_emit_single_oracle(
		out, "xdg-document-portal", "policy-view",
		"first-after-grant", parent_fd, document_id);
	if (!ret)
		ret = afs_rq2_run_warmup(parent_fd, document_id, warmup_count);
	if (!ret)
		ret = afs_rq2_fuse_counter_emit(out, &counter, "before");
	if (!ret)
		ret = afs_rq2_fuse_counter_total(&counter, &fuse_before);
	if (!ret)
		ret = afs_rq2_capture_process_snapshot(&portal_before,
						       portal_pid);
	if (!ret)
		ret = afs_rq2_capture_process_snapshot(&client_before,
						       getpid());
	if (!ret)
		ret = afs_rq2_collect_measured(
			&batch, parent_fd, document_id, sample_count);
	if (!ret)
		ret = afs_rq2_capture_process_snapshot(&client_after,
						       getpid());
	if (!ret)
		ret = afs_rq2_capture_process_snapshot(&portal_after,
						       portal_pid);
	if (!ret)
		ret = afs_rq2_fuse_counter_emit(out, &counter, "after");
	if (!ret)
		ret = afs_rq2_fuse_counter_total(&counter, &fuse_after);
	if (!ret && fuse_after <= fuse_before)
		ret = -ENODATA;
	if (portal_before.thread_count) {
		int emit_ret = afs_rq2_emit_captured_process_snapshot(
			out, "xdg-document-portal", "portal-daemon", "before",
			&portal_before);

		if (emit_ret && !ret)
			ret = emit_ret;
	}
	if (client_before.thread_count) {
		int emit_ret = afs_rq2_emit_captured_process_snapshot(
			out, "xdg-document-portal", "client", "before",
			&client_before);

		if (emit_ret && !ret)
			ret = emit_ret;
	}
	if (client_after.thread_count) {
		int emit_ret = afs_rq2_emit_captured_process_snapshot(
			out, "xdg-document-portal", "client", "after",
			&client_after);

		if (emit_ret && !ret)
			ret = emit_ret;
	}
	if (portal_after.thread_count) {
		int emit_ret = afs_rq2_emit_captured_process_snapshot(
			out, "xdg-document-portal", "portal-daemon", "after",
			&portal_after);

		if (emit_ret && !ret)
			ret = emit_ret;
	}
	if (batch.count) {
		int emit_ret = afs_rq2_emit_batch(
			out, "xdg-document-portal", "policy-view", &batch);

		if (emit_ret && !ret)
			ret = emit_ret;
	}
	fprintf(out,
		"{\"event\":\"application-file-sharing-rq2-fuse-engagement\","
		"\"mechanism\":\"xdg-document-portal\","
		"\"before\":%" PRIu64 ",\"after\":%" PRIu64 ","
		"\"delta\":%" PRIu64 ",\"pass\":%s}\n",
		fuse_before, fuse_after,
		fuse_after >= fuse_before ? fuse_after - fuse_before : 0,
		!ret && fuse_after > fuse_before ? "true" : "false");
	fflush(out);

out:
	afs_rq2_free_batch(&batch);
	afs_rq2_free_process_snapshot(&portal_before);
	afs_rq2_free_process_snapshot(&portal_after);
	afs_rq2_free_process_snapshot(&client_before);
	afs_rq2_free_process_snapshot(&client_after);
	if (counter_open) {
		cleanup_ret = afs_rq2_fuse_counter_close(&counter);
		if (cleanup_ret && !ret)
			ret = cleanup_ret;
	}
	if (ret) {
		if (close(parent_fd) && !ret)
			ret = -errno;
	} else {
		*preserved_parent_fd = parent_fd;
	}
	return ret;
}

int main(int argc, char **argv)
{
	char root[PATH_MAX] = {};
	char home[PATH_MAX] = {};
	char data[PATH_MAX] = {};
	char runtime[PATH_MAX] = {};
	char host_directory[PATH_MAX] = {};
	char host_payload[PATH_MAX] = {};
	char by_app_root[PATH_MAX] = {};
	char permission_stdout[PATH_MAX] = {};
	char permission_stderr[PATH_MAX] = {};
	char portal_stdout[PATH_MAX] = {};
	char portal_stderr[PATH_MAX] = {};
	char saved_payload[PATH_MAX] = {};
	char app_a_parent[PATH_MAX] = {};
	char app_b_parent[PATH_MAX] = {};
	char app_a_document[PATH_MAX] = {};
	char app_b_document[PATH_MAX] = {};
	char app_a_payload[PATH_MAX] = {};
	char app_b_payload[PATH_MAX] = {};
	struct portal_paths app_a_paths;
	struct portal_paths app_b_paths;
	struct stat host_before = {};
	struct stat host_after = {};
	struct stat mount_stat = {};
	GTestDBus *test_bus = NULL;
	GDBusConnection *connection = NULL;
	GError *error = NULL;
	char *mountpoint = NULL;
	char *document_id = NULL;
	pid_t permission_pid = -1;
	pid_t portal_pid = -1;
	int rq2_parent_fd = -1;
	FILE *out = NULL;
	const char *rq2_fuse_counter_object = NULL;
	const char *rq2_fixture_root = NULL;
	uint32_t rq2_warmup_count = 0;
	uint32_t rq2_sample_count = 0;
	bool rq2_mode = false;
	bool source_mounted = false;
	bool mount_present = false;
	bool bytes_expected = false;
	bool root_created = false;
	bool portal_status_valid = false;
	bool permission_status_valid = false;
	int host_after_errno = 0;
	int portal_wait_status = 0;
	int permission_wait_status = 0;
	int states = 0;
	int fails = 0;
	int ret;

	if (argc != 5 && argc != 9) {
		fprintf(stderr,
			"usage: %s XDG_DOCUMENT_PORTAL XDG_PERMISSION_STORE "
			"RESULT_JSONL RESULT_DIR "
			"[FUSE_COUNTER_BPF_O RQ2_WARMUP RQ2_SAMPLES "
			"RQ2_EXT4_ROOT]\n",
			argv[0]);
		return 2;
	}
	if (argc == 9) {
		rq2_mode = true;
		rq2_fuse_counter_object = argv[5];
		rq2_fixture_root = argv[8];
		if (afs_rq2_parse_count(argv[6], &rq2_warmup_count) ||
		    afs_rq2_parse_count(argv[7], &rq2_sample_count)) {
			fprintf(stderr, "invalid RQ2 warmup or sample count\n");
			return 2;
		}
	}
	if (snprintf(root, sizeof(root), "%s/%s",
		     rq2_mode ? rq2_fixture_root : "/tmp",
		     "namei-ext-xdg-source-XXXXXX") >= (int)sizeof(root)) {
		fprintf(stderr, "fixture root path is too long\n");
		return 2;
	}
	out = fopen(argv[3], "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}
	if (!mkdtemp(root)) {
		emit_case(out, "source_fixture", false, errno,
			  "source fixture root creation failed");
		fails++;
		goto cleanup;
	}
	root_created = true;
	if (rq2_mode) {
		ret = afs_rq2_emit_filesystem(
			out, "xdg-document-portal", root);
		if (ret) {
			fails++;
			goto cleanup;
		}
	}
	ret = join_path(home, sizeof(home), root, "home");
	if (!ret)
		ret = join_path(data, sizeof(data), root, "data");
	if (!ret)
		ret = join_path(runtime, sizeof(runtime), root, "runtime");
	if (!ret)
		ret = join_path(host_directory, sizeof(host_directory), root,
				"host-document");
	if (!ret)
		ret = join_path(host_payload, sizeof(host_payload), host_directory,
				DOCUMENT_BASENAME);
	if (!ret)
		ret = join_path(permission_stdout, sizeof(permission_stdout), argv[4],
				"source-permission-store.stdout.log");
	if (!ret)
		ret = join_path(permission_stderr, sizeof(permission_stderr), argv[4],
				"source-permission-store.stderr.log");
	if (!ret)
		ret = join_path(portal_stdout, sizeof(portal_stdout), argv[4],
				"source-portal.stdout.log");
	if (!ret)
		ret = join_path(portal_stderr, sizeof(portal_stderr), argv[4],
				"source-portal.stderr.log");
	if (!ret)
		ret = join_path(saved_payload, sizeof(saved_payload), argv[4],
				"source-host-payload.txt");
	if (!ret)
		ret = make_directory(home);
	if (!ret)
		ret = make_directory(data);
	if (!ret)
		ret = make_directory(runtime);
	if (!ret)
		ret = make_directory(host_directory);
	if (!ret)
		ret = write_text(host_payload, DOCUMENT_PAYLOAD);
	if (!ret && stat(host_payload, &host_before))
		ret = -errno;
	if (ret) {
		emit_case(out, "source_fixture", false, -ret,
			  "source fixture setup failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "source_fixture", true, 0,
		  "fixed host payload and isolated runtime created");
	if (rq2_mode) {
		ret = run_rq2_direct_control(out, root, rq2_warmup_count,
					     rq2_sample_count);
		emit_case(out, "rq2_direct_ext4", !ret, ret ? -ret : 0,
			  ret ? "direct ext4 transaction failed" :
			  "direct ext4 transaction completed");
		fails += !!ret;
		if (ret)
			goto cleanup;
	}

	if (setenv("HOME", home, 1) ||
	    setenv("XDG_DATA_HOME", data, 1) ||
	    setenv("XDG_RUNTIME_DIR", runtime, 1) ||
	    setenv("GIO_USE_VFS", "local", 1)) {
		emit_case(out, "source_environment", false, errno,
			  "isolated source environment setup failed");
		fails++;
		goto cleanup;
	}

	test_bus = g_test_dbus_new(G_TEST_DBUS_NONE);
	g_test_dbus_up(test_bus);
	/* g_test_dbus_up() unsets XDG_RUNTIME_DIR. Match the upstream test setup. */
	if (setenv("XDG_RUNTIME_DIR", runtime, 1)) {
		emit_case(out, "source_environment", false, errno,
			  "source runtime environment restore failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "source_environment", true, 0,
		  "isolated source environment configured");
	connection = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &error);
	if (!connection) {
		log_gerror("private D-Bus connection", error);
		emit_case(out, "private_dbus", false, EIO,
			  "private D-Bus connection failed");
		g_clear_error(&error);
		fails++;
		goto cleanup;
	}
	emit_case(out, "private_dbus", true, 0,
		  "private D-Bus session started");

	permission_pid = spawn_logged(argv[2], permission_stdout,
				      permission_stderr);
	if (permission_pid <= 0 ||
	    wait_for_bus_name(connection,
			      "org.freedesktop.impl.portal.PermissionStore")) {
		emit_case(out, "permission_store", false, EIO,
			  "permission store did not own its D-Bus name");
		fails++;
		goto cleanup;
	}
	emit_case(out, "permission_store", true, 0,
		  "official permission store owns its D-Bus name");

	portal_pid = spawn_logged(argv[1], portal_stdout, portal_stderr);
	if (portal_pid <= 0) {
		emit_case(out, "source_portal", false, errno,
			  "official document portal process did not start");
		fails++;
		goto cleanup;
	}
	ret = wait_for_bus_name(connection, "org.freedesktop.portal.Documents");
	if (ret) {
		emit_case(out, "source_portal", false, -ret,
			  "official document portal did not own its D-Bus name");
		fails++;
		goto cleanup;
	}
	ret = get_mountpoint(connection, &mountpoint);
	if (ret) {
		emit_case(out, "source_portal", false, -ret,
			  "GetMountPoint failed");
		fails++;
		goto cleanup;
	}
	if (stat(mountpoint, &mount_stat)) {
		emit_case(out, "source_portal", false, errno,
			  "document portal mount point was not accessible");
		fails++;
		goto cleanup;
	}
	ret = portal_mount_status(mountpoint, &mount_present);
	if (ret || !mount_present) {
		emit_case(out, "source_portal", false, ret ? -ret : ENODEV,
			  "document portal did not establish a fuse.portal mount");
		fails++;
		goto cleanup;
	}
	source_mounted = true;
	if (!process_running(portal_pid)) {
		emit_case(out, "source_portal", false, ECHILD,
			  "document portal exited after establishing its mount");
		fails++;
		goto cleanup;
	}
	emit_case(out, "source_portal", true, 0,
		  "official document portal FUSE view is active");

	ret = add_document(connection, host_payload, &document_id);
	if (ret) {
		emit_case(out, "source_add", false, -ret,
			  "official Add call failed");
		fails++;
		goto cleanup;
	}
	if (!document_id || !document_id[0]) {
		emit_case(out, "source_add", false, EINVAL,
			  "official Add returned an empty document identifier");
		fails++;
		goto cleanup;
	}
	if (rq2_mode && strlen(document_id) != 22) {
		emit_case(out, "rq2_document_id_length", false, EINVAL,
			  "official Add did not return a 22-byte identifier");
		fails++;
		goto cleanup;
	}
	emit_case(out, "source_add", true, 0,
		  "Add(fd,false,false) exported the existing host payload");

	if (join_path(by_app_root, sizeof(by_app_root), mountpoint, "by-app") ||
	    join_path(app_a_parent, sizeof(app_a_parent), by_app_root, APP_A) ||
	    join_path(app_b_parent, sizeof(app_b_parent), by_app_root, APP_B) ||
	    join_path(app_a_document, sizeof(app_a_document),
		      app_a_parent, document_id) ||
	    join_path(app_b_document, sizeof(app_b_document),
		      app_b_parent, document_id) ||
	    join_path(app_a_payload, sizeof(app_a_payload),
		      app_a_document, DOCUMENT_BASENAME) ||
	    join_path(app_b_payload, sizeof(app_b_payload),
		      app_b_document, DOCUMENT_BASENAME)) {
		emit_case(out, "source_paths", false, ENAMETOOLONG,
			  "portal path construction failed");
		fails++;
		goto cleanup;
	}
	app_a_paths = (struct portal_paths) {
		.parent = app_a_parent,
		.document = app_a_document,
		.payload = app_a_payload,
		.host_payload = host_payload,
		.listed_name = document_id,
	};
	app_b_paths = (struct portal_paths) {
		.parent = app_b_parent,
		.document = app_b_document,
		.payload = app_b_payload,
		.host_payload = host_payload,
		.listed_name = document_id,
	};

	fails += !emit_state(out, "application-a-before-grant", false,
			    &app_a_paths);
	states++;
	fails += !emit_state(out, "application-b-without-grant", false,
			    &app_b_paths);
	states++;

	if (rq2_mode) {
		uint64_t started = afs_rq2_monotonic_raw_ns();

		ret = call_permissions(connection, "GrantPermissions",
				       document_id, APP_A);
		afs_rq2_emit_ack(out, "xdg-document-portal", "grant",
				 afs_rq2_monotonic_raw_ns() - started, ret);
	} else {
		ret = call_permissions(connection, "GrantPermissions",
				       document_id, APP_A);
	}
	if (ret) {
		emit_case(out, "source_grant", false, -ret,
			  "GrantPermissions returned an error");
		fails++;
		goto cleanup;
	}
	if (rq2_mode) {
		ret = run_rq2_portal_measurement(
			out, rq2_fuse_counter_object, &mount_stat, app_a_parent,
			document_id, portal_pid, rq2_warmup_count,
			rq2_sample_count, &rq2_parent_fd);
		emit_case(out, "rq2_portal_measurement", !ret,
			  ret ? -ret : 0,
			  ret ? "official portal measured transaction failed" :
			  "official portal measured transaction completed");
		fails += !!ret;
		if (ret)
			goto cleanup;
	}
	fails += !emit_state(out, "application-a-after-grant", true,
			    &app_a_paths);
	states++;
	emit_case(out, "source_grant", true, 0,
		  "GrantPermissions and application-state validation completed");
	fails += !emit_state(out, "application-b-during-a-grant", false,
			    &app_b_paths);
	states++;

	if (rq2_mode) {
		uint64_t started = afs_rq2_monotonic_raw_ns();

		ret = call_permissions(connection, "RevokePermissions",
				       document_id, APP_A);
		afs_rq2_emit_ack(out, "xdg-document-portal", "revoke",
				 afs_rq2_monotonic_raw_ns() - started, ret);
	} else {
		ret = call_permissions(connection, "RevokePermissions",
				       document_id, APP_A);
	}
	if (ret) {
		emit_case(out, "source_revoke", false, -ret,
			  "RevokePermissions returned an error");
		fails++;
		goto cleanup;
	}
	if (rq2_mode) {
		ret = afs_rq2_emit_hidden_oracle(
			out, "xdg-document-portal", "first-after-revoke",
			rq2_parent_fd, document_id);
		emit_case(out, "rq2_portal_post_revoke", !ret,
			  ret ? -ret : 0,
			  ret ? "post-revoke RQ2 oracle failed" :
			  "post-revoke RQ2 oracle passed");
		fails += !!ret;
		if (close(rq2_parent_fd)) {
			emit_case(out, "rq2_parent_close", false, errno,
				  "pre-opened portal parent close failed");
			fails++;
		}
		rq2_parent_fd = -1;
	}
	fails += !emit_state(out, "application-a-after-revoke", false,
			    &app_a_paths);
	states++;
	emit_case(out, "source_revoke", true, 0,
		  "RevokePermissions and application-state validation completed");

	if (stat(host_payload, &host_after))
		host_after_errno = errno;
	if (!host_after_errno)
		(void)observe_text(host_payload, DOCUMENT_PAYLOAD, &bytes_expected);
	fails += !emit_lower(out, &host_before, &host_after,
			    host_after_errno, bytes_expected);
	ret = copy_file(host_payload, saved_payload);
	emit_case(out, "source_preserve_raw_object", !ret,
		  ret ? -ret : 0,
		  "source host payload saved for host comparison");
	fails += !!ret;

cleanup:
	if (rq2_parent_fd >= 0) {
		ret = close(rq2_parent_fd) ? -errno : 0;
		emit_case(out, "rq2_parent_cleanup", !ret, ret ? -ret : 0,
			  ret ? "pre-opened portal parent cleanup failed" :
			  "pre-opened portal parent closed");
		fails += !!ret;
		rq2_parent_fd = -1;
	}
	if (connection) {
		g_dbus_connection_close_sync(connection, NULL, NULL);
		g_object_unref(connection);
		connection = NULL;
	}
	ret = stop_process(portal_pid, &portal_wait_status,
			   &portal_status_valid);
	fails += !emit_process_exit(out, "xdg-document-portal", portal_pid, ret,
				    portal_wait_status, portal_status_valid);
	if (source_mounted && mountpoint) {
		ret = portal_mount_status(mountpoint, &mount_present);
		if (!ret && mount_present)
			ret = -EBUSY;
		emit_case(out, "source_unmount", !ret, ret ? -ret : 0,
			  ret ? "portal FUSE view remains mounted" :
			  "portal FUSE view is unmounted");
		fails += !!ret;
	}
	ret = stop_process(permission_pid, &permission_wait_status,
			   &permission_status_valid);
	fails += !emit_process_exit(out, "xdg-permission-store",
				    permission_pid, ret,
				    permission_wait_status,
				    permission_status_valid);
	if (test_bus) {
		g_test_dbus_down(test_bus);
		g_object_unref(test_bus);
	}
	free(document_id);
	free(mountpoint);
	ret = root_created ? remove_tree(root) : 0;
	emit_case(out, "source_fixture_cleanup", !ret, ret ? -ret : 0,
		  ret ? "source fixture cleanup failed" :
		  "source fixture removed");
	fails += !!ret;
	if (rq2_mode) {
		fprintf(out,
			"{\"event\":\"application-file-sharing-rq2-summary\","
			"\"mechanism\":\"xdg-document-portal\","
			"\"document_id_bytes\":22,\"payload_bytes\":27,"
			"\"warmup_transactions\":%" PRIu32 ","
			"\"measured_transactions\":%" PRIu32 ","
			"\"direct_transactions\":%" PRIu32 ","
			"\"failures\":%d,\"pass\":%s}\n",
			rq2_warmup_count, rq2_sample_count, rq2_sample_count,
			fails, fails ? "false" : "true");
	}
	fprintf(out,
		"{\"event\":\"application-file-sharing-source-summary\","
		"\"mechanism\":\"xdg-document-portal\","
		"\"states\":%d,\"expected_states\":5,"
		"\"failures\":%d,\"pass\":%s}\n",
		states, fails, fails ? "false" : "true");
	fclose(out);
	return fails ? 1 : 0;
}
