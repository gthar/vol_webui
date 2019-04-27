const ip = '127.0.0.1';
//const ip = location.hostname;
const url = `ws://${ip}:${port}/`

const vol_re = /\bvol-.+?\b/g;

const widget = document.getElementById("vol-widget");
const currentVol = document.getElementById("current-vol");
const slider = document.getElementsByTagName('input')[0];
const button = document.getElementsByTagName('button')[0];


const setMute = (x) => {
    if (x) {
        widget.classList.add("mute");
        slider.disabled = true;
        console.log("muted")
    } else {
        widget.classList.remove("mute");
        slider.disabled = false;
        console.log("unmuted");
    }
}

const iconLevel = (vol) => {
    if (vol < 10) {
        return "vol-off";
    } else if (vol >= 10 && vol < 40) {
        return "vol-low";
    } else if (vol >= 40 && vol < 80) {
        return "vol-mid";
    } else if (vol >= 80) {
        return "vol-high";
    }
}

const setVol = (x) => {
    slider.value = x;
    currentVol.innerHTML = x;
    let vol_icon = iconLevel(x);
    if (/vol-/.test(widget.className)) {
        widget.className = widget.className.replace(vol_re, vol_icon);
    } else {
        widget.classList.add(vol_icon);
    }
    console.log("volume set to:", x);
}

var websocket = new WebSocket(url);

slider.oninput = () => {
    websocket.send(JSON.stringify({type: 'volume', value: slider.value}));
}

button.onclick = () => {
    websocket.send(JSON.stringify({type: 'mute'}));
}

const actions = {'volume': setVol, 'mute': setMute};

websocket.onmessage = (event) => {
    let data = JSON.parse(event.data);
    actions[data.type](data.value);
}
