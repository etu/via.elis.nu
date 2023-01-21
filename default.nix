{ pkgs ? import <nixpkgs> {}, stdenv ? pkgs.stdenv }:

let
  domain = "via.elis.nu";

in stdenv.mkDerivation {
  name = "arvika-vegans";

  src = ./.;

  nativeBuildInputs = [
    pkgs.imagemagick
    pkgs.inkscape
    pkgs.nodePackages.svgo
    pkgs.qrencode

    ((pkgs.emacsPackagesFor pkgs.emacs-nox).emacsWithPackages (epkgs: with epkgs; [
      org
    ]))

    (pkgs.texlive.combine {
      inherit (pkgs.texlive) scheme-basic
        babel-swedish
        booktabs
        capt-of
        cm-super
        etoolbox
        hyphen-swedish
        parskip
        ulem
        wrapfig;
    })
  ];

  buildPhase = ''
    # Optimize SVG file
    svgo logo.svg

    # Export SVG to PNG
    inkscape --export-type=png --export-filename=logo.png --export-width=768 logo.svg
    inkscape --export-type=png --export-filename=logo_print.png --export-width=2480 logo.svg

    # Generate QR code with link
    qrencode -m 9 -s 9 -l H -o qrcode_plain.png --foreground "2d7f35" "https://${domain}"

    # Embed logo on the QR code
    magick qrcode_plain.png logo.png -resize %[fx:u.w/1.5]x%[fx:u.h/1.5] -gravity north -composite qrcode_logo.png

    # Embed text link on the QR code
    convert qrcode_logo.png -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf -gravity south -pointsize 36 -fill "#2d7f35" -annotate +0+10 "${domain}" qrcode.png

    # Publish org files
    env HOME=. emacs --batch --load=publish.el
  '';

  installPhase = ''
    mkdir $out
    cp -v output/* $out
  '';
}
