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
include $(ROOT_DIR)/mk/workload.mk

.DEFAULT_GOAL := phase1

.PHONY: all phase1 phase1-smoke check-prereqs abi bpf bench functional \
	policy-load policy-semantic agent-workspace \
	experiments experiment-agent-workspace experiment-env-cache \
	w1-oracle \
	help clean clean-results
.NOTPARALLEL: phase1 experiments

all: phase1

phase1: phase1-smoke kvm-policy-load kvm-functional

phase1-smoke: check-prereqs abi bpf functional bench policy-load policy-semantic kernel-objects kvm-smoke

experiments: experiment-agent-workspace experiment-env-cache

experiment-agent-workspace: kvm-agent-workspace-matrix

experiment-env-cache: kvm-build-cache-matrix

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

policy-load:
	$(MAKE) -C "$(ROOT_DIR)/tests/policy_load" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

policy-semantic:
	$(MAKE) -C "$(ROOT_DIR)/tests/policy_semantic" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

w1-oracle:
	$(MAKE) -C "$(ROOT_DIR)/tests/w1_oracle" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

agent-workspace:
	$(MAKE) -C "$(ROOT_DIR)/tests/agent_workspace" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

help:
	@printf '%s\n' 'Targets:'
	@printf '%s\n' ''
	@printf '%s\n' 'Current validation:'
	@printf '%s\n' '  make phase1          run current prototype validation: host checks, KVM smoke, policy load, functional KVM'
	@printf '%s\n' '  make phase1-smoke    check tools, build userspace/BPF, compile touched kernel objects, boot KVM smoke'
	@printf '%s\n' ''
	@printf '%s\n' 'Current experiment lifecycle:'
	@printf '%s\n' '  make experiments'
	@printf '%s\n' '                       run current integrated experiment targets; fails until all matrices exist'
	@printf '%s\n' '  make experiment-agent-workspace'
	@printf '%s\n' '                       run the Agent workspace lifecycle matrix and preserve raw KVM/FUSE results'
	@printf '%s\n' '  make experiment-env-cache'
	@printf '%s\n' '                       run the traditional Redis/nginx ccache build-cache matrix with namei_ext, native, and FUSE rows'
	@printf '%s\n' '  make kvm-agent-workspace-preflight'
	@printf '%s\n' '                       boot KVM and run the Agent workspace dependency preflight'
	@printf '%s\n' ''
	@printf '%s\n' 'Build and component checks:'
	@printf '%s\n' '  make kernel-config   build the committed x86_64 Phase 1 kernel config'
	@printf '%s\n' '  make kernel-objects  compile fs/namei.o fs/readdir.o fs/namei_ext.o'
	@printf '%s\n' '  make kernel          build the Phase 1 bzImage'
	@printf '%s\n' '  make docker          build and save the Phase 1 runtime image'
	@printf '%s\n' '  make docker-smoke    run the runtime image without a workspace bind mount'
	@printf '%s\n' '  make kvm-smoke       boot the modified kernel and run guest smoke'
	@printf '%s\n' '  make kvm-policy-load boot the modified kernel and load/attach all BPF policies'
	@printf '%s\n' '  make kvm-policy-semantic boot the modified kernel and check policy-family semantics'
	@printf '%s\n' '  make kvm-functional  boot the modified kernel and run functional tests'
	@printf '%s\n' '  make kvm-bench       boot the modified kernel and run microbenchmarks'
	@printf '%s\n' '  make abi             build and run ABI layout checks'
	@printf '%s\n' '  make bpf             build BPF component outputs'
	@printf '%s\n' '  make functional      build functional-test component outputs'
	@printf '%s\n' '  make bench           build benchmark component outputs'
	@printf '%s\n' ''
	@printf '%s\n' 'Cleanup:'
	@printf '%s\n' '  make clean           remove build/cache outputs, keep results'
	@printf '%s\n' '  make clean-results   remove Phase 1 results'

clean: kernel-clean docker-clean
	$(MAKE) -C "$(ROOT_DIR)/tests/abi" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/bpf" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/bench/workloads" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/functional" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/policy_load" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/policy_semantic" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/w1_oracle" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/agent_workspace" BUILD_ROOT="$(BUILD_ROOT)" clean
	rm -rf "$(BUILD_ROOT)/workloads" "$(CACHE_ROOT)/workloads"
	rm -rf "$(BUILD_ROOT)"

clean-results:
	rm -rf "$(RESULT_ROOT)/phase1"
