#!/usr/bin/env bash
# ==============================================================================
# modules/fastp.sh - Adapter and Quality Trimming
# ==============================================================================
set -euo pipefail

SAMPLE_ID="${1:-}"
FASTQ1="${2:-}"
FASTQ2="${3:-}"
OUT_DIR="${4:-}"
THREADS="${5:-2}"
MIN_LEN="${6:-36}"
QUAL_PHRED="${7:-20}"

if [[ -z "$SAMPLE_ID" || -z "$FASTQ1" || -z "$FASTQ2" || -z "$OUT_DIR" ]]; then
    echo "[FASTP ERROR] Missing required arguments." >&2
    echo "Usage: $0 <SAMPLE_ID> <FASTQ1> <FASTQ2> <OUT_DIR> [THREADS] [MIN_LEN] [QUAL_PHRED]" >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
TRIMMED_R1="${OUT_DIR}/${SAMPLE_ID}_R1.trimmed.fastq.gz"
TRIMMED_R2="${OUT_DIR}/${SAMPLE_ID}_R2.trimmed.fastq.gz"
HTML_REPORT="${OUT_DIR}/${SAMPLE_ID}_fastp.html"
JSON_REPORT="${OUT_DIR}/${SAMPLE_ID}_fastp.json"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FASTP] Starting trimming for sample: ${SAMPLE_ID}"

fastp \
    --thread "$THREADS" \
    --in1 "$FASTQ1" \
    --in2 "$FASTQ2" \
    --out1 "$TRIMMED_R1" \
    --out2 "$TRIMMED_R2" \
    --html "$HTML_REPORT" \
    --json "$JSON_REPORT" \
    --qualified_quality_phred "$QUAL_PHRED" \
    --length_required "$MIN_LEN" \
    --detect_adapter_for_pe

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FASTP] Trimmed reads written to: ${TRIMMED_R1}, ${TRIMMED_R2}"
