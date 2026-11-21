#!/usr/bin/env bash
# ==============================================================================
# tests/smoke_test.sh - Smoke Test Suite for exome-pipeline
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Running Smoke Test for exome-pipeline ==="
cd "$ROOT_DIR"

# 1. Check all modules exist and are executable
echo "[TEST 1] Verifying modules..."
MODULES=(
    "fastqc.sh"
    "fastp.sh"
    "bwa_align.sh"
    "sam_to_bam.sh"
    "sort_index.sh"
    "mark_duplicates.sh"
    "bqsr.sh"
    "haplotypecaller.sh"
    "filter_variants.sh"
    "compress_index.sh"
    "multiqc.sh"
)

for mod in "${MODULES[@]}"; do
    if [[ ! -x "modules/${mod}" ]]; then
        echo "Error: modules/${mod} does not exist or is not executable!" >&2
        exit 1
    fi
    echo "  ✓ modules/${mod} is executable"
done

# 2. Check runner script
echo "[TEST 2] Verifying runner..."
if [[ ! -x "run_exome.sh" ]]; then
    echo "Error: run_exome.sh is not executable!" >&2
    exit 1
fi
echo "  ✓ run_exome.sh is executable"

# 3. Check Docker script and configs
echo "[TEST 3] Verifying Docker setup files..."
[[ -x "exome_docker.sh" ]] || { echo "Error: exome_docker.sh is missing or not executable" >&2; exit 1; }
[[ -f "exome_docker.config.example" ]] || { echo "Error: exome_docker.config.example is missing" >&2; exit 1; }
[[ -f "Dockerfile" ]] || { echo "Error: Dockerfile is missing" >&2; exit 1; }
[[ -f ".dockerignore" ]] || { echo "Error: .dockerignore is missing" >&2; exit 1; }
echo "  ✓ Docker wrapper and container specs verified"

# 4. Generate synthetic test data if missing
echo "[TEST 4] Checking synthetic test data..."
if [[ ! -f "test_data/test_sample_R1.fastq.gz" ]]; then
    echo "  Generating synthetic test dataset..."
    python3 scripts/generate_synthetic_test_data.py
fi
echo "  ✓ Synthetic test data ready"

# 5. Run dry-run test
echo "[TEST 5] Running dry-run pipeline test (sample layout)..."
./run_exome.sh --samplesheet samplesheets/test.csv --layout sample --dry-run
echo "  ✓ Dry-run sample layout passed"

echo "[TEST 6] Running dry-run pipeline test (stage layout)..."
./run_exome.sh --samplesheet samplesheets/test.csv --layout stage --dry-run
echo "  ✓ Dry-run stage layout passed"

echo "============================================="
echo "🎉 ALL SMOKE TESTS PASSED SUCCESSFULLY!"
echo "============================================="
