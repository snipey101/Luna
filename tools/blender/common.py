"""Shared helpers for building low-poly, flat-coloured models headlessly.

Blender is Z-up with models facing +Y. The glTF exporter converts to Y-up,
so +Y in Blender becomes -Z (Godot's "forward") after import.
"""
import math
import os

import bpy
from mathutils import Euler, Matrix, Vector

OUT_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "models")
)

_materials = {}


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _materials.clear()


def hex_rgba(hex_str):
    h = hex_str.lstrip("#")
    srgb = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    # Principled base colour is linear; convert from sRGB.
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]
    return (*lin, 1.0)


def material(hex_str, roughness=0.85):
    key = (hex_str, roughness)
    if key in _materials:
        return _materials[key]
    mat = bpy.data.materials.new(name="mat_" + hex_str.lstrip("#"))
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = hex_rgba(hex_str)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular"].default_value = 0.2
    mat.diffuse_color = hex_rgba(hex_str)  # used by workbench previews
    _materials[key] = mat
    return mat


def world_pos(obj):
    """World position for un-rotated, un-scaled hierarchies (matrix_world
    is stale until a depsgraph update, so sum locations instead)."""
    p = Vector(obj.location)
    while obj.parent is not None:
        obj = obj.parent
        p += obj.location
    return p


def _finish(obj, name, color, pivot, offset, parent, smooth):
    """Move mesh so `pivot` is the object origin, then parent."""
    obj.name = name
    obj.data.name = name
    # Mesh currently centred at origin; shift so its centre sits at `offset`
    # relative to the pivot.
    obj.data.transform(Matrix.Translation(Vector(offset)))
    obj.location = Vector(pivot)
    if color:
        obj.data.materials.append(material(color))
    if smooth:
        for p in obj.data.polygons:
            p.use_smooth = True
    if parent is not None:
        # Store pivot in parent space (parent has no rotation/scale).
        obj.parent = parent
        obj.location = Vector(pivot) - world_pos(parent)
    return obj


def ellipsoid(name, radii, center, color, pivot=None, parent=None,
              segments=18, rings=10, smooth=True, rot=(0, 0, 0)):
    """Ellipsoid whose centre is at `center`; object origin at `pivot`."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1.0)
    obj = bpy.context.active_object
    obj.data.transform(Matrix.Diagonal((*radii, 1.0)))
    obj.data.transform(Euler(rot).to_matrix().to_4x4())
    pivot = center if pivot is None else pivot
    offset = Vector(center) - Vector(pivot)
    return _finish(obj, name, color, pivot, offset, parent, smooth)


def cone(name, r1, depth, center, color, rot=(0, 0, 0), pivot=None,
         parent=None, verts=12, r2=0.0, smooth=True):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=depth)
    obj = bpy.context.active_object
    obj.data.transform(Matrix.Rotation(rot[0], 4, "X"))
    obj.data.transform(Matrix.Rotation(rot[1], 4, "Y"))
    obj.data.transform(Matrix.Rotation(rot[2], 4, "Z"))
    pivot = center if pivot is None else pivot
    offset = Vector(center) - Vector(pivot)
    return _finish(obj, name, color, pivot, offset, parent, smooth)


def cylinder(name, radius, depth, center, color, rot=(0, 0, 0), pivot=None,
             parent=None, verts=12, smooth=False):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth)
    obj = bpy.context.active_object
    obj.data.transform(Matrix.Rotation(rot[0], 4, "X"))
    obj.data.transform(Matrix.Rotation(rot[1], 4, "Y"))
    obj.data.transform(Matrix.Rotation(rot[2], 4, "Z"))
    pivot = center if pivot is None else pivot
    offset = Vector(center) - Vector(pivot)
    return _finish(obj, name, color, pivot, offset, parent, smooth)


def box(name, size, center, color, pivot=None, parent=None, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    obj = bpy.context.active_object
    obj.data.transform(Matrix.Diagonal((*size, 1.0)))
    if bevel > 0:
        mod = obj.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier="bevel")
    pivot = center if pivot is None else pivot
    offset = Vector(center) - Vector(pivot)
    return _finish(obj, name, color, pivot, offset, parent, smooth=bevel > 0)


def empty(name, location=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = Vector(location)
    if parent is not None:
        obj.parent = parent
        obj.location = Vector(location) - world_pos(parent)
    return obj


def export_glb(filename):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, filename)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )
    print("exported", path)
    return path


DEG = math.pi / 180.0
