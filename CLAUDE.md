# Dotfiles

Matt's macOS configuration — single source of truth for all managed configs.

## Architecture

```yaml
# Symlink architecture: dotfiles repo owns all configs.
symlinks:
  source: "~/Dev/dotfiles/"
  targets:
    - "~/.config/*"
    - "~/.zshrc, ~/.zsh_aliases, ~/.zsh_plugins.txt"
    - "~/.hammerspoon/"
    - "~/.local/bin/*"
    - "~/Library/LaunchAgents/*.plist"

  rule: "NEVER edit files in ~/.config/ directly — always edit in ~/Dev/dotfiles/"
  reason: "Apps can replace symlinks with real files, causing silent divergence"
  recovery: "Re-run install.sh — it's idempotent (backs up real files, recreates symlinks)"
```

## What's Managed

- **Shell**: zshrc, aliases, plugins (antidote)
- **Window management**: AeroSpace (config + scripts), Rectangle (via defaults)
- **Status bar**: SketchyBar
- **Borders**: JankyBorders
- **Keyboard**: Karabiner-Elements
- **Prompt**: Starship
- **Git**: XDG-compliant config + global ignore
- **Automation**: Hammerspoon
- **Scripts**: `~/.local/bin/` utilities
- **LaunchAgents**: plist files auto-loaded on install
- **Packages**: Brewfile (not symlinked, used with `brew bundle`)

## install.sh

Idempotent installer. Safe to re-run at any time.

1. Backs up any real files to `~/.dotfiles-backup/<timestamp>/`
2. Removes existing symlinks
3. Creates fresh symlinks
4. Loads LaunchAgents
5. Sets macOS defaults (Rectangle gaps)

### Adding New Configs

Use the `link_file()` pattern:

```bash
link_file "$DOTFILES_DIR/path/to/config" "$HOME/.config/target/config"
```

## Removed

- **iStatMenus**: Not installed, orphaned configs cleaned up
