FROM ubuntu:22.04 AS base

LABEL maintainer="jlanej"
LABEL description="Long-read aligner benchmarking suite (Minimap2, Winnowmap2, NGMLR, LRA, pbmm2, samtools)"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    git \
    libbz2-dev \
    libcurl4-gnutls-dev \
    liblzma-dev \
    libncurses5-dev \
    libssl-dev \
    libz-dev \
    pkg-config \
    python3 \
    python3-pip \
    tabix \
    wget \
    zlib1g-dev \
    autoconf \
    automake \
    libtool \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# htslib (shared library + headers, needed by samtools and LRA)
# ---------------------------------------------------------------------------
ARG HTSLIB_VERSION=1.21
RUN cd /tmp && \
    wget -q https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2 && \
    tar xjf htslib-${HTSLIB_VERSION}.tar.bz2 && \
    cd htslib-${HTSLIB_VERSION} && \
    ./configure --prefix=/usr/local && make -j"$(nproc)" && make install && \
    rm -rf /tmp/htslib-*
RUN ldconfig

# ---------------------------------------------------------------------------
# samtools
# ---------------------------------------------------------------------------
ARG SAMTOOLS_VERSION=1.21
RUN cd /tmp && \
    wget -q https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2 && \
    tar xjf samtools-${SAMTOOLS_VERSION}.tar.bz2 && \
    cd samtools-${SAMTOOLS_VERSION} && \
    ./configure --prefix=/usr/local && make -j"$(nproc)" && make install && \
    rm -rf /tmp/samtools-*

# ---------------------------------------------------------------------------
# Minimap2
# ---------------------------------------------------------------------------
ARG MINIMAP2_VERSION=2.28
RUN cd /tmp && \
    wget -q https://github.com/lh3/minimap2/releases/download/v${MINIMAP2_VERSION}/minimap2-${MINIMAP2_VERSION}_x64-linux.tar.bz2 && \
    tar xjf minimap2-${MINIMAP2_VERSION}_x64-linux.tar.bz2 && \
    cp minimap2-${MINIMAP2_VERSION}_x64-linux/minimap2 /usr/local/bin/ && \
    rm -rf /tmp/minimap2-*

# ---------------------------------------------------------------------------
# Winnowmap2
# ---------------------------------------------------------------------------
ARG WINNOWMAP_VERSION=2.03
RUN cd /tmp && \
    git clone --depth 1 --branch v${WINNOWMAP_VERSION} https://github.com/marbl/Winnowmap.git && \
    cd Winnowmap && make -j"$(nproc)" && \
    cp bin/winnowmap /usr/local/bin/ && \
    cp bin/meryl /usr/local/bin/ 2>/dev/null || true && \
    rm -rf /tmp/Winnowmap

# ---------------------------------------------------------------------------
# NGMLR
# ---------------------------------------------------------------------------
ARG NGMLR_VERSION=0.2.7
RUN cd /tmp && \
    wget -q https://github.com/philres/ngmlr/releases/download/v${NGMLR_VERSION}/ngmlr-${NGMLR_VERSION}-linux-x86_64.tar.gz && \
    tar xzf ngmlr-${NGMLR_VERSION}-linux-x86_64.tar.gz && \
    cp ngmlr-${NGMLR_VERSION}/ngmlr /usr/local/bin/ && \
    rm -rf /tmp/ngmlr-*

# ---------------------------------------------------------------------------
# LRA
# ---------------------------------------------------------------------------
RUN cd /tmp && \
    git clone --depth 1 https://github.com/ChaissonLab/LRA.git && \
    cd LRA && make -j"$(nproc)" && \
    cp lra /usr/local/bin/ && \
    rm -rf /tmp/LRA

# ---------------------------------------------------------------------------
# pbmm2 (via mamba / bioconda)
# ---------------------------------------------------------------------------
RUN cd /tmp && \
    wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh && \
    bash Miniforge3-Linux-x86_64.sh -b -p /opt/miniforge && \
    rm Miniforge3-Linux-x86_64.sh
ENV PATH="/opt/miniforge/bin:${PATH}"
RUN mamba install -y -c bioconda -c conda-forge pbmm2 && mamba clean -afy

# ---------------------------------------------------------------------------
# Copy scripts and test data
# ---------------------------------------------------------------------------
COPY scripts/ /opt/aligner-bench/scripts/
COPY test_data/ /opt/aligner-bench/test_data/

RUN chmod +x /opt/aligner-bench/scripts/*.sh

WORKDIR /data

ENTRYPOINT ["/bin/bash"]
