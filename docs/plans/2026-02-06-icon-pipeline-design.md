# Icon Pipeline Design

Semi-automatic icon management for SketchyBar workspaces.

## Problem

- macOS app icons have squircle masks that render poorly at 16px
- Manually sourcing clean dark-mode icons from Google is tedious
- Need focused (full opacity) and unfocused (50% dim) variants
- Adding new apps requires updating multiple files

## Solution

A script that reads a YAML config, downloads icons, resizes to 16x16, generates dim variants, and auto-updates the SketchyBar icon mapping.

## File Structure

```
~/.config/sketchybar/
├── icons/
│   ├── icons.yaml           # Config: bundle ID → URL mapping
│   ├── update-icons.sh      # The automation script
│   └── 16px/
│       ├── spotify.png      # Focused (full opacity)
│       ├── ghostty.png
│       └── dim50/
│           ├── spotify.png  # Unfocused (50% opacity)
│           └── ghostty.png
```

## Config Format (icons.yaml)

```yaml
icons:
  com.spotify.client:
    name: spotify
    url: https://example.com/spotify-dark.png
  com.mitchellh.ghostty:
    name: ghostty
    url: https://raw.githubusercontent.com/mitchellh/ghostty/main/assets/icon.png
```

- `name`: Output filename (without .png)
- `url`: Direct link to clean dark-mode icon (PNG preferred)

## Dependencies

- `curl` — downloading icons (pre-installed)
- `imagemagick` — resize + opacity (`brew install imagemagick`)
- `yq` — YAML parsing (`brew install yq`)

## Processing Pipeline

```
1. Parse icons.yaml
2. For each entry:
   a. Download icon to temp file
   b. Validate it's a real image
   c. Resize to 16x16 (preserve transparency)
   d. Save to 16px/{name}.png
   e. Apply 50% opacity
   f. Save to 16px/dim50/{name}.png
3. Update app_icons.sh with new mappings
4. Report success/failures
```

### ImageMagick Commands

```bash
# Resize to 16x16 (fit within bounds, center, transparent background)
magick input.png -resize 16x16 -gravity center -extent 16x16 -background none output.png

# Generate 50% dim version
magick input.png -alpha set -channel A -evaluate multiply 0.5 +channel dim.png
```

## Auto-updating app_icons.sh

The script scans `plugins/app_icons.sh` and inserts missing bundle ID → name mappings into the `get_icon_name()` case statement.

```bash
# Before the catch-all *) line, insert:
com.linear) echo "linear.png" ;;
```

Safety:
- Only adds, never removes existing entries
- Preserves manual customisations
- Reports what was added

## Integration Changes

1. **app_icons.sh** — Update paths:
   ```bash
   CUSTOM_ICONS="$HOME/.config/sketchybar/icons/16px"
   CUSTOM_ICONS_DIM="$HOME/.config/sketchybar/icons/16px/dim50"
   ```

2. **aerospace_refresh.sh** — Adjust `ICON_SCALE` if needed for 16px

## Usage

```bash
# Find bundle ID
osascript -e 'id of app "Linear"'

# Add to icons.yaml
# (manually find a clean dark-mode icon URL)

# Run the script
~/.config/sketchybar/icons/update-icons.sh

# Reload SketchyBar
sketchybar --reload
```

## Error Handling

- Skip if URL returns non-200
- Skip if downloaded file isn't a valid image
- Continue processing remaining icons
- Report all failures at the end
