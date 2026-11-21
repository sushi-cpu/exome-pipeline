#!/usr/bin/env bash
# ==============================================================================
# modules/fastqc.sh - Read Quality Control
# ==============================================================================
set -euo pipefail

SAMPLE_ID="${1:-}"
FASTQ1="${2:-}"
FASTQ2="${3:-}"
OUT_DIR="${4:-}"
THREADS="${5:-2}"

if [[ -z "$SAMPLE_ID" || -z "$FASTQ1" || -z "$FASTQ2" || -z "$OUT_DIR" ]]; then
    echo "[FASTQC ERROR] Missing required arguments." >&2
    echo "Usage: $0 <SAMPLE_ID> <FASTQ1> <FASTQ2> <OUT_DIR> [THREADS]" >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FASTQC] Starting QC for sample: ${SAMPLE_ID}"

fastqc --threads "$THREADS" --outdir "$OUT_DIR" "$FASTQ1" "$FASTQ2"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FASTQC] Completed QC for sample: ${SAMPLE_ID}"
