"""Build scenery props as .glb. Run: Blender -b -P make_props.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from common import (DEG, box, cone, cylinder, ellipsoid, empty, export_glb,  # noqa: E402
                    reset_scene)

TRUNK = "#9A6B4B"
LEAF = "#7CC46A"
LEAF_DARK = "#5FAE57"
WOOD = "#F3E3C7"
ROCK = "#B8B4AE"


def tree_round():
    root = empty("TreeRound")
    cylinder("Trunk", 0.22, 1.4, (0, 0, 0.7), TRUNK, parent=root, verts=10)
    ellipsoid("Canopy", (1.1, 1.1, 1.0), (0, 0, 2.1), LEAF, parent=root, segments=14, rings=8)
    ellipsoid("Canopy2", (0.7, 0.7, 0.65), (0.45, 0.3, 2.75), LEAF, parent=root,
              segments=12, rings=7)
    export_glb("tree_round.glb")


def tree_pine():
    root = empty("TreePine")
    cylinder("Trunk", 0.18, 0.8, (0, 0, 0.4), TRUNK, parent=root, verts=10)
    for i, (r, z) in enumerate(((1.0, 1.2), (0.78, 1.9), (0.52, 2.55))):
        cone("Tier%d" % i, r, 1.0, (0, 0, z), LEAF_DARK, parent=root, verts=10)
    export_glb("tree_pine.glb")


def bush():
    root = empty("Bush")
    for i, (x, y, r) in enumerate(((0, 0, 0.5), (0.4, 0.15, 0.38), (-0.35, 0.1, 0.36))):
        ellipsoid("Blob%d" % i, (r, r, r * 0.85), (x, y, r * 0.7), LEAF, parent=root,
                  segments=12, rings=7)
    export_glb("bush.glb")


def fence():
    """One 2 m fence segment along +X, starting at the origin."""
    root = empty("Fence")
    for i, x in enumerate((0.0, 2.0)):
        box("Post%d" % i, (0.16, 0.16, 0.8), (x, 0, 0.4), WOOD, parent=root, bevel=0.03)
        cone("Cap%d" % i, 0.115, 0.1, (x, 0, 0.85), WOOD, rot=(0, 0, 45 * DEG),
             parent=root, verts=4, smooth=False)
    for i, z in enumerate((0.3, 0.6)):
        box("Rail%d" % i, (2.0, 0.08, 0.12), (1.0, 0, z), WOOD, parent=root, bevel=0.02)
    export_glb("fence.glb")


def rock():
    root = empty("Rock")
    ellipsoid("Rock0", (0.5, 0.4, 0.3), (0, 0, 0.18), ROCK, parent=root,
              segments=8, rings=5, smooth=False)
    ellipsoid("Rock1", (0.28, 0.25, 0.2), (0.38, 0.2, 0.1), ROCK, parent=root,
              segments=7, rings=4, smooth=False)
    export_glb("rock.glb")


def flowers():
    root = empty("Flowers")
    colors = ("#FF8FAB", "#FFD166", "#FFFFFF", "#B39DDB")
    spots = ((0, 0), (0.18, 0.1), (-0.12, 0.16), (0.05, -0.17), (-0.2, -0.08))
    for i, (x, y) in enumerate(spots):
        cylinder("Stem%d" % i, 0.012, 0.18, (x, y, 0.09), LEAF_DARK, parent=root, verts=5)
        ellipsoid("Petal%d" % i, (0.05, 0.05, 0.025), (x, y, 0.19), colors[i % 4],
                  parent=root, segments=8, rings=4)
        ellipsoid("Middle%d" % i, (0.02,) * 3, (x, y, 0.21), "#FFB347",
                  parent=root, segments=6, rings=4)
    export_glb("flowers.glb")


def food_bowl():
    """Luna's food. The game hides `Kibble` when the bowl is empty."""
    root = empty("FoodBowl")
    cylinder("Bowl", 0.22, 0.1, (0, 0, 0.05), "#5DA9E9", parent=root, verts=16, smooth=True)
    ellipsoid("Kibble", (0.18, 0.18, 0.07), (0, 0, 0.1), "#B07A4A", parent=root,
              segments=12, rings=6, smooth=False)
    export_glb("food_bowl.glb")


def heart():
    """Floats above befriended dogs. Built facing +Y (towards the camera side)."""
    root = empty("Heart")
    pink = "#FF6F91"
    for i, sx in enumerate((-1, 1)):
        ellipsoid("Lobe%d" % i, (0.13, 0.08, 0.13), (sx * 0.1, 0, 0.05), pink, parent=root,
                  segments=14, rings=8)
    cone("Point", 0.2, 0.26, (0, 0, -0.1), pink, rot=(180 * DEG, 0, 0), parent=root,
         verts=16)
    export_glb("heart.glb")


for fn in (tree_round, tree_pine, bush, fence, rock, flowers, food_bowl, heart):
    reset_scene()
    fn()
