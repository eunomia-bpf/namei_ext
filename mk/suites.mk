# Public suite registry. Suite Makefiles own implementation; this file owns
# evidence-level classification and aggregate membership.

NAMEI_EXT_CURRENT_GATE_TARGETS := \
	kvm-agent-workspace-matrix \
	kvm-application-file-sharing-preflight \
	kvm-build-action-sandboxing-preflight

NAMEI_EXT_DEPENDENCY_PREFLIGHT_ENTRYPOINTS := \
	kvm-application-file-sharing-preflight \
	kvm-build-action-sandboxing-preflight \
	kvm-build-action-rq2-preflight \
	kvm-agent-workspace-rq2-preflight \
	kvm-agent-workspace-source-task-rq1-preflight \
	kvm-checkpoint-restore-preflight \
	kvm-spindle-staging-preflight \
	kvm-toolchain-environment-preflight \
	kvm-kubernetes-configmap-publication-rq1-preflight \
	kvm-fxmark-rq2-preflight \
	kvm-fxmark-fast-path-preflight \
	kvm-fxmark-readdir-preflight

NAMEI_EXT_BLOCKED_DEPENDENCY_PREFLIGHT_ENTRYPOINTS := \
	kvm-service-config-rotation-preflight

NAMEI_EXT_FORMAL_CASE_STUDY_TARGETS := \
	experiment-agent-workspace-rq2 \
	experiment-agent-workspace-rq3 \
	experiment-application-file-sharing-rq1 \
	experiment-build-action-sandboxing-rq1 \
	experiment-toolchain-environment
NAMEI_EXT_FORMAL_CASE_STUDY_ENTRYPOINTS := \
	$(NAMEI_EXT_FORMAL_CASE_STUDY_TARGETS) \
	kvm-agent-workspace-rq2 \
	kvm-agent-workspace-rq3 \
	kvm-application-file-sharing-rq1 \
	kvm-build-action-sandboxing-rq1 \
	kvm-toolchain-environment \
	experiment-kubernetes-configmap-publication-rq1 \
	kvm-kubernetes-configmap-publication-rq1 \
	experiment-spindle-staging \
	kvm-spindle-staging

# Implemented entrypoints that are not eligible for aggregate evidence
# collection because their dependency gate is currently closed.
NAMEI_EXT_BLOCKED_FORMAL_CASE_STUDY_ENTRYPOINTS := \
	experiment-service-config-rotation \
	kvm-service-config-rotation

NAMEI_EXT_FORMAL_PERFORMANCE_TARGETS := \
	experiment-fxmark-rq2 \
	experiment-fxmark-fast-path
# The readdir entrypoints are clean-tree gated but remain outside the aggregate
# target list until their independent KVM preflight passes.
NAMEI_EXT_FORMAL_PERFORMANCE_ENTRYPOINTS := \
	$(NAMEI_EXT_FORMAL_PERFORMANCE_TARGETS) \
	kvm-fxmark-rq2 \
	kvm-fxmark-fast-path \
	experiment-fxmark-readdir \
	kvm-fxmark-readdir

NAMEI_EXT_HISTORICAL_TARGETS := legacy-build-cache

# Compatibility name consumed by the shared KVM infrastructure.
CURRENT_EXPERIMENT_TARGETS := $(NAMEI_EXT_CURRENT_GATE_TARGETS)

CLEAN_SOURCE_EXPERIMENT_TARGETS := \
	$(sort \
		$(NAMEI_EXT_CURRENT_GATE_TARGETS) \
		$(NAMEI_EXT_DEPENDENCY_PREFLIGHT_ENTRYPOINTS) \
		$(NAMEI_EXT_BLOCKED_DEPENDENCY_PREFLIGHT_ENTRYPOINTS) \
		$(NAMEI_EXT_FORMAL_CASE_STUDY_ENTRYPOINTS) \
		$(NAMEI_EXT_BLOCKED_FORMAL_CASE_STUDY_ENTRYPOINTS) \
		$(NAMEI_EXT_FORMAL_PERFORMANCE_ENTRYPOINTS))
