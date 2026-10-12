#!/bin/sh
# Rebuild every model into game/assets/models/.
# Usage: tools/blender/build_all.sh [--preview out.png]
set -e
BLENDER="${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}"
DIR="$(cd "$(dirname "$0")" && pwd)"
"$BLENDER" -b -P "$DIR/make_dogs.py" -- "$@" | grep -E "exported|Error|Traceback" || true
"$BLENDER" -b -P "$DIR/make_props.py" | grep -E "exported|Error|Traceback" || true
