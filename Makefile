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
daemon_template = $(server_src)/vol_webui_d.py.jinja2

nginx_template = $(src_dir)/nginx.conf.jinja2
unit_template = $(src_dir)/vol_webui.service.jinja2

index_src = $(client_src)/index.html
js_src = $(client_src)/main.js
style_src = $(client_src)/style.scss
icon_src = $(client_src)/icon.svg

share = $(build_dir)/share/vol_webui
nginx_conf = $(share)/nginx.conf
www_dir = $(share)/www

index_html = $(www_dir)/index.html
main_js = $(www_dir)/main.js
style = $(www_dir)/style.css
icon = $(www_dir)/icon.svg
font = $(www_dir)/open_sans.ttf

systemd_dir = $(build_dir)/lib/systemd/system
systemd_unit = $(systemd_dir)/vol_webui.service

bin_dir = $(build_dir)/bin
daemon = $(bin_dir)/vol_webui_d.py
alsa_events = $(bin_dir)/alsa_events


all: server client system

server: $(daemon) $(alsa_events)

client: $(index_html) $(main_js) $(style) $(icon) $(font)

system: $(nginx_conf) $(systemd_unit)

$(daemon): $(daemon_template)
	@echo --- preparing server script
	mkdir -p $(build_dir)/bin
	python render_template.py \
		$(daemon_template) \
		$(daemon) \
		--port $(ws_port) \
		--install_dir \"$(install_dir)\"
	chmod +x $(daemon)

$(alsa_events): $(server_src)/alsa_events.c
	@echo --- building alsa monitorer
	mkdir -p $(build_dir)/bin
	gcc src/server/alsa_events.c \
		-std=gnu99 -Wall -pedantic -Wextra \
		-I/usr/include/alsa \
		-o $(alsa_events) \
		-lasound

build_env: build_requirements.txt
	@echo --- preparing virtual environtment to build
	virtualenv build_env
	. build_env/bin/activate; \
	pip install -r build_requirements.txt

$(font): build_env
	@echo --- retrieving and preparing font
	mkdir -p $(www_dir)
	mkdir -p $(www_dir)
	. build_env/bin/activate; \
	python build_scripts/get_font.py \
		--font_orig $(font_uri) \
		--kept_chars "0123456789M()" \
		--out_font $(font)

$(index_html): $(index_src)
	mkdir -p $(www_dir)
	cp $(index_src) $(index_html)

$(main_js): $(js_src)
	@echo --- building main.js
	mkdir -p $(www_dir)
	$(eval tmp := $(shell mktemp))
	@echo 'const port = $(ws_port);' > $(tmp)
	/usr/bin/closure-compiler \
		--compilation_level ADVANCED_OPTIMIZATIONS \
		--js $(tmp) \
		--js $(js_src) \
		--js_output_file $(main_js)
	@rm $(tmp)

$(style): $(style_src)
	@echo -- building style.css
	mkdir -p $(www_dir)
	/usr/bin/sass \
		--style compressed \
		--sourcemap=none \
		$(style_src) \
		$(style)

$(icon): $(icon_src)
	mkdir -p $(www_dir)
	cp $(icon_src) $(icon)

$(nginx_conf): $(nginx_template)
	@echo --- rendering nginx config file
	mkdir -p $(share)
	python render_template.py \
		$(nginx_template) \
		$(nginx_conf) \
		--port $(ui_port) \
		--install_dir $(install_dir)

$(systemd_unit): $(unit_template)
	@echo --- rendering systemd unit file
	mkdir -p $(systemd_dir)
	python render_template.py \
	    $(unit_template) \
	    $(systemd_unit) \
	    --user $(user) \
	    --install_dir $(install_dir) \
	    --host $(ws_host) \
	    --mixer $(mixer) \
	    --card $(card)

clean:
	rm -rf $(build_dir)
	rm -rf build_env
