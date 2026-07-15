# Reference PDF Index

This directory stores local copies of papers used by the related-work and
experiment-design notes. The PDFs are reference inputs only; experiment evidence
and raw results stay under `results/`.

Code and artifact entry points are cataloged separately in
`docs/reference/CODE_SOURCES.md`.

| File | Source | Project relevance | SHA256 |
| --- | --- | --- | --- |
| `arxiv2602.08199-branch-contexts-branchfs.pdf` | Branch contexts / BranchFS, arXiv 2602.08199 | Agent workspace branching supplies concrete branch/session/commit/abort behavior for the agent lifecycle workload. | `84d1156141ddb18f97fbc51fdd759f0b0d861eea7f3ef8181dffe4f627f19ce6` |
| `arxiv2605.26298-sandlock.pdf` | Sandlock, arXiv 2605.26298 | Agent sandboxing uses runtime filesystem/network/process policies and COW workspace state; useful reproducible source for AI agent workspace lifecycle. | `a0141c3d88f0c26d14635f7b48e1b9aff3c3d4623fc0c5d11175820e2900cfc1` |
| `arxiv2604.13536-yolofs.pdf` | YoloFS, arXiv 2604.13536 | Agent filesystem safety methodology: staged effects, snapshots, progressive permission, hidden side-effect tasks, user-agent-filesystem interaction oracles, and a reproduced public compat-branch mounted e2e workload. | `e70956616b7c317b2285c4088e7f7be92532c01b37bf7e66dfc36dfed9709ea2` |
| `arxiv2602.11210-swe-minisandbox.pdf` | SWE-MiniSandbox, arXiv 2602.11210 | Container-free SWE agent sandboxing stresses namespace/chroot/bind-mount setup and per-instance filesystem state. | `22f6fd0a570f2bad8958599dfa9129833d9c89870a23add633c52b1dfb54e7c5` |
| `arxiv2602.09345-agentcgroup.pdf` | AgentCgroup, arXiv 2602.09345 | AI coding-agent tool-call traces and SWE-rebench tasks provide operation boundaries for agent workload design. | `a5664fc4c3ab469a19ae37d1569bf7879d1bb7124048518cc4df074e68140ada` |
| `neurips2024-yang-swe-agent.pdf` | SWE-agent, NeurIPS 2024 | Open-source software-engineering agent tasks provide real repository build/test/file-access traces. | `0116614120ddfaa37e7c944b7205b4f05523a2415e11846081c08dd0d848ea05` |
| `arxiv2511.03690-openhands-sdk.pdf` | OpenHands Software Agent SDK, arXiv 2511.03690 | OpenHands local and ephemeral workspaces motivate real agent workspace lifecycle traces. | `0c99b4a838a5f37c4ecd07b3dd2143016cf799a9eb547c8ba7660951e2d408a5` |
| `arxiv2601.11868-terminal-bench.pdf` | Terminal-Bench, arXiv 2601.11868 | Terminal tasks with executable tests provide real agent command-line workloads and correctness oracles. | `4430e04a507b2442bb7b24a88899b750948fa0a6b3bbc33a8d541d6d4debcc1e` |
| `arxiv2601.22859-menvagent.pdf` | MEnvAgent, arXiv 2601.22859 | Polyglot environment construction supplies reproducible build/test environment and cache-reuse workloads. | `ea8483bc1ab4e47fb3b0a824cf61f364e07287d5b98f0da6aafc90132cf4341f` |
| `arxiv2512.06915-multi-docker-eval.pdf` | Multi-Docker-Eval, arXiv 2512.06915 | Docker environment construction benchmark supplies real repositories and dependency/cache setup pressure. | `5c64f1bfb7e0ba0130b12efef16c00e31501aa71cd3d820f994b0664e488c615` |
| `arxiv2602.23866-swe-rebench-v2.pdf` | SWE-rebench V2, arXiv 2602.23866 | Language-agnostic SWE task collection supplies real repos, tests, commits, and environment metadata. | `8e7a6c235b2aca7422b9a3778540fddddda7403ae7c53c16b2a26eab6942a7c4` |
| `arxiv2602.00592-docksmith.pdf` | DockSmith, arXiv 2602.00592 | Environment construction methodology and Docker-building trajectory source; use with SWE-Factory, Multi-Docker-Eval, and MEnvAgent for environment/cache workload design. | `5f02fa80679a316a8ef238743178c96ec34a8cc08a6488df901b62d7e792daff` |
| `atc13-ren-tablefs.pdf` | Ren and Gibson, TABLEFS, ATC 2013 | Stacked/FUSE metadata filesystem anchor for systems that own metadata layout and batching. | `b511bb879e814cd8144d9883779d9de80bfee98d59d1e2e0c04fb3e65cd2b1f4` |
| `atc19-bijlani-extfuse.pdf` | Bijlani et al., ExtFUSE, ATC 2019 | Shows FUSE can be extended/optimized, so our FUSE comparison must be workload-specific rather than a generic "FUSE is slow" claim. | `ce5734ee022fab071998f30e9ebeb91a3a3af1d944be28fa53687816e3f07e1d` |
| `cluster16-ansel-dmtcp-path-virtualization.pdf` | DMTCP path virtualization material | Checkpoint/restart path virtualization is a real path-view motivation and can inform rollback/restore oracle design. | `05f8b46dcff4875448b6ca931bd3a86d0dc70702ad7b6997c983cef5bf292e6e` |
| `fast15-jannen-betrfs.pdf` | Jannen et al., BetrFS, FAST 2015 | Example where FUSE was insufficient for a write-optimized filesystem because kernel implementation provided finer control over reads and metadata behavior. | `a4ee697665c80d370165b3f5a028f4a5b4a49246f3d86ea917f2ffba10b4d4f0` |
| `fast16-zhang-composite-file-fs.pdf` | Zhang et al., Composite-file File System, FAST 2016 | Custom filesystem anchor for designs that change file-to-metadata mapping and storage semantics. | `9cef619be573bb09e4dd056e126a81f2e3fbf9aff7b46b9a7ee70d2e57b016e1` |
| `fast16-xu-nova.pdf` | Xu and Swanson, NOVA, FAST 2016 | Example of a custom kernel filesystem built for storage layout and persistence semantics, outside `namei_ext`'s path-resolution scope. | `5c320273da2f40f959aba2503bf146d58713e416ff773f9d986d5d8323c0a320` |
| `fast17-vangoor-to-fuse-or-not-to-fuse.pdf` | Vangoor et al., To FUSE or Not to FUSE, FAST 2017 | Establishes that FUSE overhead is workload-dependent; our FUSE comparisons need direct measurements. | `871e3c664402ee1865767b17b8ca6197941753796f1f9256420351c1f9ffcbeb` |
| `fast21-miller-bento.pdf` | Miller et al., Bento, FAST 2021 | Motivates the space between FUSE flexibility and kernel filesystem performance, while still requiring a filesystem implementation. | `d02be24b407895cef3b5f49361e0243bcb08dfe3216d15be7e02763e8ec402b8` |
| `hotstorage15-tarasov-terra-incognita-userspace-fs.pdf` | Tarasov et al., Terra Incognita, HotStorage 2015 | Motivates why many systems choose user-space filesystems and why FUSE claims require direct workload measurement. | `31ae3a14cc29de3bc63667737df7a95c8e1464e1b76ec42098cc12982c725593` |
| `pdsw17-zheng-deltafs-indexed-massive-directory.pdf` | Zheng et al., DeltaFS Indexed Massive Directory, PDSW 2017 | DeltaFS metadata/index design anchors the full metadata-service design point. | `5cc90457362750c9110273ca911699b8a5e60b6a38bd56a5fbf39ebebf5c07bc` |
| `sc21-zheng-deltafs.pdf` | Zheng et al., DeltaFS, SC 2021 | DeltaFS anchors namespace-log, selective-merge, and workflow metadata semantics outside `namei_ext`'s narrow hook. | `37d716115bad455a2d89704e6d41d3812b6e7c28b8ae311253135fa6a3a96edf` |
| `sc14-ren-indexfs.pdf` | Ren et al., IndexFS, SC 2014 | IndexFS anchors scalable metadata partitioning and caching as a full metadata-service mechanism. | `d7ba506d2dc6724365e15ddc6106358ecadc4697c492f17ef1e00c10718de486` |
| `usenix99-zadok-wrapfs-stackable-templates.pdf` | Zadok et al., Wrapfs stackable templates, USENIX 1999 | Classic stackable-filesystem motivation: add nontrivial filesystem behavior without modifying clients or lower filesystems. | `76dda16325a06ae769610199145ea5dc2c2d6da353c1918ddc445875b573d404` |
