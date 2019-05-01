const inc_by = 5;
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

const sendVol = (inc) => () => {
    let new_val = parseInt(slider.value, 10) + inc;
    if (new_val < 0) {
        new_val = 0;
    }
    if (new_val > 100) {
        new_val = 100
    }
    websocket.send(JSON.stringify({
        type: 'volume',
        value: new_val
    }));
}

const sendMute = () => {
    websocket.send(JSON.stringify({type: 'mute'}));
}

slider.oninput = sendVol(0);
button.onclick = sendMute;

const actions = {'volume': setVol, 'mute': setMute};

websocket.onmessage = (event) => {
    let data = JSON.parse(event.data);
    actions[data.type](data.value);
}

const key_actions = {
    " ": sendMute,
    "m": sendMute,
    "+": sendVol(inc_by),
    "-": sendVol(-inc_by)
}

document.body.onkeypress = (event) => {
    try {
        key_actions[event.key]();
    } catch (err) {
        console.log(`no action implemented for key '${event.key}'`);
    }
}
