#!/usr/bin/env python3
"""
Keybinding Dashboard Generator

Parses configuration from:
- Karabiner-Elements (complex_modifications)
- AeroSpace (TOML bindings)
- Hammerspoon (cheatsheet.lua for display labels)

Outputs:
- templates/keybindings.json (data for HTML dashboard)
"""

import json
import sys
from pathlib import Path
from datetime import datetime

# Add parsers to path
sys.path.insert(0, str(Path(__file__).parent))

from parsers.karabiner import parse_karabiner
from parsers.aerospace import parse_aerospace
from parsers.hammerspoon import parse_hammerspoon, get_description_for_key
from parsers.rectangle import parse_rectangle


# Configuration paths
DOTFILES = Path.home() / 'Dev/dotfiles'
CONFIG_PATHS = {
    'karabiner': DOTFILES / '.config/karabiner/karabiner.json',
    'aerospace': DOTFILES / '.config/aerospace/aerospace.toml',
    'hammerspoon': DOTFILES / 'hammerspoon/cheatsheet.lua',
}

# Source file paths for VS Code links
SOURCE_FILES = {
    'karabiner': str(DOTFILES / '.config/karabiner/karabiner.json'),
    'aerospace': str(DOTFILES / '.config/aerospace/aerospace.toml'),
    'hammerspoon': str(DOTFILES / 'hammerspoon/'),
    'rectangle': None,  # GUI-configured, but can trigger via URL scheme
    'raycast': None,  # GUI-configured
}

# Layer metadata
LAYER_META = {
    'hyper': {
        'name': 'Hyper',
        'activatorKeys': ['caps'],
        'layerClass': '',
        'description': 'Caps Lock (hold) = ⌘⌃⌥⇧',
    },
    'alt': {
        'name': 'Alt',
        'activatorKeys': ['alt'],
        'layerClass': 'alt-layer',
        'description': 'Option key bindings',
    },
    'alt-shift': {
        'name': 'Alt+Shift',
        'activatorKeys': ['alt', 'shift'],
        'layerClass': 'alt-layer',
        'description': 'Option + Shift bindings',
    },
    'service': {
        'name': 'Service',
        'activatorKeys': ['caps', 'semicolon'],
        'layerClass': 'service-layer',
        'description': 'Hyper+; to enter',
    },
}


def derive_icon(action_type: str, action: str) -> dict:
    """Derive icon type and data from action type."""
    icons = {
        'workspace': ('ws', extract_ws_number(action)),
        'position': ('pos', 'center'),
        'focus': ('focus', derive_focus_direction(action)),
        'mode': ('mode', None),
        'resize': ('resize', 'grow' if '+' in action else 'shrink'),
        'system': ('sys', None),
    }
    icon, data = icons.get(action_type, ('sys', None))
    return {'icon': icon, 'iconData': data}


def extract_ws_number(action: str) -> str:
    """Extract workspace number from action string."""
    import re
    match = re.search(r'(\d+)', action)
    return match.group(1) if match else ''


def derive_focus_direction(action: str) -> str:
    """Derive focus direction arrow from action."""
    action_lower = action.lower()
    if 'l' in action_lower or 'left' in action_lower or 'prev' in action_lower:
        return '◂'
    if 'r' in action_lower or 'right' in action_lower or 'next' in action_lower:
        return '▸'
    if 'u' in action_lower or 'up' in action_lower:
        return '▴'
    if 'd' in action_lower or 'down' in action_lower:
        return '▾'
    return '▸'


def merge_bindings(
    karabiner: dict[str, list],
    aerospace: dict[str, list],
    hammerspoon_sections: dict,
    rectangle: dict[str, list] = None,
) -> dict[str, dict]:
    """
    Merge bindings from all sources into unified layer structure.

    Priority: Karabiner > AeroSpace (since Karabiner triggers AeroSpace commands)
    Enrichment: Use Hammerspoon descriptions where available
    """
    layers = {}

    for layer_id, meta in LAYER_META.items():
        bindings = {}

        # Start with Karabiner bindings (primary for hyper)
        for b in karabiner.get(layer_id, []):
            key = b['key']
            # Try to get better description from Hammerspoon
            hs_desc = get_description_for_key(hammerspoon_sections, layer_id, key)

            binding = {
                'action': b['action'],
                'type': b['type'],
                'source': b['source'],
                'desc': hs_desc or b['desc'],
                'raw_command': b.get('raw_command'),
                'condition': b.get('condition'),
                **derive_icon(b['type'], b['action']),
            }

            # Handle conditional bindings (tiling vs floating mode)
            if b.get('condition'):
                # Store as variant, don't overwrite
                existing = bindings.get(key, {})
                if 'variants' not in existing:
                    existing['variants'] = []
                existing['variants'].append({
                    'condition': b['condition'],
                    **binding,
                })
                if 'action' not in existing:
                    # Use first variant as default display
                    existing.update(binding)
                bindings[key] = existing
            else:
                bindings[key] = binding

        # Add AeroSpace bindings (for alt and service layers)
        for b in aerospace.get(layer_id, []):
            key = b['key']
            if key not in bindings:  # Don't overwrite Karabiner
                hs_desc = get_description_for_key(hammerspoon_sections, layer_id, key)

                bindings[key] = {
                    'action': b['action'],
                    'type': b['type'],
                    'source': b['source'],
                    'desc': hs_desc or b['desc'],
                    'raw_command': b.get('raw_command'),
                    **derive_icon(b['type'], b['action']),
                }

        # Add Rectangle Pro bindings (lowest priority - only if not already defined)
        if rectangle:
            for b in rectangle.get(layer_id, []):
                key = b['key']
                if key not in bindings:
                    bindings[key] = {
                        'action': b['action'],
                        'type': b['type'],
                        'source': b['source'],
                        'desc': b['desc'],
                        'raw_command': b.get('raw_command'),
                        **derive_icon(b['type'], b['action']),
                    }

        layers[layer_id] = {
            **meta,
            'bindings': bindings,
        }

    return layers


def generate_output(layers: dict) -> dict:
    """Generate the final output structure."""
    return {
        'generated': datetime.now().isoformat(),
        'sourceFiles': SOURCE_FILES,
        'layers': layers,
    }


def main():
    """Main entry point."""
    print("Parsing Karabiner...")
    karabiner = parse_karabiner(CONFIG_PATHS['karabiner'])

    print("Parsing AeroSpace...")
    aerospace = parse_aerospace(CONFIG_PATHS['aerospace'])

    print("Parsing Hammerspoon cheatsheet...")
    hammerspoon = parse_hammerspoon(CONFIG_PATHS['hammerspoon'])

    print("Parsing Rectangle Pro...")
    rectangle = parse_rectangle()

    print("Merging bindings...")
    layers = merge_bindings(karabiner, aerospace, hammerspoon, rectangle)

    output = generate_output(layers)

    # Write to templates/keybindings.json
    output_path = Path(__file__).parent / 'templates' / 'keybindings.json'
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'w') as f:
        json.dump(output, f, indent=2)

    print(f"Generated: {output_path}")

    # Also write as JS module for direct browser loading (avoids CORS issues)
    js_path = Path(__file__).parent / 'dashboard' / 'keybindings-data.js'
    with open(js_path, 'w') as f:
        f.write(f"// Auto-generated by generate.py - do not edit\n")
        f.write(f"window.KEYBINDINGS_DATA = {json.dumps(output, indent=2)};\n")

    print(f"Generated: {js_path}")

    # Print summary
    for layer_id, layer in layers.items():
        binding_count = len(layer['bindings'])
        print(f"  {layer['name']}: {binding_count} bindings")

    return output


if __name__ == '__main__':
    main()
