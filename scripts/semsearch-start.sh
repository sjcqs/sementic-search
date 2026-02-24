#!/usr/bin/env bash
set -euo pipefail

_self="$0"; while [ -L "$_self" ]; do _self="$(readlink "$_self")"; done
source "$(cd "$(dirname "$_self")" && pwd)/_common.sh"

SKIP_OLLAMA=false
for arg in "$@"; do
    case "$arg" in
        --no-ollama) SKIP_OLLAMA=true ;;
        --help|-h)
            echo "Usage: $0 [--no-ollama] [--help]"
            echo ""
            echo "Start all semantic search services (Ollama, Colima, Milvus)."
            echo ""
            echo "Options:"
            echo "  --no-ollama  Skip starting Ollama"
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

# --- 1. Ollama ---
if [ "$SKIP_OLLAMA" = false ]; then
    info "Checking Ollama..."
    if ollama_is_running; then
        echo "  Ollama is already running."
    else
        echo "  Starting Ollama..."
        ollama serve &>/dev/null &
        disown
        echo "  Waiting for Ollama to be ready..."
        for i in $(seq 1 20); do
            if ollama_is_running; then
                echo "  Ollama is ready."
                break
            fi
            if [ "$i" -eq 20 ]; then
                die "Ollama did not start within 10 seconds."
            fi
            sleep 0.5
        done
    fi
else
    info "Skipping Ollama (--no-ollama)"
fi

# --- 2. Milvus (delegate to milvus-start.sh) ---
info "Starting Milvus (via milvus-start.sh)..."
bash "$SCRIPT_DIR/milvus-start.sh"

# --- 3. Health verification ---
info "Verifying Milvus health..."
for i in $(seq 1 180); do
    if milvus_is_healthy; then
        echo "  Milvus is healthy."
        break
    fi
    if [ "$i" -eq 180 ]; then
        die "Milvus did not become healthy within 90 seconds."
    fi
    sleep 0.5
done

if [ "$SKIP_OLLAMA" = false ] && ollama_is_running; then
    info "Verifying embedding model..."
    if ollama list 2>/dev/null | grep -q "${EMBEDDING_MODEL%%:*}"; then
        echo "  Model '$EMBEDDING_MODEL' is available."
    else
        warn "Model '$EMBEDDING_MODEL' not found. Run: ollama pull $EMBEDDING_MODEL"
    fi
fi

# --- Summary ---
echo ""
info "All services running!"
echo "  Ollama           : http://localhost:11434"
echo "  Milvus gRPC      : localhost:19530"
echo "  Milvus WebUI     : http://127.0.0.1:9091/webui/"
echo "  Embedding model  : $EMBEDDING_MODEL"
