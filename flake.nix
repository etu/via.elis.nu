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
                   --export-text-to-path ${./media/vegan-flag-flyer-a5.svg}

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

      packages.qrcode_web =
        pkgs.runCommandNoCC "qrcode_web" {
          nativeBuildInputs = [pkgs.qrencode];
        } ''
          # Generate QR code with link
          qrencode "https://${domain}"     \
                   --output=qrcode_web.svg \
                   --type=SVG              \
                   --foreground="${color}" \
                   --level=H

          mv qrcode_web.svg $out
        '';

      packages.qrcode_email =
        pkgs.runCommandNoCC "qrcode_email" {
          nativeBuildInputs = [pkgs.qrencode];
        } ''
          # Generate QR code with email
          qrencode "mailto:${email}?subject=Intresserad vegan i Arvika 🌱" \
                   --output=qrcode_email.svg                               \
                   --type=SVG                                              \
                   --foreground="${color}"                                 \
                   --level=H

          mv qrcode_email.svg $out
        '';

      packages.flyer = pkgs.stdenv.mkDerivation {
        name = "flyer.pdf";
        src = ./.;

        nativeBuildInputs = [
          pkgs.inkscape
          pkgs.liberation_ttf
        ];

        buildPhase = ''
          # Copy qr codes
          cp ${self.packages.${system}.qrcode_web} qrcode_web.svg
          cp ${self.packages.${system}.qrcode_email} qrcode_email.svg

          # Build the PDF
          inkscape --export-type=pdf --export-filename=flyer.pdf flyer.svg
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
