{
  description = "NixOS operations hub";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      # Every directory in hosts/ is a host. Adding a machine = adding a directory.
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      hosts = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );
    in
    {
      # `hub check`: every host must evaluate (flake check does that itself)
      # and every script must pass shellcheck.
      checks.x86_64-linux.scripts =
        pkgs.runCommand "shellcheck-scripts" { nativeBuildInputs = [ pkgs.shellcheck ]; }
          ''
            shellcheck --severity=warning ${./bin}/* ${./config/sway/scripts}/*.sh
            touch $out
          '';

      nixosConfigurations = lib.genAttrs hosts (
        name:
        lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${name}/default.nix
            {
              networking.hostName = name;
              # boot menu, os-release, fastfetch; the ID stays "nixos" for tools that check it
              system.nixos.distroName = "ophub NixOS";
            }
          ];
        }
      );
    };
}
