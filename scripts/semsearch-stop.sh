#!/usr/bin/env bash
set -euo pipefail

_self="$0"; while [ -L "$_self" ]; do _self="$(readlink "$_self")"; done
source "$(cd "$(dirname "$_self")" && pwd)/_common.sh"

STOP_COLIMA=false
KEEP_OLLAMA=false

for arg in "$@"; do
    case "$arg" in
        --colima)       STOP_COLIMA=true ;;
        --keep-ollama)  KEEP_OLLAMA=true ;;
        --milvus-only)  KEEP_OLLAMA=true ;;
        --help|-h)
            echo "Usage: $0 [--colima] [--keep-ollama] [--help]"
            echo ""
            echo "Stop semantic search services."
            echo ""
            echo "Options:"
            echo "  --colima       Also stop the Colima VM"
            echo "  --keep-ollama  Don't stop Ollama (alias: --milvus-only)"
            echo "  --help         Show this help message"
            echo ""
            echo "Default: stops Milvus and Ollama, keeps Colima running."
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Run '$0 --help' for usage."
            exit 1
            ;;
    esac
done

# --- 1. Milvus (delegate to milvus-stop.sh) ---
MILVUS_ARGS=()
if [ "$STOP_COLIMA" = true ]; then
    MILVUS_ARGS+=(--colima)
fi
info "Stopping Milvus..."
bash "$SCRIPT_DIR/milvus-stop.sh" "${MILVUS_ARGS[@]+"${MILVUS_ARGS[@]}"}"

# --- 2. Ollama ---
if [ "$KEEP_OLLAMA" = true ]; then
    info "Keeping Ollama running (--keep-ollama)"
else
    info "Stopping Ollama..."
    # Check if Ollama.app is managing the process
    if pgrep -f "Ollama.app" &>/dev/null; then
        warn "Ollama appears to be managed by Ollama.app — quit the app manually to stop it."
    elif pgrep -f "ollama serve" &>/dev/null; then
        pkill -f "ollama serve" 2>/dev/null || true
        echo "  Ollama stopped."
    else
        echo "  Ollama is not running."
    fi
fi

echo ""
info "Done."
