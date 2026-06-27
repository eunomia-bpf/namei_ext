# W4 bulk ccache 真实 workload 设计

## 背景

当前 W4 ccache release comparison 已经有更强的外部 `materialized_cache_view`
baseline。结果显示，小规模 Redis/nginx two-file trace 只有 4 个 cache objects、4 个
leaf parents，直接物化 baseline setup/update 更快。因此 W4 不能靠和
`table_redirect.bpf.c` 比较来支撑 C2/C8。

下一步应该扩大真实 workload，而不是修改论文结论。本设计增加一个 bulk ccache trace：
仍然使用真实 Redis/nginx 源码和 ccache hot compile，但从每个项目选择多份可独立编译的
C 源文件，产生更多 cache objects 和更高 cache-path 操作量。

## 目标

- 通过 Make target 在修改内核 KVM 中运行。
- 使用真实 Redis 7.2.14 和 nginx 1.26.3 源码，而不是手写 fixture。
- 生成 raw ccache hot compile trace、object hash、source manifest、ccache stats。
- 将 trace-derived cache objects 转换为 `w4-ccache-bulk-policy-bridge-entries.tsv`。
- 在 KVM 中 attach `cache_locality_view.bpf.c`，验证 trace-derived entries 的 lookup、
  content 和 readdir oracle。
- 作为后续 bulk rule macrobench、materialized baseline、FUSE/cache-remap baseline 和
  operation-weighted hit-rate 评估的输入。

## Workload 选择

默认 bulk source set 来自现有真实 workload 构建树：

Redis：

- `src/adlist.c`
- `src/crc64.c`
- `src/dict.c`
- `src/intset.c`
- `src/listpack.c`
- `src/lzf_c.c`
- `src/lzf_d.c`
- `src/siphash.c`
- `src/ziplist.c`
- `src/sha1.c`

nginx：

- `src/core/ngx_string.c`
- `src/core/ngx_palloc.c`
- `src/core/ngx_array.c`
- `src/core/ngx_hash.c`
- `src/core/ngx_list.c`
- `src/core/ngx_buf.c`
- `src/core/ngx_queue.c`
- `src/core/ngx_output_chain.c`
- `src/os/unix/ngx_alloc.c`
- `src/os/unix/ngx_files.c`

这些文件在当前 build tree 中用已有 include path 可独立 `ccache gcc -c`。失败的候选文件
不会进入默认列表。

## 正确性 oracle

bulk trace target 必须检查：

- 所有声明 source 文件存在；
- cold compile 和 hot compile object hash 一致；
- ccache stats 中 miss 和 direct hit 覆盖声明 source 数量；
- strace 中存在 Redis/nginx cache path file operations；
- trace-derived cache objects 数量达到最小阈值；
- bridge 生成的 TSV 每行 object hash 与原始 cache object 一致；
- KVM policy content oracle 0 failure。

## OSDI 解释

如果 bulk workload 仍然被 materialized/FUSE/native baseline 击败，结论仍然是负结果，
应该继续补 stale/corrupt/update window、BuildKit/Prometheus cache trace、native
ccache/BuildKit baseline 或收窄 W4 claim。不能把小规模或负结果改写成 C2/C8 支持证据。

如果 bulk workload 展示出 parent-rule policy 明显减少 setup/update/materialization
成本，还需要后续 release repetitions、外部 baseline parity、operation-weighted hit-rate
和 hard gate 才能支撑论文主张。
