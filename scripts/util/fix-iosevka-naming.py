#!/usr/bin/env python3
"""
Fix Iosevka Extended font family naming.
Consolidates all weights under "Iosevka Extended" family with proper subfamily names.
"""

import sys
from pathlib import Path
from fontTools.ttLib import TTFont

# Weight mapping from filename to proper subfamily name
WEIGHT_MAP = {
    "Thin": ("Thin", 100),
    "ExtraLight": ("ExtraLight", 200),
    "Light": ("Light", 300),
    "Regular": ("Regular", 400),
    "Medium": ("Medium", 500),
    "SemiBold": ("SemiBold", 600),
    "Bold": ("Bold", 700),
    "ExtraBold": ("ExtraBold", 800),
    "Heavy": ("Heavy", 900),
}

STYLE_SUFFIXES = {
    "Italic": " Italic",
    "Oblique": " Oblique",
}


def parse_filename(filename: str) -> tuple[str, str, str]:
    """Parse Iosevka-ExtendedHeavyItalic.ttf -> (Extended, Heavy, Italic)"""
    name = filename.replace(".ttf", "").replace(".otf", "")

    # Handle both naming conventions:
    # Iosevka-ExtendedHeavy.ttf (FontBase style)
    # Iosevka-Heavy-Extended.ttf (other style)

    if name.startswith("Iosevka-Extended"):
        rest = name.replace("Iosevka-Extended", "")
    elif "-Extended" in name:
        rest = name.replace("Iosevka-", "").replace("-Extended", "")
    else:
        return None, None, None

    # Find weight and style
    weight = "Regular"
    style = ""

    for w in sorted(WEIGHT_MAP.keys(), key=len, reverse=True):
        if rest.startswith(w):
            weight = w
            rest = rest[len(w):]
            break

    for s in STYLE_SUFFIXES:
        if rest == s or rest == f"-{s}":
            style = s
            break

    return "Extended", weight, style


def fix_font_names(font_path: Path, output_dir: Path):
    """Fix the name table entries for proper family grouping."""
    filename = font_path.name
    width, weight, style = parse_filename(filename)

    if width is None:
        print(f"  Skipping {filename} - not an Extended variant")
        return

    font = TTFont(font_path)
    name_table = font["name"]

    family = "Iosevka Extended"
    subfamily_name, _ = WEIGHT_MAP.get(weight, ("Regular", 400))
    if style:
        subfamily = f"{subfamily_name}{STYLE_SUFFIXES[style]}"
    else:
        subfamily = subfamily_name

    full_name = f"{family} {subfamily}"
    ps_name = full_name.replace(" ", "-")

    # Update name records for all platforms
    for record in name_table.names:
        if record.nameID == 1:  # Family
            record.string = family
        elif record.nameID == 2:  # Subfamily
            record.string = subfamily
        elif record.nameID == 4:  # Full name
            record.string = full_name
        elif record.nameID == 6:  # PostScript name
            record.string = ps_name
        elif record.nameID == 16:  # Typo family
            record.string = family
        elif record.nameID == 17:  # Typo subfamily
            record.string = subfamily

    # Ensure nameID 16 and 17 exist (preferred family/subfamily)
    platforms = [(3, 1, 0x409), (1, 0, 0)]  # Windows, Mac
    for plat, enc, lang in platforms:
        existing_16 = name_table.getName(16, plat, enc, lang)
        if not existing_16:
            name_table.setName(family, 16, plat, enc, lang)
        existing_17 = name_table.getName(17, plat, enc, lang)
        if not existing_17:
            name_table.setName(subfamily, 17, plat, enc, lang)

    output_path = output_dir / filename
    font.save(output_path)
    print(f"  {filename} -> {subfamily}")


def main():
    if len(sys.argv) < 3:
        print("Usage: fix-iosevka-naming.py <input_dir> <output_dir>")
        sys.exit(1)

    input_dir = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    output_dir.mkdir(parents=True, exist_ok=True)

    fonts = list(input_dir.glob("Iosevka*Extended*.ttf")) + \
            list(input_dir.glob("Iosevka-Extended*.ttf"))

    if not fonts:
        print(f"No Extended fonts found in {input_dir}")
        sys.exit(1)

    print(f"Processing {len(fonts)} fonts...")
    for font_path in sorted(set(fonts)):
        fix_font_names(font_path, output_dir)

    print(f"\nDone! Fixed fonts saved to {output_dir}")
    print("To install: copy to ~/Library/Fonts/ and run 'fc-cache -f'")


if __name__ == "__main__":
    main()
