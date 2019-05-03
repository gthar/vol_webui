# vol_webui

Remote Web UI interface to control the volume of my RaspberryPi from my phone
Intended to be run by the user `volume`.

Create if needed with: `useradd -M -G audio -s /usr/sbin/nologin volume`

## Build and install
make

* render_template: script use to render jinja2 templates
* install.sh: copy the built files and install it with stow

## Build/install dependencies
* fonttools
* jinja2
* SASS
* minify
* alsa
* gcc
* Google Closure Compiler
* wget

## Run dependencies
* what is specified in requirements.txt
* alsa
* nginx

## TODO
* Use a proper logger
* Test server on the pi
* install target
