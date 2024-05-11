{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    roc.url = "github:roc-lang/roc";
  };

  outputs = { nixpkgs, flake-utils, roc, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # see "packages =" in https://github.com/roc-lang/roc/blob/main/flake.nix
        rocPkgs = roc.packages.${system};

        rocFull = rocPkgs.full;
      in
      {
        formatter = pkgs.nixpkgs-fmt;

        devShells = {
          default = pkgs.mkShell {
            buildInputs =
              [
                rocFull # includes CLI
              ];
          };
        };
      });
}
