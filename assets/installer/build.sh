#!/usr/bin/env bash
# Regenerate the Anaconda branding PNGs from the SVG sources in this directory.
# Requires ImageMagick 7 (`magick`) built with librsvg.
# File names and sizes match fedora-logos' /usr/share/anaconda/pixmaps/*.png.
set -euo pipefail
cd "$(dirname "$0")"
render() { # name width height
    magick -background none -density 96 "RSVG:$1.svg" -resize "$2x$3!" \
        -define png:color-type=6 "PNG32:$1.png"
    magick identify -format '%f %wx%h\n' "$1.png"
}
render sidebar-bg      406 767
render sidebar-logo    150  69
render topbar-bg      1040 132
render anaconda_header 119  36
