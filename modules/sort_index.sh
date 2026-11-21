#!/usr/bin/env bash
# ==============================================================================
# modules/sort_index.sh - Coordinate Sort and Index BAM
# ==============================================================================
set -euo pipefail

SAMPLE_ID="${1:-}"
IN_BAM="${2:-}"
OUT_DIR="${3:-}"
THREADS="${4:-2}"
KEEP_UNSORTED="${5:-false}"

if [[ -z "$SAMPLE_ID" || -z "$IN_BAM" || -z "$OUT_DIR" ]]; then
    echo "[SORT_INDEX ERROR] Missing required arguments." >&2
    echo "Usage: $0 <SAMPLE_ID> <IN_BAM> <OUT_DIR> [THREADS] [KEEP_UNSORTED]" >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
SORTED_BAM="${OUT_DIR}/${SAMPLE_ID}.sorted.bam"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SORT_INDEX] Sorting BAM for sample: ${SAMPLE_ID}"

samtools sort -@ "$THREADS" -o "$SORTED_BAM" "$IN_BAM"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SORT_INDEX] Indexing sorted BAM: ${SORTED_BAM}"

samtools index -@ "$THREADS" "$SORTED_BAM"

if [[ "$KEEP_UNSORTED" != "true" && "$IN_BAM" != "$SORTED_BAM" ]]; then
    rm -f "$IN_BAM"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SORT_INDEX] Cleaned up unsorted BAM: ${IN_BAM}"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SORT_INDEX] Sorted BAM and BAI ready: ${SORTED_BAM}"
