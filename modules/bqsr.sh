#!/usr/bin/env bash
# ==============================================================================
# modules/bqsr.sh - Base Quality Score Recalibration
# ==============================================================================
set -euo pipefail

SAMPLE_ID="${1:-}"
IN_BAM="${2:-}"
REFERENCE="${3:-}"
KNOWN_SITES="${4:-}"
OUT_DIR="${5:-}"
JAVA_OPTS="${6:--Xmx4g}"

if [[ -z "$SAMPLE_ID" || -z "$IN_BAM" || -z "$REFERENCE" || -z "$KNOWN_SITES" || -z "$OUT_DIR" ]]; then
    echo "[BQSR ERROR] Missing required arguments." >&2
    echo "Usage: $0 <SAMPLE_ID> <IN_BAM> <REFERENCE> <KNOWN_SITES> <OUT_DIR> [JAVA_OPTS]" >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
RECAL_TABLE="${OUT_DIR}/${SAMPLE_ID}.recal_data.table"
RECAL_BAM="${OUT_DIR}/${SAMPLE_ID}.bqsr.bam"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BQSR] Step 1: Generating recalibration table for sample: ${SAMPLE_ID}"

gatk --java-options "$JAVA_OPTS" BaseRecalibrator \
    -I "$IN_BAM" \
    -R "$REFERENCE" \
    --known-sites "$KNOWN_SITES" \
    -O "$RECAL_TABLE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BQSR] Step 2: Applying BQSR to BAM for sample: ${SAMPLE_ID}"

gatk --java-options "$JAVA_OPTS" ApplyBQSR \
    -I "$IN_BAM" \
    -R "$REFERENCE" \
    --bqsr-recal-file "$RECAL_TABLE" \
    -O "$RECAL_BAM" \
    --create-output-bam-index true

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BQSR] Recalibrated BAM created: ${RECAL_BAM}"
