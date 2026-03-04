#!/usr/bin/env bash
set -euo pipefail
# ---------------------------------------------------------------------------
# Run Winnowmap2 on long reads
# Usage: run_winnowmap2.sh <reference.fa> <reads.fastq> <output_dir> [preset]
#   preset: map-ont (default) | map-pb | map-pb-clr
# ---------------------------------------------------------------------------
REF="${1:?Usage: run_winnowmap2.sh <ref.fa> <reads.fq> <outdir> [preset]}"
READS="${2:?Provide reads FASTQ}"
OUTDIR="${3:?Provide output directory}"
PRESET="${4:-map-ont}"
THREADS="${THREADS:-$(nproc)}"

mkdir -p "${OUTDIR}"

echo "[winnowmap2] Computing repetitive k-mers …"
meryl count k=15 output "${OUTDIR}/merylDB" "${REF}" 2>/dev/null || true
meryl print greater-than distinct=0.9998 "${OUTDIR}/merylDB" > "${OUTDIR}/repetitive_k15.txt" 2>/dev/null || true

# Fall back to empty repetitive-kmer list if meryl is unavailable
REP_KMERS="${OUTDIR}/repetitive_k15.txt"
if [ ! -s "${REP_KMERS}" ]; then
    touch "${REP_KMERS}"
fi

echo "[winnowmap2] Aligning with preset=${PRESET}, threads=${THREADS}"
winnowmap -W "${REP_KMERS}" -a -x "${PRESET}" -t "${THREADS}" "${REF}" "${READS}" \
    | samtools sort -@ "${THREADS}" -o "${OUTDIR}/winnowmap2.bam"
samtools index "${OUTDIR}/winnowmap2.bam"
samtools flagstat "${OUTDIR}/winnowmap2.bam" > "${OUTDIR}/winnowmap2.flagstat.txt"

echo "[winnowmap2] Done → ${OUTDIR}/winnowmap2.bam"
