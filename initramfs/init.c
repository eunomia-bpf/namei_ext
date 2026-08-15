// SPDX-License-Identifier: MIT
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <linux/reboot.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/reboot.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

static void mount_one(const char *source, const char *target, const char *type)
{
	if (mkdir(target, 0755) && errno != EEXIST)
		perror(target);
	if (mount(source, target, type, 0, NULL) && errno != EBUSY)
		perror(type);
}

static int runv(char *const argv[])
{
	pid_t pid = fork();
	int status;
	if (pid < 0)
		return 127;
	if (pid == 0) {
		execv(argv[0], argv);
		perror(argv[0]);
		_exit(127);
	}
	if (waitpid(pid, &status, 0) < 0)
		return 127;
	return WIFEXITED(status) ? WEXITSTATUS(status) : 128;
}

static int run1(const char *path, const char *arg)
{
	char *const argv[] = { (char *)path, (char *)arg, NULL };
	return runv(argv);
}

static int install(const char *object, const char *section,
		   const char *hook, const char *abi)
{
	char *const argv[] = {
		"/bin/ebpfos-load", (char *)object, (char *)section,
		(char *)hook, (char *)abi, NULL,
	};
	return runv(argv);
}

static int touch_file(const char *path)
{
	int fd = open(path, O_CREAT | O_RDWR | O_TRUNC, 0644);
	if (fd < 0)
		return -1;
	if (write(fd, "ok\n", 3) != 3) {
		close(fd);
		return -1;
	}
	close(fd);
	return 0;
}

static int expect_open(const char *path, int should_succeed)
{
	int fd;
	errno = 0;
	fd = open(path, O_RDONLY);
	if (fd >= 0)
		close(fd);
	if (should_succeed)
		return fd >= 0 ? 0 : -1;
	return fd < 0 && errno == EACCES ? 0 : -1;
}

static int native_bpf_replacement_test(void)
{
	pid_t ppid = getppid();
	int failures = 0;

	if (install("/opt/ebpfos/test_override.bpf.o",
		    "raw_tp/ebpfos_syscall_test", "0", "0x6d23c2ef91efa8b9"))
		failures++;
	if (getppid() != 4242) {
		printf("EBPFOS_SYSCALL_REPLACE_FAIL got=%d\n", (int)getppid());
		failures++;
	} else {
		puts("EBPFOS_SYSCALL_REPLACE_PASS");
	}
	if (install("/opt/ebpfos/syscall.bpf.o", "raw_tp/ebpfos_syscall",
		    "0", "0x6d23c2ef91efa8b9"))
		failures++;
	if (getppid() != ppid) {
		printf("EBPFOS_SYSCALL_ROLLFORWARD_FAIL got=%d want=%d\n",
		       (int)getppid(), (int)ppid);
		failures++;
	} else {
		puts("EBPFOS_SYSCALL_ROLLFORWARD_PASS");
	}

	mount_one("tmpfs", "/tmp", "tmpfs");
	if (touch_file("/tmp/denyxx") || touch_file("/tmp/allow"))
		failures++;
	if (install("/opt/ebpfos/test_deny_len6.bpf.o",
		    "raw_tp/ebpfos_vfs_test", "2", "0x15ad64cb3a2fddd5"))
		failures++;
	if (expect_open("/tmp/denyxx", 0) || expect_open("/tmp/allow", 1)) {
		puts("EBPFOS_VFS_REPLACE_FAIL");
		failures++;
	} else {
		puts("EBPFOS_VFS_REPLACE_PASS");
	}
	if (install("/opt/ebpfos/filesystem.bpf.o",
		    "raw_tp/ebpfos_vfs_lookup", "2", "0x15ad64cb3a2fddd5"))
		failures++;
	if (expect_open("/tmp/denyxx", 1)) {
		puts("EBPFOS_VFS_ROLLFORWARD_FAIL");
		failures++;
	} else {
		puts("EBPFOS_VFS_ROLLFORWARD_PASS");
	}

	failures += install("/opt/ebpfos/syscall.bpf.o", "raw_tp/ebpfos_syscall",
			    "1", "0xccaea0a5c69ba3b3") != 0;
	failures += install("/opt/ebpfos/filesystem.bpf.o", "raw_tp/ebpfos_vfs_readdir",
			    "3", "0x76a4934657508e52") != 0;
	failures += install("/opt/ebpfos/scheduler.bpf.o", "raw_tp/ebpfos_sched",
			    "4", "0xe9bf4388fce4d2d3") != 0;
	failures += install("/opt/ebpfos/scheduler.bpf.o", "raw_tp/ebpfos_sched",
			    "5", "0x27b841226676ba43") != 0;
	failures += install("/opt/ebpfos/memory.bpf.o", "raw_tp/ebpfos_mm",
			    "6", "0xe1137d1be95f0529") != 0;
	failures += install("/opt/ebpfos/block.bpf.o", "raw_tp/ebpfos_block",
			    "7", "0xbdcaa660e509145b") != 0;
	failures += install("/opt/ebpfos/network.bpf.o", "raw_tp/ebpfos_net_rx",
			    "8", "0x702a869a2a96a073") != 0;
	failures += install("/opt/ebpfos/network.bpf.o", "raw_tp/ebpfos_net_tx",
			    "9", "0xf9d9b7dfcf0fb589") != 0;
	failures += install("/opt/ebpfos/security.bpf.o", "raw_tp/ebpfos_security",
			    "10", "0x8fa27536eeabab62") != 0;
	failures += install("/opt/ebpfos/driver.bpf.o", "raw_tp/ebpfos_driver",
			    "11", "0x087fa77d3aa0d222") != 0;
	failures += install("/opt/ebpfos/lifecycle.bpf.o",
			    "raw_tp/ebpfos_driver_lifecycle", "12",
			    "0x8a7fbda2b451c51c") != 0;

	if (!failures)
		puts("EBPFOS_NATIVE_BPF_GRAPH_PASS");
	return failures ? 1 : 0;
}

int main(void)
{
	int status_result, demo_result, native_result;
	char *const clear_syscall[] = { "/bin/ebpfosctl", "clear", "0", NULL };

	mount_one("proc", "/proc", "proc");
	mount_one("sysfs", "/sys", "sysfs");
	mount_one("devtmpfs", "/dev", "devtmpfs");
	puts("EBPFOS_TEST_BEGIN");
	status_result = run1("/bin/ebpfosctl", "status");
	demo_result = run1("/bin/ebpfosctl", "demo");
	native_result = native_bpf_replacement_test();
	if (!status_result && !demo_result && !native_result)
		puts("EBPFOS_TEST_PASS");
	else
		printf("EBPFOS_TEST_FAIL status=%d demo=%d native=%d\n",
		       status_result, demo_result, native_result);
	(void)runv(clear_syscall);
	fflush(NULL);
	sync();
	reboot(LINUX_REBOOT_CMD_POWER_OFF);
	return status_result || demo_result || native_result;
}
