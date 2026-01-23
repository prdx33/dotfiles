# Icon Set Generation Prompt

## Reference Images

See the `reference/` folder — 89 original app icons extracted at 128x128. Use these as the source to work from.

Reference sheet: `reference/_reference_sheet.png`

---

## The Brief

Recreate each icon with these modifications:

1. **Remove the macOS squircle background** — extract just the logo/symbol
2. **Transparent background** — no shape behind the icon, just the raw mark
3. **Simplify for small size** — these will display at 16–32px, so remove fine details that won't read
4. **Consistent style** — all icons should feel like part of the same family

---

## Style Treatment

- **Geometry**: Clean, slightly simplified shapes — keep recognisability, lose fussy details
- **Colours**: Keep original brand colours but normalise saturation (70–85%) and brightness (80–95%) so they harmonise
- **Edges**: Crisp, anti-aliased — no fuzzy borders
- **Subtle glow**: Optional 10% opacity outer glow in the icon's primary colour, helps pop on dark backgrounds
- **No backgrounds**: Transparent PNG, just the floating symbol

---

## When the Logo Won't Work Small

If an icon is too complex or has a container (like Ghostty's terminal-with-ghost):
- Extract the **most recognisable element** (the ghost, not the terminal frame)
- Keep that element **accurate to the original** design
- Search the official logo/branding for reference if needed

---

## Output

- **Size**: 128x128 PNG (will be scaled to 16–32px)
- **Format**: PNG with transparency
- **Naming**: lowercase with underscores, matching the reference files

---

## Example Transformations

| App | Original | Simplified |
|-----|----------|------------|
| Spotify | Green squircle with black waves | Green circle with black waves, no squircle |
| Firefox | Fox/flame around globe in squircle | Just the fox/flame and globe, floating |
| Obsidian | Purple gem in squircle | Just the purple gem |
| Ghostty | Terminal screen with ghost | Just the ghost character |
| Slack | Four-dot hashtag in squircle | Just the four coloured dots/pills |

---

## Context

These icons will be used in a macOS menu bar (sketchybar) at 16pt on a dark (#1a1a1a) background. They need to be instantly recognisable at small size while looking cohesive as a set.
