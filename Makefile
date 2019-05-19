progname = vol_webui
build_dir = build
sites_enabled = /etc/nginx/sites-enabled
sites_available = /etc/nginx/sites-available

ui_port = 4567
ws_port = 6789
kept_chars = "0123456789M()"

J2C = python render_template.py
JSC = closure-compiler
CSSC = sass
TTFC = pyftsubset
HTMLC = minify

JSC_OPTS = --compilation_level ADVANCED_OPTIMIZATIONS
CSSC_OPTS = --style compressed --sourcemap=none
TTFC_OPTS = --text=$(kept_chars)

src = src
nginx_template = $(src)/nginx.conf.jinja2
index_template = $(src)/index.html.jinja2
js_src = $(src)/main.js
style_src = $(src)/style.scss
icon_src = $(src)/icon.svg
font_uri = https://fonts.gstatic.com/s/opensans/v16/mem8YaGs126MiZpBA-UFVZ0e.ttf

nginx_conf = nginx.conf
build_nginx_conf = $(build_dir)/$(nginx_conf)
install_nginx_conf = $(sites_available)/$(progname).conf

build_www = $(build_dir)/www
install_www = /www/$(progname)

tmp_dir = temp
tmp_index = $(tmp_dir)/index.html.jinja2

full_font = $(tmp_dir)/full_font.ttf
index_html = $(tmp_dir)/index.html
main_js = $(tmp_dir)/main.js
style = $(tmp_dir)/style.css

main_page = $(build_www)/index.html
font = $(build_www)/font.ttf

all: $(main_page) $(font) $(build_nginx_conf)

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
	@mkdir -p $(build_dir)
	$(J2C) $(nginx_template) $(build_nginx_conf) \
		--port $(ui_port) \
		--web_dir $(install_www)

install:
	cp -r $(build_www) $(install_www)
	cp $(build_nginx_conf) $(install_nginx_conf)
	ln -fs $(install_nginx_conf) $(sites_enabled)/$(progname).conf

clean:
	rm -rf $(tmp_dir)

reset: clean
	rm -rf $(build_dir)
