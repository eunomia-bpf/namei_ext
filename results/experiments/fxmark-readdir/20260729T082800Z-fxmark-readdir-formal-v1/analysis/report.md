# Corrected FxMark readdir analysis

- Mode: formal
- Paired blocks: 10
- Tests: MRDL, MRDM
- Workers: 1, 2, 4
- Bootstrap: 10000 paired resamples, seed 20260728
- Primary verdict: **mixed**

The primary gate requires every SELECT/FUSE 95% CI lower bound to exceed 1. Any upper bound at or below 1 is contradictory; all other complete outcomes are mixed.

| Test | Workers | SELECT/FUSE ratio (95% CI) | FUSE opendir | FUSE readdir | FUSE releasedir |
| --- | ---: | ---: | ---: | ---: | ---: |
| MRDL | 1 | 2.314 [2.223, 2.355] | 18289 | 256040 | 18289 |
| MRDL | 2 | 2.200 [2.178, 2.212] | 37974 | 531618 | 37974 |
| MRDL | 4 | 3.663 [3.505, 3.789] | 44467 | 622517 | 44467 |
| MRDM | 1 | 2.909 [2.833, 2.968] | 14346 | 200832 | 14346 |
| MRDM | 2 | 2.450 [2.332, 2.586] | 10500 | 272990 | 10500 |
| MRDM | 4 | 1.018 [0.907, 1.135] | 4647 | 232260 | 4647 |

## Throughput

| Test | Workers | Stock | Unattached | PASS | SELECT | FUSE |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| MRDL | 1 | 15105537.341 | 15083961.451 | 11659784.591 | 11663867.940 | 4995207.617 |
| MRDL | 2 | 28907252.651 | 28720747.318 | 22879651.738 | 22775286.676 | 10371611.781 |
| MRDL | 4 | 56873377.305 | 56845974.485 | 44993416.459 | 44926685.615 | 12144947.710 |
| MRDM | 1 | 14892418.115 | 14879705.967 | 11538258.610 | 11505725.022 | 3918143.828 |
| MRDM | 2 | 10872223.346 | 11003152.093 | 14367528.167 | 14208417.568 | 5734878.897 |
| MRDM | 4 | 5442950.349 | 5567977.989 | 5440092.359 | 5308026.407 | 5074022.025 |
