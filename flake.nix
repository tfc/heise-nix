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
    perSystem = { config, pkgs, lib, system, ... }:
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
          hello-cpp = pkgs.callPackage ./package-cpp.nix { };

          hello-rust = craneLib.buildPackage { inherit cargoArtifacts src; };

          hello-rust-doc = craneLib.cargoDoc {
            inherit cargoArtifacts src;
          };
        } // lib.optionalAttrs (lib.hasSuffix "linux" system) {
          hello-cpp-docker = pkgs.dockerTools.buildLayeredImage {
            name = "hello-cpp";
            tag = "latest";
            config.Cmd = [ "${config.packages.hello-cpp}/bin/hello-cpp" ];
          };

          hello-rust-docker = pkgs.dockerTools.buildLayeredImage {
            name = "hello-rust";
            tag = "latest";
            config.Cmd = [ "${config.packages.hello-rust}/bin/hello-rust" ];
          };
        } // lib.optionalAttrs (system != "x86_64-darwin") {
          # There is no `targetPackages.darwin.LibsystemCross` for x86_64 darwin
          hello-cpp-static = pkgs.pkgsStatic.callPackage ./package-cpp.nix { };
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
