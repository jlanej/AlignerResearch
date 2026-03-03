# AlignerResearch

A benchmarking suite for state-of-the-art **long-read sequence aligners** (PacBio &amp; Oxford Nanopore).
All tools are packaged in a single Docker image for reproducible evaluation, with first-class support for running on HPC clusters via [Apptainer](https://apptainer.org/).

---

## Long-Read Aligners Included

| Aligner | Version | Best For | Speed | Accuracy | Memory |
|---------|---------|----------|-------|----------|--------|
| [Minimap2](https://github.com/lh3/minimap2) | 2.28 | ONT / PacBio HiFi / CLR | ★★★ | ★★★ | Low |
| [Winnowmap2](https://github.com/marbl/Winnowmap) | 2.03 | Repetitive regions, SVs | ★★☆ | ★★★ | Moderate |
| [NGMLR](https://github.com/philres/ngmlr) | 0.2.7 | Structural variant calling | ★☆☆ | ★★☆ | High |
| [LRA](https://github.com/ChaissonLab/LRA) | latest | PacBio HiFi, complex SVs | ★★☆ | ★★★ | Moderate |
| [pbmm2](https://github.com/PacificBiosciences/pbmm2) | latest | PacBio (HiFi / CLR / Iso-Seq) | ★★☆ | ★★★ | Moderate |

Utility: **samtools 1.21** is included for BAM sorting, indexing, and flagstat.

---

## Aligner Research Summary

### Minimap2

Minimap2 is the de facto standard long-read aligner, supporting ONT, PacBio HiFi, and CLR data through purpose-built presets.
It is the fastest general-purpose aligner with low memory requirements and produces high-quality alignments suitable for variant calling with tools such as Sniffles2 and cuteSV.

**Advantages**
- Extremely fast; handles very large datasets with ease
- Versatile presets: `map-ont`, `map-hifi`, `map-pb`, `lr:hq` (for latest high-accuracy ONT reads)
- Low RAM footprint
- Broad downstream tool compatibility

**Pitfalls**
- May miss complex structural variants in highly repetitive regions
- Older `map-ont` preset is suboptimal for newest high-accuracy ONT chemistries (use `lr:hq`)

### Winnowmap2

Built on top of Minimap2, Winnowmap2 adds repeat-aware alignment using weighted minimisers.
It masks highly repetitive k-mers, leading to improved sensitivity in centromeric and other repetitive regions.

**Advantages**
- Superior SV detection in repetitive sequences (centromeres, segmental duplications)
- Near-Minimap2 speed
- Drop-in replacement workflow (similar CLI interface)

**Pitfalls**
- Requires a pre-computed repetitive k-mer list (via meryl)
- Slightly higher computational cost than vanilla Minimap2
- Best results often come from combining Winnowmap2 and Minimap2 outputs

### NGMLR

NGMLR was specifically designed for structural variant detection with long reads, excelling at mapping split and gapped alignments around breakpoints.

**Advantages**
- High recall for complex SVs (large indels, inversions, translocations)
- Well-paired with the SV caller SVIM

**Pitfalls**
- Significantly slower than Minimap2 and Winnowmap2
- High memory usage; not practical for routine whole-genome mapping at scale
- Higher proportion of unmapped reads compared to Minimap2

### LRA (Long Read Aligner)

LRA uses a concave gap cost model that improves alignment accuracy near complex structural changes, especially for SVs >1 kb.

**Advantages**
- High alignment precision for PacBio HiFi data
- Strong performance on complex SVs and large insertions/deletions
- Competitive speed (faster than NGMLR)

**Pitfalls**
- Less effective on noisy ONT data
- Limited platform scope compared to Minimap2
- Typically used as an augmentative aligner rather than standalone

### pbmm2

pbmm2 is PacBio's official wrapper around Minimap2, with parameters optimised for PacBio data types (HiFi, CLR, Iso-Seq).

**Advantages**
- Gold standard for PacBio-centric workflows
- Pre-tuned presets: `HiFi`, `CCS`, `SUBREAD`, `ISOSEQ`
- Seamless integration with PacBio SV caller (pbsv)

**Pitfalls**
- Not platform-agnostic — not suitable for ONT data
- Slightly slower than raw Minimap2 due to additional QC steps

---

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (for local use)
- [Apptainer](https://apptainer.org/) ≥ 1.2 (for HPC use)

### Pull the image

```bash
# From GitHub Container Registry
docker pull ghcr.io/jlanej/alignerresearch:main
```

### Build locally

```bash
git clone https://github.com/jlanej/AlignerResearch.git
cd AlignerResearch
docker build -t aligner-bench .
```

---

## Running Aligners with Docker

Each aligner has a dedicated wrapper script under `scripts/`. They all follow the same interface:

```
run_<aligner>.sh <reference.fa> <reads.fastq> <output_dir> [preset]
```

### Run all aligners (integration test)

```bash
docker run --rm \
  -v "$(pwd)/test_data:/data/test_data:ro" \
  -v "$(pwd)/comparison:/data/comparison" \
  aligner-bench \
  -c "bash /opt/aligner-bench/scripts/run_all_aligners.sh \
        /data/test_data/reference.fa \
        /data/test_data/reads.fastq \
        /data/comparison"
```

### Run a single aligner

```bash
# Minimap2 — ONT reads
docker run --rm \
  -v "$(pwd)/my_data:/data:ro" \
  -v "$(pwd)/results:/results" \
  aligner-bench \
  -c "bash /opt/aligner-bench/scripts/run_minimap2.sh \
        /data/ref.fa /data/reads.fq /results map-ont"

# Minimap2 — PacBio HiFi reads
docker run --rm \
  -v "$(pwd)/my_data:/data:ro" \
  -v "$(pwd)/results:/results" \
  aligner-bench \
  -c "bash /opt/aligner-bench/scripts/run_minimap2.sh \
        /data/ref.fa /data/reads.fq /results map-hifi"

# Winnowmap2
docker run --rm \
  -v "$(pwd)/my_data:/data:ro" \
  -v "$(pwd)/results:/results" \
  aligner-bench \
  -c "bash /opt/aligner-bench/scripts/run_winnowmap2.sh \
        /data/ref.fa /data/reads.fq /results map-ont"

# NGMLR
docker run --rm \
  -v "$(pwd)/my_data:/data:ro" \
  -v "$(pwd)/results:/results" \
  aligner-bench \
  -c "bash /opt/aligner-bench/scripts/run_ngmlr.sh \
        /data/ref.fa /data/reads.fq /results ont"

# LRA
docker run --rm \
  -v "$(pwd)/my_data:/data:ro" \
  -v "$(pwd)/results:/results" \
  aligner-bench \
  -c "bash /opt/aligner-bench/scripts/run_lra.sh \
        /data/ref.fa /data/reads.fq /results ONT"

# pbmm2 (PacBio HiFi)
docker run --rm \
  -v "$(pwd)/my_data:/data:ro" \
  -v "$(pwd)/results:/results" \
  aligner-bench \
  -c "bash /opt/aligner-bench/scripts/run_pbmm2.sh \
        /data/ref.fa /data/reads.fq /results HiFi"
```

### Set thread count

```bash
docker run --rm -e THREADS=16 \
  -v "$(pwd)/my_data:/data:ro" \
  -v "$(pwd)/results:/results" \
  aligner-bench \
  -c "bash /opt/aligner-bench/scripts/run_minimap2.sh \
        /data/ref.fa /data/reads.fq /results map-ont"
```

---

## Running on HPC with Apptainer

Apptainer (formerly Singularity) is the standard way to run containers on HPC clusters.
It runs as your user (no root required) and automatically bind-mounts your home directory.

### 1. Pull and convert the image (one-time)

```bash
module load apptainer          # or: module load singularity
apptainer pull aligner-bench.sif docker://ghcr.io/jlanej/alignerresearch:main
```

### 2. Interactive shell

```bash
apptainer shell aligner-bench.sif
# Inside the container you have minimap2, winnowmap, ngmlr, lra, pbmm2, samtools
```

### 3. Run an aligner directly

```bash
# Minimap2 — ONT reads
apptainer exec aligner-bench.sif \
  bash /opt/aligner-bench/scripts/run_minimap2.sh \
    /path/to/reference.fa \
    /path/to/reads.fastq \
    /path/to/output \
    map-ont

# Winnowmap2 — ONT reads
apptainer exec aligner-bench.sif \
  bash /opt/aligner-bench/scripts/run_winnowmap2.sh \
    /path/to/reference.fa \
    /path/to/reads.fastq \
    /path/to/output \
    map-ont

# NGMLR — ONT reads
apptainer exec aligner-bench.sif \
  bash /opt/aligner-bench/scripts/run_ngmlr.sh \
    /path/to/reference.fa \
    /path/to/reads.fastq \
    /path/to/output \
    ont

# LRA — PacBio HiFi
apptainer exec aligner-bench.sif \
  bash /opt/aligner-bench/scripts/run_lra.sh \
    /path/to/reference.fa \
    /path/to/reads.fastq \
    /path/to/output \
    CCS

# pbmm2 — PacBio HiFi
apptainer exec aligner-bench.sif \
  bash /opt/aligner-bench/scripts/run_pbmm2.sh \
    /path/to/reference.fa \
    /path/to/reads.fastq \
    /path/to/output \
    HiFi
```

### 4. Run all aligners (full benchmark)

```bash
apptainer exec aligner-bench.sif \
  bash /opt/aligner-bench/scripts/run_all_aligners.sh \
    /path/to/reference.fa \
    /path/to/reads.fastq \
    /path/to/comparison_output
```

### 5. SLURM job script example

```bash
#!/bin/bash
#SBATCH --job-name=aligner-bench
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=aligner-bench_%j.log

module load apptainer

export THREADS=${SLURM_CPUS_PER_TASK}

REF="/scratch/user/data/reference.fa"
READS="/scratch/user/data/reads.fastq"
OUTDIR="/scratch/user/results/comparison"

apptainer exec \
  --bind /scratch \
  aligner-bench.sif \
  bash /opt/aligner-bench/scripts/run_all_aligners.sh \
    "${REF}" "${READS}" "${OUTDIR}"
```

### 6. Bind-mount additional paths

```bash
# Bind /scratch and /project into the container
apptainer exec --bind /scratch,/project aligner-bench.sif \
  bash /opt/aligner-bench/scripts/run_minimap2.sh \
    /project/genomes/hg38.fa \
    /scratch/reads/ont_reads.fq \
    /scratch/results/minimap2 \
    lr:hq
```

### 7. Clean environment (recommended)

```bash
# Use --cleanenv to prevent host environment variables from leaking in
apptainer exec --cleanenv aligner-bench.sif \
  bash /opt/aligner-bench/scripts/run_minimap2.sh \
    /data/ref.fa /data/reads.fq /data/out map-ont
```

---

## Repository Structure

```
AlignerResearch/
├── Dockerfile                          # Single image with all long-read aligners
├── README.md                           # This file
├── LICENSE
├── comparison/                         # Integration test results (auto-committed by CI)
│   └── .gitkeep
├── scripts/
│   ├── run_minimap2.sh                 # Minimap2 wrapper
│   ├── run_winnowmap2.sh              # Winnowmap2 wrapper
│   ├── run_ngmlr.sh                   # NGMLR wrapper
│   ├── run_lra.sh                     # LRA wrapper
│   ├── run_pbmm2.sh                   # pbmm2 wrapper
│   └── run_all_aligners.sh           # Run all & produce comparison summary
├── test_data/
│   ├── reference.fa                   # Small synthetic reference (~5 kb)
│   └── reads.fastq                    # Synthetic long reads (500–3000 bp, ~5% error)
└── .github/workflows/
    ├── docker-publish.yml             # Build & push image to GHCR
    └── integration-tests.yml          # Run all aligners, commit results
```

---

## CI / CD

| Workflow | Trigger | Description |
|----------|---------|-------------|
| **Docker Build and Publish** | Push to `main`, tags | Builds the Docker image and pushes to `ghcr.io/jlanej/alignerresearch` |
| **Integration Tests** | Push to `main`, PRs | Builds the image, runs all aligners against test data, and commits results to `comparison/` |

---

## Comparison Directory

The `comparison/` directory stores the output from each aligner after running the integration test suite.
For every aligner the following files are produced:

| File | Description |
|------|-------------|
| `<aligner>.bam` | Sorted, indexed alignment |
| `<aligner>.flagstat.txt` | samtools flagstat summary |
| `summary.txt` | Pass/fail and timing for each aligner |

These results are automatically committed by CI on pushes to `main`, allowing you to track alignment behaviour over time as test data evolves.

---

## License

[MIT](LICENSE)
