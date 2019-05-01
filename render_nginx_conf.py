#!/usr/bin/env python3

"""
Render the NGINX config file from its template
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
    parser.add_argument("--port", type=int)
    parser.add_argument("--install_dir", type=str)

    args = parser.parse_args()

    templ_str = open(args.in_file).read()
    templ = jinja2.Template(templ_str)
    nginx_conf = templ.render(port=args.port, install_dir=args.install_dir)
    open(args.out_file, 'w').write(nginx_conf + '\n')


if __name__ == '__main__':
    sys.exit(main())
