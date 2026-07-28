// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <dirent.h>
#include <dlfcn.h>
#include <dmtcp.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define WAIT_TIMEOUT_SECONDS 30

struct app_paths {
	const char *logical_workspace;
	const char *physical_a;
	const char *physical_b;
	const char *observations;
	const char *pre_ready;
	const char *post_ready;
	const char *complete;
	const char *success;
	const char *failure;
	bool expect_post_failure;
	char logical_state[PATH_MAX];
	char logical_shared[PATH_MAX];
	char physical_a_state[PATH_MAX];
	char physical_b_state[PATH_MAX];
};

static const char *required_env(const char *name)
{
	const char *value = getenv(name);

	if (!value || !value[0]) {
		fprintf(stderr, "checkpoint_restore_app: %s is not set\n", name);
		exit(120);
	}
	return value;
}

static int join_path(char *output, size_t size, const char *dir,
		     const char *name)
{
	int length = snprintf(output, size, "%s/%s", dir, name);

	if (length < 0)
		return -errno;
	return (size_t)length < size ? 0 : -ENAMETOOLONG;
}

static int write_marker(const char *path, const char *value)
{
	size_t length = strlen(value);
	ssize_t written;
	int fd;

	fd = open(path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0644);
	if (fd < 0)
		return -errno;
	written = write(fd, value, length);
	if (written != (ssize_t)length) {
		int saved_errno = errno ? errno : EIO;

		close(fd);
		return -saved_errno;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static int read_exact_file(const char *path, const char *expected,
			   struct stat *metadata)
{
	char buffer[128] = {};
	size_t expected_length = strlen(expected);
	size_t total = 0;
	FILE *stream;

	stream = fopen(path, "r");
	if (!stream)
		return -errno;
	if (fstat(fileno(stream), metadata)) {
		int saved_errno = errno;

		fclose(stream);
		return -saved_errno;
	}
	while (total < sizeof(buffer) - 1) {
		size_t count = fread(buffer + total, 1,
				     sizeof(buffer) - 1 - total, stream);

		total += count;
		if (!count)
			break;
	}
	if (ferror(stream)) {
		int saved_errno = errno ? errno : EIO;

		fclose(stream);
		return -saved_errno;
	}
	if (fclose(stream))
		return -errno;
	if (total != expected_length ||
	    memcmp(buffer, expected, expected_length))
		return -EIO;
	return 0;
}

static int check_directory(const char *path, bool expect_stale,
			   bool expect_new, bool *saw_stale_out,
			   bool *saw_new_out)
{
	bool saw_stale = false;
	bool saw_new = false;
	struct dirent *entry;
	DIR *directory;

	directory = opendir(path);
	if (!directory)
		return -errno;
	errno = 0;
	while ((entry = readdir(directory))) {
		if (!strcmp(entry->d_name, "stale.txt"))
			saw_stale = true;
		if (!strcmp(entry->d_name, "new.txt"))
			saw_new = true;
	}
	if (errno) {
		int saved_errno = errno;

		closedir(directory);
		return -saved_errno;
	}
	if (closedir(directory))
		return -errno;
	*saw_stale_out = saw_stale;
	*saw_new_out = saw_new;
	return saw_stale == expect_stale && saw_new == expect_new ? 0 : -EIO;
}

static int read_cgroup(char output[512])
{
	ssize_t count;
	int fd;

	fd = open("/proc/self/cgroup", O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	count = read(fd, output, 511);
	if (count < 0) {
		int saved_errno = errno;

		close(fd);
		return -saved_errno;
	}
	close(fd);
	output[count] = '\0';
	for (ssize_t index = 0; index < count; index++) {
		if (output[index] == '\n' || output[index] == '\r')
			output[index] = ' ';
		if (output[index] == '"')
			output[index] = '\'';
	}
	return 0;
}

static void emit_observation(const struct app_paths *paths, const char *stage,
			     const char *generation, int checkpoints,
			     int restarts, const struct stat *logical,
			     const struct stat *physical, bool saw_stale,
			     bool saw_new, const char *cgroup, int error,
			     int restart_env_status,
			     const char *restart_mapping,
			     const char *checkpoint_mapping,
			     bool expected_failure, bool pass)
{
	FILE *output = fopen(paths->observations, "a");

	if (!output)
		exit(121);
	fprintf(output,
		"{\"event\":\"checkpoint-restore-application\","
		"\"stage\":\"%s\",\"generation\":\"%s\","
		"\"logical_path\":\"%s/state.txt\","
		"\"checkpoints\":%d,\"restarts\":%d,"
		"\"logical_dev\":%llu,\"logical_ino\":%llu,"
		"\"physical_dev\":%llu,\"physical_ino\":%llu,"
		"\"saw_stale\":%s,\"saw_new\":%s,"
		"\"cgroup\":\"%s\",\"errno\":%d,"
		"\"restart_env_status\":%d,"
		"\"restart_mapping\":\"%s\","
		"\"checkpoint_mapping\":\"%s\","
		"\"expected_failure\":%s,\"pass\":%s}\n",
		stage, generation, paths->logical_workspace, checkpoints,
		restarts, (unsigned long long)(logical ? logical->st_dev : 0),
		(unsigned long long)(logical ? logical->st_ino : 0),
		(unsigned long long)(physical ? physical->st_dev : 0),
		(unsigned long long)(physical ? physical->st_ino : 0),
		saw_stale ? "true" : "false", saw_new ? "true" : "false",
		cgroup ? cgroup : "", error < 0 ? -error : error,
		restart_env_status, restart_mapping ? restart_mapping : "",
		checkpoint_mapping ? checkpoint_mapping : "",
		expected_failure ? "true" : "false",
		pass ? "true" : "false");
	if (fclose(output))
		exit(122);
}

static int validate_stage(const struct app_paths *paths, bool restored,
			  int checkpoints, int restarts)
{
	const char *expected_state =
		restored ? "generation-b\n" : "generation-a\n";
	const char *expected_shared = "shared-common\n";
	const char *physical_state =
		restored ? paths->physical_b_state : paths->physical_a_state;
	const char *generation = restored ? "b" : "a";
	struct stat logical = {};
	struct stat physical = {};
	struct stat shared = {};
	char cgroup[512] = {};
	char restart_mapping[PATH_MAX * 2] = {};
	const char *checkpoint_mapping = getenv("DMTCP_PATH_MAPPING");
	int restart_env_status = RESTART_ENV_NOTFOUND;
	bool saw_stale = false;
	bool saw_new = false;
	int ret;

	ret = read_cgroup(cgroup);
	if (!ret)
		ret = read_exact_file(paths->logical_state, expected_state, &logical);
	if (!ret && stat(physical_state, &physical))
		ret = -errno;
	if (!ret && (logical.st_dev != physical.st_dev ||
		     logical.st_ino != physical.st_ino))
		ret = -EXDEV;
	if (!ret)
		ret = read_exact_file(paths->logical_shared, expected_shared,
				      &shared);
	if (!ret)
		ret = check_directory(paths->logical_workspace, !restored,
				      restored, &saw_stale, &saw_new);
	if (restored)
	{
		typedef DmtcpGetRestartEnvErr_t (*restart_env_fn)(
			const char *, char *, size_t);
		restart_env_fn get_restart_env =
			(restart_env_fn)dlsym(RTLD_DEFAULT,
					     "dmtcp_get_restart_env");

		restart_env_status = get_restart_env ?
			get_restart_env("DMTCP_PATH_MAPPING",
					restart_mapping,
					sizeof(restart_mapping)) :
			RESTART_ENV_INTERNAL_ERROR;
	}

	bool expected_failure = restored && paths->expect_post_failure;
	bool pass = expected_failure ? ret == -ENOENT : !ret;

	emit_observation(paths, restored ? "post-restart" : "pre-checkpoint",
			 generation, checkpoints, restarts, &logical, &physical,
			 saw_stale, saw_new, cgroup, ret, restart_env_status,
			 restart_mapping, checkpoint_mapping, expected_failure,
			 pass);
	return ret;
}

static int wait_for_file(const char *path)
{
	struct timespec delay = {
		.tv_sec = 0,
		.tv_nsec = 10000000,
	};
	time_t deadline = time(NULL) + WAIT_TIMEOUT_SECONDS;

	while (time(NULL) <= deadline) {
		if (!access(path, F_OK))
			return 0;
		if (errno != ENOENT)
			return -errno;
		nanosleep(&delay, NULL);
	}
	return -ETIMEDOUT;
}

static int build_paths(struct app_paths *paths)
{
	paths->logical_workspace =
		required_env("NAMEI_EXT_CR_LOGICAL_WORKSPACE");
	paths->physical_a = required_env("NAMEI_EXT_CR_PHYSICAL_A");
	paths->physical_b = required_env("NAMEI_EXT_CR_PHYSICAL_B");
	paths->observations = required_env("NAMEI_EXT_CR_APP_OBSERVATIONS");
	paths->pre_ready = required_env("NAMEI_EXT_CR_PRE_READY");
	paths->post_ready = required_env("NAMEI_EXT_CR_POST_READY");
	paths->complete = required_env("NAMEI_EXT_CR_COMPLETE");
	paths->success = required_env("NAMEI_EXT_CR_SUCCESS");
	paths->failure = required_env("NAMEI_EXT_CR_FAILURE");
	paths->expect_post_failure =
		!strcmp(required_env("NAMEI_EXT_CR_EXPECT_POST_FAILURE"), "1");

	return join_path(paths->logical_state, sizeof(paths->logical_state),
			 paths->logical_workspace, "state.txt") ||
		       join_path(paths->logical_shared,
				 sizeof(paths->logical_shared),
				 paths->logical_workspace, "shared.txt") ||
		       join_path(paths->physical_a_state,
				 sizeof(paths->physical_a_state),
				 paths->physical_a, "state.txt") ||
		       join_path(paths->physical_b_state,
				 sizeof(paths->physical_b_state),
				 paths->physical_b, "state.txt");
}

int main(void)
{
	struct app_paths paths = {};
	bool pre_checkpoint_complete = false;

	if (build_paths(&paths)) {
		fprintf(stderr, "checkpoint_restore_app: path setup failed\n");
		return 123;
	}

	for (;;) {
		int checkpoints = 0;
		int restarts = 0;
		int ret = dmtcp_get_local_status(&checkpoints, &restarts);

		if (ret == DMTCP_NOT_PRESENT) {
			fprintf(stderr,
				"checkpoint_restore_app: not running under DMTCP\n");
			return 124;
		}
		if (!restarts && !pre_checkpoint_complete) {
			ret = validate_stage(&paths, false, checkpoints, restarts);
			if (ret || write_marker(paths.pre_ready, "ready\n")) {
				write_marker(paths.failure, "pre-checkpoint\n");
				return 125;
			}
			pre_checkpoint_complete = true;
		}
		if (restarts > 0) {
			ret = validate_stage(&paths, true, checkpoints, restarts);
			if (paths.expect_post_failure) {
				if (ret != -ENOENT) {
					write_marker(paths.failure,
						     "unexpected-post-result\n");
					return 128;
				}
				if (write_marker(paths.failure,
						 "expected-post-enoent\n"))
					return 129;
				return 126;
			}
			if (ret) {
				write_marker(paths.failure, "post-restart\n");
				return 126;
			}
			if (write_marker(paths.post_ready, "ready\n") ||
			    wait_for_file(paths.complete) ||
			    write_marker(paths.success, "success\n")) {
				write_marker(paths.failure, "post-control\n");
				return 127;
			}
			return 0;
		}
		usleep(10000);
	}
}
