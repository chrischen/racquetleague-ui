#!/bin/sh
# Link the DinkHunt labeler UI bundle into this image's build context.
#
# The labeler stays an isolated project (rescript 12 / React 19, its own
# repo); rlui only serves its BUILT bundle at /labeler (see server.js).
# Run this before `docker build`, after building the bundle for the subpath:
#
#   cd ../dinkhunt/labeler && \
#     LABELER_UI_BASE=/labeler/ VITE_LABELER_BASE=/labeler-api npm run build:web
#   cd ../../racquetleague-ui && sh scripts/copy-labeler-dist.sh
#
# labeler-dist/ is gitignored; the Dockerfile's `COPY . .` picks it up. If it
# is absent the image simply ships without /labeler (server.js checks).
set -eu
src="${LABELER_DIST:-../dinkhunt/labeler/web/dist}"
if [ ! -f "$src/index.html" ]; then
  echo "error: $src/index.html not found — build the labeler bundle first (see header)" >&2
  exit 1
fi
if ! grep -q '/labeler/assets/' "$src/index.html"; then
  echo "error: $src was built for the root path, not /labeler/ — rebuild with LABELER_UI_BASE=/labeler/" >&2
  exit 1
fi
rm -rf labeler-dist
cp -R "$src" labeler-dist
echo "labeler-dist/ <- $src ($(find labeler-dist -type f | wc -l | tr -d ' ') files)"
