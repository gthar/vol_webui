# vol_webui

Remote Web UI interface to control the volume of my RaspberryPi from my phone
Intended to be used with the `vol_webui` service from https://github.com/gthar/alsavolctl. This Web UI should receive WebSocket messages from that service. Make sure the port matches.

## Build and install
First install https://github.com/gthar/alsavolctl in the target virtualenv.

* `make`
* copy over to the RaspberryPi and continue there
* `sudo make install`

## Install dependencies
* fonttools
* jinja2
* SASS
* minify
* Google Closure Compiler
* wget

## Run dependencies
* nginx
* https://github.com/gthar/alsavolctl

## TODO
* make websockets work with zeroconf (avahi)
