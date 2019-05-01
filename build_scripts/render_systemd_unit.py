#!/usr/bin/env python3

"""
Render the systemd unit file for the daemon
"""

import argparse
import sys

import jinja2

def main():
    """
    Parse the arguments and to the thing
    """

    parser = argparse.ArgumentParser()

    parser.add_argument("--in_file", type=str)
    parser.add_argument("--out_file", type=str)
    parser.add_argument("--ws_host", type=str)
    parser.add_argument("--mixer", type=str)
    parser.add_argument("--card", type=str)
    parser.add_argument("--user", type=str)
    parser.add_argument("--install_dir", type=str)

    args = parser.parse_args()

    templ_str = open(args.in_file).read()
    templ = jinja2.Template(templ_str)

    unit_file = templ.render(
        host=args.ws_host,
        mixer=args.mixer,
        card=args.card,
        user=args.user,
        install_dir=args.install_dir)

    open(args.out_file, 'w').write(unit_file + '\n')


if __name__ == '__main__':
    sys.exit(main())
