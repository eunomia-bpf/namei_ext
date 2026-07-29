// SPDX-License-Identifier: GPL-2.0

#ifndef NAMEI_EXT_RQ3_SEMANTIC_ORACLES_H
#define NAMEI_EXT_RQ3_SEMANTIC_ORACLES_H

#include <stdbool.h>
#include <stddef.h>
#include <string.h>

/*
 * One contract drives both runners. The condition-specific case names locate
 * the implementation evidence; operation and expected describe the shared
 * application-visible oracle.
 */
#define RQ3_SEMANTIC_ORACLES(X)                                             \
	X("base-main-bytes", "base_epoch_main", "base_lookup_main",         \
	  "read", "bytes=base-main")                                        \
	X("base-main-mode", "base_epoch_main_mode", "base_main_mode",       \
	  "stat", "mode=0644")                                               \
	X("base-hidden-lookup", "base_epoch_whiteout",                       \
	  "base_lookup_deleted_hidden", "stat", "errno=ENOENT")              \
	X("base-hidden-readdir", "base_epoch_readdir",                       \
	  "base_readdir_deleted_hidden", "readdir",                          \
	  "required=main,link,src,.git;absent=deleted,generated,cached")     \
	X("base-nested-src", "base_epoch_src_app", "base_nested_src",       \
	  "read", "bytes=base-app")                                         \
	X("base-nested-git", "base_epoch_git_head", "base_nested_git",      \
	  "read", "bytes=ref-main")                                         \
	X("base-symlink", "base_epoch_symlink", "base_symlink",             \
	  "readlink", "target=main.txt")                                    \
	X("base-symlink-follow", "base_epoch_symlink_follow",                \
	  "base_symlink_follow", "read", "bytes=base-main")                  \
	X("base-execute", "base_epoch_exec_tool", "base_exec_tool",         \
	  "exec", "exit=0")                                                  \
	X("base-denied-access", "base_epoch_denied_access",                  \
	  "base_unprivileged_access_denied", "access", "errno=EACCES")       \
	X("base-denied-mode", "base_epoch_denied_mode", "base_denied_mode", \
	  "stat", "mode=0000")                                               \
	X("upper-main-bytes", "upper_epoch_main", "upper_lookup_main",      \
	  "read", "bytes=upper-main")                                       \
	X("upper-main-mode", "upper_epoch_main_mode", "upper_main_mode",    \
	  "stat", "mode=0600")                                               \
	X("upper-hidden-lookup", "upper_epoch_whiteout",                     \
	  "upper_lookup_deleted_hidden", "stat", "errno=ENOENT")             \
	X("upper-hidden-readdir", "upper_epoch_readdir_before_write",        \
	  "upper_readdir_deleted_hidden", "readdir",                         \
	  "required=main,link,src,.git;absent=deleted,generated,cached")     \
	X("upper-nested-src", "upper_epoch_src_app", "upper_nested_src",    \
	  "read", "bytes=agent-edited-app")                                 \
	X("upper-nested-git", "upper_epoch_git_head", "upper_nested_git",   \
	  "read", "bytes=ref-agent")                                        \
	X("upper-symlink", "upper_epoch_symlink", "upper_symlink",          \
	  "readlink", "target=main.txt")                                    \
	X("upper-symlink-follow", "upper_epoch_symlink_follow",              \
	  "upper_symlink_follow", "read", "bytes=upper-main")                \
	X("upper-execute", "upper_epoch_exec_tool", "upper_exec_tool",      \
	  "exec", "exit=0")                                                  \
	X("upper-denied-access", "upper_epoch_denied_access",                \
	  "upper_unprivileged_access_denied", "access", "errno=EACCES")      \
	X("upper-denied-mode", "upper_epoch_denied_mode",                   \
	  "upper_denied_mode", "stat", "mode=0100")                          \
	X("generated-negative", "upper_generated_negative_before_write",    \
	  "generated_negative_before_create", "stat", "errno=ENOENT")        \
	X("generated-create",                                                \
	  "upper_epoch_create_write_fsync_fchmod_fstat",                     \
	  "generated_create_write_fsync_fchmod_fstat", "open-write",         \
	  "flags=CREAT,EXCL,WRONLY,CLOEXEC;fsync;mode=0640;size=19")          \
	X("generated-lower-bytes", "upper_generated_visible",               \
	  "generated_lower_visible", "read-lower",                           \
	  "bytes=generated-in-upper")                                       \
	X("generated-readdir", "upper_epoch_readdir_after_write",           \
	  "generated_readdir_visible", "readdir",                            \
	  "required=main,link,src,.git,generated;absent=deleted,cached")     \
	X("cached-negative-before-create",                                   \
	  "agentfs_cached_negative_before_create",                           \
	  "cached_negative_before_create", "stat", "errno=ENOENT")           \
	X("cached-negative-create", "agentfs_cached_negative_create",       \
	  "cached_negative_create", "open-write",                            \
	  "flags=CREAT,EXCL,WRONLY,CLOEXEC;mode=0644;bytes=cached-created")  \
	X("cached-negative-bytes", "agentfs_cached_negative_visible",       \
	  "cached_negative_read", "read", "bytes=cached-created")            \
	X("cached-negative-readdir",                                        \
	  "agentfs_cached_negative_readdir_visible",                         \
	  "cached_negative_readdir_visible", "readdir",                      \
	  "required=main,link,src,.git,generated,cached;absent=deleted")     \
	X("rename-generated", "agentfs_rename_generated_to_renamed",        \
	  "rename_generated_to_renamed", "rename", "generated->renamed")     \
	X("rename-old-absent", "agentfs_rename_generated_old_absent",       \
	  "rename_old_absent", "stat", "generated=ENOENT")                   \
	X("rename-new-bytes", "agentfs_rename_generated_new_visible",       \
	  "rename_new_visible", "read", "renamed=generated-in-upper")        \
	X("rename-restore", "agentfs_rename_restored_generated",            \
	  "rename_restore_generated", "rename", "renamed->generated")        \
	X("unlink-cached-negative", "agentfs_unlink_cached_created",        \
	  "unlink_cached_negative", "unlink", "cached=removed")              \
	X("unlink-result-absent", "agentfs_unlink_cached_absent",           \
	  "unlink_cached_negative_absent", "stat", "cached=ENOENT")          \
	X("final-lower-tree", "final_tree_manifest",                        \
	  "final_lower_tree_manifest", "manifest", "fields=19")

struct rq3_semantic_contract {
	const char *oracle_id;
	const char *namei_case;
	const char *wrapfs_case;
	const char *operation;
	const char *expected;
};

#define RQ3_ORACLE_ENTRY(id, namei, wrapfs, operation, expected)             \
	{ (id), (namei), (wrapfs), (operation), (expected) },
static const struct rq3_semantic_contract rq3_semantic_contracts[] = {
	RQ3_SEMANTIC_ORACLES(RQ3_ORACLE_ENTRY)
};
#undef RQ3_ORACLE_ENTRY

static inline const struct rq3_semantic_contract *
rq3_semantic_contract_for_case(const char *case_name, bool namei_ext)
{
	size_t i;

	for (i = 0;
	     i < sizeof(rq3_semantic_contracts) /
			 sizeof(rq3_semantic_contracts[0]);
	     i++) {
		const char *candidate = namei_ext ?
			rq3_semantic_contracts[i].namei_case :
			rq3_semantic_contracts[i].wrapfs_case;

		if (!strcmp(candidate, case_name))
			return &rq3_semantic_contracts[i];
	}
	return NULL;
}

#endif
