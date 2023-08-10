{
  description = "Heise Nix Example Project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    perSystem = { config, pkgs, system, ... }: {
      devShells.default = pkgs.mkShell {
        inputsFrom = builtins.attrValues config.checks;
        inherit (config.checks.pre-commit-check) shellHook;
      };

      packages = {
        hello-cpp = pkgs.stdenv.mkDerivation {
          name = "hello-cpp";
          src = ./cpp;
          nativeBuildInputs = [ pkgs.cmake ];
          buildInputs = [ pkgs.boost ];
        };
        hello-rust = pkgs.rustPlatform.buildRustPackage {
          name = "hello-rust";
          src = ./rust;
          cargoLock.lockFile = ./rust/Cargo.lock;
        };
      };

      checks = {
        inherit (config.packages)
          hello-cpp
          hello-rust
          ;

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
