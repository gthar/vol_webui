# vol_webui

Remote Web UI interface to control the volume of my RaspberryPi from my phone
Intended to be run by the user `volume`.

Create if needed with: `useradd -M -G audio -s /usr/sbin/nologin volume`

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
* Use a proper logger
* Test server on the pi
* install.sh
* gitignore
* use a makefile
