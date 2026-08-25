{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    roc.url = "github:roc-lang/roc/alpha4-rolling";
    cloud-cli.url = "github:fogpipe/cloud-cli";
  };

  outputs = { nixpkgs, flake-utils, roc, cloud-cli, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # the fpcloud binary is proprietary
          config.allowUnfree = true;
        };

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
                pkgs.pgcli
                pkgs.just
                pkgs.jq
                pkgs.postgresql_15
                pkgs.process-compose
                cloud-cli.packages.${system}.default
              ];
          };
        };
      });
}
