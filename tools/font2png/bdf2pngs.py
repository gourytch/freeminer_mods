#! /usr/bin/env python
# -*- coding: utf-8 -*-
#
#
# apt-get install pcf2bdf
# wget https://pypi.python.org/packages/source/b/bdflib/bdflib-v1.0.0.tar.gz
# wget https://raw.github.com/drj11/pypng/master/code/png.py
# pcf2bdf /usr/share/fonts/X11/misc/ter-u28b_unicode.pcf.gz >myfont.bdf
# search and correct values for fname and outname variables
# python bdfrender.py myfont.bdf
# ???
# PROFIT
#
# tool produces files myfont.meta and myfont.png
# NOTE: ONLY FOR FIXED FONTS!
#
# LICENSE: DWTFYWTPL


import sys, re, os, os.path
import bdflib.reader as reader
import png

big_palette = False
# nums = (0x00, 0x33, 0x66, 0x99, 0xCC, 0xFF) # web-palette
# nums = (0x00, 0x55, 0xAA, 0xFF)
nums = (0x00, 0x88, 0xFF)
dir = "fonts"

def render_glyph (image, glyph, x_offs, y_offs, color):
    bitmap_min_X = min(0, glyph.bbX)
    bitmap_max_X = max(0, glyph.bbX + glyph.bbW-1)
    bitmap_min_Y = min(0, glyph.bbY)
    bitmap_max_Y = max(0, glyph.bbY + glyph.bbH-1)
    yy = y_offs
    for y in range(bitmap_max_Y, bitmap_min_Y - 1, -1):
        # Find the data row associated with this output row.
        if glyph.bbY <= y < glyph.bbY + glyph.bbH:
            data_row = glyph.data[y - glyph.bbY]
        else:
            data_row = 0
        xx = x_offs
        for x in range(bitmap_min_X, bitmap_max_X + 1):
            bit_number = glyph.bbW - (x - glyph.bbX) - 1
            if glyph.bbX <= x < glyph.bbX + glyph.bbW and (
                    data_row >> bit_number & 1):
                image [yy][xx] = color
            xx += 1
        yy += 1
    return

if len(sys.argv) < 2:
    sys.stderr.write ("usage: %s fontfile.bdf\n" % sys.argv[0])
    sys.exit (1)

fname = sys.argv [1]
rx = re.search (r"^(.*)\.[Bb][Dd][Ff]$", fname)
if not rx:
    sys.stderr.write ("filename '%s' does not looks as bdf-file\n" % fname)
    sys.exit (1)
name = rx.group (1)
metaname = name + ".meta"

print "load font from file %s" % fname
font = reader.read_bdf (file (fname, "rt"))

if big_palette:
    print "create palette"
    palette = [(0x00,0x00,0x00,0x00),]
    for r in nums:
        for g in nums:
            for b in nums:
                palette.append((r, g, b, 0xFF))
else:
    palette = [(0x00,0x00,0x00,0x00),
               (0x00,0x00,0x00,0xFF), # 01
               (0x00,0x00,0x7F,0xFF), # 02
               (0x00,0x7F,0x00,0xFF), # 03
               (0x00,0x7F,0x7F,0xFF), # 04
               (0x7F,0x00,0x00,0xFF), # 05
               (0x7F,0x00,0x7F,0xFF), # 06
               (0x7F,0x7F,0x00,0xFF), # 07
               (0x7F,0x7F,0x7F,0xFF), # 08
               (0x3F,0x3F,0x3F,0xFF), # 09
               (0x00,0x00,0xFF,0xFF), # 10
               (0x00,0xFF,0x00,0xFF), # 11
               (0x00,0xFF,0xFF,0xFF), # 12
               (0xFF,0x00,0x00,0xFF), # 13
               (0xFF,0x00,0xFF,0xFF), # 14
               (0xFF,0xFF,0x00,0xFF), # 15
               (0xFF,0xFF,0xFF,0xFF),]# 16

# print palette

glyph_w = font.glyphs[0].bbW # FIXME this is only
glyph_h = font.glyphs[0].bbH # in case of fixed font
nglyphs = len(font.glyphs)
palsize = len(palette)
colixs  = range(1, palsize)

w_range = range(glyph_w)
h_range = range(glyph_h)

print "%d glyphs, %d variations" % (nglyphs, palsize - 1)

print "store metainformation to %s" % metaname
meta = open (metaname, "wt")

meta.write ("NAME %s\n" % name)
meta.write ("FACE_NAME %s\n" % font.properties ['FACE_NAME'])
meta.write ("CELL_WIDTH %d\n" % glyph_w)
meta.write ("CELL_HEIGHT %d\n" % glyph_h)
meta.write ("NUM_COLORS %d\n" % len(colixs))
meta.write ("NUM_GLYPHS %d\n" % nglyphs)
meta.write ("CODEPOINTS %s\n" % " ".join ("%04x" % x.codepoint for x in font.glyphs))
meta.write ("\n")

for glyph in font.glyphs:
    meta.write ("%04x %s\n" % (glyph.codepoint, glyph.name))
meta.close ()

ix = 1
x_offs = 0

print "render %d glyphs in %d variations" % (nglyphs, len(colixs))
for glyph in font.glyphs:
    for c in colixs:
        image   = [[0 for x in w_range] for y in h_range]
        render_glyph (image, glyph, 0, 0, c)
        outname = "%s/%s/%02d/%04x.png" % (dir, name, c-1, glyph.codepoint)
#       outname = "%s/%s/%02d/%04x.png" % (dir, name, c, glyph.name)
        d = os.path.dirname (outname)
        if not os.path.exists (d):
            os.makedirs (d)
        f = open (outname, "wb")
        w = png.Writer (glyph_w, glyph_h, palette=palette, bitdepth=8)
        w.write (f, image)
        f.close ()
print "done."
