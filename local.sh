#! /usr/bin/env nix-shell
#! nix-shell -i bash -p python3 xdg_utils firefox

#
# Usage:
# ./local.sh
#

nix-build default.nix

if test -L result
then
    # Sleep a second and then open the browser
    sleep 1 && xdg-open "http://localhost:8000/" &

    # Launch web server
    cd result/ && python -m http.server && cd -

    # Remove symlink
    rm result
fi
