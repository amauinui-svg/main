# Idle Country UI theme ("State Dossier") — the single source for every rendered UI image
Light comes from the TOP. Every piece is built from the same 5 layers, in this order:
1. Outer edge: 2px ink #0b0d10, corner radius 6px (chips/pills: full round).
2. Body: two-stop vertical gradient, light at top (see palette), never a drop shadow.
3. Paper grain: fractal noise, 5% strength, same seed and scale on every piece.
4. Top lip: 2px highlight, white at 22%, inset 3px from the sides.
5. Base bevel (buttons only): 4px band of the body's dark stop at the bottom; pressed state removes it and drops the face 2px.
Palette (top -> bottom):
  slate panel  #2a2f36 -> #1f2328, inner rule #444b54
  manila       #e2cfa3 -> #c9b285, bevel #9f8a5f, ink text #2a2214
  slate button #3a4048 -> #2c3138, bevel #1c2026
  red          #d9544a -> #b33a31, bevel #7d2620
  green        #6fa35c -> #557f46, bevel #3a5a2f
  locked       #5a5f66 -> #474b51, bevel #33363b
  map: deep sea #18202a, sea #1d2631, shallow #283646, paper land #cdbb8f, coast ink #3b3222
Text is NEVER baked into images: Roblox TextLabels (Special Elite headings, Roboto Condensed body) sit on top.
Pixel art (map, pins, convoy sprites) uses the same palette, shown with ResamplerMode Pixelated at whole-number scales.
