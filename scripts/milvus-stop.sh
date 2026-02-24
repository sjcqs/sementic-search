#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MILVUS_DIR="$SCRIPT_DIR/../.milvus"
MILVUS_SCRIPT="standalone_embed.sh"

STOP_COLIMA=false
for arg in "$@"; do
    case "$arg" in
        --colima) STOP_COLIMA=true ;;
        *)
            echo "Usage: $0 [--colima]"
            echo "  --colima  Also stop the Colima VM to free system resources"
            exit 1
            ;;
    esac
done

# --- Milvus ---
if [ -f "$MILVUS_DIR/$MILVUS_SCRIPT" ]; then
    echo "Stopping Milvus..."
    cd "$MILVUS_DIR"
    bash "$MILVUS_SCRIPT" stop
    echo "Milvus stopped."
else
    echo "Milvus script not found at $MILVUS_DIR/$MILVUS_SCRIPT — nothing to stop."
fi

# --- Colima ---
if [ "$STOP_COLIMA" = true ]; then
    if colima status &>/dev/null; then
        echo "Stopping Colima..."
        colima stop
        echo "Colima stopped."
    else
        echo "Colima is not running."
    fi
fi
