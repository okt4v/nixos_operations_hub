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
    # only read when a switched-on feature declares a secret
    defaultSopsFile =
      if builtins.pathExists ../secrets/secrets.yaml then
        ../secrets/secrets.yaml
      else
        throw "A feature you switched on (mail, calendar, a backup) needs secrets: run `hub sec`, add them (docs/INSTALL.md), git add secrets/secrets.yaml, then switch again.";
    secrets.icloud = lib.mkIf config.hub.cal.enable { owner = "oktav"; };
  };
}
