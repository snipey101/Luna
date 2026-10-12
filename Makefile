GODOT ?= /Applications/Godot.app/Contents/MacOS/Godot
BLENDER ?= /Applications/Blender.app/Contents/MacOS/Blender

.PHONY: run test assets models sounds windows clean

## Play the game on macOS
run:
	$(GODOT) --path game

## Headless gameplay checks
test:
	$(GODOT) --headless --path game res://tests/test_gameplay.tscn

## Rebuild models and sounds, then reimport into Godot
assets: models sounds
	$(GODOT) --headless --path game --import

models:
	BLENDER=$(BLENDER) tools/blender/build_all.sh

sounds:
	python3 tools/audio/make_sounds.py

## Export build/Luna.exe for Windows
windows:
	mkdir -p build
	$(GODOT) --headless --path game --export-release "Windows Desktop" ../build/Luna.exe

clean:
	rm -rf build
