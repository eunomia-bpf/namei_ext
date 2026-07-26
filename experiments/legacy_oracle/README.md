# Legacy Multi-Workload Oracle

`namei_ext_w1_oracle.c` preserves the historical multi-workload runner used by
the existing ccache matrix and earlier experiments. It is not the template for
current industrial case studies.

The compatibility target remains:

```text
make w1-oracle
```

New W1--W7 experiments must use the shared `runner/` harness and a focused
directory under `experiments/`. Do not add new workload modes, source-system
adapters, or result schemas to this legacy binary.
