# Optional apps of this host. Switch with `hub apps` (menu) or
# `hub apps on|off <name>`, then `hub switch`. One app per line.
# The catalog (which package each name is) is home/apps.nix.
{
  thunderbird = true; # mail client
  spotify = true; # music (Super+Ctrl+M scratchpad)
  mullvad = true; # Mullvad VPN window (the VPN itself is always there)
  obsidian = true; # notes app over ~/doc/notes (mode school opens it)
  anki = true; # flashcards (`card` adds cards)
  zotero = true; # literature manager (mode school opens it)
  onlyoffice = true; # Word/Excel/PowerPoint compatible office
  libreoffice = false; # office suite
  vscode = true; # VS Code
  gimp = true; # image editor
  inkscape = true; # vector drawing; `fig` needs it
  krita = false; # painting
  darktable = false; # photo raw developer
  audacity = false; # audio editor
  kdenlive = false; # video editor
  qalculate = true; # calculator window (`menu calc` works without it)
  openscreen = true; # screen recorder with zoom effects
  godot = true; # game engine
  aseprite = true; # pixel art
  blender = true; # 3D
  freecad = false; # CAD
  vlc = false; # video player (mpv is always there)
  calibre = false; # e-book library
  signal = false; # Signal messenger
  element = false; # Matrix chat
  telegram = false; # Telegram
  discord = false; # Discord (Vesktop)
}
