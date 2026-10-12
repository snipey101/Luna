extends Node
## Tiny sound player. Sfx.play("bark") with optional pitch wobble.

const SOUNDS := {
	"bark": preload("res://assets/audio/bark.wav"),
	"chime": preload("res://assets/audio/chime.wav"),
	"whimper": preload("res://assets/audio/whimper.wav"),
	"step": preload("res://assets/audio/step.wav"),
	"win": preload("res://assets/audio/win.wav"),
}
const MUSIC := preload("res://assets/audio/music.wav")

var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.stream = MUSIC
	_music.volume_db = -12.0
	_music.finished.connect(_music.play)
	add_child(_music)


func play(sound: String, volume_db := 0.0, pitch_wobble := 0.08) -> void:
	for p in _pool:
		if not p.playing:
			p.stream = SOUNDS[sound]
			p.volume_db = volume_db
			p.pitch_scale = 1.0 + randf_range(-pitch_wobble, pitch_wobble)
			p.play()
			return


func start_music() -> void:
	if not _music.playing:
		_music.play()


func stop_music() -> void:
	_music.stop()
