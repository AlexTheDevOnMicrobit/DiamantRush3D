extends RefCounted
## Génération procédurale d'un parcours. Format d'une étape :
##   [écart, dénivelé, décalage_latéral, largeur_x, largeur_z, type, (cap)]
##   type : n normale | m mobile | f friable | c checkpoint | b trampoline | s tourniquet
##          k clignotante | v tapis roulant | o orbitale | l ascenseur
##   cap  : (optionnel) nouvelle direction 0 = -Z, 1 = +X, 2 = +Z, 3 = -X

const LevelData = preload("res://scripts/level_data.gd")
const HEADINGS: Array[Vector3] = [
	Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0),
]
const UNSTABLE := ["m", "f", "k", "o", "l"]
const MAX_COUNT := 90


## length_mult : 1 / 1.5 / 2 / 3 — diff_setting : 0 détendu, 1 normal, 2 expert
static func generate(seed_value: int, theme_idx: int, run_pos: int = 0, length_mult: float = 1.0, diff_setting: int = 1) -> Dictionary:
	var theme: Dictionary = LevelData.get_themes()[theme_idx]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, theme_idx, run_pos, 7919])

	var diff_off: float = [-1.5, 0.0, 1.5][clampi(diff_setting, 0, 2)]
	var diff := clampf(float(theme["difficulty"]) + diff_off, 0.5, 11.0)
	var count := mini(int((9.0 + diff * 1.8) * length_mult), MAX_COUNT)
	var gap_cap := minf(3.0 + 0.17 * diff, 4.6)
	var base_size := 5.4 - 0.3 * diff
	var cp_every := 4 if diff < 3.0 else (5 if diff < 7.0 else 6)
	var unstable_limit := 2 if diff < 5.0 else 3
	var hazard_scale: float = [0.6, 1.0, 1.4][clampi(diff_setting, 0, 2)]

	var steps: Array = []
	var rects: Array = [] # {min: Vector2, max: Vector2, y: float}
	var pos := Vector3.ZERO
	var heading := 0
	var prev_size := Vector2(8, 8)
	rects.append({"min": Vector2(-4, -4), "max": Vector2(4, 4), "y": 0.0})
	var tops: Array[Vector3] = [Vector3.ZERO]

	var force_next := ""
	var fall_run := 0
	var unstable_run := 0
	var prev_kind := "n"

	for i in count:
		var last := i == count - 1
		var placed := false
		for attempt in 25:
			var kind := _pick_kind(rng, theme["weights"], i, last, force_next, prev_kind, fall_run, attempt, cp_every, unstable_run, unstable_limit, hazard_scale)
			var new_heading := heading
			if i >= 3 and not last and rng.randf() < 0.14 and attempt < 15:
				new_heading = (heading + (1 if rng.randf() < 0.5 else 3)) % 4

			var sz := _pick_size(rng, kind, base_size, last)
			var dy := rng.randf_range(-0.4, 1.1) if kind != "b" else rng.randf_range(0.0, 0.5)
			if force_next == "after_b":
				dy = rng.randf_range(3.0, 3.5)
			var lat := rng.randf_range(-3.0, 3.0) if not (kind in ["m", "o"]) else 0.0
			if prev_kind in ["m", "o"]:
				lat = 0.0
			if absf(lat) < 0.8:
				lat = 0.0
			var gap_max := minf(gap_cap, 4.5 - maxf(dy, 0.0) * 0.8 - (0.4 if absf(lat) > 1.5 else 0.0))
			if kind == "l" or prev_kind == "l":
				gap_max -= 0.4 # l'ascenseur bouge de ±1.6 m en hauteur
			var gap := rng.randf_range(2.4, maxf(2.5, gap_max))
			if kind == "b":
				gap = rng.randf_range(2.6, 3.4)
			if kind == "l":
				dy = rng.randf_range(-0.2, 0.6)

			var f: Vector3 = HEADINGS[new_heading]
			var r: Vector3 = f.cross(Vector3.UP)
			var half_prev := (prev_size.y if new_heading % 2 == 0 else prev_size.x) / 2.0
			var half_new := (sz.y if new_heading % 2 == 0 else sz.x) / 2.0
			var cand := pos + f * (half_prev + gap + half_new) + r * lat + Vector3(0, dy, 0)

			var margin := 1.2
			var ext := Vector2(sz.x / 2.0 + margin, sz.y / 2.0 + margin)
			if kind == "m":
				ext += Vector2(absf(r.x), absf(r.z)) * 2.6
			elif kind == "o":
				ext += Vector2(2.6, 2.6)
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
			tops.append(pos)

			fall_run = fall_run + 1 if kind == "f" else 0
			unstable_run = unstable_run + 1 if kind in UNSTABLE else 0
			force_next = "after_b" if kind == "b" else ""
			prev_kind = kind
			placed = true
			break

		if not placed:
			# repli sûr : plateforme normale tout droit
			var f2: Vector3 = HEADINGS[heading]
			var half_p := (prev_size.y if heading % 2 == 0 else prev_size.x) / 2.0
			pos += f2 * (half_p + 3.0 + 2.0) + Vector3(0, 0.5, 0)
			steps.append([3.0, 0.5, 0.0, 4.0, 4.0, "n"])
			rects.append({"min": Vector2(pos.x, pos.z) - Vector2(3.2, 3.2), "max": Vector2(pos.x, pos.z) + Vector2(3.2, 3.2), "y": pos.y})
			tops.append(pos)
			prev_size = Vector2(4, 4)
			prev_kind = "n"
			force_next = ""
			fall_run = 0
			unstable_run = 0

	# bonus flottants au-dessus de certains vides : [indice_étape, type]
	var powerups: Array = []
	var spacing := 7
	for i in range(4, steps.size() - 1):
		if i % spacing == 0 and rng.randf() < 0.8:
			var s: Array = steps[i]
			if float(s[0]) >= 3.0 and not (str(s[5]) in ["b"]):
				powerups.append([i, "wing" if rng.randf() < 0.5 else "boost"])

	return {
		"name": theme["name"],
		"theme": theme_idx,
		"difficulty": diff,
		"par": 40.0 + count * 6.5,
		"steps": steps,
		"powerups": powerups,
	}


static func _pick_kind(rng: RandomNumberGenerator, weights: Dictionary, i: int, last: bool, force_next: String, prev_kind: String, fall_run: int, attempt: int, cp_every: int, unstable_run: int, unstable_limit: int, hazard_scale: float) -> String:
	if last:
		return "n"
	if force_next == "after_b":
		return "n"
	if i == 0:
		return "n"
	if i % cp_every == cp_every - 1:
		return "c"
	if attempt >= 18 or unstable_run >= unstable_limit:
		return "n"
	var w := weights.duplicate()
	for k in w:
		if k != "n":
			w[k] = float(w[k]) * hazard_scale
	if prev_kind == "s":
		w["s"] = 0.0
	if prev_kind == "k":
		w["k"] = 0.0 # deux dalles clignotantes de suite : impossible à anticiper
	if fall_run >= 3:
		w["f"] = 0.0
	if prev_kind == "b":
		w["b"] = 0.0
		w["l"] = 0.0
		w["o"] = 0.0
	if prev_kind == "m" or prev_kind == "o":
		w["m"] = float(w["m"]) * 0.3
		w["o"] = float(w["o"]) * 0.3
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
		"o":
			s = clampf(s, 3.4, 4.4)
		"l":
			s = clampf(s, 3.4, 4.6)
		"k":
			s = clampf(s, 3.2, 5.0)
		"v":
			s = clampf(s, 3.4, 5.4)
		"c":
			s = maxf(s, 4.0)
		"b":
			s = clampf(s, 2.8, 3.4)
	if rng.randf() < 0.3 and kind != "v":
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
