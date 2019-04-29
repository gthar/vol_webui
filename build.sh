#!/usr/bin/env bash

INSTALL_DIR="/home/rilla/Code/python/vol_webui/build"
PORT=6789

mkdir -p build
mkdir -p build/bin
mkdir -p build/lib/systemd/system
mkdir -p build/share/vol_webui/

echo --- preparing server script
function setVar {
    varName=$1
    val=$2
    sed -E "s|^(${varName} = )None(.*)$|\1${val}\2|g"
}

< src/main.py \
    setVar INSTALL_DIR \"${INSTALL_DIR}\" | \
    setVar PORT $PORT > \
    build/bin/vol_webui.py

chmod +x build/bin/vol_webui.py

echo --- building alsa monitorer
gcc src/alsa_events.c \
    -std=gnu99 -Wall -pedantic -Wextra \
    -I/usr/include/alsa \
    -o build/bin/alsa_events \
    -lasound

echo --- building static page
python build_page.py \
   --in_js src/main.js \
   --port $PORT \
   --in_scss src/style.scss \
   --in_svg src/icon.svg \
   --in_jinja src/index.jinja2 \
   --out_index build/share/vol_webui/index.html

echo --- retrieving and preparing font
python get_font.py \
   --font_orig https://fonts.gstatic.com/s/opensans/v16/mem8YaGs126MiZpBA-UFVZ0e.ttf \
   --kept_chars "0123456789M()" \
   --out_font build/share/vol_webui/open_sans.ttf
