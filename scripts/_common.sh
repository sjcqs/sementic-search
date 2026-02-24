#!/usr/bin/env bash
# Shared variables and helpers for semsearch-* scripts.
# Source this file; do not execute directly.

# --- Paths ---
_SOURCE="${BASH_SOURCE[0]}"
while [ -L "$_SOURCE" ]; do
    _SOURCE="$(readlink "$_SOURCE")"
done
SCRIPT_DIR="$(cd "$(dirname "$_SOURCE")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MILVUS_DIR="$PROJECT_DIR/.milvus"

# --- Defaults ---
COLIMA_CPU="${COLIMA_CPU:-4}"
COLIMA_MEMORY="${COLIMA_MEMORY:-8}"
COLIMA_DISK="${COLIMA_DISK:-100}"
EMBEDDING_MODEL="${EMBEDDING_MODEL:-nomic-embed-text:v1.5}"
MILVUS_ADDRESS="${MILVUS_ADDRESS:-http://localhost:19530}"
EMBEDDING_PROVIDER="${EMBEDDING_PROVIDER:-Ollama}"
EMBEDDING_BATCH_SIZE="${EMBEDDING_BATCH_SIZE:-10}"

# --- Helpers ---
info()  { echo "==> $*"; }
warn()  { echo "WARNING: $*" >&2; }
die()   { echo "ERROR: $*" >&2; exit 1; }

require_cmd() {
    local cmd="$1"
    local hint="${2:-}"
    if ! command -v "$cmd" &>/dev/null; then
        if [ -n "$hint" ]; then
            echo "  ✗ $cmd — not found. Install: $hint"
        else
            echo "  ✗ $cmd — not found."
        fi
        return 1
    fi
    echo "  ✓ $cmd"
    return 0
}

require_or_install_cmd() {
    local cmd="$1"
    local install_cmd="${2:-}"
    if command -v "$cmd" &>/dev/null; then
        echo "  ✓ $cmd"
        return 0
    fi
    if [ -z "$install_cmd" ]; then
        echo "  ✗ $cmd — not found (no install command available)"
        return 1
    fi
    echo "  ✗ $cmd — not found. Installing via: $install_cmd"
    if eval "$install_cmd"; then
        echo "  ✓ $cmd — installed"
        return 0
    else
        echo "  ✗ $cmd — installation failed"
        return 1
    fi
}

ollama_is_running() {
    curl -sf http://localhost:11434/api/tags &>/dev/null
}

milvus_is_healthy() {
    curl -sf http://localhost:9091/healthz &>/dev/null
}

colima_is_running() {
    colima status &>/dev/null
}
