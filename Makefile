SHELL := /bin/bash
.SHELLFLAGS := -e -o pipefail -c

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
KERNEL_DIR := $(ROOT_DIR)/kernel
BUILD_ROOT ?= $(ROOT_DIR)/.build
CACHE_ROOT ?= $(ROOT_DIR)/.cache
RESULT_ROOT ?= $(ROOT_DIR)/results

NPROC ?= $(shell nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
JOBS ?= $(NPROC)
ifeq ($(origin RUN_ID), undefined)
RUN_ID := $(shell date -u +%Y%m%dT%H%M%SZ)-$(shell od -An -N4 -tx4 /dev/urandom 2>/dev/null | tr -d ' \n')
endif

include $(ROOT_DIR)/configs/kvm/x86_64.mk
include $(ROOT_DIR)/configs/benchmarks/phase1.mk
include $(ROOT_DIR)/mk/kernel.mk
include $(ROOT_DIR)/mk/docker.mk
include $(ROOT_DIR)/mk/kvm.mk
include $(ROOT_DIR)/mk/report.mk

.DEFAULT_GOAL := phase1

.PHONY: all phase1 phase1-smoke check-prereqs abi bpf bench functional help clean clean-results

all: phase1

phase1: phase1-smoke kvm-functional kvm-bench docker-smoke report

phase1-smoke: check-prereqs abi bpf functional bench kernel-objects kvm-smoke

check-prereqs:
	command -v make >/dev/null
	command -v clang >/dev/null
	command -v docker >/dev/null
	command -v jq >/dev/null
	command -v $(VNG) >/dev/null
	command -v pahole >/dev/null
	test -r /dev/kvm
	test -w /dev/kvm

bpf:
	$(MAKE) -C "$(ROOT_DIR)/bpf" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

abi:
	$(MAKE) -C "$(ROOT_DIR)/tests/abi" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" RESULT_DIR="$(PHASE1_RESULT_DIR)" run

bench:
	$(MAKE) -C "$(ROOT_DIR)/bench/workloads" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

functional:
	$(MAKE) -C "$(ROOT_DIR)/tests/functional" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

help:
	@printf '%s\n' 'Targets:'
	@printf '%s\n' '  make phase1          run the current Phase 1 smoke flow and write a report'
	@printf '%s\n' '  make phase1-smoke    check tools, compile touched kernel objects, boot KVM smoke'
	@printf '%s\n' '  make kernel-config   build the committed x86_64 Phase 1 kernel config'
	@printf '%s\n' '  make kernel-objects  compile fs/namei.o fs/readdir.o fs/namei_ext.o'
	@printf '%s\n' '  make kernel          build the Phase 1 bzImage'
	@printf '%s\n' '  make docker          build and save the Phase 1 runtime image'
	@printf '%s\n' '  make docker-smoke    run the runtime image without a workspace bind mount'
	@printf '%s\n' '  make kvm-smoke       boot the modified kernel and run guest smoke'
	@printf '%s\n' '  make kvm-functional  boot the modified kernel and run functional tests'
	@printf '%s\n' '  make kvm-bench       boot the modified kernel and run microbenchmarks'
	@printf '%s\n' '  make abi             build and run ABI layout checks'
	@printf '%s\n' '  make bpf             build BPF component outputs'
	@printf '%s\n' '  make functional      build functional-test component outputs'
	@printf '%s\n' '  make bench           build benchmark component outputs'
	@printf '%s\n' '  make report          write the current smoke report'
	@printf '%s\n' '  make clean           remove build/cache outputs, keep results'
	@printf '%s\n' '  make clean-results   remove Phase 1 results'

clean: kernel-clean docker-clean
	$(MAKE) -C "$(ROOT_DIR)/tests/abi" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/bpf" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/bench/workloads" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/functional" BUILD_ROOT="$(BUILD_ROOT)" clean
	rm -rf "$(BUILD_ROOT)"

clean-results:
	rm -rf "$(RESULT_ROOT)/phase1"
