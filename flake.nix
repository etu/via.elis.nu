{
  description = "etu/via.elis.nu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-utils.url = "flake-utils";
    theme-albatross.url = "github:etu/hugo-theme-albatross";
    theme-albatross.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    flake-utils,
    nixpkgs,
    self,
    ...
  } @ inputs:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      tpkgs = inputs.theme-albatross.packages.${system};
      color = "2d7f35"; # Color used for qr codes and such
      domain = "via.elis.nu";
      email = "via@elis.nu";
    in {
      packages.hugo = tpkgs.hugo;
      packages.theme = tpkgs.theme;
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

          # install theme pinned hugo
          tpkgs.hugo
        ];

        buildPhase = ''
          # Install theme
          mkdir -p themes
          ln -s ${tpkgs.theme} themes/${tpkgs.theme.theme-name}

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
