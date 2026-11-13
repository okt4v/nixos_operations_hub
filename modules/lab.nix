# Virtual machines and network/security tooling.
{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;
  programs.wireshark.enable = true;

  users.users.oktav.extraGroups = [
    "libvirtd"
    "wireshark"
  ];

  # Isolated network for `lab` VMs: no <forward>, so no route to the LAN or
  # the internet. Guests reach each other and this host only.
  systemd.services.libvirt-lab-net = {
    description = "Define the isolated libvirt network 'lab'";
    wantedBy = [ "multi-user.target" ];
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.libvirt}/bin/virsh net-info lab >/dev/null 2>&1 || ${pkgs.libvirt}/bin/virsh net-define ${pkgs.writeText "lab-net.xml" ''
        <network>
          <name>lab</name>
          <bridge name="virbr-lab"/>
          <ip address="10.66.0.1" netmask="255.255.255.0">
            <dhcp><range start="10.66.0.10" end="10.66.0.200"/></dhcp>
          </ip>
        </network>
      ''}
    '';
  };

  environment.systemPackages = with pkgs; [
    virt-viewer
    bubblewrap # `agent`
    nmap
    burpsuite
    cryptsetup
  ];
}
