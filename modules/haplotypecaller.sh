#!/usr/bin/env bash
# ==============================================================================
# modules/haplotypecaller.sh - Call Germline SNVs and Indels
# ==============================================================================
set -euo pipefail

SAMPLE_ID="${1:-}"
IN_BAM="${2:-}"
REFERENCE="${3:-}"
TARGET_BED="${4:-}"
OUT_DIR="${5:-}"
JAVA_OPTS="${6:--Xmx4g}"
EXTRA_ARGS="${7:-}"

if [[ -z "$SAMPLE_ID" || -z "$IN_BAM" || -z "$REFERENCE" || -z "$OUT_DIR" ]]; then
    echo "[HAPLOTYPECALLER ERROR] Missing required arguments." >&2
    echo "Usage: $0 <SAMPLE_ID> <IN_BAM> <REFERENCE> <TARGET_BED> <OUT_DIR> [JAVA_OPTS] [EXTRA_ARGS]" >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
RAW_VCF="${OUT_DIR}/${SAMPLE_ID}.raw.vcf.gz"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [HAPLOTYPECALLER] Calling variants for sample: ${SAMPLE_ID}"

INTERVAL_ARG=()
if [[ -n "$TARGET_BED" && -f "$TARGET_BED" ]]; then
    INTERVAL_ARG=("-L" "$TARGET_BED")
fi

gatk --java-options "$JAVA_OPTS" HaplotypeCaller \
    -I "$IN_BAM" \
    -R "$REFERENCE" \
    "${INTERVAL_ARG[@]}" \
    -O "$RAW_VCF" \
    $EXTRA_ARGS

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [HAPLOTYPECALLER] Raw callset written: ${RAW_VCF}"
