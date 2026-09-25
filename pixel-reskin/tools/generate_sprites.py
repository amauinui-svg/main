"""
Build a Swarm: pixel art reskin generator.

Every sprite in the game is defined in this file as a tiny text grid (one
character per pixel) or drawn with a little math. Running the script writes:

  art/sprites/*.png            each sprite frame at 1x (true pixel size)
  art/upload/atlas.png         every unit, projectile, pickup and effect in ONE image
  art/upload/arena_bg.png      the whole arena floor baked into one image
  art/upload/tile_*.png        ground tiles, if you would rather tile than bake
  art/preview/*.png            sprite sheet + scene mockup (scaled up, for viewing)
  src/PixelArt/Atlas.luau      generated Luau table: sprite name -> atlas frames

Edit a grid or a colour, run `python3 tools/generate_sprites.py`, re-upload.

BEES follow the shape book (BACKLOG, "THE SHAPE BOOK, REV 2"):
  SHAPE  = behaviour   one silhouette per behaviour, wings at head level, rectangles
  COLOUR = element     bees are drawn in two layers. `bee_<shape>_tint` is the
                       body in white/grey and gets ImageColor3 = the element
                       colour; `bee_<shape>` is the outline, band, wings and eyes,
                       never tinted. One drawing serves every palette.
  PAINT  = rarity      overlays: rarity_shine (Rare), rarity_aura (Epic, and
                       Legendary tinted gold), rarity_crown (Legendary)
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
# Palette. Keys are shared by every grid; a sprite can override any of them.
# ---------------------------------------------------------------------------

BASE = {
    ".": None,
    "k": (28, 24, 36),      # outline
    "b": (44, 36, 52),      # band / stinger
    "e": (255, 255, 255),   # eye, spark white
    "w": (232, 246, 255),   # wing
    "W": (160, 205, 228),   # wing shade
    "c": (255, 255, 255),   # TINT: body light (becomes the element colour)
    "C": (168, 168, 168),   # TINT: body shade (element colour, darker)
    "d": (64, 66, 82),      # dark metal
    "m": (176, 182, 200),   # light metal
    "n": (236, 226, 204),   # bone / lance
    "g": (255, 240, 140),   # glow bulb
    "y": (255, 214, 72),    # pollen yellow
    "Y": (214, 150, 30),    # pollen shade
    "h": (250, 186, 52),    # honey
    "H": (196, 120, 24),    # honey shade
    "l": (255, 255, 255),   # highlight (recoloured per sprite)
    "r": (158, 160, 172),   # rock / iron
    "R": (112, 112, 126),   # rock shade
    "L": (200, 202, 212),   # rock light
    "x": (150, 230, 70),    # acid
    "X": (82, 160, 40),     # acid shade
    "o": (244, 134, 40),    # orange
    "q": (255, 84, 84),     # boss shot
    "Q": (170, 30, 44),     # boss shot shade
}
TINT_KEYS = {"c", "C"}

# Element colours used for the PREVIEWS only. In game the colour comes from
# the bee's palette in BeeShapes, passed to PixelArt.newBee.
ELEMENTS = {
    "honey":  (255, 205, 60),
    "fire":   (240, 80, 72),
    "frost":  (110, 190, 255),
    "poison": (124, 216, 88),
    "dark":   (162, 104, 228),
    "royal":  (250, 132, 200),
    "tide":   (76, 212, 190),
    "light":  (250, 244, 225),
}

# ---------------------------------------------------------------------------
# Bees: six behaviour silhouettes plus the Worker (replaces the Looter ship).
# Rows are the LEFT half and get mirrored. Frame B only lists the rows that
# change (the wing flap).
# ---------------------------------------------------------------------------

BEES = {
    # Orbiter: the standard bee. Two wings, block, band, stinger.
    "orbiter": (
        [
            "kkk...",
            "kwwkkk",
            "kwWkce",
            "kkkkcc",
            "..kccc",
            "..kccc",
            "..kbbb",
            "..kCCC",
            "...kCC",
            "....kb",
            ".....k",
            "......",
        ],
        {0: "......", 1: "kkkkkk", 2: "kWWkce", 3: "kkkkcc"},
    ),
    # Interceptor: a needle. Narrow body, wings swept back, built to chase.
    "interceptor": (
        [
            ".....k",
            "....kc",
            "kkkkke",
            "kwwwkc",
            ".kWWkc",
            "..kkkb",
            "....kc",
            "....kC",
            "....kb",
            "....kC",
            ".....k",
            "......",
        ],
        {2: "..kkke", 3: "..kwkc", 4: "...kkc", 5: "....kb"},
    ),
    # Sentry: squat and wide with a barrel out front. Holds a station, shoots.
    "sentry": (
        [
            ".....k",
            "....kd",
            "kkkkkd",
            "kwwkcc",
            "kwWkec",
            "kkkccc",
            ".kcccc",
            ".kbbbb",
            ".kCCCC",
            "..kCCC",
            "...kkk",
            "......",
        ],
        {2: "....kd", 3: "kkkkcc", 4: "kWWkec"},
    ),
    # Guardian (Warden): a metal shield plate in front. Blocks, interposes.
    "guardian": (
        [
            ".kkkkk",
            "kmmmmm",
            "kddddd",
            "kkkkkk",
            "kwwkce",
            "kWWkcc",
            "kkkccc",
            "..kbbb",
            "..kCCC",
            "...kCC",
            "....kk",
            "......",
        ],
        {4: "kWWkce", 5: "kkkkcc"},
    ),
    # Charger (Lancer): bulky with a lance horn. Rams things.
    "charger": (
        [
            ".....k",
            "....kn",
            "....kn",
            "kkkkkn",
            "kwwkce",
            "kwWkcc",
            "kkkccc",
            ".kcccc",
            ".kbbbb",
            ".kCCCC",
            "..kCCC",
            "...kkk",
        ],
        {3: "....kn", 4: "kkkkce", 5: "kWWkcc"},
    ),
    # Escort (Signal): small, with glowing antenna bulbs. Follows your aim.
    "escort": (
        [
            ".kk...",
            ".kgk..",
            "kkkkkk",
            "kwwkce",
            "kwWkcc",
            "kkkkcc",
            "...kcc",
            "...kbb",
            "...kCC",
            "....kk",
            "......",
            "......",
        ],
        {3: "kWWkce", 4: "kkkkcc", 5: "...kcc"},
    ),
    # Worker: pollen baskets on its hips. Collects. Replaces the Looter ship.
    "worker": (
        [
            "kkk...",
            "kwwkkk",
            "kwWkce",
            "kkkkcc",
            "..kccc",
            "kykccc",
            "kYkbbb",
            ".kkCCC",
            "...kCC",
            "....kb",
            ".....k",
            "......",
        ],
        {0: "......", 1: "kkkkkk", 2: "kWWkce", 3: "kkkkcc"},
    ),
}

# ---------------------------------------------------------------------------
# Enemies. Names are placeholders until they are mapped to the 14 species.
# ---------------------------------------------------------------------------

ANT = [
    ["...k..", "....k.", "....ka", "...kaA", "....ka", ".k..ka", "..kkaA",
     ".k..ka", "...kaA", "..kaaA", "..kaaA", "...kaA", "....kk"],
    ["...k..", "....k.", "....ka", "...kaA", "....ka", "k...ka", ".kkkaA",
     "k...ka", "...kaA", "..kaaA", "..kaaA", "...kaA", "....kk"],
]
BEETLE = [
    ["...k..", "....k.", "....kd", "..k.kd", "...klg", ".kkgGk", "..kggk",
     ".kkgGk", "..kgGk", "...kgk", "....kk", "......"],
    ["...k..", "....k.", "....kd", ".k..kd", "...klg", "..kgGk", ".kkggk",
     "..kgGk", ".kkgGk", "...kgk", "....kk", "......"],
]
SPIDER = [
    ["k.....", ".k....", "..k.kk", "kk.kss", "..kkSs", "..kSse", "kk.kss",
     "..kkss", ".k.kSs", "k..kss", "....kk", "......"],
    [".k....", "k.....", "..k.kk", ".kkkss", "..kkSs", "..kSse", ".kkkss",
     "..kkss", "k..kSs", ".k.kss", "....kk", "......"],
]
WASP = [
    ["....k.", ".....k", "....ke", ".wwwko", "wWWWkb", "wWWkoO", ".wwkbb",
     "...koO", "...kbb", "....ko", ".....k", ".....k"],
    ["....k.", ".....k", "....ke", "..wwko", ".wWWkb", "..wkoO", "...kbb",
     "...koO", "...kbb", "....ko", ".....k", ".....k"],
]
SLIME = [
    [".....", "..kkk", ".kppp", "kplpp", "kpekp", "kpekp", "kpppp", "kPPPP", ".kkkk", "....."],
    [".....", ".....", "..kkk", ".kppp", "kplpp", "kpekp", "kpppp", "kPPPP", "kkkkk", "....."],
]
# Ironback (Carapace): the siege enemy. Armoured shell with a mortar on its back.
IRONBACK = [
    ["......k", ".....kd", "....kkd", "..kkiii", ".kiiiIi", "kiiIiii", "kiIiiIk",
     "kiiiiIk", "kIiiIIk", ".kIIIIk", "k.kkkkk", ".k.....", "......."],
    ["......k", ".....kd", "....kkd", "..kkiii", ".kiiiIi", "kiiIiii", "kiIiiIk",
     "kiiiiIk", "kIiiIIk", ".kIIIIk", ".kkkkkk", "k......", "......."],
]
BOSS = [
    [".........k", "........kh", "..k.....kh", "...k...khh", "....kkkddd",
     "...k.kdded", "..k.kkdddd", ".k.kmmmmlm", "..kmmmlmMk", ".kkmmmmmMk",
     "k.kmMmmmMk", ".kkmmmmmMk", "..kmMmmmMk", "k.kmmmmMMk", ".kkMmmmMMk",
     "...kMMMMMk", "....kMMMkk", ".....kkkkk"],
    [".........k", "........kh", "...k....kh", "...k...khh", "....kkkddd",
     "..k..kdded", "...kkkdddd", ".k.kmmmmlm", "..kmmmlmMk", ".kkmmmmmMk",
     ".kkmMmmmMk", "k.kmmmmmMk", "..kmMmmmMk", ".kkmmmmMMk", "k.kMmmmMMk",
     "...kMMMMMk", "....kMMMkk", ".....kkkkk"],
]

# ---------------------------------------------------------------------------
# Projectiles, pickups, effects, overlays (full rows, not mirrored)
# ---------------------------------------------------------------------------

SHOT_BEE = [[".k.", "kck", "kck", "kCk", ".k."]]              # tint with the bee's element
SHOT_CANNON = [[".kkk.", "kLrrk", "krrRk", "kRRRk", ".kkk."]]  # your weapon
SHOT_BOSS = [[".kkkk.", "kqeqqk", "kqqqqk", "kqqqQk", "kQqQQk", ".kkkk."]]
SHOT_SIEGE = [[".kk.", "kook", "kddk", "kddk", "kddk", ".kk."]]  # Ironback shell
SHOT_ACID = [[".kk.", "kxXk", "kXXk", ".kk."]]
HONEY_DROP = [["...k...", "..khk..", ".khhhk.", "khehhHk", "khhhhHk", "khhhHHk", ".kHHHk.", "..kkk.."]]
SPARK = [
    ["...e...", "...y...", "..yey..", "eyeeeye", "..yey..", "...y...", "...e..."],
    ["e.....e", ".y...y.", "...e...", "..e.e..", "...e...", ".y...y.", "e.....e"],
]
POOF = [
    ["..k.k..", ".kLLLk.", "kLLeLLk", ".LeeeL.", "kLLeLLk", ".kLLLk.", "..k.k.."],
    ["L.....L", "...L...", ".L...L.", "L..e..L", ".L...L.", "...L...", "L.....L"],
]
SHINE = [[".e.", "eee", ".e."]]
CROWN = [[".k.k.k.", "kykykyk", "kyyyyyk", "kYYYYYk", ".kkkkk."]]
ROCK = [[".kkkk.", "kLLrrk", "kLrrRk", "krrRRk", ".kkkk."]]
FLOWER = [["..f..", ".fff.", "ffcff", ".fff.", "..f.."]]


def mirror(rows):
    return [r + r[::-1] for r in rows]


def grid_to_image(rows, pal, keep=None):
    """Render a grid. `keep` limits which palette keys are drawn (for layers)."""
    h = len(rows)
    w = max(len(r) for r in rows)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch not in pal:
                raise ValueError(f"unknown palette key {ch!r} in {row!r}")
            if keep is not None and ch not in keep:
                continue
            col = pal[ch]
            if col is not None:
                px[x, y] = (*col, 255) if len(col) == 3 else col
    return img


def frames(grids, overrides=None, do_mirror=True, keep=None):
    pal = dict(BASE)
    pal.update(overrides or {})
    return [grid_to_image(mirror(g) if do_mirror else g, pal, keep) for g in grids]


def bee_frames(shape):
    a, b_rows = BEES[shape]
    b = [b_rows.get(i, row) for i, row in enumerate(a)]
    for g in (a, b):
        assert all(len(r) == 6 for r in g), f"{shape}: every row must be 6 wide"
    all_keys = set(BASE) - {"."}
    base = frames([a, b], keep=all_keys - TINT_KEYS)
    tint = frames([a, b], keep=TINT_KEYS)
    return base, tint


def tinted(img, colour):
    """What ImageColor3 does in Roblox: multiply every pixel by the colour."""
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (r * colour[0] // 255, g * colour[1] // 255, b * colour[2] // 255, a)
    return out


def bee_preview(shape, element, frame=0):
    base, tint = BEE_LAYERS[shape]
    img = tinted(tint[frame], ELEMENTS[element])
    img.alpha_composite(base[frame])
    return img


# ---------------------------------------------------------------------------
# Procedural sprites
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


def disc(size, fill, shade, light, outline=BASE["k"]):
    """A round orb with an outline, lit from the top left."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = (size - 1) / 2
    r = size / 2
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c, y - c)
            if d > r - 0.2:
                continue
            if d > r - 1.2:
                col = outline
            elif (x - c) + (y - c) > r * 0.5:
                col = shade
            elif (x - c) + (y - c) < -r * 0.6:
                col = light
            else:
                col = fill
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
    for x in range(9, 15):
        for y in range(19, 22):
            px[x, y] = (*BASE["k"], 255)
    px[11, 20] = px[12, 20] = (*BASE["h"], 255)
    return img


def cannon():
    """The Gunner's single cannon. Pivot is the image centre, barrel points up,
    so ImageLabel.Rotation aims it without any offset maths."""
    size = 17
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    k, dk, lt = BASE["k"] + (255,), BASE["d"] + (255,), BASE["m"] + (255,)
    d.rectangle([6, 0, 10, 9], fill=k)       # barrel outline
    d.rectangle([7, 1, 9, 9], fill=dk)
    d.line([7, 1, 7, 8], fill=lt)            # barrel shine
    d.rectangle([6, 1, 10, 2], fill=k)       # muzzle ring
    d.point([(7, 1), (8, 1), (9, 1)], fill=lt)
    turret = disc(9, BASE["d"], (40, 42, 54), BASE["m"])
    img.alpha_composite(turret, (4, 8))
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
            px[round(c + math.cos(a) * rr), round(c + math.sin(a) * rr)] = col
    return img


def aura(size=20):
    """Dithered pixel ring drawn in white so ImageColor3 picks the rarity colour."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c, y - c)
            if size / 2 - 2.2 < d < size / 2 - 0.4 and (x + y) % 2 == 0:
                px[x, y] = (255, 255, 255, 230)
            elif size / 2 - 3.4 < d <= size / 2 - 2.2 and (x + y) % 4 == 0:
                px[x, y] = (255, 255, 255, 120)
    return img


def ground_tile(kind, seed, size=32):
    rnd = random.Random(seed)
    if kind == "dirt":
        base, shades = (152, 104, 62), [(136, 92, 54), (170, 122, 78), (118, 78, 44)]
    else:
        base, shades = (98, 168, 70), [(86, 152, 60), (112, 184, 80), (76, 138, 54)]
    img = Image.new("RGBA", (size, size), (*base, 255))
    px = img.load()
    for _ in range(size * size // 5):
        px[rnd.randrange(size), rnd.randrange(size)] = (*rnd.choice(shades), 255)
    if kind in ("grass", "meadow"):
        for _ in range(10):  # little 2 pixel grass tufts
            x, y = rnd.randrange(size), rnd.randrange(1, size)
            px[x, y] = px[x, y - 1] = (*shades[1], 255)
    if kind == "dirt":
        for _ in range(9):  # pebbles, like the reference path
            x, y = rnd.randrange(size - 1), rnd.randrange(size - 1)
            px[x, y] = px[x + 1, y] = (196, 150, 104, 255)
            px[x, y + 1] = shades[2] + (255,)
    if kind == "meadow":  # pollen fields
        petals = [(255, 255, 255), (255, 150, 200), (255, 220, 80), (150, 190, 255)]
        for _ in range(6):
            x, y = rnd.randrange(2, size - 2), rnd.randrange(2, size - 2)
            p = rnd.choice(petals)
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                px[x + dx, y + dy] = (*p, 255)
            px[x, y] = (255, 214, 72, 255)
    return img


# ---------------------------------------------------------------------------
# Build everything
# ---------------------------------------------------------------------------

BEE_LAYERS = {shape: bee_frames(shape) for shape in BEES}


def build_sprites():
    s = {}
    for shape, (base, tint) in BEE_LAYERS.items():
        s[f"bee_{shape}"] = base
        s[f"bee_{shape}_tint"] = tint
    s["rarity_shine"] = frames(SHINE, do_mirror=False)
    s["rarity_aura"] = [aura()]
    s["rarity_crown"] = frames(CROWN, do_mirror=False)

    s["enemy_ant"] = frames(ANT, {"a": (190, 66, 48), "A": (124, 36, 28)})
    s["enemy_beetle"] = frames(BEETLE, {"g": (72, 168, 96), "G": (38, 104, 66), "d": (42, 56, 44), "l": (150, 230, 160)})
    s["enemy_spider"] = frames(SPIDER, {"s": (104, 70, 130), "S": (62, 42, 88), "e": (255, 70, 70)})
    s["enemy_wasp"] = frames(WASP, {"o": (244, 134, 40), "O": (182, 82, 28), "e": (255, 60, 60)})
    s["enemy_slime"] = frames(SLIME, {"p": (255, 96, 150), "P": (200, 52, 112), "l": (255, 190, 214)})
    s["enemy_ironback"] = frames(IRONBACK, {"i": (136, 144, 160), "I": (86, 92, 110)})
    s["boss_beetle"] = frames(BOSS, {"m": (124, 64, 166), "M": (74, 34, 112), "d": (40, 30, 50), "h": (236, 226, 204), "e": (255, 80, 80), "l": (190, 150, 240)})

    s["shot_bee"] = frames(SHOT_BEE, do_mirror=False)
    s["shot_cannon"] = frames(SHOT_CANNON, do_mirror=False)
    s["shot_boss"] = frames(SHOT_BOSS, do_mirror=False)
    s["shot_siege"] = frames(SHOT_SIEGE, do_mirror=False)
    s["shot_acid"] = frames(SHOT_ACID, do_mirror=False)
    pollen = (BASE["y"], BASE["Y"], (255, 246, 190))
    s["pollen_s"] = [disc(5, *pollen)]
    s["pollen_m"] = [disc(7, *pollen)]
    s["pollen_l"] = [disc(9, *pollen)]
    s["pickup_honey"] = frames(HONEY_DROP, do_mirror=False)
    s["fx_spark"] = frames(SPARK, do_mirror=False)
    s["fx_poof"] = frames(POOF, do_mirror=False)

    s["hive"] = [hive()]
    s["weapon_cannon"] = [cannon()]
    s["ring"] = [ring()]
    s["deco_rock"] = frames(ROCK, do_mirror=False)
    for name, col in {"white": (255, 255, 255), "pink": (255, 150, 200), "blue": (150, 190, 255)}.items():
        s[f"deco_flower_{name}"] = frames(FLOWER, {"f": col, "c": (255, 214, 72)}, do_mirror=False)
    green = ((74, 150, 64), (46, 104, 48), (116, 192, 90), (30, 70, 36))
    s["deco_bush"] = [blob(12, *green, seed=3, lumps=4)]
    s["deco_tree"] = [blob(22, *green, seed=7, lumps=6)]
    return s


def build_tiles():
    return {
        "tile_grass": ground_tile("grass", 1),
        "tile_dirt": ground_tile("dirt", 2),
        "tile_meadow": ground_tile("meadow", 3),
    }


def pack_atlas(sprites, width=256):
    """Shelf pack every frame with a 1px transparent gutter (stops bleeding)."""
    items = [(name, i, f) for name, fs in sprites.items() for i, f in enumerate(fs)]
    items.sort(key=lambda t: -t[2].height)
    x = y = shelf = 0
    rects, placed = {}, []
    for name, i, f in items:
        w, h = f.width + 2, f.height + 2
        if x + w > width:
            x, y, shelf = 0, y + shelf, 0
        placed.append((f, x + 1, y + 1))
        rects.setdefault(name, {})[i] = (x + 1, y + 1, f.width, f.height)
        x += w
        shelf = max(shelf, h)
    atlas = Image.new("RGBA", (width, y + shelf), (0, 0, 0, 0))
    for f, px_, py_ in placed:
        atlas.paste(f, (px_, py_))
    return atlas, {n: [rects[n][i] for i in sorted(rects[n])] for n in sprites}


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


def shadow_of(img, alpha=70):
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sh.putalpha(img.getchannel("A").point(lambda v: alpha if v else 0))
    return sh


# ---------------------------------------------------------------------------
# The arena floor, baked into one image, plus previews
# ---------------------------------------------------------------------------

W, H = 480, 270


def arena_background(sprites, tiles):
    """Grass border, stepped dirt clearing, trees/bushes/rocks/flowers.
    One ImageLabel in game instead of dozens of tiles and decorations."""
    rnd = random.Random(42)
    scene = Image.new("RGBA", (W, H))
    for ty in range(0, H, 32):
        for tx in range(0, W, 32):
            scene.paste(tiles["tile_meadow" if rnd.random() < 0.25 else "tile_grass"], (tx, ty))

    left, right, top, bottom, step = 56, 424, 22, 252, 4
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
    mp, sp = mask.load(), scene.load()
    for y in range(2, H - 1):
        for x in range(1, W - 1):
            if not mp[x, y]:
                continue
            if not (mp[x, y - 1] and mp[x - 1, y] and mp[x + 1, y] and mp[x, y + 1]):
                sp[x, y] = (84, 54, 32, 255)
            elif not mp[x, y - 2]:
                sp[x, y] = (118, 78, 44, 255)

    def put(img, x, y, sh):
        pos = (int(x - img.width / 2), int(y - img.height / 2))
        if sh:
            scene.alpha_composite(shadow_of(img), (pos[0] + sh[0], pos[1] + sh[1]))
        scene.alpha_composite(img, pos)

    for x, y in [(18, 40), (28, 120), (14, 200), (40, 250), (452, 30), (460, 110), (448, 190), (470, 246), (22, 8)]:
        put(sprites["deco_tree"][0], x, y, (2, 3))
    for x, y in [(44, 70), (36, 166), (440, 70), (446, 150), (60, 8), (410, 262)]:
        put(sprites["deco_bush"][0], x, y, (1, 2))
    for x, y in [(12, 88), (470, 150), (30, 228), (436, 226)]:
        put(sprites["deco_rock"][0], x, y, (1, 1))
    for _ in range(14):
        name = rnd.choice(["deco_flower_white", "deco_flower_pink", "deco_flower_blue"])
        put(sprites[name][0], rnd.choice([rnd.randrange(4, 48), rnd.randrange(432, 476)]), rnd.randrange(4, 266), None)
    for _ in range(10):
        put(sprites["deco_rock"][0], rnd.randrange(80, 400), rnd.randrange(40, 240), (1, 1))
    return scene


def mockup(bg, sprites):
    scene = bg.copy()

    def place(img, x, y, shadow=(1, 2)):
        pos = (int(x - img.width / 2), int(y - img.height / 2))
        if shadow:
            scene.alpha_composite(shadow_of(img), (pos[0] + shadow[0], pos[1] + shadow[1]))
        scene.alpha_composite(img, pos)

    def sprite(name, x, y, frame=0, shadow=(1, 2)):
        place(sprites[name][frame], x, y, shadow)

    cx, cy = 240, 138
    sprite("ring", cx, cy, shadow=None)
    sprite("hive", cx, cy, shadow=(2, 3))
    place(sprites["weapon_cannon"][0].rotate(-35, resample=Image.NEAREST, expand=True), cx, cy - 2, shadow=None)

    # The comb's bees at their ring separations (guardian close, sentry far).
    loadout = [
        ("guardian", "light", 0.55, 3), ("orbiter", "honey", 1.0, 4), ("escort", "royal", 1.0, 2),
        ("charger", "fire", 1.10, 2), ("interceptor", "frost", 1.22, 3), ("sentry", "poison", 1.40, 2),
        ("worker", "honey", 0.8, 1),
    ]
    rarity = {"orbiter": "epic", "sentry": "legendary", "interceptor": "rare"}
    base_r = 42
    for n, (shape, elem, rr, count) in enumerate(loadout):
        for i in range(count):
            a = (i / count) * math.tau + n * 0.9
            x, y = cx + math.cos(a) * base_r * rr, cy + math.sin(a) * base_r * rr
            rar = rarity.get(shape) if i == 0 else None
            if rar in ("epic", "legendary"):
                glow = (255, 210, 60) if rar == "legendary" else (190, 120, 255)
                place(tinted(sprites["rarity_aura"][0], glow), x, y, shadow=None)
            place(bee_preview(shape, elem, frame=i % 2), x, y, shadow=(2, 4))
            if rar == "rare":
                place(sprites["rarity_shine"][0], x - 4, y - 1, shadow=None)
            if rar == "legendary":
                place(sprites["rarity_crown"][0], x, y - 8, shadow=None)

    enemies = [
        ("enemy_ant", 150, 40), ("enemy_ant", 170, 58), ("enemy_ant", 300, 36),
        ("enemy_beetle", 330, 70), ("enemy_beetle", 120, 190), ("enemy_spider", 360, 210),
        ("enemy_spider", 100, 90), ("enemy_wasp", 250, 52), ("enemy_wasp", 390, 120),
        ("enemy_slime", 86, 140), ("enemy_slime", 396, 160), ("enemy_ant", 220, 232),
        ("enemy_ironback", 140, 238),
    ]
    for i, (n, x, y) in enumerate(enemies):
        sprite(n, x, y, frame=i % 2, shadow=(1, 3) if "wasp" in n else (1, 1))
    sprite("boss_beetle", 370, 48, shadow=(2, 2))

    for x, y, e in [(215, 95, "honey"), (262, 90, "fire"), (205, 170, "frost"), (285, 180, "poison"), (310, 128, "honey")]:
        place(tinted(sprites["shot_bee"][0], ELEMENTS[e]), x, y, shadow=None)
    sprite("shot_cannon", 212, 110, shadow=(1, 1))
    sprite("shot_cannon", 190, 88, shadow=(1, 1))
    sprite("shot_boss", 352, 72, shadow=None)
    sprite("shot_siege", 170, 205, shadow=(1, 3))
    sprite("fx_spark", 252, 56, frame=0, shadow=None)
    sprite("fx_poof", 118, 94, frame=0, shadow=None)
    for name, x, y in [("pollen_s", 160, 150), ("pollen_m", 320, 200), ("pollen_l", 282, 104), ("pollen_s", 176, 160)]:
        sprite(name, x, y, shadow=(1, 1))
    sprite("pickup_honey", 330, 150, shadow=(1, 1))
    return scale(scene, 4)


def contact_sheet(sprites, tiles):
    k = 6
    cell = 30 * k
    entries = []
    for shape in BEES:
        for f in range(2):
            entries.append((f"bee_{shape}", bee_preview(shape, list(ELEMENTS)[len(entries) // 2 % 8], f)))
    entries += [(f"bee_{s}_tint", sprites[f"bee_{s}_tint"][0]) for s in ("orbiter",)]
    entries += [(f"bee_{s} (base)", sprites[f"bee_{s}"][0]) for s in ("orbiter",)]
    skip = {f"bee_{s}" for s in BEES} | {f"bee_{s}_tint" for s in BEES}
    entries += [(n, f) for n, fs in sprites.items() if n not in skip for f in fs]
    entries += list(tiles.items())
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


def element_sheet():
    """Every bee shape in every element: the one-drawing-many-palettes check."""
    k, pad = 6, 6
    cell = 12 * k + pad * 2
    sheet = Image.new("RGBA", (cell * len(ELEMENTS) + 120, cell * len(BEES)), (38, 34, 46, 255))
    d = ImageDraw.Draw(sheet)
    for r, shape in enumerate(BEES):
        d.text((6, r * cell + cell // 2 - 6), shape, fill=(230, 220, 200, 255))
        for c, elem in enumerate(ELEMENTS):
            img = scale(bee_preview(shape, elem), k)
            sheet.alpha_composite(img, (120 + c * cell + pad, r * cell + pad))
    return sheet


def main():
    for d in (OUT_SPRITES, OUT_UPLOAD, OUT_PREVIEW, os.path.dirname(OUT_LUAU)):
        os.makedirs(d, exist_ok=True)
    for d in (OUT_SPRITES, OUT_UPLOAD):  # clear old output so renamed sprites don't linger
        for f in os.listdir(d):
            os.remove(os.path.join(d, f))
    sprites = build_sprites()
    tiles = build_tiles()

    for name, fs in sprites.items():
        for i, f in enumerate(fs):
            f.save(os.path.join(OUT_SPRITES, f"{name}_{i}.png"))
    for name, t in tiles.items():
        t.save(os.path.join(OUT_SPRITES, f"{name}.png"))
        t.save(os.path.join(OUT_UPLOAD, f"{name}.png"))

    atlas_sprites = {n: fs for n, fs in sprites.items() if not n.startswith("deco_")}
    atlas, rects = pack_atlas(atlas_sprites)
    atlas.save(os.path.join(OUT_UPLOAD, "atlas.png"))
    with open(os.path.join(OUT_UPLOAD, "atlas.json"), "w") as fh:
        json.dump({"size": atlas.size, "sprites": rects}, fh, indent=1)
    write_luau(rects, atlas.size)

    bg = arena_background(sprites, tiles)
    bg.save(os.path.join(OUT_UPLOAD, "arena_bg.png"))

    contact_sheet(sprites, tiles).save(os.path.join(OUT_PREVIEW, "sprite_sheet.png"))
    element_sheet().save(os.path.join(OUT_PREVIEW, "bee_elements.png"))
    mockup(bg, sprites).save(os.path.join(OUT_PREVIEW, "mockup.png"))
    print(f"atlas {atlas.size}, {sum(len(v) for v in atlas_sprites.values())} frames")


if __name__ == "__main__":
    main()
