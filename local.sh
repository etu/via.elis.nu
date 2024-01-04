#! /usr/bin/env nix-shell
#! nix-shell -i bash -p xdg_utils

set -euo pipefail

# Build icon
rm -f src/static/img/logo.png &&
    nix run nixpkgs#inkscape -- --export-type=png                         \
                                --export-filename=src/static/img/logo.png \
                                --export-width=768                        \
                                src/static/img/logo.svg

# Build a symlink to the flyer
rm -f src/static/$(nix eval .#flyer.name --raw) &&
    nix build .#flyer --out-link src/static/$(nix eval .#flyer.name --raw)

# Install the fontawesome files
rm -rf src/themes/via/assets/scss/fontawesome src/themes/via/static/fonts/fontawesome
mkdir -p src/themes/via/assets/scss/fontawesome
mkdir -p src/themes/via/static/fonts/fontawesome
install -m 644 -D $(nix build .#fontawesome --print-out-paths --no-link)/scss/* -t src/themes/via/assets/scss/fontawesome
install -m 644 -D $(nix build .#fontawesome --print-out-paths --no-link)/webfonts/* -t src/themes/via/static/fonts/fontawesome

# Navigate to directory
cd src/

# Open browser
sleep 1 && xdg-open "http://localhost:1313/" &

# Run pinned version of hugo
nix run .#hugo -- server --logLevel debug --disableFastRender
