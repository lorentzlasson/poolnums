{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    cloud-cli.url = "github:fogpipe/cloud-cli";
  };

  outputs = { nixpkgs, flake-utils, cloud-cli, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # the fpcloud binary is proprietary
          config.allowUnfree = true;
        };

        # must match the `roc:` pin in main.roc's app header
        rocVersion = "2026-09-29-7f11a82";

        rocAssets = {
          x86_64-linux = { arch = "x86_64"; hash = "sha256-PzkR+Dhss0Vh+fyTodBL8cGooPTEyXhdnwKR3I0Q/RU="; };
          aarch64-linux = { arch = "arm64"; hash = "sha256-MjD0Qgkv2wds3NYiPxlTlqZ0nuOC4+AOBeeOcxvLjms="; };
        };

        # the nightly release binary is statically linked, so it runs on NixOS as is
        roc = pkgs.stdenvNoCC.mkDerivation {
          pname = "roc";
          version = "nightly-${rocVersion}";
          src = pkgs.fetchurl {
            url = "https://github.com/roc-lang/nightlies/releases/download/nightly-${rocVersion}/roc_nightly-linux_${rocAssets.${system}.arch}-${rocVersion}.tar.gz";
            inherit (rocAssets.${system}) hash;
          };
          installPhase = "install -D --mode=755 roc $out/bin/roc";
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;

        devShells = {
          default = pkgs.mkShell {
            buildInputs =
              [
                roc
                pkgs.just
                pkgs.jq
                pkgs.process-compose
                cloud-cli.packages.${system}.default
              ];
          };
        };
      });
}
