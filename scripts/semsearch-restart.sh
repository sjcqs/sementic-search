#!/usr/bin/env bash
set -euo pipefail

_self="$0"; while [ -L "$_self" ]; do _self="$(readlink "$_self")"; done
source "$(cd "$(dirname "$_self")" && pwd)/_common.sh"

STOP_ARGS=()
START_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --colima)
            STOP_ARGS+=(--colima)
            ;;
        --no-ollama)
            STOP_ARGS+=(--keep-ollama)
            START_ARGS+=(--no-ollama)
            ;;
        --help|-h)
            echo "Usage: $0 [--colima] [--no-ollama] [--help]"
            echo ""
            echo "Restart all semantic search services (stop then start)."
            echo ""
            echo "Options:"
            echo "  --colima     Also restart the Colima VM"
            echo "  --no-ollama  Skip Ollama on restart"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Run '$0 --help' for usage."
            exit 1
            ;;
    esac
done

info "Stopping services..."
bash "$SCRIPT_DIR/semsearch-stop.sh" "${STOP_ARGS[@]+"${STOP_ARGS[@]}"}"

echo ""
info "Starting services..."
bash "$SCRIPT_DIR/semsearch-start.sh" "${START_ARGS[@]+"${START_ARGS[@]}"}"
