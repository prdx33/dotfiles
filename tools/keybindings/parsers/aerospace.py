"""
Parse AeroSpace TOML configuration to extract keybindings.

AeroSpace uses mode-based keybinding sections:
- [mode.main.binding] - default mode bindings
- [mode.service.binding] - service mode bindings

Key format: modifier-key (e.g., alt-q, alt-shift-q)
"""

import re
from pathlib import Path
from typing import Any

try:
    import tomllib
except ImportError:
    import tomli as tomllib  # Python < 3.11 fallback


def parse_aerospace(config_path: Path) -> dict[str, list[dict]]:
    """
    Parse AeroSpace TOML config and extract keybindings.

    Returns:
        Dict mapping layer names to lists of binding objects
    """
    with open(config_path, 'rb') as f:
        config = tomllib.load(f)

    bindings: dict[str, list[dict]] = {
        'alt': [],
        'alt-shift': [],
        'service': [],
    }

    # Parse main mode bindings
    main_bindings = config.get('mode', {}).get('main', {}).get('binding', {})
    for key_combo, command in main_bindings.items():
        layer, key = parse_key_combo(key_combo)
        if layer and layer in bindings:
            binding = create_binding(key, command)
            bindings[layer].append(binding)

    # Parse service mode bindings
    service_bindings = config.get('mode', {}).get('service', {}).get('binding', {})
    for key_combo, command in service_bindings.items():
        # Service mode uses plain keys (no modifier prefix)
        key = key_combo.lower()
        binding = create_binding(key, command, is_service=True)
        bindings['service'].append(binding)

    return bindings


def parse_key_combo(combo: str) -> tuple[str | None, str]:
    """
    Parse AeroSpace key combo format into (layer, key).

    Examples:
        alt-q -> ('alt', 'q')
        alt-shift-q -> ('alt-shift', 'q')
        cmd-q -> (None, 'q')  # Not a layer we track
    """
    parts = combo.lower().split('-')

    if len(parts) < 2:
        return (None, combo)

    # Check for alt-shift first (3 parts)
    if len(parts) >= 3 and 'alt' in parts and 'shift' in parts:
        # Find the key (last part that isn't a modifier)
        key = parts[-1]
        return ('alt-shift', key)

    # Check for plain alt (2 parts)
    if parts[0] == 'alt':
        return ('alt', parts[-1])

    return (None, parts[-1])


def create_binding(key: str, command: Any, is_service: bool = False) -> dict:
    """
    Create a binding object from key and command.

    Command can be:
    - String: single command
    - List: multiple commands to execute in sequence
    """
    # Normalise command to list
    if isinstance(command, str):
        commands = [command]
    else:
        commands = list(command)

    # Join for analysis
    cmd_str = ' && '.join(commands)

    display_action, action_type, desc = derive_display_info(key, commands, is_service)

    return {
        'key': normalise_key(key),
        'action': display_action,
        'type': action_type,
        'source': 'aerospace',
        'desc': desc,
        'raw_command': cmd_str,
        'commands': commands,
    }


def normalise_key(key: str) -> str:
    """Convert AeroSpace key names to our standard format."""
    mappings = {
        'semicolon': 'semicolon',
        'quote': 'quote',
        'backslash': 'backslash',
        'comma': 'comma',
        'period': 'period',
        'slash': 'slash',
        'space': 'space',
    }
    return mappings.get(key, key.lower())


def derive_display_info(key: str, commands: list[str], is_service: bool) -> tuple[str, str, str]:
    """
    Derive display label, type, and description from commands.

    Returns:
        (display_action, action_type, description)
    """
    cmd_str = ' '.join(commands).lower()

    # Service mode special handling
    if is_service:
        if key == 'esc':
            return ('Exit', 'mode', 'Exit service mode')
        if key == 'r' and 'reload-config' in cmd_str:
            return ('Reload', 'system', 'Reload AeroSpace config')
        if key == 'q' and 'close-all' in cmd_str:
            return ('Close', 'system', 'Close all windows but current')
        if key == 'd' and 'enable' in cmd_str:
            return ('Toggle', 'mode', 'Enable/disable AeroSpace')
        if key == 'f' and 'flatten' in cmd_str:
            return ('Flatten', 'mode', 'Flatten workspace tree')

    # Workspace operations
    if 'move-node-to-workspace' in cmd_str:
        ws_match = re.search(r'move-node-to-workspace\s+(\d+)', cmd_str)
        ws_num = ws_match.group(1) if ws_match else '?'

        # Check if we also follow (workspace X after move)
        if f'workspace {ws_num}' in cmd_str:
            return (f'Go {ws_num}', 'workspace', f'Send window + follow to workspace {ws_num}')
        return (f'Send {ws_num}', 'workspace', f'Send window to workspace {ws_num} (stay)')

    if 'move-workspace-to-monitor' in cmd_str:
        return ('Mon WS', 'position', 'Move workspace to next monitor')

    # Resize operations
    if 'resize' in cmd_str:
        # Look for the resize amounts
        size_match = re.search(r'([+-]\d+)', cmd_str)
        size = size_match.group(1) if size_match else '?'
        return (size, 'resize', f'Resize window {size}')

    # Layout operations
    if 'flatten-workspace-tree' in cmd_str:
        if 'balance-sizes' in cmd_str:
            return ('Reset', 'mode', 'Flatten + h-tiles + balance')
        return ('Flatten', 'mode', 'Flatten workspace tree')

    if 'layout floating tiling' in cmd_str:
        return ('Float', 'mode', 'Toggle window float/tile')

    if 'layout horizontal' in cmd_str or 'layout tiles' in cmd_str:
        return ('H-Tile', 'mode', 'Set horizontal tiles')

    if 'balance-sizes' in cmd_str:
        return ('Balance', 'mode', 'Balance window sizes')

    # Fallback
    short_cmd = commands[0][:15] if commands else '?'
    return (short_cmd, 'system', ' + '.join(commands))


if __name__ == '__main__':
    # Test parsing
    config_path = Path.home() / 'Dev/dotfiles/.config/aerospace/aerospace.toml'
    if config_path.exists():
        bindings = parse_aerospace(config_path)
        for layer, items in bindings.items():
            print(f"\n=== {layer.upper()} ===")
            for b in items:
                print(f"  {b['key']}: {b['action']} ({b['type']}) - {b['desc']}")
