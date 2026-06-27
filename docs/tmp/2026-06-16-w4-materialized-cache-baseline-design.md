# W4 物化 cache view baseline 设计

## 背景

W4 目前已经有 `cache_locality_view.bpf.c` 和 `table_redirect.bpf.c` 的
KVM rule macrobench。这个对比有价值，但 `table_redirect.bpf.c` 仍然是
项目内部机制，只能作为 ablation 或内部设计替代，不能作为 OSDI 主 baseline。
如果该 baseline 不支持 claim，正确做法不是改弱论文叙事，而是继续补真实系统
baseline。

本设计加入一个外部 baseline：`materialized_cache_view`。它不加载 eBPF
policy，不使用 `namei_ext`，而是把 trace 派生出的 ccache cache object 直接复制
到应用可见路径中。它代表“没有 programmable path-resolution abstraction 时，
用物化目录树提供同等可见路径内容”的工程选择。

## 目标

- 通过 Make target 在 KVM 内运行，沿用已构建的 modified kernel 运行环境。
- 复用 `kvm-w4-ccache-policy-bridge` 生成的真实 ccache trace 派生输入。
- 记录 setup、update、correctness 三类 raw JSONL 行。
- 明确标记 `policy_executed:false`，避免把它混入 eBPF policy 结果。
- 保留失败为硬失败：输入缺失、复制失败、内容不等、目录枚举不一致都失败。
- 为后续 W4 ledger 提供外部 feature-equivalent baseline 输入。

## 非目标

- 不把 `table_redirect.bpf.c` 当成主 baseline。
- 不引入 shell 脚本、YAML/JSON policy 语言或项目外控制面。
- 不在 collector 中计算论文结论、ratio 或置信区间。
- 不声称该 baseline 已经覆盖所有 ccache/BuildKit cache-locality 场景。

## Workload 与输入

输入来自现有 W4 ccache 链路：

- real Redis/nginx ccache hot compile 产生 cache path trace；
- `kvm-w4-ccache-policy-bridge` 将 trace-derived cache object 写成
  `w4-ccache-policy-bridge-entries.tsv`；
- 本 baseline 逐条读取 TSV，并把 `original` 对象复制为 `visible` 名称。

因此 workload 仍然是来自生产级开源应用的 Redis/nginx source compile，而不是
人工构造的路径循环。

## Baseline 语义

对每个 `(parent_relative, visible, original)`：

1. 在 sample workdir 下创建 `parent_relative` 目录。
2. 将 `original` 文件复制到 `parent_relative/visible`。
3. 不创建 hidden backing object，不加载 BPF map，不 attach policy。
4. 正确性检查读取 `visible` 内容必须等于 `original`，并且 readdir 能看到
   `visible`。

update 阶段追加一个同 parent 的新 cache object，并把新内容直接写入可见路径。
这代表物化视图在 cache object 变化时的目录树维护成本。

## 指标

每个 sample 输出：

- `setup_ns`
- `created_dirs`
- `created_files`
- `bytes_copied`
- `cache_objects`
- `cache_leaf_parents`
- `update_ns`
- `baseline_update_writes`
- `update_bytes_written`
- `policy_executed:false`
- correctness booleans

这些都是 raw observations。是否支持 C2/C8 由后续 ledger 或 report target 解释。

## 预期解释

如果 materialized baseline 在小规模 W4 上很强，这不是论文失败，而是下一步实验
设计信号：需要扩大到 stale/corrupt/update window、更多 cache object、跨 parent
fanout、读写并发，或增加 FUSE/native ccache/BuildKit baseline。OSDI 叙事不能依赖
弱 baseline；真实 baseline 不够区分时，要继续补实验。

## 风险

- 当前 trace object 数量较小，setup/update 成本可能被固定开销主导。
- 直接物化 baseline 只覆盖内容等价，不覆盖 stale/corrupt policy decision。
- 该 baseline 不执行 namei_ext policy，因此只能作为外部比较输入，不能替代
  policy correctness gate。
