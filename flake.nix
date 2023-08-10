{
  description = "Heise Nix Example Project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
        buildInputs = with pkgs; [
          boost
          cmake
          cargo
          rustc
        ];
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
      };
    };
  };
}
