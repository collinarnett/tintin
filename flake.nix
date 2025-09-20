{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      git-hooks-nix,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ git-hooks-nix.flakeModule ];
      systems = [ "x86_64-linux" ];
      perSystem =
        {
          config,
          system,
          pkgs,
          lib,
          ...
        }:
        let
          ghc = "ghc984";
        in
        {
          devShells.default = pkgs.haskell.packages.${ghc}.shellFor {
            packages = ps: [
              (ps.callCabal2nix "tintin" ./. { })
            ];
          };
        };
    };

}
