# Secrets with sops-nix. One age key, yours, decrypts everything:
#   ~/.config/sops/age/keys.txt   (keep a copy in KeePassXC)
# `hub sec` creates the key on first use and opens secrets/secrets.yaml.
# A secret only has to exist once a feature that declares it is switched on.
{
  inputs,
  config,
  lib,
  ...
}:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # hub.cal.enable = true; once the secret `icloud` (app-specific password)
  # is in secrets/secrets.yaml. Calendar sync starts by itself after that.
  options.hub.cal.enable = lib.mkEnableOption "iCloud calendar sync";

  config.sops = {
    age.keyFile = "/home/oktav/.config/sops/age/keys.txt";
    defaultSopsFile = lib.mkIf (builtins.pathExists ../secrets/secrets.yaml) ../secrets/secrets.yaml;
    secrets.icloud = lib.mkIf config.hub.cal.enable { owner = "oktav"; };
  };
}
