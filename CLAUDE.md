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
- **Scripts**: `scripts/` organised by function, symlinked flat to `~/.local/bin/`
  - `wm/` — window management (aerospace-*, hyper-e)
  - `services/` — background daemons (devup/devdown, spotify-sonos, ghostty-crash-logger)
  - `util/` — CLI tools (perflog, tools, fix-iosevka)
  - `security/` — docs only, not symlinked (.md files excluded)
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

## Security

```yaml
# Agent security hardening — enforced by hooks and sandbox, not instructions.
security:
  secrets:
    method: "1Password CLI (op)"
    rule: "Secrets are NEVER in env vars, .env files, or shell environment"
    access: "op read 'op://Vault/Item/field' or op run --env-file=.env.tpl"

  when_blocked:
    behaviour: "STOP and REPORT the block to the user"
    do_not: "Find workarounds, alternative paths, or creative bypasses"
    reason: "Security hooks exist for a reason — bypassing them is the threat model"

  protected_files:
    - "~/.claude/settings.json"
    - "~/.claude/settings.local.json"
    - "~/.claude/hooks/*.sh"
    - "~/.zshrc, ~/.zsh_aliases"

  network:
    rule: "Sandbox enforces egress whitelist — do not request non-whitelisted hosts"
```

## Removed

- **iStatMenus**: Not installed, orphaned configs cleaned up
