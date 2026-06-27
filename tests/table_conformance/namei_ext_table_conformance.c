// SPDX-License-Identifier: GPL-2.0
#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

struct check_state {
	FILE *out;
	unsigned int failures;
};

static char *read_file(const char *path, size_t *size_out)
{
	FILE *file;
	long size;
	char *buf;

	file = fopen(path, "rb");
	if (!file)
		return NULL;
	if (fseek(file, 0, SEEK_END) != 0) {
		fclose(file);
		return NULL;
	}
	size = ftell(file);
	if (size < 0) {
		fclose(file);
		return NULL;
	}
	if (fseek(file, 0, SEEK_SET) != 0) {
		fclose(file);
		return NULL;
	}
	buf = calloc((size_t)size + 1, 1);
	if (!buf) {
		fclose(file);
		return NULL;
	}
	if (size > 0 && fread(buf, 1, (size_t)size, file) != (size_t)size) {
		free(buf);
		fclose(file);
		return NULL;
	}
	fclose(file);
	*size_out = (size_t)size;
	return buf;
}

static unsigned int count_substr(const char *haystack, const char *needle)
{
	unsigned int count = 0;
	const char *p = haystack;
	size_t len = strlen(needle);

	while ((p = strstr(p, needle)) != NULL) {
		count++;
		p += len;
	}
	return count;
}

static char *slice_policy_body(const char *source)
{
	const char *sec = strstr(source, "SEC(\"cgroup/namei_ext\")");
	const char *func;
	const char *open;
	const char *p;
	int depth = 0;

	if (!sec)
		return NULL;
	func = strstr(sec, "int namei_ext_policy(");
	if (!func)
		return NULL;
	open = strchr(func, '{');
	if (!open)
		return NULL;
	for (p = open; *p; p++) {
		if (*p == '{')
			depth++;
		else if (*p == '}') {
			depth--;
			if (depth == 0) {
				size_t len = (size_t)(p - open + 1);
				char *body = calloc(len + 1, 1);
				if (!body)
					return NULL;
				memcpy(body, open, len);
				return body;
			}
		}
	}
	return NULL;
}

static void emit(struct check_state *state, const char *name, bool pass,
		 const char *detail)
{
	fprintf(state->out,
		"{\"event\":\"table-conformance\",\"name\":\"%s\",\"pass\":%s,\"detail\":\"%s\"}\n",
		name, pass ? "true" : "false", detail);
	if (!pass)
		state->failures++;
}

static void expect_count(struct check_state *state, const char *text,
			 const char *needle, unsigned int expected,
			 const char *name)
{
	unsigned int count = count_substr(text, needle);
	char detail[160];
	bool pass = count == expected;

	snprintf(detail, sizeof(detail), "expected %u occurrence(s), observed %u",
		 expected, count);
	emit(state, name, pass, detail);
}

static void forbid_any(struct check_state *state, const char *text,
		       const char *name, const char *const *needles,
		       size_t needle_count)
{
	size_t i;

	for (i = 0; i < needle_count; i++) {
		if (strstr(text, needles[i])) {
			char detail[160];
			snprintf(detail, sizeof(detail), "forbidden token present: %s",
				 needles[i]);
			emit(state, name, false, detail);
			return;
		}
	}
	emit(state, name, true, "no forbidden token present");
}

int main(int argc, char **argv)
{
	const char *out_path;
	const char *source_path;
	const char *object_path;
	struct check_state state = {};
	struct stat source_stat;
	struct stat object_stat;
	char *source = NULL;
	char *body = NULL;
	size_t source_size = 0;
	static const char *const forbidden_source[] = {
		"BPF_MAP_TYPE_ARRAY",
		"BPF_MAP_TYPE_PROG_ARRAY",
		"bpf_map_update_elem",
		"bpf_map_delete_elem",
		"bpf_tail_call",
		"bpf_loop",
		"bpf_get_prandom",
		"bpf_ktime_get",
		"bpf_probe_read",
	};
	static const char *const forbidden_body[] = {
		"if (",
		"for (",
		"while (",
		"switch (",
		"goto ",
		"else",
		"?",
		"namei_ext_is",
		"namei_ext_redirect_literal",
	};

	if (argc != 4) {
		fprintf(stderr, "usage: %s OUT_JSONL TABLE_SOURCE TABLE_OBJECT\n",
			argv[0]);
		return 2;
	}

	out_path = argv[1];
	source_path = argv[2];
	object_path = argv[3];
	state.out = fopen(out_path, "w");
	if (!state.out) {
		fprintf(stderr, "open %s: %s\n", out_path, strerror(errno));
		return 1;
	}

	source = read_file(source_path, &source_size);
	emit(&state, "source_readable", source != NULL && source_size > 0,
	     "table_redirect.bpf.c is readable and non-empty");
	emit(&state, "object_exists",
	     stat(object_path, &object_stat) == 0 && object_stat.st_size > 0,
	     "table_redirect.bpf.o exists and is non-empty");
	emit(&state, "source_stat", stat(source_path, &source_stat) == 0,
	     "source stat succeeded");
	if (!source || stat(source_path, &source_stat) != 0 ||
	    stat(object_path, &object_stat) != 0)
		goto summary;

	emit(&state, "object_fresh",
	     object_stat.st_mtime >= source_stat.st_mtime,
	     "object mtime is not older than source mtime");

	body = slice_policy_body(source);
	emit(&state, "policy_body_parse", body != NULL,
	     "single cgroup/namei_ext policy body parsed");
	if (!body)
		goto summary;

	expect_count(&state, source, "SEC(\"cgroup/namei_ext\")", 1,
		     "single_attach_section");
	expect_count(&state, source, "BPF_MAP_TYPE_HASH", 1, "hash_map_only");
	expect_count(&state, source, "exact_redirects", 2, "single_exact_map_use");
	expect_count(&state, source, "struct namei_ext_component_key", 2,
		     "component_key_map_type");
	expect_count(&state, source, "struct namei_ext_redirect_rule", 2,
		     "redirect_rule_map_type");
	expect_count(&state, body, "namei_ext_build_component_key(ctx, &key);",
		     1, "component_key_builder");
	expect_count(&state, body, "bpf_map_lookup_elem(&exact_redirects, &key)",
		     1, "single_exact_lookup");
	expect_count(&state, body, "return namei_ext_apply_rule(ctx, rule);",
		     1, "pass_redirect_return");
	forbid_any(&state, source, "no_forbidden_source_helpers",
		   forbidden_source,
		   sizeof(forbidden_source) / sizeof(forbidden_source[0]));
	forbid_any(&state, body, "no_policy_body_resolver_logic",
		   forbidden_body, sizeof(forbidden_body) / sizeof(forbidden_body[0]));

summary:
	fprintf(state.out,
		"{\"event\":\"table-conformance-summary\",\"pass\":%s,\"failures\":%u}\n",
		state.failures == 0 ? "true" : "false", state.failures);
	fclose(state.out);
	free(source);
	free(body);
	return state.failures == 0 ? 0 : 1;
}
