# FxMark RQ2 Result

- Repetitions: 10 paired five-boot blocks
- Bootstrap samples: 10000
- Bootstrap seed: 20260726
- Predeclared gate verdict: **inconclusive_or_mixed**

| Test | Workers | Unattached / stock (95% CI) | SELECT / FUSE (95% CI) | FUSE measured requests |
| --- | ---: | ---: | ---: | ---: |
| MRPL | 1 | 0.982 [0.978, 1.005] | 1.084 [1.040, 1.099] | 1 |
| MRPL | 2 | 0.983 [0.966, 0.997] | 1.075 [1.064, 1.102] | 2 |
| MRPL | 4 | 0.981 [0.958, 1.012] | 1.088 [1.049, 1.115] | 4 |
| MRPM | 1 | 1.000 [0.987, 1.005] | 1.068 [1.051, 1.079] | 8 |
| MRPM | 2 | 1.003 [0.982, 1.009] | 1.064 [1.048, 1.072] | 15 |
| MRPM | 4 | 1.003 [0.990, 1.009] | 1.058 [1.035, 1.075] | 16 |
| MRPH | 1 | 1.010 [0.985, 1.015] | 1.058 [1.039, 1.081] | 1 |
| MRPH | 2 | 1.013 [1.000, 1.023] | 1.052 [1.034, 1.070] | 1 |
| MRPH | 4 | 1.013 [1.006, 1.020] | 1.066 [1.049, 1.077] | 1 |

## Active Policy Cost

| Test | Workers | PASS / stock (95% CI) | SELECT / stock (95% CI) | FUSE / stock (95% CI) | SELECT / PASS (95% CI) |
| --- | ---: | ---: | ---: | ---: | ---: |
| MRPL | 1 | 0.887 [0.873, 0.898] | 0.881 [0.864, 0.894] | 0.818 [0.808, 0.831] | 0.997 [0.970, 1.020] |
| MRPL | 2 | 0.886 [0.851, 0.904] | 0.885 [0.863, 0.891] | 0.811 [0.797, 0.833] | 0.998 [0.975, 1.022] |
| MRPL | 4 | 0.884 [0.880, 0.895] | 0.883 [0.861, 0.893] | 0.818 [0.785, 0.836] | 0.981 [0.973, 1.011] |
| MRPM | 1 | 0.914 [0.910, 0.935] | 0.919 [0.913, 0.927] | 0.864 [0.849, 0.879] | 0.999 [0.988, 1.010] |
| MRPM | 2 | 0.925 [0.918, 0.942] | 0.925 [0.921, 0.937] | 0.872 [0.863, 0.878] | 0.992 [0.989, 1.008] |
| MRPM | 4 | 0.928 [0.913, 0.936] | 0.921 [0.909, 0.925] | 0.867 [0.857, 0.885] | 0.993 [0.982, 1.005] |
| MRPH | 1 | 0.916 [0.907, 0.932] | 0.917 [0.904, 0.926] | 0.861 [0.855, 0.875] | 0.994 [0.992, 1.002] |
| MRPH | 2 | 0.926 [0.916, 0.941] | 0.920 [0.902, 0.928] | 0.869 [0.852, 0.888] | 0.988 [0.980, 0.999] |
| MRPH | 4 | 0.934 [0.928, 0.953] | 0.932 [0.921, 0.947] | 0.881 [0.866, 0.893] | 0.997 [0.979, 1.011] |

The verdict above covers only the two predeclared admission gates. The active-policy table reports the full throughput cost and must be interpreted with the primary table.

This report is generated from the complete raw JSONL matrix. It is scoped to cache-hot `stat()` path resolution in the pinned FxMark source and does not establish open, readdir, cache-cold, or tail-latency behavior.
