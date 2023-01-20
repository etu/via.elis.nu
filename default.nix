{ pkgs ? import <nixpkgs> {}, stdenv ? pkgs.stdenv }:

stdenv.mkDerivation {
  name = "arvika-vegans";

  src = ./.;

  nativeBuildInputs = [
    pkgs.inkscape
    pkgs.nodePackages.svgo
  ];

  buildPhase = ''
    svgo logo.svg
    inkscape --export-type=png --export-filename=logo.png logo.svg
  '';

  installPhase = ''
    mkdir $out
    cp -v logo.png logo.svg $out
  '';
}
