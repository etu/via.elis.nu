{
  description = "etu/via.elis.nu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      packages = flake-utils.lib.flattenTree {
        default = let
          domain = "via.elis.nu";
          email = "via@elis.nu";
        in
          pkgs.stdenv.mkDerivation {
            name = domain;

            src = ./.;

            nativeBuildInputs = [
              pkgs.imagemagick
              pkgs.inkscape
              pkgs.pngquant
              pkgs.qrencode

              ((pkgs.emacsPackagesFor pkgs.emacs-nox).emacsWithPackages (epkgs:
                with epkgs; [
                  org
                ]))

              (pkgs.texlive.combine {
                inherit
                  (pkgs.texlive)
                  scheme-basic
                  babel-swedish
                  booktabs
                  capt-of
                  cm-super
                  etoolbox
                  hyphen-swedish
                  parskip
                  ulem
                  wrapfig
                  ;
              })
            ];

            buildPhase = ''
              # Export SVG to PNG
              inkscape --export-type=png --export-filename=src/logo.png --export-width=768 src/logo.svg
              inkscape --export-type=png --export-filename=src/logo_flyer.png --export-width=2480 src/logo.svg

              # Generate QR code with link
              qrencode -m 9 -s 9 -l H -o src/qrcode_plain_web.png --foreground "2d7f35" "https://${domain}"
              qrencode -m 9 -s 9 -l H -o src/qrcode_plain_mail.png --foreground "2d7f35" "mailto:${email}?subject=Intresserad vegan i Arvika 🌱"

              # Embed description on the QR code
              convert src/qrcode_plain_web.png -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf -gravity north -pointsize 36 -fill "#2d7f35" -annotate +0+10 "Hemsida:" src/qrcode_header_web.png
              convert src/qrcode_plain_mail.png -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf -gravity north -pointsize 36 -fill "#2d7f35" -annotate +0+10 "Kontakt:" src/qrcode_header_mail.png

              # Embed contents on the QR code
              convert src/qrcode_header_web.png -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf -gravity south -pointsize 36 -fill "#2d7f35" -annotate +0+10 "${domain}" src/qrcode_web.png
              convert src/qrcode_header_mail.png -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf -gravity south -pointsize 36 -fill "#2d7f35" -annotate +0+10 "${email}" src/qrcode_mail.png

              # Optimize PNG logo before publishing the site.
              pngquant --skip-if-larger --verbose --strip src/logo.png && rm src/logo.png && mv src/logo-fs8.png src/logo.png

              # Optimize flyer images before publishing the site.
              pngquant --skip-if-larger --verbose --strip src/logo_flyer.png && rm src/logo_flyer.png && mv src/logo_flyer-fs8.png src/logo_flyer.png
              pngquant --skip-if-larger --verbose --strip src/qrcode_web.png && rm src/qrcode_web.png && mv src/qrcode_web-fs8.png src/qrcode_web.png
              pngquant --skip-if-larger --verbose --strip src/qrcode_mail.png && rm src/qrcode_mail.png && mv src/qrcode_mail-fs8.png src/qrcode_mail.png

              # Publish org files
              env HOME=. emacs --batch --load=publish.el
            '';

            installPhase = ''
              mkdir $out
              cp -rv output/* $out
            '';
          };
      };

      formatter = pkgs.alejandra;
    });
}
