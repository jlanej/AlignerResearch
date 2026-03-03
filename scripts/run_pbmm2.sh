#!/usr/bin/env bash
set -euo pipefail
# ---------------------------------------------------------------------------
# Run pbmm2 on PacBio long reads
# Usage: run_pbmm2.sh <reference.fa> <reads.fastq> <output_dir> [preset]
#   preset: HiFi (default) | CCS | SUBREAD | UNROLLED | ISOSEQ
# ---------------------------------------------------------------------------
REF="${1:?Usage: run_pbmm2.sh <ref.fa> <reads.fq> <outdir> [preset]}"
READS="${2:?Provide reads FASTQ}"
OUTDIR="${3:?Provide output directory}"
PRESET="${4:-HiFi}"
THREADS="${THREADS:-$(nproc)}"

mkdir -p "${OUTDIR}"

echo "[pbmm2] Aligning with preset=${PRESET}, threads=${THREADS}"
pbmm2 align "${REF}" "${READS}" "${OUTDIR}/pbmm2.bam" \
    --preset "${PRESET}" \
    -j "${THREADS}" \
    --sort \
    --log-level INFO

samtools index "${OUTDIR}/pbmm2.bam"
samtools flagstat "${OUTDIR}/pbmm2.bam" > "${OUTDIR}/pbmm2.flagstat.txt"

echo "[pbmm2] Done → ${OUTDIR}/pbmm2.bam"
