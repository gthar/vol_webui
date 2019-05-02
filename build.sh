#!/usr/bin/env bash

INSTALL_DIR="/home/rilla/Code/python/vol_webui/build"
WS_PORT=6789
UI_PORT=4567

mkdir -p build
mkdir -p build/bin
mkdir -p build/lib/systemd/system
mkdir -p build/share/vol_webui/www

echo --- preparing server script
function setVar {
    varName=$1
    val=$2
    sed -E "s|^(${varName} = )None(.*)$|\1${val}\2|g"
}

< src/server/main.py \
    setVar INSTALL_DIR \"${INSTALL_DIR}\" | \
    setVar PORT $WS_PORT > \
    build/bin/vol_webui.py

chmod +x build/bin/vol_webui.py

echo --- building alsa monitorer
gcc src/server/alsa_events.c \
    -std=gnu99 -Wall -pedantic -Wextra \
    -I/usr/include/alsa \
    -o build/bin/alsa_events \
    -lasound

if [ ! -d build_env ]
then
    echo --- preparing virtual environtment to build
    virtualenv build_env
    source build_env/bin/activate
    pip install -r build_requirements.txt
else
    source build_env/bin/activate
fi

echo --- building static page
python build_scripts/build_page.py \
   --in_js src/client/main.js \
   --port $WS_PORT \
   --in_scss src/client/style.scss \
   --in_svg src/client/icon.svg \
   --in_jinja src/client/index.jinja2 \
   --out_index build/share/vol_webui/www/index.html

echo --- retrieving and preparing font
python build_scripts/get_font.py \
   --font_orig https://fonts.gstatic.com/s/opensans/v16/mem8YaGs126MiZpBA-UFVZ0e.ttf \
   --kept_chars "0123456789M()" \
   --out_font build/share/vol_webui/www/open_sans.ttf

echo --- rendering nginx config file
python build_scripts/render_nginx_conf.py \
    --in_file src/nginx.jinja2 \
    --port $UI_PORT \
    --install_dir $INSTALL_DIR \
    --out_file build/share/vol_webui/nginx.conf

echo --- rendering systemd unit file
python build_scripts/render_systemd_unit.py \
    --in_file src/systemd_unit.jinja2 \
    --out_file build/lib/systemd/system/vol_webui.service \
    --install_dir $INSTALL_DIR \
    --user volume \
    --ws_host localhost \
    --mixer Master \
    --card hw:0
