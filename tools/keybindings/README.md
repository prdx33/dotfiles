# Keybindings Dashboard

Visual keyboard dashboard for window management keybindings with auto-generation from config files.

## Quick Start

```bash
# Generate keybindings data from configs
python3 generate.py

# Open dashboard in browser
open dashboard/window-management-keymap.html
```

## Structure

```
keybindings/
├── generate.py          # Main generator script
├── parsers/             # Config file parsers
│   ├── karabiner.py     # Karabiner complex_modifications
│   ├── aerospace.py     # AeroSpace TOML bindings
│   └── hammerspoon.py   # Cheatsheet display labels
├── templates/
│   └── keybindings.json # Generated data
└── dashboard/
    ├── window-management-keymap.html  # Main dashboard
    └── corne-keymap-viewer.html       # Corne keyboard reference
```

## Dashboard Features

- **Layer tabs**: Hyper / Alt / Alt+Shift / Service
- **Edit mode**: Draft binding changes (E key)
- **Export**: Generate Claude prompts for config changes
- **VS Code links**: Open source configs from tooltips

## Config Sources

| Source | File | Layer |
|--------|------|-------|
| Karabiner | `.config/karabiner/karabiner.json` | Hyper (⌘⌃⌥⇧) |
| AeroSpace | `.config/aerospace/aerospace.toml` | Alt, Alt+Shift, Service |
| Hammerspoon | `hammerspoon/cheatsheet.lua` | Display labels |
