#!/usr/bin/env python3
import os, re

SWAY_DIR = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

def load_variables():
    variables = {}
    try:
        with open(os.path.join(SWAY_DIR, "variables.conf")) as f:
            for line in f:
                m = re.match(r'\s*set\s+(\$\w+)\s+(.+)', line)
                if m:
                    variables[m.group(1)] = m.group(2).strip()
    except FileNotFoundError:
        pass
    return variables

def resolve(text, variables):
    for k in sorted(variables, key=len, reverse=True):
        text = text.replace(k, variables[k])
    return text.replace('\\@', '@')

def humanize_key(key, variables):
    key = resolve(key, variables)
    return (key
            .replace('Mod4', 'Super')
            .replace('Mod1', 'Alt')
            .replace('XF86AudioMute', 'AudioMute')
            .replace('XF86AudioLowerVolume', 'VolumeDown')
            .replace('XF86AudioRaiseVolume', 'VolumeUp')
            .replace('XF86AudioMicMute', 'MicMute')
            .replace('XF86MonBrightnessDown', 'BrightnessDown')
            .replace('XF86MonBrightnessUp', 'BrightnessUp'))

def parse_keybindings():
    variables = load_variables()
    sections = []
    current_section = "General"
    current_binds = []
    pending_desc = None
    consecutive_comments = 0
    in_mode = None

    try:
        with open(os.path.join(SWAY_DIR, "keybindings.conf")) as f:
            lines = f.readlines()
    except FileNotFoundError:
        return []

    i = 0
    while i < len(lines):
        stripped = lines[i].strip()

        if stripped == '#' and i + 2 < len(lines):
            m = re.match(r'^#\s+(.+):\s*$', lines[i + 1].strip())
            if m and lines[i + 2].strip() == '#':
                if current_binds:
                    sections.append((current_section, current_binds))
                current_section = m.group(1)
                current_binds = []
                pending_desc = None
                consecutive_comments = 0
                i += 3
                continue

        m = re.match(r'\s*mode\s+"([^"]+)"\s*\{', stripped)
        if m:
            if current_binds:
                sections.append((current_section, current_binds))
            current_section = f"{m.group(1).capitalize()} mode"
            current_binds = []
            pending_desc = None
            consecutive_comments = 0
            in_mode = m.group(1)
            i += 1
            continue

        if stripped == '}' and in_mode:
            in_mode = None
            pending_desc = None
            consecutive_comments = 0
            i += 1
            continue

        if stripped.startswith('#'):
            text = stripped.lstrip('#').strip()
            if text:
                consecutive_comments += 1
                if consecutive_comments == 1:
                    pending_desc = text
                else:
                    pending_desc = None
            i += 1
            continue

        m = re.match(r'bindsym\s+(.*)', stripped)
        if m:
            rest = m.group(1)
            flags = []
            while rest.startswith('--'):
                parts = rest.split(None, 1)
                flags.append(parts[0][2:])
                rest = parts[1] if len(parts) > 1 else ''

            parts = rest.split(None, 1)
            if parts:
                key = humanize_key(parts[0], variables)
                action = resolve(parts[1].strip() if len(parts) > 1 else '', variables)
                desc = pending_desc if consecutive_comments == 1 else None
                current_binds.append({'key': key, 'desc': desc or action, 'flags': flags})
            pending_desc = None
            consecutive_comments = 0
            i += 1
            continue

        if not stripped or not stripped.startswith('#'):
            pending_desc = None
            consecutive_comments = 0
        i += 1

    if current_binds:
        sections.append((current_section, current_binds))
    return sections

RESET  = '\033[0m'
BOLD   = '\033[1m'
GREEN  = '\033[32m'
CYAN   = '\033[36m'
YELLOW = '\033[33m'
DIM    = '\033[2m'

for sec_name, binds in parse_keybindings():
    print(f"\n{BOLD}{CYAN}── {sec_name.upper()} ──{RESET}")
    for b in binds:
        key_plain = b['key']
        pad = ' ' * max(1, 32 - len(key_plain))
        flags = '  '.join(f"{YELLOW}[{f}]{RESET}" for f in b['flags'])
        flags_str = f"  {flags}" if flags else ''
        print(f"  {GREEN}{key_plain}{RESET}{pad}{DIM}{b['desc']}{RESET}{flags_str}")
