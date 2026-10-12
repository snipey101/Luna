"""Build Luna and every breed as a .glb.

Run: Blender -b -P make_dogs.py [-- --preview /path/to/lineup.png]

Node names the game relies on: Body, Head, EarL, EarR, LegFL, LegFR,
LegBL, LegBR, Tail.
"""
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(__file__))
from common import (DEG, cone, cylinder, ellipsoid, empty, export_glb,  # noqa: E402
                    reset_scene)

GLOBAL_SCALE = 1.8  # keep in sync with Breeds.MODEL_SCALE in the game

EYE = "#241C1C"
NOSE = "#2A2222"
CHEEK = "#F4A3A8"
WHITE = "#FFFFFF"

BASE = dict(
    s=1.0,
    body=(0.17, 0.26, 0.20),   # width, length, height (full extents)
    leg_len=0.14, leg_r=0.055,
    head_r=0.17,
    snout=(0.09, 0.07),        # length, radius
    snout_color=None,
    ears="floppy", ear_len=0.13,
    tail="straight",
    main="#F2CC8F", light="#FBE3B8", ear_color=None, paw_color=None,
    saddle=None, chest=None, tail_tip=None,
    brows=False, collar=None, fluffy=False,
)

BREEDS = {
    "luna": dict(main="#F2CC8F", light="#FBE3B8", ear_color="#E3B475",
                 collar="#E5484D"),
    "golden": dict(s=1.35, main="#D9963A", light="#EDB868", ear_color="#C98530",
                   ear_len=0.15, tail="fluffy", head_r=0.16),
    "corgi": dict(body=(0.19, 0.33, 0.18), leg_len=0.07, leg_r=0.05,
                  main="#E08A3C", light="#FFF4E6", chest="#FFF4E6",
                  paw_color="#FFF4E6", snout_color="#FFF4E6",
                  ears="pointy_big", tail="stub"),
    "beagle": dict(s=1.1, main="#FFF8EC", light="#FFF8EC", saddle="#3B2A20",
                   ear_color="#9B5A2B", ear_len=0.15, tail="up", tail_tip=WHITE,
                   snout_color="#FFF8EC"),
    "pug": dict(s=0.95, body=(0.2, 0.25, 0.21), main="#E8D3A8", light="#E8D3A8",
                snout=(0.05, 0.08), snout_color="#3A3030", ears="small",
                ear_color="#3A3030", tail="curl", head_r=0.18),
    "chihuahua": dict(s=0.72, body=(0.15, 0.22, 0.17), leg_r=0.04, leg_len=0.15,
                      main="#E9C38C", light="#F6E2C2", ears="pointy_huge",
                      snout=(0.06, 0.055), tail="up", head_r=0.18),
    "whippet": dict(s=1.2, body=(0.14, 0.3, 0.17), leg_len=0.22, leg_r=0.038,
                    main="#B9B2AD", light="#F2EEEA", chest="#F2EEEA",
                    ears="small", ear_color="#9C948F", snout=(0.11, 0.055),
                    tail="thin", head_r=0.14),
    "dachshund": dict(body=(0.15, 0.44, 0.17), leg_len=0.06, leg_r=0.045,
                      main="#8B4A26", light="#A9643A", ear_color="#6E3519",
                      ear_len=0.14, snout=(0.11, 0.06), tail="thin", head_r=0.15),
    "poodle": dict(main="#FBF7F2", light="#FBF7F2", ears="pom", ear_color="#F1E8DE",
                   tail="pom", fluffy=True, leg_r=0.045, leg_len=0.17,
                   snout=(0.09, 0.055)),
    "doberman": dict(s=1.4, body=(0.16, 0.28, 0.19), leg_len=0.18, leg_r=0.045,
                     main="#2E2828", light="#B86B2E", paw_color="#B86B2E",
                     snout_color="#B86B2E", ears="pointy", tail="stub",
                     brows=True, head_r=0.15, snout=(0.11, 0.06)),
    "shepherd": dict(s=1.45, body=(0.17, 0.3, 0.2), leg_len=0.17, leg_r=0.05,
                     main="#C47A3A", light="#D9A066", saddle="#2A2420",
                     snout_color="#2A2420", ears="pointy", tail="fluffy",
                     tail_tip="#2A2420", brows=True, head_r=0.15,
                     snout=(0.11, 0.065)),
}


def build_dog(key, params, origin=(0.0, 0.0, 0.0)):
    p = dict(BASE)
    p.update(params)
    s = p["s"] * GLOBAL_SCALE
    ox, oy, oz = origin
    W, L, H = (d * s for d in p["body"])
    leg_len, leg_r = p["leg_len"] * s, p["leg_r"] * s
    hr = p["head_r"] * s
    sn_len, sn_r = (d * s for d in p["snout"])
    ear_len = p["ear_len"] * s
    main, light = p["main"], p["light"]
    ear_col = p["ear_color"] or main
    paw_col = p["paw_color"] or light
    snout_col = p["snout_color"] or light

    root = empty(key, (ox, oy, oz))
    body_z = oz + leg_len + H * 0.4
    body_c = (ox, oy, body_z)
    body = ellipsoid("Body", (W / 2, L / 2, H / 2), body_c, main, parent=root)
    if p["fluffy"]:
        for i, yy in enumerate((-0.25, 0.3)):
            ellipsoid("Fluff%d" % i, (W * 0.62, L * 0.32, H * 0.62),
                      (ox, oy + L * yy, body_z + H * 0.05), main, parent=body)
    if p["saddle"]:
        ellipsoid("Saddle", (W * 0.52, L * 0.4, H * 0.3),
                  (ox, oy - L * 0.05, body_z + H * 0.22), p["saddle"], parent=body)
    if p["chest"]:
        ellipsoid("Chest", (W * 0.38, L * 0.2, H * 0.38),
                  (ox, oy + L * 0.33, body_z - H * 0.05), p["chest"], parent=body)

    # Legs: pivot at shoulder/hip so the game can swing them.
    hip_z = body_z - H * 0.1
    for name, sx, sy in (("LegFL", -1, 1), ("LegFR", 1, 1),
                         ("LegBL", -1, -1), ("LegBR", 1, -1)):
        px, py = ox + sx * W * 0.3, oy + sy * L * 0.32
        leg = ellipsoid(name, (leg_r, leg_r, (hip_z - oz) / 2 + leg_r * 0.3),
                        (px, py, oz + (hip_z - oz) / 2 + leg_r * 0.3), main,
                        pivot=(px, py, hip_z), parent=body, segments=12, rings=8)
        ellipsoid(name + "Paw", (leg_r * 1.15, leg_r * 1.35, leg_r * 0.75),
                  (px, py + leg_r * 0.25, oz + leg_r * 0.7), paw_col,
                  parent=leg, segments=12, rings=8)

    # Head: pivot at the neck.
    neck = (ox, oy + L * 0.38, body_z + H * 0.3)
    hc = (ox, neck[1] + hr * 0.35, neck[2] + hr * 0.7)
    head = ellipsoid("Head", (hr * 1.05, hr * 0.95, hr), hc, main, pivot=neck,
                     parent=body)
    hx, hy, hz = hc
    if p["collar"]:
        cylinder("Collar", hr * 0.62, hr * 0.18, (ox, neck[1] + hr * 0.05, neck[2] + hr * 0.1),
                 p["collar"], rot=(-20 * DEG, 0, 0), parent=head, verts=16)
        ellipsoid("Tag", (hr * 0.1, hr * 0.04, hr * 0.12),
                  (ox, neck[1] + hr * 0.62, neck[2] - hr * 0.08), "#F7C948", parent=head)

    # Snout and nose
    sy = hy + hr * 0.8
    sz = hz - hr * 0.3
    ellipsoid("Snout", (sn_r * 1.2, sn_len, sn_r * 0.85), (hx, sy, sz), snout_col,
              parent=head)
    ellipsoid("Nose", (sn_r * 0.5, sn_r * 0.35, sn_r * 0.38),
              (hx, sy + sn_len * 0.9, sz + sn_r * 0.45), NOSE, parent=head)

    # Eyes with highlights
    for sx, tag in ((-1, "L"), (1, "R")):
        ex, ey, ez = hx + sx * hr * 0.42, hy + hr * 0.8, hz + hr * 0.15
        ellipsoid("Eye" + tag, (hr * 0.13, hr * 0.08, hr * 0.15), (ex, ey, ez), EYE,
                  parent=head, segments=12, rings=8)
        ellipsoid("Shine" + tag, (hr * 0.045,) * 3,
                  (ex + hr * 0.04, ey + hr * 0.065, ez + hr * 0.06), WHITE,
                  parent=head, segments=8, rings=6)
        ellipsoid("Cheek" + tag, (hr * 0.14, hr * 0.05, hr * 0.09),
                  (hx + sx * hr * 0.66, hy + hr * 0.66, hz - hr * 0.2), CHEEK,
                  parent=head, segments=10, rings=6)
        if p["brows"]:
            ellipsoid("Brow" + tag, (hr * 0.2, hr * 0.05, hr * 0.05),
                      (ex - sx * hr * 0.02, ey + hr * 0.03, ez + hr * 0.24), EYE,
                      rot=(0, sx * 25 * DEG, 0), parent=head, segments=8, rings=6)

    # Ears: pivot at their base so they can flop.
    ears = p["ears"]
    for sx, tag in ((-1, "L"), (1, "R")):
        if ears == "floppy":
            base = (hx + sx * hr * 0.82, hy - hr * 0.05, hz + hr * 0.55)
            ellipsoid("Ear" + tag, (hr * 0.2, hr * 0.42, ear_len),
                      (base[0] + sx * hr * 0.1, base[1], base[2] - ear_len * 0.75),
                      ear_col, pivot=base, rot=(0, -sx * 12 * DEG, 0), parent=head)
        elif ears.startswith("pointy"):
            size = {"pointy": 1.0, "pointy_big": 1.3, "pointy_huge": 1.75}[ears]
            r1, depth = hr * 0.3 * size, hr * 0.62 * size
            base = (hx + sx * hr * 0.55, hy - hr * 0.1, hz + hr * 0.72)
            cone("Ear" + tag, r1, depth,
                 (base[0] + sx * depth * 0.18, base[1], base[2] + depth * 0.42),
                 ear_col, rot=(0, sx * 22 * DEG, 0), pivot=base, parent=head,
                 verts=10)
        elif ears == "small":
            base = (hx + sx * hr * 0.78, hy, hz + hr * 0.62)
            ellipsoid("Ear" + tag, (hr * 0.22, hr * 0.12, hr * 0.2),
                      (base[0] + sx * hr * 0.12, base[1] + hr * 0.08, base[2] - hr * 0.08),
                      ear_col, pivot=base, rot=(0, -sx * 35 * DEG, 0), parent=head)
        elif ears == "pom":
            base = (hx + sx * hr * 0.85, hy, hz + hr * 0.4)
            ellipsoid("Ear" + tag, (hr * 0.3, hr * 0.3, hr * 0.42),
                      (base[0] + sx * hr * 0.12, base[1], base[2] - hr * 0.35),
                      ear_col, pivot=base, parent=head)
    if p["fluffy"]:
        ellipsoid("TopKnot", (hr * 0.55, hr * 0.5, hr * 0.42),
                  (hx, hy - hr * 0.05, hz + hr * 0.85), main, parent=head)

    # Tail: pivot at its base so it can wag.
    tb = (ox, oy - L * 0.45, body_z + H * 0.22)
    tail = p["tail"]
    tip = p["tail_tip"]
    if tail in ("straight", "fluffy", "thin", "up"):
        thick = {"straight": 0.045, "fluffy": 0.07, "thin": 0.03, "up": 0.04}[tail] * s
        length = {"straight": 0.16, "fluffy": 0.17, "thin": 0.17, "up": 0.13}[tail] * s
        ang = {"straight": 40, "fluffy": 35, "thin": 25, "up": 10}[tail] * DEG
        c = (ox, tb[1] - length * 0.55 * _sin(ang), tb[2] + length * 0.5 * _cos(ang))
        t = ellipsoid("Tail", (thick, thick, length * 0.6), c, main, pivot=tb,
                      rot=(ang, 0, 0), parent=body, segments=12, rings=8)
        if tip:
            ellipsoid("TailTip", (thick * 1.05,) * 2 + (length * 0.22,),
                      (ox, tb[1] - length * 1.0 * _sin(ang), tb[2] + length * 0.95 * _cos(ang)),
                      tip, rot=(ang, 0, 0), parent=t, segments=10, rings=6)
    elif tail == "stub":
        ellipsoid("Tail", (0.04 * s,) * 3, (ox, tb[1] - 0.02 * s, tb[2] + 0.02 * s),
                  main, pivot=tb, parent=body, segments=10, rings=6)
    elif tail == "curl":
        ellipsoid("Tail", (0.05 * s, 0.05 * s, 0.05 * s),
                  (ox, tb[1] + 0.01 * s, tb[2] + 0.06 * s), main, pivot=tb,
                  parent=body, segments=12, rings=8)
    elif tail == "pom":
        t = ellipsoid("Tail", (0.025 * s, 0.025 * s, 0.07 * s),
                      (ox, tb[1] - 0.03 * s, tb[2] + 0.06 * s), main, pivot=tb,
                      rot=(25 * DEG, 0, 0), parent=body, segments=10, rings=6)
        ellipsoid("TailPom", (0.065 * s,) * 3, (ox, tb[1] - 0.06 * s, tb[2] + 0.13 * s),
                  main, parent=t, segments=12, rings=8)
    return root


def _sin(a):
    import math
    return math.sin(a)


def _cos(a):
    import math
    return math.cos(a)


def render_preview(path):
    reset_scene()
    x = 0.0
    for key, params in BREEDS.items():
        s = params.get("s", 1.0) * GLOBAL_SCALE
        x += 0.45 * s
        build_dog(key, params, origin=(x, 0, 0)).rotation_euler = (0, 0, 30 * DEG)
        x += 0.45 * s
    scene = bpy.context.scene
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = x * 1.05
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = (x / 2, 6, 2.4)
    cam.rotation_euler = (72 * DEG, 0, 180 * DEG)
    scene.camera = cam
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.render.resolution_x = 2000
    scene.render.resolution_y = 500
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    for key, params in BREEDS.items():
        reset_scene()
        build_dog(key, params)
        export_glb("dog_%s.glb" % key)
    if "--preview" in argv:
        render_preview(argv[argv.index("--preview") + 1])


main()
