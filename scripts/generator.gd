extends RefCounted
## Génération procédurale d'un parcours (même format d'étapes que décrit dans level_data.gd) :
##   [écart, dénivelé, décalage_latéral, largeur_x, largeur_z, type, (cap)]

const LevelData = preload("res://scripts/level_data.gd")
const HEADINGS: Array[Vector3] = [
	Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0),
]


static func generate(seed_value: int, stage: int) -> Dictionary:
	var theme: Dictionary = LevelData.get_themes()[stage]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, stage, 7919])

	var count := 13 + stage * 3
	var gap_cap := 3.3 + 0.3 * stage
	var base_size := 4.8 - 0.45 * stage

	var steps: Array = []
	var rects: Array = [] # {min: Vector2, max: Vector2, y: float}
	var pos := Vector3.ZERO
	var heading := 0
	var prev_size := Vector2(8, 8)
	rects.append({"min": Vector2(-4, -4), "max": Vector2(4, 4), "y": 0.0})

	var force_next := ""
	var fall_run := 0
	var prev_kind := "n"

	for i in count:
		var last := i == count - 1
		var placed := false
		for attempt in 25:
			var kind := _pick_kind(rng, theme["weights"], i, last, force_next, prev_kind, fall_run, attempt)
			var new_heading := heading
			if i >= 3 and not last and rng.randf() < 0.14 and attempt < 15:
				new_heading = (heading + (1 if rng.randf() < 0.5 else 3)) % 4

			var sz := _pick_size(rng, kind, base_size, last)
			var dy := rng.randf_range(-0.4, 1.1) if kind != "b" else rng.randf_range(0.0, 0.5)
			if force_next == "after_b":
				dy = rng.randf_range(3.0, 3.5)
			var lat := rng.randf_range(-3.0, 3.0) if kind != "m" else 0.0
			if prev_kind == "m":
				lat = 0.0
			if abs(lat) < 0.8:
				lat = 0.0
			var gap_max := minf(gap_cap, 4.5 - maxf(dy, 0.0) * 0.8 - (0.4 if absf(lat) > 1.5 else 0.0))
			var gap := rng.randf_range(2.4, maxf(2.5, gap_max))
			if kind == "b":
				gap = rng.randf_range(2.6, 3.4)

			var f: Vector3 = HEADINGS[new_heading]
			var r: Vector3 = f.cross(Vector3.UP)
			var half_prev := (prev_size.y if new_heading % 2 == 0 else prev_size.x) / 2.0
			var half_new := (sz.y if new_heading % 2 == 0 else sz.x) / 2.0
			var cand := pos + f * (half_prev + gap + half_new) + r * lat + Vector3(0, dy, 0)

			var margin := 1.2
			var ext := Vector2(sz.x / 2.0 + margin, sz.y / 2.0 + margin)
			if kind == "m":
				ext += Vector2(absf(r.x), absf(r.z)) * 2.6
			var rect := {
				"min": Vector2(cand.x, cand.z) - ext,
				"max": Vector2(cand.x, cand.z) + ext,
				"y": cand.y,
			}
			if _overlaps(rect, rects):
				continue

			var step: Array = [snappedf(gap, 0.1), snappedf(dy, 0.1), snappedf(lat, 0.1), snappedf(sz.x, 0.1), snappedf(sz.y, 0.1), kind]
			if new_heading != heading:
				step.append(new_heading)
			steps.append(step)
			rects.append(rect)
			heading = new_heading
			pos = cand
			prev_size = sz

			fall_run = fall_run + 1 if kind == "f" else 0
			force_next = "after_b" if kind == "b" else ""
			prev_kind = kind
			placed = true
			break

		if not placed:
			# repli sûr : plateforme normale tout droit, au-dessus de tout
			var sz2 := Vector2(4, 4)
			var f2: Vector3 = HEADINGS[heading]
			var half_p := (prev_size.y if heading % 2 == 0 else prev_size.x) / 2.0
			pos += f2 * (half_p + 3.0 + 2.0) + Vector3(0, 0.5, 0)
			steps.append([3.0, 0.5, 0.0, 4.0, 4.0, "n"])
			rects.append({"min": Vector2(pos.x, pos.z) - Vector2(3.2, 3.2), "max": Vector2(pos.x, pos.z) + Vector2(3.2, 3.2), "y": pos.y})
			prev_size = sz2
			prev_kind = "n"
			force_next = ""
			fall_run = 0

	return {
		"name": theme["name"],
		"theme": stage,
		"par": 40.0 + count * 7.0,
		"steps": steps,
	}


static func _pick_kind(rng: RandomNumberGenerator, weights: Dictionary, i: int, last: bool, force_next: String, prev_kind: String, fall_run: int, attempt: int) -> String:
	if last:
		return "n"
	if force_next == "after_b":
		return "n"
	if i == 0:
		return "n"
	if i % 5 == 4:
		return "c"
	if attempt >= 18:
		return "n"
	var w := weights.duplicate()
	if prev_kind == "s":
		w["s"] = 0.0
	if fall_run >= 3:
		w["f"] = 0.0
	if prev_kind == "b":
		w["b"] = 0.0
	if prev_kind == "m":
		w["m"] = w["m"] * 0.3
	var total := 0.0
	for k in w:
		total += float(w[k])
	var roll := rng.randf() * total
	for k in w:
		roll -= float(w[k])
		if roll <= 0.0:
			return String(k)
	return "n"


static func _pick_size(rng: RandomNumberGenerator, kind: String, base: float, last: bool) -> Vector2:
	if last:
		return Vector2(7, 7)
	var s := clampf(base + rng.randf_range(-0.8, 1.0), 2.6, 6.0)
	match kind:
		"s":
			s = maxf(s, 5.0)
		"m":
			s = clampf(s, 3.2, 4.2)
		"c":
			s = maxf(s, 4.0)
		"b":
			s = clampf(s, 2.8, 3.4)
	if rng.randf() < 0.3:
		return Vector2(s, clampf(s + rng.randf_range(-0.8, 0.8), 2.6, 6.0))
	return Vector2(s, s)


static func _overlaps(rect: Dictionary, rects: Array) -> bool:
	# la dernière plateforme (voisine directe) est ignorée
	for j in range(rects.size() - 1):
		var o: Dictionary = rects[j]
		if absf(float(o["y"]) - float(rect["y"])) > 7.0:
			continue
		var a_min: Vector2 = rect["min"]
		var a_max: Vector2 = rect["max"]
		var b_min: Vector2 = o["min"]
		var b_max: Vector2 = o["max"]
		if a_min.x < b_max.x and a_max.x > b_min.x and a_min.y < b_max.y and a_max.y > b_min.y:
			return true
	return false
