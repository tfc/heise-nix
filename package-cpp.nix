{ stdenv, boost, cmake }:

stdenv.mkDerivation {
  name = "hello-cpp";
  src = ./cpp;
  nativeBuildInputs = [ cmake ];
  buildInputs = [ boost ];
}
