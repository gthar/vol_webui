# vol_webui

Remote Web UI interface to control the volume of my RaspberryPi from my phone
Intended to be run by the user `volume`.

## Build and install
First install https://github.com/gthar/alsavolctl in the target virtualenv.

* `make`
* copy over to the RaspberryPi and continue there
* `sudo make install`

## Build/install dependencies
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
