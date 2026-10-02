#!/bin/bash
# Builds the website and puts it on the server (after the one-off
# tool/server/setup_space_cadet.sh). No sudo needed.
#
#   tool/deploy_site.sh
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER=beheer@134.209.201.232
TARGET=/var/www/space-cadet.nl/www/
"$ROOT/tool/build_site.sh"
rsync -az --delete --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r "$ROOT/build/site/" "$SERVER:$TARGET"
echo "Deployed to $TARGET"
