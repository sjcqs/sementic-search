#!/usr/bin/env bash
set -euo pipefail

_self="$0"; while [ -L "$_self" ]; do _self="$(readlink "$_self")"; done
source "$(cd "$(dirname "$_self")" && pwd)/_common.sh"

TARGET_DIR="$HOME/bin"
REMOVE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        --remove)
            REMOVE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--dir <path>] [--remove] [--help]"
            echo ""
            echo "Create or remove symlinks for semsearch-* commands."
            echo ""
            echo "Options:"
            echo "  --dir <path>  Target directory (default: ~/bin)"
            echo "  --remove      Remove symlinks instead of creating them"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run '$0 --help' for usage."
            exit 1
            ;;
    esac
done

# Collect all semsearch-*.sh scripts
SCRIPTS=("$SCRIPT_DIR"/semsearch-*.sh)
if [ ${#SCRIPTS[@]} -eq 0 ]; then
    die "No semsearch-*.sh scripts found in $SCRIPT_DIR"
fi

if [ "$REMOVE" = true ]; then
    # --- Remove mode ---
    info "Removing symlinks from $TARGET_DIR..."
    REMOVED=0
    for script in "${SCRIPTS[@]}"; do
        name="$(basename "$script" .sh)"
        link="$TARGET_DIR/$name"
        if [ -L "$link" ]; then
            link_target="$(readlink "$link")"
            if [ "$link_target" = "$script" ]; then
                rm "$link"
                echo "  Removed $link"
                ((REMOVED++)) || true
            else
                warn "$link points to $link_target, not our script — skipping"
            fi
        fi
    done
    if [ "$REMOVED" -eq 0 ]; then
        echo "  No symlinks to remove."
    else
        echo "  Removed $REMOVED symlink(s)."
    fi
else
    # --- Install mode ---
    mkdir -p "$TARGET_DIR"

    info "Creating symlinks in $TARGET_DIR..."
    CREATED=0
    for script in "${SCRIPTS[@]}"; do
        chmod +x "$script"
        name="$(basename "$script" .sh)"
        link="$TARGET_DIR/$name"
        if [ -L "$link" ]; then
            link_target="$(readlink "$link")"
            if [ "$link_target" = "$script" ]; then
                echo "  $name — already linked"
            else
                warn "$name — $link points to $link_target, not our script — skipping"
            fi
        elif [ -e "$link" ]; then
            warn "$name — $link exists and is not a symlink — skipping"
        else
            ln -s "$script" "$link"
            echo "  $name -> $script"
            ((CREATED++)) || true
        fi
    done

    if [ "$CREATED" -gt 0 ]; then
        echo "  Created $CREATED symlink(s)."
    else
        echo "  All symlinks already in place."
    fi

    # Check if target dir is in PATH
    if [[ ":$PATH:" != *":$TARGET_DIR:"* ]]; then
        echo ""
        warn "$TARGET_DIR is not in your PATH."
        SHELL_NAME="$(basename "$SHELL")"
        case "$SHELL_NAME" in
            zsh)  RC_FILE="~/.zshrc" ;;
            bash) RC_FILE="~/.bashrc" ;;
            *)    RC_FILE="your shell config" ;;
        esac
        echo "  Add this to $RC_FILE:"
        echo ""
        echo "    export PATH=\"$TARGET_DIR:\$PATH\""
        echo ""
    fi

    # Print available commands
    echo ""
    info "Available commands:"
    for script in "${SCRIPTS[@]}"; do
        name="$(basename "$script" .sh)"
        echo "  $name"
    done
fi
