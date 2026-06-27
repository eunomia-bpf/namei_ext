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
include $(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk
include $(ROOT_DIR)/mk/kernel.mk
include $(ROOT_DIR)/mk/docker.mk
include $(ROOT_DIR)/mk/kvm.mk
include $(ROOT_DIR)/mk/table_budget.mk
include $(ROOT_DIR)/mk/report.mk
include $(ROOT_DIR)/mk/workload.mk
include $(ROOT_DIR)/mk/eval_osdi.mk

.DEFAULT_GOAL := phase1

.PHONY: all phase1 phase1-smoke check-prereqs abi bpf bench functional policy-load policy-semantic table-conformance table-budget w1-oracle kvm-w1-build-macrobench kvm-w1-build-baseline-macrobench kvm-w2-nginx-baseline-macrobench kvm-w3-redis-policy-macrobench kvm-w3-redis-baseline-macrobench kvm-w4-cache-transition-counterfactual kvm-w4-ccache-bulk-trace kvm-w4-ccache-bulk-policy-bridge kvm-w4-ccache-bulk-materialized-baseline-macrobench kvm-w4-ccache-bulk-fuse-baseline-macrobench kvm-w4-ccache-bulk-policy-compile kvm-w4-ccache-bulk-native-compile kvm-w4-ccache-bulk-fuse-compile kvm-w4-ccache-bulk-policy-macrobench kvm-w4-ccache-rule-macrobench kvm-w4-ccache-materialized-baseline-macrobench eval-osdi-smoke eval-osdi-policy-family-ledger eval-osdi-policy-family eval-osdi-baselines eval-osdi-macrobench-ledger eval-osdi-macrobench eval-osdi-workload-macrobench-ledger eval-osdi-workload-macrobench eval-osdi-c4-lookup-readdir-ledger eval-osdi-c4-lookup-readdir eval-osdi-claim-verdict-ledger eval-osdi-w1-build-workload-macrobench-ledger eval-osdi-w1-build-workload-macrobench eval-osdi-w2-nginx-workload-macrobench-ledger eval-osdi-w2-nginx-workload-macrobench eval-osdi-w3-redis-workload-macrobench-ledger eval-osdi-w3-redis-workload-macrobench eval-osdi-w4-ccache-workload-macrobench-ledger eval-osdi-w4-ccache-workload-macrobench eval-osdi-performance-tail eval-osdi-performance-ledger eval-osdi-performance-comparison eval-osdi-performance-tool-redirect-ledger eval-osdi-c3-residual-diagnostic-ledger eval-osdi-c5-rusage-nohook-ledger eval-osdi-c7-artifact-audit-ledger eval-osdi-performance eval-osdi-paper eval-osdi-paper-report help clean clean-results
.NOTPARALLEL: phase1

all: phase1

phase1: phase1-smoke kvm-policy-load kvm-policy-semantic kvm-w1-oracle kvm-w1-build-replay kvm-w1-release-build-replay kvm-w1-branch-probes kvm-w2-oracle kvm-w2-nginx-real kvm-w3-oracle kvm-w3-redis-replay kvm-w3-redis-table-replay kvm-w3-redis-counterfactual kvm-w4-oracle kvm-w4-cache-content kvm-w4-cache-table-content kvm-w4-cache-transition-counterfactual kvm-w4-ccache-real kvm-w4-ccache-trace kvm-w4-ccache-policy-bridge kvm-w4-ccache-policy-compile kvm-w4-ccache-parent-compile kvm-w4-ccache-table-compile kvm-w4-ccache-release-counterfactual table-budget kvm-functional kvm-bench docker-smoke report

phase1-smoke: check-prereqs abi bpf functional bench policy-load policy-semantic table-conformance w1-oracle kernel-objects kvm-smoke

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

table-conformance: bpf
	$(MAKE) -C "$(ROOT_DIR)/tests/table_conformance" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" RESULT_DIR="$(PHASE1_RESULT_DIR)" run

w1-oracle:
	$(MAKE) -C "$(ROOT_DIR)/tests/w1_oracle" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

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
	@printf '%s\n' '  make kvm-policy-load boot the modified kernel and load/attach all BPF policies'
	@printf '%s\n' '  make kvm-policy-semantic boot the modified kernel and check policy-family semantics'
	@printf '%s\n' '  make kvm-w1-oracle  boot the modified kernel and validate W1 trace-derived path oracle'
	@printf '%s\n' '  make kvm-w1-build-replay boot the modified kernel and validate W1 policy build replay witness'
	@printf '%s\n' '  make kvm-w1-release-build-replay boot the modified kernel and validate W1 policy release binary replay witness'
	@printf '%s\n' '  make kvm-w1-build-macrobench boot the modified kernel and write W1 setup/update PoC rows'
	@printf '%s\n' '  make kvm-w1-build-baseline-macrobench boot the modified kernel and write W1 build feature-equivalent baseline rows'
	@printf '%s\n' '  make kvm-w1-branch-probes boot the modified kernel and validate W1 poison/negative branch probes'
	@printf '%s\n' '  make kvm-w2-oracle  boot the modified kernel and validate W2 fixture path oracle'
	@printf '%s\n' '  make kvm-w2-nginx-real boot the modified kernel and run real nginx endpoint health oracle'
	@printf '%s\n' '  make kvm-w2-nginx-macrobench boot the modified kernel and write W2 nginx setup/update PoC rows'
	@printf '%s\n' '  make kvm-w2-nginx-baseline-macrobench boot the modified kernel and write W2 nginx feature-equivalent baseline rows'
	@printf '%s\n' '  make kvm-w3-oracle  boot the modified kernel and validate W3 checkpoint path oracle'
	@printf '%s\n' '  make kvm-w3-redis-replay boot the modified kernel and run Redis checkpoint replay witness'
	@printf '%s\n' '  make kvm-w3-redis-table-replay boot the modified kernel and run the same Redis replay through table_redirect'
	@printf '%s\n' '  make kvm-w3-redis-counterfactual boot the modified kernel and write W3 table-only counterfactual accounting'
	@printf '%s\n' '  make kvm-w3-redis-policy-macrobench boot the modified kernel and write W3 Redis policy setup/update rows'
	@printf '%s\n' '  make kvm-w3-redis-baseline-macrobench boot the modified kernel and write W3 Redis materialized/FUSE baseline rows'
	@printf '%s\n' '  make kvm-w4-oracle  boot the modified kernel and validate W4 cache path oracle'
	@printf '%s\n' '  make kvm-w4-cache-content boot the modified kernel and validate W4 cache content oracle'
	@printf '%s\n' '  make kvm-w4-cache-table-content boot the modified kernel and run W4 cache content through table_redirect'
	@printf '%s\n' '  make kvm-w4-cache-transition-counterfactual boot the modified kernel and run W4 stale/corrupt/update transition counterfactual'
	@printf '%s\n' '  make kvm-w4-ccache-real boot the modified kernel and run real ccache transition witness'
	@printf '%s\n' '  make kvm-w4-ccache-trace boot the modified kernel and trace real ccache cache-path file ops'
	@printf '%s\n' '  make kvm-w4-ccache-policy-bridge boot the modified kernel and validate trace-derived ccache cache objects through policy'
	@printf '%s\n' '  make kvm-w4-ccache-bulk-trace boot the modified kernel and trace multi-source real ccache cache-path ops'
	@printf '%s\n' '  make kvm-w4-ccache-bulk-policy-bridge boot the modified kernel and validate bulk trace-derived cache objects through policy'
	@printf '%s\n' '  make kvm-w4-ccache-bulk-materialized-baseline-macrobench boot the modified kernel and write W4 bulk materialized cache baseline rows'
	@printf '%s\n' '  make kvm-w4-ccache-bulk-fuse-baseline-macrobench boot the modified kernel and write W4 bulk FUSE cache baseline rows'
	@printf '%s\n' '  make kvm-w4-ccache-bulk-policy-compile boot the modified kernel and run bulk ccache hot compiles through attached cache policy'
	@printf '%s\n' '  make kvm-w4-ccache-bulk-native-compile boot the modified kernel and run bulk native ccache hot-compile baseline rows'
	@printf '%s\n' '  make kvm-w4-ccache-bulk-fuse-compile boot the modified kernel and run bulk ccache hot compiles through FUSE baseline'
	@printf '%s\n' '  make kvm-w4-ccache-bulk-policy-macrobench boot the modified kernel and write W4 bulk policy setup/update rows'
	@printf '%s\n' '  make kvm-w4-ccache-policy-compile boot the modified kernel and run real ccache hot compiles through attached cache policy'
	@printf '%s\n' '  make kvm-w4-ccache-parent-compile boot the modified kernel and run ccache hot compiles through parent-scoped cache policy'
	@printf '%s\n' '  make kvm-w4-ccache-table-compile boot the modified kernel and run the same ccache witness through table_redirect'
	@printf '%s\n' '  make kvm-w4-ccache-release-counterfactual boot the modified kernel and write W4 release-level counterfactual accounting'
	@printf '%s\n' '  make kvm-w4-ccache-rule-macrobench boot the modified kernel and write W4 ccache rule setup/update rows'
	@printf '%s\n' '  make kvm-w4-ccache-materialized-baseline-macrobench boot the modified kernel and write W4 materialized cache baseline rows'
	@printf '%s\n' '  make kvm-functional  boot the modified kernel and run functional tests'
	@printf '%s\n' '  make kvm-bench       boot the modified kernel and run microbenchmarks'
	@printf '%s\n' '  make kvm-eval-osdi-baselines boot the modified kernel and run external baseline smoke rows'
	@printf '%s\n' '  make abi             build and run ABI layout checks'
	@printf '%s\n' '  make bpf             build BPF component outputs'
	@printf '%s\n' '  make table-conformance check table_redirect source/object conformance'
	@printf '%s\n' '  make table-budget    write non-C8 table-only raw accounting from KVM oracle results'
	@printf '%s\n' '  make w1-oracle       build W1 trace-derived path oracle runner'
	@printf '%s\n' '  make functional      build functional-test component outputs'
	@printf '%s\n' '  make bench           build benchmark component outputs'
	@printf '%s\n' '  make report          write the current smoke report'
	@printf '%s\n' '  make workloads       fetch fixed sources, build/trace W1 real workloads, and write provenance'
	@printf '%s\n' '  make eval-osdi-workload-macrobench-ledger derive W1-W4 C2 workload inventory from current artifacts'
	@printf '%s\n' '  make eval-osdi-claim-verdict-ledger derive C1-C8 paper claim verdicts from current ledgers'
	@printf '%s\n' '  make eval-osdi-w3-redis-workload-macrobench-ledger derive W3 Redis policy/materialized/FUSE workload macrobench ledger'
	@printf '%s\n' '  make workload-build-graph generate W1 source traces and trace-witness manifests'
	@printf '%s\n' '  make workload-w1-build-output-oracle verify W1 host real-build output hashes'
	@printf '%s\n' '  make workload-w1-oracle-entries generate W1 trace-derived oracle TSV'
	@printf '%s\n' '  make workload-w2-oracle-entries generate W2 fixture oracle TSV'
	@printf '%s\n' '  make workload-w3-oracle-entries generate W3 checkpoint oracle TSV'
	@printf '%s\n' '  make workload-w3-podman-criu-capability audit host Podman/CRIU checkpoint capability'
	@printf '%s\n' '  make workload-w4-oracle-entries generate W4 cache oracle TSV'
	@printf '%s\n' '  make eval-osdi-smoke run Phase 1 and write the current OSDI evidence ledger'
	@printf '%s\n' '  make eval-osdi-policy-family-ledger write B12 ledger from an existing Phase 1 root'
	@printf '%s\n' '  make eval-osdi-policy-family hard-gate B12 policy-family release qualification'
	@printf '%s\n' '  make eval-osdi-baselines boot KVM and write external baseline smoke ledger'
	@printf '%s\n' '  make eval-osdi-workload-macrobench hard-gate W1-W4 C2 workload macrobench qualification'
	@printf '%s\n' '  make eval-osdi-c4-lookup-readdir-ledger derive the W1-W4 C4 lookup/readdir matrix from KVM oracles'
	@printf '%s\n' '  make eval-osdi-w1-build-workload-macrobench-ledger write W1 build workload comparison ledger'
	@printf '%s\n' '  make eval-osdi-w1-build-workload-macrobench hard-gate W1 build workload comparison qualification'
	@printf '%s\n' '  make eval-osdi-w2-nginx-workload-macrobench-ledger write W2 C2 partial workload comparison ledger'
	@printf '%s\n' '  make eval-osdi-w2-nginx-workload-macrobench hard-gate W2 C2 workload comparison qualification'
	@printf '%s\n' '  make eval-osdi-w4-ccache-workload-macrobench-ledger write W4 ccache workload comparison ledger'
	@printf '%s\n' '  make eval-osdi-w4-ccache-workload-macrobench hard-gate W4 ccache workload comparison qualification'
	@printf '%s\n' '  make eval-osdi-performance-tail write percentile/CI artifact from KVM bench_latency rows'
	@printf '%s\n' '  make eval-osdi-performance-ledger write B2/B8 performance ledger from a Phase 1 root'
	@printf '%s\n' '  make eval-osdi-performance-comparison write B2/B8 performance ratio and claim-verdict ledger'
	@printf '%s\n' '  make eval-osdi-performance-tool-redirect-ledger write scoped C3 tool-redirect performance verdict'
	@printf '%s\n' '  make eval-osdi-c3-residual-diagnostic-ledger diagnose full-suite C3/FUSE baseline residual blockers'
	@printf '%s\n' '  make eval-osdi-c5-rusage-nohook-ledger diagnose C5 pass-only residual with rusage/no-hook rows'
	@printf '%s\n' '  make eval-osdi-c7-artifact-audit-ledger audit paper artifacts and reproducibility blockers'
	@printf '%s\n' '  make eval-osdi-performance hard-gate release performance/baseline qualification'
	@printf '%s\n' '  make eval-osdi-paper run the current release-evaluation hard gates'
	@printf '%s\n' '  make eval-osdi-paper-report write the release report after hard gates pass'
	@printf '%s\n' '  make clean           remove build/cache outputs, keep results'
	@printf '%s\n' '  make clean-results   remove Phase 1 results'
	@printf '%s\n' '  make workload-clean-results remove workload provenance and run results'

clean: kernel-clean docker-clean
	$(MAKE) -C "$(ROOT_DIR)/tests/abi" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/bpf" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/bench/workloads" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/functional" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/policy_load" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/policy_semantic" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/table_conformance" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) -C "$(ROOT_DIR)/tests/w1_oracle" BUILD_ROOT="$(BUILD_ROOT)" clean
	$(MAKE) workload-clean
	rm -rf "$(BUILD_ROOT)"

clean-results:
	rm -rf "$(RESULT_ROOT)/phase1"
