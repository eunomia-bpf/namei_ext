// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <bpf/bpf.h>
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

#define TARGET_V0_APP 1
#define TARGET_V0_CERT 2
#define TARGET_V0_RETIRED 3
#define TARGET_V1_APP 4
#define TARGET_V1_CERT 5
#define TARGET_V1_ADDED 6
#define FILE_COUNT 4
#define PRESERVATION_COUNT 12

enum configmap_publication_counter {
	CONFIGMAP_COUNTER_TOTAL = 0,
	CONFIGMAP_COUNTER_LOOKUP = 1,
	CONFIGMAP_COUNTER_READDIR = 2,
	CONFIGMAP_COUNTER_SELECT = 3,
	CONFIGMAP_COUNTER_PASS = 4,
	CONFIGMAP_COUNTER_HIDE = 5,
};

enum payload_file_index {
	FILE_APP = 0,
	FILE_CERT = 1,
	FILE_RETIRED = 2,
	FILE_ADDED = 3,
};

enum root_entry_mask {
	ROOT_CONFIG = 1U << 0,
	ROOT_TLS = 1U << 1,
	ROOT_RETIRED = 1U << 2,
	ROOT_ADDED = 1U << 3,
	ROOT_PLACEHOLDER = 1U << 4,
};

struct runner_paths {
	const char *result_dir;
	char work[PATH_MAX];
	char lower[PATH_MAX];
	char v0[PATH_MAX];
	char v1[PATH_MAX];
	char view[PATH_MAX];
	char current[PATH_MAX];
	char current_config[PATH_MAX];
	char current_tls[PATH_MAX];
	char current_app[PATH_MAX];
	char current_cert[PATH_MAX];
	char current_retired[PATH_MAX];
	char current_added[PATH_MAX];
	char placeholder[PATH_MAX];
	char cgroup[PATH_MAX];
};

struct file_observation {
	int error;
	struct stat metadata;
	char bytes[64];
	size_t length;
};

struct view_observation {
	struct file_observation files[FILE_COUNT];
	unsigned int root_mask;
	unsigned int root_unexpected;
	unsigned int config_mask;
	unsigned int config_unexpected;
	unsigned int tls_mask;
	unsigned int tls_unexpected;
};

struct preservation_entry {
	char path[PATH_MAX];
	bool regular;
	struct stat before;
	struct stat after;
	char before_bytes[64];
	char after_bytes[64];
	size_t before_length;
	size_t after_length;
};

static const char *const file_relatives[FILE_COUNT] = {
	"config/app.conf",
	"tls/cert.pem",
	"retired.conf",
	"added.conf",
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
	fputs("{\"event\":\"kubernetes-configmap-case\",\"case\":", output);
	json_string(output, name);
	fprintf(output, ",\"pass\":%s,\"errno\":%d,\"detail\":",
		pass ? "true" : "false", error);
	json_string(output, detail);
	fputs("}\n", output);
	fflush(output);
}

static void emit_counter(FILE *output, const char *name, uint64_t value,
			 bool pass)
{
	fputs("{\"event\":\"kubernetes-configmap-counter\",\"counter\":",
	      output);
	json_string(output, name);
	fprintf(output, ",\"value\":%llu,\"pass\":%s}\n",
		(unsigned long long)value, pass ? "true" : "false");
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

static int read_fd_text(int fd, char *buffer, size_t size, size_t *length_out)
{
	size_t length = 0;

	while (length + 1 < size) {
		ssize_t count = read(fd, buffer + length, size - length - 1);

		if (count < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		if (!count)
			break;
		length += (size_t)count;
	}
	if (length + 1 == size) {
		char extra;
		ssize_t count = read(fd, &extra, 1);

		if (count > 0)
			return -EOVERFLOW;
		if (count < 0 && errno != EINTR)
			return -errno;
	}
	buffer[length] = '\0';
	*length_out = length;
	return 0;
}

static int read_file_text(const char *path, char *buffer, size_t size,
			  size_t *length_out)
{
	int fd = open(path, O_RDONLY | O_CLOEXEC);
	int ret;

	if (fd < 0)
		return -errno;
	ret = read_fd_text(fd, buffer, size, length_out);
	if (close(fd) && !ret)
		ret = -errno;
	return ret;
}

static int make_directory(const char *path, mode_t mode)
{
	if (mkdir(path, mode))
		return -errno;
	if (chmod(path, mode))
		return -errno;
	return 0;
}

static int write_file_mode(const char *path, const char *bytes, mode_t mode)
{
	int fd = open(path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, mode);
	int ret;

	if (fd < 0)
		return -errno;
	ret = write_all(fd, bytes, strlen(bytes));
	if (!ret && fchmod(fd, mode))
		ret = -errno;
	if (close(fd) && !ret)
		ret = -errno;
	return ret;
}

static int join(char *destination, const char *directory, const char *name)
{
	return namei_ext_path_join(destination, PATH_MAX, directory, name);
}

static int initialize_paths(struct runner_paths *paths, const char *result_dir,
			    const char *cgroup_root)
{
	paths->result_dir = result_dir;
	if (join(paths->work, result_dir, "namei-ext") ||
	    join(paths->lower, paths->work, "lower") ||
	    join(paths->v0, paths->lower, "v0") ||
	    join(paths->v1, paths->lower, "v1") ||
	    join(paths->view, paths->work, "view") ||
	    join(paths->current, paths->view, "current") ||
	    join(paths->current_config, paths->current, "config") ||
	    join(paths->current_tls, paths->current, "tls") ||
	    join(paths->current_app, paths->current_config, "app.conf") ||
	    join(paths->current_cert, paths->current_tls, "cert.pem") ||
	    join(paths->current_retired, paths->current, "retired.conf") ||
	    join(paths->current_added, paths->current, "added.conf") ||
	    join(paths->placeholder, paths->current, "placeholder"))
		return -ENAMETOOLONG;
	if (snprintf(paths->cgroup, sizeof(paths->cgroup),
		     "%s/namei-ext-configmap-%ld", cgroup_root,
		     (long)getpid()) >= (int)sizeof(paths->cgroup))
		return -ENAMETOOLONG;
	return 0;
}

static int setup_generation(const char *root, bool second)
{
	char config[PATH_MAX];
	char tls[PATH_MAX];
	char app[PATH_MAX];
	char cert[PATH_MAX];
	char optional[PATH_MAX];
	int ret;

	if (join(config, root, "config") || join(tls, root, "tls") ||
	    join(app, config, "app.conf") ||
	    join(cert, tls, "cert.pem") ||
	    join(optional, root, second ? "added.conf" : "retired.conf"))
		return -ENAMETOOLONG;
	ret = make_directory(root, 0755);
	if (!ret)
		ret = make_directory(config, 0755);
	if (!ret)
		ret = make_directory(tls, 0755);
	if (!ret)
		ret = write_file_mode(app,
			second ? "version=1\n" : "version=0\n",
			second ? 0600 : 0644);
	if (!ret)
		ret = write_file_mode(cert,
			second ? "certificate-v1\n" : "certificate-v0\n",
			0400);
	if (!ret)
		ret = write_file_mode(optional,
			second ? "added\n" : "retired\n", 0644);
	return ret;
}

static int setup_fixture(struct runner_paths *paths)
{
	int ret = make_directory(paths->work, 0755);

	if (!ret)
		ret = make_directory(paths->lower, 0755);
	if (!ret)
		ret = setup_generation(paths->v0, false);
	if (!ret)
		ret = setup_generation(paths->v1, true);
	if (!ret)
		ret = make_directory(paths->view, 0755);
	if (!ret)
		ret = make_directory(paths->current, 0755);
	if (!ret)
		ret = make_directory(paths->current_config, 0755);
	if (!ret)
		ret = make_directory(paths->current_tls, 0755);
	if (!ret)
		ret = write_file_mode(paths->current_app,
				      "logical-placeholder\n", 0644);
	if (!ret)
		ret = write_file_mode(paths->current_cert,
				      "logical-placeholder\n", 0644);
	if (!ret)
		ret = write_file_mode(paths->current_retired,
				      "logical-placeholder\n", 0644);
	if (!ret)
		ret = write_file_mode(paths->current_added,
				      "logical-placeholder\n", 0644);
	if (!ret)
		ret = write_file_mode(paths->placeholder,
				      "unmanaged-placeholder\n", 0644);
	return ret;
}

static int capture_file(const char *path, struct file_observation *observation)
{
	int ret;

	memset(observation, 0, sizeof(*observation));
	if (stat(path, &observation->metadata)) {
		observation->error = errno;
		return errno == ENOENT ? 0 : -errno;
	}
	if (!S_ISREG(observation->metadata.st_mode))
		return -EINVAL;
	ret = read_file_text(path, observation->bytes,
			     sizeof(observation->bytes), &observation->length);
	if (ret)
		return ret;
	return 0;
}

static int list_directory(const char *path, unsigned int *mask,
			  unsigned int *unexpected, bool root)
{
	DIR *directory = opendir(path);
	struct dirent *entry;

	if (!directory)
		return -errno;
	*mask = 0;
	*unexpected = 0;
	errno = 0;
	while ((entry = readdir(directory))) {
		if (!strcmp(entry->d_name, ".") || !strcmp(entry->d_name, ".."))
			continue;
		if (root && !strcmp(entry->d_name, "config"))
			*mask |= ROOT_CONFIG;
		else if (root && !strcmp(entry->d_name, "tls"))
			*mask |= ROOT_TLS;
		else if (root && !strcmp(entry->d_name, "retired.conf"))
			*mask |= ROOT_RETIRED;
		else if (root && !strcmp(entry->d_name, "added.conf"))
			*mask |= ROOT_ADDED;
		else if (root && !strcmp(entry->d_name, "placeholder"))
			*mask |= ROOT_PLACEHOLDER;
		else if (!root && !strcmp(entry->d_name, "app.conf"))
			*mask |= 1U;
		else if (!root && !strcmp(entry->d_name, "cert.pem"))
			*mask |= 1U;
		else
			(*unexpected)++;
	}
	int saved_errno = errno;
	int close_ret = closedir(directory);

	if (saved_errno)
		return -saved_errno;
	if (close_ret)
		return -errno;
	return 0;
}

static int capture_view(const char *root, struct view_observation *view)
{
	char path[PATH_MAX];
	char config[PATH_MAX];
	char tls[PATH_MAX];
	int ret = 0;

	memset(view, 0, sizeof(*view));
	for (size_t index = 0; index < FILE_COUNT; index++) {
		if (join(path, root, file_relatives[index]))
			return -ENAMETOOLONG;
		ret = capture_file(path, &view->files[index]);
		if (ret)
			return ret;
	}
	if (join(config, root, "config") || join(tls, root, "tls"))
		return -ENAMETOOLONG;
	ret = list_directory(root, &view->root_mask,
			     &view->root_unexpected, true);
	if (!ret)
		ret = list_directory(config, &view->config_mask,
				     &view->config_unexpected, false);
	if (!ret)
		ret = list_directory(tls, &view->tls_mask,
				     &view->tls_unexpected, false);
	return ret;
}

static bool metadata_matches(const struct stat *actual,
			     const struct stat *expected)
{
	return actual->st_dev == expected->st_dev &&
		actual->st_ino == expected->st_ino &&
		actual->st_mode == expected->st_mode &&
		actual->st_uid == expected->st_uid &&
		actual->st_gid == expected->st_gid &&
		actual->st_size == expected->st_size;
}

static bool file_matches(const struct file_observation *actual,
			 const struct file_observation *expected, bool present)
{
	if (!present)
		return actual->error == ENOENT;
	return actual->error == 0 && expected->error == 0 &&
		metadata_matches(&actual->metadata, &expected->metadata) &&
		actual->length == expected->length &&
		!memcmp(actual->bytes, expected->bytes, actual->length);
}

static bool file_matches_payload(const struct file_observation *actual,
				 const char *bytes, mode_t mode, bool present)
{
	if (!present)
		return actual->error == ENOENT;
	return actual->error == 0 &&
		S_ISREG(actual->metadata.st_mode) &&
		(actual->metadata.st_mode & 07777) == mode &&
		actual->length == strlen(bytes) &&
		!memcmp(actual->bytes, bytes, actual->length);
}

static bool view_matches_payload(const struct view_observation *view,
				 bool second)
{
	unsigned int root_mask = ROOT_CONFIG | ROOT_TLS |
		(second ? ROOT_ADDED : ROOT_RETIRED);

	return file_matches_payload(&view->files[FILE_APP],
				    second ? "version=1\n" : "version=0\n",
				    second ? 0600 : 0644, true) &&
		file_matches_payload(&view->files[FILE_CERT],
				     second ? "certificate-v1\n" :
					      "certificate-v0\n",
				     0400, true) &&
		file_matches_payload(&view->files[FILE_RETIRED],
				     "retired\n", 0644, !second) &&
		file_matches_payload(&view->files[FILE_ADDED],
				     "added\n", 0644, second) &&
		view->root_mask == root_mask &&
		view->root_unexpected == 0 &&
		view->config_mask == 1U &&
		view->config_unexpected == 0 &&
		view->tls_mask == 1U &&
		view->tls_unexpected == 0;
}

static bool view_matches(const struct view_observation *actual,
			 const struct view_observation *expected, bool second)
{
	return file_matches(&actual->files[FILE_APP],
			    &expected->files[FILE_APP], true) &&
		file_matches(&actual->files[FILE_CERT],
			     &expected->files[FILE_CERT], true) &&
		file_matches(&actual->files[FILE_RETIRED],
			     &expected->files[FILE_RETIRED], !second) &&
		file_matches(&actual->files[FILE_ADDED],
			     &expected->files[FILE_ADDED], second) &&
		view_matches_payload(actual, second);
}

static bool view_owned_by(const struct view_observation *view, bool second,
			  uid_t uid, gid_t gid)
{
	for (size_t index = 0; index < FILE_COUNT; index++) {
		bool present = index == FILE_APP || index == FILE_CERT ||
			(index == FILE_RETIRED && !second) ||
			(index == FILE_ADDED && second);

		if (!present)
			continue;
		if (view->files[index].error ||
		    view->files[index].metadata.st_uid != uid ||
		    view->files[index].metadata.st_gid != gid)
			return false;
	}
	return true;
}

static int wait_child(pid_t pid, int *exit_code)
{
	int status;

	while (waitpid(pid, &status, 0) < 0) {
		if (errno != EINTR)
			return -errno;
	}
	if (WIFEXITED(status)) {
		*exit_code = WEXITSTATUS(status);
		return 0;
	}
	if (WIFSIGNALED(status)) {
		*exit_code = 128 + WTERMSIG(status);
		return 0;
	}
	return -ECHILD;
}

static int run_consumer(const char *root, const char *result_dir,
			const char *state, const char *expected,
			uid_t runtime_uid, gid_t runtime_gid,
			int *exit_code_out, char *observed, size_t size)
{
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	char leaf[128];
	pid_t pid;
	int ret;

	if (snprintf(leaf, sizeof(leaf), "cat-%s.stdout.log", state) >=
		    (int)sizeof(leaf) ||
	    join(stdout_path, result_dir, leaf) ||
	    snprintf(leaf, sizeof(leaf), "cat-%s.stderr.log", state) >=
		    (int)sizeof(leaf) ||
	    join(stderr_path, result_dir, leaf))
		return -ENAMETOOLONG;
	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		int stdout_fd = open(stdout_path,
				     O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC,
				     0644);
		int stderr_fd = open(stderr_path,
				     O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC,
				     0644);

		if (stdout_fd < 0 || stderr_fd < 0 ||
		    dup2(stdout_fd, STDOUT_FILENO) < 0 ||
		    dup2(stderr_fd, STDERR_FILENO) < 0)
			_exit(120);
		close(stdout_fd);
		close(stderr_fd);
		if (setgroups(0, NULL) ||
		    setresgid(runtime_gid, runtime_gid, runtime_gid) ||
		    setresuid(runtime_uid, runtime_uid, runtime_uid) ||
		    getuid() != runtime_uid || geteuid() != runtime_uid ||
		    getgid() != runtime_gid || getegid() != runtime_gid)
			_exit(119);
		execl("/bin/sh", "sh", "-c",
		      "cat \"$1/config/app.conf\" && "
		      "exec cat \"$1/tls/cert.pem\"",
		      "sh", root,
		      (char *)NULL);
		_exit(121);
	}
	ret = wait_child(pid, exit_code_out);
	if (ret)
		return ret;
	size_t length = 0;
	ret = read_file_text(stdout_path, observed, size, &length);
	if (ret)
		return ret;
	char stderr_text[64];
	size_t stderr_length = 0;
	ret = read_file_text(stderr_path, stderr_text, sizeof(stderr_text),
			     &stderr_length);
	if (ret)
		return ret;
	if (*exit_code_out || stderr_length || strcmp(observed, expected))
		return -EINVAL;
	return 0;
}

static void emit_state_file(FILE *output, size_t index,
			    const struct file_observation *actual,
			    const struct file_observation *expected)
{
	fputs("{\"path\":", output);
	json_string(output, file_relatives[index]);
	fprintf(output,
		",\"errno\":%d,\"bytes\":", actual->error);
	json_string(output, actual->bytes);
	fprintf(output,
		",\"mode\":%u,\"uid\":%u,\"gid\":%u,\"dev\":%llu,"
		"\"ino\":%llu,\"size\":%lld,\"expected_errno\":%d,"
		"\"expected_dev\":%llu,\"expected_ino\":%llu}",
		(unsigned int)(actual->metadata.st_mode & 07777),
		(unsigned int)actual->metadata.st_uid,
		(unsigned int)actual->metadata.st_gid,
		(unsigned long long)actual->metadata.st_dev,
		(unsigned long long)actual->metadata.st_ino,
		(long long)actual->metadata.st_size, expected->error,
		(unsigned long long)expected->metadata.st_dev,
		(unsigned long long)expected->metadata.st_ino);
}

static void emit_state(FILE *output, const char *mechanism,
		       const char *state, uint32_t generation,
		       const struct view_observation *view,
		       const struct view_observation *expected,
		       uid_t runtime_uid, gid_t runtime_gid,
		       int consumer_exit, const char *consumer_output,
		       bool pass)
{
	fputs("{\"event\":\"kubernetes-configmap-state\",\"mechanism\":",
	      output);
	json_string(output, mechanism);
	fputs(",\"state\":", output);
	json_string(output, state);
	fprintf(output,
		",\"generation\":%u,\"root_mask\":%u,"
		"\"root_unexpected\":%u,\"config_mask\":%u,"
		"\"config_unexpected\":%u,\"tls_mask\":%u,"
		"\"tls_unexpected\":%u,\"runtime_uid\":%u,"
		"\"runtime_gid\":%u,\"files\":[",
		generation, view->root_mask, view->root_unexpected,
		view->config_mask, view->config_unexpected,
		view->tls_mask, view->tls_unexpected,
		(unsigned int)runtime_uid, (unsigned int)runtime_gid);
	for (size_t index = 0; index < FILE_COUNT; index++) {
		if (index)
			fputc(',', output);
		emit_state_file(output, index, &view->files[index],
				&expected->files[index]);
	}
	fprintf(output, "],\"consumer_exit\":%d,\"consumer_stdout\":",
		consumer_exit);
	json_string(output, consumer_output);
	fprintf(output, ",\"pass\":%s}\n", pass ? "true" : "false");
	fflush(output);
}

static int run_state(FILE *output, const char *mechanism,
		     const char *state, uint32_t generation,
		     const char *root, const struct view_observation *expected,
		     bool second, const char *result_dir,
		     uid_t runtime_uid, gid_t runtime_gid,
		     struct view_observation *captured)
{
	char consumer_output[64] = {};
	int consumer_exit = -1;
	int ret = capture_view(root, captured);

	if (!ret)
		ret = run_consumer(root, result_dir, state,
				   second ?
					"version=1\ncertificate-v1\n" :
					"version=0\ncertificate-v0\n",
				   runtime_uid, runtime_gid,
				   &consumer_exit, consumer_output,
				   sizeof(consumer_output));
	bool pass = !ret && view_matches(captured, expected, second) &&
		view_matches_payload(expected, second) &&
		view_owned_by(captured, second, runtime_uid, runtime_gid) &&
		view_owned_by(expected, second, runtime_uid, runtime_gid);

	emit_state(output, mechanism, state, generation, captured, expected,
		   runtime_uid, runtime_gid, consumer_exit, consumer_output, pass);
	return pass ? 0 : (ret ? ret : -EINVAL);
}

static int map_fd(struct namei_ext_harness_policy *policy,
		  const char *map_name)
{
	struct bpf_map *map = bpf_object__find_map_by_name(policy->obj, map_name);
	int fd;

	if (!map)
		return -ENOENT;
	fd = bpf_map__fd(map);
	return fd < 0 ? -EINVAL : fd;
}

static int set_generation(struct namei_ext_harness_policy *policy,
			  uint64_t cgroup_id, uint32_t generation,
			  bool present)
{
	int fd = map_fd(policy, "configmap_publication_generations");

	if (fd < 0)
		return fd;
	if (present) {
		if (generation > 1)
			return -EINVAL;
		if (bpf_map_update_elem(fd, &cgroup_id, &generation, BPF_ANY))
			return -errno;
	} else if (bpf_map_delete_elem(fd, &cgroup_id) && errno != ENOENT) {
		return -errno;
	}
	return 0;
}

static int configure_view_map(struct namei_ext_harness_policy *policy,
			      const char *map_name, uint64_t cgroup_id,
			      const struct runner_paths *paths, bool second)
{
	static const char *const names[] = {
		"app.conf", "cert.pem", "retired.conf", "added.conf",
		"placeholder",
	};
	const char *const parents[] = {
		paths->current_config, paths->current_tls, paths->current,
		paths->current, paths->current,
	};
	const uint32_t v0_targets[] = {
		TARGET_V0_APP, TARGET_V0_CERT, TARGET_V0_RETIRED, 0, 0,
	};
	const uint32_t v1_targets[] = {
		TARGET_V1_APP, TARGET_V1_CERT, 0, TARGET_V1_ADDED, 0,
	};
	const uint32_t *targets = second ? v1_targets : v0_targets;

	for (size_t index = 0; index < sizeof(names) / sizeof(names[0]);
	     index++) {
		int ret = namei_ext_component_map_update(
			policy, map_name, cgroup_id, parents[index],
			names[index], targets[index]);

		if (ret)
			return ret;
	}
	return 0;
}

static int configure_view_maps(struct namei_ext_harness_policy *policy,
			       uint64_t cgroup_id,
			       const struct runner_paths *paths)
{
	int ret = configure_view_map(policy, "configmap_publication_v0_views",
				     cgroup_id, paths, false);

	if (!ret)
		ret = configure_view_map(policy,
					 "configmap_publication_v1_views",
					 cgroup_id, paths, true);
	return ret;
}

static int delete_view_map(struct namei_ext_harness_policy *policy,
			   const char *map_name, uint64_t cgroup_id,
			   const struct runner_paths *paths)
{
	static const char *const names[] = {
		"app.conf", "cert.pem", "retired.conf", "added.conf",
		"placeholder",
	};
	const char *const parents[] = {
		paths->current_config, paths->current_tls, paths->current,
		paths->current, paths->current,
	};
	int first_error = 0;

	for (size_t index = 0; index < sizeof(names) / sizeof(names[0]);
	     index++) {
		int ret = namei_ext_component_map_delete(
			policy, map_name, cgroup_id, parents[index],
			names[index]);

		if (ret && !first_error)
			first_error = ret;
	}
	return first_error;
}

static int delete_view_maps(struct namei_ext_harness_policy *policy,
			    uint64_t cgroup_id,
			    const struct runner_paths *paths)
{
	int first_error = delete_view_map(
		policy, "configmap_publication_v0_views", cgroup_id, paths);
	int ret = delete_view_map(
		policy, "configmap_publication_v1_views", cgroup_id, paths);

	return first_error ? first_error : ret;
}

static int capture_old_fd(FILE *output, int fd, const struct stat *initial,
			  const char *stage)
{
	char bytes[64] = {};
	size_t length = 0;
	struct stat current = {};
	int ret = lseek(fd, 0, SEEK_SET) < 0 ? -errno : 0;

	if (!ret)
		ret = read_fd_text(fd, bytes, sizeof(bytes), &length);
	if (!ret && fstat(fd, &current))
		ret = -errno;
	bool pass = !ret && length == strlen("version=0\n") &&
		!memcmp(bytes, "version=0\n", length) &&
		current.st_dev == initial->st_dev &&
		current.st_ino == initial->st_ino;

	fputs("{\"event\":\"kubernetes-configmap-old-fd\","
	      "\"mechanism\":\"namei_ext\",\"stage\":", output);
	json_string(output, stage);
	fprintf(output,
		",\"bytes\":");
	json_string(output, bytes);
	fprintf(output,
		",\"initial_dev\":%llu,\"initial_ino\":%llu,"
		"\"current_dev\":%llu,\"current_ino\":%llu,\"pass\":%s}\n",
		(unsigned long long)initial->st_dev,
		(unsigned long long)initial->st_ino,
		(unsigned long long)current.st_dev,
		(unsigned long long)current.st_ino,
		pass ? "true" : "false");
	fflush(output);
	return pass ? 0 : (ret ? ret : -EINVAL);
}

static int capture_dirfd_lookup(FILE *output, int root_fd,
				const struct stat *initial_root,
				const struct file_observation *expected,
				const char *state)
{
	struct stat current_root = {};
	struct stat file_metadata = {};
	char bytes[64] = {};
	size_t length = 0;
	int file_fd = -1;
	int ret = fstat(root_fd, &current_root) ? -errno : 0;

	if (!ret) {
		file_fd = openat(root_fd, "config/app.conf",
				 O_RDONLY | O_CLOEXEC);
		if (file_fd < 0)
			ret = -errno;
	}
	if (!ret)
		ret = read_fd_text(file_fd, bytes, sizeof(bytes), &length);
	if (!ret && fstat(file_fd, &file_metadata))
		ret = -errno;
	if (file_fd >= 0 && close(file_fd) && !ret)
		ret = -errno;

	bool pass = !ret &&
		current_root.st_dev == initial_root->st_dev &&
		current_root.st_ino == initial_root->st_ino &&
		expected->error == 0 &&
		metadata_matches(&file_metadata, &expected->metadata) &&
		length == expected->length &&
		!memcmp(bytes, expected->bytes, length);

	fputs("{\"event\":\"kubernetes-configmap-dirfd\","
	      "\"mechanism\":\"namei_ext\",\"state\":", output);
	json_string(output, state);
	fputs(",\"bytes\":", output);
	json_string(output, bytes);
	fprintf(output,
		",\"errno\":%d,\"mode\":%u,\"root_initial_dev\":%llu,"
		"\"root_initial_ino\":%llu,\"root_current_dev\":%llu,"
		"\"root_current_ino\":%llu,\"file_dev\":%llu,"
		"\"file_ino\":%llu,\"expected_file_dev\":%llu,"
		"\"expected_file_ino\":%llu,\"pass\":%s}\n",
		ret ? -ret : 0,
		(unsigned int)(file_metadata.st_mode & 07777),
		(unsigned long long)initial_root->st_dev,
		(unsigned long long)initial_root->st_ino,
		(unsigned long long)current_root.st_dev,
		(unsigned long long)current_root.st_ino,
		(unsigned long long)file_metadata.st_dev,
		(unsigned long long)file_metadata.st_ino,
		(unsigned long long)expected->metadata.st_dev,
		(unsigned long long)expected->metadata.st_ino,
		pass ? "true" : "false");
	fflush(output);
	return pass ? 0 : (ret ? ret : -EINVAL);
}

static int setup_preservation_entries(const struct runner_paths *paths,
				      struct preservation_entry *entries)
{
	static const struct {
		const char *generation;
		const char *relative;
		bool regular;
	} specifications[PRESERVATION_COUNT] = {
		{ "v0", "", false },
		{ "v0", "config", false },
		{ "v0", "tls", false },
		{ "v0", "config/app.conf", true },
		{ "v0", "tls/cert.pem", true },
		{ "v0", "retired.conf", true },
		{ "v1", "", false },
		{ "v1", "config", false },
		{ "v1", "tls", false },
		{ "v1", "config/app.conf", true },
		{ "v1", "tls/cert.pem", true },
		{ "v1", "added.conf", true },
	};

	for (size_t index = 0; index < PRESERVATION_COUNT; index++) {
		const char *root = !strcmp(specifications[index].generation, "v0") ?
			paths->v0 : paths->v1;

		entries[index].regular = specifications[index].regular;
		if (!*specifications[index].relative) {
			if (snprintf(entries[index].path,
				     sizeof(entries[index].path), "%s", root) >=
			    (int)sizeof(entries[index].path))
				return -ENAMETOOLONG;
		} else if (join(entries[index].path, root,
				specifications[index].relative)) {
			return -ENAMETOOLONG;
		}
	}
	return 0;
}

static int capture_preservation(struct preservation_entry *entries,
				bool before)
{
	for (size_t index = 0; index < PRESERVATION_COUNT; index++) {
		struct stat *metadata = before ? &entries[index].before :
			&entries[index].after;
		char *bytes = before ? entries[index].before_bytes :
			entries[index].after_bytes;
		size_t *length = before ? &entries[index].before_length :
			&entries[index].after_length;

		if (stat(entries[index].path, metadata))
			return -errno;
		if (entries[index].regular) {
			int ret = read_file_text(entries[index].path, bytes, 64,
						 length);
			if (ret)
				return ret;
		}
	}
	return 0;
}

static bool preserved_entry_matches(const struct preservation_entry *entry)
{
	const struct stat *before = &entry->before;
	const struct stat *after = &entry->after;

	if (before->st_mode != after->st_mode ||
	    before->st_uid != after->st_uid ||
	    before->st_gid != after->st_gid ||
	    before->st_dev != after->st_dev ||
	    before->st_ino != after->st_ino ||
	    before->st_size != after->st_size ||
	    before->st_mtim.tv_sec != after->st_mtim.tv_sec ||
	    before->st_mtim.tv_nsec != after->st_mtim.tv_nsec ||
	    before->st_ctim.tv_sec != after->st_ctim.tv_sec ||
	    before->st_ctim.tv_nsec != after->st_ctim.tv_nsec)
		return false;
	if (entry->regular &&
	    (entry->before_length != entry->after_length ||
	     memcmp(entry->before_bytes, entry->after_bytes,
		    entry->before_length)))
		return false;
	return true;
}

static int write_preservation_tsv(const char *path,
				  const struct preservation_entry *entries,
				  bool before)
{
	FILE *output = fopen(path, "w");

	if (!output)
		return -errno;
	for (size_t index = 0; index < PRESERVATION_COUNT; index++) {
		const struct stat *metadata = before ? &entries[index].before :
			&entries[index].after;

		fprintf(output,
			"%s\t%o\t%u\t%u\t%llu\t%llu\t%lld\t%lld.%09ld\t%lld.%09ld\n",
			entries[index].path,
			(unsigned int)metadata->st_mode,
			(unsigned int)metadata->st_uid,
			(unsigned int)metadata->st_gid,
			(unsigned long long)metadata->st_dev,
			(unsigned long long)metadata->st_ino,
			(long long)metadata->st_size,
			(long long)metadata->st_mtim.tv_sec,
			metadata->st_mtim.tv_nsec,
			(long long)metadata->st_ctim.tv_sec,
			metadata->st_ctim.tv_nsec);
	}
	if (fclose(output))
		return -errno;
	return 0;
}

static int emit_preservation(FILE *output,
			     const struct preservation_entry *entries)
{
	int failures = 0;

	for (size_t index = 0; index < PRESERVATION_COUNT; index++) {
		bool pass = preserved_entry_matches(&entries[index]);

		fputs("{\"event\":\"kubernetes-configmap-lower\","
		      "\"path\":", output);
		json_string(output, entries[index].path);
		fprintf(output,
			",\"regular\":%s,\"before_mode\":%u,"
			"\"after_mode\":%u,\"before_dev\":%llu,"
			"\"after_dev\":%llu,\"before_ino\":%llu,"
			"\"after_ino\":%llu,\"before_bytes\":",
			entries[index].regular ? "true" : "false",
			(unsigned int)entries[index].before.st_mode,
			(unsigned int)entries[index].after.st_mode,
			(unsigned long long)entries[index].before.st_dev,
			(unsigned long long)entries[index].after.st_dev,
			(unsigned long long)entries[index].before.st_ino,
			(unsigned long long)entries[index].after.st_ino);
		json_string(output, entries[index].before_bytes);
		fputs(",\"after_bytes\":", output);
		json_string(output, entries[index].after_bytes);
		fprintf(output, ",\"pass\":%s}\n",
			pass ? "true" : "false");
		failures += !pass;
	}
	fflush(output);
	return failures ? -EIO : 0;
}

static int unmanaged_control(const struct runner_paths *paths)
{
	struct stat metadata;
	unsigned int root_mask;
	unsigned int root_unexpected;
	unsigned int config_mask;
	unsigned int config_unexpected;
	unsigned int tls_mask;
	unsigned int tls_unexpected;
	char bytes[64];
	size_t length = 0;
	int ret;

	if (stat(paths->placeholder, &metadata))
		return -errno;
	if (!S_ISREG(metadata.st_mode))
		return -EINVAL;
	ret = read_file_text(paths->current_app, bytes, sizeof(bytes), &length);
	if (ret || strcmp(bytes, "logical-placeholder\n"))
		return -EINVAL;
	if (list_directory(paths->current, &root_mask, &root_unexpected, true))
		return -EINVAL;
	if (list_directory(paths->current_config, &config_mask,
			   &config_unexpected, false) ||
	    list_directory(paths->current_tls, &tls_mask,
			   &tls_unexpected, false))
		return -EINVAL;
	return root_mask == (ROOT_CONFIG | ROOT_TLS | ROOT_RETIRED |
			     ROOT_ADDED | ROOT_PLACEHOLDER) &&
		root_unexpected == 0 && config_mask == 1U &&
		config_unexpected == 0 && tls_mask == 1U &&
		tls_unexpected == 0 ? 0 : -EINVAL;
}

static int register_targets(const struct runner_paths *paths)
{
	char target[PATH_MAX];
	static const struct {
		bool second;
		const char *relative;
		uint32_t id;
	} specifications[] = {
		{ false, "config/app.conf", TARGET_V0_APP },
		{ false, "tls/cert.pem", TARGET_V0_CERT },
		{ false, "retired.conf", TARGET_V0_RETIRED },
		{ true, "config/app.conf", TARGET_V1_APP },
		{ true, "tls/cert.pem", TARGET_V1_CERT },
		{ true, "added.conf", TARGET_V1_ADDED },
	};

	for (size_t index = 0;
	     index < sizeof(specifications) / sizeof(specifications[0]);
	     index++) {
		const char *root = specifications[index].second ?
			paths->v1 : paths->v0;
		int ret;

		if (join(target, root, specifications[index].relative))
			return -ENAMETOOLONG;
		ret = namei_ext_register_target(paths->cgroup, target,
						specifications[index].id);
		if (ret)
			return ret;
	}
	return 0;
}

static int normalize_libbpf_result(int result, int saved_errno)
{
	if (!result)
		return 0;
	if (result == -1 && saved_errno)
		return -saved_errno;
	return result < 0 ? result : -result;
}

static int counter(FILE *output, struct namei_ext_harness_policy *policy,
		   const char *name, uint32_t key)
{
	uint64_t value = 0;
	int ret = namei_ext_policy_counter(
		policy, "configmap_publication_counters", key, &value);
	bool pass = !ret && value > 0;

	emit_counter(output, name, value, pass);
	return pass ? 0 : (ret ? ret : -ERANGE);
}

int main(int argc, char **argv)
{
	const char *cgroup_root = "/sys/fs/cgroup";
	struct namei_ext_harness_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	struct runner_paths paths = {};
	struct view_observation expected_v0 = {};
	struct view_observation expected_v1 = {};
	struct view_observation direct_v0 = {};
	struct view_observation direct_v1 = {};
	struct view_observation initial = {};
	struct view_observation update = {};
	struct view_observation no_op = {};
	struct view_observation rollback = {};
	struct preservation_entry preserved[PRESERVATION_COUNT] = {};
	struct stat result_metadata = {};
	char before_tsv[PATH_MAX];
	char after_tsv[PATH_MAX];
	uint64_t cgroup_id = 0;
	uid_t runtime_uid;
	gid_t runtime_gid;
	FILE *output = NULL;
	bool cgroup_created = false;
	bool targets_registered = false;
	bool policy_attached = false;
	bool in_managed_cgroup = false;
	bool generation_set = false;
	bool views_configured = false;
	bool preservation_ready = false;
	int old_fd = -1;
	int root_fd = -1;
	struct stat old_stat = {};
	struct stat root_stat = {};
	int failures = 0;
	int ret;

	if (argc < 4 || argc > 5) {
		fprintf(stderr,
			"usage: %s POLICY RESULT_JSONL RESULT_DIR [CGROUP_ROOT]\n",
			argv[0]);
		return 2;
	}
	if (argc == 5)
		cgroup_root = argv[4];
	if (stat(argv[3], &result_metadata)) {
		ret = -errno;
		goto fatal;
	}
	runtime_uid = result_metadata.st_uid;
	runtime_gid = result_metadata.st_gid;
	if (!runtime_uid || !runtime_gid) {
		ret = -EINVAL;
		goto fatal;
	}
	ret = initialize_paths(&paths, argv[3], cgroup_root);
	if (ret)
		goto fatal;
	output = fopen(argv[2], "a");
	if (!output) {
		ret = -errno;
		goto fatal;
	}
	ret = setup_fixture(&paths);
	emit_case(output, "setup_fixture", !ret, ret ? -ret : 0,
		  "two complete generations and one stable logical payload root created");
	if (ret) {
		failures++;
		goto cleanup;
	}
	if (join(before_tsv, paths.result_dir, "lower-before.tsv") ||
	    join(after_tsv, paths.result_dir, "lower-after.tsv")) {
		ret = -ENAMETOOLONG;
		failures++;
		goto cleanup;
	}
	ret = setup_preservation_entries(&paths, preserved);
	if (!ret)
		ret = capture_preservation(preserved, true);
	if (!ret)
		ret = write_preservation_tsv(before_tsv, preserved, true);
	emit_case(output, "capture_lower_before", !ret, ret ? -ret : 0,
		  "pre-existing V0 and V1 lower objects captured without atime");
	if (ret) {
		failures++;
		goto cleanup;
	}
	preservation_ready = true;

	ret = capture_view(paths.v0, &expected_v0);
	if (!ret && !view_matches_payload(&expected_v0, false))
		ret = -EINVAL;
	if (!ret)
		ret = capture_view(paths.v1, &expected_v1);
	if (!ret && !view_matches_payload(&expected_v1, true))
		ret = -EINVAL;
	emit_case(output, "validate_expected_generations", !ret,
		  ret ? -ret : 0,
		  "V0 and V1 lower generations match the fixed payload oracle");
	if (ret) {
		failures++;
		goto cleanup;
	}

	ret = run_state(output, "direct", "physical-v0", 0, paths.v0,
			&expected_v0, false, paths.result_dir,
			runtime_uid, runtime_gid, &direct_v0);
	failures += !!ret;
	ret = run_state(output, "direct", "physical-v1", 1, paths.v1,
			&expected_v1, true, paths.result_dir,
			runtime_uid, runtime_gid, &direct_v1);
	failures += !!ret;

	ret = unmanaged_control(&paths);
	emit_case(output, "unmanaged_before", !ret, ret ? -ret : 0,
		  "unmanaged process observed the stable placeholder tree");
	if (ret) {
		failures++;
		goto cleanup;
	}
	if (mkdir(paths.cgroup, 0755)) {
		ret = -errno;
		failures++;
		emit_case(output, "create_cgroup", false, -ret,
			  "managed cgroup creation failed");
		goto cleanup;
	}
	cgroup_created = true;
	emit_case(output, "create_cgroup", true, 0,
		  "managed cgroup created");
	ret = namei_ext_cgroup_id(paths.cgroup, &cgroup_id);
	if (ret) {
		failures++;
		emit_case(output, "cgroup_identity", false, -ret,
			  "managed cgroup identity failed");
		goto cleanup;
	}
	emit_case(output, "cgroup_identity", true, 0,
		  "managed cgroup identity captured");
	targets_registered = true;
	ret = register_targets(&paths);
	emit_case(output, "register_generations", !ret, ret ? -ret : 0,
		  "six V0 and V1 payload files registered");
	if (ret) {
		failures++;
		goto cleanup;
	}
	errno = 0;
	ret = namei_ext_policy_load_attach(argv[1], cgroup_root, &policy);
	ret = normalize_libbpf_result(ret, errno);
	emit_case(output, "attach_policy", !ret, ret ? -ret : 0,
		  "policy attached through cgroup/namei_ext");
	if (ret) {
		failures++;
		goto cleanup;
	}
	policy_attached = true;
	views_configured = true;
	ret = configure_view_maps(&policy, cgroup_id, &paths);
	emit_case(output, "configure_payload_entries", !ret,
		  ret ? -ret : 0,
		  "V0 and V1 file selection and visibility entries configured");
	if (ret) {
		failures++;
		goto cleanup;
	}
	ret = set_generation(&policy, cgroup_id, 0, true);
	emit_case(output, "scope_cgroup", !ret, ret ? -ret : 0,
		  "the declared cgroup selected V0");
	if (ret) {
		failures++;
		goto cleanup;
	}
	generation_set = true;
	ret = namei_ext_move_self_to_cgroup(paths.cgroup);
	emit_case(output, "enter_managed_cgroup", !ret, ret ? -ret : 0,
		  "runner entered the managed process group");
	if (ret) {
		failures++;
		goto cleanup;
	}
	in_managed_cgroup = true;

	ret = run_state(output, "namei_ext", "initial", 0,
			paths.current, &expected_v0, false, paths.result_dir,
			runtime_uid, runtime_gid, &initial);
	failures += !!ret;
	root_fd = open(paths.current, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (root_fd < 0 || fstat(root_fd, &root_stat)) {
		ret = -errno;
		emit_case(output, "open_stable_root_dirfd", false, -ret,
			  "failed to retain the stable logical volume root");
		failures++;
		goto cleanup;
	}
	emit_case(output, "open_stable_root_dirfd", true, 0,
		  "stable logical volume root retained across updates");
	ret = capture_dirfd_lookup(output, root_fd, &root_stat,
				   &expected_v0.files[FILE_APP], "initial");
	failures += !!ret;
	old_fd = open(paths.current_app, O_RDONLY | O_CLOEXEC);
	if (old_fd < 0 || fstat(old_fd, &old_stat)) {
		ret = -errno;
		emit_case(output, "open_old_v0_fd", false, -ret,
			  "failed to retain the initial V0 descriptor");
		failures++;
		goto cleanup;
	}
	emit_case(output, "open_old_v0_fd", true, 0,
		  "initial V0 descriptor retained across later updates");

	ret = set_generation(&policy, cgroup_id, 1, true);
	if (!ret)
		ret = run_state(output, "namei_ext", "update", 1,
				paths.current, &expected_v1, true,
				paths.result_dir, runtime_uid, runtime_gid,
				&update);
	failures += !!ret;
	ret = capture_dirfd_lookup(output, root_fd, &root_stat,
				   &expected_v1.files[FILE_APP], "update");
	failures += !!ret;
	ret = capture_old_fd(output, old_fd, &old_stat, "after-update");
	failures += !!ret;

	struct stat no_op_before = {};
	struct stat no_op_after = {};
	if (stat(paths.current_app, &no_op_before))
		ret = -errno;
	else
		ret = set_generation(&policy, cgroup_id, 1, true);
	if (!ret)
		ret = run_state(output, "namei_ext", "no-op", 1,
				paths.current, &expected_v1, true,
				paths.result_dir, runtime_uid, runtime_gid,
				&no_op);
	if (!ret && stat(paths.current_app, &no_op_after))
		ret = -errno;
	bool no_op_pass = !ret &&
		no_op_before.st_dev == no_op_after.st_dev &&
		no_op_before.st_ino == no_op_after.st_ino;
	fprintf(output,
		"{\"event\":\"kubernetes-configmap-no-op\","
		"\"mechanism\":\"namei_ext\",\"before_dev\":%llu,"
		"\"before_ino\":%llu,\"after_dev\":%llu,"
		"\"after_ino\":%llu,\"pass\":%s}\n",
		(unsigned long long)no_op_before.st_dev,
		(unsigned long long)no_op_before.st_ino,
		(unsigned long long)no_op_after.st_dev,
		(unsigned long long)no_op_after.st_ino,
		no_op_pass ? "true" : "false");
	fflush(output);
	failures += !no_op_pass;
	ret = capture_dirfd_lookup(output, root_fd, &root_stat,
				   &expected_v1.files[FILE_APP], "no-op");
	failures += !!ret;

	ret = set_generation(&policy, cgroup_id, 0, true);
	if (!ret)
		ret = run_state(output, "namei_ext", "rollback", 0,
				paths.current, &expected_v0, false,
				paths.result_dir, runtime_uid, runtime_gid,
				&rollback);
	bool rollback_identity = !ret &&
		rollback.files[FILE_APP].metadata.st_dev ==
			initial.files[FILE_APP].metadata.st_dev &&
		rollback.files[FILE_APP].metadata.st_ino ==
			initial.files[FILE_APP].metadata.st_ino;
	emit_case(output, "rollback_original_v0_identity", rollback_identity,
		  rollback_identity ? 0 : EIO,
		  "rollback reselected the original pre-existing V0 object");
	failures += !rollback_identity;
	ret = capture_dirfd_lookup(output, root_fd, &root_stat,
				   &expected_v0.files[FILE_APP], "rollback");
	failures += !!ret;
	ret = capture_old_fd(output, old_fd, &old_stat, "after-rollback");
	failures += !!ret;

	failures += !!counter(output, &policy, "total",
			      CONFIGMAP_COUNTER_TOTAL);
	failures += !!counter(output, &policy, "lookup",
			      CONFIGMAP_COUNTER_LOOKUP);
	failures += !!counter(output, &policy, "readdir",
			      CONFIGMAP_COUNTER_READDIR);
	failures += !!counter(output, &policy, "select",
			      CONFIGMAP_COUNTER_SELECT);
	failures += !!counter(output, &policy, "pass",
			      CONFIGMAP_COUNTER_PASS);
	failures += !!counter(output, &policy, "hide",
			      CONFIGMAP_COUNTER_HIDE);

cleanup:
	if (root_fd >= 0) {
		if (close(root_fd)) {
			failures++;
			emit_case(output, "close_stable_root_dirfd", false, errno,
				  "stable root descriptor close failed");
		} else {
			emit_case(output, "close_stable_root_dirfd", true, 0,
				  "stable root descriptor closed");
		}
		root_fd = -1;
	}
	if (old_fd >= 0) {
		if (close(old_fd)) {
			failures++;
			emit_case(output, "close_old_fd", false, errno,
				  "old descriptor close failed");
		} else {
			emit_case(output, "close_old_fd", true, 0,
				  "old descriptor closed");
		}
		old_fd = -1;
	}
	if (in_managed_cgroup) {
		ret = namei_ext_move_self_to_cgroup(cgroup_root);
		emit_case(output, "leave_managed_cgroup", !ret,
			  ret ? -ret : 0,
			  "runner returned to the unmanaged root cgroup");
		failures += !!ret;
		in_managed_cgroup = false;
	}
	if (policy_attached && generation_set) {
		ret = set_generation(&policy, cgroup_id, 0, false);
		emit_case(output, "delete_cgroup_scope", !ret,
			  ret ? -ret : 0, "cgroup generation state deleted");
		failures += !!ret;
		generation_set = false;
	}
	if (policy_attached && views_configured) {
		ret = delete_view_maps(&policy, cgroup_id, &paths);
		emit_case(output, "delete_payload_entries", !ret,
			  ret ? -ret : 0,
			  "V0 and V1 payload map entries deleted");
		failures += !!ret;
		views_configured = false;
	}
	if (policy_attached) {
		errno = 0;
		ret = namei_ext_policy_destroy(&policy);
		ret = normalize_libbpf_result(ret, errno);
		emit_case(output, "detach_policy", !ret, ret ? -ret : 0,
			  "policy detached");
		failures += !!ret;
		policy_attached = false;
	}
	if (targets_registered) {
		ret = namei_ext_clear_targets(paths.cgroup);
		emit_case(output, "clear_targets", !ret, ret ? -ret : 0,
			  "registered generation targets cleared");
		failures += !!ret;
		targets_registered = false;
	}
	if (cgroup_created) {
		if (rmdir(paths.cgroup)) {
			ret = -errno;
			emit_case(output, "remove_cgroup", false, -ret,
				  "managed cgroup removal failed");
			failures++;
		} else {
			emit_case(output, "remove_cgroup", true, 0,
				  "managed cgroup removed");
		}
		cgroup_created = false;
	}
	if (preservation_ready) {
		ret = capture_preservation(preserved, false);
		if (!ret)
			ret = write_preservation_tsv(after_tsv, preserved, false);
		if (!ret)
			ret = emit_preservation(output, preserved);
		emit_case(output, "preserve_lower_generations", !ret,
			  ret ? -ret : 0,
			  "pre-existing V0 and V1 bytes and defined metadata remained unchanged");
		failures += !!ret;
	}
	if (output) {
		ret = unmanaged_control(&paths);
		emit_case(output, "unmanaged_after", !ret, ret ? -ret : 0,
			  "unmanaged placeholder view restored after cleanup");
		failures += !!ret;
		fprintf(output,
			"{\"event\":\"kubernetes-configmap-namei-summary\","
			"\"mechanism\":\"namei_ext\",\"states\":4,"
			"\"direct_controls\":2,\"failures\":%d,\"pass\":%s}\n",
			failures, failures ? "false" : "true");
		fflush(output);
		if (fclose(output))
			failures++;
	}
	return failures ? 1 : 0;

fatal:
	fprintf(stderr, "configmap publication runner failed: %s\n",
		strerror(-ret));
	if (output)
		fclose(output);
	return 2;
}
