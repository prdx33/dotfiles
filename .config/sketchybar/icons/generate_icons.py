#!/usr/bin/env python3
"""
Generate 10x10 abstract app icons for sketchybar
Simplified, harmonious palette with recognisable shapes
"""

from PIL import Image, ImageDraw
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# Harmonious palette - muted but distinct
COLORS = {
    # Warm
    'orange': (255, 149, 0),
    'orange_dark': (204, 102, 0),
    'red': (255, 69, 58),
    'red_dark': (180, 50, 40),
    'pink': (255, 105, 180),
    'coral': (255, 127, 80),

    # Cool
    'blue': (50, 173, 230),
    'blue_dark': (30, 120, 180),
    'blue_deep': (0, 102, 204),
    'purple': (175, 82, 222),
    'purple_dark': (120, 60, 160),
    'violet': (138, 43, 226),
    'indigo': (88, 86, 214),

    # Nature
    'green': (52, 199, 89),
    'green_dark': (30, 150, 60),
    'green_bright': (30, 215, 96),
    'teal': (90, 200, 250),
    'cyan': (100, 210, 255),

    # Neutral
    'white': (255, 255, 255),
    'gray_light': (200, 200, 200),
    'gray': (142, 142, 147),
    'gray_dark': (72, 72, 74),
    'black': (28, 28, 30),

    # Accent
    'yellow': (255, 214, 10),
    'gold': (255, 193, 7),

    # Brand-specific
    'spotify_green': (30, 215, 96),
    'slack_purple': (97, 31, 105),
    'slack_red': (224, 30, 90),
    'slack_green': (47, 168, 85),
    'slack_yellow': (236, 178, 46),
    'notion_black': (25, 25, 25),
    'linear_purple': (98, 77, 227),
    'figma_red': (242, 78, 30),
    'figma_purple': (162, 89, 255),
    'signal_blue': (58, 118, 246),
    'proton_purple': (109, 74, 255),
    'obsidian_purple': (124, 77, 255),
    'vscode_blue': (0, 122, 204),
    'docker_blue': (29, 99, 237),
    'github_black': (36, 41, 46),
    'warp_blue': (0, 180, 216),
    'brave_orange': (251, 84, 43),
}

def create_icon(pixels, bg=(0, 0, 0, 0)):
    """Create 10x10 image from pixel data"""
    img = Image.new('RGBA', (10, 10), bg)
    for (x, y), color in pixels.items():
        if 0 <= x < 10 and 0 <= y < 10:
            # Add alpha if not present
            if len(color) == 3:
                color = (*color, 255)
            img.putpixel((x, y), color)
    return img

def filled_circle(color, center_color=None):
    """Filled circle with optional center dot"""
    pixels = {}
    c = color
    # 10x10 circle pattern
    pattern = [
        "   ####   ",
        "  ######  ",
        " ######## ",
        "##########",
        "##########",
        "##########",
        "##########",
        " ######## ",
        "  ######  ",
        "   ####   ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = c
    if center_color:
        # Add center 2x2 dot
        for dx in [4, 5]:
            for dy in [4, 5]:
                pixels[(dx, dy)] = center_color
    return pixels

def ring_circle(outer, inner=None):
    """Circle outline"""
    pixels = {}
    pattern = [
        "   ####   ",
        "  #    #  ",
        " #      # ",
        "#        #",
        "#        #",
        "#        #",
        "#        #",
        " #      # ",
        "  #    #  ",
        "   ####   ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = outer
    return pixels

def filled_square(color, border=None):
    """Filled square with optional border"""
    pixels = {}
    for x in range(2, 8):
        for y in range(2, 8):
            pixels[(x, y)] = color
    if border:
        for i in range(2, 8):
            pixels[(i, 2)] = border
            pixels[(i, 7)] = border
            pixels[(2, i)] = border
            pixels[(7, i)] = border
    return pixels

def rounded_square(color):
    """Square with rounded corners"""
    pixels = {}
    pattern = [
        "          ",
        "  ######  ",
        " ######## ",
        " ######## ",
        " ######## ",
        " ######## ",
        " ######## ",
        " ######## ",
        "  ######  ",
        "          ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = color
    return pixels

def diamond(color):
    """Diamond/crystal shape"""
    pixels = {}
    pattern = [
        "    ##    ",
        "   ####   ",
        "  ######  ",
        " ######## ",
        "##########",
        "##########",
        " ######## ",
        "  ######  ",
        "   ####   ",
        "    ##    ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = color
    return pixels

def crystal(top_color, bottom_color):
    """Two-tone crystal shape for Obsidian-style"""
    pixels = {}
    pattern_top = [
        "    ##    ",
        "   ####   ",
        "  ######  ",
        " ######## ",
        "##########",
    ]
    pattern_bottom = [
        "##########",
        " ######## ",
        "  ######  ",
        "   ####   ",
        "    ##    ",
    ]
    for y, row in enumerate(pattern_top):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = top_color
    for y, row in enumerate(pattern_bottom):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y + 5)] = bottom_color
    return pixels

def triangle_up(color):
    """Upward pointing triangle"""
    pixels = {}
    pattern = [
        "    ##    ",
        "    ##    ",
        "   ####   ",
        "   ####   ",
        "  ######  ",
        "  ######  ",
        " ######## ",
        " ######## ",
        "##########",
        "##########",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = color
    return pixels

def triangle_down(color):
    """Downward pointing triangle"""
    pixels = {}
    pattern = [
        "##########",
        "##########",
        " ######## ",
        " ######## ",
        "  ######  ",
        "  ######  ",
        "   ####   ",
        "   ####   ",
        "    ##    ",
        "    ##    ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = color
    return pixels

def letter(char, color):
    """Simple letter patterns"""
    letters = {
        'M': [
            "#        #",
            "##      ##",
            "# #    # #",
            "#  #  #  #",
            "#   ##   #",
            "#        #",
            "#        #",
            "#        #",
            "#        #",
            "#        #",
        ],
        'S': [
            "  ######  ",
            " #      # ",
            "#          ",
            " #        ",
            "  ######  ",
            "        # ",
            "          #",
            "#        #",
            " #      # ",
            "  ######  ",
        ],
        'W': [
            "#        #",
            "#        #",
            "#        #",
            "#        #",
            "#   ##   #",
            "#  #  #  #",
            "# #    # #",
            "##      ##",
            "#        #",
            "          ",
        ],
    }
    pixels = {}
    if char in letters:
        for y, row in enumerate(letters[char]):
            for x, c in enumerate(row):
                if c == '#':
                    pixels[(x, y)] = color
    return pixels

def gradient_circle(top_color, bottom_color):
    """Circle with vertical gradient"""
    pixels = {}
    pattern = [
        "   ####   ",
        "  ######  ",
        " ######## ",
        "##########",
        "##########",
        "##########",
        "##########",
        " ######## ",
        "  ######  ",
        "   ####   ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                # Blend colors based on y position
                t = y / 9.0
                r = int(top_color[0] * (1-t) + bottom_color[0] * t)
                g = int(top_color[1] * (1-t) + bottom_color[1] * t)
                b = int(top_color[2] * (1-t) + bottom_color[2] * t)
                pixels[(x, y)] = (r, g, b)
    return pixels

def dots_grid(colors):
    """Grid of colored dots (for Slack, etc)"""
    pixels = {}
    positions = [(2,2), (5,2), (2,5), (5,5)]
    for i, (x, y) in enumerate(positions):
        c = colors[i % len(colors)]
        for dx in range(2):
            for dy in range(2):
                pixels[(x+dx, y+dy)] = c
    return pixels

def play_button(color):
    """Play triangle"""
    pixels = {}
    pattern = [
        "          ",
        " ##       ",
        " ####     ",
        " ######   ",
        " ######## ",
        " ######## ",
        " ######   ",
        " ####     ",
        " ##       ",
        "          ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = color
    return pixels

def music_note(color):
    """Simple music note shape"""
    pixels = {}
    pattern = [
        "    ######",
        "    ######",
        "    ##    ",
        "    ##    ",
        "    ##    ",
        "    ##    ",
        "  ####    ",
        " ######   ",
        " ######   ",
        "  ####    ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = color
    return pixels

def shield(outer, inner):
    """Shield shape"""
    pixels = {}
    pattern_outer = [
        " ######## ",
        "##########",
        "##########",
        "##########",
        "##########",
        " ######## ",
        " ######## ",
        "  ######  ",
        "   ####   ",
        "    ##    ",
    ]
    pattern_inner = [
        "          ",
        "          ",
        "  ######  ",
        "  ######  ",
        "  ######  ",
        "   ####   ",
        "   ####   ",
        "    ##    ",
        "          ",
        "          ",
    ]
    for y, row in enumerate(pattern_outer):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = outer
    for y, row in enumerate(pattern_inner):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = inner
    return pixels

def hexagon(color):
    """Hexagon shape"""
    pixels = {}
    pattern = [
        "   ####   ",
        "  ######  ",
        " ######## ",
        "##########",
        "##########",
        "##########",
        "##########",
        " ######## ",
        "  ######  ",
        "   ####   ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = color
    return pixels

def code_brackets(color):
    """Code brackets < > """
    pixels = {}
    pattern = [
        "          ",
        "  ##  ##  ",
        " ##    ## ",
        "##      ##",
        "#        #",
        "#        #",
        "##      ##",
        " ##    ## ",
        "  ##  ##  ",
        "          ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = color
    return pixels

def chat_bubble(color):
    """Chat bubble"""
    pixels = {}
    pattern = [
        "  ######  ",
        " ######## ",
        "##########",
        "##########",
        "##########",
        " ######## ",
        "  ######  ",
        " ##       ",
        "##        ",
        "          ",
    ]
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = color
    return pixels

def flame(orange, yellow):
    """Flame shape"""
    pixels = {}
    pattern_orange = [
        "    ##    ",
        "   ####   ",
        "   ####   ",
        "  ######  ",
        "  ######  ",
        " ######## ",
        " ######## ",
        " ######## ",
        "  ######  ",
        "   ####   ",
    ]
    pattern_yellow = [
        "          ",
        "          ",
        "    ##    ",
        "   ####   ",
        "   ####   ",
        "   ####   ",
        "  ######  ",
        "  ######  ",
        "   ####   ",
        "    ##    ",
    ]
    for y, row in enumerate(pattern_orange):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = orange
    for y, row in enumerate(pattern_yellow):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = yellow
    return pixels

def eye(outer, pupil):
    """Eye shape"""
    pixels = {}
    pattern_outer = [
        "          ",
        "   ####   ",
        "  ######  ",
        " ######## ",
        "##########",
        "##########",
        " ######## ",
        "  ######  ",
        "   ####   ",
        "          ",
    ]
    pattern_pupil = [
        "          ",
        "          ",
        "          ",
        "    ##    ",
        "   ####   ",
        "   ####   ",
        "    ##    ",
        "          ",
        "          ",
        "          ",
    ]
    for y, row in enumerate(pattern_outer):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = outer
    for y, row in enumerate(pattern_pupil):
        for x, char in enumerate(row):
            if char == '#':
                pixels[(x, y)] = pupil
    return pixels


# App icon definitions - artistic interpretations
APP_ICONS = {
    # Browsers
    'Firefox': lambda: gradient_circle(COLORS['orange'], COLORS['purple_dark']),
    'Brave Browser': lambda: filled_circle(COLORS['brave_orange'], COLORS['white']),
    'Safari': lambda: filled_circle(COLORS['blue'], COLORS['white']),
    'Mullvad Browser': lambda: filled_circle(COLORS['green_dark'], COLORS['yellow']),
    'Orion': lambda: gradient_circle(COLORS['purple'], COLORS['blue']),

    # Development
    'Visual Studio Code': lambda: rounded_square(COLORS['vscode_blue']),
    'Ghostty': lambda: filled_circle(COLORS['gray_dark'], COLORS['cyan']),
    'iTerm': lambda: rounded_square(COLORS['green']),
    'Warp': lambda: gradient_circle(COLORS['warp_blue'], COLORS['purple']),
    'GitHub Desktop': lambda: filled_circle(COLORS['github_black'], COLORS['white']),
    'Docker': lambda: filled_circle(COLORS['docker_blue'], COLORS['white']),
    'Figma': lambda: gradient_circle(COLORS['figma_red'], COLORS['figma_purple']),
    'draw.io': lambda: hexagon(COLORS['orange']),
    'LM Studio': lambda: rounded_square(COLORS['green_dark']),
    'Hammerspoon': lambda: filled_circle(COLORS['yellow'], COLORS['black']),
    'Vial': lambda: rounded_square(COLORS['purple']),
    'ZMK Studio': lambda: rounded_square(COLORS['teal']),

    # Productivity
    'Obsidian': lambda: crystal(COLORS['obsidian_purple'], COLORS['purple_dark']),
    'Notion': lambda: rounded_square(COLORS['notion_black']),
    'Notion Calendar': lambda: filled_square(COLORS['notion_black'], COLORS['white']),
    'Linear': lambda: filled_circle(COLORS['linear_purple']),
    'Todoist': lambda: filled_circle(COLORS['red']),
    'Typora': lambda: rounded_square(COLORS['green_dark']),
    'Airtable': lambda: filled_square(COLORS['blue'], COLORS['yellow']),
    'PDF Expert': lambda: rounded_square(COLORS['red']),

    # Communication
    'Slack': lambda: dots_grid([COLORS['slack_red'], COLORS['slack_green'], COLORS['slack_yellow'], COLORS['slack_purple']]),
    'Signal': lambda: chat_bubble(COLORS['signal_blue']),
    'WhatsApp': lambda: chat_bubble(COLORS['green']),
    'KakaoTalk': lambda: chat_bubble(COLORS['yellow']),
    'Spark': lambda: gradient_circle(COLORS['blue'], COLORS['cyan']),
    'Spark Desktop': lambda: gradient_circle(COLORS['blue'], COLORS['cyan']),

    # AI & Chat
    'ChatGPT': lambda: filled_circle(COLORS['teal'], COLORS['white']),
    'Claude': lambda: filled_circle(COLORS['coral'], COLORS['white']),

    # Media
    'Spotify': lambda: filled_circle(COLORS['spotify_green'], COLORS['black']),
    'Jellyfin': lambda: gradient_circle(COLORS['purple'], COLORS['blue']),
    'OBS': lambda: filled_circle(COLORS['gray_dark'], COLORS['white']),
    'Elmedia Player': lambda: play_button(COLORS['orange']),
    'Sonos': lambda: ring_circle(COLORS['black']),
    'SoundSource': lambda: music_note(COLORS['purple']),
    'Endel': lambda: gradient_circle(COLORS['purple_dark'], COLORS['blue_dark']),

    # Security & Privacy
    '1Password': lambda: rounded_square(COLORS['blue']),
    'Little Snitch': lambda: shield(COLORS['gray_dark'], COLORS['yellow']),
    'Mullvad VPN': lambda: shield(COLORS['green_dark'], COLORS['yellow']),
    'NordVPN': lambda: shield(COLORS['blue_deep'], COLORS['white']),
    'Tailscale': lambda: hexagon(COLORS['blue']),
    'NextDNS': lambda: shield(COLORS['orange'], COLORS['white']),
    'Proton Mail': lambda: shield(COLORS['proton_purple'], COLORS['white']),
    'Proton Mail Bridge': lambda: shield(COLORS['proton_purple'], COLORS['gray']),
    'Proton Pass': lambda: shield(COLORS['proton_purple'], COLORS['yellow']),
    'Yubico Authenticator': lambda: rounded_square(COLORS['green']),
    'YubiKey Manager': lambda: rounded_square(COLORS['green_dark']),

    # Microsoft
    'Microsoft Word': lambda: rounded_square(COLORS['blue_deep']),
    'Microsoft Excel': lambda: rounded_square(COLORS['green']),
    'Microsoft PowerPoint': lambda: rounded_square(COLORS['orange']),
    'Microsoft Outlook': lambda: rounded_square(COLORS['blue']),
    'Microsoft OneNote': lambda: rounded_square(COLORS['purple']),
    'OneDrive': lambda: filled_circle(COLORS['blue'], COLORS['white']),

    # Utilities
    'Raycast': lambda: gradient_circle(COLORS['orange'], COLORS['red']),
    'CleanShot X': lambda: filled_circle(COLORS['purple'], COLORS['white']),
    'BetterSnapTool': lambda: filled_square(COLORS['blue'], COLORS['gray']),
    'BetterDisplay': lambda: rounded_square(COLORS['blue']),
    'HazeOver': lambda: filled_circle(COLORS['gray'], COLORS['gray_dark']),
    'Hand Mirror': lambda: filled_circle(COLORS['pink']),
    'Pandan': lambda: filled_circle(COLORS['green']),
    'iStat Menus': lambda: rounded_square(COLORS['gray_dark']),
    'Karabiner-Elements': lambda: rounded_square(COLORS['orange']),
    'Karabiner-EventViewer': lambda: rounded_square(COLORS['orange_dark']),
    'Flux': lambda: filled_circle(COLORS['orange'], COLORS['yellow']),
    'FontBase': lambda: rounded_square(COLORS['red']),
    'Ghost Buster Pro': lambda: filled_circle(COLORS['gray'], COLORS['white']),
    'Lingon Pro': lambda: flame(COLORS['orange'], COLORS['yellow']),
    'Network Radar': lambda: ring_circle(COLORS['green']),
    'qBittorrent': lambda: triangle_down(COLORS['blue']),
    'QSpace Pro': lambda: rounded_square(COLORS['blue']),
    'SF Symbols': lambda: rounded_square(COLORS['blue']),
    'Webcam Setting': lambda: eye(COLORS['gray'], COLORS['black']),
    'TNAS PC': lambda: rounded_square(COLORS['blue_dark']),
    'CursorSense': lambda: filled_circle(COLORS['blue']),
    'BatFi': lambda: filled_circle(COLORS['green'], COLORS['yellow']),
    'ActivityWatch': lambda: eye(COLORS['purple'], COLORS['black']),
    'Actual': lambda: rounded_square(COLORS['purple']),
    'AdGuard for Safari': lambda: shield(COLORS['green'], COLORS['white']),
    'AeroSpace': lambda: hexagon(COLORS['blue']),
    'Blackmagic Proxy Generator': lambda: rounded_square(COLORS['red_dark']),
    'Bloom': lambda: filled_circle(COLORS['pink'], COLORS['white']),
    'Menu Bar Controller for Sonos 2': lambda: music_note(COLORS['black']),
    'superwhisper': lambda: filled_circle(COLORS['purple'], COLORS['white']),
    'uBlock Origin Lite': lambda: shield(COLORS['red'], COLORS['white']),

    # Games
    'Hades II': lambda: flame(COLORS['red'], COLORS['orange']),
}

def get_default_icon(name):
    """Generate a default icon based on app name"""
    # Use first letter's hash to pick a color
    colors = [
        COLORS['blue'], COLORS['green'], COLORS['purple'],
        COLORS['orange'], COLORS['red'], COLORS['teal'],
        COLORS['pink'], COLORS['indigo'], COLORS['coral']
    ]
    color = colors[hash(name) % len(colors)]
    return rounded_square(color)

def save_icon(name, pixels, bg=(0, 0, 0, 0)):
    """Save icon as PNG"""
    img = create_icon(pixels, bg)
    # Sanitise filename
    safe_name = name.replace(' ', '_').replace('.', '_').lower()
    path = os.path.join(OUTPUT_DIR, f"{safe_name}.png")
    img.save(path, 'PNG')
    return path

def generate_all():
    """Generate all icons"""
    apps = []
    for entry in os.listdir('/Applications'):
        if entry.endswith('.app'):
            apps.append(entry[:-4])

    generated = []
    for app in sorted(apps):
        if app in APP_ICONS:
            pixels = APP_ICONS[app]()
        else:
            pixels = get_default_icon(app)

        path = save_icon(app, pixels)
        generated.append((app, path))
        print(f"Generated: {app}")

    return generated

if __name__ == '__main__':
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    generate_all()
    print(f"\nIcons saved to: {OUTPUT_DIR}")
