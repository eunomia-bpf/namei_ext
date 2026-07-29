WRAPFS_VERSION := 0.1

ccflags-y += -DWRAPFS_VERSION=\"$(WRAPFS_VERSION)\"

obj-m += wrapfs.o

wrapfs-y := dentry.o file.o inode.o main.o super.o lookup.o
