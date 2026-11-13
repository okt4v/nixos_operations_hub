# Keyboard layer (kanata), for hosts with the German ISO laptop keyboard.
# The one config that needs a rebuild to change: kanata runs as a system
# service and reads its config from the store. Validate edits first with
# `kanata --check -c config/kanata/main.kbd`.
{ ... }:

{
  services.kanata = {
    enable = true;
    keyboards.main = {
      config = builtins.readFile ../config/kanata/main.kbd;
      extraDefCfg = "process-unmapped-keys yes";
    };
  };
}
