# W4 bulk ccache 真实 workload 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## 背景

此前 W4 ccache release ledger 使用 Redis/nginx two-file trace，只产生 4 个
trace-derived cache objects。新增的 `materialized_cache_view` 外部 baseline 在这个
小 trace shape 上比 parent-rule policy 更快，因此 W4 不能继续只围绕 sampled
two-file trace 或 `table_redirect.bpf.c` 做解释。

本实现按 `2026-06-16-w4-bulk-ccache-workload-design.md` 增加一个更真实的 bulk
ccache trace/bridge workflow：在修改内核 KVM guest 中对 Redis 7.2.14 和 nginx
1.26.3 各 10 个真实源文件做 cold/hot ccache 编译，用 `strace -f -e trace=%file`
采集真实 `CCACHE_DIR` 文件访问，再把 trace-derived cache object 转成
`cache_locality_view.bpf.c` 的 policy oracle 输入。

## 修改内容

- `mk/kvm.mk`
  - 新增 bulk source list、trace/result/input artifact 变量。
  - 新增 `kvm-w4-ccache-bulk-trace`。
  - 新增 `kvm-w4-ccache-bulk-policy-bridge`。
  - 两个 guest target 都只写 raw JSONL、TSV、strace log、sha256 manifest 和 dmesg。
- `Makefile`
  - 新增公开 help entry 和 phony target。
- `docs/tmp/2026-06-16-w4-bulk-ccache-workload-design.md`
  - 记录 workload 选择、oracle 和 OSDI 解释边界。

没有新增项目自有 shell 脚本；所有入口仍是 Make target。

## Workload

默认 Redis source set：

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

默认 nginx source set：

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

这些 source 都来自 project-owned workload fetch/build tree，不是手写 fixture。

## 验证命令

```text
make w1-oracle bpf
make kvm-w4-ccache-bulk-policy-bridge RUN_ID=20260616T-w4-ccache-bulk-smoke-v1
```

环境检查：

- `/dev/kvm` 可读写。
- `vng --version` 为 `virtme-ng 1.40`。

## 结果

结果目录：

```text
results/phase1/20260616T-w4-ccache-bulk-smoke-v1/
```

关键 raw artifacts：

- `w4-ccache-bulk-trace.jsonl`
- `w4-ccache-bulk-policy-bridge.jsonl`
- `w4-ccache-bulk-source-manifest.tsv`
- `w4-ccache-bulk-trace-redis.strace.log`
- `w4-ccache-bulk-trace-nginx.strace.log`
- `w4-ccache-bulk-policy-bridge-trace-objects.txt`
- `w4-ccache-bulk-policy-bridge-entries.tsv`
- `w4-ccache-bulk-trace-inputs.sha256`
- `w4-ccache-bulk-policy-bridge-inputs.sha256`
- `dmesg-w4-ccache-bulk-trace.log`
- `dmesg-w4-ccache-bulk-policy-bridge.log`

`w4-ccache-bulk-cache-path-trace` row 记录：

- `source_count=20`
- `redis_trace_file_ops=1851`
- `nginx_trace_file_ops=6067`
- `redis_cache_path_file_ops=200`
- `nginx_cache_path_file_ops=200`
- `cache_path_file_ops=400`
- `cache_miss=20`
- `direct_cache_hit=20`
- `local_storage_hit=20`
- `local_storage_write=40`
- `output_hash_match=true`
- `pass=true` 由 summary row 表达

`w4-ccache-bulk-policy-bridge-summary` row 记录：

- `trace_objects=40`
- `entries=40`
- `redis_trace_objects=20`
- `nginx_trace_objects=20`
- `policy_content_oracle_failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `pass=true`
- `qualified_for_c8=false`

## 解释

这个 run 把 W4 从 two-file sampled trace 推进到 20 个真实源文件、400 条真实
ccache cache-path file ops 和 40 个 trace-derived cache objects。它证明 bulk
ccache trace 可以在修改内核 KVM 中产生更大、更真实的 policy oracle 输入，并且
这些 entries 能通过真实 `cgroup/namei_ext` attach path 的 content/readdir oracle。

它仍不是 W4 C2/C8 支持证据，原因是：

- bulk hot compile 的 trace target 本身没有 attach policy；
- bridge target 执行的是 trace-derived content oracle，不是 operation-weighted
  compile hit-rate；
- 没有同 bulk shape 的 materialized/FUSE/native ccache baseline；
- 没有真实 stale/corrupt/update-window oracle；
- 没有证明 table-only 在同等 budget 下失败或超预算。

## 后续

下一步应基于这 40 个 trace-derived objects 做同 workload 的：

- bulk parent-rule policy-attached compile；
- bulk table-only comparator；
- bulk materialized/cache-remap/FUSE/native ccache baseline；
- operation-weighted policy hit-rate；
- stale/corrupt/update-window gate。

如果这些 baseline 仍然击败 proposed system，应继续扩大到 BuildKit/Prometheus cache
trace 或收窄 W4 主张，而不是把当前负结果改写成正结果。
