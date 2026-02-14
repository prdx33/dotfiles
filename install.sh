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
echo ""

# ────────────────────────────────────────────────────────────────────────────
# Git Configuration (XDG-compliant)
# ────────────────────────────────────────────────────────────────────────────
echo "Git configs:"
mkdir -p "$HOME/.config/git"
link_file "$DOTFILES_DIR/.config/git/config" "$HOME/.config/git/config"
link_file "$DOTFILES_DIR/.config/git/ignore" "$HOME/.config/git/ignore"
echo ""

# ────────────────────────────────────────────────────────────────────────────
# AeroSpace Configuration (XDG path)
# ────────────────────────────────────────────────────────────────────────────
echo "AeroSpace config:"
mkdir -p "$HOME/.config/aerospace"
link_file "$DOTFILES_DIR/.config/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
mkdir -p "$HOME/.config/aerospace/scripts"
for script in "$DOTFILES_DIR"/.config/aerospace/scripts/*; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        link_file "$script" "$HOME/.config/aerospace/scripts/$script_name"
    fi
done
echo ""

# ────────────────────────────────────────────────────────────────────────────
# Karabiner Configuration
# ────────────────────────────────────────────────────────────────────────────
echo "Karabiner config:"
mkdir -p "$HOME/.config/karabiner"
link_file "$DOTFILES_DIR/.config/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
echo ""

# ────────────────────────────────────────────────────────────────────────────
# SketchyBar Configuration
# ────────────────────────────────────────────────────────────────────────────
echo "SketchyBar config:"
link_file "$DOTFILES_DIR/.config/sketchybar" "$HOME/.config/sketchybar"
echo ""

# ────────────────────────────────────────────────────────────────────────────
# JankyBorders Configuration
# ────────────────────────────────────────────────────────────────────────────
echo "JankyBorders config:"
mkdir -p "$HOME/.config/borders"
link_file "$DOTFILES_DIR/.config/borders/bordersrc" "$HOME/.config/borders/bordersrc"
echo ""

# ────────────────────────────────────────────────────────────────────────────
# Starship Prompt Configuration
# ────────────────────────────────────────────────────────────────────────────
echo "Starship config:"
link_file "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
echo ""

# Remove old ~/.gitconfig if it exists and point to new location
if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
    echo "  📦 Backing up existing ~/.gitconfig"
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.gitconfig" "$BACKUP_DIR/"
    echo "  ℹ️  Git now uses ~/.config/git/config (XDG-compliant)"
fi
echo ""

# ────────────────────────────────────────────────────────────────────────────
# Hammerspoon Configuration
# ────────────────────────────────────────────────────────────────────────────
echo "Hammerspoon config:"
link_file "$DOTFILES_DIR/hammerspoon" "$HOME/.hammerspoon"
echo ""

# ────────────────────────────────────────────────────────────────────────────
# Scripts (~/.local/bin)
# ────────────────────────────────────────────────────────────────────────────
echo "Scripts:"
mkdir -p "$HOME/.local/bin"
for script in "$DOTFILES_DIR"/scripts/*/*; do
    if [ -f "$script" ] || [ -L "$script" ]; then
        script_name=$(basename "$script")
        case "$script_name" in
            *.md|*.txt|*.rst|*.csv|README*) continue ;;
        esac
        link_file "$script" "$HOME/.local/bin/$script_name"
    fi
done
echo ""

# ────────────────────────────────────────────────────────────────────────────
# Launch Agents (~/Library/LaunchAgents)
# ────────────────────────────────────────────────────────────────────────────
echo "Launch Agents:"
mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$HOME/.local/log"
for plist in "$DOTFILES_DIR"/launchagents/*.plist; do
    if [ -f "$plist" ]; then
        plist_name=$(basename "$plist")
        label="${plist_name%.plist}"

        # Unload if currently loaded
        launchctl list | grep -q "$label" && launchctl unload "$HOME/Library/LaunchAgents/$plist_name" 2>/dev/null || true

        link_file "$plist" "$HOME/Library/LaunchAgents/$plist_name"

        # Load the agent
        launchctl load "$HOME/Library/LaunchAgents/$plist_name"
        echo "    → Loaded $label"
    fi
done
echo ""

# ────────────────────────────────────────────────────────────────────────────
# macOS Defaults (apps without config files)
# ────────────────────────────────────────────────────────────────────────────
echo "macOS defaults:"

# Rectangle gaps (match AeroSpace gaps)
defaults write com.knollsoft.Rectangle gapSize -int 10
defaults write com.knollsoft.Rectangle screenEdgeGapBottom -int 10
defaults write com.knollsoft.Rectangle screenEdgeGapLeft -int 10
defaults write com.knollsoft.Rectangle screenEdgeGapRight -int 10
defaults write com.knollsoft.Rectangle screenEdgeGapTop -int 10
defaults write com.knollsoft.Rectangle unsnapRestore -int 2
echo "  ✓ Rectangle gaps: 10px (matching AeroSpace), restore-on-drag disabled"
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
