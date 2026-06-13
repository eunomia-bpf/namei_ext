FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bpftool \
    ca-certificates \
    clang \
    coreutils \
    findutils \
    gcc \
    jq \
    libc6-dev \
    libelf-dev \
    llvm \
    make \
    procps \
    python3 \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/namei_ext

COPY Makefile README.md AGENTS.md ./
COPY configs/ configs/
COPY mk/ mk/
COPY bpf/ bpf/
COPY bench/ bench/
COPY tests/ tests/

ENV NAMEI_EXT_RUNTIME=1

CMD ["make", "-C", "/opt/namei_ext", "bpf"]
