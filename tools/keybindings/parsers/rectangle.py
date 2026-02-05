"""
Parse Rectangle Pro preferences to extract keybindings.

Rectangle Pro stores bindings in ~/Library/Preferences/com.knollsoft.Rectangle-Pro.plist
Each action has a keyCode and modifierFlags field.
"""

import subprocess
import json
from pathlib import Path

# macOS modifier flags
MODIFIER_FLAGS = {
    131072: 'shift',      # 0x20000
    262144: 'control',    # 0x40000
    524288: 'option',     # 0x80000
    1048576: 'command',   # 0x100000
}

# KeyCode to key name mapping (common keys)
KEY_CODES = {
    0: 'a', 1: 's', 2: 'd', 3: 'f', 4: 'h', 5: 'g', 6: 'z', 7: 'x', 8: 'c', 9: 'v',
    11: 'b', 12: 'q', 13: 'w', 14: 'e', 15: 'r', 16: 'y', 17: 't', 18: '1', 19: '2',
    20: '3', 21: '4', 22: '6', 23: '5', 24: '=', 25: '9', 26: '7', 27: '-', 28: '8',
    29: '0', 31: 'o', 32: 'u', 34: 'i', 35: 'p', 37: 'l', 38: 'j', 40: 'k', 41: ';',
    43: ',', 45: 'n', 46: 'm', 47: '.', 50: '`',
    123: 'left', 124: 'right', 125: 'down', 126: 'up',
}

# Rectangle action names to display labels
ACTION_LABELS = {
    'leftHalf': ('Left', 'Left half of screen'),
    'rightHalf': ('Right', 'Right half of screen'),
    'topHalf': ('Top', 'Top half of screen'),
    'bottomHalf': ('Bottom', 'Bottom half of screen'),
    'topLeft': ('TL', 'Top left corner'),
    'topRight': ('TR', 'Top right corner'),
    'bottomLeft': ('BL', 'Bottom left corner'),
    'bottomRight': ('BR', 'Bottom right corner'),
    'maximize': ('Max', 'Maximize window'),
    'almostMaximize': ('~Max', 'Almost maximize'),
    'center': ('Center', 'Center window'),
    'centerHalf': ('C 1/2', 'Center half'),
    'centerThird': ('C 1/3', 'Center third'),
    'firstThird': ('1/3', 'First third'),
    'lastThird': ('3/3', 'Last third'),
    'firstTwoThirds': ('2/3 L', 'First two thirds'),
    'lastTwoThirds': ('2/3 R', 'Last two thirds'),
    'restore': ('Restore', 'Restore previous size'),
    'smaller': ('Shrink', 'Make smaller'),
    'larger': ('Grow', 'Make larger'),
    'nextDisplay': ('Next Mon', 'Move to next display'),
    'previousDisplay': ('Prev Mon', 'Move to previous display'),
    'cascadeAll': ('Cascade', 'Cascade all windows'),
    'cascadeApp': ('Cascade App', 'Cascade app windows'),
}


def decode_modifiers(flags: int) -> list[str]:
    """Decode modifier flags into list of modifier names."""
    mods = []
    for flag, name in MODIFIER_FLAGS.items():
        if flags & flag:
            mods.append(name)
    return mods


def is_hyper(mods: list[str]) -> bool:
    """Check if modifiers represent Hyper (all 4 modifiers)."""
    return set(mods) == {'command', 'control', 'option', 'shift'}


def parse_rectangle(plist_path: Path = None) -> dict[str, list[dict]]:
    """
    Parse Rectangle Pro preferences and extract keybindings.

    Returns:
        Dict mapping layer names to lists of binding objects
    """
    if plist_path is None:
        plist_path = Path.home() / 'Library/Preferences/com.knollsoft.Rectangle-Pro.plist'

    bindings = {
        'hyper': [],
        'alt': [],
        'alt-shift': [],
        'rectangle': [],  # Non-hyper Rectangle bindings
    }

    if not plist_path.exists():
        return bindings

    # Read plist using defaults command
    try:
        result = subprocess.run(
            ['defaults', 'read', 'com.knollsoft.Rectangle-Pro'],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode != 0:
            return bindings
    except Exception:
        return bindings

    # Parse the output (it's in plist text format, not JSON)
    # For simplicity, we'll use defaults export to get JSON-ish format
    try:
        result = subprocess.run(
            ['defaults', 'export', 'com.knollsoft.Rectangle-Pro', '-'],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode != 0:
            return bindings

        import plistlib
        prefs = plistlib.loads(result.stdout.encode())
    except Exception as e:
        print(f"Error parsing Rectangle Pro prefs: {e}")
        return bindings

    # Iterate through known action names
    for action_name, (label, desc) in ACTION_LABELS.items():
        action_data = prefs.get(action_name, {})

        if not isinstance(action_data, dict):
            continue

        key_code = action_data.get('keyCode')
        mod_flags = action_data.get('modifierFlags', 0)

        if key_code is None:
            continue

        key = KEY_CODES.get(key_code, f'key{key_code}')
        mods = decode_modifiers(mod_flags)

        binding = {
            'key': key,
            'action': label,
            'type': 'position',
            'source': 'rectangle',
            'desc': desc,
            'raw_command': f'rectangle-pro://execute-action?name={action_name}',
            'modifiers': mods,
        }

        # Categorize by modifier layer
        if is_hyper(mods):
            bindings['hyper'].append(binding)
        elif set(mods) == {'option', 'shift'}:
            bindings['alt-shift'].append(binding)
        elif set(mods) == {'option'}:
            bindings['alt'].append(binding)
        else:
            bindings['rectangle'].append(binding)

    return bindings


if __name__ == '__main__':
    # Test parsing
    bindings = parse_rectangle()
    for layer, items in bindings.items():
        if items:
            print(f"\n=== {layer.upper()} ===")
            for b in items:
                print(f"  {b['key']}: {b['action']} - {b['desc']} ({b['modifiers']})")
