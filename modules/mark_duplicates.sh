#!/usr/bin/env bash
# ==============================================================================
# modules/mark_duplicates.sh - Identify and Mark Duplicate Reads
# ==============================================================================
set -euo pipefail

SAMPLE_ID="${1:-}"
IN_BAM="${2:-}"
OUT_DIR="${3:-}"
JAVA_OPTS="${4:--Xmx4g}"
VALIDATION_STR="${5:-LENIENT}"
REMOVE_DUPS="${6:-false}"

if [[ -z "$SAMPLE_ID" || -z "$IN_BAM" || -z "$OUT_DIR" ]]; then
    echo "[MARK_DUPLICATES ERROR] Missing required arguments." >&2
    echo "Usage: $0 <SAMPLE_ID> <IN_BAM> <OUT_DIR> [JAVA_OPTS] [VALIDATION_STR] [REMOVE_DUPS]" >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
DEDUP_BAM="${OUT_DIR}/${SAMPLE_ID}.dedup.bam"
METRICS_FILE="${OUT_DIR}/${SAMPLE_ID}.dedup.metrics.txt"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MARK_DUPLICATES] Marking duplicates for sample: ${SAMPLE_ID}"

gatk --java-options "$JAVA_OPTS" MarkDuplicates \
    -I "$IN_BAM" \
    -O "$DEDUP_BAM" \
    -M "$METRICS_FILE" \
    --VALIDATION_STRINGENCY "$VALIDATION_STR" \
    --REMOVE_DUPLICATES "$REMOVE_DUPS" \
    --CREATE_INDEX true

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MARK_DUPLICATES] Marked BAM: ${DEDUP_BAM}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MARK_DUPLICATES] Metrics: ${METRICS_FILE}"
