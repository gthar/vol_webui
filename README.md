# vol_webui

Remote Web UI interface to control the volume of my RaspberryPi from my phone

## Build and install
* build_page.py: builds the static index.html to serve
* get_font.py: download and minimize the font to use (Open Sans)
* build.sh: build the server code, the page and get the font.
        Place everythin in their install directory structure
* install.sh: copy the built files and install it with stow

## Build/install dependencies
* python fonttools
* python htmlmin
* python Jinja2
* python libsass
* python requests
* alsa
* gcc
* Google Closure Compiler

## Run dependencies
* pyalsaaudio
* python websockets
* alsa
* nginx

## TODO
* Make nginx config for the static content
* Make systemd unit for the server
* Use a proper logger
* Test server on the pi
* install.sh
* gitignore
