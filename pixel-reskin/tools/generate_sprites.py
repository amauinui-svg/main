"""
Build a Swarm: pixel art reskin generator.

Every sprite in the game is defined in this file as a tiny text grid (one
character per pixel) or drawn procedurally. Running the script writes:

  art/sprites/*.png          each sprite frame at 1x (true pixel size)
  art/upload/atlas.png       every unit/projectile/decoration frame packed into ONE image
  art/upload/*_x8.png        ground tiles, hive and ring upscaled 8x for 3D Textures/Decals
  art/preview/*.png          contact sheet + full scene mockup (scaled up, for viewing)
  src/PixelArt/Atlas.luau    generated Luau table of atlas rects (name -> frames)

Edit a grid or a palette color, run `python3 tools/generate_sprites.py`, re-upload.
"""

import json
import math
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_SPRITES = os.path.join(ROOT, "art", "sprites")
OUT_UPLOAD = os.path.join(ROOT, "art", "upload")
OUT_PREVIEW = os.path.join(ROOT, "art", "preview")
OUT_LUAU = os.path.join(ROOT, "src", "PixelArt", "Atlas.luau")

# ---------------------------------------------------------------------------
# Palette. Shared keys across all sprites; per sprite overrides swap colors
# (that is how the six bee colors come from one drawing).
# ---------------------------------------------------------------------------

BASE = {
    ".": None,
    "k": (28, 24, 36),      # outline
    "b": (44, 36, 52),      # bee stripe / dark body
    "e": (255, 255, 255),   # eye / spark white
    "w": (232, 246, 255),   # wing
    "W": (160, 205, 228),   # wing shade
    "y": (255, 214, 72),    # yellow
    "Y": (214, 150, 30),    # yellow shade
    "h": (250, 186, 52),    # honey
    "H": (196, 120, 24),    # honey shade
    "l": (255, 255, 255),   # highlight (recolored per sprite)
    "r": (158, 160, 172),   # rock
    "R": (112, 112, 126),   # rock shade
    "L": (200, 202, 212),   # rock light
    "x": (150, 230, 70),    # acid
    "X": (82, 160, 40),     # acid shade
}

BEE_COLORS = {
    "yellow": ((255, 205, 60), (206, 140, 28)),
    "red":    ((236, 76, 76), (160, 40, 56)),
    "purple": ((162, 104, 228), (100, 60, 164)),
    "green":  ((124, 216, 88), (60, 150, 62)),
    "pink":   ((250, 132, 200), (188, 72, 144)),
    "teal":   ((76, 212, 190), (34, 142, 138)),
}

# ---------------------------------------------------------------------------
# Sprite grids. mirror=True means each row is the LEFT half and gets mirrored,
# which keeps top down creatures perfectly symmetrical.
# ---------------------------------------------------------------------------

BEE = [
    [  # wings out
        "....k.",
        ".....k",
        "....ke",
        ".wwwkc",
        "wWWWkb",
        "wWWkcC",
        ".wwkbb",
        "...kcC",
        "...kbb",
        "....kc",
        ".....k",
        "......",
    ],
    [  # wings in
        "....k.",
        ".....k",
        "....ke",
        "..wwkc",
        ".wWWkb",
        "..wkcC",
        "...kbb",
        "...kcC",
        "...kbb",
        "....kc",
        ".....k",
        "......",
    ],
]

ANT = [
    [
        "...k..",
        "....k.",
        "....ka",
        "...kaA",
        "....ka",
        ".k..ka",
        "..kkaA",
        ".k..ka",
        "...kaA",
        "..kaaA",
        "..kaaA",
        "...kaA",
        "....kk",
    ],
    [
        "...k..",
        "....k.",
        "....ka",
        "...kaA",
        "....ka",
        "k...ka",
        ".kkkaA",
        "k...ka",
        "...kaA",
        "..kaaA",
        "..kaaA",
        "...kaA",
        "....kk",
    ],
]

BEETLE = [
    [
        "...k..",
        "....k.",
        "....kd",
        "..k.kd",
        "...klg",
        ".kkgGk",
        "..kggk",
        ".kkgGk",
        "..kgGk",
        "...kgk",
        "....kk",
        "......",
    ],
    [
        "...k..",
        "....k.",
        "....kd",
        ".k..kd",
        "...klg",
        "..kgGk",
        ".kkggk",
        "..kgGk",
        ".kkgGk",
        "...kgk",
        "....kk",
        "......",
    ],
]

SPIDER = [
    [
        "k.....",
        ".k....",
        "..k.kk",
        "kk.kss",
        "..kkSs",
        "..kSse",
        "kk.kss",
        "..kkss",
        ".k.kSs",
        "k..kss",
        "....kk",
        "......",
    ],
    [
        ".k....",
        "k.....",
        "..k.kk",
        ".kkkss",
        "..kkSs",
        "..kSse",
        ".kkkss",
        "..kkss",
        "k..kSs",
        ".k.kss",
        "....kk",
        "......",
    ],
]

WASP = [
    [
        "....k.",
        ".....k",
        "....ke",
        ".wwwko",
        "wWWWkb",
        "wWWkoO",
        ".wwkbb",
        "...koO",
        "...kbb",
        "....ko",
        ".....k",
        ".....k",
    ],
    [
        "....k.",
        ".....k",
        "....ke",
        "..wwko",
        ".wWWkb",
        "..wkoO",
        "...kbb",
        "...koO",
        "...kbb",
        "....ko",
        ".....k",
        ".....k",
    ],
]

SLIME = [
    [
        ".....",
        "..kkk",
        ".kppp",
        "kplpp",
        "kpekp",
        "kpekp",
        "kpppp",
        "kPPPP",
        ".kkkk",
        ".....",
    ],
    [
        ".....",
        ".....",
        "..kkk",
        ".kppp",
        "kplpp",
        "kpekp",
        "kpppp",
        "kPPPP",
        "kkkkk",
        ".....",
    ],
]

BOSS = [
    [
        ".........k",
        "........kh",
        "..k.....kh",
        "...k...khh",
        "....kkkddd",
        "...k.kdded",
        "..k.kkdddd",
        ".k.kmmmmlm",
        "..kmmmlmMk",
        ".kkmmmmmMk",
        "k.kmMmmmMk",
        ".kkmmmmmMk",
        "..kmMmmmMk",
        "k.kmmmmMMk",
        ".kkMmmmMMk",
        "...kMMMMMk",
        "....kMMMkk",
        ".....kkkkk",
    ],
    [
        ".........k",
        "........kh",
        "...k....kh",
        "...k...khh",
        "....kkkddd",
        "..k..kdded",
        "...kkkdddd",
        ".k.kmmmmlm",
        "..kmmmlmMk",
        ".kkmmmmmMk",
        ".kkmMmmmMk",
        "k.kmmmmmMk",
        "..kmMmmmMk",
        ".kkmmmmMMk",
        "k.kMmmmMMk",
        "...kMMMMMk",
        "....kMMMkk",
        ".....kkkkk",
    ],
]

STINGER = [[".e.", ".w.", ".w.", "kyk", "kYk", ".k."]]
POLLEN = [[".kkk.", "kyeyk", "kyyyk", "kYyYk", ".kkk."]]
ACID = [[".kk.", "kxXk", "kXXk", ".kk."]]
HONEY_DROP = [[
    "...k...",
    "..khk..",
    ".khhhk.",
    "khehhHk",
    "khhhhHk",
    "khhhHHk",
    ".kHHHk.",
    "..kkk..",
]]
SPARK = [
    ["...e...", "...y...", "..yey..", "eyeeeye", "..yey..", "...y...", "...e..."],
    ["e.....e", ".y...y.", "...e...", "..e.e..", "...e...", ".y...y.", "e.....e"],
]
ROCK = [[".kkkk.", "kLLrrk", "kLrrRk", "krrRRk", ".kkkk."]]
FLOWER = [["..f..", ".fff.", "ffcff", ".fff.", "..f.."]]


def mirror(rows):
    return [r + r[::-1] for r in rows]


def grid_to_image(rows, pal):
    h = len(rows)
    w = max(len(r) for r in rows)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            col = pal.get(ch, BASE.get(ch))
            if ch not in pal and ch not in BASE:
                raise ValueError(f"unknown palette key {ch!r}")
            if col is not None:
                px[x, y] = (*col, 255) if len(col) == 3 else col
    return img


def frames(grids, overrides, do_mirror=True):
    pal = dict(BASE)
    pal.update(overrides)
    return [grid_to_image(mirror(g) if do_mirror else g, pal) for g in grids]


# ---------------------------------------------------------------------------
# Procedural sprites (round things are easier to draw with math)
# ---------------------------------------------------------------------------

def blob(size, base, dark, light, outline, seed, lumps=5):
    """Top down bush/tree canopy: clustered circles, lit from the top left."""
    rnd = random.Random(seed)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = (size - 1) / 2
    r_main = size * 0.36
    circles = [(c, c, r_main)]
    for i in range(lumps):
        a = i / lumps * math.tau + rnd.random() * 0.5
        d = r_main * 0.55
        circles.append((c + math.cos(a) * d, c + math.sin(a) * d, r_main * rnd.uniform(0.5, 0.65)))

    def inside(x, y):
        return any((x - cx) ** 2 + (y - cy) ** 2 <= r * r for cx, cy, r in circles)

    for y in range(size):
        for x in range(size):
            if not inside(x, y):
                continue
            if not (inside(x - 1, y) and inside(x + 1, y) and inside(x, y - 1) and inside(x, y + 1)):
                px[x, y] = (*outline, 255)
                continue
            shade = (x - c) + (y - c) * 1.3 + rnd.uniform(-2.5, 2.5)
            col = light if shade < -size * 0.25 else dark if shade > size * 0.18 else base
            px[x, y] = (*col, 255)
    return img


def hive():
    """Top down straw skep: concentric bands with a dark entrance."""
    size = 24
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = 11.5
    light, mid, dark = (246, 206, 112), (212, 158, 72), (150, 96, 40)
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c, y - c)
            if d > 11.6:
                continue
            if d > 10.6:
                col = BASE["k"]
            else:
                band = int(d) // 2
                col = light if band % 2 == 0 else mid
                if (x - c) + (y - c) > 6:
                    col = mid if col == light else dark
            px[x, y] = (*col, 255)
    for x, y in [(11, 11), (12, 11), (11, 12), (12, 12)]:
        px[x, y] = (255, 236, 170, 255)
    for x in range(9, 15):
        for y in range(19, 22):
            px[x, y] = (*BASE["k"], 255)
    px[11, 20] = px[12, 20] = (*BASE["h"], 255)
    return img


def ring(radius=30):
    """Dashed damage ring drawn around the hive."""
    size = radius * 2 + 3
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = size // 2
    steps = int(math.tau * radius * 2)
    for i in range(steps):
        a = i / steps * math.tau
        if int(a / math.tau * 24) % 2:
            continue
        for rr, col in ((radius + 1, (120, 40, 20, 200)), (radius, (255, 150, 60, 255))):
            x = round(c + math.cos(a) * rr)
            y = round(c + math.sin(a) * rr)
            px[x, y] = col
    return img


def ground_tile(kind, seed, size=32):
    rnd = random.Random(seed)
    if kind == "grass":
        base, shades = (98, 168, 70), [(86, 152, 60), (112, 184, 80), (76, 138, 54)]
    elif kind == "dirt":
        base, shades = (152, 104, 62), [(136, 92, 54), (170, 122, 78), (118, 78, 44)]
    else:  # meadow: grass plus flowers (pollen fields)
        base, shades = (98, 168, 70), [(86, 152, 60), (112, 184, 80), (76, 138, 54)]
    img = Image.new("RGBA", (size, size), (*base, 255))
    px = img.load()
    for _ in range(size * size // 5):
        x, y = rnd.randrange(size), rnd.randrange(size)
        px[x, y] = (*rnd.choice(shades), 255)
    if kind == "grass" or kind == "meadow":
        # little 2 pixel grass tufts
        for _ in range(10):
            x, y = rnd.randrange(size), rnd.randrange(1, size)
            px[x, y] = (*shades[1], 255)
            px[x, y - 1] = (*shades[1], 255)
    if kind == "dirt":
        # pebbles, like the reference path
        for _ in range(9):
            x, y = rnd.randrange(size - 1), rnd.randrange(size - 1)
            px[x, y] = (196, 150, 104, 255)
            px[x + 1, y] = (196, 150, 104, 255)
            px[x, y + 1] = shades[2] + (255,)
    if kind == "meadow":
        petals = [(255, 255, 255), (255, 150, 200), (255, 220, 80), (150, 190, 255)]
        for _ in range(6):
            x, y = rnd.randrange(2, size - 2), rnd.randrange(2, size - 2)
            p = rnd.choice(petals)
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                px[x + dx, y + dy] = (*p, 255)
            px[x, y] = (255, 214, 72, 255)
    return img


# ---------------------------------------------------------------------------
# Build the sprite set
# ---------------------------------------------------------------------------

def build_sprites():
    s = {}
    for name, (c, C) in BEE_COLORS.items():
        s[f"bee_{name}"] = frames(BEE, {"c": c, "C": C})
    s["enemy_ant"] = frames(ANT, {"a": (190, 66, 48), "A": (124, 36, 28)})
    s["enemy_beetle"] = frames(BEETLE, {"g": (72, 168, 96), "G": (38, 104, 66), "d": (42, 56, 44), "l": (150, 230, 160)})
    s["enemy_spider"] = frames(SPIDER, {"s": (104, 70, 130), "S": (62, 42, 88), "e": (255, 70, 70)})
    s["enemy_wasp"] = frames(WASP, {"o": (244, 134, 40), "O": (182, 82, 28), "e": (255, 60, 60)})
    s["enemy_slime"] = frames(SLIME, {"p": (255, 96, 150), "P": (200, 52, 112), "l": (255, 190, 214)})
    s["boss_beetle"] = frames(BOSS, {"m": (124, 64, 166), "M": (74, 34, 112), "d": (40, 30, 50), "h": (236, 226, 204), "e": (255, 80, 80), "l": (190, 150, 240)})
    s["proj_stinger"] = frames(STINGER, {}, do_mirror=False)
    s["proj_pollen"] = frames(POLLEN, {}, do_mirror=False)
    s["proj_acid"] = frames(ACID, {}, do_mirror=False)
    s["fx_spark"] = frames(SPARK, {}, do_mirror=False)
    s["pickup_honey"] = frames(HONEY_DROP, {}, do_mirror=False)
    s["deco_rock"] = frames(ROCK, {}, do_mirror=False)
    for name, col in {"white": (255, 255, 255), "pink": (255, 150, 200), "blue": (150, 190, 255)}.items():
        s[f"deco_flower_{name}"] = frames(FLOWER, {"f": col, "c": (255, 214, 72)}, do_mirror=False)
    green = ((74, 150, 64), (46, 104, 48), (116, 192, 90), (30, 70, 36))
    s["deco_bush"] = [blob(12, *green, seed=3, lumps=4)]
    s["deco_tree"] = [blob(22, *green, seed=7, lumps=6)]
    s["hive"] = [hive()]
    s["ring"] = [ring()]
    return s


def build_tiles():
    return {
        "tile_grass": ground_tile("grass", 1),
        "tile_dirt": ground_tile("dirt", 2),
        "tile_meadow": ground_tile("meadow", 3),
    }


def pack_atlas(sprites, width=256):
    """Shelf pack every frame with a 1px transparent gutter (stops bleeding)."""
    items = []
    for name, fs in sprites.items():
        for i, f in enumerate(fs):
            items.append((name, i, f))
    items.sort(key=lambda t: -t[2].height)
    x = y = shelf = 0
    rects = {}
    placed = []
    for name, i, f in items:
        w, h = f.width + 2, f.height + 2
        if x + w > width:
            x, y, shelf = 0, y + shelf, 0
        placed.append((f, x + 1, y + 1))
        rects.setdefault(name, {})[i] = (x + 1, y + 1, f.width, f.height)
        x += w
        shelf = max(shelf, h)
    height = y + shelf
    atlas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for f, px_, py_ in placed:
        atlas.paste(f, (px_, py_))
    ordered = {n: [rects[n][i] for i in sorted(rects[n])] for n in sprites}
    return atlas, ordered


def write_luau(rects, atlas_size):
    lines = [
        "-- GENERATED by pixel-reskin/tools/generate_sprites.py. Do not hand edit;",
        "-- change the generator and rerun it instead.",
        "-- Each sprite is a list of frames: { x, y, width, height } in atlas pixels.",
        "return {",
        f"\tSize = Vector2.new({atlas_size[0]}, {atlas_size[1]}),",
        "\tSprites = {",
    ]
    for name, fs in rects.items():
        inner = ", ".join("{ %d, %d, %d, %d }" % r for r in fs)
        lines.append(f"\t\t{name} = {{ {inner} }},")
    lines += ["\t},", "}", ""]
    with open(OUT_LUAU, "w") as fh:
        fh.write("\n".join(lines))


def scale(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


# ---------------------------------------------------------------------------
# Previews
# ---------------------------------------------------------------------------

def contact_sheet(sprites, tiles):
    k = 6
    cell = 30 * k
    entries = [(n, f) for n, fs in sprites.items() for f in fs] + list(tiles.items())
    cols = 8
    rows = math.ceil(len(entries) / cols)
    sheet = Image.new("RGBA", (cols * cell, rows * (cell + 18)), (38, 34, 46, 255))
    d = ImageDraw.Draw(sheet)
    for idx, (name, f) in enumerate(entries):
        cx, cy = (idx % cols) * cell, (idx // cols) * (cell + 18)
        big = scale(f, k) if f.width * k <= cell else scale(f, max(1, cell // f.width))
        sheet.alpha_composite(big, (cx + (cell - big.width) // 2, cy + (cell - big.height) // 2))
        d.text((cx + 6, cy + cell + 2), name, fill=(230, 220, 200, 255))
    return sheet


def shadow_of(img, alpha=70):
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    a = img.getchannel("A").point(lambda v: alpha if v else 0)
    sh.putalpha(a)
    return sh


def mockup(sprites, tiles):
    """A 480x270 frame of the game, then upscaled 4x to 1920x1080."""
    W, H = 480, 270
    rnd = random.Random(42)
    scene = Image.new("RGBA", (W, H))
    for ty in range(0, H, 32):
        for tx in range(0, W, 32):
            scene.paste(tiles["tile_meadow" if rnd.random() < 0.25 else "tile_grass"], (tx, ty))

    # Dirt arena with stepped pixel edges, like the reference path.
    left, right, top, bottom = 56, 424, 22, 252
    step = 4
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    md.rectangle([left, top, right, bottom], fill=255)
    for x in range(left - step * 3, right + step * 3, step * 3):
        md.rectangle([x, top - rnd.choice((0, step, step * 2)), x + step * 3, top], fill=255)
        md.rectangle([x, bottom, x + step * 3, bottom + rnd.choice((0, step, step * 2))], fill=255)
    for y in range(top, bottom, step * 3):
        md.rectangle([left - rnd.choice((0, step, step * 2)), y, left, y + step * 3], fill=255)
        md.rectangle([right, y, right + rnd.choice((0, step, step * 2)), y + step * 3], fill=255)
    dirt = Image.new("RGBA", (W, H))
    for ty in range(0, H, 32):
        for tx in range(0, W, 32):
            dirt.paste(tiles["tile_dirt"], (tx, ty))
    scene.paste(dirt, (0, 0), mask)
    # grass lip: dark shadow on the dirt just below/inside the grass edge
    mp = mask.load()
    sp = scene.load()
    for y in range(2, H - 1):
        for x in range(1, W - 1):
            if not mp[x, y]:
                continue
            if not (mp[x, y - 1] and mp[x - 1, y] and mp[x + 1, y] and mp[x, y + 1]):
                sp[x, y] = (84, 54, 32, 255)
            elif not mp[x, y - 2]:
                sp[x, y] = (118, 78, 44, 255)

    def place(name, x, y, frame=0, shadow=(1, 2)):
        img = sprites[name][frame]
        pos = (int(x - img.width / 2), int(y - img.height / 2))
        if shadow:
            scene.alpha_composite(shadow_of(img), (pos[0] + shadow[0], pos[1] + shadow[1]))
        scene.alpha_composite(img, pos)

    # decorations on the grass
    for x, y in [(18, 40), (28, 120), (14, 200), (40, 250), (452, 30), (460, 110), (448, 190), (470, 246), (22, 8)]:
        place("deco_tree", x, y, shadow=(2, 3))
    for x, y in [(44, 70), (36, 166), (440, 70), (446, 150), (60, 8), (410, 262)]:
        place("deco_bush", x, y, shadow=(1, 2))
    for x, y in [(12, 88), (470, 150), (30, 228), (436, 226)]:
        place("deco_rock", x, y, shadow=(1, 1))
    for i in range(14):
        place(rnd.choice(["deco_flower_white", "deco_flower_pink", "deco_flower_blue"]),
              rnd.choice([rnd.randrange(4, 48), rnd.randrange(432, 476)]), rnd.randrange(4, 266), shadow=None)
    for _ in range(10):
        place("deco_rock", rnd.randrange(80, 400), rnd.randrange(40, 240), shadow=(1, 1))

    cx, cy = 240, 138
    place("ring", cx, cy, shadow=None)
    place("hive", cx, cy, shadow=(2, 3))

    bees = list(BEE_COLORS)
    for i in range(14):
        a = i / 14 * math.tau
        d = 18 + (i % 3) * 5
        place(f"bee_{bees[i % len(bees)]}", cx + math.cos(a) * d, cy + math.sin(a) * d, frame=i % 2, shadow=(2, 4))

    enemies = [
        ("enemy_ant", 150, 40), ("enemy_ant", 170, 58), ("enemy_ant", 300, 36),
        ("enemy_beetle", 330, 70), ("enemy_beetle", 120, 190), ("enemy_spider", 360, 210),
        ("enemy_spider", 100, 90), ("enemy_wasp", 250, 52), ("enemy_wasp", 390, 120),
        ("enemy_slime", 86, 140), ("enemy_slime", 396, 160), ("enemy_ant", 220, 232),
    ]
    for i, (n, x, y) in enumerate(enemies):
        place(n, x, y, frame=i % 2, shadow=(1, 3) if "wasp" in n else (1, 1))
    place("boss_beetle", 370, 48, shadow=(2, 2))

    for x, y in [(215, 95), (262, 90), (205, 170), (285, 180), (180, 120), (310, 140)]:
        place("proj_stinger", x, y, shadow=None)
    for x, y in [(230, 70), (330, 100)]:
        place("proj_pollen", x, y, shadow=(1, 1))
    place("proj_acid", 350, 190, shadow=None)
    place("fx_spark", 252, 56, frame=0, shadow=None)
    place("fx_spark", 118, 94, frame=1, shadow=None)
    for x, y in [(160, 150), (320, 200), (280, 110)]:
        place("pickup_honey", x, y, shadow=(1, 1))
    return scale(scene, 4)


def main():
    for d in (OUT_SPRITES, OUT_UPLOAD, OUT_PREVIEW, os.path.dirname(OUT_LUAU)):
        os.makedirs(d, exist_ok=True)
    sprites = build_sprites()
    tiles = build_tiles()

    for name, fs in sprites.items():
        for i, f in enumerate(fs):
            f.save(os.path.join(OUT_SPRITES, f"{name}_{i}.png"))
    for name, t in tiles.items():
        t.save(os.path.join(OUT_SPRITES, f"{name}.png"))

    atlas_sprites = {n: fs for n, fs in sprites.items() if n not in ("hive", "ring")}
    atlas, rects = pack_atlas(atlas_sprites)
    atlas.save(os.path.join(OUT_UPLOAD, "atlas.png"))
    with open(os.path.join(OUT_UPLOAD, "atlas.json"), "w") as fh:
        json.dump({"size": atlas.size, "sprites": rects}, fh, indent=1)
    write_luau(rects, atlas.size)

    # Big world objects and tiles, upscaled 8x so 3D Decals/Textures stay crisp.
    for name, img in {**tiles, "hive": sprites["hive"][0], "ring": sprites["ring"][0]}.items():
        scale(img, 8).save(os.path.join(OUT_UPLOAD, f"{name}_x8.png"))
        img.save(os.path.join(OUT_UPLOAD, f"{name}.png"))

    contact_sheet(sprites, tiles).save(os.path.join(OUT_PREVIEW, "sprite_sheet.png"))
    mockup(sprites, tiles).save(os.path.join(OUT_PREVIEW, "mockup.png"))
    print(f"atlas {atlas.size}, {sum(len(v) for v in sprites.values())} frames, {len(tiles)} tiles")


if __name__ == "__main__":
    main()
