# OSDI evaluation workload IDs.
#
# The owning workload directories live under workload/<id>/.

OSDI_WORKLOADS_BUILD := \
	w1-redis-build \
	w1-nginx-build

OSDI_WORKLOADS_FIXTURE := \
	w2-nginx-fixture \
	w2-postgres-secret-fixture

OSDI_WORKLOADS_CHECKPOINT := \
	w3-redis-podman-criu \
	w3-nginx-podman-criu

OSDI_WORKLOADS_CACHE := \
	w4-ccache-redis-nginx \
	w4-buildkit-prometheus-go-cache

OSDI_WORKLOADS_ALL := \
	$(OSDI_WORKLOADS_BUILD) \
	$(OSDI_WORKLOADS_FIXTURE) \
	$(OSDI_WORKLOADS_CHECKPOINT) \
	$(OSDI_WORKLOADS_CACHE)

