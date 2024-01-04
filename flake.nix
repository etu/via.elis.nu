{
  description = "etu/via.elis.nu";

  inputs.flake-utils.url = "flake-utils";

  outputs = {
    flake-utils,
    nixpkgs,
    self,
    ...
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import nixpkgs {inherit system;};
      color = "2d7f35"; # Color used for qr codes and such
      domain = "via.elis.nu";
      email = "via@elis.nu";
    in {
      packages.plain-flag-flyer-a5 =
        pkgs.runCommandNoCC "plain-flag-flyer-a5" {
          nativeBuildInputs = [pkgs.inkscape];
        } ''
          inkscape --export-type=svg            \
                   --export-filename=output.svg \
                   --vacuum-defs                \
                   --export-plain-svg           \
                   --export-text-to-path ${./flag-flyer-a5.svg}

          mv output.svg $out
        '';

      packages.hugo = pkgs.symlinkJoin {
        name = "hugo-${pkgs.hugo.version}-dart-sass-embedded-${pkgs.dart-sass.version}-bundle";

        buildInputs = [pkgs.makeWrapper];
        paths = [pkgs.hugo pkgs.dart-sass];

        postBuild = "wrapProgram $out/bin/hugo --prefix PATH : ${pkgs.dart-sass}/bin";

        meta.mainProgram = "hugo";
      };

      packages.fontawesome = let
        version = "6.5.1";
      in
        pkgs.stdenv.mkDerivation {
          pname = "fontawesome-free";
          inherit version;

          src = pkgs.fetchzip {
            url = "https://use.fontawesome.com/releases/v${version}/fontawesome-free-${version}-web.zip";
            hash = "sha256-gXXhKyTDC/Q6PBzpWRFvx/TxcUd3msaRSdC3ZHFzCoc=";
          };

          buildPhase = ":";

          installPhase = ''
            mkdir -p $out

            cp -vr scss webfonts $out
          '';
        };

      packages.flyer = let
        fontdir = "${pkgs.dejavu_fonts}/share/fonts/truetype";
        fontpath = "${fontdir}/DejaVuSans.ttf";
        fontsize = 46;
      in
        pkgs.stdenv.mkDerivation {
          name = "flyer.pdf";
          src = ./.;

          nativeBuildInputs = [
            pkgs.imagemagick
            pkgs.inkscape
            pkgs.pngquant
            pkgs.qrencode
            pkgs.typst
          ];

          buildPhase = ''
            # Export SVG to PNG
            inkscape --export-type=png                \
                     --export-filename=logo_flyer.png \
                     --export-width=2480              \
                     src/static/img/logo.svg


            # Generate QR code with link
            qrencode -m 9 -s 9 -l H -o qrcode_plain_web.png  \
                     --foreground "${color}"                 \
                     "https://${domain}"

            qrencode -m 9 -s 9 -l H -o qrcode_plain_mail.png \
                     --foreground "${color}"                 \
                     "mailto:${email}?subject=Intresserad vegan i Arvika 🌱"


            # Embed description on the QR code
            convert qrcode_plain_web.png                     \
                    -font ${fontpath}                        \
                    -gravity north                           \
                    -pointsize ${builtins.toString fontsize} \
                    -fill "#${color}"                        \
                    -annotate +0+10                          \
                    "Hemsida:"                               \
                    qrcode_header_web.png

            convert qrcode_plain_mail.png                    \
                    -font ${fontpath}                        \
                    -gravity north                           \
                    -pointsize ${builtins.toString fontsize} \
                    -fill "#${color}"                        \
                    -annotate +0+10                          \
                    "Kontakt:"                               \
                    qrcode_header_mail.png


            # Embed contents on the QR code
            convert qrcode_header_web.png                    \
                    -font ${fontpath}                        \
                    -gravity south                           \
                    -pointsize ${builtins.toString fontsize} \
                    -fill "#${color}"                        \
                    -annotate +0+10                          \
                    "${domain}"                              \
                    qrcode_web.png

            convert qrcode_header_mail.png                   \
                    -font ${fontpath}                        \
                    -gravity south                           \
                    -pointsize ${builtins.toString fontsize} \
                    -fill "#${color}"                        \
                    -annotate +0+10                          \
                    "${email}"                               \
                    qrcode_mail.png


            # Optimize flyer images before embedding the pdf.
            pngquant --skip-if-larger --verbose --strip logo_flyer.png &&
              rm logo_flyer.png &&
              mv logo_flyer-fs8.png logo_flyer.png

            pngquant --skip-if-larger --verbose --strip qrcode_web.png &&
              rm qrcode_web.png &&
              mv qrcode_web-fs8.png qrcode_web.png

            pngquant --skip-if-larger --verbose --strip qrcode_mail.png &&
              rm qrcode_mail.png &&
              mv qrcode_mail-fs8.png qrcode_mail.png

            # Build the PDF
            typst compile flyer.typst --font-path ${fontdir}
          '';

          installPhase = ''
            mv flyer.pdf $out
          '';
        };

      packages.website = pkgs.stdenv.mkDerivation {
        name = domain;

        src = ./src;

        nativeBuildInputs = [
          pkgs.imagemagick
          pkgs.inkscape
          pkgs.pngquant
          self.packages.${system}.hugo
        ];

        buildPhase = ''
          # Export SVG to PNG
          inkscape --export-type=png                     \
                   --export-filename=static/img/logo.png \
                   --export-width=768                    \
                   static/img/logo.svg

          # Optimize PNG logo before publishing the site.
          pngquant --skip-if-larger --verbose --strip static/img/logo.png &&
            rm static/img/logo.png &&
            mv static/img/logo-fs8.png static/img/logo.png

          # Copy flyer to static output
          cp ${self.packages.${system}.flyer} static/${self.packages.${system}.flyer.name}

          # Install fontawesome resources
          install -m 644 -D ${self.packages.${system}.fontawesome}/scss/* -t themes/via/assets/scss/fontawesome
          install -m 644 -D ${self.packages.${system}.fontawesome}/webfonts/* -t themes/via/static/fonts/fontawesome

          # Build page
          hugo --logLevel debug
        '';

        installPhase = ''
          cp -vr public/ $out

          # Set domain for github pages
          echo ${domain} > $out/CNAME
        '';
      };

      formatter = pkgs.alejandra;
    });
}
