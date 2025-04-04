#! /usr/bin/env nix-shell
#! nix-shell -i bash -p xdg-utils

set -euo pipefail

# Build the theme for the spcified page and place the symlink in the correct location.
nix build .#theme --out-link "src/themes/$(nix eval .#theme.theme-name --raw)"

# Build icon
rm -f src/static/img/logo.png &&
    nix run nixpkgs#inkscape -- --export-type=png                         \
                                --export-filename=src/static/img/logo.png \
                                --export-width=768                        \
                                src/static/img/logo.svg

# Navigate to directory
cd src/

# Open browser
sleep 1 && xdg-open "http://localhost:1313/" &

# Run pinned version of hugo
nix run .#hugo -- server --logLevel debug --disableFastRender --gc
