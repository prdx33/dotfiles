#!/usr/bin/env python3
"""
Hand-crafted 32x32 app icons - raw logo shapes, no squircle
Designed for 16pt retina display in sketchybar
"""

from PIL import Image, ImageDraw
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__)) + "/crafted"
os.makedirs(OUTPUT_DIR, exist_ok=True)

SIZE = 32

def create_image():
    return Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))

def spotify():
    """Green circle with black sound wave curves"""
    img = create_image()
    draw = ImageDraw.Draw(img)

    # Green circle - Spotify green
    green = (30, 215, 96)
    draw.ellipse([2, 2, 29, 29], fill=green)

    # Black curves (simplified as arcs)
    black = (0, 0, 0)
    # Three curved lines
    draw.arc([7, 8, 25, 18], start=200, end=340, fill=black, width=2)
    draw.arc([8, 12, 24, 20], start=200, end=340, fill=black, width=2)
    draw.arc([9, 16, 23, 23], start=200, end=340, fill=black, width=2)

    return img

def firefox():
    """Orange/red flame fox shape wrapping blue globe"""
    img = create_image()
    draw = ImageDraw.Draw(img)

    # Blue globe base
    blue = (65, 90, 190)
    draw.ellipse([6, 6, 26, 26], fill=blue)

    # Orange flame/fox wrapping around
    orange = (255, 80, 30)
    orange_light = (255, 150, 50)

    # Main flame body - sweeping around
    draw.pieslice([2, 2, 30, 30], start=45, end=300, fill=orange)

    # Cut out center to show globe
    draw.ellipse([8, 8, 24, 24], fill=blue)

    # Fox head/ear at top
    draw.ellipse([4, 3, 14, 13], fill=orange)

    # Lighter inner flame
    draw.pieslice([4, 4, 28, 28], start=60, end=200, fill=orange_light)
    draw.ellipse([9, 9, 23, 23], fill=blue)

    return img

def ghostty():
    """Simple ghost silhouette - Ghostty style"""
    img = create_image()
    draw = ImageDraw.Draw(img)

    # Ghost color - light gray/white
    ghost = (220, 220, 230)
    dark = (80, 80, 90)

    # Ghost body - rounded top, wavy bottom
    # Head
    draw.ellipse([6, 3, 26, 20], fill=ghost)

    # Body
    draw.rectangle([6, 12, 26, 26], fill=ghost)

    # Wavy bottom - cut out triangles
    transparent = (0, 0, 0, 0)
    draw.polygon([(6, 26), (10, 20), (14, 26)], fill=transparent)
    draw.polygon([(14, 26), (18, 20), (22, 26)], fill=transparent)
    draw.polygon([(22, 26), (26, 20), (26, 26)], fill=transparent)

    # Redraw the waves as ghost color bumps
    draw.ellipse([6, 22, 14, 30], fill=ghost)
    draw.ellipse([12, 22, 20, 30], fill=ghost)
    draw.ellipse([18, 22, 26, 30], fill=ghost)

    # Cut bottom
    draw.rectangle([0, 28, 32, 32], fill=transparent)

    # Eyes
    draw.ellipse([10, 10, 14, 15], fill=dark)
    draw.ellipse([18, 10, 22, 15], fill=dark)

    return img

def obsidian():
    """Purple crystal/gem shape"""
    img = create_image()
    draw = ImageDraw.Draw(img)

    # Obsidian purple
    purple_dark = (88, 55, 160)
    purple_mid = (124, 77, 255)
    purple_light = (160, 120, 255)

    # Diamond/crystal shape
    # Top facet
    draw.polygon([(16, 2), (6, 12), (26, 12)], fill=purple_light)

    # Left facet
    draw.polygon([(6, 12), (16, 30), (16, 12)], fill=purple_dark)

    # Right facet
    draw.polygon([(26, 12), (16, 30), (16, 12)], fill=purple_mid)

    return img

def messages():
    """Green chat bubble"""
    img = create_image()
    draw = ImageDraw.Draw(img)

    # Apple Messages green
    green = (50, 205, 80)

    # Main bubble - rounded rectangle
    draw.rounded_rectangle([3, 4, 29, 22], radius=8, fill=green)

    # Tail/pointer at bottom left
    draw.polygon([(6, 20), (4, 28), (14, 20)], fill=green)

    return img

def vscode():
    """Blue folded ribbon/bracket shape"""
    img = create_image()
    draw = ImageDraw.Draw(img)

    # VS Code blue
    blue = (0, 122, 204)
    blue_light = (50, 160, 230)

    # Left ribbon fold
    draw.polygon([(4, 8), (4, 24), (16, 30), (16, 16)], fill=blue)

    # Right ribbon fold
    draw.polygon([(16, 2), (28, 8), (28, 24), (16, 18)], fill=blue_light)

    # Top connector
    draw.polygon([(4, 8), (16, 2), (16, 16)], fill=blue_light)

    return img

def slack():
    """Four colored dots in hashtag pattern"""
    img = create_image()
    draw = ImageDraw.Draw(img)

    # Slack colors
    red = (224, 30, 90)
    green = (47, 168, 85)
    yellow = (236, 178, 46)
    blue = (54, 197, 240)

    # Four pills in # pattern
    r = 3  # radius

    # Top left - blue vertical
    draw.rounded_rectangle([6, 4, 12, 16], radius=r, fill=blue)
    # Top horizontal from blue
    draw.rounded_rectangle([6, 4, 18, 10], radius=r, fill=blue)

    # Top right - green vertical
    draw.rounded_rectangle([20, 4, 26, 16], radius=r, fill=green)
    # Top right green pill
    draw.rounded_rectangle([14, 4, 26, 10], radius=r, fill=green)

    # Bottom left - yellow
    draw.rounded_rectangle([6, 16, 12, 28], radius=r, fill=yellow)
    draw.rounded_rectangle([6, 22, 18, 28], radius=r, fill=yellow)

    # Bottom right - red
    draw.rounded_rectangle([20, 16, 26, 28], radius=r, fill=red)
    draw.rounded_rectangle([14, 22, 26, 28], radius=r, fill=red)

    return img

# Generate all
icons = {
    'spotify': spotify,
    'firefox': firefox,
    'ghostty': ghostty,
    'obsidian': obsidian,
    'messages': messages,
    'vscode': vscode,
    'slack': slack,
}

for name, func in icons.items():
    img = func()
    path = os.path.join(OUTPUT_DIR, f"{name}.png")
    img.save(path, 'PNG')
    print(f"Created: {path}")

print(f"\nAll icons saved to: {OUTPUT_DIR}")
