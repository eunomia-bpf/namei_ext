/* SPDX-License-Identifier: MIT */
#include "ebpfos_uapi.h"
#include <elf.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/bpf.h>
#include <linux/unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>
#ifndef __NR_bpf
#error "bpf syscall number is unavailable"
#endif
static int bpf_syscall(enum bpf_cmd command, union bpf_attr *attr){return (int)syscall(__NR_bpf,command,attr,sizeof(*attr));}
static void *map_file(const char *path,size_t *size_out){struct stat st;void *data;int fd=open(path,O_RDONLY|O_CLOEXEC);if(fd<0)return MAP_FAILED;if(fstat(fd,&st)<0||st.st_size<=0){close(fd);errno=EINVAL;return MAP_FAILED;}data=mmap(NULL,(size_t)st.st_size,PROT_READ,MAP_PRIVATE,fd,0);close(fd);if(data==MAP_FAILED)return MAP_FAILED;*size_out=(size_t)st.st_size;return data;}
static const Elf64_Shdr *find_section(const void *data,size_t size,const char *wanted){const Elf64_Ehdr *eh=data;const Elf64_Shdr *shdr;const char *names;unsigned int i;if(size<sizeof(*eh)||memcmp(eh->e_ident,ELFMAG,SELFMAG)||eh->e_ident[EI_CLASS]!=ELFCLASS64||eh->e_machine!=EM_BPF||eh->e_shentsize!=sizeof(Elf64_Shdr)||!eh->e_shnum||eh->e_shstrndx>=eh->e_shnum)return NULL;if(eh->e_shoff>size||(uint64_t)eh->e_shnum*sizeof(*shdr)>size-eh->e_shoff)return NULL;shdr=(const Elf64_Shdr*)((const char*)data+eh->e_shoff);if(shdr[eh->e_shstrndx].sh_offset>size||shdr[eh->e_shstrndx].sh_size>size-shdr[eh->e_shstrndx].sh_offset)return NULL;names=(const char*)data+shdr[eh->e_shstrndx].sh_offset;for(i=0;i<eh->e_shnum;i++){const char *name;if(shdr[i].sh_name>=shdr[eh->e_shstrndx].sh_size)continue;name=names+shdr[i].sh_name;if(!strcmp(name,wanted)){if(shdr[i].sh_offset>size||shdr[i].sh_size>size-shdr[i].sh_offset)return NULL;return &shdr[i];}}return NULL;}
static int load_raw_program(const void *data,size_t size,const char *section){const Elf64_Shdr *program=find_section(data,size,section);static const char license[]="GPL";char *log;union bpf_attr attr={0};int fd;if(!program||!program->sh_size||program->sh_size%sizeof(struct bpf_insn)){errno=ENOEXEC;return -1;}log=calloc(1,1U<<20);if(!log)return -1;attr.prog_type=BPF_PROG_TYPE_RAW_TRACEPOINT;attr.insn_cnt=(uint32_t)(program->sh_size/sizeof(struct bpf_insn));attr.insns=(uint64_t)(uintptr_t)((const char*)data+program->sh_offset);attr.license=(uint64_t)(uintptr_t)license;attr.log_buf=(uint64_t)(uintptr_t)log;attr.log_size=1U<<20;attr.log_level=1;fd=bpf_syscall(BPF_PROG_LOAD,&attr);if(fd<0)fprintf(stderr,"BPF_PROG_LOAD %s/raw_tracepoint: %s\n%s\n",section,strerror(errno),log);free(log);return fd;}
static uint64_t parse_u64(const char *text){char *end=NULL;unsigned long long value;errno=0;value=strtoull(text,&end,0);if(errno||!end||*end){fprintf(stderr,"invalid integer: %s\n",text);exit(2);}return (uint64_t)value;}
int main(int argc,char **argv){struct ebpfos_ioc_set_hook hook={.prog_fd=-1};struct ebpfos_ioc_commit commit={0};const char *device=getenv("EBPFOS_DEVICE"),*object,*section;size_t size=0;void *data=MAP_FAILED;int ctl=-1,prog=-1,result=1;if(argc!=5){fprintf(stderr,"usage: %s OBJECT SECTION HOOK_ID ABI_HASH\n",argv[0]);return 2;}object=argv[1];section=argv[2];hook.hook_id=(uint32_t)parse_u64(argv[3]);hook.abi_hash=parse_u64(argv[4]);if(hook.hook_id>=EBPFOS_HOOK_MAX)return 2;if(!device)device="/dev/ebpfos";data=map_file(object,&size);if(data==MAP_FAILED){perror(object);goto out;}prog=load_raw_program(data,size,section);if(prog<0)goto out;ctl=open(device,O_RDWR|O_CLOEXEC);if(ctl<0){perror(device);goto out;}hook.prog_fd=prog;if(ioctl(ctl,EBPFOS_IOC_BEGIN)<0||ioctl(ctl,EBPFOS_IOC_SET_HOOK,&hook)<0||ioctl(ctl,EBPFOS_IOC_COMMIT,&commit)<0){perror("eBPFOS install transaction");(void)ioctl(ctl,EBPFOS_IOC_ABORT);goto out;}printf("installed object=%s section=%s hook=%u generation=%llu\n",object,section,hook.hook_id,(unsigned long long)commit.new_generation);result=0;out:if(ctl>=0)close(ctl);if(prog>=0)close(prog);if(data!=MAP_FAILED)munmap(data,size);return result;}
