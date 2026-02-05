"""
Parse Karabiner-Elements complex_modifications to extract keybindings.

Karabiner uses modifier combinations to create virtual layers:
- command + control + option + shift = Hyper (triggered by Caps Lock hold)
- option = Alt layer
- option + shift = Alt+Shift layer
"""

import json
import re
from pathlib import Path
from typing import Any

# Modifier sets that map to our layers
MODIFIER_LAYERS = {
    frozenset(['command', 'control', 'option', 'shift']): 'hyper',
    frozenset(['option']): 'alt',
    frozenset(['option', 'shift']): 'alt-shift',
}

# Variable conditions that map to layers (for variable-based Hyper)
VARIABLE_LAYERS = {
    ('hyper', 1): 'hyper',
}


def parse_karabiner(config_path: Path) -> dict[str, list[dict]]:
    """
    Parse Karabiner config and extract keybindings organised by layer.

    Returns:
        Dict mapping layer names to lists of binding objects
    """
    with open(config_path) as f:
        config = json.load(f)

    bindings: dict[str, list[dict]] = {
        'hyper': [],
        'alt': [],
        'alt-shift': [],
    }

    # Navigate to complex_modifications rules
    try:
        rules = config['profiles'][0]['complex_modifications']['rules']
    except (KeyError, IndexError):
        return bindings

    for rule in rules:
        description = rule.get('description', '')
        manipulators = rule.get('manipulators', [])

        for manip in manipulators:
            if manip.get('type') != 'basic':
                continue

            from_key = manip.get('from', {})
            key_code = from_key.get('key_code')
            modifiers = from_key.get('modifiers', {}).get('mandatory', [])

            if not key_code:
                continue

            # Determine which layer this belongs to
            layer = None

            # Check for modifier-based layers (old style)
            mod_set = frozenset(modifiers)
            layer = MODIFIER_LAYERS.get(mod_set)

            # Check for variable-based layers (new style with hyper variable)
            if not layer:
                conditions = manip.get('conditions', [])
                for cond in conditions:
                    if cond.get('type') == 'variable_if':
                        var_key = (cond.get('name'), cond.get('value'))
                        if var_key in VARIABLE_LAYERS:
                            layer = VARIABLE_LAYERS[var_key]
                            break

            if not layer:
                continue

            # Extract the action (shell_command or key mapping)
            to_list = manip.get('to', [])
            action = None
            action_detail = None

            for to_item in to_list:
                if 'shell_command' in to_item:
                    action = 'shell'
                    action_detail = to_item['shell_command']
                    break
                elif 'key_code' in to_item:
                    action = 'key'
                    action_detail = to_item['key_code']
                    break

            if not action:
                continue

            # Check for conditions (context-aware bindings)
            conditions = manip.get('conditions', [])
            condition_info = None
            for cond in conditions:
                if cond.get('type') == 'variable_if':
                    condition_info = f"{cond.get('name')}={cond.get('value')}"
                elif cond.get('type') == 'variable_unless':
                    condition_info = f"!{cond.get('name')}={cond.get('value')}"

            # Derive display info from the action
            display_action, action_type, desc = derive_display_info(
                key_code, action_detail, description, condition_info
            )

            binding = {
                'key': normalise_key_code(key_code),
                'action': display_action,
                'type': action_type,
                'source': 'karabiner',
                'desc': desc,
                'raw_command': action_detail if action == 'shell' else None,
                'condition': condition_info,
                'rule_description': description,
            }

            bindings[layer].append(binding)

    return bindings


def normalise_key_code(key_code: str) -> str:
    """Convert Karabiner key codes to our standard format."""
    mappings = {
        'semicolon': 'semicolon',
        'quote': 'quote',
        'backslash': 'backslash',
        'comma': 'comma',
        'period': 'period',
        'slash': 'slash',
    }
    return mappings.get(key_code, key_code.lower())


def derive_display_info(key: str, command: str, rule_desc: str, condition: str | None) -> tuple[str, str, str]:
    """
    Derive display label, type, and description from the raw command.

    Returns:
        (display_action, action_type, description)
    """
    if not command:
        return ('?', 'system', rule_desc)

    cmd_lower = command.lower()

    # Workspace operations
    if 'summon-workspace' in cmd_lower:
        ws_match = re.search(r'summon-workspace\s+(\d+)', command)
        ws_num = ws_match.group(1) if ws_match else '?'
        return (f'WS {ws_num}', 'workspace', f'Summon workspace {ws_num} to current monitor')

    if 'move-node-to-workspace' in cmd_lower:
        ws_match = re.search(r'move-node-to-workspace\s+(\d+)', command)
        ws_num = ws_match.group(1) if ws_match else '?'
        return (f'Send {ws_num}', 'workspace', f'Send window to workspace {ws_num}')

    if 'workspace' in cmd_lower and 'move-node' not in cmd_lower:
        ws_match = re.search(r'workspace\s+(\d+)', command)
        if ws_match:
            ws_num = ws_match.group(1)
            return (f'Go {ws_num}', 'workspace', f'Switch to workspace {ws_num}')

    # Focus operations
    if 'focus' in cmd_lower:
        if 'left' in cmd_lower:
            return ('Foc L', 'focus', 'Focus window to left')
        elif 'right' in cmd_lower:
            return ('Foc R', 'focus', 'Focus window to right')
        elif 'up' in cmd_lower:
            return ('Foc U', 'focus', 'Focus window above')
        elif 'down' in cmd_lower:
            return ('Foc D', 'focus', 'Focus window below')
        elif 'monitor' in cmd_lower:
            return ('Mon', 'focus', 'Focus next monitor')
        elif 'dfs-prev' in cmd_lower:
            return ('Prev', 'focus', 'Focus previous window')
        elif 'dfs-next' in cmd_lower:
            return ('Next', 'focus', 'Focus next window')

    # Move operations
    if 'move-node-to-monitor' in cmd_lower:
        return ('Mon+Win', 'position', 'Move window to next monitor + follow')

    if 'move ' in cmd_lower:
        if 'left' in cmd_lower:
            return ('Mov L', 'position', 'Move window left')
        elif 'right' in cmd_lower:
            return ('Mov R', 'position', 'Move window right')
        elif 'up' in cmd_lower:
            return ('Mov U', 'position', 'Move window up')
        elif 'down' in cmd_lower:
            return ('Mov D', 'position', 'Move window down')

    # Resize operations
    if 'resize' in cmd_lower:
        size_match = re.search(r'([+-]\d+)', command)
        size = size_match.group(1) if size_match else '?'
        return (size, 'resize', f'Resize window {size}')

    # Layout operations
    if 'layout' in cmd_lower:
        if 'floating' in cmd_lower and 'tiling' in cmd_lower:
            return ('Float', 'mode', 'Toggle window float/tile')
        elif 'horizontal' in cmd_lower and 'vertical' in cmd_lower:
            return ('H/V', 'mode', 'Toggle horizontal/vertical tiles')
        elif 'accordion' in cmd_lower:
            return ('Acc', 'mode', 'Toggle accordion mode')

    # Mode operations
    if 'mode service' in cmd_lower:
        return ('Svc', 'mode', 'Enter service mode')

    # Flatten/balance
    if 'flatten' in cmd_lower:
        if 'balance' in cmd_lower:
            return ('Reset', 'mode', 'Flatten + balance layout')
        return ('Flat', 'mode', 'Flatten workspace tree')

    # SketchyBar
    if 'sketchybar' in cmd_lower and 'BarToggle' in command:
        return ('Bar', 'system', 'Toggle SketchyBar')

    # Rectangle (float positioning)
    if 'rectangle://' in cmd_lower:
        if 'maximize' in cmd_lower:
            return ('Max', 'position', 'Maximize window')
        return ('Rect', 'position', 'Rectangle positioning')

    # Pop-out script
    if 'pop-out' in cmd_lower:
        return ('Pop', 'mode', 'Pop window out of tile')

    # Aerospace focus wrap scripts
    if 'aerospace-focus-wrap-prev' in cmd_lower:
        return ('Prev', 'focus', 'Focus previous window (wrap)')
    if 'aerospace-focus-wrap-next' in cmd_lower:
        return ('Next', 'focus', 'Focus next window (wrap)')

    # Rectangle Pro actions
    if 'rectangle-pro://' in cmd_lower or 'rectangle://' in cmd_lower:
        if 'left-half' in cmd_lower:
            return ('Left', 'position', 'Left half of screen')
        if 'right-half' in cmd_lower:
            return ('Right', 'position', 'Right half of screen')
        if 'first-third' in cmd_lower:
            return ('1/3', 'position', 'First third of screen')
        if 'last-third' in cmd_lower:
            return ('3/3', 'position', 'Last third of screen')
        if 'center-third' in cmd_lower:
            return ('C 1/3', 'position', 'Center third of screen')
        if 'cascade-all' in cmd_lower:
            return ('Cascade', 'position', 'Cascade all windows')
        if 'almost-maximize' in cmd_lower:
            return ('~Max', 'position', 'Almost maximize')
        if 'maximize' in cmd_lower:
            return ('Max', 'position', 'Maximize window')
        return ('Rect', 'position', 'Rectangle positioning')

    # BarToggle
    if 'bartoggle' in cmd_lower:
        return ('Bar', 'system', 'Toggle SketchyBar')

    # Cycle scripts
    if 'cycle-left' in cmd_lower:
        return ('◂Cyc', 'position', 'Cycle left positions')
    elif 'cycle-right' in cmd_lower:
        return ('Cyc▸', 'position', 'Cycle right positions')
    elif 'cycle-center' in cmd_lower:
        return ('⬚Cyc', 'position', 'Cycle center positions')

    # Toggle tiling
    if 'toggle-workspace-float' in cmd_lower:
        return ('Mode', 'mode', 'Toggle workspace tiling mode')

    # Fallback: use rule description
    short_desc = rule_desc[:10] if rule_desc else '?'
    return (short_desc, 'system', rule_desc)


if __name__ == '__main__':
    # Test parsing
    config_path = Path.home() / 'Dev/dotfiles/.config/karabiner/karabiner.json'
    if config_path.exists():
        bindings = parse_karabiner(config_path)
        for layer, items in bindings.items():
            print(f"\n=== {layer.upper()} ===")
            for b in items:
                print(f"  {b['key']}: {b['action']} ({b['type']}) - {b['desc']}")
