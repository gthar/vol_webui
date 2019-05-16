progname = vol_webui
build_dir = build
# prefix = /usr/local
prefix = $(build_dir)
#venv_dir = /usr/local/opt/virtualenvs
venv_dir = /home/rilla/Code/python
#venv = $(venv_dir)/volume_ctl
venv = $(venv_dir)/env
nginx_sites = /etc/nginx/sites-enabled

stow_dir = $(prefix)/stow
install_dir = $(stow_dir)/$(progname)

ui_port = 4567
ws_port = 6789
ws_host = 0.0.0.0
user = volume
card = hw:0
device = default
mixer = Digital
kept_chars = "0123456789M()"

J2C = python render_template.py
JSC = closure-compiler
CSSC = sass
TTFC = pyftsubset
HTMLC = minify
STOW = stow

JSC_OPTS = --compilation_level ADVANCED_OPTIMIZATIONS
CSSC_OPTS = --style compressed --sourcemap=none
TTFC_OPTS = --text=$(kept_chars)
STOW_OPTS = --dir $(stow_dir) --target $(prefix)

font_uri = https://fonts.gstatic.com/s/opensans/v16/mem8YaGs126MiZpBA-UFVZ0e.ttf

src_dir = src
server_src = $(src_dir)/server
client_src = $(src_dir)/client

daemon_template = $(server_src)/vol_webui_d.py.jinja2

nginx_template = $(src_dir)/nginx.conf.jinja2
unit_template = $(src_dir)/$(progname).service.jinja2

index_template = $(client_src)/index.html.jinja2
js_src = $(client_src)/main.js
style_src = $(client_src)/style.scss
icon_src = $(client_src)/icon.svg

share = share/$(progname)
build_share = $(build_dir)/$(share)
install_share = $(prefix)/$(share)

nginx_conf = nginx.conf
build_nginx_conf = $(build_share)/$(nginx_conf)
install_nginx_conf = $(install_share)/$(nginx_conf)

www = www
build_www = $(build_share)/$(www)
install_www = $(install_share)/$(www)

tmp_dir = temp
tmp_index = $(tmp_dir)/index.html.jinja2

index_html = $(tmp_dir)/index.html
main_js = $(tmp_dir)/main.js
style = $(tmp_dir)/style.css
font = $(build_www)/font.ttf

main_page = $(build_www)/index.html

systemd_dir = $(build_dir)/lib/systemd/system
systemd_unit = $(systemd_dir)/$(progname).service

bin_dir = $(build_dir)/bin
server = $(bin_dir)/vol_webui_d.py

full_font = $(tmp_dir)/full_font.ttf

activate_venv = . $(venv)/bin/activate
py_requirements = requirements.txt
py_version = 3.7
py_path = `which python$(py_version)`
bash = '\#!/usr/bin/env bash'
interpreter = $(venv)/bin/python$(py_version)

all: $(server) client system

client: $(main_page) $(font)

system: $(build_nginx_conf) $(systemd_unit)

$(server): $(daemon_template)
	@echo --- preparing server script
	@mkdir -p $(bin_dir)
	$(J2C) $(daemon_template) $(daemon) \
		--port $(ws_port) \
		--prefix \"$(prefix)\" \
		--interpreter $(interpreter)
	chmod +x $(daemon)

$(full_font):
	@echo --- retrieving font
	@mkdir -p $(tmp_dir)
	wget -O $(full_font) $(font_uri)

$(font): $(full_font)
	@echo --- subsetting font
	@mkdir -p $(build_www)
	$(TTFC) $(full_font) $(TTFC_OPTS) --output-file=$(font)

$(main_page): $(index_html)
	echo $(main_page)
	@echo --- minifying index.html
	@mkdir -p $(build_www)
	$(HTMLC) --output $(main_page) $(index_html)

$(index_html): $(index_template) $(main_js) $(style) $(icon_src)
	@echo --- rendering index.html
	@mkdir -p $(tmp_dir)
	@cp $(index_template) $(tmp_index)
	@cp $(icon_src) $(tmp_dir)
	$(J2C) $(tmp_index) $(index_html)

$(main_js): $(js_src)
	@echo --- building main.js
	@mkdir -p $(tmp_dir)
	$(eval tmp := $(shell mktemp))
	@echo 'const port = $(ws_port);' > $(tmp)
	$(JSC) $(JSC_OPTS) --js $(tmp) --js $(js_src) --js_output_file $(main_js)
	@rm $(tmp)

$(style): $(style_src)
	@echo -- building style.css
	@mkdir -p $(tmp_dir)
	$(CSSC) $(CSSC_OPTS) $(style_src) $(style)

$(build_nginx_conf): $(nginx_template)
	@echo --- rendering nginx config file
	@mkdir -p $(build_share)
	$(J2C) $(nginx_template) $(build_nginx_conf) \
		--port $(ui_port) \
		--web_dir $(install_www)

$(systemd_unit): $(unit_template)
	@echo --- rendering systemd unit file
	@mkdir -p $(systemd_dir)
	$(J2C) $(unit_template) $(systemd_unit) \
	    --user $(user) \
	    --prefix $(prefix) \
	    --host $(ws_host) \
	    --card $(card) \
	    --device $(device) \
	    --mixer $(mixer)

install:
	$(activate_venv); \
		pip install -r $(py_requirements)
	mkdir -p $(install_dir)
	cp -r $(build_dir)/* $(install_dir)
	$(STOW) $(STOW_OPTS) $(progname)
	systemctl enable $(progname).service
	systemctl start $(progname).service
	ln -fs $(install_nginx_conf) $(nginx_sites)/$(progname).conf
	systemctl restart nginx.service

clean:
	rm -rf $(tmp_dir)

reset: clean
	rm -rf $(build_dir)
