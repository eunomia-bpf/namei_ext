#ifndef NAMEI_EXT_BPF_H
#define NAMEI_EXT_BPF_H

typedef unsigned char __u8;
typedef unsigned int __u32;
typedef unsigned long long __u64;

#define SEC(name) __attribute__((section(name), used))

#define BPF_NAMEI_EXT_NAME_MAX 64

#define BPF_NAMEI_EXT_LOOKUP 0
#define BPF_NAMEI_EXT_READDIR 1

#define BPF_NAMEI_EXT_PASS 0
#define BPF_NAMEI_EXT_REDIRECT 1

struct bpf_namei_ext_ctx {
	__u32 event;
	__u32 flags;
	__u32 name_len;
	__u32 name_hash;
	__u64 cgroup_id;
	__u8 name[BPF_NAMEI_EXT_NAME_MAX];
	__u32 redirect_name_len;
	__u32 reserved;
	__u8 redirect_name[BPF_NAMEI_EXT_NAME_MAX];
};

#endif /* NAMEI_EXT_BPF_H */
