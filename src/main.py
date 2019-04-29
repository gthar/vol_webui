"""
Server part of the app. Communicate with the client through WebSockets
"""

import argparse
import asyncio
import functools
import json
import sys

import alsaaudio
import websockets


# This two will be hardcoded by the `build.sh` script. This allows me to have
# the client javascript sent as a static file
INSTALL_DIR = None
PORT = None


def query_mixer(mixer_name):
    """
    Query the current state of the mixer
    input: mixer_name
    output: a tuple with the volume (0-100) and the mute state (0/1)
    """
    mixer = alsaaudio.Mixer(mixer_name)
    vol, _ = mixer.getvolume()
    mute, _ = mixer.getmute()
    return vol, mute


async def broadcast(connected, msg):
    """
    Given a list of connected clients and a message, send the message to all
    of them
    """
    for socket in connected:
        await socket.send(msg)


def mk_msg(val_type, value):
    """
    Given a type of message (vol/mute) and its value, create a JSON message
    for it
    """
    return json.dumps({'type': val_type, 'value': value})


async def producer(mixer, card, connected):
    """
    Given a mixer, a card and a list of connected clients, watch for changes in
    volume and mute state and broadcast any changes to all clients
    """

    print("starting monitor loop")
    cmd = INSTALL_DIR + "/bin/alsa_events"
    vol, mute = query_mixer(mixer)

    proc = await asyncio.create_subprocess_exec(
        cmd, card,
        stdout=asyncio.subprocess.PIPE
    )
    async for _ in proc.stdout:
        new_vol, new_mute = query_mixer(mixer)

        if new_vol != vol:
            print("vol changed to", new_vol)
            await broadcast(connected, mk_msg('volume', new_vol))
            vol = new_vol

        if new_mute != mute:
            print("mute changed to", new_mute)
            await broadcast(connected, mk_msg('mute', new_mute))
            mute = new_mute

    returncode = await proc.wait()
    return returncode


async def handler(websocket, _, connected, mixer):
    """
    WebSocket handler. Watch for changes in the clients and update the volume
    accordingly
    """
    connected.add(websocket)
    try:
        vol, mute = query_mixer(mixer)
        await websocket.send(mk_msg('volume', vol))
        await websocket.send(mk_msg('mute', mute))

        async for msg in websocket:
            data = json.loads(msg)
            mixer = alsaaudio.Mixer(mixer)

            if data['type'] == 'volume':
                mixer.setvolume(int(data['value']))

            elif data['type'] == 'mute':
                mute, _ = mixer.getmute()
                mixer.setmute(not mute)

            else:
                print("unsupported event: {}", data)

    finally:
        connected.remove(websocket)


def main():
    """
    Parse the arguments and start the server
    """

    parser = argparse.ArgumentParser(description="Volume Web UI")
    parser.add_argument("--host", type=str, default='localhost')
    parser.add_argument("--mixer", type=str, default='Master')
    parser.add_argument("--card", type=str, default='hw:0')
    args = parser.parse_args()

    connected = set()
    loop = asyncio.get_event_loop()
    loop.create_task(producer(args.mixer, args.card, connected))
    loop.run_until_complete(websockets.serve(
        functools.partial(handler, connected=connected, mixer=args.mixer),
        args.host,
        PORT
    ))
    loop.run_forever()


if __name__ == '__main__':
    sys.exit(main())
