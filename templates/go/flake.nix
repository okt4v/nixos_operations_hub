{
  # `nixpkgs` resolves through the system registry: same versions as the
  # system, nothing extra to download. Run `nix flake update` to move it.
  inputs.nixpkgs.url = "nixpkgs";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        # Project-specific tools and libraries go here, not in the system config.
        packages = with pkgs; [
          go
          gopls
        ];
      };
    };
}
