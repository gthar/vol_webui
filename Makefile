install_dir = /home/rilla/Code/python/vol_webui/build
build_dir = build

ui_port = 4567
ws_port = 6789
ws_host = localhost
user = volume
mixer = Master
card = hw:0
kept_chars = "0123456789M()"

LIBS = alsa
CFLAGS = -std=gnu99 -Wall -pedantic -Wextra `pkg-config --cflags ${LIBS}`
LDFLAGS = `pkg-config --libs ${LIBS}`

CC = gcc
J2C = python render_template.py
JSC = closure-compiler
CSSC = sass
TTFC = pyftsubset
HTMLC = minify

JSC_OPTS = --compilation_level ADVANCED_OPTIMIZATIONS
CSSC_OPTS = --style compressed --sourcemap=none
TTFC_OPTS = --text=$(kept_chars)

font_uri = https://fonts.gstatic.com/s/opensans/v16/mem8YaGs126MiZpBA-UFVZ0e.ttf

src_dir = src
server_src = $(src_dir)/server
client_src = $(src_dir)/client

monitor_src = $(server_src)/alsa_events.c
daemon_template = $(server_src)/vol_webui_d.py.jinja2

nginx_template = $(src_dir)/nginx.conf.jinja2
unit_template = $(src_dir)/vol_webui.service.jinja2

index_template = $(client_src)/index.html.jinja2
js_src = $(client_src)/main.js
style_src = $(client_src)/style.scss
icon_src = $(client_src)/icon.svg

share = $(build_dir)/share/vol_webui
nginx_conf = $(share)/nginx.conf
www_dir = $(share)/www

tmp_dir = temp
tmp_index = $(tmp_dir)/index.html.jinja2

index_html = $(tmp_dir)/index.html
main_js = $(tmp_dir)/main.js
style = $(tmp_dir)/style.css
font = $(www_dir)/open_sans.ttf

main_page = $(www_dir)/index.html

systemd_dir = $(build_dir)/lib/systemd/system
systemd_unit = $(systemd_dir)/vol_webui.service

bin_dir = $(build_dir)/bin
daemon = $(bin_dir)/vol_webui_d.py
alsa_events = $(bin_dir)/alsa_events

full_font = $(tmp_dir)/OpenSans.ttf

all: server client system

server: $(daemon) $(alsa_events)

client: $(main_page) $(font)

system: $(nginx_conf) $(systemd_unit)

$(daemon): $(daemon_template)
	@echo --- preparing server script
	mkdir -p $(build_dir)/bin
	$(J2C) $(daemon_template) $(daemon) \
		--port $(ws_port) \
		--install_dir \"$(install_dir)\"
	chmod +x $(daemon)

$(alsa_events): $(server_src)/alsa_events.c
	@echo --- building alsa monitorer
	mkdir -p $(bin_dir)
	$(CC) $(monitor_src) $(CFLAGS) -o $(alsa_events) $(LDFLAGS)

$(full_font):
	@echo --- retrieving font
	mkdir -p $(tmp_dir)
	wget -O $(full_font) $(font_uri)

$(font): $(full_font)
	@echo --- subsetting font
	$(TTFC) $(full_font) $(TTFC_OPTS) --output-file=$(font)

$(main_page): $(index_html)
	@echo --- minifying index.html
	$(HTMLC) --output $(main_page) $(index_html)

$(index_html): $(index_template) $(main_js) $(style) $(icon_src)
	@echo --- rendering index.html
	@mkdir -p $(www_dir)
	@mkdir -p $(tmp_dir)
	@cp $(index_template) $(tmp_index)
	@cp $(icon_src) $(tmp_dir)
	$(J2C) $(tmp_index) $(index_html)

$(main_js): $(js_src)
	@echo --- building main.js
	mkdir -p $(www_dir)
	$(eval tmp := $(shell mktemp))
	@echo 'const port = $(ws_port);' > $(tmp)
	$(JSC) $(JSC_OPTS) --js $(tmp) --js $(js_src) --js_output_file $(main_js)
	@rm $(tmp)

$(style): $(style_src)
	@echo -- building style.css
	mkdir -p $(www_dir)
	$(CSSC) $(CSSC_OPTS) $(style_src) $(style)

$(nginx_conf): $(nginx_template)
	@echo --- rendering nginx config file
	mkdir -p $(share)
	$(J2C) $(nginx_template) $(nginx_conf) \
		--port $(ui_port) \
		--install_dir $(install_dir)

$(systemd_unit): $(unit_template)
	@echo --- rendering systemd unit file
	mkdir -p $(systemd_dir)
	$(J2C) $(unit_template) $(systemd_unit) \
	    --user $(user) \
	    --install_dir $(install_dir) \
	    --host $(ws_host) \
	    --mixer $(mixer) \
	    --card $(card)

clean:
	rm -rf $(build_dir)
	rm -rf $(tmp_dir)
