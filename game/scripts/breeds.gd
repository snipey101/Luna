class_name Breeds
## Breed roster and per-personality tuning. Each breed can override stats.

enum Personality { FRIENDLY, TIMID, AGGRESSIVE }

## Blender builds dogs at this multiple of their nominal size (GLOBAL_SCALE).
const MODEL_SCALE := 1.8

const STATS := {
	Personality.FRIENDLY: {
		"wander_speed": 1.0, "wander_radius": 5.0, "notice": 4.0,
	},
	Personality.TIMID: {
		"wander_speed": 1.3, "wander_radius": 6.0, "notice": 8.0, "notice_sneak": 3.0,
		"flee_speed": 5.5, "flee_time": 3.0, "tired_time": 2.5,
	},
	Personality.AGGRESSIVE: {
		"wander_speed": 1.2, "wander_radius": 3.5, "notice": 7.0,
		"chase_speed": 4.2, "leash": 15.0, "cooldown": 5.0,
		# After a bark: runs off this fast, and can be befriended for this long.
		"scared_speed": 3.8, "scared_time": 3.0,
	},
}

## model: glb under assets/models; scale: rough size for collision/heart height.
const DATA := {
	"golden": {"name": "Golden Retriever", "personality": Personality.FRIENDLY, "scale": 1.35, "count": 2},
	"corgi": {"name": "Corgi", "personality": Personality.FRIENDLY, "scale": 1.0, "count": 2},
	"beagle": {"name": "Beagle", "personality": Personality.FRIENDLY, "scale": 1.1, "count": 2},
	"pug": {"name": "Pug", "personality": Personality.FRIENDLY, "scale": 0.95, "count": 1},
	"chihuahua": {"name": "Chihuahua", "personality": Personality.TIMID, "scale": 0.72, "count": 2,
		"stats": {"flee_speed": 5.2}},
	"whippet": {"name": "Whippet", "personality": Personality.TIMID, "scale": 1.2, "count": 1,
		"stats": {"flee_speed": 6.2, "flee_time": 2.5}},
	"dachshund": {"name": "Dachshund", "personality": Personality.TIMID, "scale": 1.0, "count": 2,
		"stats": {"flee_speed": 5.0, "flee_time": 3.5}},
	"poodle": {"name": "Poodle", "personality": Personality.TIMID, "scale": 1.0, "count": 1},
	"doberman": {"name": "Doberman", "personality": Personality.AGGRESSIVE, "scale": 1.4, "count": 2,
		"stats": {"chase_speed": 4.4}},
	"shepherd": {"name": "German Shepherd", "personality": Personality.AGGRESSIVE, "scale": 1.45, "count": 2,
		"stats": {"chase_speed": 4.0}},
}


static func stats_for(key: String) -> Dictionary:
	var breed: Dictionary = DATA[key]
	return (STATS[breed.personality] as Dictionary).merged(breed.get("stats", {}), true)


static func model_for(key: String) -> PackedScene:
	return load("res://assets/models/dog_%s.glb" % key)
