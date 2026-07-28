// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <arpa/inet.h>
#include <bpf/bpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <ftw.h>
#include <limits.h>
#include <namei_ext_harness.h>
#include <netinet/in.h>
#include <poll.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define CURRENT_TARGET_ID 1
#define CANARY_TARGET_ID 2
#define INVALID_TARGET_ID 3
#define ROLLBACK_TARGET_ID 4
#define CURRENT_BODY "current-generation\n"
#define CANARY_BODY "canary-generation\n"
#define INVALID_DIRECTIVE "namei_ext_invalid_directive"
#define MAX_HTTP_RESPONSE 16384
#define MAX_CONFIG_SIZE 8192
#define WORKER_BODY_SIZE 65536
#define SHA256_HEX_LENGTH 64
#define PROCESS_TIMEOUT_SECONDS 5

enum service_config_rotation_counter {
	SCR_COUNTER_TOTAL = 0,
	SCR_COUNTER_LOOKUP = 1,
	SCR_COUNTER_READDIR = 2,
	SCR_COUNTER_SELECT = 3,
	SCR_COUNTER_PASS = 4,
};

struct file_snapshot {
	const char *path;
	struct stat metadata;
	char sha256[SHA256_HEX_LENGTH + 1];
};

struct runner_paths {
	char fixture[PATH_MAX];
	char view[PATH_MAX];
	char live[PATH_MAX];
	char logical_config[PATH_MAX];
	char current_dir[PATH_MAX];
	char canary_dir[PATH_MAX];
	char invalid_dir[PATH_MAX];
	char rollback_dir[PATH_MAX];
	char current_config[PATH_MAX];
	char canary_config[PATH_MAX];
	char invalid_config[PATH_MAX];
	char rollback_config[PATH_MAX];
	char current_content[PATH_MAX];
	char canary_content[PATH_MAX];
	char current_index[PATH_MAX];
	char canary_index[PATH_MAX];
	char runtime[PATH_MAX];
	char prefix[PATH_MAX];
	char prefix_logs[PATH_MAX];
	char client_body_temp[PATH_MAX];
	char pid_file[PATH_MAX];
	char error_log[PATH_MAX];
	char captured_error_log[PATH_MAX];
	char nginx_stdout[PATH_MAX];
	char nginx_stderr[PATH_MAX];
};

static uint64_t monotonic_ns(void)
{
	struct timespec now;

	if (clock_gettime(CLOCK_MONOTONIC, &now)) {
		perror("clock_gettime CLOCK_MONOTONIC");
		exit(125);
	}
	return (uint64_t)now.tv_sec * 1000000000ULL + now.tv_nsec;
}

static void sleep_milliseconds(unsigned int milliseconds)
{
	struct timespec delay = {
		.tv_sec = milliseconds / 1000,
		.tv_nsec = (long)(milliseconds % 1000) * 1000000L,
	};

	while (nanosleep(&delay, &delay) && errno == EINTR)
		;
}

static void emit_case(FILE *out, unsigned int repetition, const char *name,
		      bool pass, int err, const char *detail)
{
	fprintf(out,
		"{\"event\":\"service-config-rotation-case\","
		"\"result_level\":\"kvm_service_config_rotation\","
		"\"repetition\":%u,\"case\":\"%s\",\"pass\":%s,"
		"\"errno\":%d,\"detail\":\"%s\"}\n",
		repetition, name, pass ? "true" : "false", err, detail);
	fflush(out);
}

static void emit_state(FILE *out, unsigned int repetition,
		       const char *state, unsigned int target_id,
		       const char *logical_sha256,
		       const char *physical_sha256, const char *http_body,
		       pid_t master_pid, pid_t worker_before,
		       pid_t worker_after, uint64_t latency_ns,
		       unsigned int poll_attempts, bool reload_error,
		       bool pass)
{
	fprintf(out,
		"{\"event\":\"service-config-rotation-state\","
		"\"result_level\":\"kvm_service_config_rotation\","
		"\"repetition\":%u,\"state\":\"%s\",\"target_id\":%u,"
		"\"logical_sha256\":\"%s\",\"physical_sha256\":\"%s\","
		"\"http_body\":\"%s\",\"master_pid\":%ld,"
		"\"worker_before\":%ld,\"worker_after\":%ld,"
		"\"latency_ns\":%llu,\"poll_attempts\":%u,"
		"\"reload_error_observed\":%s,\"pass\":%s}\n",
		repetition, state, target_id, logical_sha256, physical_sha256,
		http_body, (long)master_pid, (long)worker_before,
		(long)worker_after, (unsigned long long)latency_ns,
		poll_attempts, reload_error ? "true" : "false",
		pass ? "true" : "false");
	fflush(out);
}

static void emit_counter(FILE *out, unsigned int repetition,
			 const char *name, unsigned long long value, bool pass)
{
	fprintf(out,
		"{\"event\":\"service-config-rotation-policy-counter\","
		"\"result_level\":\"kvm_service_config_rotation\","
		"\"repetition\":%u,\"counter\":\"%s\",\"value\":%llu,"
		"\"pass\":%s}\n",
		repetition, name, value, pass ? "true" : "false");
	fflush(out);
}

static int make_directory(const char *path)
{
	if (!mkdir(path, 0755))
		return 0;
	return errno == EEXIST ? 0 : -errno;
}

static int build_paths(struct runner_paths *paths, const char *result_dir,
		       const char *runtime_root)
{
	if (namei_ext_path_join(paths->fixture, sizeof(paths->fixture),
				result_dir, "fixture") ||
	    namei_ext_path_join(paths->view, sizeof(paths->view),
				paths->fixture, "view") ||
	    namei_ext_path_join(paths->live, sizeof(paths->live),
				paths->view, "live") ||
	    namei_ext_path_join(paths->logical_config,
				sizeof(paths->logical_config), paths->live,
				"nginx.conf") ||
	    namei_ext_path_join(paths->current_dir, sizeof(paths->current_dir),
				paths->fixture, "generation-current") ||
	    namei_ext_path_join(paths->canary_dir, sizeof(paths->canary_dir),
				paths->fixture, "generation-canary") ||
	    namei_ext_path_join(paths->invalid_dir, sizeof(paths->invalid_dir),
				paths->fixture, "generation-invalid") ||
	    namei_ext_path_join(paths->rollback_dir,
				sizeof(paths->rollback_dir), paths->fixture,
				"generation-rollback") ||
	    namei_ext_path_join(paths->current_config,
				sizeof(paths->current_config), paths->current_dir,
				"nginx.conf") ||
	    namei_ext_path_join(paths->canary_config,
				sizeof(paths->canary_config), paths->canary_dir,
				"nginx.conf") ||
	    namei_ext_path_join(paths->invalid_config,
				sizeof(paths->invalid_config), paths->invalid_dir,
				"nginx.conf") ||
	    namei_ext_path_join(paths->rollback_config,
				sizeof(paths->rollback_config),
				paths->rollback_dir, "nginx.conf") ||
	    namei_ext_path_join(paths->current_content,
				sizeof(paths->current_content), paths->fixture,
				"content-current") ||
	    namei_ext_path_join(paths->canary_content,
				sizeof(paths->canary_content), paths->fixture,
				"content-canary") ||
	    namei_ext_path_join(paths->current_index,
				sizeof(paths->current_index),
				paths->current_content, "index.html") ||
	    namei_ext_path_join(paths->canary_index,
				sizeof(paths->canary_index),
				paths->canary_content, "index.html") ||
	    snprintf(paths->runtime, sizeof(paths->runtime), "%s",
		     runtime_root) >= (int)sizeof(paths->runtime) ||
	    namei_ext_path_join(paths->prefix, sizeof(paths->prefix),
				paths->runtime, "prefix") ||
	    namei_ext_path_join(paths->prefix_logs, sizeof(paths->prefix_logs),
				paths->prefix, "logs") ||
	    namei_ext_path_join(paths->client_body_temp,
				sizeof(paths->client_body_temp), paths->prefix,
				"client_body_temp") ||
	    namei_ext_path_join(paths->pid_file, sizeof(paths->pid_file),
				paths->runtime, "nginx.pid") ||
	    namei_ext_path_join(paths->error_log, sizeof(paths->error_log),
				paths->runtime, "error.log") ||
	    namei_ext_path_join(paths->captured_error_log,
				sizeof(paths->captured_error_log), result_dir,
				"nginx.error.log") ||
	    namei_ext_path_join(paths->nginx_stdout,
				sizeof(paths->nginx_stdout), result_dir,
				"nginx.stdout.log") ||
	    namei_ext_path_join(paths->nginx_stderr,
				sizeof(paths->nginx_stderr), result_dir,
				"nginx.stderr.log"))
		return -ENAMETOOLONG;
	return 0;
}

static int copy_nonempty_regular_file(const char *source,
				      const char *destination)
{
	struct stat source_stat;
	struct stat destination_stat;
	char buffer[16384];
	int source_fd = -1;
	int destination_fd = -1;
	int ret = 0;
	bool destination_created = false;

	if (stat(source, &source_stat))
		return -errno;
	if (!S_ISREG(source_stat.st_mode) || source_stat.st_size <= 0)
		return -EINVAL;
	source_fd = open(source, O_RDONLY | O_CLOEXEC);
	if (source_fd < 0)
		return -errno;
	destination_fd = open(destination,
			      O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0644);
	if (destination_fd < 0) {
		ret = -errno;
		goto out;
	}
	destination_created = true;
	for (;;) {
		ssize_t read_count = read(source_fd, buffer, sizeof(buffer));

		if (!read_count)
			break;
		if (read_count < 0) {
			if (errno == EINTR)
				continue;
			ret = -errno;
			goto out;
		}
		for (ssize_t written = 0; written < read_count;) {
			ssize_t write_count = write(destination_fd,
						    buffer + written,
						    read_count - written);

			if (write_count < 0) {
				if (errno == EINTR)
					continue;
				ret = -errno;
				goto out;
			}
			if (!write_count) {
				ret = -EIO;
				goto out;
			}
			written += write_count;
		}
	}
	if (fsync(destination_fd)) {
		ret = -errno;
		goto out;
	}
	if (close(destination_fd)) {
		destination_fd = -1;
		ret = -errno;
		goto out;
	}
	destination_fd = -1;
	if (stat(destination, &destination_stat)) {
		ret = -errno;
		goto out;
	}
	if (!S_ISREG(destination_stat.st_mode) ||
	    destination_stat.st_size != source_stat.st_size ||
	    destination_stat.st_size <= 0)
		ret = -EIO;

out:
	if (destination_fd >= 0 && close(destination_fd) && !ret)
		ret = -errno;
	if (source_fd >= 0 && close(source_fd) && !ret)
		ret = -errno;
	if (ret && destination_created)
		unlink(destination);
	return ret;
}

static int remove_tree_entry(const char *path, const struct stat *metadata,
			     int type, struct FTW *walk)
{
	(void)metadata;
	(void)type;
	(void)walk;

	return remove(path);
}

static int remove_tree(const char *path)
{
	if (nftw(path, remove_tree_entry, 32, FTW_DEPTH | FTW_PHYS))
		return -errno;
	return 0;
}

static int choose_loopback_port(unsigned short *port_out)
{
	struct sockaddr_in address = {
		.sin_family = AF_INET,
		.sin_addr.s_addr = htonl(INADDR_LOOPBACK),
		.sin_port = 0,
	};
	socklen_t address_len = sizeof(address);
	int fd;

	fd = socket(AF_INET, SOCK_STREAM | SOCK_CLOEXEC, 0);
	if (fd < 0)
		return -errno;
	if (bind(fd, (struct sockaddr *)&address, sizeof(address)) ||
	    getsockname(fd, (struct sockaddr *)&address, &address_len)) {
		int saved_errno = errno;

		close(fd);
		return -saved_errno;
	}
	*port_out = ntohs(address.sin_port);
	close(fd);
	return *port_out ? 0 : -EINVAL;
}

static int write_config(const char *path, const char *generation,
			const char *content_root, const char *pid_file,
			const char *error_log, const char *client_body_temp,
			unsigned short port, bool invalid)
{
	char config[MAX_CONFIG_SIZE];
	int length;

	length = snprintf(
		config, sizeof(config),
		"# generation: %s\n"
		"%s"
		"worker_processes 1;\n"
		"pid %s;\n"
		"error_log %s notice;\n"
		"events { worker_connections 64; }\n"
		"http {\n"
		"    access_log off;\n"
		"    client_body_temp_path %s;\n"
		"    server {\n"
		"        listen 127.0.0.1:%u;\n"
		"        server_name localhost;\n"
		"        location / { root %s; }\n"
		"        location = /upload {\n"
		"            client_body_in_file_only on;\n"
		"            proxy_pass http://127.0.0.1:%u/index.html;\n"
		"        }\n"
		"    }\n"
		"}\n",
		generation,
		invalid ? INVALID_DIRECTIVE " on;\n" : "",
		pid_file, error_log, client_body_temp, port, content_root, port);
	if (length < 0 || (size_t)length >= sizeof(config))
		return -ENAMETOOLONG;
	return namei_ext_write_text(path, config);
}

static int terminate_child(pid_t pid, int *status_out)
{
	if (kill(pid, SIGKILL) && errno != ESRCH)
		return -errno;
	uint64_t deadline = monotonic_ns() + 1000000000ULL;

	while (monotonic_ns() < deadline) {
		pid_t waited = waitpid(pid, status_out, WNOHANG);

		if (waited == pid || (waited < 0 && errno == ECHILD))
			return 0;
		if (waited < 0 && errno != EINTR)
			return -errno;
		sleep_milliseconds(10);
	}
	return -ETIMEDOUT;
}

static int wait_pid_until(pid_t pid, uint64_t deadline, int *status_out)
{
	while (monotonic_ns() < deadline) {
		pid_t waited = waitpid(pid, status_out, WNOHANG);

		if (waited == pid)
			return 0;
		if (waited < 0 && errno != EINTR)
			return -errno;
		sleep_milliseconds(10);
	}
	terminate_child(pid, status_out);
	return -ETIMEDOUT;
}

static int wait_pid_deadline(pid_t pid, unsigned int timeout_seconds,
			     int *status_out)
{
	return wait_pid_until(
		pid, monotonic_ns() +
		(uint64_t)timeout_seconds * 1000000000ULL, status_out);
}

static int stop_nginx_master(pid_t pid, unsigned int timeout_seconds,
			     int *status_out, bool *reaped_out)
{
	uint64_t deadline;
	int force_ret;
	int initial_error = 0;
	pid_t waited;

	*reaped_out = false;
	waited = waitpid(pid, status_out, WNOHANG);
	if (waited == pid) {
		*reaped_out = true;
		return -ECHILD;
	}
	if (waited < 0) {
		initial_error = -errno;
		goto force;
	}
	if (kill(pid, SIGQUIT)) {
		initial_error = -errno;
		goto force;
	}
	deadline = monotonic_ns() +
		(uint64_t)timeout_seconds * 1000000000ULL;
	while (monotonic_ns() < deadline) {
		waited = waitpid(pid, status_out, WNOHANG);
		if (waited == pid) {
			*reaped_out = true;
			if (WIFEXITED(*status_out) &&
			    !WEXITSTATUS(*status_out))
				return 0;
			return -ECHILD;
		}
		if (waited < 0 && errno != EINTR) {
			initial_error = -errno;
			goto force;
		}
		sleep_milliseconds(10);
	}
	initial_error = -ETIMEDOUT;

force:
	force_ret = terminate_child(pid, status_out);

	if (force_ret)
		return force_ret;
	*reaped_out = true;
	return initial_error ? initial_error : -ECHILD;
}

static int run_nginx_validation(const char *nginx, const char *config,
				const char *prefix, const char *stdout_path,
				const char *stderr_path,
				unsigned int timeout_seconds)
{
	char prefix_arg[PATH_MAX + 2];
	pid_t pid;
	int status = 0;
	int ret;

	if (snprintf(prefix_arg, sizeof(prefix_arg), "%s/", prefix) >=
	    (int)sizeof(prefix_arg))
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
		execl(nginx, nginx, "-p", prefix_arg, "-c", config, "-t",
		      (char *)NULL);
		_exit(121);
	}
	ret = wait_pid_deadline(pid, timeout_seconds, &status);
	if (ret)
		return ret;
	if (!WIFEXITED(status))
		return -ECHILD;
	return WEXITSTATUS(status);
}

static int sha256_file(const char *path, const char *cgroup_path,
		       char output[SHA256_HEX_LENGTH + 1])
{
	char buffer[PATH_MAX + SHA256_HEX_LENGTH + 8] = {};
	ssize_t total = 0;
	uint64_t deadline;
	int pipefd[2];
	pid_t pid;
	int status = 0;
	int flags;
	int ret = 0;
	bool eof = false;

	if (pipe2(pipefd, O_CLOEXEC))
		return -errno;
	pid = fork();
	if (pid < 0) {
		int saved_errno = errno;

		close(pipefd[0]);
		close(pipefd[1]);
		return -saved_errno;
	}
	if (!pid) {
		if (cgroup_path &&
		    namei_ext_move_self_to_cgroup(cgroup_path))
			_exit(120);
		if (dup2(pipefd[1], STDOUT_FILENO) < 0)
			_exit(121);
		close(pipefd[0]);
		close(pipefd[1]);
		execlp("sha256sum", "sha256sum", path, (char *)NULL);
		_exit(122);
	}
	close(pipefd[1]);
	flags = fcntl(pipefd[0], F_GETFL);
	if (flags < 0 || fcntl(pipefd[0], F_SETFL, flags | O_NONBLOCK)) {
		ret = -errno;
		goto terminate;
	}
	deadline = monotonic_ns() +
		(uint64_t)PROCESS_TIMEOUT_SECONDS * 1000000000ULL;
	while (monotonic_ns() < deadline &&
	       total < (ssize_t)sizeof(buffer) - 1) {
		ssize_t nread = read(pipefd[0], buffer + total,
				    sizeof(buffer) - 1 - total);

		if (nread > 0) {
			total += nread;
			continue;
		}
		if (!nread) {
			eof = true;
			break;
		}
		if (errno == EINTR)
			continue;
		if (errno != EAGAIN && errno != EWOULDBLOCK) {
			ret = -errno;
			goto terminate;
		}
		struct pollfd descriptor = {
			.fd = pipefd[0],
			.events = POLLIN | POLLHUP,
		};
		int poll_ret = poll(&descriptor, 1, 100);

		if (poll_ret < 0 && errno != EINTR) {
			ret = -errno;
			goto terminate;
		}
	}
	if (!eof) {
		ret = -ETIMEDOUT;
		goto terminate;
	}
	close(pipefd[0]);
	ret = wait_pid_until(pid, deadline, &status);
	if (ret)
		return ret;
	if (!WIFEXITED(status) || WEXITSTATUS(status) ||
	    total < SHA256_HEX_LENGTH + 2 ||
	    buffer[SHA256_HEX_LENGTH] != ' ')
		return -EIO;
	memcpy(output, buffer, SHA256_HEX_LENGTH);
	output[SHA256_HEX_LENGTH] = '\0';
	for (size_t index = 0; index < SHA256_HEX_LENGTH; index++) {
		char value = output[index];

		if (!((value >= '0' && value <= '9') ||
		      (value >= 'a' && value <= 'f')))
			return -EINVAL;
	}
	return 0;

terminate:
	close(pipefd[0]);
	terminate_child(pid, &status);
	return ret;
}

static int directory_probe(const char *cgroup_path, const char *directory)
{
	pid_t pid = fork();

	if (pid < 0)
		return -errno;
	if (!pid) {
		struct dirent *entry;
		DIR *stream;
		bool found = false;

		if (namei_ext_move_self_to_cgroup(cgroup_path))
			_exit(120);
		stream = opendir(directory);
		if (!stream)
			_exit(121);
		errno = 0;
		while ((entry = readdir(stream))) {
			if (!strcmp(entry->d_name, "nginx.conf"))
				found = true;
		}
		if (errno)
			_exit(122);
		if (closedir(stream))
			_exit(123);
		_exit(found ? 0 : 124);
	}
	int status = 0;
	int ret = wait_pid_deadline(pid, PROCESS_TIMEOUT_SECONDS, &status);

	if (ret)
		return ret;
	if (!WIFEXITED(status) || WEXITSTATUS(status))
		return -EIO;
	return 0;
}

static int logical_identity(const char *cgroup_path, const char *logical_dir,
			    const char *logical_config,
			    const char *physical_sha256,
			    char logical_sha256[SHA256_HEX_LENGTH + 1])
{
	int ret = sha256_file(logical_config, cgroup_path, logical_sha256);

	if (ret)
		return ret;
	if (strcmp(logical_sha256, physical_sha256))
		return -EIO;
	return directory_probe(cgroup_path, logical_dir);
}

static int write_all(int fd, const void *buffer, size_t length)
{
	const char *cursor = buffer;

	while (length) {
		ssize_t written = write(fd, cursor, length);

		if (written < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		if (!written)
			return -EIO;
		cursor += written;
		length -= (size_t)written;
	}
	return 0;
}

static int http_body_once(unsigned short port, char *body, size_t body_size)
{
	static const char request[] =
		"GET /index.html HTTP/1.0\r\nHost: localhost\r\n"
		"Connection: close\r\n\r\n";
	struct timeval timeout = {
		.tv_sec = 0,
		.tv_usec = 250000,
	};
	struct sockaddr_in address = {
		.sin_family = AF_INET,
		.sin_addr.s_addr = htonl(INADDR_LOOPBACK),
	};
	char response[MAX_HTTP_RESPONSE + 1] = {};
	ssize_t total = 0;
	int fd;

	address.sin_port = htons(port);
	fd = socket(AF_INET, SOCK_STREAM | SOCK_CLOEXEC, 0);
	if (fd < 0)
		return -errno;
	if (setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout,
		       sizeof(timeout)) ||
	    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout,
		       sizeof(timeout))) {
		int saved_errno = errno;

		close(fd);
		return -saved_errno;
	}
	if (connect(fd, (struct sockaddr *)&address, sizeof(address))) {
		int saved_errno = errno;

		close(fd);
		return -saved_errno;
	}
	int ret = write_all(fd, request, sizeof(request) - 1);
	if (ret) {
		close(fd);
		return ret;
	}
	while (total < MAX_HTTP_RESPONSE) {
		ssize_t nread = read(fd, response + total,
				    MAX_HTTP_RESPONSE - total);

		if (nread < 0) {
			if (errno == EINTR)
				continue;
			close(fd);
			return -errno;
		}
		if (!nread)
			break;
		total += nread;
	}
	close(fd);
	response[total] = '\0';
	if (strncmp(response, "HTTP/1.1 200 ", 13) &&
	    strncmp(response, "HTTP/1.0 200 ", 13))
		return -EIO;
	char *separator = strstr(response, "\r\n\r\n");
	if (!separator)
		return -EIO;
	separator += 4;
	if (strlen(separator) >= body_size)
		return -ENOSPC;
	strcpy(body, separator);
	return 0;
}

static int exercise_worker_temp_io(unsigned short port)
{
	static const char body_chunk[4096] = {
		[0 ... sizeof(body_chunk) - 1] = 'x',
	};
	struct timeval timeout = {
		.tv_sec = 2,
		.tv_usec = 0,
	};
	struct sockaddr_in address = {
		.sin_family = AF_INET,
		.sin_addr.s_addr = htonl(INADDR_LOOPBACK),
	};
	char header[512];
	char response[MAX_HTTP_RESPONSE + 1] = {};
	size_t remaining = WORKER_BODY_SIZE;
	size_t total = 0;
	int length;
	int fd;
	int ret;

	length = snprintf(
		header, sizeof(header),
		"POST /upload HTTP/1.0\r\nHost: localhost\r\n"
		"Content-Type: application/octet-stream\r\n"
		"Content-Length: %u\r\nConnection: close\r\n\r\n",
		(unsigned int)WORKER_BODY_SIZE);
	if (length < 0 || length >= (int)sizeof(header))
		return -ENAMETOOLONG;
	address.sin_port = htons(port);
	fd = socket(AF_INET, SOCK_STREAM | SOCK_CLOEXEC, 0);
	if (fd < 0)
		return -errno;
	if (setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout,
		       sizeof(timeout)) ||
	    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout,
		       sizeof(timeout)) ||
	    connect(fd, (struct sockaddr *)&address, sizeof(address))) {
		ret = -errno;
		goto out;
	}
	ret = write_all(fd, header, (size_t)length);
	while (!ret && remaining) {
		size_t chunk = remaining < sizeof(body_chunk) ?
			remaining : sizeof(body_chunk);

		ret = write_all(fd, body_chunk, chunk);
		remaining -= chunk;
	}
	if (ret)
		goto out;
	if (shutdown(fd, SHUT_WR)) {
		ret = -errno;
		goto out;
	}
	while (total < MAX_HTTP_RESPONSE) {
		ssize_t nread = read(fd, response + total,
				    MAX_HTTP_RESPONSE - total);

		if (nread < 0) {
			if (errno == EINTR)
				continue;
			ret = -errno;
			goto out;
		}
		if (!nread)
			break;
		total += (size_t)nread;
	}
	response[total] = '\0';
	if (strncmp(response, "HTTP/1.1 405 ", 13) &&
	    strncmp(response, "HTTP/1.0 405 ", 13))
		ret = -EIO;

out:
	if (close(fd) && !ret)
		ret = -errno;
	return ret;
}

static int worker_effective_uid(pid_t worker, uid_t *uid_out)
{
	char path[128];
	char line[256];
	FILE *status;
	unsigned long real_uid;
	unsigned long effective_uid;

	if (snprintf(path, sizeof(path), "/proc/%ld/status", (long)worker) >=
	    (int)sizeof(path))
		return -ENAMETOOLONG;
	status = fopen(path, "r");
	if (!status)
		return -errno;
	while (fgets(line, sizeof(line), status)) {
		if (sscanf(line, "Uid:\t%lu\t%lu", &real_uid,
			   &effective_uid) == 2) {
			int ret = 0;

			(void)real_uid;
			if (effective_uid > UINT_MAX)
				ret = -ERANGE;
			else
				*uid_out = (uid_t)effective_uid;
			if (fclose(status) && !ret)
				ret = -errno;
			return ret;
		}
	}
	if (fclose(status))
		return -errno;
	return -EINVAL;
}

static int verify_worker_temp_file(const char *directory, pid_t worker)
{
	struct dirent *entry;
	struct stat metadata;
	uid_t worker_uid = 0;
	DIR *stream;
	unsigned int matches = 0;
	int ret;

	ret = worker_effective_uid(worker, &worker_uid);
	if (ret)
		return ret;
	stream = opendir(directory);
	if (!stream)
		return -errno;
	errno = 0;
	while ((entry = readdir(stream))) {
		if (!strcmp(entry->d_name, ".") || !strcmp(entry->d_name, ".."))
			continue;
		if (fstatat(dirfd(stream), entry->d_name, &metadata,
			    AT_SYMLINK_NOFOLLOW)) {
			ret = -errno;
			goto out;
		}
		if (!S_ISREG(metadata.st_mode) ||
		    metadata.st_size != WORKER_BODY_SIZE ||
		    metadata.st_uid != worker_uid) {
			ret = -EINVAL;
			goto out;
		}
		matches++;
	}
	if (errno) {
		ret = -errno;
		goto out;
	}
	ret = matches == 1 ? 0 : -EINVAL;

out:
	if (closedir(stream) && !ret)
		ret = -errno;
	return ret;
}

static int observed_http_body(unsigned short port, const char *expected,
			      char *body, size_t body_size)
{
	char raw[256] = {};
	size_t length;
	int ret;

	ret = http_body_once(port, raw, sizeof(raw));
	if (ret)
		return ret;
	if (strcmp(raw, expected))
		return -EIO;
	length = strlen(raw);
	if (!length || raw[length - 1] != '\n')
		return -EINVAL;
	raw[--length] = '\0';
	if (length >= body_size)
		return -ENOSPC;
	for (size_t index = 0; index < length; index++) {
		if (raw[index] < 0x20 || raw[index] == '"' || raw[index] == '\\')
			return -EINVAL;
	}
	memcpy(body, raw, length + 1);
	return 0;
}

static int read_single_worker(pid_t master_pid, pid_t *worker_out)
{
	char path[128];
	char children[256] = {};
	char *cursor;
	char *end;
	long worker;
	ssize_t nread;
	int fd;

	if (snprintf(path, sizeof(path), "/proc/%ld/task/%ld/children",
		     (long)master_pid, (long)master_pid) >= (int)sizeof(path))
		return -ENAMETOOLONG;
	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	nread = read(fd, children, sizeof(children) - 1);
	close(fd);
	if (nread < 0)
		return -errno;
	children[nread] = '\0';
	cursor = children;
	while (*cursor == ' ' || *cursor == '\t' || *cursor == '\n')
		cursor++;
	if (!*cursor)
		return -EAGAIN;
	errno = 0;
	worker = strtol(cursor, &end, 10);
	if (errno || end == cursor || worker <= 0 || worker > INT_MAX)
		return -EINVAL;
	while (*end == ' ' || *end == '\t' || *end == '\n')
		end++;
	if (*end)
		return -EAGAIN;
	*worker_out = (pid_t)worker;
	return 0;
}

static bool process_alive(pid_t pid)
{
	if (pid <= 0)
		return false;
	if (!kill(pid, 0))
		return true;
	return errno == EPERM;
}

static int wait_service_state(unsigned short port, const char *expected_body,
			      pid_t master_pid, pid_t old_worker,
			      bool require_new_worker,
			      unsigned int timeout_seconds, pid_t *worker_out,
			      uint64_t *latency_ns,
			      unsigned int *attempts_out)
{
	uint64_t started = monotonic_ns();
	uint64_t deadline = started +
		(uint64_t)timeout_seconds * 1000000000ULL;
	unsigned int attempts = 0;

	while (monotonic_ns() < deadline) {
		char body[256] = {};
		pid_t worker = 0;

		attempts++;
		if (!process_alive(master_pid))
			return -ESRCH;
		if (!read_single_worker(master_pid, &worker) &&
		    !http_body_once(port, body, sizeof(body)) &&
		    !strcmp(body, expected_body)) {
			if (!require_new_worker ||
			    (worker != old_worker &&
			     !process_alive(old_worker))) {
				*worker_out = worker;
				*latency_ns = monotonic_ns() - started;
				*attempts_out = attempts;
				return 0;
			}
		}
		sleep_milliseconds(20);
	}
	return -ETIMEDOUT;
}

static int file_tail_contains(const char *path, off_t offset,
			      const char *needle)
{
	char buffer[8192] = {};
	ssize_t nread;
	int fd = open(path, O_RDONLY | O_CLOEXEC);

	if (fd < 0)
		return -errno;
	if (lseek(fd, offset, SEEK_SET) < 0) {
		int saved_errno = errno;

		close(fd);
		return -saved_errno;
	}
	nread = read(fd, buffer, sizeof(buffer) - 1);
	if (nread < 0) {
		int saved_errno = errno;

		close(fd);
		return -saved_errno;
	}
	if (close(fd))
		return -errno;
	buffer[nread] = '\0';
	return strstr(buffer, needle) ? 1 : 0;
}

static int file_tail_has_nginx_failure(const char *path, off_t offset)
{
	static const char *const levels[] = {
		"[emerg]", "[alert]", "[crit]", "[error]",
	};

	for (size_t index = 0; index < sizeof(levels) / sizeof(levels[0]);
	     index++) {
		int ret = file_tail_contains(path, offset, levels[index]);

		if (ret)
			return ret;
	}
	return 0;
}

static int wait_invalid_rejection(unsigned short port, pid_t master_pid,
				  pid_t worker, const char *error_log,
				  off_t error_offset,
				  unsigned int timeout_seconds,
				  uint64_t *latency_ns,
				  unsigned int *attempts_out)
{
	uint64_t started = monotonic_ns();
	uint64_t deadline = started +
		(uint64_t)timeout_seconds * 1000000000ULL;
	unsigned int attempts = 0;

	while (monotonic_ns() < deadline) {
		char body[256] = {};
		pid_t current_worker = 0;
		int log_match;

		attempts++;
		if (!process_alive(master_pid))
			return -ESRCH;
		log_match = file_tail_contains(error_log, error_offset,
					       INVALID_DIRECTIVE);
		if (log_match < 0)
			return log_match;
		if (!read_single_worker(master_pid, &current_worker) &&
		    current_worker == worker &&
		    !http_body_once(port, body, sizeof(body)) &&
		    !strcmp(body, CANARY_BODY) &&
		    log_match == 1) {
			*latency_ns = monotonic_ns() - started;
			*attempts_out = attempts;
			return 0;
		}
		sleep_milliseconds(20);
	}
	return -ETIMEDOUT;
}

static pid_t spawn_nginx(const char *nginx, const char *logical_config,
			 const char *prefix, const char *cgroup_path,
			 const char *stdout_path, const char *stderr_path)
{
	char prefix_arg[PATH_MAX + 2];
	pid_t pid;

	if (snprintf(prefix_arg, sizeof(prefix_arg), "%s/", prefix) >=
	    (int)sizeof(prefix_arg))
		return -ENAMETOOLONG;
	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		int stdout_fd;
		int stderr_fd;

		if (namei_ext_move_self_to_cgroup(cgroup_path))
			_exit(120);
		stdout_fd = open(stdout_path,
				 O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);
		stderr_fd = open(stderr_path,
				 O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);
		if (stdout_fd < 0 || stderr_fd < 0 ||
		    dup2(stdout_fd, STDOUT_FILENO) < 0 ||
		    dup2(stderr_fd, STDERR_FILENO) < 0)
			_exit(121);
		close(stdout_fd);
		close(stderr_fd);
		execl(nginx, nginx, "-p", prefix_arg, "-c", logical_config,
		      "-g", "daemon off;", (char *)NULL);
		_exit(122);
	}
	return pid;
}

static int capture_snapshot(struct file_snapshot *snapshot)
{
	if (stat(snapshot->path, &snapshot->metadata))
		return -errno;
	return sha256_file(snapshot->path, NULL, snapshot->sha256);
}

static int check_snapshot(const struct file_snapshot *snapshot)
{
	struct stat current;
	char sha256[SHA256_HEX_LENGTH + 1];
	int ret;

	if (stat(snapshot->path, &current))
		return -errno;
	ret = sha256_file(snapshot->path, NULL, sha256);
	if (ret)
		return ret;
	if (snapshot->metadata.st_dev != current.st_dev ||
	    snapshot->metadata.st_ino != current.st_ino ||
	    snapshot->metadata.st_mode != current.st_mode ||
	    snapshot->metadata.st_size != current.st_size ||
	    snapshot->metadata.st_mtim.tv_sec != current.st_mtim.tv_sec ||
	    snapshot->metadata.st_mtim.tv_nsec != current.st_mtim.tv_nsec ||
	    snapshot->metadata.st_ctim.tv_sec != current.st_ctim.tv_sec ||
	    snapshot->metadata.st_ctim.tv_nsec != current.st_ctim.tv_nsec ||
	    strcmp(snapshot->sha256, sha256))
		return -EIO;
	return 0;
}

static int update_target(struct namei_ext_harness_policy *policy,
			 uint64_t cgroup_id, const struct runner_paths *paths,
			 uint32_t target_id)
{
	return namei_ext_component_map_update(
		policy, "service_config_views", cgroup_id, paths->view,
		"live", target_id);
}

static int scope_policy_to_cgroup(struct namei_ext_harness_policy *policy,
				  uint64_t cgroup_id)
{
	struct bpf_map *map;
	uint8_t managed = 1;
	int map_fd;

	map = bpf_object__find_map_by_name(
		policy->obj, "service_config_rotation_cgroups");
	if (!map)
		return -ENOENT;
	map_fd = bpf_map__fd(map);
	if (map_fd < 0)
		return -EINVAL;
	if (bpf_map_update_elem(map_fd, &cgroup_id, &managed, BPF_ANY))
		return -errno;
	return 0;
}

static int check_counter(FILE *out, unsigned int repetition,
			 struct namei_ext_harness_policy *policy,
			 const char *name, uint32_t key)
{
	uint64_t value = 0;
	int ret = namei_ext_policy_counter(
		policy, "service_config_rotation_counters", key, &value);
	bool pass = !ret && value > 0;

	emit_counter(out, repetition, name, value, pass);
	return pass ? 0 : ret ? ret : -EINVAL;
}

int main(int argc, char **argv)
{
	const char *cgroup_root = "/sys/fs/cgroup";
	const char *policy_path;
	const char *nginx;
	const char *result_path;
	const char *result_dir;
	struct namei_ext_harness_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	struct runner_paths paths = {};
	struct file_snapshot snapshots[6] = {};
	struct stat runtime_metadata = {};
	char cgroup[PATH_MAX] = {};
	char policy_resolved[PATH_MAX] = {};
	char nginx_resolved[PATH_MAX] = {};
	char result_path_resolved[PATH_MAX] = {};
	char result_dir_resolved[PATH_MAX] = {};
	char runtime_root[PATH_MAX] = {};
	char validation_stdout[4][PATH_MAX] = {};
	char validation_stderr[4][PATH_MAX] = {};
	char logical_sha256[SHA256_HEX_LENGTH + 1] = {};
	char physical_sha256[4][SHA256_HEX_LENGTH + 1] = {};
	char observed_body[256] = {};
	const char *configs[4];
	const char *validation_names[4] = {
		"current", "canary", "invalid", "rollback",
	};
	unsigned int repetition;
	unsigned int timeout_seconds;
	unsigned short port = 0;
	uint64_t cgroup_id = 0;
	uint64_t latency_ns = 0;
	unsigned int attempts = 0;
	pid_t master_pid = 0;
	pid_t current_worker = 0;
	pid_t canary_worker = 0;
	pid_t rollback_worker = 0;
	bool targets_registered = false;
	bool nginx_started = false;
	bool nginx_reaped = false;
	bool cgroup_created = false;
	bool runtime_created = false;
	FILE *out;
	int fails = 0;
	int ret;
	int status = 0;

	if (argc < 7 || argc > 8) {
		fprintf(stderr,
			"usage: %s POLICY RESULT_JSONL NGINX RESULT_DIR "
			"REPETITION TIMEOUT_SECONDS [CGROUP_ROOT]\n",
			argv[0]);
		return 2;
	}
	if (!realpath(argv[1], policy_resolved) ||
	    !realpath(argv[2], result_path_resolved) ||
	    !realpath(argv[3], nginx_resolved) ||
	    !realpath(argv[4], result_dir_resolved)) {
		perror("realpath input");
		return 2;
	}
	policy_path = policy_resolved;
	result_path = result_path_resolved;
	nginx = nginx_resolved;
	result_dir = result_dir_resolved;
	repetition = (unsigned int)strtoul(argv[5], NULL, 10);
	timeout_seconds = (unsigned int)strtoul(argv[6], NULL, 10);
	if (!repetition || !timeout_seconds)
		return 2;
	if (argc == 8)
		cgroup_root = argv[7];
	out = fopen(result_path, "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}
	ret = snprintf(runtime_root, sizeof(runtime_root),
		       "/tmp/namei-ext-service-config-%ld", (long)getpid());
	if (ret < 0 || ret >= (int)sizeof(runtime_root) ||
	    build_paths(&paths, result_dir, runtime_root) ||
	    snprintf(cgroup, sizeof(cgroup),
		     "%s/namei-ext-service-config-%ld", cgroup_root,
		     (long)getpid()) >= (int)sizeof(cgroup)) {
		emit_case(out, repetition, "paths", false, ENAMETOOLONG,
			  "fixture path construction failed");
		fails++;
		goto cleanup;
	}
	for (size_t index = 0; index < 4; index++) {
		if (snprintf(validation_stdout[index],
			     sizeof(validation_stdout[index]),
			     "%s/nginx-%s-test.stdout.log", result_dir,
			     validation_names[index]) >=
			    (int)sizeof(validation_stdout[index]) ||
		    snprintf(validation_stderr[index],
			     sizeof(validation_stderr[index]),
			     "%s/nginx-%s-test.stderr.log", result_dir,
			     validation_names[index]) >=
			    (int)sizeof(validation_stderr[index])) {
			emit_case(out, repetition, "validation_paths", false,
				  ENAMETOOLONG,
				  "validation log path construction failed");
			fails++;
			goto cleanup;
		}
	}
	ret = make_directory(paths.fixture) ||
	      make_directory(paths.view) ||
	      make_directory(paths.live) ||
	      make_directory(paths.current_dir) ||
	      make_directory(paths.canary_dir) ||
	      make_directory(paths.invalid_dir) ||
	      make_directory(paths.rollback_dir) ||
	      make_directory(paths.current_content) ||
	      make_directory(paths.canary_content);
	if (ret) {
		emit_case(out, repetition, "fixture", false,
			  errno ? errno : EIO,
			  "persistent fixture directory setup failed");
		fails++;
		goto cleanup;
	}
	if (mkdir(paths.runtime, 0711)) {
		emit_case(out, repetition, "fixture", false,
			  errno ? errno : EIO,
			  "guest-local runtime directory setup failed");
		fails++;
		goto cleanup;
	}
	runtime_created = true;
	ret = make_directory(paths.prefix);
	if (!ret)
		ret = make_directory(paths.prefix_logs);
	if (!ret && stat(paths.runtime, &runtime_metadata))
		ret = -errno;
	if (!ret && (!S_ISDIR(runtime_metadata.st_mode) ||
		     (runtime_metadata.st_mode & 0777) != 0711 ||
		     runtime_metadata.st_uid != geteuid()))
		ret = -EINVAL;
	emit_case(out, repetition, "runtime_boundary", !ret,
		  ret ? -ret : 0,
		  "guest-local runtime root is owner-controlled and traversable");
	if (ret) {
		fails++;
		goto cleanup;
	}
	if (choose_loopback_port(&port) ||
	    namei_ext_write_text(paths.current_index, CURRENT_BODY) ||
	    namei_ext_write_text(paths.canary_index, CANARY_BODY) ||
	    write_config(paths.current_config, "current",
			 paths.current_content, paths.pid_file, paths.error_log,
			 paths.client_body_temp, port, false) ||
	    write_config(paths.canary_config, "canary",
			 paths.canary_content, paths.pid_file, paths.error_log,
			 paths.client_body_temp, port, false) ||
	    write_config(paths.invalid_config, "invalid",
			 paths.canary_content, paths.pid_file, paths.error_log,
			 paths.client_body_temp, port, true) ||
	    write_config(paths.rollback_config, "rollback",
			 paths.current_content, paths.pid_file, paths.error_log,
			 paths.client_body_temp, port, false)) {
		emit_case(out, repetition, "fixture", false,
			  errno ? errno : EIO, "fixture generation failed");
		fails++;
		goto cleanup;
	}
	configs[0] = paths.current_config;
	configs[1] = paths.canary_config;
	configs[2] = paths.invalid_config;
	configs[3] = paths.rollback_config;
	for (size_t index = 0; index < 4; index++) {
		ret = sha256_file(configs[index], NULL, physical_sha256[index]);
		if (ret) {
			emit_case(out, repetition, "physical_config_hash",
				  false, -ret,
				  "physical configuration hash failed");
			fails++;
			goto cleanup;
		}
	}
	for (size_t left = 0; left < 4; left++) {
		for (size_t right = left + 1; right < 4; right++) {
			if (!strcmp(physical_sha256[left],
				    physical_sha256[right])) {
				emit_case(out, repetition,
					  "distinct_generation_hashes", false,
					  EINVAL,
					  "configuration generations must be distinct");
				fails++;
				goto cleanup;
			}
		}
	}
	snapshots[0].path = paths.current_config;
	snapshots[1].path = paths.canary_config;
	snapshots[2].path = paths.invalid_config;
	snapshots[3].path = paths.rollback_config;
	snapshots[4].path = paths.current_index;
	snapshots[5].path = paths.canary_index;
	for (size_t index = 0; index < 6; index++) {
		ret = capture_snapshot(&snapshots[index]);
		if (ret) {
			emit_case(out, repetition, "lower_snapshot", false,
				  -ret, "lower-object snapshot failed");
			fails++;
			goto cleanup;
		}
	}
	for (size_t index = 0; index < 4; index++) {
		ret = run_nginx_validation(
			nginx, configs[index], paths.prefix,
			validation_stdout[index], validation_stderr[index],
			timeout_seconds);
		int validation_log_match = index == 2 ?
			file_tail_contains(validation_stderr[index], 0,
					   INVALID_DIRECTIVE) : 0;
		if (validation_log_match < 0)
			ret = validation_log_match;
		bool expected = index == 2 ?
			ret == 1 && validation_log_match == 1 :
			ret == 0;

		emit_case(out, repetition, validation_names[index], expected,
			  ret < 0 ? -ret : ret,
			  index == 2 ?
			  "invalid physical generation rejected by nginx -t" :
			  "physical generation accepted by nginx -t");
		if (!expected) {
			fails++;
			goto cleanup;
		}
	}
	if (mkdir(cgroup, 0755)) {
		emit_case(out, repetition, "service_cgroup", false,
			  errno ? errno : EIO,
			  "service cgroup setup failed");
		fails++;
		goto cleanup;
	}
	cgroup_created = true;
	if (namei_ext_cgroup_id(cgroup, &cgroup_id)) {
		emit_case(out, repetition, "service_cgroup", false,
			  errno ? errno : EIO,
			  "service cgroup identity failed");
		fails++;
		goto cleanup;
	}
	targets_registered = true;
	if (namei_ext_register_target(cgroup, paths.current_dir,
				       CURRENT_TARGET_ID) ||
	    namei_ext_register_target(cgroup, paths.canary_dir,
				       CANARY_TARGET_ID) ||
	    namei_ext_register_target(cgroup, paths.invalid_dir,
				       INVALID_TARGET_ID) ||
	    namei_ext_register_target(cgroup, paths.rollback_dir,
				       ROLLBACK_TARGET_ID)) {
		emit_case(out, repetition, "register_generations", false,
			  errno ? errno : EIO,
			  "target registration failed");
		fails++;
		goto cleanup;
	}
	if (namei_ext_policy_load_attach(policy_path, cgroup_root, &policy)) {
		emit_case(out, repetition, "attach_policy", false, errno,
			  "load or attach failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, repetition, "attach_policy", true, 0,
		  "policy attached through cgroup/namei_ext");
	ret = scope_policy_to_cgroup(&policy, cgroup_id);
	emit_case(out, repetition, "scope_policy", !ret, ret ? -ret : 0,
		  "policy counters scoped to the service cgroup");
	if (ret) {
		fails++;
		goto cleanup;
	}
	logical_sha256[0] = '\0';
	latency_ns = 0;
	attempts = 0;
	ret = update_target(&policy, cgroup_id, &paths, CURRENT_TARGET_ID);
	if (!ret)
		ret = logical_identity(cgroup, paths.live,
				       paths.logical_config,
				       physical_sha256[0], logical_sha256);
	if (ret) {
		emit_state(out, repetition, "current", CURRENT_TARGET_ID,
			   logical_sha256, physical_sha256[0], observed_body,
			   0, 0, 0, 0, 0, false, false);
		fails++;
		goto cleanup;
	}
	master_pid = spawn_nginx(nginx, paths.logical_config, paths.prefix,
				 cgroup, paths.nginx_stdout,
				 paths.nginx_stderr);
	if (master_pid <= 0) {
		emit_state(out, repetition, "current", CURRENT_TARGET_ID,
			   logical_sha256, physical_sha256[0], observed_body,
			   0, 0, 0, 0, 0, false, false);
		fails++;
		goto cleanup;
	}
	nginx_started = true;
	ret = wait_service_state(port, CURRENT_BODY, master_pid, 0, false,
				 timeout_seconds, &current_worker,
				 &latency_ns, &attempts);
	if (!ret)
		ret = observed_http_body(port, CURRENT_BODY, observed_body,
					 sizeof(observed_body));
	emit_state(out, repetition, "current", CURRENT_TARGET_ID,
		   logical_sha256, physical_sha256[0], observed_body,
		   master_pid, 0, current_worker, latency_ns, attempts,
		   false, !ret);
	if (ret) {
		fails++;
		goto cleanup;
	}
	ret = exercise_worker_temp_io(port);
	if (!ret)
		ret = verify_worker_temp_file(paths.client_body_temp,
					      current_worker);
	emit_case(out, repetition, "worker_runtime_io", !ret,
		  ret ? -ret : 0,
		  "default nginx worker stored a request body in guest-local runtime");
	if (ret) {
		fails++;
		goto cleanup;
	}

	logical_sha256[0] = '\0';
	observed_body[0] = '\0';
	latency_ns = 0;
	attempts = 0;
	ret = update_target(&policy, cgroup_id, &paths, CANARY_TARGET_ID);
	if (!ret)
		ret = logical_identity(cgroup, paths.live,
				       paths.logical_config,
				       physical_sha256[1], logical_sha256);
	struct stat canary_error_before = {};
	if (!ret && stat(paths.error_log, &canary_error_before))
		ret = -errno;
	if (!ret && kill(master_pid, SIGHUP))
		ret = -errno;
	if (!ret)
		ret = wait_service_state(port, CANARY_BODY, master_pid,
					 current_worker, true, timeout_seconds,
					 &canary_worker, &latency_ns,
					 &attempts);
	if (!ret)
		ret = observed_http_body(port, CANARY_BODY, observed_body,
					 sizeof(observed_body));
	int canary_log_scan =
		file_tail_has_nginx_failure(paths.error_log,
					    canary_error_before.st_size);
	bool canary_reload_error = canary_log_scan > 0;
	if (!ret && canary_log_scan < 0)
		ret = canary_log_scan;
	if (!ret && canary_reload_error)
		ret = -EINVAL;
	emit_state(out, repetition, "canary", CANARY_TARGET_ID,
		   logical_sha256, physical_sha256[1], observed_body,
		   master_pid, current_worker, canary_worker, latency_ns,
		   attempts, canary_reload_error, !ret);
	if (ret) {
		fails++;
		goto cleanup;
	}

	logical_sha256[0] = '\0';
	observed_body[0] = '\0';
	latency_ns = 0;
	attempts = 0;
	ret = update_target(&policy, cgroup_id, &paths, INVALID_TARGET_ID);
	if (!ret)
		ret = logical_identity(cgroup, paths.live,
				       paths.logical_config,
				       physical_sha256[2], logical_sha256);
	struct stat error_before = {};
	if (!ret && stat(paths.error_log, &error_before))
		ret = -errno;
	if (!ret && kill(master_pid, SIGHUP))
		ret = -errno;
	if (!ret)
		ret = wait_invalid_rejection(
			port, master_pid, canary_worker, paths.error_log,
			error_before.st_size, timeout_seconds, &latency_ns,
			&attempts);
	if (!ret)
		ret = observed_http_body(port, CANARY_BODY, observed_body,
					 sizeof(observed_body));
	int invalid_directive_scan =
		file_tail_contains(paths.error_log, error_before.st_size,
				   INVALID_DIRECTIVE);
	int invalid_level_scan =
		file_tail_has_nginx_failure(paths.error_log,
					    error_before.st_size);
	bool invalid_reload_error =
		invalid_directive_scan > 0 && invalid_level_scan > 0;
	if (!ret && invalid_directive_scan < 0)
		ret = invalid_directive_scan;
	if (!ret && invalid_level_scan < 0)
		ret = invalid_level_scan;
	if (!ret && !invalid_reload_error)
		ret = -EINVAL;
	emit_state(out, repetition, "invalid", INVALID_TARGET_ID,
		   logical_sha256, physical_sha256[2], observed_body,
		   master_pid, canary_worker, canary_worker, latency_ns,
		   attempts, invalid_reload_error, !ret);
	if (ret) {
		fails++;
		goto cleanup;
	}

	logical_sha256[0] = '\0';
	observed_body[0] = '\0';
	latency_ns = 0;
	attempts = 0;
	ret = update_target(&policy, cgroup_id, &paths, ROLLBACK_TARGET_ID);
	if (!ret)
		ret = logical_identity(cgroup, paths.live,
				       paths.logical_config,
				       physical_sha256[3], logical_sha256);
	struct stat rollback_error_before = {};
	if (!ret && stat(paths.error_log, &rollback_error_before))
		ret = -errno;
	if (!ret && kill(master_pid, SIGHUP))
		ret = -errno;
	if (!ret)
		ret = wait_service_state(port, CURRENT_BODY, master_pid,
					 canary_worker, true, timeout_seconds,
					 &rollback_worker, &latency_ns,
					 &attempts);
	if (!ret)
		ret = observed_http_body(port, CURRENT_BODY, observed_body,
					 sizeof(observed_body));
	int rollback_log_scan =
		file_tail_has_nginx_failure(paths.error_log,
					    rollback_error_before.st_size);
	bool rollback_reload_error = rollback_log_scan > 0;
	if (!ret && rollback_log_scan < 0)
		ret = rollback_log_scan;
	if (!ret && rollback_reload_error)
		ret = -EINVAL;
	emit_state(out, repetition, "rollback", ROLLBACK_TARGET_ID,
		   logical_sha256, physical_sha256[3], observed_body,
		   master_pid, canary_worker, rollback_worker, latency_ns,
		   attempts, rollback_reload_error, !ret);
	if (ret) {
		fails++;
		goto cleanup;
	}

	for (size_t index = 0; index < 6; index++) {
		ret = check_snapshot(&snapshots[index]);
		if (ret)
			break;
	}
	emit_case(out, repetition, "lower_objects_unchanged", !ret,
		  ret ? -ret : 0,
		  "generation and content bytes and metadata remain unchanged");
	fails += !!ret;
	fails += !!check_counter(out, repetition, &policy, "lookup",
				 SCR_COUNTER_LOOKUP);
	fails += !!check_counter(out, repetition, &policy, "readdir",
				 SCR_COUNTER_READDIR);
	fails += !!check_counter(out, repetition, &policy, "select",
				 SCR_COUNTER_SELECT);

cleanup:
	if (nginx_started) {
		ret = stop_nginx_master(master_pid, timeout_seconds, &status,
					&nginx_reaped);
		emit_case(out, repetition, "graceful_shutdown", !ret,
			  ret ? -ret : 0,
			  ret ? "nginx master required checked forced shutdown" :
			  "nginx master was reaped after SIGQUIT");
		fails += !!ret;
	} else {
		nginx_reaped = true;
		emit_case(out, repetition, "graceful_shutdown", true, 0,
			  "nginx was not started");
	}
	if (runtime_created) {
		if (!nginx_reaped) {
			emit_case(out, repetition, "capture_error_log", false,
				  EBUSY, "nginx master was not reaped");
			emit_case(out, repetition, "remove_runtime", false,
				  EBUSY, "live nginx runtime tree retained");
			fails += 2;
		} else {
			ret = copy_nonempty_regular_file(paths.error_log,
						       paths.captured_error_log);
			emit_case(out, repetition, "capture_error_log", !ret,
				  ret ? -ret : 0,
				  "non-empty nginx error log captured in result tree");
			fails += !!ret;
			ret = remove_tree(paths.runtime);
			emit_case(out, repetition, "remove_runtime", !ret,
				  ret ? -ret : 0,
				  "guest-local nginx runtime tree removed");
			fails += !!ret;
		}
	}
	if (policy.attached) {
		ret = namei_ext_policy_destroy(&policy);
		emit_case(out, repetition, "detach_policy", !ret,
			  ret ? -ret : 0, "policy detached");
		fails += !!ret;
	}
	if (targets_registered) {
		ret = namei_ext_clear_targets(cgroup);
		emit_case(out, repetition, "clear_targets", !ret,
			  ret ? -ret : 0, "service target registry cleared");
		fails += !!ret;
	}
	if (cgroup_created) {
		ret = rmdir(cgroup);
		emit_case(out, repetition, "remove_cgroup", !ret,
			  ret ? errno : 0, "service cgroup removed");
		fails += !!ret;
	}
	fprintf(out,
		"{\"event\":\"service-config-rotation-summary\","
		"\"result_level\":\"kvm_service_config_rotation\","
		"\"repetition\":%u,\"source_system\":\"kubernetes-atomic-writer+nginx\","
		"\"states\":4,\"master_pid\":%ld,\"pass\":%s,"
		"\"failures\":%d}\n",
		repetition, (long)master_pid, fails ? "false" : "true", fails);
	fflush(out);
	fclose(out);
	return fails ? 1 : 0;
}
