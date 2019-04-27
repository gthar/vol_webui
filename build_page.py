#!/usr/bin/env python3

import argparse
import subprocess
import sys
import tempfile

import htmlmin
import jinja2
import sass


def make_js(in_js, port):
    print("minimizing JavaScript")
    with tempfile.NamedTemporaryFile() as tmp:
        tmp.write("const port = {};".format(port).encode())
        tmp.flush()
        proc = subprocess.run([
            "/usr/bin/closure-compiler",
            "--compilation_level", "ADVANCED_OPTIMIZATIONS",
            tmp.name, in_js
        ], stdout=subprocess.PIPE)
        js = proc.stdout.decode().strip()
    return js


def make_css(in_scss):
    print("compiling SASS")
    return sass.compile(filename=in_scss, output_style="compressed").strip()


def render_template(templ_str, css, js, svg):
    print("rendering template")
    templ = jinja2.Template(templ_str)
    html = templ.render(style_css=css, main_js=js, icon_svg=svg)
    return htmlmin.minify(html)


def make_html(in_jinja, in_js, in_scss, in_svg, port):
    js = make_js(in_js, port)
    css = make_css(in_scss)
    svg = open(in_svg).read()
    templ_str = open(in_jinja).read()
    return render_template(templ_str, css, js, svg)


def main(args):
    html = make_html(
            args.in_jinja,
            args.in_js,
            args.in_scss,
            args.in_svg,
            args.port)
    print("saving index.html")
    open(args.out_index, 'w').write(html)


parser = argparse.ArgumentParser()

parser.add_argument("--in_js", type=str)
parser.add_argument("--port", type=int)
parser.add_argument("--in_scss", type=str)
parser.add_argument("--in_svg", type=str)
parser.add_argument("--in_jinja", type=str)

parser.add_argument("--out_index", type=str)


if __name__ == '__main__':
    sys.exit(main(parser.parse_args()))
