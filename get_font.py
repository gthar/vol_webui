"""
Download, subset and put in the right direction the UI font
"""

import argparse
import sys
import tempfile

import requests

__requires__ = 'fonttools'
from pkg_resources import load_entry_point


def get_and_subset(font_uri, kept_chars, out_file):
    """
    Download, subset and put in the right direction the UI font
    """
    font_subset = load_entry_point('fonttools', 'console_scripts', 'pyftsubset')
    print("downloading font")
    req = requests.get(font_uri, allow_redirects=True)
    with tempfile.NamedTemporaryFile('wb') as tmp:
        tmp.write(req.content)
        print("subsetting font")
        font_subset([
            tmp.name,
            "--text=" + kept_chars,
            "--output-file=" + out_file])


def main():
    """
    Parse arguments and to the thing
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--font_orig", type=str)
    parser.add_argument("--kept_chars", type=str)
    parser.add_argument("--out_font", type=str)
    args = parser.parse_args()
    get_and_subset(args.font_orig, args.kept_chars, args.out_font)
    return 0


if __name__ == '__main__':
    sys.exit(main())
