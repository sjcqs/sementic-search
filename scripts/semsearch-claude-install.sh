#!/usr/bin/env bash
set -euo pipefail

_self="$0"; while [ -L "$_self" ]; do _self="$(readlink "$_self")"; done
source "$(cd "$(dirname "$_self")" && pwd)/_common.sh"

ACTION="install"

for arg in "$@"; do
    case "$arg" in
        --remove)
            ACTION="remove"
            ;;
        --help|-h)
            echo "Usage: $0 [--remove] [--help]"
            echo ""
            echo "Add (or remove) the claude-context MCP server for the current project."
            echo ""
            echo "Options:"
            echo "  --remove  Remove the MCP server instead of adding it"
            echo "  --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Run '$0 --help' for usage."
            exit 1
            ;;
    esac
done

# --- Prerequisites ---
if ! command -v claude &>/dev/null; then
    die "claude CLI not found. Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
fi

MCP_NAME="claude-context"

if [ "$ACTION" = "remove" ]; then
    info "Removing MCP server '$MCP_NAME'..."
    claude mcp remove "$MCP_NAME" 2>/dev/null \
        && echo "  Removed '$MCP_NAME'." \
        || echo "  '$MCP_NAME' was not configured."
    exit 0
fi

# --- Install ---
info "Adding MCP server '$MCP_NAME' to local project..."

claude mcp add "$MCP_NAME" \
    -t stdio \
    -e "EMBEDDING_PROVIDER=$EMBEDDING_PROVIDER" \
    -e "EMBEDDING_MODEL=$EMBEDDING_MODEL" \
    -e "MILVUS_ADDRESS=$MILVUS_ADDRESS" \
    -e "EMBEDDING_BATCH_SIZE=$EMBEDDING_BATCH_SIZE" \
    -- npx -y @zilliz/claude-context-mcp@latest

echo ""
info "MCP server '$MCP_NAME' added."
echo "  Restart Claude Code to pick up the new server."
echo "  Run '$0 --remove' to uninstall."
