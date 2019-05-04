# vol_webui

Remote Web UI interface to control the volume of my RaspberryPi from my phone
Intended to be run by the user `volume`.

Create if needed with: `useradd -M -G audio -s /usr/sbin/nologin volume`

## Build and install
In other not to bloat my Pi installation and to avoid the hassle of
cross-compiling C code, I've decided to build most of this from my laptop, then
transfer the filed to the Pi and compile the C code there.

Make install creates a virtualenv for the package dependencies and installs the
whole thing with stow.

* `make remote clean`
* copy over to the RaspberryPi and continue there
* `make compiled clean`
* `sudo make install`

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
* systemd
* alsa
* nginx
* python3.7

## TODO
* Use a proper logger
* Test server on the pi
