// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
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

#define DOCUMENT_TARGET_ID 1
#define DOCUMENT_PAYLOAD "xdg-portal-existing-object\n"
#define UNRELATED_PAYLOAD "unrelated-document-object\n"

enum application_file_sharing_counter {
	AFS_COUNTER_TOTAL = 0,
	AFS_COUNTER_LOOKUP = 1,
	AFS_COUNTER_READDIR = 2,
	AFS_COUNTER_SELECT = 3,
	AFS_COUNTER_HIDE_LOOKUP = 4,
	AFS_COUNTER_HIDE_READDIR = 5,
	AFS_COUNTER_PASS = 6,
};

struct probe_paths {
	const char *view;
	const char *document;
	const char *payload;
	const char *unrelated_payload;
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

		if (namei_ext_move_self_to_cgroup(cgroup_path))
			_exit(1);
		if (!namei_ext_read_text_equals(paths->unrelated_payload,
					       UNRELATED_PAYLOAD))
			_exit(1);
		listed = directory_contains(paths->view, "document");
		if (visible) {
			if (stat(paths->document, &st) || !S_ISDIR(st.st_mode))
				_exit(1);
			if (!namei_ext_read_text_equals(paths->payload,
						       DOCUMENT_PAYLOAD))
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
	return namei_ext_wait_child(pid);
}

static int update_grant(struct namei_ext_harness_policy *policy,
			uint64_t cgroup_id,
			const char *parent, const char *name, bool grant)
{
	if (grant)
		return namei_ext_component_map_update(
			policy, "sharing_grants", cgroup_id, parent, name,
			DOCUMENT_TARGET_ID);
	return namei_ext_component_map_delete(
		policy, "sharing_grants", cgroup_id, parent, name);
}

static int register_scope(struct namei_ext_harness_policy *policy,
			  const char *parent, const char *name)
{
	return namei_ext_component_map_update(
		policy, "sharing_scopes", 0, parent, name, 1);
}

static int check_counter(FILE *out,
			 struct namei_ext_harness_policy *policy,
			 const char *name, uint32_t key)
{
	uint64_t value = 0;
	bool pass;
	int ret;

	ret = namei_ext_policy_counter(
		policy, "application_file_sharing_counters", key, &value);
	if (ret)
		return ret;
	pass = value > 0;
	emit_counter(out, name, value, pass);
	return pass ? 0 : -EINVAL;
}

int main(int argc, char **argv)
{
	const char *cgroup_root = "/sys/fs/cgroup";
	struct namei_ext_harness_policy policy = {
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
	uint64_t app_a_cgroup_id = 0;
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
	    namei_ext_path_join(view, sizeof(view), root, "view") ||
	    namei_ext_path_join(document, sizeof(document), view, "document") ||
	    namei_ext_path_join(host_document, sizeof(host_document), root,
				"host-document") ||
	    namei_ext_path_join(payload, sizeof(payload), document,
				"payload.txt") ||
	    namei_ext_path_join(host_payload, sizeof(host_payload),
				host_document, "payload.txt") ||
	    namei_ext_path_join(unrelated, sizeof(unrelated), root,
				"unrelated") ||
	    namei_ext_path_join(unrelated_document,
				sizeof(unrelated_document), unrelated,
				"document") ||
	    namei_ext_path_join(unrelated_payload, sizeof(unrelated_payload),
				unrelated_document, "payload.txt")) {
		emit_case(out, "paths", false, ENAMETOOLONG,
			  "path construction failed");
		fails++;
		goto cleanup;
	}
	if (mkdir(view, 0755) || mkdir(document, 0755) ||
	    mkdir(host_document, 0755) || mkdir(unrelated, 0755) ||
	    mkdir(unrelated_document, 0755) ||
	    namei_ext_write_text(host_payload, DOCUMENT_PAYLOAD) ||
	    namei_ext_write_text(unrelated_payload, UNRELATED_PAYLOAD) ||
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
	ret = namei_ext_cgroup_id(cgroup_a, &app_a_cgroup_id);
	if (ret) {
		emit_case(out, "application_cgroup_id", false, -ret,
			  "cgroup identity lookup failed");
		fails++;
		goto cleanup;
	}
	ret = namei_ext_register_target(cgroup_a, host_document,
					 DOCUMENT_TARGET_ID);
	if (ret) {
		emit_case(out, "register_existing_document", false, -ret,
			  "target registration in application cgroup failed");
		fails++;
		goto cleanup;
	}
	target_registered = true;
	emit_case(out, "register_existing_document", true, 0,
		  "existing host document registered for application A");

	if (namei_ext_policy_load_attach(argv[1], cgroup_root, &policy)) {
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
	    !namei_ext_read_text_equals(host_payload, DOCUMENT_PAYLOAD)) {
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
		ret = namei_ext_policy_destroy(&policy);
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
		ret = namei_ext_clear_targets(cgroup_a);
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
