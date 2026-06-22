#!/usr/bin/env python3
"""Render a still preview PNG from an Xcursor file (no xcur2png needed).

Usage: render_cursor.py <xcursor-file> <out.png> [target-size]

Parses the Xcursor binary format, picks the image whose nominal size is
closest to the requested target (default 48), un-premultiplies the alpha and
writes a PNG via Pillow. Exits non-zero on any failure so callers can fall back.
"""
import struct
import sys

from PIL import Image

XCURSOR_IMAGE_TYPE = 0xFFFD0002


def read_images(path):
    with open(path, "rb") as fh:
        data = fh.read()

    if data[:4] != b"Xcur":
        raise ValueError("not an Xcursor file")

    _hdr, _ver, ntoc = struct.unpack_from("<III", data, 4)
    images = []
    toc_off = 16
    for i in range(ntoc):
        ctype, subtype, position = struct.unpack_from("<III", data, toc_off + i * 12)
        if ctype != XCURSOR_IMAGE_TYPE:
            continue
        # chunk header: header, type, subtype, version, width, height, xhot, yhot, delay
        _ch, _ct, nominal, _cv, width, height, _xh, _yh, _delay = struct.unpack_from(
            "<IIIIIIIII", data, position
        )
        pix_off = position + 36
        nbytes = width * height * 4
        images.append((nominal or width, width, height, data[pix_off:pix_off + nbytes]))
    if not images:
        raise ValueError("no image chunks in cursor")
    return images


def to_png(width, height, raw):
    # Xcursor stores premultiplied ARGB little-endian => bytes are B,G,R,A.
    img = Image.frombytes("RGBA", (width, height), raw, "raw", "BGRA")
    # Un-premultiply alpha for correct edges over transparency.
    px = img.load()
    for y in range(height):
        for x in range(width):
            r, g, b, a = px[x, y]
            if a and a < 255:
                r = min(255, r * 255 // a)
                g = min(255, g * 255 // a)
                b = min(255, b * 255 // a)
                px[x, y] = (r, g, b, a)
    return img


def main():
    if len(sys.argv) < 3:
        sys.exit("usage: render_cursor.py <xcursor-file> <out.png> [size]")
    src, out = sys.argv[1], sys.argv[2]
    target = int(sys.argv[3]) if len(sys.argv) > 3 else 48

    images = read_images(src)
    nominal, width, height, raw = min(images, key=lambda im: abs(im[0] - target))
    img = to_png(width, height, raw)
    img.save(out)


if __name__ == "__main__":
    main()
