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


import sys, re
import bdflib.reader as reader
import png

colored = True
big_palette = False
# nums = (0x00, 0x33, 0x66, 0x99, 0xCC, 0xFF) # web-palette
# nums = (0x00, 0x55, 0xAA, 0xFF)
nums = (0x00, 0x88, 0xFF)

ucodes = []
for u in xrange (0x20, 0x7F):
  ucodes.append(u)

for u in u"АаБбВвГгДдЕеЁёЖжЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЪъЫыЬьЭэЮюЯяҐґЄєІіЇї":
  ucodes.append (ord (u))


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
outname = name + ".png"
metaname = name + ".meta"

print "load font from file %s" % fname
font = reader.read_bdf (file (fname, "rt"))

if colored:
  if big_palette:
      print "create palette"
      palette = [(0x00,0x00,0x00,0x00),]
      for r in nums:
          for g in nums:
              for b in nums:
                  palette.append((r, g, b, 0xFF))
  else:
      palette = [(0x00,0x00,0x00,0x00),
                 (0x00,0x00,0x00,0xFF), 
                 (0x00,0x00,0x7F,0xFF), 
                 (0x00,0x7F,0x00,0xFF), 
                 (0x00,0x7F,0x7F,0xFF), 
                 (0x7F,0x00,0x00,0xFF), 
                 (0x7F,0x00,0x7F,0xFF), 
                 (0x7F,0x7F,0x00,0xFF), 
                 (0x7F,0x7F,0x7F,0xFF),
                 (0x30,0x30,0x30,0xFF), 
                 (0x00,0x00,0xFF,0xFF), 
                 (0x00,0xFF,0x00,0xFF), 
                 (0x00,0xFF,0xFF,0xFF), 
                 (0xFF,0x00,0x00,0xFF), 
                 (0xFF,0x00,0xFF,0xFF), 
                 (0xFF,0xFF,0x00,0xFF), 
                 (0xFF,0xFF,0xFF,0xFF),]
else: # not colored
  palette = [(0x00,0x00,0x00,0x00),
             (0x00,0x00,0x00,0xFF),]


# codeset
glyphs = []
all_glyphs_codepoints = font.glyphs_by_codepoint.keys ()
if ucodes:
  print "use only glyphs for selected unicodes"
  for u in ucodes:
    if u in all_glyphs_codepoints:
      glyphs.append (font.glyphs_by_codepoint [u])
    else:
      print "unicode u%04x (%c) has no glyph" % (u, unichr (u))
else:
  print "use all glyphs"
  glyphs = [font.glyphs_by_codepoint [u] for u in all_glyphs_codepoints]

glyph_w = font.glyphs[0].bbW # FIXME this is only 
glyph_h = font.glyphs[0].bbH # in case of fixed font
nglyphs = len(glyphs)
width   = nglyphs * glyph_w
palsize = len(palette)
colixs  = range(1, palsize)
height  = glyph_h * len(colixs)

x_range = range(width)
y_range = range(height)

print "%d glyphs, %d variations" % (nglyphs, palsize - 1)
print "allocate image %d x %d" % (width, height)
image   = [[0 for x in x_range] for y in y_range]

print "store metainformation to %s" % metaname
meta = open (metaname, "wt")

meta.write ("IMAGE_FILE %s\n" % outname)
meta.write ("FACE_NAME %s\n" % font.properties ['FACE_NAME'])
meta.write ("CELL_WIDTH %d\n" % glyph_w)
meta.write ("CELL_HEIGHT %d\n" % glyph_h)
meta.write ("NUM_COLORS %d\n" % len(colixs))
meta.write ("NUM_GLYPHS %d\n" % nglyphs)
meta.write ("CODEPOINTS %s\n" % " ".join ("%04x" % x.codepoint for x in glyphs))
meta.write ("\n")

for glyph in glyphs:
  meta.write ("%04x %s\n" % (glyph.codepoint, glyph.name))
meta.close ()

ix = 1
x_offs = 0

print "render %d glyphs in %d variations" % (nglyphs, len(colixs))
for glyph in glyphs:
    # print "[%d of %d]: 0x%04X, %s" % (ix, nglyphs, glyph.codepoint, glyph.name)
    y_offs = 0
    for c in colixs:
        render_glyph (image, glyph, x_offs, y_offs, c)
        y_offs += glyph_h
    x_offs += glyph_w
    ix += 1
    # if 10 < ix:
    #     break

print "save image to file %s" % outname
f = open (outname, "wb")
w = png.Writer (width, height, palette=palette, bitdepth=8)
w.write (f, image)
f.close ()
print "done."
