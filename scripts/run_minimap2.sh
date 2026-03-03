#!/usr/bin/env bash
set -euo pipefail
# ---------------------------------------------------------------------------
# Run Minimap2 on long reads (ONT / PacBio HiFi)
# Usage: run_minimap2.sh <reference.fa> <reads.fastq> <output_dir> [preset]
#   preset: map-ont (default) | map-hifi | map-pb | lr:hq
# ---------------------------------------------------------------------------
REF="${1:?Usage: run_minimap2.sh <ref.fa> <reads.fq> <outdir> [preset]}"
READS="${2:?Provide reads FASTQ}"
OUTDIR="${3:?Provide output directory}"
PRESET="${4:-map-ont}"
THREADS="${THREADS:-$(nproc)}"

mkdir -p "${OUTDIR}"

echo "[minimap2] Aligning with preset=${PRESET}, threads=${THREADS}"
minimap2 -a -x "${PRESET}" -t "${THREADS}" "${REF}" "${READS}" \
    | samtools sort -@ "${THREADS}" -o "${OUTDIR}/minimap2.bam"
samtools index "${OUTDIR}/minimap2.bam"
samtools flagstat "${OUTDIR}/minimap2.bam" > "${OUTDIR}/minimap2.flagstat.txt"

echo "[minimap2] Done → ${OUTDIR}/minimap2.bam"
