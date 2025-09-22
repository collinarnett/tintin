{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake.overlays.default = final: prev: {
        haskell = prev.haskell // {
          packages = prev.haskell.packages // {
            ghc984 = prev.haskell.packages.ghc984.extend (
              hFinal: hPrev: {
                tintin = hFinal.callCabal2nix "tintin" ./. { };
              }
            );
          };
        };
      };
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
            nativeBuildInputs = with pkgs; [
              cabal-install
              haskellPackages.cabal-fmt
              haskell-language-server
            ];
          };
          packages.default = pkgs.haskell.packages.${ghc}.callCabal2nix "tintin" ./. { };
        };
    };

}
