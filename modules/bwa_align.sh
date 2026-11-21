#!/usr/bin/env bash
# ==============================================================================
# modules/bwa_align.sh - Read Alignment to Reference Genome
# ==============================================================================
set -euo pipefail

SAMPLE_ID="${1:-}"
TRIMMED_R1="${2:-}"
TRIMMED_R2="${3:-}"
OUT_DIR="${4:-}"
REFERENCE="${5:-}"
THREADS="${6:-4}"
BWA_BIN="${7:-bwa}"

if [[ -z "$SAMPLE_ID" || -z "$TRIMMED_R1" || -z "$TRIMMED_R2" || -z "$OUT_DIR" || -z "$REFERENCE" ]]; then
    echo "[BWA ERROR] Missing required arguments." >&2
    echo "Usage: $0 <SAMPLE_ID> <TRIMMED_R1> <TRIMMED_R2> <OUT_DIR> <REFERENCE> [THREADS] [BWA_BIN]" >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
OUT_SAM="${OUT_DIR}/${SAMPLE_ID}.sam"
READ_GROUP="@RG\tID:${SAMPLE_ID}\tSM:${SAMPLE_ID}\tPL:ILLUMINA\tLB:exome_${SAMPLE_ID}\tPU:unit1"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BWA] Aligning reads for sample: ${SAMPLE_ID} using ${BWA_BIN}"

"$BWA_BIN" mem \
    -t "$THREADS" \
    -R "$READ_GROUP" \
    "$REFERENCE" \
    "$TRIMMED_R1" \
    "$TRIMMED_R2" > "$OUT_SAM"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BWA] Alignment completed: ${OUT_SAM}"
