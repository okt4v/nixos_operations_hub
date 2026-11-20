# Remote unlock: at boot, before the disk is open, SSH listens on port 2222
# (wired network, DHCP). Log in as root with your key and you are asked for
# the disk passphrase straight away:
#   ssh -p 2222 root@<machine>
# The initrd's host key is /var/lib/initrd-ssh/ssh_host_ed25519_key; the
# installer creates it, otherwise `hub doctor` says how. Wifi does not work
# this early, so this is for machines on a cable (desktop, homelab server).
{ ... }:

{
  boot.initrd = {
    # ponytail: common wired NIC drivers; add yours if `ip link` in the
    # initrd shows nothing (driver: readlink /sys/class/net/<if>/device/driver)
    availableKernelModules = [
      "r8169"
      "e1000e"
      "igb"
      "igc"
      "tg3"
      "atlantic"
      "virtio_net"
    ];
    systemd.network = {
      enable = true;
      networks."10-wired" = {
        matchConfig.Type = "ether";
        networkConfig.DHCP = "yes";
      };
    };
    network.enable = true;
    network.ssh = {
      enable = true;
      port = 2222;
      hostKeys = [ "/var/lib/initrd-ssh/ssh_host_ed25519_key" ];
      authorizedKeyFiles = [ ../secrets/oktav.pub ];
    };
    # logging in goes straight to the passphrase prompt
    systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
  };
}
