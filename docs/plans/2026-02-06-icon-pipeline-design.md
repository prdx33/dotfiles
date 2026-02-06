# Icon Pipeline Design

Semi-automatic icon management for SketchyBar workspaces.

## Problem

- macOS app icons have squircle masks that render poorly at small sizes
- Manually sourcing clean dark-mode icons is tedious
- Need focused (full opacity) and unfocused (50% dim) variants
- Want consistent, recognisable icons across the bar

## Solution

LLM-assisted icon generation from reference images, plus a script for dim variants.

## Architecture

### Icon Sizing

| Source | Scale | Display |
|--------|-------|---------|
| 32px   | × 0.5 | 16pt    |

32px source provides retina-sharp rendering at 16pt display size.

### File Structure

```
~/.config/sketchybar/icons/
├── 32px/                           # Generated icons
│   ├── com.spotify.client.png
│   ├── com.mitchellh.ghostty.png
│   └── dim50/                      # Auto-generated dim variants
│       ├── com.spotify.client.png
│       └── com.mitchellh.ghostty.png
├── generate-dim.sh                 # Dim variant generator
└── tinyicon/                       # Legacy (24px, to be migrated)
```

### Naming Convention

Icons named by **bundle ID** — no mapping file needed.

```bash
# Get bundle ID for any app
osascript -e 'id of app "Spotify"'
# → com.spotify.client
```

## Icon Generation (LLM)

### Workflow

1. Screenshot the macOS app icon (or find source image)
2. Feed to vision-capable LLM with the prompt below
3. Save output as `32px/{bundle_id}.png`
4. Run `generate-dim.sh` to create dim variants

### Generation Prompt

```
Reference: [attached app icon]
App: {app_name}

Generate a 32×32 pixel icon:

- Extract ONLY the logomark/symbol — no background, no container, no squircle
- Faithful to original style: preserve gradients, colours, and shape if present
- Remove macOS mask, shadows, gloss, and any background
- Transparent background
- Sharp, pixel-aligned edges
- Must be instantly recognisable as {app_name} at 16pt on dark UI (#1e1e2e)

Output: Clean logomark, true to brand, readable at small size.
```

### Style Parameters

```yaml
icon_style:
  content: logomark_only
  background: transparent
  treatment: faithful         # gradients if source has them, flat if source is flat
  colours: original
  edges: sharp
  size: 32x32
  optimised_for: 16pt on #1e1e2e
```

## Dim Variant Generator

### Dependencies

- `imagemagick` (`brew install imagemagick`)

### Script: generate-dim.sh

```bash
#!/bin/bash
# Generate 50% opacity dim variants for all icons in 32px/

ICONS_DIR="$HOME/.config/sketchybar/icons/32px"
DIM_DIR="$ICONS_DIR/dim50"

mkdir -p "$DIM_DIR"

for icon in "$ICONS_DIR"/*.png; do
    [[ -f "$icon" ]] || continue
    name=$(basename "$icon")
    magick "$icon" -alpha set -channel A -evaluate multiply 0.5 +channel "$DIM_DIR/$name"
    echo "Generated: $DIM_DIR/$name"
done

echo "Done. $(ls -1 "$DIM_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ') dim variants."
```

## Integration Changes

### app_icons.sh

Replace case statement with filesystem lookup:

```bash
CUSTOM_ICONS="$HOME/.config/sketchybar/icons/32px"
CUSTOM_ICONS_DIM="$HOME/.config/sketchybar/icons/32px/dim50"

# Get icon path by bundle ID (returns empty if not found)
get_icon_path() {
    local bundle="$1"
    local icon="$CUSTOM_ICONS/${bundle}.png"
    [[ -f "$icon" ]] && echo "$icon" || echo ""
}

get_icon_path_dimmed() {
    local bundle="$1"
    local state="$2"
    local icon

    case "$state" in
        focused) icon="$CUSTOM_ICONS/${bundle}.png" ;;
        *)       icon="$CUSTOM_ICONS_DIM/${bundle}.png" ;;
    esac

    [[ -f "$icon" ]] && echo "$icon" || echo ""
}
```

### aerospace_refresh.sh / aerospace_change.sh

Update `ICON_SCALE` from `0.5` to match new 32px icons (already correct).

## Usage

```bash
# 1. Get bundle ID
osascript -e 'id of app "Linear"'
# → com.linear

# 2. Generate icon via LLM (using prompt above)
# Save to: ~/.config/sketchybar/icons/32px/com.linear.png

# 3. Generate dim variant
~/.config/sketchybar/icons/generate-dim.sh

# 4. Reload SketchyBar
sketchybar --reload
```

## Migration from tinyicon/

Existing 24px icons in `tinyicon/` can be:
1. Regenerated at 32px using the LLM workflow
2. Or resized: `magick input.png -resize 32x32 output.png` (may lose quality)

The `tinyicon/` directory remains as legacy until all icons are migrated.
