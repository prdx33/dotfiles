# Matt's Dotfiles

Personal dotfiles for macOS development environment.

## Structure

```
dotfiles/
├── .config/
│   └── git/
│       ├── config      # Git configuration (XDG-compliant)
│       └── ignore      # Global gitignore
├── shell/
│   ├── zshrc           # Main shell config
│   ├── zsh_aliases     # Custom aliases
│   ├── zsh_plugins.txt # Antidote plugin list
│   └── p10k.zsh        # Powerlevel10k theme
├── install.sh          # Symlink installer
└── README.md
```

## Installation

```bash
cd ~/Dev/dotfiles
chmod +x install.sh
./install.sh
```

The installer will:
1. Back up any existing files to `~/.dotfiles-backup/`
2. Create symlinks to this repo
3. Migrate git config to XDG-compliant location

## What's NOT Here

Files with secrets or machine-specific state are excluded:
- `~/.claude.json` - Claude Code preferences
- `~/.mcp.json` - MCP server configs (contains tokens)
- `~/.ssh/` - SSH keys

## Key Tools

- **Shell**: zsh + antidote + powerlevel10k
- **Navigation**: zoxide (smart cd)
- **Search**: fzf (fuzzy finder)
- **Node**: nvm
