#!/usr/bin/env bash
# ==============================================================================
# modules/compress_index.sh - Compress and Index Final VCF
# ==============================================================================
set -euo pipefail

SAMPLE_ID="${1:-}"
IN_VCF="${2:-}"
OUT_DIR="${3:-}"

if [[ -z "$SAMPLE_ID" || -z "$IN_VCF" || -z "$OUT_DIR" ]]; then
    echo "[COMPRESS_INDEX ERROR] Missing required arguments." >&2
    echo "Usage: $0 <SAMPLE_ID> <IN_VCF> <OUT_DIR>" >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
FINAL_VCF_GZ="${OUT_DIR}/${SAMPLE_ID}.filtered.vcf.gz"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [COMPRESS_INDEX] Compressing and indexing final calls for: ${SAMPLE_ID}"

# If already bgzipped, copy or symlink, else bgzip
if [[ "$IN_VCF" == *.gz ]]; then
    cp "$IN_VCF" "$FINAL_VCF_GZ"
else
    bgzip -c "$IN_VCF" > "$FINAL_VCF_GZ"
fi

tabix -p vcf -f "$FINAL_VCF_GZ"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [COMPRESS_INDEX] Final indexed release: ${FINAL_VCF_GZ} and ${FINAL_VCF_GZ}.tbi"
