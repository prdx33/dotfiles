#!/usr/bin/env python3
"""
Fetch clean SVG icons from Simple Icons and convert to PNG
"""

import os
import requests
import cairosvg

OUTPUT_DIR = os.path.expanduser("~/.config/sketchybar/icons/clean")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Map app names to Simple Icons slugs
# Format: "App Name": ("slug", "hex_color") or just "slug" for default color
ICON_MAP = {
    # Browsers
    "Firefox": "firefox",
    "Brave Browser": "brave",
    "Safari": "safari",
    "Orion": None,  # Not on Simple Icons

    # Dev
    "Visual Studio Code": "visualstudiocode",
    "Ghostty": None,  # Too new
    "iTerm": "iterm2",
    "Warp": "warp",
    "GitHub Desktop": "github",
    "Docker": "docker",
    "Figma": "figma",
    "draw.io": "diagramsdotnet",

    # Productivity
    "Obsidian": "obsidian",
    "Notion": "notion",
    "Linear": "linear",
    "Todoist": "todoist",
    "Airtable": "airtable",

    # Communication
    "Slack": "slack",
    "Signal": "signal",
    "WhatsApp": "whatsapp",
    "Discord": "discord",
    "ChatGPT": "openai",

    # Media
    "Spotify": "spotify",
    "Jellyfin": "jellyfin",
    "OBS": "obsstudio",
    "Sonos": "sonos",

    # Security
    "1Password": "1password",
    "NordVPN": "nordvpn",
    "Tailscale": "tailscale",
    "Proton Mail": "protonmail",
    "Proton Pass": "proton",

    # Microsoft
    "Microsoft Word": "microsoftword",
    "Microsoft Excel": "microsoftexcel",
    "Microsoft PowerPoint": "microsoftpowerpoint",
    "Microsoft Outlook": "microsoftoutlook",
    "Microsoft OneNote": "microsoftonenote",
    "OneDrive": "microsoftonedrive",

    # Utilities
    "Raycast": "raycast",
    "Hammerspoon": None,
    "qBittorrent": "qbittorrent",

    # Other popular
    "Claude": "anthropic",
    "Hades II": None,  # Game
    "KakaoTalk": "kakaotalk",
}

# Additional apps to try with auto-generated slugs
AUTO_APPS = [
    "1Password", "ActivityWatch", "Airtable", "Brave Browser", "ChatGPT",
    "Claude", "Docker", "Figma", "Firefox", "GitHub Desktop", "Jellyfin",
    "KakaoTalk", "Linear", "Microsoft Excel", "Microsoft OneNote",
    "Microsoft Outlook", "Microsoft PowerPoint", "Microsoft Word",
    "NordVPN", "Notion", "OBS", "Obsidian", "OneDrive", "Proton Mail",
    "qBittorrent", "Raycast", "Safari", "Signal", "Slack", "Sonos",
    "Spotify", "Tailscale", "Todoist", "Visual Studio Code", "Warp", "WhatsApp",
    "iTerm",
]

def fetch_icon(slug, color=None):
    """Fetch SVG from Simple Icons CDN"""
    if color:
        url = f"https://cdn.simpleicons.org/{slug}/{color}"
    else:
        url = f"https://cdn.simpleicons.org/{slug}"

    try:
        resp = requests.get(url, timeout=10)
        if resp.status_code == 200 and 'svg' in resp.headers.get('content-type', ''):
            return resp.text
    except:
        pass
    return None

def svg_to_png(svg_content, output_path, size=128):
    """Convert SVG to PNG at specified size"""
    cairosvg.svg2png(
        bytestring=svg_content.encode('utf-8'),
        write_to=output_path,
        output_width=size,
        output_height=size
    )

def main():
    success = []
    failed = []

    for app_name, slug_info in ICON_MAP.items():
        if slug_info is None:
            failed.append((app_name, "No Simple Icons entry"))
            continue

        if isinstance(slug_info, tuple):
            slug, color = slug_info
        else:
            slug = slug_info
            color = None

        svg = fetch_icon(slug, color)
        if svg:
            safe_name = app_name.lower().replace(' ', '_').replace('.', '_')
            output_path = os.path.join(OUTPUT_DIR, f"{safe_name}.png")
            try:
                svg_to_png(svg, output_path)
                success.append(app_name)
                print(f"✓ {app_name}")
            except Exception as e:
                failed.append((app_name, str(e)))
                print(f"✗ {app_name}: {e}")
        else:
            failed.append((app_name, "Fetch failed"))
            print(f"✗ {app_name}: not found")

    print(f"\n✓ {len(success)} icons downloaded")
    print(f"✗ {len(failed)} failed")

    if failed:
        print("\nFailed apps:")
        for app, reason in failed:
            print(f"  - {app}: {reason}")

if __name__ == "__main__":
    main()
