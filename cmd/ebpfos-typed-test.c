/* SPDX-License-Identifier: MIT */
#define _GNU_SOURCE
#include <arpa/inet.h>
#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/if.h>
#include <linux/sockios.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

struct loaded_object {
	struct bpf_object *obj;
	int hits_fd;
};

static struct loaded_object load_object(const char *path, const char *hits_map)
{
	struct loaded_object loaded = { 0 };
	struct bpf_map *map;
	long error;

	loaded.hits_fd = -1;
	loaded.obj = bpf_object__open_file(path, NULL);
	error = libbpf_get_error(loaded.obj);
	if (error) {
		fprintf(stderr, "open %s: %s\n", path, strerror(-error));
		loaded.obj = NULL;
		return loaded;
	}
	if (bpf_object__load(loaded.obj)) {
		fprintf(stderr, "load %s failed\n", path);
		bpf_object__close(loaded.obj);
		loaded.obj = NULL;
		return loaded;
	}
	if (hits_map) {
		map = bpf_object__find_map_by_name(loaded.obj, hits_map);
		if (!map) {
			fprintf(stderr, "%s: map %s not found\n", path, hits_map);
			bpf_object__close(loaded.obj);
			loaded.obj = NULL;
			return loaded;
		}
		loaded.hits_fd = bpf_map__fd(map);
	}
	return loaded;
}

static struct bpf_link *attach_ops(struct bpf_object *obj, const char *name)
{
	struct bpf_map *map = bpf_object__find_map_by_name(obj, name);
	struct bpf_link *link;
	long error;

	if (!map) {
		fprintf(stderr, "struct_ops map %s not found\n", name);
		return NULL;
	}
	link = bpf_map__attach_struct_ops(map);
	error = libbpf_get_error(link);
	if (error) {
		fprintf(stderr, "attach %s: %s\n", name, strerror(-error));
		return NULL;
	}
	return link;
}

static unsigned long long hit_count(int fd, unsigned int key)
{
	unsigned long long value = 0;

	if (fd < 0 || bpf_map_lookup_elem(fd, &key, &value))
		return 0;
	return value;
}

static int fs_test(struct loaded_object *obj)
{
	struct bpf_link *link;
	int fd;

	fd = open("/tmp/denyxx", O_CREAT | O_RDWR | O_TRUNC, 0644);
	if (fd < 0)
		return 1;
	close(fd);
	link = attach_ops(obj->obj, "ebpfos_test_fs");
	if (!link)
		return 1;
	errno = 0;
	fd = open("/tmp/denyxx", O_RDONLY);
	if (fd >= 0 || errno != EACCES || hit_count(obj->hits_fd, 0) == 0) {
		if (fd >= 0)
			close(fd);
		bpf_link__destroy(link);
		return 1;
	}
	bpf_link__destroy(link);
	fd = open("/tmp/denyxx", O_RDONLY);
	if (fd < 0)
		return 1;
	close(fd);
	puts("EBPFOS_TYPED_FS_PASS");
	return 0;
}

static int bring_loopback_up(void)
{
	struct ifreq request = { 0 };
	int fd = socket(AF_INET, SOCK_DGRAM, 0);

	if (fd < 0)
		return 1;
	strncpy(request.ifr_name, "lo", sizeof(request.ifr_name) - 1);
	if (ioctl(fd, SIOCGIFFLAGS, &request)) {
		close(fd);
		return 1;
	}
	request.ifr_flags |= IFF_UP | IFF_RUNNING;
	if (ioctl(fd, SIOCSIFFLAGS, &request)) {
		close(fd);
		return 1;
	}
	close(fd);
	return 0;
}

static int net_test(struct loaded_object *obj)
{
	struct sockaddr_in address = { .sin_family = AF_INET };
	struct timeval timeout = { .tv_sec = 0, .tv_usec = 250000 };
	struct bpf_link *link;
	socklen_t length = sizeof(address);
	char byte = 'x';
	int rx = -1, tx = -1;
	int result = 1;

	if (bring_loopback_up())
		return 1;
	rx = socket(AF_INET, SOCK_DGRAM, 0);
	tx = socket(AF_INET, SOCK_DGRAM, 0);
	if (rx < 0 || tx < 0)
		goto out;
	address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
	address.sin_port = 0;
	if (bind(rx, (struct sockaddr *)&address, sizeof(address)) ||
	    getsockname(rx, (struct sockaddr *)&address, &length))
		goto out;
	setsockopt(rx, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
	link = attach_ops(obj->obj, "ebpfos_test_net");
	if (!link)
		goto out;
	if (sendto(tx, &byte, 1, 0, (struct sockaddr *)&address,
		   sizeof(address)) < 0) {
		bpf_link__destroy(link);
		goto out;
	}
	errno = 0;
	if (recv(rx, &byte, 1, 0) >= 0 ||
	    (errno != EAGAIN && errno != EWOULDBLOCK) ||
	    (hit_count(obj->hits_fd, 4) == 0 && hit_count(obj->hits_fd, 5) == 0)) {
		bpf_link__destroy(link);
		goto out;
	}
	bpf_link__destroy(link);
	if (sendto(tx, &byte, 1, 0, (struct sockaddr *)&address,
		   sizeof(address)) != 1 || recv(rx, &byte, 1, 0) != 1)
		goto out;
	puts("EBPFOS_TYPED_NET_PASS");
	result = 0;
out:
	if (rx >= 0)
		close(rx);
	if (tx >= 0)
		close(tx);
	return result;
}

static int block_test(struct loaded_object *obj)
{
	struct bpf_link *link;
	char buffer[4096];
	ssize_t written;
	int fd;

	fd = open("/dev/vda", O_RDWR | O_SYNC);
	if (fd < 0)
		return 1;
	memset(buffer, 0xa5, sizeof(buffer));
	link = attach_ops(obj->obj, "ebpfos_test_block");
	if (!link) {
		close(fd);
		return 1;
	}
	errno = 0;
	written = pwrite(fd, buffer, sizeof(buffer), 0);
	if (written == (ssize_t)sizeof(buffer) && fsync(fd) == 0) {
		bpf_link__destroy(link);
		close(fd);
		return 1;
	}
	if (hit_count(obj->hits_fd, 3) == 0) {
		bpf_link__destroy(link);
		close(fd);
		return 1;
	}
	bpf_link__destroy(link);
	if (pwrite(fd, buffer, sizeof(buffer), 0) != (ssize_t)sizeof(buffer) ||
	    fsync(fd)) {
		close(fd);
		return 1;
	}
	close(fd);
	puts("EBPFOS_TYPED_BLOCK_PASS");
	return 0;
}

static int write_text(const char *path, const char *text)
{
	int fd = open(path, O_WRONLY);
	ssize_t length = (ssize_t)strlen(text);
	ssize_t written;

	if (fd < 0)
		return 1;
	written = write(fd, text, (size_t)length);
	close(fd);
	return written == length ? 0 : 1;
}

static int find_virtio_block(char *name, size_t size)
{
	DIR *dir = opendir("/sys/bus/virtio/drivers/virtio_blk");
	struct dirent *entry;

	if (!dir)
		return 1;
	while ((entry = readdir(dir))) {
		if (!strncmp(entry->d_name, "virtio", 6)) {
			snprintf(name, size, "%s", entry->d_name);
			closedir(dir);
			return 0;
		}
	}
	closedir(dir);
	return 1;
}

static int driver_bound(const char *name)
{
	char path[256];

	snprintf(path, sizeof(path), "/sys/bus/virtio/devices/%s/driver", name);
	return access(path, F_OK) == 0;
}

static int driver_test(struct loaded_object *obj)
{
	struct bpf_link *link;
	char name[64];

	if (find_virtio_block(name, sizeof(name)))
		return 1;
	link = attach_ops(obj->obj, "ebpfos_test_driver");
	if (!link)
		return 1;
	(void)write_text("/sys/bus/virtio/drivers/virtio_blk/unbind", name);
	if (!driver_bound(name) || hit_count(obj->hits_fd, 7) == 0) {
		bpf_link__destroy(link);
		return 1;
	}
	bpf_link__destroy(link);
	if (write_text("/sys/bus/virtio/drivers/virtio_blk/unbind", name) ||
	    driver_bound(name))
		return 1;
	link = attach_ops(obj->obj, "ebpfos_test_driver");
	if (!link)
		return 1;
	(void)write_text("/sys/bus/virtio/drivers/virtio_blk/bind", name);
	if (driver_bound(name) || hit_count(obj->hits_fd, 6) == 0) {
		bpf_link__destroy(link);
		return 1;
	}
	bpf_link__destroy(link);
	if (write_text("/sys/bus/virtio/drivers/virtio_blk/bind", name) ||
	    !driver_bound(name))
		return 1;
	puts("EBPFOS_TYPED_DRIVER_PASS");
	return 0;
}

static unsigned long long mem_available_kb(void)
{
	FILE *file = fopen("/proc/meminfo", "r");
	char label[64], unit[32];
	unsigned long long value;

	if (!file)
		return 0;
	while (fscanf(file, "%63s %llu %31s", label, &value, unit) == 3) {
		if (!strcmp(label, "MemAvailable:")) {
			fclose(file);
			return value;
		}
	}
	fclose(file);
	return 0;
}

static int mm_test(struct loaded_object *obj)
{
	struct bpf_link *link;
	unsigned long long available = mem_available_kb();
	pid_t child;
	int status;

	if (available < 65536)
		return 1;
	link = attach_ops(obj->obj, "ebpfos_test_mm");
	if (!link)
		return 1;
	child = fork();
	if (child == 0) {
		size_t bytes = (size_t)((available > 131072 ? available - 65536 :
				available * 3 / 4) * 1024ULL);
		char *memory;
		int adj = open("/proc/self/oom_score_adj", O_WRONLY);
		if (adj >= 0) {
			(void)write(adj, "1000", 4);
			close(adj);
		}
		memory = malloc(bytes);
		if (!memory)
			_exit(0);
		for (size_t offset = 0; offset < bytes; offset += 4096)
			memory[offset] = (char)offset;
		usleep(100000);
		free(memory);
		_exit(0);
	}
	if (child < 0) {
		bpf_link__destroy(link);
		return 1;
	}
	(void)waitpid(child, &status, 0);
	if (hit_count(obj->hits_fd, 2) == 0) {
		bpf_link__destroy(link);
		return 1;
	}
	bpf_link__destroy(link);
	puts("EBPFOS_TYPED_MM_PASS");
	return 0;
}

static int tcp_test(const char *path)
{
	struct loaded_object obj = load_object(path, "tcp_hits");
	struct bpf_link *link = NULL;
	struct sockaddr_in address = { .sin_family = AF_INET };
	socklen_t length = sizeof(address);
	char name[32] = { 0 };
	char buffer[65536];
	int server = -1, client = -1, accepted = -1;
	int result = 1;

	if (!obj.obj)
		return 1;
	link = attach_ops(obj.obj, "ebpfos_tcp_component");
	if (!link)
		goto out;
	server = socket(AF_INET, SOCK_STREAM, 0);
	client = socket(AF_INET, SOCK_STREAM, 0);
	if (server < 0 || client < 0)
		goto out;
	address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
	if (bind(server, (struct sockaddr *)&address, sizeof(address)) ||
	    getsockname(server, (struct sockaddr *)&address, &length) ||
	    listen(server, 1))
		goto out;
	if (setsockopt(client, IPPROTO_TCP, TCP_CONGESTION,
		       "ebpfreno", sizeof("ebpfreno")))
		goto out;
	if (connect(client, (struct sockaddr *)&address, sizeof(address)))
		goto out;
	accepted = accept(server, NULL, NULL);
	if (accepted < 0)
		goto out;
	memset(buffer, 0x5a, sizeof(buffer));
	for (int i = 0; i < 32; i++) {
		if (send(client, buffer, sizeof(buffer), 0) <= 0)
			goto out;
		if (recv(accepted, buffer, sizeof(buffer), MSG_WAITALL) <= 0)
			goto out;
	}
	length = sizeof(name);
	if (getsockopt(client, IPPROTO_TCP, TCP_CONGESTION, name, &length) ||
	    strcmp(name, "ebpfreno") || hit_count(obj.hits_fd, 0) == 0)
		goto out;
	puts("EBPFOS_TYPED_TCP_PASS");
	result = 0;
out:
	if (accepted >= 0)
		close(accepted);
	if (client >= 0)
		close(client);
	if (server >= 0)
		close(server);
	if (link)
		bpf_link__destroy(link);
	if (obj.obj)
		bpf_object__close(obj.obj);
	return result;
}

int main(int argc, char **argv)
{
	struct loaded_object subsystem;
	int failed = 0;

	if (argc != 3) {
		fprintf(stderr, "usage: %s TEST_SUBSYSTEMS_OBJECT TCP_OBJECT\n", argv[0]);
		return 2;
	}
	subsystem = load_object(argv[1], "test_hits");
	if (!subsystem.obj)
		return 1;
	failed |= fs_test(&subsystem);
	failed |= net_test(&subsystem);
	failed |= block_test(&subsystem);
	failed |= driver_test(&subsystem);
	failed |= mm_test(&subsystem);
	bpf_object__close(subsystem.obj);
	failed |= tcp_test(argv[2]);
	if (!failed)
		puts("EBPFOS_TYPED_SUBSYSTEMS_PASS");
	return failed ? 1 : 0;
}
