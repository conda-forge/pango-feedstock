import gi
gi.require_version('PangoCairo', '1.0')
from gi.repository import PangoCairo
import sys

fontmap = PangoCairo.FontMap.get_default()
assert fontmap.list_families()

import cairo
import struct
import subprocess
from gi.repository import Pango

surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 256, 64)
context = cairo.Context(surface)
layout = PangoCairo.create_layout(context)
layout.set_font_description(Pango.FontDescription("Sans 20"))
layout.set_text("ARM64 office caf\u00e9", -1)
width, height = layout.get_pixel_size()
assert width > 0 and height > 0
assert layout.get_unknown_glyphs_count() == 0
context.set_source_rgb(0, 0.5, 0)
PangoCairo.show_layout(context, layout)
surface.flush()
pixels = struct.unpack("=" + "I" * (len(surface.get_data()) // 4), surface.get_data())
ink = [p for p in pixels if p >> 24]
assert 10 < len(ink) < 256 * 64
assert all(p & 0x00FF00FF == 0 for p in ink)
print("PASS: installed PangoCairo text layout, font coverage, and rendered pixels")

subprocess.run(["pango-view", "--no-display", "--text=ARM64", "--output=pango-cli.png"], check=True)
image = cairo.ImageSurface.create_from_png("pango-cli.png")
assert image.get_width() > 0 and image.get_height() > 0
print("PASS: installed pango-view produces a decodable PNG")
