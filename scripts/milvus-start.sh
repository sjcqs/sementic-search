#!/usr/bin/env bash
set -euo pipefail

COLIMA_CPU=${COLIMA_CPU:-4}
COLIMA_MEMORY=${COLIMA_MEMORY:-8}
COLIMA_DISK=${COLIMA_DISK:-100}
MILVUS_SCRIPT="standalone_embed.sh"
MILVUS_SCRIPT_URL="https://raw.githubusercontent.com/milvus-io/milvus/master/scripts/standalone_embed.sh"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MILVUS_DIR="$SCRIPT_DIR/../.milvus"

mkdir -p "$MILVUS_DIR"

# --- Colima ---
if ! command -v colima &>/dev/null; then
    echo "Error: colima is not installed. Run: brew install colima docker"
    exit 1
fi

if ! colima status &>/dev/null; then
    echo "Starting Colima (cpu=$COLIMA_CPU, memory=$COLIMA_MEMORY GB, disk=$COLIMA_DISK GB)..."
    colima start --cpu "$COLIMA_CPU" --memory "$COLIMA_MEMORY" --disk "$COLIMA_DISK"
else
    echo "Colima is already running."
fi

# Ensure docker context points to Colima
docker context use colima &>/dev/null || true

# --- Milvus ---
if ! [ -f "$MILVUS_DIR/$MILVUS_SCRIPT" ]; then
    echo "Downloading Milvus standalone script..."
    curl -sfL "$MILVUS_SCRIPT_URL" -o "$MILVUS_DIR/$MILVUS_SCRIPT"
fi

echo "Starting Milvus..."
cd "$MILVUS_DIR"
bash "$MILVUS_SCRIPT" start

echo ""
echo "Milvus is running."
echo "  gRPC endpoint : localhost:19530"
echo "  WebUI          : http://127.0.0.1:9091/webui/"
