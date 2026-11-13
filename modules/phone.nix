# Phone link (KDE Connect): notifications, clipboard, files, media control.
# Pair once from the tray icon or `kdeconnect-cli --pair`. Opens ports
# 1714-1764 on the firewall; on untrusted wifi net-trust stops the daemon.
{ ... }:

{
  programs.kdeconnect.enable = true;
}
