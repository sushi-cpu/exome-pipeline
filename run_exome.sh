#!/usr/bin/env bash
# ==============================================================================
# run_exome.sh - Whole Exome Sequencing (WES) Orchestrator
# ==============================================================================
# Architecture Design:
# - Pure configuration decoupling: all baseline variables loaded from exome.config
# - CLI overrides for flexible cohort execution
# - Modular decoupled execution passing through discrete step scripts
# - Comprehensive timing, exit trapping, and layout orchestration
# ==============================================================================
set -euo pipefail

START_TIME=$(date +%s)
START_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# ------------------------------------------------------------------------------
# 1. Load Baseline Configuration
# ------------------------------------------------------------------------------
CONFIG_PATH="./exome.config"

# Quick scan for custom --config before sourcing
for ((i=1; i<=$#; i++)); do
    if [[ "${!i}" == "--config" ]]; then
        next_idx=$((i+1))
        if [[ $next_idx -le $# ]]; then
            CONFIG_PATH="${!next_idx}"
        fi
        break
    fi
done

if [[ ! -f "$CONFIG_PATH" ]]; then
    if [[ -f "./exome.config.example" ]]; then
        echo "[WARNING] ${CONFIG_PATH} not found. Falling back to ./exome.config.example"
        CONFIG_PATH="./exome.config.example"
    else
        echo "[FATAL] Configuration file not found: ${CONFIG_PATH}" >&2
        exit 1
    fi
fi

# Source configuration file (All variables assigned here)
source "$CONFIG_PATH"

# ------------------------------------------------------------------------------
# 2. Command-Line Argument Parsing (Overrides Config Defaults)
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --config PATH         Path to custom configuration file (default: ./exome.config)
  --samplesheet PATH    Path to input samplesheet CSV (default: ${SAMPLESHEET})
  --layout MODE         Output layout mode: 'sample' or 'stage' (default: ${LAYOUT})
  --results-dir PATH    Directory to store analysis results (default: ${RESULTS_DIR})
  --logs-dir PATH       Directory to store execution logs (default: ${LOGS_DIR})
  --threads NUM         Total CPU threads to allocate (default: ${TOTAL_THREADS})
  --dry-run             Validate configuration and paths without executing tools
  --help, -h            Show this help message and exit

Samplesheet Format:
  CSV header: sample,patient,fastq_1,fastq_2
  Example:    NA12878,patient1,/data/NA12878_R1.fq.gz,/data/NA12878_R2.fq.gz
EOF
}

while (($#)); do
    case "$1" in
        --config)
            # Already parsed for sourcing
            shift 2
            ;;
        --samplesheet)
            [[ $# -ge 2 ]] || { echo "Error: --samplesheet requires an argument" >&2; exit 2; }
            SAMPLESHEET="$2"
            shift 2
            ;;
        --layout)
            [[ $# -ge 2 ]] || { echo "Error: --layout requires 'sample' or 'stage'" >&2; exit 2; }
            LAYOUT="$2"
            shift 2
            ;;
        --results-dir)
            [[ $# -ge 2 ]] || { echo "Error: --results-dir requires an argument" >&2; exit 2; }
            RESULTS_DIR="$2"
            shift 2
            ;;
        --logs-dir)
            [[ $# -ge 2 ]] || { echo "Error: --logs-dir requires an argument" >&2; exit 2; }
            LOGS_DIR="$2"
            shift 2
            ;;
        --threads)
            [[ $# -ge 2 ]] || { echo "Error: --threads requires a number" >&2; exit 2; }
            TOTAL_THREADS="$2"
            BWA_THREADS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift 1
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown argument: $1" >&2
            show_help
            exit 2
            ;;
    esac
done

# ------------------------------------------------------------------------------
# 3. Environment and Input Verification
# ------------------------------------------------------------------------------
echo "======================================================================"
echo "    Whole Exome Sequencing (WES) Pipeline Orchestrator"
echo "======================================================================"
echo "Started At:         ${START_DATE}"
echo "Configuration:      ${CONFIG_PATH}"
echo "Samplesheet:        ${SAMPLESHEET}"
echo "Results Directory:  ${RESULTS_DIR}"
echo "Logs Directory:     ${LOGS_DIR}"
echo "Layout Strategy:    ${LAYOUT}"
echo "Total Threads:      ${TOTAL_THREADS}"
echo "Reference Genome:   ${REFERENCE}"
echo "Dry Run Mode:       ${DRY_RUN}"
echo "======================================================================"

if [[ ! -f "$SAMPLESHEET" ]]; then
    echo "[FATAL] Samplesheet not found: ${SAMPLESHEET}" >&2
    exit 1
fi

mkdir -p "$RESULTS_DIR" "$LOGS_DIR" "${RESULTS_DIR}/reports"

# Validate tools existence when not in dry-run
REQUIRED_TOOLS=("fastqc" "fastp" "$BWA_BIN" "samtools" "gatk" "bgzip" "tabix")
if [[ "$RUN_MULTIQC" == "true" ]]; then
    REQUIRED_TOOLS+=("multiqc")
fi

if [[ "$DRY_RUN" != "true" ]]; then
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo "[FATAL] Required executable not found in PATH: $tool" >&2
            echo "Please activate the conda environment (conda activate exome) or run inside Docker." >&2
            exit 127
        fi
    done
fi

# ------------------------------------------------------------------------------
# 4. Process Samplesheet
# ------------------------------------------------------------------------------
PROCESSED_COUNT=0
FAILED_COUNT=0

# Ensure modules are executable
chmod +x "${MODULES_DIR}"/*.sh

# Read samplesheet while tolerating CRLF and varying header whitespaces
while IFS=',' read -r col1 col2 col3 col4 || [[ -n "$col1" ]]; do
    # Trim leading/trailing whitespace and quotes
    SAMPLE=$(echo "$col1" | tr -d ' "\r\t')
    PATIENT=$(echo "$col2" | tr -d ' "\r\t')
    FASTQ1=$(echo "$col3" | tr -d ' "\r\t')
    FASTQ2=$(echo "$col4" | tr -d ' "\r\t')

    # Skip header or empty lines
    if [[ -z "$SAMPLE" || "$SAMPLE" =~ ^# || "$SAMPLE" == "sample" ]]; then
        continue
    fi

    SAMPLE_START=$(date +%s)
    echo ""
    echo "----------------------------------------------------------------------"
    echo ">>> Processing Sample: [${SAMPLE}] (Patient: ${PATIENT})"
    echo "    FASTQ 1: ${FASTQ1}"
    echo "    FASTQ 2: ${FASTQ2}"
    echo "----------------------------------------------------------------------"

    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ ! -f "$FASTQ1" ]]; then
            echo "[ERROR] FASTQ 1 file not found: ${FASTQ1}" >&2
            ((FAILED_COUNT++)) || true
            continue
        fi
        if [[ ! -f "$FASTQ2" ]]; then
            echo "[ERROR] FASTQ 2 file not found: ${FASTQ2}" >&2
            ((FAILED_COUNT++)) || true
            continue
        fi
    fi

    # Establish output folders according to selected LAYOUT strategy
    if [[ "$LAYOUT" == "sample" ]]; then
        SAMPLE_ROOT="${RESULTS_DIR}/${SAMPLE}"
        DIR_FASTQC="${SAMPLE_ROOT}/fastqc"
        DIR_TRIMMED="${SAMPLE_ROOT}/trimmed_fastq"
        DIR_ALIGN="${SAMPLE_ROOT}/alignment"
        DIR_BAM="${SAMPLE_ROOT}/bam"
        DIR_SORTED="${SAMPLE_ROOT}/sorted"
        DIR_DEDUP="${SAMPLE_ROOT}/duplicate_marked"
        DIR_BQSR="${SAMPLE_ROOT}/bqsr"
        DIR_RAW_VCF="${SAMPLE_ROOT}/raw_vcf"
        DIR_FILTER_VCF="${SAMPLE_ROOT}/filtered_vcf"
        DIR_FINAL_VCF="${SAMPLE_ROOT}/final_vcf"
    elif [[ "$LAYOUT" == "stage" ]]; then
        DIR_FASTQC="${RESULTS_DIR}/fastqc"
        DIR_TRIMMED="${RESULTS_DIR}/trimmed_fastq"
        DIR_ALIGN="${RESULTS_DIR}/alignment"
        DIR_BAM="${RESULTS_DIR}/bam"
        DIR_SORTED="${RESULTS_DIR}/sorted"
        DIR_DEDUP="${RESULTS_DIR}/duplicate_marked"
        DIR_BQSR="${RESULTS_DIR}/bqsr"
        DIR_RAW_VCF="${RESULTS_DIR}/raw_vcf"
        DIR_FILTER_VCF="${RESULTS_DIR}/filtered_vcf"
        DIR_FINAL_VCF="${RESULTS_DIR}/final_vcf"
    else
        echo "[FATAL] Invalid LAYOUT option: '${LAYOUT}'. Choose 'sample' or 'stage'." >&2
        exit 2
    fi

    mkdir -p "$DIR_FASTQC" "$DIR_TRIMMED" "$DIR_ALIGN" "$DIR_BAM" \
             "$DIR_SORTED" "$DIR_DEDUP" "$DIR_BQSR" "$DIR_RAW_VCF" \
             "$DIR_FILTER_VCF" "$DIR_FINAL_VCF"

    SAMPLE_LOG="${LOGS_DIR}/${SAMPLE}_$(date '+%Y%m%d_%H%M%S').log"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would execute pipeline modules 1 through 11 for sample ${SAMPLE}"
        echo "          Target layout folders created in ${RESULTS_DIR}"
        ((PROCESSED_COUNT++)) || true
        continue
    fi

    # Wrap per-sample execution with log redirect
    {
        # Step 1: Read Quality Control
        echo "[STAGE 1/11] FastQC: Quality control on raw reads..."
        "${MODULES_DIR}/fastqc.sh" "$SAMPLE" "$FASTQ1" "$FASTQ2" "$DIR_FASTQC" "$FASTQC_THREADS"

        # Step 2: Quality & Adapter Trimming
        echo "[STAGE 2/11] fastp: Trimming adapters and low-quality bases..."
        "${MODULES_DIR}/fastp.sh" "$SAMPLE" "$FASTQ1" "$FASTQ2" "$DIR_TRIMMED" "$FASTP_THREADS" "$FASTP_MIN_LENGTH" "$FASTP_QUAL_PHRED"
        TRIMMED_R1="${DIR_TRIMMED}/${SAMPLE}_R1.trimmed.fastq.gz"
        TRIMMED_R2="${DIR_TRIMMED}/${SAMPLE}_R2.trimmed.fastq.gz"

        # Step 3: BWA-MEM Alignment
        echo "[STAGE 3/11] ${BWA_BIN}: Aligning trimmed reads to reference..."
        "${MODULES_DIR}/bwa_align.sh" "$SAMPLE" "$TRIMMED_R1" "$TRIMMED_R2" "$DIR_ALIGN" "$REFERENCE" "$BWA_THREADS" "$BWA_BIN"
        ALIGN_SAM="${DIR_ALIGN}/${SAMPLE}.sam"

        # Step 4: SAM to BAM conversion
        echo "[STAGE 4/11] samtools view: Converting SAM to binary BAM format..."
        "${MODULES_DIR}/sam_to_bam.sh" "$SAMPLE" "$ALIGN_SAM" "$DIR_BAM" "$SAMTOOLS_THREADS" "$KEEP_INTERMEDIATE_BAM"
        RAW_BAM="${DIR_BAM}/${SAMPLE}.bam"

        # Step 5: Sort and Index
        echo "[STAGE 5/11] samtools sort: Coordinate-sorting and indexing alignments..."
        "${MODULES_DIR}/sort_index.sh" "$SAMPLE" "$RAW_BAM" "$DIR_SORTED" "$SAMTOOLS_THREADS" "$KEEP_INTERMEDIATE_BAM"
        SORTED_BAM="${DIR_SORTED}/${SAMPLE}.sorted.bam"

        # Step 6: Mark Duplicates
        echo "[STAGE 6/11] GATK MarkDuplicates: Identifying PCR and optical duplicate reads..."
        "${MODULES_DIR}/mark_duplicates.sh" "$SAMPLE" "$SORTED_BAM" "$DIR_DEDUP" "$GATK_JAVA_OPTIONS" "$PICARD_VALIDATION_STRINGENCY" "$REMOVE_DUPLICATES"
        DEDUP_BAM="${DIR_DEDUP}/${SAMPLE}.dedup.bam"

        # Step 7: BQSR
        echo "[STAGE 7/11] GATK BQSR: Recalibrating base quality scores..."
        "${MODULES_DIR}/bqsr.sh" "$SAMPLE" "$DEDUP_BAM" "$REFERENCE" "$KNOWN_SITES" "$DIR_BQSR" "$GATK_JAVA_OPTIONS"
        BQSR_BAM="${DIR_BQSR}/${SAMPLE}.bqsr.bam"

        # Step 8 & 9: HaplotypeCaller
        echo "[STAGE 8-9/11] GATK HaplotypeCaller: Calling germline variants..."
        "${MODULES_DIR}/haplotypecaller.sh" "$SAMPLE" "$BQSR_BAM" "$REFERENCE" "$TARGET_BED" "$DIR_RAW_VCF" "$GATK_JAVA_OPTIONS" "$GATK_HC_EXTRA_ARGS"
        RAW_VCF="${DIR_RAW_VCF}/${SAMPLE}.raw.vcf.gz"

        # Step 10: Variant Filtering
        echo "[STAGE 10/11] GATK VariantFiltration: Applying hard filters to callset..."
        "${MODULES_DIR}/filter_variants.sh" "$SAMPLE" "$RAW_VCF" "$REFERENCE" "$DIR_FILTER_VCF" "$GATK_JAVA_OPTIONS" "$GATK_FILTER_EXPRESSION" "$GATK_FILTER_NAME"
        FILTERED_VCF="${DIR_FILTER_VCF}/${SAMPLE}.filtered.vcf"

        # Step 11: Compress and Index
        echo "[STAGE 11/11] bgzip & tabix: Generating final indexed release VCF..."
        "${MODULES_DIR}/compress_index.sh" "$SAMPLE" "$FILTERED_VCF" "$DIR_FINAL_VCF"
        FINAL_VCF="${DIR_FINAL_VCF}/${SAMPLE}.filtered.vcf.gz"

        echo "[SUCCESS] Sample ${SAMPLE} completed successfully."
        echo "          Final VCF: ${FINAL_VCF}"
    } 2>&1 | tee "$SAMPLE_LOG"

    SAMPLE_END=$(date +%s)
    SAMPLE_ELAPSED=$((SAMPLE_END - SAMPLE_START))
    echo ">>> Sample ${SAMPLE} runtime: ${SAMPLE_ELAPSED} seconds. Log saved to: ${SAMPLE_LOG}"
    ((PROCESSED_COUNT++)) || true

done < "$SAMPLESHEET"

# ------------------------------------------------------------------------------
# 5. Cohort Summary MultiQC Reporting
# ------------------------------------------------------------------------------
if [[ "$RUN_MULTIQC" == "true" && "$DRY_RUN" != "true" && $PROCESSED_COUNT -gt 0 ]]; then
    echo ""
    echo "======================================================================"
    echo "Generating Cohort MultiQC Report..."
    echo "======================================================================"
    REPORTS_DIR="${RESULTS_DIR}/reports"
    "${MODULES_DIR}/multiqc.sh" "$RESULTS_DIR" "$REPORTS_DIR"
fi

# ------------------------------------------------------------------------------
# 6. Pipeline Execution Summary
# ------------------------------------------------------------------------------
END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
HOURS=$((TOTAL_ELAPSED / 3600))
MINUTES=$(((TOTAL_ELAPSED % 3600) / 60))
SECONDS=$((TOTAL_ELAPSED % 60))

echo ""
echo "======================================================================"
echo "    Whole Exome Sequencing Pipeline Execution Finished"
echo "======================================================================"
echo "Samples Processed:  ${PROCESSED_COUNT}"
echo "Samples Failed:     ${FAILED_COUNT}"
printf "Total Wall Time:    %02d hours, %02d minutes, %02d seconds\n" "$HOURS" "$MINUTES" "$SECONDS"
echo "Results Root:       ${RESULTS_DIR}"
echo "Logs Directory:     ${LOGS_DIR}"
echo "Completed At:       $(date '+%Y-%m-%d %H:%M:%S')"
echo "======================================================================"

if [[ $FAILED_COUNT -gt 0 ]]; then
    exit 1
fi
exit 0
