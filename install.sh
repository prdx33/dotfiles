#!/bin/bash
# ============================================================================
# Dotfiles Installation Script
# Creates symlinks from home directory to this repo
# ============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

echo "🔗 Installing dotfiles from $DOTFILES_DIR"
echo ""

# Function to create symlink with backup
link_file() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "  📦 Backing up existing $dest"
        mkdir -p "$BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
    fi

    if [ -L "$dest" ]; then
        rm "$dest"
    fi

    echo "  ✓ Linking $dest → $src"
    ln -s "$src" "$dest"
}

# ────────────────────────────────────────────────────────────────────────────
# Shell Configuration
# ────────────────────────────────────────────────────────────────────────────
echo "Shell configs:"
link_file "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/shell/zsh_aliases" "$HOME/.zsh_aliases"
link_file "$DOTFILES_DIR/shell/zsh_plugins.txt" "$HOME/.zsh_plugins.txt"
link_file "$DOTFILES_DIR/shell/p10k.zsh" "$HOME/.p10k.zsh"
echo ""

# ────────────────────────────────────────────────────────────────────────────
# Git Configuration (XDG-compliant)
# ────────────────────────────────────────────────────────────────────────────
echo "Git configs:"
mkdir -p "$HOME/.config/git"
link_file "$DOTFILES_DIR/.config/git/config" "$HOME/.config/git/config"
link_file "$DOTFILES_DIR/.config/git/ignore" "$HOME/.config/git/ignore"

# Remove old ~/.gitconfig if it exists and point to new location
if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
    echo "  📦 Backing up existing ~/.gitconfig"
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.gitconfig" "$BACKUP_DIR/"
    echo "  ℹ️  Git now uses ~/.config/git/config (XDG-compliant)"
fi
echo ""

# ────────────────────────────────────────────────────────────────────────────
# Summary
# ────────────────────────────────────────────────────────────────────────────
echo "✅ Dotfiles installed successfully!"
echo ""

if [ -d "$BACKUP_DIR" ]; then
    echo "📦 Backups saved to: $BACKUP_DIR"
    echo ""
fi

echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Git will now use ~/.config/git/config"
echo ""
