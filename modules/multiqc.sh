#!/usr/bin/env bash
# ==============================================================================
# modules/multiqc.sh - Aggregate QC Reports Across Cohort
# ==============================================================================
set -euo pipefail

RESULTS_DIR="${1:-results}"
REPORTS_DIR="${2:-results/reports}"

if [[ ! -d "$RESULTS_DIR" ]]; then
    echo "[MULTIQC ERROR] Results directory does not exist: $RESULTS_DIR" >&2
    exit 1
fi

mkdir -p "$REPORTS_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MULTIQC] Scanning ${RESULTS_DIR} for QC and metric outputs..."

multiqc "$RESULTS_DIR" \
    --outdir "$REPORTS_DIR" \
    --filename "multiqc_report.html" \
    --force \
    --interactive

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MULTIQC] MultiQC summary report generated at: ${REPORTS_DIR}/multiqc_report.html"
