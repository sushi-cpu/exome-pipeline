#!/usr/bin/env bash
# ==============================================================================
# modules/sam_to_bam.sh - Convert Alignment Format (SAM to BAM)
# ==============================================================================
set -euo pipefail

SAMPLE_ID="${1:-}"
IN_SAM="${2:-}"
OUT_DIR="${3:-}"
THREADS="${4:-2}"
KEEP_SAM="${5:-false}"

if [[ -z "$SAMPLE_ID" || -z "$IN_SAM" || -z "$OUT_DIR" ]]; then
    echo "[SAM2BAM ERROR] Missing required arguments." >&2
    echo "Usage: $0 <SAMPLE_ID> <IN_SAM> <OUT_DIR> [THREADS] [KEEP_SAM]" >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
OUT_BAM="${OUT_DIR}/${SAMPLE_ID}.bam"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SAM2BAM] Converting SAM to BAM for sample: ${SAMPLE_ID}"

samtools view -@ "$THREADS" -b -o "$OUT_BAM" "$IN_SAM"

if [[ "$KEEP_SAM" != "true" ]]; then
    rm -f "$IN_SAM"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SAM2BAM] Cleaned up temporary SAM: ${IN_SAM}"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SAM2BAM] BAM created: ${OUT_BAM}"
