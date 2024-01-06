{
  description = "Heise Nix Example Project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    advisory-db.url = "github:rustsec/advisory-db";
    advisory-db.flake = false;
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    perSystem = { config, pkgs, system, ... }:
      let
        craneLib = inputs.crane.lib.${system};
        src = craneLib.cleanCargoSource (craneLib.path ./rust);
        cargoArtifacts = craneLib.buildDepsOnly { inherit src; };
      in
      {
        devShells.default = pkgs.mkShell {
          inputsFrom = [ config.packages.hello-cpp config.packages.hello-rust ];
          inherit (config.checks.pre-commit-check) shellHook;
        };

        packages = {
          hello-cpp = pkgs.stdenv.mkDerivation {
            name = "hello-cpp";
            src = ./cpp;
            nativeBuildInputs = [ pkgs.cmake ];
            buildInputs = [ pkgs.boost ];
          };
          hello-rust = craneLib.buildPackage { inherit cargoArtifacts src; };

          hello-rust-doc = craneLib.cargoDoc {
            inherit cargoArtifacts src;
          };
        };

        checks = config.packages // {
          hello-rust-audit = craneLib.cargoAudit {
            inherit (inputs) advisory-db;
            inherit src;
          };

          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # Rust
              clippy.enable = true;
              rustfmt.enable = true;

              # Nix
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              statix.enable = true;

              # Shell
              shellcheck.enable = true;
              shfmt.enable = true;
            };
            settings.rust.cargoManifestPath = "./rust/Cargo.toml";
          };
        };
      };
  };
}
