// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/bpf.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define DOCUMENT_TARGET_ID 1
#define DOCUMENT_PAYLOAD "xdg-portal-existing-object\n"
#define UNRELATED_PAYLOAD "unrelated-document-object\n"
#define NAMEI_EXT_NAME_MAX 64

enum application_file_sharing_counter {
	AFS_COUNTER_TOTAL = 0,
	AFS_COUNTER_LOOKUP = 1,
	AFS_COUNTER_READDIR = 2,
	AFS_COUNTER_SELECT = 3,
	AFS_COUNTER_HIDE_LOOKUP = 4,
	AFS_COUNTER_HIDE_READDIR = 5,
	AFS_COUNTER_PASS = 6,
};

struct attached_policy {
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	bool attached;
};

struct probe_paths {
	const char *view;
	const char *document;
	const char *payload;
	const char *unrelated_payload;
};

struct namei_ext_component_key {
	__u32 event;
	__u32 name_len;
	__u64 cgroup_id;
	__u64 parent_dev;
	__u64 parent_ino;
	__u8 name[NAMEI_EXT_NAME_MAX];
};

static void emit_case(FILE *out, const char *name, bool pass, int err,
		      const char *detail)
{
	fprintf(out,
		"{\"event\":\"application-file-sharing-case\","
		"\"result_level\":\"kvm_application_file_sharing_preflight\","
		"\"case\":\"%s\",\"pass\":%s,\"errno\":%d,"
		"\"detail\":\"%s\"}\n",
		name, pass ? "true" : "false", err, detail);
	fflush(out);
}

static void emit_counter(FILE *out, const char *name,
			 unsigned long long value, bool pass)
{
	fprintf(out,
		"{\"event\":\"application-file-sharing-policy-counter\","
		"\"result_level\":\"kvm_application_file_sharing_preflight\","
		"\"counter\":\"%s\",\"value\":%llu,\"pass\":%s}\n",
		name, value, pass ? "true" : "false");
	fflush(out);
}

static int set_path(char *dst, size_t size, const char *dir,
		    const char *name)
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
	ssize_t len;
	int fd;

	fd = open(path, O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);
	if (fd < 0)
		return -errno;
	len = write(fd, value, strlen(value));
	if (len != (ssize_t)strlen(value)) {
		int saved_errno = errno ? errno : EIO;

		close(fd);
		return -saved_errno;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static bool read_file_matches(const char *path, const char *expected)
{
	char buf[128] = {};
	ssize_t nread;
	int fd;

	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return false;
	nread = read(fd, buf, sizeof(buf) - 1);
	close(fd);
	return nread >= 0 && !strcmp(buf, expected);
}

static bool directory_contains(const char *path, const char *name)
{
	struct dirent *entry;
	DIR *dir;
	bool found = false;

	dir = opendir(path);
	if (!dir)
		return false;
	while ((entry = readdir(dir))) {
		if (!strcmp(entry->d_name, name)) {
			found = true;
			break;
		}
	}
	closedir(dir);
	return found;
}

static int move_self_to_cgroup(const char *cgroup_path)
{
	char procs_path[PATH_MAX];
	char pid_buf[32];
	ssize_t nwritten;
	int fd;
	int len;

	if (set_path(procs_path, sizeof(procs_path), cgroup_path,
		     "cgroup.procs"))
		return -ENAMETOOLONG;
	fd = open(procs_path, O_WRONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	len = snprintf(pid_buf, sizeof(pid_buf), "%ld\n", (long)getpid());
	if (len < 0 || (size_t)len >= sizeof(pid_buf)) {
		close(fd);
		return -EINVAL;
	}
	nwritten = write(fd, pid_buf, len);
	if (nwritten != len) {
		int saved_errno = errno ? errno : EIO;

		close(fd);
		return -saved_errno;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static int wait_child(pid_t pid)
{
	int status;

	if (waitpid(pid, &status, 0) != pid)
		return -errno;
	if (!WIFEXITED(status))
		return -ECHILD;
	return WEXITSTATUS(status) ? -EIO : 0;
}

static int register_target_for_cgroup(const char *cgroup_path,
				      const char *target_dir)
{
	pid_t pid;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		char register_buf[64];
		ssize_t nwritten;
		int register_fd;
		int target_fd;
		int len;

		if (move_self_to_cgroup(cgroup_path))
			_exit(1);
		target_fd = open(target_dir, O_PATH | O_DIRECTORY | O_CLOEXEC);
		if (target_fd < 0)
			_exit(1);
		register_fd = open("/sys/kernel/debug/namei_ext/register_target",
				   O_WRONLY | O_CLOEXEC);
		if (register_fd < 0) {
			close(target_fd);
			_exit(1);
		}
		len = snprintf(register_buf, sizeof(register_buf), "%u %d\n",
			       DOCUMENT_TARGET_ID, target_fd);
		if (len < 0 || (size_t)len >= sizeof(register_buf)) {
			close(register_fd);
			close(target_fd);
			_exit(1);
		}
		nwritten = write(register_fd, register_buf, len);
		close(register_fd);
		close(target_fd);
		_exit(nwritten == len ? 0 : 1);
	}
	return wait_child(pid);
}

static int clear_targets_for_cgroup(const char *cgroup_path)
{
	pid_t pid;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		const char clear[] = "clear\n";
		ssize_t nwritten;
		int register_fd;

		if (move_self_to_cgroup(cgroup_path))
			_exit(1);
		register_fd = open("/sys/kernel/debug/namei_ext/register_target",
				   O_WRONLY | O_CLOEXEC);
		if (register_fd < 0)
			_exit(1);
		nwritten = write(register_fd, clear, strlen(clear));
		close(register_fd);
		_exit(nwritten == (ssize_t)strlen(clear) ? 0 : 1);
	}
	return wait_child(pid);
}

static int cgroup_id_from_path(const char *path, __u64 *id_out)
{
	union {
		__u64 cgroup_id;
		unsigned char bytes[8];
	} id = {};
	struct file_handle *handle;
	struct file_handle *resized;
	size_t size = sizeof(*handle);
	int mount_id = 0;
	int saved_errno;
	int ret;

	handle = calloc(1, size);
	if (!handle)
		return -errno;
	errno = 0;
	ret = name_to_handle_at(AT_FDCWD, path, handle, &mount_id, 0);
	if (ret >= 0 || errno != EOVERFLOW || handle->handle_bytes != 8) {
		saved_errno = errno ? errno : EINVAL;
		free(handle);
		return -saved_errno;
	}

	size += handle->handle_bytes;
	resized = realloc(handle, size);
	if (!resized) {
		saved_errno = errno;
		free(handle);
		return -saved_errno;
	}
	handle = resized;
	ret = name_to_handle_at(AT_FDCWD, path, handle, &mount_id, 0);
	if (ret < 0) {
		saved_errno = errno;
		free(handle);
		return -saved_errno;
	}
	memcpy(id.bytes, handle->f_handle, sizeof(id.bytes));
	free(handle);
	if (!id.cgroup_id)
		return -EINVAL;
	*id_out = id.cgroup_id;
	return 0;
}

static int load_and_attach(const char *obj_path, const char *cgroup_path,
			   struct attached_policy *policy)
{
	struct bpf_program *program;
	struct bpf_object *object;
	int cgroup_fd;
	int program_fd;
	int err;

	object = bpf_object__open_file(obj_path, NULL);
	err = libbpf_get_error(object);
	if (err) {
		errno = -err;
		return -1;
	}
	err = bpf_object__load(object);
	if (err) {
		errno = -err;
		goto close_object;
	}
	program = bpf_object__next_program(object, NULL);
	if (!program) {
		errno = EINVAL;
		goto close_object;
	}
	program_fd = bpf_program__fd(program);
	if (program_fd < 0) {
		errno = EINVAL;
		goto close_object;
	}
	cgroup_fd = open(cgroup_path, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (cgroup_fd < 0)
		goto close_object;
	err = bpf_prog_attach(program_fd, cgroup_fd, BPF_CGROUP_NAMEI_EXT, 0);
	if (err) {
		errno = -err;
		close(cgroup_fd);
		goto close_object;
	}

	policy->obj = object;
	policy->cgroup_fd = cgroup_fd;
	policy->prog_fd = program_fd;
	policy->attached = true;
	return 0;

close_object:
	bpf_object__close(object);
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

static int run_access_probe(const char *cgroup_path,
			    const struct probe_paths *paths, bool visible)
{
	pid_t pid;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		struct stat st;
		bool listed;

		if (move_self_to_cgroup(cgroup_path))
			_exit(1);
		if (!read_file_matches(paths->unrelated_payload,
				      UNRELATED_PAYLOAD))
			_exit(1);
		listed = directory_contains(paths->view, "document");
		if (visible) {
			if (stat(paths->document, &st) || !S_ISDIR(st.st_mode))
				_exit(1);
			if (!read_file_matches(paths->payload, DOCUMENT_PAYLOAD))
				_exit(1);
			if (!listed)
				_exit(1);
		} else {
			errno = 0;
			if (!stat(paths->document, &st) || errno != ENOENT)
				_exit(1);
			errno = 0;
			if (access(paths->payload, F_OK) == 0 || errno != ENOENT)
				_exit(1);
			if (listed)
				_exit(1);
		}
		_exit(0);
	}
	return wait_child(pid);
}

static int fill_component_key(struct namei_ext_component_key *key,
			      __u64 cgroup_id, const char *parent,
			      const char *name)
{
	struct stat st;
	size_t name_len = strlen(name);

	if (name_len > sizeof(key->name))
		return -ENAMETOOLONG;
	if (stat(parent, &st))
		return -errno;
	memset(key, 0, sizeof(*key));
	key->name_len = name_len;
	key->cgroup_id = cgroup_id;
	key->parent_dev = st.st_dev;
	key->parent_ino = st.st_ino;
	memcpy(key->name, name, name_len);
	return 0;
}

static int update_grant(struct attached_policy *policy, __u64 cgroup_id,
			const char *parent, const char *name, bool grant)
{
	struct namei_ext_component_key key;
	struct bpf_map *map;
	__u32 target_id = DOCUMENT_TARGET_ID;
	int map_fd;
	int ret;

	ret = fill_component_key(&key, cgroup_id, parent, name);
	if (ret)
		return ret;
	map = bpf_object__find_map_by_name(policy->obj, "sharing_grants");
	if (!map)
		return -ENOENT;
	map_fd = bpf_map__fd(map);
	if (map_fd < 0)
		return -EINVAL;
	if (grant) {
		if (bpf_map_update_elem(map_fd, &key, &target_id, BPF_ANY))
			return -errno;
	} else if (bpf_map_delete_elem(map_fd, &key) && errno != ENOENT) {
		return -errno;
	}
	return 0;
}

static int register_scope(struct attached_policy *policy, const char *parent,
			  const char *name)
{
	struct namei_ext_component_key key;
	struct bpf_map *map;
	__u32 managed = 1;
	int map_fd;
	int ret;

	ret = fill_component_key(&key, 0, parent, name);
	if (ret)
		return ret;
	map = bpf_object__find_map_by_name(policy->obj, "sharing_scopes");
	if (!map)
		return -ENOENT;
	map_fd = bpf_map__fd(map);
	if (map_fd < 0)
		return -EINVAL;
	if (bpf_map_update_elem(map_fd, &key, &managed, BPF_ANY))
		return -errno;
	return 0;
}

static int check_counter(FILE *out, struct attached_policy *policy,
			 const char *name, __u32 key)
{
	struct bpf_map *map;
	__u64 value = 0;
	int map_fd;
	bool pass;

	map = bpf_object__find_map_by_name(
		policy->obj, "application_file_sharing_counters");
	if (!map)
		return -ENOENT;
	map_fd = bpf_map__fd(map);
	if (map_fd < 0)
		return -EINVAL;
	if (bpf_map_lookup_elem(map_fd, &key, &value))
		return -errno;
	pass = value > 0;
	emit_counter(out, name, value, pass);
	return pass ? 0 : -EINVAL;
}

int main(int argc, char **argv)
{
	const char *cgroup_root = "/sys/fs/cgroup";
	struct attached_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	char root[] = "/tmp/namei-ext-app-file-sharing-XXXXXX";
	char cgroup_a[PATH_MAX] = {};
	char cgroup_b[PATH_MAX] = {};
	char view[PATH_MAX] = {};
	char document[PATH_MAX] = {};
	char host_document[PATH_MAX] = {};
	char payload[PATH_MAX] = {};
	char host_payload[PATH_MAX] = {};
	char unrelated[PATH_MAX] = {};
	char unrelated_document[PATH_MAX] = {};
	char unrelated_payload[PATH_MAX] = {};
	struct probe_paths paths;
	struct stat host_before;
	struct stat host_after;
	__u64 app_a_cgroup_id = 0;
	FILE *out;
	bool target_registered = false;
	int fails = 0;
	int ret;

	if (argc < 3 || argc > 4) {
		fprintf(stderr,
			"usage: %s POLICY_BPF_O RESULT_JSONL [CGROUP_ROOT]\n",
			argv[0]);
		return 2;
	}
	if (argc == 4)
		cgroup_root = argv[3];
	out = fopen(argv[2], "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}
	if (!mkdtemp(root)) {
		emit_case(out, "mkdtemp", false, errno, "workspace setup failed");
		fclose(out);
		return 1;
	}
	if (snprintf(cgroup_a, sizeof(cgroup_a),
		     "%s/namei-ext-app-share-a-%ld", cgroup_root,
		     (long)getpid()) >= (int)sizeof(cgroup_a) ||
	    snprintf(cgroup_b, sizeof(cgroup_b),
		     "%s/namei-ext-app-share-b-%ld", cgroup_root,
		     (long)getpid()) >= (int)sizeof(cgroup_b) ||
	    set_path(view, sizeof(view), root, "view") ||
	    set_path(document, sizeof(document), view, "document") ||
	    set_path(host_document, sizeof(host_document), root,
		     "host-document") ||
	    set_path(payload, sizeof(payload), document, "payload.txt") ||
	    set_path(host_payload, sizeof(host_payload), host_document,
		     "payload.txt") ||
	    set_path(unrelated, sizeof(unrelated), root, "unrelated") ||
	    set_path(unrelated_document, sizeof(unrelated_document), unrelated,
		     "document") ||
	    set_path(unrelated_payload, sizeof(unrelated_payload),
		     unrelated_document, "payload.txt")) {
		emit_case(out, "paths", false, ENAMETOOLONG,
			  "path construction failed");
		fails++;
		goto cleanup;
	}
	if (mkdir(view, 0755) || mkdir(document, 0755) ||
	    mkdir(host_document, 0755) || mkdir(unrelated, 0755) ||
	    mkdir(unrelated_document, 0755) ||
	    write_file(host_payload, DOCUMENT_PAYLOAD) ||
	    write_file(unrelated_payload, UNRELATED_PAYLOAD) ||
	    stat(host_payload, &host_before)) {
		emit_case(out, "fixture", false, errno,
			  "existing host document fixture failed");
		fails++;
		goto cleanup;
	}
	if (mkdir(cgroup_a, 0755) || mkdir(cgroup_b, 0755)) {
		emit_case(out, "application_cgroups", false, errno,
			  "application identity cgroups failed");
		fails++;
		goto cleanup;
	}
	ret = cgroup_id_from_path(cgroup_a, &app_a_cgroup_id);
	if (ret) {
		emit_case(out, "application_cgroup_id", false, -ret,
			  "cgroup identity lookup failed");
		fails++;
		goto cleanup;
	}
	ret = register_target_for_cgroup(cgroup_a, host_document);
	if (ret) {
		emit_case(out, "register_existing_document", false, -ret,
			  "target registration in application cgroup failed");
		fails++;
		goto cleanup;
	}
	target_registered = true;
	emit_case(out, "register_existing_document", true, 0,
		  "existing host document registered for application A");

	if (load_and_attach(argv[1], cgroup_root, &policy)) {
		emit_case(out, "attach_policy", false, errno,
			  "load or attach failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "attach_policy", true, 0,
		  "policy attached to real cgroup/namei_ext path");
	ret = register_scope(&policy, view, "document");
	emit_case(out, "register_portal_scope", !ret, ret ? -ret : 0,
		  "grant policy scoped to the portal parent and logical name");
	fails += !!ret;
	if (ret)
		goto cleanup;

	paths.view = view;
	paths.document = document;
	paths.payload = payload;
	paths.unrelated_payload = unrelated_payload;
	ret = run_access_probe(cgroup_a, &paths, false);
	emit_case(out, "application_a_before_grant", !ret, ret ? -ret : 0,
		  "application A has no document before grant");
	fails += !!ret;
	ret = run_access_probe(cgroup_b, &paths, false);
	emit_case(out, "application_b_without_grant", !ret, ret ? -ret : 0,
		  "application B cannot see another application's document");
	fails += !!ret;

	ret = update_grant(&policy, app_a_cgroup_id, view, "document", true);
	emit_case(out, "grant_application_a", !ret, ret ? -ret : 0,
		  "grant map updated for application A");
	fails += !!ret;
	if (!ret) {
		ret = run_access_probe(cgroup_a, &paths, true);
		emit_case(out, "application_a_after_grant", !ret,
			  ret ? -ret : 0,
			  "application A opens, stats, reads, and enumerates the document");
		fails += !!ret;
	}
	ret = run_access_probe(cgroup_b, &paths, false);
	emit_case(out, "application_b_during_a_grant", !ret,
		  ret ? -ret : 0,
		  "application B remains unable to see application A's grant");
	fails += !!ret;

	ret = update_grant(&policy, app_a_cgroup_id, view, "document", false);
	emit_case(out, "revoke_application_a", !ret, ret ? -ret : 0,
		  "grant removed for application A");
	fails += !!ret;
	if (!ret) {
		ret = run_access_probe(cgroup_a, &paths, false);
		emit_case(out, "application_a_after_revoke", !ret,
			  ret ? -ret : 0,
			  "revocation changes subsequent lookup and readdir results");
		fails += !!ret;
	}

	if (stat(host_payload, &host_after) ||
	    host_before.st_dev != host_after.st_dev ||
	    host_before.st_ino != host_after.st_ino ||
	    host_before.st_mode != host_after.st_mode ||
	    host_before.st_size != host_after.st_size ||
	    !read_file_matches(host_payload, DOCUMENT_PAYLOAD)) {
		emit_case(out, "lower_object_unchanged", false, EIO,
			  "host document data or metadata changed");
		fails++;
	} else {
		emit_case(out, "lower_object_unchanged", true, 0,
			  "host document remains owned by the lower filesystem");
	}

	fails += !!check_counter(out, &policy, "lookup", AFS_COUNTER_LOOKUP);
	fails += !!check_counter(out, &policy, "readdir", AFS_COUNTER_READDIR);
	fails += !!check_counter(out, &policy, "select", AFS_COUNTER_SELECT);
	fails += !!check_counter(out, &policy, "hide_lookup",
				 AFS_COUNTER_HIDE_LOOKUP);
	fails += !!check_counter(out, &policy, "hide_readdir",
				 AFS_COUNTER_HIDE_READDIR);

cleanup:
	if (policy.attached) {
		ret = destroy_policy(&policy);
		if (ret) {
			emit_case(out, "detach_policy", false, -ret,
				  "policy detach failed");
			fails++;
		} else {
			emit_case(out, "detach_policy", true, 0,
				  "policy detached");
		}
	} else {
		emit_case(out, "detach_policy", true, 0,
			  "policy was never attached");
	}
	if (target_registered) {
		ret = clear_targets_for_cgroup(cgroup_a);
		emit_case(out, "clear_registered_document", !ret,
			  ret ? -ret : 0,
			  "application A target registry cleared");
		fails += !!ret;
	}
	if (cgroup_a[0])
		rmdir(cgroup_a);
	if (cgroup_b[0])
		rmdir(cgroup_b);
	if (host_payload[0])
		unlink(host_payload);
	if (unrelated_payload[0])
		unlink(unrelated_payload);
	if (unrelated_document[0])
		rmdir(unrelated_document);
	if (unrelated[0])
		rmdir(unrelated);
	if (host_document[0])
		rmdir(host_document);
	if (document[0])
		rmdir(document);
	if (view[0])
		rmdir(view);
	rmdir(root);
	fprintf(out,
		"{\"event\":\"application-file-sharing-summary\","
		"\"result_level\":\"kvm_application_file_sharing_preflight\","
		"\"workload\":\"sandboxed-application-file-sharing\","
		"\"source_system\":\"xdg-document-portal\","
		"\"applications\":2,"
		"\"pass\":%s,\"failures\":%d}\n",
		fails ? "false" : "true", fails);
	fclose(out);
	return fails ? 1 : 0;
}
