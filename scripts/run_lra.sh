#!/usr/bin/env bash
set -euo pipefail
# ---------------------------------------------------------------------------
# Run LRA on long reads
# Usage: run_lra.sh <reference.fa> <reads.fastq> <output_dir> [tech]
#   tech: ONT (default) | CCS | CLR
# ---------------------------------------------------------------------------
REF="${1:?Usage: run_lra.sh <ref.fa> <reads.fq> <outdir> [ONT|CCS|CLR]}"
READS="${2:?Provide reads FASTQ}"
OUTDIR="${3:?Provide output directory}"
TECH="${4:-ONT}"
THREADS="${THREADS:-$(nproc)}"

mkdir -p "${OUTDIR}"

echo "[lra] Indexing reference for technology=${TECH} …"
lra index "${REF}" "${TECH}" 2>/dev/null || true

echo "[lra] Aligning with tech=${TECH}, threads=${THREADS}"
lra align -t "${THREADS}" "${REF}" "${READS}" "${TECH}" -p s \
    | samtools sort -@ "${THREADS}" -o "${OUTDIR}/lra.bam"
samtools index "${OUTDIR}/lra.bam"
samtools flagstat "${OUTDIR}/lra.bam" > "${OUTDIR}/lra.flagstat.txt"

echo "[lra] Done → ${OUTDIR}/lra.bam"
