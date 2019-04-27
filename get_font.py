#!/usr/bin/env python3

import argparse
import requests
import sys
import tempfile

__requires__ = 'fonttools'
from pkg_resources import load_entry_point


def main(args):
    font_subset = load_entry_point('fonttools', 'console_scripts', 'pyftsubset')
    print("downloading font")
    r = requests.get(args.font_orig, allow_redirects=True)
    with tempfile.NamedTemporaryFile('wb') as tmp:
        tmp.write(r.content)
        print("subsetting font")
        font_subset([
           tmp.name,
           "--text=" + args.kept_chars,
           "--output-file=" + args.out_font])


parser = argparse.ArgumentParser()

parser.add_argument("--font_orig", type=str)
parser.add_argument("--kept_chars", type=str)
parser.add_argument("--out_font", type=str)


if __name__ == '__main__':
    sys.exit(main(parser.parse_args()))
