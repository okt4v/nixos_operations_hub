# Secure Boot (lanzaboote) and TPM disk unlock. OFF by default: both need
# one-time enrolment on the real machine first, see docs/INSTALL.md.
#   hub.secureBoot.enable = true;
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options.hub.secureBoot.enable = lib.mkEnableOption "Secure Boot and TPM unlock of the encrypted disk";

  config = lib.mkIf config.hub.secureBoot.enable {
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    # Unlock with the TPM (+ PIN) when enrolled; the passphrase keeps working.
    boot.initrd.luks.devices.crypt.crypttabExtraOpts = [ "tpm2-device=auto" ];
    environment.systemPackages = [ pkgs.sbctl ];
  };
}
