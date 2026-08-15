// SPDX-License-Identifier: GPL-2.0-only
#include <linux/bpf.h>
#include <linux/err.h>
#include <linux/filter.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/rcupdate.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/ebpfos.h>

struct ebpfos_slot { struct bpf_prog *prog; u64 abi_hash; u64 flags; };
struct ebpfos_state_slot { struct bpf_map *map; u64 schema_hash; u64 flags; };
struct ebpfos_graph {
	u64 generation, hook_mask, state_mask;
	struct ebpfos_slot slots[EBPFOS_HOOK_MAX];
	struct ebpfos_state_slot state[EBPFOS_MAX_STATE_SLOTS];
};
struct ebpfos_file { struct ebpfos_graph *pending; };
static DEFINE_MUTEX(ebpfos_graph_lock);
static struct ebpfos_graph __rcu *ebpfos_active_graph;
static const u64 ebpfos_hook_abi[EBPFOS_HOOK_MAX] = {
	[EBPFOS_HOOK_SYSCALL_ENTER]=EBPFOS_ABI_SYSCALL_ENTER,
	[EBPFOS_HOOK_SYSCALL_EXIT]=EBPFOS_ABI_SYSCALL_EXIT,
	[EBPFOS_HOOK_VFS_LOOKUP]=EBPFOS_ABI_VFS_LOOKUP,
	[EBPFOS_HOOK_VFS_READDIR]=EBPFOS_ABI_VFS_READDIR,
	[EBPFOS_HOOK_SCHED_SELECT]=EBPFOS_ABI_SCHED_SELECT,
	[EBPFOS_HOOK_SCHED_ENQUEUE]=EBPFOS_ABI_SCHED_ENQUEUE,
	[EBPFOS_HOOK_MM_RECLAIM]=EBPFOS_ABI_MM_RECLAIM,
	[EBPFOS_HOOK_BLOCK_SUBMIT]=EBPFOS_ABI_BLOCK_SUBMIT,
	[EBPFOS_HOOK_NET_RX]=EBPFOS_ABI_NET_RX,
	[EBPFOS_HOOK_NET_TX]=EBPFOS_ABI_NET_TX,
	[EBPFOS_HOOK_SECURITY]=EBPFOS_ABI_SECURITY,
	[EBPFOS_HOOK_DRIVER_PROBE]=EBPFOS_ABI_DRIVER_PROBE,
	[EBPFOS_HOOK_DRIVER_LIFECYCLE]=EBPFOS_ABI_DRIVER_LIFECYCLE,
};

static void ebpfos_graph_put(struct ebpfos_graph *g)
{
	unsigned int i;
	if (!g) return;
	for (i=0;i<EBPFOS_HOOK_MAX;i++) if (g->slots[i].prog) bpf_prog_put(g->slots[i].prog);
	for (i=0;i<EBPFOS_MAX_STATE_SLOTS;i++) if (g->state[i].map) bpf_map_put(g->state[i].map);
	kfree(g);
}

static struct ebpfos_graph *ebpfos_graph_clone_locked(void)
{
	struct ebpfos_graph *old, *new;
	unsigned int i;
	lockdep_assert_held(&ebpfos_graph_lock);
	old=rcu_dereference_protected(ebpfos_active_graph,lockdep_is_held(&ebpfos_graph_lock));
	new=kzalloc(sizeof(*new),GFP_KERNEL);
	if (!new) return NULL;
	if (!old) return new;
	new->generation=old->generation; new->hook_mask=old->hook_mask; new->state_mask=old->state_mask;
	for (i=0;i<EBPFOS_HOOK_MAX;i++){ new->slots[i]=old->slots[i]; if(new->slots[i].prog)bpf_prog_inc(new->slots[i].prog); }
	for (i=0;i<EBPFOS_MAX_STATE_SLOTS;i++){ new->state[i]=old->state[i]; if(new->state[i].map)bpf_map_inc(new->state[i].map); }
	return new;
}

u32 ebpfos_run_hook(enum ebpfos_hook_id hook,const u64 *args,u32 nr_args)
{
	struct ebpfos_graph *g; struct bpf_prog *p; u64 ctx[3+EBPFOS_MAX_ARGS]={0};
	u32 r=EBPFOS_ACTION(EBPFOS_VERDICT_CONTINUE,0),i;
	if ((unsigned int)hook>=EBPFOS_HOOK_MAX) return r;
	if (nr_args>EBPFOS_MAX_ARGS) nr_args=EBPFOS_MAX_ARGS;
	rcu_read_lock(); g=rcu_dereference(ebpfos_active_graph);
	if (!g || !(g->hook_mask & BIT_ULL(hook))) goto out;
	p=g->slots[hook].prog; if(!p) goto out;
	ctx[0]=hook; ctx[1]=g->generation; ctx[2]=nr_args;
	for(i=0;i<nr_args;i++) ctx[3+i]=args[i];
	r=bpf_prog_run_pin_on_cpu(p,ctx);
out: rcu_read_unlock(); return r;
}
EXPORT_SYMBOL_GPL(ebpfos_run_hook);

bool ebpfos_hook_enabled(enum ebpfos_hook_id hook)
{
	struct ebpfos_graph *g; bool e=false;
	if ((unsigned int)hook>=EBPFOS_HOOK_MAX) return false;
	rcu_read_lock(); g=rcu_dereference(ebpfos_active_graph); if(g)e=g->hook_mask & BIT_ULL(hook); rcu_read_unlock(); return e;
}
EXPORT_SYMBOL_GPL(ebpfos_hook_enabled);

static int ebpfos_open(struct inode *inode,struct file *file){ struct ebpfos_file *s=kzalloc(sizeof(*s),GFP_KERNEL); if(!s)return -ENOMEM; file->private_data=s; return 0; }
static int ebpfos_release(struct inode *inode,struct file *file){ struct ebpfos_file *s=file->private_data; if(s){ebpfos_graph_put(s->pending);kfree(s);} return 0; }
static long ebpfos_ioctl_version(void __user *argp){ struct ebpfos_ioc_version v={.uapi_version=EBPFOS_UAPI_VERSION,.hook_count=EBPFOS_HOOK_MAX}; return copy_to_user(argp,&v,sizeof(v))?-EFAULT:0; }
static long ebpfos_ioctl_begin(struct ebpfos_file *s){ struct ebpfos_graph *p; if(s->pending)return -EBUSY; mutex_lock(&ebpfos_graph_lock); p=ebpfos_graph_clone_locked(); mutex_unlock(&ebpfos_graph_lock); if(!p)return -ENOMEM; s->pending=p; return 0; }

static long ebpfos_ioctl_set_hook(struct ebpfos_file *s,void __user *argp)
{
	struct ebpfos_ioc_set_hook q; struct bpf_prog *p=NULL,*old;
	if(!s->pending)return -EINVAL; if(copy_from_user(&q,argp,sizeof(q)))return -EFAULT;
	if(q.hook_id>=EBPFOS_HOOK_MAX)return -ERANGE;
	if(q.prog_fd>=0 && q.abi_hash!=ebpfos_hook_abi[q.hook_id])return -EPROTO;
	if(q.prog_fd>=0){p=bpf_prog_get_type_dev(q.prog_fd,BPF_PROG_TYPE_RAW_TRACEPOINT,false);if(IS_ERR(p))return PTR_ERR(p);}
	old=s->pending->slots[q.hook_id].prog; s->pending->slots[q.hook_id].prog=p; s->pending->slots[q.hook_id].abi_hash=q.abi_hash; s->pending->slots[q.hook_id].flags=q.flags;
	if(p)s->pending->hook_mask|=BIT_ULL(q.hook_id);else s->pending->hook_mask&=~BIT_ULL(q.hook_id); if(old)bpf_prog_put(old); return 0;
}

static long ebpfos_ioctl_set_state(struct ebpfos_file *s,void __user *argp)
{
	struct ebpfos_ioc_set_state q; struct bpf_map *m=NULL,*old;
	if(!s->pending)return -EINVAL; if(copy_from_user(&q,argp,sizeof(q)))return -EFAULT; if(q.slot>=EBPFOS_MAX_STATE_SLOTS)return -ERANGE;
	old=s->pending->state[q.slot].map;
	if(old && q.map_fd>=0 && s->pending->state[q.slot].schema_hash!=q.schema_hash && (!(q.flags&EBPFOS_STATE_F_MIGRATED)||q.previous_schema_hash!=s->pending->state[q.slot].schema_hash))return -EXDEV;
	if(q.map_fd>=0){m=bpf_map_get(q.map_fd);if(IS_ERR(m))return PTR_ERR(m);}
	s->pending->state[q.slot].map=m; s->pending->state[q.slot].schema_hash=q.schema_hash; s->pending->state[q.slot].flags=q.flags;
	if(m)s->pending->state_mask|=BIT_ULL(q.slot);else s->pending->state_mask&=~BIT_ULL(q.slot); if(old)bpf_map_put(old); return 0;
}

static long ebpfos_ioctl_commit(struct ebpfos_file *s,void __user *argp)
{
	struct ebpfos_ioc_commit q; struct ebpfos_graph *old,*new;
	if(!s->pending)return -EINVAL; if(copy_from_user(&q,argp,sizeof(q)))return -EFAULT;
	mutex_lock(&ebpfos_graph_lock); old=rcu_dereference_protected(ebpfos_active_graph,lockdep_is_held(&ebpfos_graph_lock));
	if(q.expected_generation && old && q.expected_generation!=old->generation){mutex_unlock(&ebpfos_graph_lock);return -ESTALE;}
	new=s->pending; new->generation=old?old->generation+1:1; s->pending=NULL; rcu_assign_pointer(ebpfos_active_graph,new); q.new_generation=new->generation; mutex_unlock(&ebpfos_graph_lock);
	synchronize_rcu(); ebpfos_graph_put(old); return copy_to_user(argp,&q,sizeof(q))?-EFAULT:0;
}
static long ebpfos_ioctl_status(void __user *argp){struct ebpfos_ioc_status s={0};struct ebpfos_graph*g;rcu_read_lock();g=rcu_dereference(ebpfos_active_graph);if(g){s.generation=g->generation;s.hook_mask=g->hook_mask;s.state_mask=g->state_mask;}rcu_read_unlock();return copy_to_user(argp,&s,sizeof(s))?-EFAULT:0;}
static long ebpfos_ioctl_run(void __user *argp){struct ebpfos_ioc_run q;if(copy_from_user(&q,argp,sizeof(q)))return -EFAULT;if(q.hook_id>=EBPFOS_HOOK_MAX||q.nr_args>EBPFOS_MAX_ARGS)return -ERANGE;q.result=ebpfos_run_hook(q.hook_id,q.args,q.nr_args);return copy_to_user(argp,&q,sizeof(q))?-EFAULT:0;}
static long ebpfos_ioctl(struct file *file,unsigned int cmd,unsigned long arg)
{
	struct ebpfos_file*s=file->private_data;void __user*argp=(void __user*)arg;
	switch(cmd){case EBPFOS_IOC_VERSION:return ebpfos_ioctl_version(argp);case EBPFOS_IOC_BEGIN:return ebpfos_ioctl_begin(s);case EBPFOS_IOC_SET_HOOK:return ebpfos_ioctl_set_hook(s,argp);case EBPFOS_IOC_COMMIT:return ebpfos_ioctl_commit(s,argp);case EBPFOS_IOC_ABORT:ebpfos_graph_put(s->pending);s->pending=NULL;return 0;case EBPFOS_IOC_STATUS:return ebpfos_ioctl_status(argp);case EBPFOS_IOC_RUN:return ebpfos_ioctl_run(argp);case EBPFOS_IOC_SET_STATE:return ebpfos_ioctl_set_state(s,argp);default:return -ENOTTY;}
}
static const struct file_operations ebpfos_fops={.owner=THIS_MODULE,.open=ebpfos_open,.release=ebpfos_release,.unlocked_ioctl=ebpfos_ioctl,
#ifdef CONFIG_COMPAT
.compat_ioctl=ebpfos_ioctl,
#endif
.llseek=noop_llseek};
static struct miscdevice ebpfos_miscdev={.minor=MISC_DYNAMIC_MINOR,.name="ebpfos",.fops=&ebpfos_fops,.mode=0600};
static int __init ebpfos_init(void){struct ebpfos_graph*i;int e;i=kzalloc(sizeof(*i),GFP_KERNEL);if(!i)return -ENOMEM;i->generation=1;rcu_assign_pointer(ebpfos_active_graph,i);e=misc_register(&ebpfos_miscdev);if(e){RCU_INIT_POINTER(ebpfos_active_graph,NULL);kfree(i);return e;}pr_info("ebpfos: composition nucleus ready, generation=1\n");return 0;}
#ifdef MODULE
static void __exit ebpfos_exit(void){struct ebpfos_graph*old;misc_deregister(&ebpfos_miscdev);mutex_lock(&ebpfos_graph_lock);old=rcu_dereference_protected(ebpfos_active_graph,lockdep_is_held(&ebpfos_graph_lock));RCU_INIT_POINTER(ebpfos_active_graph,NULL);mutex_unlock(&ebpfos_graph_lock);synchronize_rcu();ebpfos_graph_put(old);}
#endif
subsys_initcall(ebpfos_init);
#ifdef MODULE
module_exit(ebpfos_exit);
#endif
MODULE_DESCRIPTION("eBPFOS transactional eBPF component graph");
MODULE_AUTHOR("eunomia-bpf community");
MODULE_LICENSE("GPL");
MODULE_VERSION("0.2");
MODULE_IMPORT_NS(BPF_INTERNAL);
