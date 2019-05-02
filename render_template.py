#!/usr/bin/env python3

"""
Standalone jinja2 parser
Takes an input file, an output file and the value of the variables as optional
arguments
"""

import argparse
import sys

import jinja2


def parse_unknown(args):
    """
    Parse the list of unknown args to a dictionary
    """
    keys = args[0::2]
    values = args[1::2]
    kwargs = {k.replace('--', ''): v
              for k, v in zip(keys, values)
              if k.startswith('--')}
    return kwargs


def render_template(templ_str, kwargs):
    """
    Render from a string representing the template and a dictionary of kwargs
    """
    return jinja2.Template(templ_str).render(**kwargs)


def main():
    """
    Parse the arguments and do the thing
    """
    parser = argparse.ArgumentParser()

    parser.add_argument("input", type=str)
    parser.add_argument("output", type=str)
    args, unknown = parser.parse_known_args()

    kwargs = parse_unknown(unknown)

    templ_str = open(args.input).read()
    out_str = render_template(templ_str, kwargs)
    open(args.output, 'w').write(out_str + '\n')

    return 0


if __name__ == "__main__":
    sys.exit(main())
