#!/usr/bin/env bash
STEP=0.05
OPACITY_FILE="/tmp/sway_global_opacity"
KITTY_OPACITY_FILE="/tmp/sway_kitty_opacity"

if [ -f "$OPACITY_FILE" ]; then CURRENT=$(cat "$OPACITY_FILE"); else CURRENT="1.0"; fi
if [ -f "$KITTY_OPACITY_FILE" ]; then KITTY_CURRENT=$(cat "$KITTY_OPACITY_FILE"); else KITTY_CURRENT="1.0"; fi

if [ "$1" = "increase" ]; then
    NEW=$(python3 -c "print(round(min(1.0, $CURRENT + $STEP), 2))")
    KITTY_NEW=$(python3 -c "print(round(min(1.0, $KITTY_CURRENT + $STEP), 2))")
else
    NEW=$(python3 -c "print(round(max(0.1, $CURRENT - $STEP), 2))")
    KITTY_NEW=$(python3 -c "print(round(max(0.1, $KITTY_CURRENT - $STEP), 2))")
fi

echo "$NEW" > "$OPACITY_FILE"
echo "$KITTY_NEW" > "$KITTY_OPACITY_FILE"

swaymsg -t get_tree | python3 -c "
import sys, json, subprocess

opacity       = '$NEW'
kitty_opacity = '$KITTY_NEW'
tree = json.loads(sys.stdin.read())

def find_focused(node):
    if node.get('focused'):
        return node
    for child in node.get('nodes', []) + node.get('floating_nodes', []):
        result = find_focused(child)
        if result:
            return result
    return None

def get_con_ids(node):
    ids = []
    if node.get('type') == 'con' and node.get('name') is not None:
        ids.append(node['id'])
    for child in node.get('nodes', []) + node.get('floating_nodes', []):
        ids.extend(get_con_ids(child))
    return ids

def get_kitty_socket(pid):
    try:
        children = subprocess.check_output(['pgrep', '-P', str(pid)]).decode().split()
        for cpid in children:
            try:
                with open(f'/proc/{cpid}/environ', 'rb') as f:
                    env = f.read().decode('utf-8', errors='replace')
                for var in env.split('\0'):
                    if var.startswith('KITTY_LISTEN_ON='):
                        return var[len('KITTY_LISTEN_ON='):]
            except:
                pass
    except:
        pass
    return None

focused = find_focused(tree)

if focused and focused.get('app_id') == 'kitty':
    pid = focused.get('pid')
    socket = get_kitty_socket(pid) if pid else None
    if socket:
        subprocess.run(['kitty', '@', '--to', socket, 'set-background-opacity', kitty_opacity])
    else:
        subprocess.run(['swaymsg', f'[con_id={focused[\"id\"]}] opacity {opacity}'])
else:
    for wid in get_con_ids(tree):
        subprocess.run(['swaymsg', f'[con_id={wid}] opacity {opacity}'])
" 2>>/tmp/opacity-debug.log
