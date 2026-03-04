#!/usr/bin/env bash
set -euo pipefail
# ---------------------------------------------------------------------------
# run_all_aligners.sh — Run every long-read aligner against the test data
# and collect results into the comparison/ directory.
#
# Usage: run_all_aligners.sh [reference.fa] [reads.fastq] [output_root]
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

REF="${1:-${REPO_ROOT}/test_data/reference.fa}"
READS="${2:-${REPO_ROOT}/test_data/reads.fastq}"
OUT_ROOT="${3:-${REPO_ROOT}/comparison}"
THREADS="${THREADS:-$(nproc)}"

export THREADS

echo "=============================================="
echo " Long-Read Aligner Integration Test Suite"
echo "=============================================="
echo "Reference : ${REF}"
echo "Reads     : ${READS}"
echo "Output    : ${OUT_ROOT}"
echo "Threads   : ${THREADS}"
echo "=============================================="

SUMMARY="${OUT_ROOT}/summary.txt"
: > "${SUMMARY}"

run_aligner() {
    local name="$1"
    local script="$2"
    shift 2
    local outdir="${OUT_ROOT}/${name}"
    echo ""
    echo ">>> Running ${name} …"
    local start_time end_time elapsed
    start_time=$(date +%s)
    if bash "${SCRIPT_DIR}/${script}" "$@" "${outdir}"; then
        end_time=$(date +%s)
        elapsed=$((end_time - start_time))
        echo "    ✓ ${name} completed in ${elapsed}s"
        echo "${name}: PASS (${elapsed}s)" >> "${SUMMARY}"
    else
        end_time=$(date +%s)
        elapsed=$((end_time - start_time))
        echo "    ✗ ${name} FAILED after ${elapsed}s"
        echo "${name}: FAIL (${elapsed}s)" >> "${SUMMARY}"
    fi
}

# ---- Minimap2 ----
run_aligner "minimap2" "run_minimap2.sh" "${REF}" "${READS}"

# ---- Winnowmap2 ----
run_aligner "winnowmap2" "run_winnowmap2.sh" "${REF}" "${READS}"

# ---- NGMLR ----
run_aligner "ngmlr" "run_ngmlr.sh" "${REF}" "${READS}"

# ---- LRA ----
run_aligner "lra" "run_lra.sh" "${REF}" "${READS}"

# ---- pbmm2 ----
run_aligner "pbmm2" "run_pbmm2.sh" "${REF}" "${READS}"

# ---- Collect flagstat summaries ----
echo ""
echo "=============================================="
echo " Flagstat Comparison"
echo "=============================================="
for fs in "${OUT_ROOT}"/*/*.flagstat.txt; do
    if [ -f "${fs}" ]; then
        echo ""
        echo "--- $(basename "$(dirname "${fs}")")/$(basename "${fs}") ---"
        cat "${fs}"
    fi
done | tee -a "${SUMMARY}"

echo ""
echo "Results written to ${OUT_ROOT}/"
echo "Summary: ${SUMMARY}"
