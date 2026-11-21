#!/usr/bin/env bash
# ==============================================================================
# modules/filter_variants.sh - Hard-Filter Variant Calls
# ==============================================================================
set -euo pipefail

SAMPLE_ID="${1:-}"
IN_VCF="${2:-}"
REFERENCE="${3:-}"
OUT_DIR="${4:-}"
JAVA_OPTS="${5:--Xmx4g}"
FILTER_EXPR="${6:-QD < 2.0 || FS > 60.0 || MQ < 40.0}"
FILTER_NAME="${7:-StandardExomeFilter}"

if [[ -z "$SAMPLE_ID" || -z "$IN_VCF" || -z "$REFERENCE" || -z "$OUT_DIR" ]]; then
    echo "[FILTER ERROR] Missing required arguments." >&2
    echo "Usage: $0 <SAMPLE_ID> <IN_VCF> <REFERENCE> <OUT_DIR> [JAVA_OPTS] [FILTER_EXPR] [FILTER_NAME]" >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
FILTERED_VCF="${OUT_DIR}/${SAMPLE_ID}.filtered.vcf"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FILTER] Filtering variants for sample: ${SAMPLE_ID}"

gatk --java-options "$JAVA_OPTS" VariantFiltration \
    -V "$IN_VCF" \
    -R "$REFERENCE" \
    -O "$FILTERED_VCF" \
    --filter-expression "$FILTER_EXPR" \
    --filter-name "$FILTER_NAME"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FILTER] Filtered VCF produced: ${FILTERED_VCF}"
