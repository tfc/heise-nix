{
  description = "Heise Nix Example Project";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          boost
          cmake
          cargo
          rustc
        ];
      };
      packages.${system} = {
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
    };
}
