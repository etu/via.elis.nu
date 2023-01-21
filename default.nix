{ ... }:

let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/befc83905c965adfd33e5cae49acb0351f6e0404.tar.gz";
    sha256 = "0m0ik7z06q3rshhhrg2p0vsrkf2jnqcq5gq1q6wb9g291rhyk6h2";
  }) {};

  domain = "via.elis.nu";
  email = "via@elis.nu";

in pkgs.stdenv.mkDerivation {
  name = domain;

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
    qrencode -m 9 -s 9 -l H -o qrcode_plain_web.png --foreground "2d7f35" "https://${domain}"
    qrencode -m 9 -s 9 -l H -o qrcode_plain_mail.png --foreground "2d7f35" "mailto:${email}?subject=Intresserad vegan i Arvika 🌱"

    # Embed description on the QR code
    convert qrcode_plain_web.png -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf -gravity north -pointsize 36 -fill "#2d7f35" -annotate +0+10 "Hemsida:" qrcode_header_web.png
    convert qrcode_plain_mail.png -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf -gravity north -pointsize 36 -fill "#2d7f35" -annotate +0+10 "Kontakt:" qrcode_header_mail.png

    # Embed contents on the QR code
    convert qrcode_header_web.png -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf -gravity south -pointsize 36 -fill "#2d7f35" -annotate +0+10 "${domain}" qrcode_web.png
    convert qrcode_header_mail.png -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf -gravity south -pointsize 36 -fill "#2d7f35" -annotate +0+10 "${email}" qrcode_mail.png

    # Publish org files
    env HOME=. emacs --batch --load=publish.el
  '';

  installPhase = ''
    mkdir $out
    cp -v output/* $out
  '';
}
