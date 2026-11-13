# One palette, every app. The colours are plain files in config/palette/;
# `theme` (bin/theme) turns them into per-app colour files under
# ~/.config/pal/<name>/ and flips ~/.config/pal/current. No rebuild.
# This only makes sure the files exist before the first login.
{ osConfig, lib, ... }:

{
  home.activation.palette = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    [ ! -x "${osConfig.hub.dir}/bin/theme" ] || run "${osConfig.hub.dir}/bin/theme" gen
  '';
}
