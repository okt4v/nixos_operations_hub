# One palette, every app. Generates ~/.config/pal/{dark,light}/<app> colour
# files; ~/.config/pal/current is a symlink that `theme` flips, so switching
# light/dark needs no rebuild. Add a palette = add an attrset below.
{ config, lib, ... }:

let
  pals = {
    dark = {
      bg = "1c1c1e";
      fg = "ffffff";
      sel = "3a3a3c";
      mute = "8e8e93";
      acc = "0a84ff";
      ok = "30d158";
      warn = "ff9f0a";
      crit = "ff453a";
    };
    light = {
      bg = "f2f2f7";
      fg = "1c1c1e";
      sel = "d1d1d6";
      mute = "6e6e73";
      acc = "007aff";
      ok = "248a3d";
      warn = "c93400";
      crit = "d70015";
    };
  };

  files = name: p: {
    "pal/${name}/name".text = name;

    "pal/${name}/sway.conf".text = ''
      # class                 border  bg      text    indicator child_border
      client.focused          #${p.acc} #${p.acc} #${p.bg} #${p.acc} #${p.acc}
      client.focused_inactive #${p.sel} #${p.sel} #${p.fg} #${p.sel} #${p.sel}
      client.unfocused        #${p.sel} #${p.bg} #${p.mute} #${p.sel} #${p.sel}
      client.urgent           #${p.crit} #${p.crit} #${p.bg} #${p.crit} #${p.crit}
    '';

    "pal/${name}/bar.css".text = lib.concatStrings (
      lib.mapAttrsToList (k: v: "@define-color ${k} #${v};\n") p
    );

    # ponytail: only the base colours; the 16 ANSI colours stay kitty's
    # defaults. Add color0..15 here if the light palette reads badly.
    "pal/${name}/kitty.conf".text = ''
      background #${p.bg}
      foreground #${p.fg}
      cursor #${p.fg}
      selection_background #${p.sel}
      selection_foreground #${p.fg}
      active_border_color #${p.acc}
      inactive_border_color #${p.sel}
      url_color #${p.acc}
    '';

    "pal/${name}/tmux.conf".text = ''
      set -g status-style "bg=#${p.bg},fg=#${p.fg}"
      set -g status-left-style "bg=#${p.acc},fg=#${p.bg},bold"
      set -g status-right "#[fg=#${p.acc}]#(cat ~/.local/state/hub/mode 2>/dev/null) #[fg=#${p.mute}]%H:%M  %d-%b-%Y "
      set -g window-status-current-style "bg=#${p.sel},fg=#${p.fg},bold"
      set -g pane-border-style "fg=#${p.sel}"
      set -g pane-active-border-style "fg=#${p.acc}"
    '';

    "pal/${name}/eww.scss".text = lib.concatStrings (lib.mapAttrsToList (k: v: "\$${k}: #${v};\n") p);

    "pal/${name}/fuzzel.ini".text = ''
      [colors]
      background=${p.bg}f5
      text=${p.fg}ff
      prompt=${p.mute}ff
      input=${p.fg}ff
      match=${p.acc}ff
      selection=${p.sel}ff
      selection-text=${p.fg}ff
      selection-match=${p.acc}ff
      border=${p.sel}ff
    '';

    "pal/${name}/mako".text = ''
      font=Inter 11
      background-color=#${p.bg}
      text-color=#${p.fg}
      border-color=#${p.sel}
      border-radius=12
      border-size=1
      default-timeout=5000
      max-visible=5
      sort=-time
      anchor=top-right
      width=340
      height=110
      margin=12
      padding=14

      [mode=dnd]
      invisible=1
    '';
  };
in
{
  xdg.configFile = lib.mkMerge (lib.mapAttrsToList files pals);

  # Start on dark; afterwards the link belongs to `theme`.
  home.activation.palCurrent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    [ -e "${config.xdg.configHome}/pal/current" ] || run ln -s dark "${config.xdg.configHome}/pal/current"
  '';
}
