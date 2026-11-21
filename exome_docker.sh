#!/usr/bin/env bash
# ==============================================================================
# exome_docker.sh
# Host-Side Docker Wrapper for Whole Exome Sequencing Pipeline
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/exome_docker.config"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Docker mount configuration not found: ${CONFIG_FILE}" >&2
    echo "Please copy exome_docker.config.example to exome_docker.config and configure paths." >&2
    exit 1
fi

source "$CONFIG_FILE"

if [[ $# -ne 2 || "$1" != "--samplesheet" ]]; then
    echo "Usage: $0 --samplesheet PATH_TO_HOST_SAMPLESHEET" >&2
    exit 2
fi

# Resolve absolute path for the host samplesheet
SAMPLESHEET_DIR="$(cd "$(dirname "$2")" && pwd)"
SAMPLESHEET_BASE="$(basename "$2")"
SAMPLESHEET="${SAMPLESHEET_DIR}/${SAMPLESHEET_BASE}"

if [[ ! -f "$SAMPLESHEET" ]]; then
    echo "Error: samplesheet not found on host: $2" >&2
    exit 1
fi

# Ensure host mount source directories exist
for directory in "$HOST_DATA_DIR" "$HOST_REFERENCE_DIR"; do
    if [[ ! -d "$directory" ]]; then
        echo "Error: mount source directory not found on host: $directory" >&2
        exit 1
    fi
done

# Ensure output directories exist on host
mkdir -p "$HOST_RESULTS_DIR" "$HOST_LOGS_DIR"

echo "============================================================"
echo "Launching Exome Pipeline Container: ${IMAGE_NAME}"
echo "Host Data:       ${HOST_DATA_DIR} -> ${CONTAINER_DATA_DIR}"
echo "Host Reference:  ${HOST_REFERENCE_DIR} -> ${CONTAINER_REFERENCE_DIR}"
echo "Host Results:    ${HOST_RESULTS_DIR} -> ${CONTAINER_RESULTS_DIR}"
echo "Host Logs:       ${HOST_LOGS_DIR} -> ${CONTAINER_LOGS_DIR}"
echo "Samplesheet:     ${SAMPLESHEET} -> ${CONTAINER_SAMPLESHEET_PATH}"
echo "============================================================"

exec docker run --rm \
    --cpus="$DOCKER_CPUS" \
    --memory="$DOCKER_MEMORY" \
    --mount "type=bind,src=${HOST_DATA_DIR},dst=${CONTAINER_DATA_DIR},readonly" \
    --mount "type=bind,src=${HOST_REFERENCE_DIR},dst=${CONTAINER_REFERENCE_DIR},readonly" \
    --mount "type=bind,src=${HOST_RESULTS_DIR},dst=${CONTAINER_RESULTS_DIR}" \
    --mount "type=bind,src=${HOST_LOGS_DIR},dst=${CONTAINER_LOGS_DIR}" \
    --mount "type=bind,src=${SAMPLESHEET},dst=${CONTAINER_SAMPLESHEET_PATH},readonly" \
    "$IMAGE_NAME" \
    --samplesheet "$CONTAINER_SAMPLESHEET_PATH"
