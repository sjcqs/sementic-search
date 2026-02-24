#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MILVUS_DIR="$SCRIPT_DIR/../.milvus"
MILVUS_SCRIPT="standalone_embed.sh"

RESTART_COLIMA=false
for arg in "$@"; do
    case "$arg" in
        --colima) RESTART_COLIMA=true ;;
        *)
            echo "Usage: $0 [--colima]"
            echo "  --colima  Also restart the Colima VM"
            exit 1
            ;;
    esac
done

# --- Colima restart ---
if [ "$RESTART_COLIMA" = true ]; then
    COLIMA_CPU=${COLIMA_CPU:-4}
    COLIMA_MEMORY=${COLIMA_MEMORY:-8}
    COLIMA_DISK=${COLIMA_DISK:-100}

    echo "Restarting Colima..."
    colima stop 2>/dev/null || true
    colima start --cpu "$COLIMA_CPU" --memory "$COLIMA_MEMORY" --disk "$COLIMA_DISK"
    docker context use colima &>/dev/null || true
fi

# --- Milvus restart ---
if [ -f "$MILVUS_DIR/$MILVUS_SCRIPT" ]; then
    echo "Restarting Milvus..."
    cd "$MILVUS_DIR"
    bash "$MILVUS_SCRIPT" stop  2>/dev/null || true
    bash "$MILVUS_SCRIPT" start
else
    echo "Milvus script not found. Running start script instead..."
    bash "$SCRIPT_DIR/milvus-start.sh"
fi

echo ""
echo "Milvus is running."
echo "  gRPC endpoint : localhost:19530"
echo "  WebUI          : http://127.0.0.1:9091/webui/"
