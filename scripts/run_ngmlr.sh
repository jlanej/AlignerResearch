#!/usr/bin/env bash
set -euo pipefail
# ---------------------------------------------------------------------------
# Run NGMLR on long reads
# Usage: run_ngmlr.sh <reference.fa> <reads.fastq> <output_dir> [preset]
#   preset: ont (default) | pacbio
# ---------------------------------------------------------------------------
REF="${1:?Usage: run_ngmlr.sh <ref.fa> <reads.fq> <outdir> [preset]}"
READS="${2:?Provide reads FASTQ}"
OUTDIR="${3:?Provide output directory}"
PRESET="${4:-ont}"
THREADS="${THREADS:-$(nproc)}"

mkdir -p "${OUTDIR}"

echo "[ngmlr] Aligning with preset=${PRESET}, threads=${THREADS}"
ngmlr -t "${THREADS}" -r "${REF}" -q "${READS}" -x "${PRESET}" \
    | samtools sort -@ "${THREADS}" -o "${OUTDIR}/ngmlr.bam"
samtools index "${OUTDIR}/ngmlr.bam"
samtools flagstat "${OUTDIR}/ngmlr.bam" > "${OUTDIR}/ngmlr.flagstat.txt"

echo "[ngmlr] Done → ${OUTDIR}/ngmlr.bam"
