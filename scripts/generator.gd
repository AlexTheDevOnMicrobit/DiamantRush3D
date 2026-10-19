extends RefCounted
## Génération procédurale d'un parcours. Format d'une étape :
##   [écart, dénivelé, décalage_latéral, largeur_x, largeur_z, type, (cap)]
##   type : n normale | m mobile | f friable | c checkpoint | b trampoline | s tourniquet
##          k clignotante | v tapis roulant | o orbitale | l ascenseur
##          t canon | j lanceur | y interrupteur | z pont | p portail (entrée) | q portail (sortie)
##          r bumper | g plaque de glace | h dalle qui rétrécit | w tapis de vent | a aimant à pièces
##   cap  : (optionnel) nouvelle direction 0 = -Z, 1 = +X, 2 = +Z, 3 = -X

const LevelData = preload("res://scripts/level_data.gd")
const HEADINGS: Array[Vector3] = [
	Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0),
]
const UNSTABLE := ["m", "f", "k", "o", "l", "z"]
const ALL_KINDS := ["n", "m", "f", "s", "b", "k", "v", "o", "l", "t", "j", "y", "p", "r", "g", "h", "w", "a"]
const MAX_COUNT := 90
const BOSS_WORLDS := [2, 5, 8, 11, 14]


static func is_boss_world(theme_idx: int) -> bool:
	return theme_idx in BOSS_WORLDS


## length_mult : 1 / 1.5 / 2 / 3 — diff_setting : 0 détendu, 1 normal, 2 expert
## extra : {diff_bonus: float (mode infini), allow_boss: bool, count_mult: float}
static func generate(seed_value: int, theme_idx: int, run_pos: int = 0, length_mult: float = 1.0, diff_setting: int = 1, extra: Dictionary = {}) -> Dictionary:
	var theme: Dictionary = LevelData.get_themes()[theme_idx]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, theme_idx, run_pos, 7919])

	var diff_off: float = [-1.5, 0.0, 1.5][clampi(diff_setting, 0, 2)]
	var diff := clampf(float(theme["difficulty"]) + diff_off + float(extra.get("diff_bonus", 0.0)), 0.5, 14.0)
	var boss: bool = is_boss_world(theme_idx) and bool(extra.get("allow_boss", true))
	var count := mini(int((9.0 + minf(diff, 11.0) * 1.8) * length_mult * float(extra.get("count_mult", 1.0))), MAX_COUNT)
	count = maxi(count, 6)
	var gap_cap := minf(3.0 + 0.17 * minf(diff, 11.0), 4.6)
	var base_size := maxf(5.4 - 0.3 * minf(diff, 11.0), 2.6)
	var cp_every := 4 if diff < 3.0 else (5 if diff < 7.0 else 6)
	var unstable_limit := 2 if diff < 5.0 else 3
	var hazard_scale: float = [0.6, 1.0, 1.4][clampi(diff_setting, 0, 2)]

	var steps: Array = []
	var rects: Array = [] # {min: Vector2, max: Vector2, y: float}
	var pos := Vector3.ZERO
	var heading := 0
	var prev_size := Vector2(8, 8)
	rects.append({"min": Vector2(-4, -4), "max": Vector2(4, 4), "y": 0.0})

	var force_next := ""
	var fall_run := 0
	var unstable_run := 0
	var prev_kind := "n"
	var hazard_run := 0

	for i in count:
		var last := i == count - 1
		var placed := false
		for attempt in 25:
			var kind := _pick_kind(rng, theme["weights"], i, last, force_next, prev_kind, fall_run, attempt, cp_every, unstable_run, unstable_limit, hazard_scale, hazard_run, count)
			var new_heading := heading
			if i >= 3 and not last and rng.randf() < 0.14 and attempt < 15 and force_next == "":
				new_heading = (heading + (1 if rng.randf() < 0.5 else 3)) % 4

			var sz := _pick_size(rng, kind, base_size, last, boss)
			var dy := rng.randf_range(-0.4, 1.1) if kind != "b" else rng.randf_range(0.0, 0.5)
			if force_next == "after_b":
				dy = rng.randf_range(3.0, 3.5)
			var lat := rng.randf_range(-3.0, 3.0) if not (kind in ["m", "o", "p", "j", "q"]) else 0.0
			if prev_kind in ["m", "o", "p", "j"]:
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
			if force_next == "after_j":
				gap = rng.randf_range(4.6, 5.6)   # le lanceur franchit un grand vide
				dy = rng.randf_range(-0.5, 0.4)
				lat = 0.0
			elif force_next == "after_p":
				gap = rng.randf_range(8.0, 12.0)  # seul le portail permet de traverser
				dy = rng.randf_range(-0.5, 1.0)
				lat = 0.0
			elif force_next == "after_y":
				gap = rng.randf_range(3.0, 4.0)   # le pont n'est solide qu'après l'interrupteur
				dy = rng.randf_range(-0.2, 0.4)
				lat = 0.0

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

			fall_run = fall_run + 1 if kind == "f" else 0
			unstable_run = unstable_run + 1 if kind in UNSTABLE else 0
			hazard_run = hazard_run + 1 if kind in ["t", "s"] else 0
			match kind:
				"b": force_next = "after_b"
				"j": force_next = "after_j"
				"p": force_next = "after_p"
				"y": force_next = "after_y"
				_: force_next = ""
			prev_kind = kind
			placed = true
			break

		if not placed:
			# repli sûr : plateforme normale tout droit (une paire interrompue redevient une dalle normale)
			if (force_next == "after_p" or force_next == "after_y") and steps.size() > 0:
				(steps[steps.size() - 1] as Array)[5] = "n"
			var f2: Vector3 = HEADINGS[heading]
			var half_p := (prev_size.y if heading % 2 == 0 else prev_size.x) / 2.0
			pos += f2 * (half_p + 3.0 + 2.0) + Vector3(0, 0.5, 0)
			var fs := Vector2(4, 4)
			if last:
				fs = Vector2(22, 22) if boss else Vector2(7, 7)
				pos += f2 * (fs.y * 0.5 - 2.0)
			steps.append([3.0, 0.5, 0.0, fs.x, fs.y, "n"])
			rects.append({"min": Vector2(pos.x, pos.z) - fs * 0.5 - Vector2(1.2, 1.2), "max": Vector2(pos.x, pos.z) + fs * 0.5 + Vector2(1.2, 1.2), "y": pos.y})
			prev_size = fs
			prev_kind = "n"
			force_next = ""
			fall_run = 0
			unstable_run = 0

	# arène du boss : la dernière dalle est un grand plateau précédé d'un checkpoint
	if boss and steps.size() >= 3:
		var pre: Array = steps[steps.size() - 2]
		if str(pre[5]) == "n":
			pre[5] = "c"
			pre[3] = maxf(float(pre[3]), 4.0)
			pre[4] = maxf(float(pre[4]), 4.0)

	# bonus flottants au-dessus de certains vides : [indice_étape, type]
	var powerups: Array = []
	var spacing := 7
	for i in range(4, steps.size() - 1):
		if i % spacing == 0 and rng.randf() < 0.8:
			var s: Array = steps[i]
			if float(s[0]) >= 3.0 and float(s[0]) <= 4.7 and not (str(s[5]) in ["b", "q", "z"]):
				powerups.append([i, "wing" if rng.randf() < 0.5 else "boost"])

	return {
		"name": theme["name"],
		"theme": theme_idx,
		"difficulty": diff,
		"par": 40.0 + count * 6.5 + (30.0 if boss else 0.0),
		"steps": steps,
		"powerups": powerups,
		"boss": boss,
		"boss_variant": BOSS_WORLDS.find(theme_idx),
	}


static func _pick_kind(rng: RandomNumberGenerator, weights: Dictionary, i: int, last: bool, force_next: String, prev_kind: String, fall_run: int, attempt: int, cp_every: int, unstable_run: int, unstable_limit: int, hazard_scale: float, hazard_run: int, count: int) -> String:
	if last:
		return "n"
	if force_next == "after_b" or force_next == "after_j":
		return "n"
	if force_next == "after_p":
		return "q"
	if force_next == "after_y":
		return "z"
	if i == 0:
		return "n"
	if i % cp_every == cp_every - 1:
		return "c"
	if attempt >= 18 or unstable_run >= unstable_limit:
		return "n"
	var w := {}
	for k in ALL_KINDS:
		w[k] = float(weights.get(k, 0.0))
		if k != "n":
			w[k] = float(w[k]) * hazard_scale
	# les paires (portail, interrupteur) ont besoin de 2 dalles + au moins une dalle de plus avant la fin
	if i >= count - 3:
		w["p"] = 0.0
		w["y"] = 0.0
		w["j"] = 0.0
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
	if prev_kind in ["q", "z"]:
		for k in ["p", "y", "j", "b", "t"]:
			w[k] = 0.0
	if prev_kind == "r":
		w["r"] = 0.0
	for k2 in ["h", "w", "a"]:
		if prev_kind == k2:
			w[k2] = 0.0
	if prev_kind == "b":
		w["w"] = 0.0
	if prev_kind == "t" or hazard_run >= 2:
		w["t"] = 0.0
		w["s"] = 0.0
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


static func _pick_size(rng: RandomNumberGenerator, kind: String, base: float, last: bool, boss: bool = false) -> Vector2:
	if last:
		return Vector2(22, 22) if boss else Vector2(7, 7)
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
		"t":
			s = clampf(s, 4.4, 6.0)
		"j":
			s = clampf(s, 3.2, 4.0)
		"y":
			s = clampf(s, 3.0, 4.0)
		"z":
			s = clampf(s, 3.4, 4.4)
		"p":
			s = clampf(s, 4.0, 5.0)
		"q":
			s = clampf(s, 3.6, 5.0)
		"r":
			s = clampf(s, 4.6, 6.0)
		"g":
			s = clampf(s, 3.4, 5.4)
		"h":
			s = clampf(s, 3.8, 5.0)
		"w":
			s = clampf(s, 3.6, 5.4)
		"a":
			s = clampf(s, 3.2, 4.4)
	if rng.randf() < 0.3 and not (kind in ["v", "t", "p", "q", "y", "z", "j", "r", "g", "h", "w"]):
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
