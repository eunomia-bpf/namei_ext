# TableFS Individual Fsbench Workload Reproduction

Date: 2026-07-01

## Motivation

The previous TableFS record had one passing `metadatacreate` run and one
segfaulting full fsbench list. That was too coarse to tell which official
fsbench workload shapes are reusable. This follow-up splits the original
TableFS fsbench workload names into independent tiny runs, each with its own
metadata/data root, so state from one workload group does not poison the next.

TableFS remains related work and appendix workload-shape evidence. It is a
full FUSE/LevelDB metadata filesystem, not a main `namei_ext` agent workload.

## Source

- Source tarball:
  `https://www.cs.cmu.edu/~kair/code/tablefs-0.3.tar.gz`
- Cached source:
  `.cache/source-inspection/tablefs-0.3/tablefs-0.3`
- Binary:
  `.cache/source-inspection/tablefs-0.3/tablefs-0.3/src/fsbench`
- Files inspected:
  `src/fsbench.cpp`, `src/fs/fswrapper.cpp`, `src/util/traceloader.cpp`, and
  `src/util/command.cpp`.

## Raw Evidence

Result root:

- `results/reproduction/2026-07-01-official-workloads/tablefs-fsbench-individual/`

Important files:

- `trace.txt`
- `groups.tsv`
- `status.tsv`
- `summary.json`
- `<group>/fsbench.conf`
- `<group>/fsbench.log`
- `<group>/monitor.log`
- `<group>/status`
- `smallfilecreate/gdb-backtrace.log`

## Method

The run used the original `tablefs_user` in-process fsbench backend with a tiny
trace:

- 20 total paths;
- 4 directories;
- 16 files;
- `create_numpaths=16`;
- `query_number=16`;
- `numthreads=1`;
- `filesize=64`.

The original `fsbench` argument parser only accepts `-configfile <path>`, not
GNU-style `--configfile=<path>`. An initial wrong invocation was discarded and
the preserved result root uses the correct invocation:

```text
sudo -n timeout 120s fsbench -configfile <conf>
```

`sudo` is needed because the original fsbench calls:

```text
echo 3 > /proc/sys/vm/drop_caches
```

## Results

| Workload group | Fsbench sequence | Exit | Result |
| --- | --- | ---: | --- |
| `metadatacreate` | `metadatacreate` | 0 | Passed. |
| `metadataquery` | `metadatacreate,metadataquery` | 0 | Passed after metadata create. |
| `onedircreate` | `onedircreate` | 0 | Passed with `BadCount = 5`, so it is executable but not a clean-zero-error workload. |
| `onedirquery` | `onedircreate,onedirquery` | 0 | Passed with create/query bad-count messages, so it is executable but not a clean-zero-error workload. |
| `renamequery` | `metadatacreate,renamequery` | 0 | Passed, `Error count = 0`. |
| `deletequery` | `metadatacreate,deletequery` | 0 | Passed, `Error count = 0`. |
| `metadatacreatecompact` | `metadatacreatecompact` | 139 | Segfault. |
| `smallfilecreate` | `smallfilecreate` | 139 | Segfault. |
| `smallfilequery` | `smallfilecreate,smallfilequery` | 139 | Segfault. |
| `scanquery` | `smallfilecreate,scanquery` | 139 | Segfault. |
| `lsstatquery` | `smallfilecreate,lsstatquery` | 139 | Segfault. |
| `scanfilequery` | `smallfilecreate,scanfilequery` | 139 | Segfault. |

The `smallfilecreate` gdb backtrace shows the crash in the original
TableFS/LevelDB metadata path:

```text
leveldb::DBImpl::Get
tablefs::LevelDBAdaptor::Get
tablefs::InodeCache::Get
tablefs::TableFS::GetAttr
tablefs::TableFSWrapper::Stat
tablefs::TableFSWrapper::Mkdir
tablefs::FileSystemBenchmark::SmallFileCreate
```

## Reuse Decision

This improves TableFS from a single passing microbenchmark to a partial
workload-family reproduction:

- usable appendix evidence: metadata create/query, one-directory create/query,
  rename, and delete fsbench groups;
- negative/porting evidence: compact and small-file/scan groups still crash in
  the ported original code on this host;
- not suitable as a main workload artifact without a TableFS porting effort.

For `namei_ext`, TableFS should stay a mechanism and workload-shape anchor for
metadata-heavy full filesystems. It should not displace the agent workspace or
environment/cache workload sources.

## Remaining Risks

- This is a tiny-scale reproduction, not the paper's original large TableFS
  evaluation.
- The workload uses `tablefs_user`, not a mounted FUSE TableFS path.
- Some exit-0 groups still print bad-count messages, so they are executable
  workload-shape evidence rather than clean correctness evidence.
- Compact and small-file/scan workloads need source-level porting/debugging
  before they can be cited as reproduced.
