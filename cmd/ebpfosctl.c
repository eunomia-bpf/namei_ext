/* SPDX-License-Identifier: MIT */
#include "ebpfos_uapi.h"
#include <errno.h>
#include <fcntl.h>
#include <linux/bpf.h>
#include <linux/unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>
#include <unistd.h>
#ifndef __NR_bpf
#error "bpf syscall number is unavailable"
#endif
#define EBPF_ALU64 0x07
#define EBPF_MOV 0xb0
#define EBPF_K 0x00
#define EBPF_JMP 0x05
#define EBPF_EXIT 0x90
#define EBPF_REG_0 0
#define EBPF_INSN(_code,_dst,_src,_off,_imm) ((struct bpf_insn){.code=(_code),.dst_reg=(_dst),.src_reg=(_src),.off=(_off),.imm=(_imm)})
static int bpf_syscall(enum bpf_cmd command,union bpf_attr *attr){return (int)syscall(__NR_bpf,command,attr,sizeof(*attr));}
static int create_state_map(void){union bpf_attr attr={0};attr.map_type=BPF_MAP_TYPE_ARRAY;attr.key_size=sizeof(uint32_t);attr.value_size=sizeof(uint64_t);attr.max_entries=1;return bpf_syscall(BPF_MAP_CREATE,&attr);}
static int state_map_update(int fd,uint32_t key,uint64_t value){union bpf_attr attr={0};attr.map_fd=fd;attr.key=(uint64_t)(uintptr_t)&key;attr.value=(uint64_t)(uintptr_t)&value;attr.flags=BPF_ANY;return bpf_syscall(BPF_MAP_UPDATE_ELEM,&attr);}
static int state_map_lookup(int fd,uint32_t key,uint64_t *value){union bpf_attr attr={0};attr.map_fd=fd;attr.key=(uint64_t)(uintptr_t)&key;attr.value=(uint64_t)(uintptr_t)value;return bpf_syscall(BPF_MAP_LOOKUP_ELEM,&attr);}
static int load_constant_program(uint32_t value){char log[65536]={0};static const char license[]="GPL";struct bpf_insn instructions[]={EBPF_INSN(EBPF_ALU64|EBPF_MOV|EBPF_K,EBPF_REG_0,0,0,(int32_t)value),EBPF_INSN(EBPF_JMP|EBPF_EXIT,0,0,0,0)};union bpf_attr attr={0};int fd;attr.prog_type=BPF_PROG_TYPE_RAW_TRACEPOINT;attr.insn_cnt=sizeof(instructions)/sizeof(instructions[0]);attr.insns=(uint64_t)(uintptr_t)instructions;attr.license=(uint64_t)(uintptr_t)license;attr.log_buf=(uint64_t)(uintptr_t)log;attr.log_size=sizeof(log);attr.log_level=1;fd=bpf_syscall(BPF_PROG_LOAD,&attr);if(fd<0)fprintf(stderr,"BPF_PROG_LOAD: %s\n%s\n",strerror(errno),log);return fd;}
static int check_version(int fd){struct ebpfos_ioc_version v;if(ioctl(fd,EBPFOS_IOC_VERSION,&v)<0){perror("EBPFOS_IOC_VERSION");return 1;}if(v.uapi_version!=EBPFOS_UAPI_VERSION||v.hook_count!=EBPFOS_HOOK_MAX){fprintf(stderr,"eBPFOS UAPI mismatch\n");return 1;}return 0;}
static int print_status(int fd){struct ebpfos_ioc_status s;if(ioctl(fd,EBPFOS_IOC_STATUS,&s)<0){perror("EBPFOS_IOC_STATUS");return 1;}printf("generation=%llu hook_mask=0x%llx state_mask=0x%llx\n",(unsigned long long)s.generation,(unsigned long long)s.hook_mask,(unsigned long long)s.state_mask);return 0;}
static int demo(int fd){const uint32_t action=EBPFOS_ACTION(EBPFOS_VERDICT_OVERRIDE,42);const uint64_t schema_v1=0x54cdc088c51dce20ULL,schema_v2=0x54cdc388c51dd339ULL;struct ebpfos_ioc_set_hook set={.hook_id=EBPFOS_HOOK_SECURITY,.prog_fd=-1,.abi_hash=EBPFOS_ABI_SECURITY};struct ebpfos_ioc_set_state st={.slot=0,.map_fd=-1,.schema_hash=schema_v1};struct ebpfos_ioc_commit commit={0};struct ebpfos_ioc_run run={.hook_id=EBPFOS_HOOK_SECURITY,.nr_args=1,.args={39}};uint64_t value=0;int program=load_constant_program(action),m1=create_state_map(),m2=-1,result=1;if(program<0||m1<0)goto out;if(state_map_update(m1,0,41)<0)goto out;set.prog_fd=program;st.map_fd=m1;if(ioctl(fd,EBPFOS_IOC_BEGIN)<0||ioctl(fd,EBPFOS_IOC_SET_HOOK,&set)<0||ioctl(fd,EBPFOS_IOC_SET_STATE,&st)<0||ioctl(fd,EBPFOS_IOC_COMMIT,&commit)<0)goto out;m2=create_state_map();if(m2<0)goto out;st.map_fd=m2;st.schema_hash=schema_v2;st.previous_schema_hash=0;st.flags=0;if(ioctl(fd,EBPFOS_IOC_BEGIN)<0)goto out;errno=0;if(ioctl(fd,EBPFOS_IOC_SET_STATE,&st)==0||errno!=EXDEV){(void)ioctl(fd,EBPFOS_IOC_ABORT);goto out;}if(ioctl(fd,EBPFOS_IOC_ABORT)<0)goto out;if(state_map_lookup(m1,0,&value)<0||state_map_update(m2,0,value)<0)goto out;st.previous_schema_hash=schema_v1;st.flags=EBPFOS_STATE_F_MIGRATED;if(ioctl(fd,EBPFOS_IOC_BEGIN)<0||ioctl(fd,EBPFOS_IOC_SET_STATE,&st)<0){(void)ioctl(fd,EBPFOS_IOC_ABORT);goto out;}commit.expected_generation=commit.new_generation;if(ioctl(fd,EBPFOS_IOC_COMMIT,&commit)<0)goto out;value=0;if(state_map_lookup(m2,0,&value)<0||value!=41)goto out;if(ioctl(fd,EBPFOS_IOC_RUN,&run)<0)goto out;printf("committed generation=%llu action=0x%x state=%llu\n",(unsigned long long)commit.new_generation,run.result,(unsigned long long)value);result=run.result==action?0:1;out:if(m2>=0)close(m2);if(m1>=0)close(m1);if(program>=0)close(program);return result;}
static uint64_t parse_u64(const char *t){char *e=NULL;unsigned long long v;errno=0;v=strtoull(t,&e,0);if(errno||!e||*e){fprintf(stderr,"invalid integer: %s\n",t);exit(2);}return (uint64_t)v;}
static uint64_t hook_abi(uint32_t h){switch(h){case EBPFOS_HOOK_SYSCALL_ENTER:return EBPFOS_ABI_SYSCALL_ENTER;case EBPFOS_HOOK_SYSCALL_EXIT:return EBPFOS_ABI_SYSCALL_EXIT;case EBPFOS_HOOK_VFS_LOOKUP:return EBPFOS_ABI_VFS_LOOKUP;case EBPFOS_HOOK_VFS_READDIR:return EBPFOS_ABI_VFS_READDIR;case EBPFOS_HOOK_SCHED_SELECT:return EBPFOS_ABI_SCHED_SELECT;case EBPFOS_HOOK_SCHED_ENQUEUE:return EBPFOS_ABI_SCHED_ENQUEUE;case EBPFOS_HOOK_MM_RECLAIM:return EBPFOS_ABI_MM_RECLAIM;case EBPFOS_HOOK_BLOCK_SUBMIT:return EBPFOS_ABI_BLOCK_SUBMIT;case EBPFOS_HOOK_NET_RX:return EBPFOS_ABI_NET_RX;case EBPFOS_HOOK_NET_TX:return EBPFOS_ABI_NET_TX;case EBPFOS_HOOK_SECURITY:return EBPFOS_ABI_SECURITY;case EBPFOS_HOOK_DRIVER_PROBE:return EBPFOS_ABI_DRIVER_PROBE;case EBPFOS_HOOK_DRIVER_LIFECYCLE:return EBPFOS_ABI_DRIVER_LIFECYCLE;default:return 0;}}
static int clear_hook(int fd,const char *t){struct ebpfos_ioc_set_hook s={.prog_fd=-1};struct ebpfos_ioc_commit c={0};s.hook_id=(uint32_t)parse_u64(t);s.abi_hash=hook_abi(s.hook_id);if(!s.abi_hash)return 2;if(ioctl(fd,EBPFOS_IOC_BEGIN)<0||ioctl(fd,EBPFOS_IOC_SET_HOOK,&s)<0||ioctl(fd,EBPFOS_IOC_COMMIT,&c)<0){(void)ioctl(fd,EBPFOS_IOC_ABORT);return 1;}printf("cleared hook=%u generation=%llu\n",s.hook_id,(unsigned long long)c.new_generation);return 0;}
static int run_hook(int fd,int argc,char **argv){struct ebpfos_ioc_run r={0};int i;if(argc<3||argc>3+EBPFOS_MAX_ARGS)return 2;r.hook_id=(uint32_t)parse_u64(argv[2]);r.nr_args=(uint32_t)(argc-3);for(i=0;i<argc-3;i++)r.args[i]=parse_u64(argv[i+3]);if(ioctl(fd,EBPFOS_IOC_RUN,&r)<0)return 1;printf("hook=%u result=0x%x verdict=%u payload=%u\n",r.hook_id,r.result,EBPFOS_ACTION_VERDICT(r.result),EBPFOS_ACTION_PAYLOAD(r.result));return 0;}
int main(int argc,char **argv){const char *device=getenv("EBPFOS_DEVICE");int fd,result;if(!device)device="/dev/ebpfos";if(argc<2)return 2;fd=open(device,O_RDWR|O_CLOEXEC);if(fd<0){perror(device);return 1;}if(check_version(fd)){close(fd);return 1;}if(!strcmp(argv[1],"status"))result=print_status(fd);else if(!strcmp(argv[1],"demo"))result=demo(fd);else if(!strcmp(argv[1],"run"))result=run_hook(fd,argc,argv);else if(!strcmp(argv[1],"clear")&&argc==3)result=clear_hook(fd,argv[2]);else result=2;close(fd);return result;}
