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
	kvm-checkpoint-restore-preflight \
	kvm-fxmark-rq2-preflight \
	kvm-fxmark-fast-path-preflight

NAMEI_EXT_BLOCKED_DEPENDENCY_PREFLIGHT_ENTRYPOINTS := \
	kvm-service-config-rotation-preflight

NAMEI_EXT_FORMAL_CASE_STUDY_TARGETS := \
	experiment-agent-workspace-rq2
NAMEI_EXT_FORMAL_CASE_STUDY_ENTRYPOINTS := \
	$(NAMEI_EXT_FORMAL_CASE_STUDY_TARGETS) \
	kvm-agent-workspace-rq2

# Implemented entrypoints that are not eligible for aggregate evidence
# collection because their dependency gate is currently closed.
NAMEI_EXT_BLOCKED_FORMAL_CASE_STUDY_ENTRYPOINTS := \
	experiment-service-config-rotation \
	kvm-service-config-rotation

NAMEI_EXT_FORMAL_PERFORMANCE_TARGETS := \
	experiment-fxmark-rq2 \
	experiment-fxmark-fast-path
NAMEI_EXT_FORMAL_PERFORMANCE_ENTRYPOINTS := \
	$(NAMEI_EXT_FORMAL_PERFORMANCE_TARGETS) \
	kvm-fxmark-rq2 \
	kvm-fxmark-fast-path

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
