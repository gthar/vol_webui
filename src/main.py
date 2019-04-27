#!/usr/bin/env python3

import alsaaudio
import argparse
import asyncio
import functools
import json
import sys
import websockets


parser = argparse.ArgumentParser(description="Volume Web UI")
parser.add_argument("--host", type=str, default='localhost')
parser.add_argument("--mixer", type=str, default='Master')
parser.add_argument("--card", type=str, default='hw:0')


def query_mixer(mixer_name):
    m = alsaaudio.Mixer(mixer_name)
    vol, _ = m.getvolume()
    mute, _ = m.getmute()
    return vol, mute


async def broadcast(connected, msg):
    for socket in connected:
        await socket.send(msg)


def mk_msg(type, value):
    return json.dumps({'type': type, 'value': value})


async def producer(mixer, card, connected):

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


async def handler(websocket, path, connected, mixer):
    connected.add(websocket)
    try:
        vol, mute = query_mixer(mixer)
        await websocket.send(mk_msg('volume', vol))
        await websocket.send(mk_msg('mute', mute))

        async for msg in websocket:
            data = json.loads(msg)
            m = alsaaudio.Mixer(mixer)

            if data['type'] == 'volume':
                m.setvolume(int(data['value']))

            elif data['type'] == 'mute':
                mute, _ = m.getmute()
                m.setmute(not mute)

            else:
                print("unsupported event: {}", data)

    finally:
        connected.remove(websocket)


def main(args):
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
    sys.exit(main(parser.parse_args()))
