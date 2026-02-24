#!/usr/bin/env bash
set -euo pipefail

_self="$0"; while [ -L "$_self" ]; do _self="$(readlink "$_self")"; done
source "$(cd "$(dirname "$_self")" && pwd)/_common.sh"

FORCE=false
INSTALL_DEPS=false
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        --dependencies) INSTALL_DEPS=true ;;
        --help|-h)
            echo "Usage: $0 [--force] [--dependencies] [--help]"
            echo ""
            echo "One-time setup for semantic search services."
            echo ""
            echo "Options:"
            echo "  --force          Overwrite existing config files (.envrc)"
            echo "  --dependencies   Install missing dependencies via Homebrew"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Run '$0 --help' for usage."
            exit 1
            ;;
    esac
done

ERRORS=0

# --- 1. Check prerequisites ---
info "Checking prerequisites..."
if [ "$INSTALL_DEPS" = true ]; then
    require_or_install_cmd direnv "brew install direnv"  || ((ERRORS++))
    require_or_install_cmd colima "brew install colima"  || ((ERRORS++))
    require_or_install_cmd docker "brew install docker"  || ((ERRORS++))
    require_or_install_cmd ollama "brew install ollama"  || ((ERRORS++))
    require_or_install_cmd npx    "brew install node"    || ((ERRORS++))
    require_or_install_cmd curl   ""                     || ((ERRORS++))
else
    require_cmd direnv "brew install direnv"       || ((ERRORS++))
    require_cmd colima "brew install colima"       || ((ERRORS++))
    require_cmd docker "brew install docker"        || ((ERRORS++))
    require_cmd ollama "brew install ollama"        || ((ERRORS++))
    require_cmd npx    "brew install node"          || ((ERRORS++))
    require_cmd curl   "(should be pre-installed)"  || ((ERRORS++))
fi

# --- 2. Pull embedding model ---
info "Pulling embedding model ($EMBEDDING_MODEL)..."
if command -v ollama &>/dev/null; then
    if ollama_is_running; then
        ollama pull "$EMBEDDING_MODEL" || { warn "Failed to pull model"; ((ERRORS++)); }
    else
        info "Starting Ollama temporarily to pull model..."
        ollama serve &>/dev/null &
        OLLAMA_PID=$!
        sleep 3
        if ollama_is_running; then
            ollama pull "$EMBEDDING_MODEL" || { warn "Failed to pull model"; ((ERRORS++)); }
            kill "$OLLAMA_PID" 2>/dev/null || true
            wait "$OLLAMA_PID" 2>/dev/null || true
        else
            warn "Could not start Ollama to pull model. Pull it manually: ollama pull $EMBEDDING_MODEL"
            kill "$OLLAMA_PID" 2>/dev/null || true
            ((ERRORS++))
        fi
    fi
else
    warn "ollama not installed — skipping model pull"
fi

# --- 3. Download Milvus standalone script ---
info "Checking Milvus standalone script..."
MILVUS_SCRIPT_URL="https://raw.githubusercontent.com/milvus-io/milvus/master/scripts/standalone_embed.sh"
mkdir -p "$MILVUS_DIR"
if [ ! -f "$MILVUS_DIR/standalone_embed.sh" ]; then
    echo "  Downloading Milvus standalone script..."
    curl -sfL "$MILVUS_SCRIPT_URL" -o "$MILVUS_DIR/standalone_embed.sh" \
        || { warn "Failed to download Milvus script"; ((ERRORS++)); }
else
    echo "  Already exists at $MILVUS_DIR/standalone_embed.sh"
fi

# --- 4. Create .envrc ---
info "Checking .envrc..."
ENVRC_FILE="$PROJECT_DIR/.envrc"
if [ -f "$ENVRC_FILE" ] && [ "$FORCE" = false ]; then
    echo "  Already exists (use --force to overwrite)"
else
    cat > "$ENVRC_FILE" <<EOF
export EMBEDDING_PROVIDER="$EMBEDDING_PROVIDER"
export EMBEDDING_MODEL="$EMBEDDING_MODEL"
export MILVUS_ADDRESS="$MILVUS_ADDRESS"
export EMBEDDING_BATCH_SIZE="$EMBEDDING_BATCH_SIZE"
EOF
    echo "  Created $ENVRC_FILE"
    echo "  Run 'direnv allow' to activate."
fi

# --- Summary ---
echo ""
if [ "$ERRORS" -gt 0 ]; then
    warn "$ERRORS issue(s) encountered — review the output above."
else
    info "Setup complete!"
fi
echo ""
echo "Next steps:"
echo "  1. direnv allow                           # activate env vars"
echo "  2. scripts/semsearch-start.sh             # start all services"
echo "  3. scripts/semsearch-claude-install.sh    # add MCP server to Claude Code"
echo "  4. scripts/semsearch-link.sh              # (optional) add commands to PATH"
