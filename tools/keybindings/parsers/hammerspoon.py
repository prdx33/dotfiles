"""
Parse Hammerspoon cheatsheet.lua to extract display labels.

The cheatsheet.lua file contains structured data in Cheatsheet.sections
that serves as the source of truth for human-readable descriptions.
"""

import re
from pathlib import Path


def parse_hammerspoon(cheatsheet_path: Path) -> dict[str, list[dict]]:
    """
    Parse Hammerspoon cheatsheet.lua and extract display information.

    Returns:
        Dict mapping section names to lists of {key, desc} objects
    """
    with open(cheatsheet_path) as f:
        content = f.read()

    sections: dict[str, list[dict]] = {}

    # Find each section block
    # Pattern: { title = "SECTION NAME", items = { ... } }
    section_pattern = r'\{\s*title\s*=\s*["\']([^"\']+)["\']\s*,\s*items\s*=\s*\{([^}]+(?:\{[^}]*\}[^}]*)*)\}\s*\}'

    for match in re.finditer(section_pattern, content, re.DOTALL):
        title = match.group(1)
        items_block = match.group(2)

        items = []

        # Parse individual items: { "key", "description" }
        item_pattern = r'\{\s*["\']([^"\']+)["\']\s*,\s*["\']([^"\']+)["\']\s*\}'
        for item_match in re.finditer(item_pattern, items_block):
            key = item_match.group(1)
            desc = item_match.group(2)
            items.append({'key': key, 'desc': desc})

        # Normalise title to our layer naming
        layer = normalise_section_title(title)
        # Merge if layer already exists (e.g., multiple HYPER sections)
        if layer in sections:
            sections[layer].extend(items)
        else:
            sections[layer] = items

    return sections


def normalise_section_title(title: str) -> str:
    """Map cheatsheet section titles to our layer names."""
    title_lower = title.lower()

    # Check more specific patterns first
    if 'service' in title_lower:
        return 'service'
    if 'hammerspoon' in title_lower:
        return 'hammerspoon'
    if 'raycast' in title_lower:
        return 'raycast'
    if 'alt+shift' in title_lower or 'alt-shift' in title_lower or '⌥⇧' in title:
        return 'alt-shift'
    if 'alt' in title_lower or '⌥' in title:
        return 'alt'
    if 'hyper' in title_lower:
        return 'hyper'

    return title_lower.replace(' ', '-')


def get_description_for_key(sections: dict, layer: str, key: str) -> str | None:
    """
    Look up the human-readable description for a key in a layer.

    Useful for enriching bindings from other parsers.
    """
    items = sections.get(layer, [])

    # Normalise key for comparison
    key_lower = key.lower()

    for item in items:
        item_key = item['key'].lower()
        # Handle ranges like "Q-P" matching individual keys
        if '-' in item_key and len(item_key) == 3:
            start, end = item_key[0], item_key[2]
            if start <= key_lower <= end:
                return item['desc']
        elif item_key == key_lower:
            return item['desc']

    return None


if __name__ == '__main__':
    # Test parsing
    cheatsheet_path = Path.home() / 'Dev/dotfiles/hammerspoon/cheatsheet.lua'
    if cheatsheet_path.exists():
        sections = parse_hammerspoon(cheatsheet_path)
        for section, items in sections.items():
            print(f"\n=== {section.upper()} ===")
            for item in items:
                print(f"  {item['key']}: {item['desc']}")
