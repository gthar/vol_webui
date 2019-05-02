install_dir = /home/rilla/Code/python/vol_webui/build
build_dir = build

ui_port = 4567
ws_port = 6789
ws_host = localhost
user = volume
mixer = Master
card = hw:0

font_uri = https://fonts.gstatic.com/s/opensans/v16/mem8YaGs126MiZpBA-UFVZ0e.ttf

src_dir = src
server_src = $(src_dir)/server
client_src = $(src_dir)/client

monitor_src = $(server_src)/alsa_events.c
daemon_src = $(server_src)/main.py

index_src = $(client_src)/index.jinja2
js_src = $(client_src)/main.js
style_src = $(client_src)/style.scss
icon_src = $(client_src)/icon.svg

share = $(build_dir)/share/vol_webui
www_dir = $(share)/www
systemd_dir=$(build_dir)/lib/systemd/system

all: server client system

server: daemon alsa_monitor

client: static_page font

system: nginx systemd_unit

daemon: $(server_src)/main.py
	@echo --- preparing server script
	mkdir -p $(build_dir)/bin
	build_scripts/build_daemon.sh \
		src/server/main.py \
		$(build_dir)/bin/vol_webui.py \
		$(ws_port) \
		$(install_dir)
	chmod +x $(build_dir)/bin/vol_webui.py

alsa_monitor: $(server_src)/alsa_events.c
	@echo --- building alsa monitorer
	mkdir -p $(build_dir)/bin
	gcc src/server/alsa_events.c \
		-std=gnu99 -Wall -pedantic -Wextra \
		-I/usr/include/alsa \
		-o $(build_dir)/bin/alsa_events \
		-lasound

build_env: build_requirements.txt
	@echo --- preparing virtual environtment to build
	virtualenv build_env
	. build_env/bin/activate; \
	pip install -r build_requirements.txt

static_page: $(index_src) $(js_src) $(style_src) $(icon_src) build_env
	@echo --- building static page
	mkdir -p $(www_dir)
	. build_env/bin/activate; \
	python build_scripts/build_page.py \
	   --in_js $(js_src) \
	   --port $(ws_port) \
	   --in_scss $(style_src) \
	   --in_svg $(icon_src) \
	   --in_jinja $(index_src) \
	   --out_index $(www_dir)/index.html

font: build_env
	@echo --- retrieving and preparing font
	mkdir -p $(www_dir)
	. build_env/bin/activate; \
	python build_scripts/get_font.py \
		--font_orig $(font_uri) \
		--kept_chars "0123456789M()" \
		--out_font $(www_dir)/open_sans.ttf

nginx: $(src_dir)/nginx.jinja2 build_env
	@echo --- rendering nginx config file
	mkdir -p $(share)
	. build_env/bin/activate; \
	python build_scripts/render_nginx_conf.py \
		--in_file $(src_dir)/nginx.jinja2 \
		--port $(ui_port) \
		--install_dir $(install_dir) \
		--out_file $(share)/nginx.conf

systemd_unit: $(src_dir)/systemd_unit.jinja2 build_env
	@echo --- rendering systemd unit file
	mkdir -p $(systemd_dir)
	. build_env/bin/activate; \
	python build_scripts/render_systemd_unit.py \
	    --in_file $(src_dir)/systemd_unit.jinja2 \
	    --out_file $(systemd_dir)/vol_webui.service \
	    --install_dir $(install_dir) \
	    --user $(user) \
	    --ws_host $(ws_host) \
	    --mixer $(mixer) \
	    --card $(card)

clean:
	rm -r $(build_dir)
	rm -r build_env
