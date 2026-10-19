extends SceneTree
## Test de fumée complet de la 3.2.0.
## Usage : godot --headless --path . --script tests/smoke.gd
## Code de sortie 0 si tout passe, 1 sinon.

const Gen = preload("res://scripts/generator.gd")
const LevelData = preload("res://scripts/level_data.gd")
const Achievements = preload("res://scripts/achievements.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Translations = preload("res://scripts/translations.gd")
const ALL_KINDS := ["n", "m", "f", "c", "b", "s", "k", "v", "o", "l", "t", "j", "y", "z", "p", "q", "r", "g"]
const BOSS_WORLDS := [2, 5, 8, 11, 14]

var g
var failures := 0
var UpdateCheck


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		print("  FAIL ", msg)
		failures += 1


func _initialize() -> void:
	await process_frame
	await process_frame
	g = root.get_node("Global")
	UpdateCheck = load("res://scripts/update_check.gd")
	g.reset_mods(false)
	g.reset_stats()
	g.options["language"] = "fr"
	g.apply_language()

	_test_generator()
	await _test_worlds()
	await _test_platform_behaviours()
	await _test_boss()
	await _test_new_content()
	await _test_endless()
	_test_challenges_and_codes()
	await _test_ghost()
	await _test_runs_and_progress()
	_test_misc()
	await _test_menus()
	await _test_touch()
	await _test_accessibility()

	g.reset_mods(false)
	g.reset_stats()
	g.options["language"] = "auto"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.GHOST_PATH))
	print("\nRÉSULTAT : ", "TOUT PASSE" if failures == 0 else "%d ÉCHEC(S)" % failures)
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- générateur

func _test_generator() -> void:
	print("== Générateur : 15 mondes x 4 longueurs x 3 difficultés x 8 seeds")
	var kinds := {}
	var bad := 0
	var det := true
	var pair_bad := 0
	var boss_bad := 0
	for w in 15:
		for li in 4:
			for dsel in 3:
				for sd in 8:
					var d: Dictionary = Gen.generate(sd * 31 + 7, w, 0, g.LENGTH_FACTORS[li], dsel)
					var diff := clampf(float(LevelData.get_themes()[w]["difficulty"]) + [-1.5, 0.0, 1.5][dsel], 0.5, 14.0)
					var expect := maxi(mini(int((9.0 + minf(diff, 11.0) * 1.8) * g.LENGTH_FACTORS[li]), 90), 6)
					if d["steps"].size() != expect:
						bad += 1
					var prev := "n"
					var idx := 0
					for s in d["steps"]:
						var k := str(s[5])
						kinds[k] = int(kinds.get(k, 0)) + 1
						var gmax := 4.65
						if prev == "p": gmax = 12.1
						elif prev == "j": gmax = 5.7
						if float(s[0]) > gmax or float(s[0]) < 1.0:
							bad += 1
						if prev == "p" and k != "q": pair_bad += 1
						if prev == "y" and k != "z": pair_bad += 1
						prev = k
						idx += 1
					var last: Array = d["steps"][d["steps"].size() - 1]
					var is_boss: bool = w in BOSS_WORLDS
					if bool(d["boss"]) != is_boss:
						boss_bad += 1
					if is_boss and float(last[3]) < 20.0:
						boss_bad += 1
					if not is_boss and float(last[3]) > 10.0:
						boss_bad += 1
					if sd == 0 and str(Gen.generate(7, w, 0, g.LENGTH_FACTORS[li], dsel)) != str(d):
						det = false
	check(bad == 0, "comptes et écarts valides (anomalies : %d)" % bad)
	check(pair_bad == 0, "interrupteur -> pont et portail -> sortie toujours appariés (%d erreurs)" % pair_bad)
	check(boss_bad == 0, "arène de boss uniquement aux mondes 3, 6, 9, 12 et 15 (%d erreurs)" % boss_bad)
	check(det, "génération déterministe")
	print("     types de plateformes : ", kinds)
	for k in ALL_KINDS:
		check(kinds.has(k), "type '%s' généré" % k)
	var d_easy: Dictionary = Gen.generate(5, 0, 0, 1.0, 1)
	var d_hard: Dictionary = Gen.generate(5, 11, 0, 1.0, 1)
	check(int(Gen.generate(5, 14, 0, 1.0, 1)["boss_variant"]) == 4 and int(Gen.generate(5, 2, 0, 1.0, 1)["boss_variant"]) == 0, "variante de boss selon le monde")
	check(d_hard["steps"].size() > d_easy["steps"].size(), "le monde 12 est plus long que le monde 1")
	var d_long: Dictionary = Gen.generate(5, 4, 0, 3.0, 1)
	var d_norm: Dictionary = Gen.generate(5, 4, 0, 1.0, 1)
	check(d_long["steps"].size() >= 2.5 * d_norm["steps"].size(), "le modificateur Longueur allonge le niveau")
	var d_end: Dictionary = Gen.generate(5, 2, 3, 1.0, 1, {"allow_boss": false, "diff_bonus": 3.0, "count_mult": 0.6})
	check(not bool(d_end["boss"]) and float(d_end["difficulty"]) > 5.0, "mode infini : pas de boss, difficulté majorée")


# ---------------------------------------------------------------- construction des mondes

func _test_worlds() -> void:
	print("== Les 15 mondes se construisent (tous modificateurs, Marathon, Expert)")
	g.mods["gravity"] = 0
	g.mods["length"] = 3
	g.mods["difficulty"] = 2
	for t in g.TOGGLES:
		g.mods[t[0]] = true
	g.mods["hardcore"] = false
	var seen_kinds := {}
	for w in 15:
		g.reset_run(1000 + w)
		g.run["stages"] = [w]
		g.run["mode"] = "free"
		var t0 := Time.get_ticks_msec()
		var lv = load("res://scenes/level.tscn").instantiate()
		root.add_child(lv)
		for f in 20:
			await physics_frame
		var ms := Time.get_ticks_msec() - t0
		check(lv.state == "play" and lv.platforms.size() > 30, "monde %d (%s) : %d plateformes, %d ms" % [w + 1, lv.data["name"], lv.platforms.size(), ms])
		for p in lv.platforms:
			seen_kinds[p.kind] = true
			if p.kind == "y" or p.kind == "p":
				if p.partner == null:
					check(false, "  partenaire manquant (%s)" % p.kind)
		check((lv.boss != null) == (w in BOSS_WORLDS), "  boss présent seulement dans les mondes 3, 6, 9, 12, 15")
		lv.player.global_position.y = lv.kill_y - 1
		for f in 3:
			await physics_frame
		check(lv.deaths == 1, "  chute -> réapparition")
		lv._toggle_pause()
		lv._toggle_pause()
		lv._win()
		check(lv.state == "won", "  victoire")
		root.remove_child(lv)
		lv.free()
	for k in ALL_KINDS:
		if not seen_kinds.has(k) and k != "n":
			print("     (type absent de ce tirage : ", k, ")")
	g.reset_mods(false)


# ---------------------------------------------------------------- comportements des nouvelles plateformes

func _find_level(kind: String, extra_mods: Dictionary = {}):
	for sd in 40:
		for w in [10, 11, 9, 6, 8]:
			g.reset_run(5000 + sd)
			g.run["stages"] = [w]
			g.run["mode"] = "free"
			var d: Dictionary = Gen.generate(5000 + sd, w, 0, 1.0, 1)
			var found := false
			for s in d["steps"]:
				if str(s[5]) == kind:
					found = true
			if found:
				var lv = load("res://scenes/level.tscn").instantiate()
				root.add_child(lv)
				await physics_frame
				return lv
	return null


func _first(lv, kind: String):
	for p in lv.platforms:
		if p.kind == kind:
			return p
	return null


func _test_platform_behaviours() -> void:
	print("== Comportement des nouveaux pièges")
	# lanceur
	var lv = await _find_level("j")
	check(lv != null, "niveau avec lanceur trouvé")
	if lv:
		var j = _first(lv, "j")
		lv.player.teleport(j.global_position + Vector3(0, 1.3, 0))
		var z0: Vector3 = lv.player.global_position
		for f in 25:
			await physics_frame
		var moved: float = Vector2(lv.player.global_position.x - z0.x, lv.player.global_position.z - z0.z).length()
		check(moved > 3.0 or lv.player.launch_t > 0.0, "le lanceur propulse Lumi (%.1f m en 25 images)" % moved)
		root.remove_child(lv)
		lv.free()
	# portail
	lv = await _find_level("p")
	check(lv != null, "niveau avec portail trouvé")
	if lv:
		var p = _first(lv, "p")
		var q = p.partner
		lv.player.teleport(p.global_position + Vector3(0, 1.3, 0))
		for f in 12:
			await physics_frame
		var dist: float = lv.player.global_position.distance_to(q.global_position + Vector3(0, 0.8, 0))
		check(dist < 4.0, "le portail téléporte Lumi sur la dalle de sortie (distance %.1f)" % dist)
		root.remove_child(lv)
		lv.free()
	# interrupteur + pont
	lv = await _find_level("y")
	check(lv != null, "niveau avec interrupteur trouvé")
	if lv:
		var y = _first(lv, "y")
		var z = y.partner
		check(z.kind == "z" and not z.is_solid() or z.kind == "z", "le pont existe")
		check(z.solid_time_left() == 0.0, "pont inactif avant l'interrupteur")
		lv.player.teleport(y.global_position + Vector3(0, 1.3, 0))
		for f in 20:
			await physics_frame
		check(z.solid_time_left() > 5.0, "l'interrupteur active le pont (%.1f s)" % z.solid_time_left())
		root.remove_child(lv)
		lv.free()
	# canon
	lv = await _find_level("t")
	check(lv != null, "niveau avec canon trouvé")
	if lv:
		var seen_shot := false
		for f in 400:
			await physics_frame
			for c in lv.get_children():
				if c is Projectile:
					seen_shot = true
			if seen_shot:
				break
		check(seen_shot, "le canon tire des projectiles")
		root.remove_child(lv)
		lv.free()
	# tapis roulant, clignotante, orbitale, ascenseur
	for kind in ["v", "k", "o", "l"]:
		lv = await _find_level(kind)
		check(lv != null, "niveau avec type '%s' trouvé" % kind)
		if lv:
			var pl = _first(lv, kind)
			var p0: Vector3 = pl.global_position
			var toggled := false
			var was: bool = pl.is_solid()
			var drift := 0.0
			for f in 240:
				await physics_frame
				if pl.is_solid() != was:
					toggled = true
				drift = maxf(drift, pl.global_position.distance_to(p0))
			match kind:
				"v": check(pl.constant_linear_velocity.length() > 1.0, "tapis roulant : vitesse de bande définie")
				"k": check(toggled, "dalle clignotante : apparaît et disparaît")
				"o": check(drift > 1.0, "orbitale : se déplace (%.1f m)" % drift)
				"l": check(drift > 1.0, "ascenseur : se déplace (%.1f m)" % drift)
			root.remove_child(lv)
			lv.free()
	# lanceur et gravité lourde : la portée reste suffisante
	g.mods["gravity"] = 2
	lv = await _find_level("j")
	if lv:
		var j2 = _first(lv, "j")
		lv.player.teleport(j2.global_position + Vector3(0, 1.3, 0))
		var s0: Vector3 = lv.player.global_position
		var maxd := 0.0
		for f in 80:
			await physics_frame
			maxd = maxf(maxd, Vector2(lv.player.global_position.x - s0.x, lv.player.global_position.z - s0.z).length())
		check(maxd > 6.0, "lanceur en gravité lourde : portée %.1f m" % maxd)
		root.remove_child(lv)
		lv.free()
	g.reset_mods(false)


# ---------------------------------------------------------------- boss

func _test_boss() -> void:
	print("== Boss de fin de monde")
	g.reset_mods(false)
	g.reset_run(777)
	g.run["stages"] = [2]
	g.run["mode"] = "free"
	var lv = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv)
	await physics_frame
	check(lv.boss != null, "le monde 3 a un boss")
	check(lv.pickups.filter(func(p): return p.kind == "diamond").is_empty(), "pas de diamant tant que le boss est debout")
	lv.player.teleport(lv.arena_top + Vector3(0, 0.3, 0))
	for f in 15:
		await physics_frame
	check(lv.boss.active, "le boss se réveille quand Lumi entre dans l'arène")
	lv.boss.duration = 6.0
	var seen_shot := false
	for f in 240:
		await physics_frame
		for c in lv.get_children():
			if c is Projectile:
				seen_shot = true
	check(seen_shot, "le boss lance des projectiles")
	# coups : le boss te repousse puis te réinitialise au checkpoint à 0 vie
	lv.hearts = 1
	lv.player.hit_cd = 0.0
	var d0: int = lv.deaths
	lv.player.get_hit(lv.arena_top + Vector3(3, 0, 0), 9.0)
	check(lv.hearts == 0 or lv.deaths == d0 + 1, "un coup retire une vie ; à zéro Lumi repart au checkpoint")
	check(not lv.player.get_hit(lv.arena_top, 9.0) or lv.player.hit_cd > 0.0, "invulnérabilité brève après un coup")
	# victoire : le temps du boss s'écoule
	lv.boss.reset()
	lv.player.teleport(lv.arena_top + Vector3(0, 0.3, 0))
	lv.boss.duration = 1.5
	for f in 260:
		await physics_frame
		lv.hearts = 3
		lv.player.hit_cd = 5.0
	check(lv.boss.finished and lv.boss_beaten, "le boss est vaincu après sa durée")
	check(not lv.pickups.filter(func(p): return is_instance_valid(p) and p.kind == "diamond").is_empty(), "le diamant apparaît")
	lv._win()
	check(lv.state == "won" and int(g.stats["bosses"]) >= 1 and g.achievements.has("boss"), "victoire, statistique et succès « Tombeur d'Ombre »")
	root.remove_child(lv)
	lv.free()


# ---------------------------------------------------------------- mode infini

func _test_endless() -> void:
	print("== Mode infini")
	g.reset_mods(false)
	g.leaderboard = {"all": [], "endless": []}
	g.reset_run(321)
	g.run["mode"] = "endless"
	g.run["stages"] = [0]
	g.run["lives"] = 3
	g.run["active"] = true
	check(g.is_endless() and g.stage_total() > 100, "mode infini reconnu")
	check(g.current_theme() == 0, "étape 1 = monde 1")
	g.run["stage"] = 13
	check(g.current_theme() == 1, "les mondes tournent (étape 14 = monde 2)")
	check(float(g.generation_extra()["diff_bonus"]) > 0.0, "la difficulté augmente après un tour complet")
	g.run["stage"] = 0
	var lv = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv)
	for f in 10:
		await physics_frame
	check(lv.boss == null, "pas de boss en mode infini")
	lv.player.global_position.y = lv.kill_y - 1
	await physics_frame
	await physics_frame
	check(int(g.run["lives"]) == 2 and lv.state == "play", "une chute coûte une vie (reste %d)" % int(g.run["lives"]))
	g.run["score"] = 4321
	lv._respawn()
	lv._respawn()
	check(lv.state == "failed", "à 0 vie la partie infinie se termine")
	check(g.leaderboard["endless"].size() == 1 and int(g.leaderboard["endless"][0]["score"]) == 4321, "score ajouté au classement infini")
	root.remove_child(lv)
	lv.free()
	# progression
	g.reset_run(322)
	g.run["mode"] = "endless"
	g.run["lives"] = 3
	g.stage_cleared({"time": 20.0, "score": 500, "coins": 2, "deaths": 0})
	await process_frame
	await process_frame
	check(int(g.run["stage"]) == 1 and int(g.run["score"]) == 500, "étape suivante en mode infini")
	# classement : tri et limite à 10
	g.leaderboard = {"all": [], "endless": []}
	for i in 14:
		g.add_score("quick", i * 100, 5, i)
	check(g.leaderboard["all"].size() == 10 and int(g.leaderboard["all"][0]["score"]) == 1300, "classement : top 10 trié")


# ---------------------------------------------------------------- défis et codes de partage

func _test_challenges_and_codes() -> void:
	print("== Défis et codes de partage")
	var a: Dictionary = g.challenge_def("daily")
	var b: Dictionary = g.challenge_def("daily")
	check(str(a) == str(b), "défi du jour déterministe")
	var w: Dictionary = g.challenge_def("weekly")
	check(w["reward"] > a["reward"] and int(w["mods"]["difficulty"]) == 2, "défi de la semaine plus dur et mieux récompensé")
	var mods_forced := 0
	for k in a["mods"]:
		if a["mods"][k] is bool and a["mods"][k]:
			mods_forced += 1
	check(mods_forced == 2, "2 modificateurs imposés au défi du jour")
	g.reset_mods(false)
	g.mods["speed"] = true
	g.start_challenge("daily")
	check(not g.mods_backup.is_empty() and bool(g.mods_backup["speed"]) and String(g.run["challenge"]) != "", "démarrer un défi sauvegarde les réglages")
	check(g.run["objective"].has("type"), "objectif du défi défini")
	g.restore_mods()
	check(bool(g.mods["speed"]) and g.mods_backup.is_empty(), "réglages restaurés après le défi")
	# objectifs
	g.reset_run(1)
	g.run["deaths"] = 2
	g.run["coins"] = 9
	g.run["time"] = 400.0
	check(g.objective_met({"type": "falls", "value": 2}) and not g.objective_met({"type": "falls", "value": 1}), "objectif : chutes")
	check(g.objective_met({"type": "coins", "value": 9}) and not g.objective_met({"type": "coins", "value": 10}), "objectif : pièces")
	check(g.objective_met({"type": "time", "value": 500.0}) and not g.objective_met({"type": "time", "value": 300.0}), "objectif : temps")
	check(not g.objective_met({"type": "nofall", "value": 0}), "objectif : sans chute")
	# codes de partage
	g.reset_mods(false)
	g.mods["gravity"] = 2
	g.mods["length"] = 1
	g.mods["difficulty"] = 0
	g.mods["mirror"] = true
	g.mods["fog"] = true
	var code: String = g.share_code("quick", 482913)
	check(code.begins_with("DR1-Q-482913-210-"), "code de partage : %s" % code)
	g.reset_mods(false)
	var r: Dictionary = g.apply_share_code(code)
	check(r["mode"] == "quick" and r["seed"] == 482913, "code relu : mode et seed")
	check(int(g.mods["gravity"]) == 2 and int(g.mods["length"]) == 1 and int(g.mods["difficulty"]) == 0 and g.mods["mirror"] and g.mods["fog"] and not g.mods["speed"], "code relu : modificateurs")
	var rf: Dictionary = g.apply_share_code(g.share_code("free", 99, [7]))
	check(rf["mode"] == "free" and rf["worlds"][0] == 7, "code du Monde libre")
	check(g.apply_share_code("n'importe quoi").is_empty() and g.apply_share_code("DR1-Z-1-111-0").is_empty() and g.apply_share_code("DR1-A-xx-111-0").is_empty() and g.apply_share_code("DR1-A-5-999-0").is_empty(), "codes invalides refusés")
	g.reset_mods(false)


# ---------------------------------------------------------------- fantôme

func _test_ghost() -> void:
	print("== Fantôme")
	g.reset_mods(false)
	g.options["ghost"] = true
	g.reset_run(4242)
	g.run["stages"] = [0]
	g.run["mode"] = "free"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.GHOST_PATH))
	g._ghosts = {}
	g._ghosts_loaded = true
	var lv = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv)
	check(lv.ghost_node == null, "pas de fantôme à la première partie")
	for f in 60:
		await physics_frame
	lv._win()
	check(lv.ghost_samples.size() >= 8 and FileAccess.file_exists(g.GHOST_PATH), "fantôme enregistré (%d échantillons)" % (lv.ghost_samples.size() / 4))
	var key: String = lv.ghost_key
	root.remove_child(lv)
	lv.free()
	g._ghosts = {}
	g._ghosts_loaded = false
	check(not g.get_ghost(key).is_empty(), "fantôme relu depuis le disque")
	var lv2 = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv2)
	await physics_frame
	check(lv2.ghost_node != null, "le fantôme est rejoué à la partie suivante")
	for f in 30:
		await physics_frame
	root.remove_child(lv2)
	lv2.free()
	check(not g.save_ghost(key, 9999.0, PackedFloat32Array([0, 0, 0, 0])), "un fantôme plus lent n'écrase pas le meilleur")
	check(g.save_ghost(key, 0.01, PackedFloat32Array([0, 0, 0, 0, 1, 0, 0, 0])), "un fantôme plus rapide le remplace")


# ---------------------------------------------------------------- runs et progression

func _test_runs_and_progress() -> void:
	print("== Runs complètes")
	g.reset_mods(false)
	g.reset_stats()
	g.start_run(5, "adventure")
	await process_frame
	await process_frame
	check(g.stage_total() == 12, "Aventure = 12 étapes")
	for st in 12:
		g.stage_cleared({"time": 50.0, "score": 2000, "coins": 3, "deaths": 1})
		await process_frame
		await process_frame
	check(not g.run["active"] and g.records.has("adventure"), "Aventure terminée et record enregistré")
	check(int(g.run["score"]) == 12 * 2000 + 1000, "score Aventure = 12 x 2000 + bonus (%d)" % int(g.run["score"]))
	check(g.leaderboard["all"].size() >= 1, "score au classement local")

	g.start_run(9, "quick")
	await process_frame
	var qw: Array = g.run["stages"]
	check(qw.size() == 5 and qw[0] < 2 and qw[4] >= 9, "Run éclair : 5 mondes de difficulté croissante %s" % str(qw))
	check(str(g.quick_worlds(9)) == str(g.quick_worlds(9)), "Run éclair déterministe")
	for st in 5:
		g.stage_cleared({"time": 40.0, "score": 1500, "coins": 2, "deaths": 0})
		await process_frame
		await process_frame
	check(g.records.has("quick"), "Run éclair terminée")

	g.start_run(11, "free", [6])
	await process_frame
	await process_frame
	check(g.stage_total() == 1 and g.current_theme() == 6, "Monde libre = 1 monde")
	g.stage_cleared({"time": 30.0, "score": 900, "coins": 1, "deaths": 0})
	await process_frame
	await process_frame
	check(g.records.has("world_6"), "record du monde libre")

	# défi réussi : récompense
	g.reset_mods(false)
	g.start_challenge("daily")
	await process_frame
	g.run["objective"] = {"type": "coins", "value": 0}
	g.run["stages"] = [3]
	var coins0: int = g.stats["coins"]
	g.stage_cleared({"time": 30.0, "score": 900, "coins": 1, "deaths": 0})
	await process_frame
	await process_frame
	check(int(g.stats["coins"]) == coins0 + 30 and g.achievements.has("challenge"), "défi du jour réussi : +30 pièces et succès")
	g.restore_mods()

	print("== Succès, apparences, sauvegarde")
	check(g.achievements.has("adventure") and g.achievements.has("quick_run"), "succès de run débloqués")
	var got: Array = Achievements.evaluate_stage(g, {"time": 10.0, "par": 100.0, "deaths": 0, "coins": 4, "coins_total": 4, "length": 3, "mods": 5, "hardcore": true, "expert": true, "boost": true, "wing": true, "boss": true, "beat_ghost": true})
	check(got.has("no_fall") and got.has("all_coins") and got.has("speedy") and got.has("marathon") and got.has("chaos") and got.has("iron_heart") and got.has("expert") and got.has("power") and got.has("ghost_win"), "succès d'étape (%d débloqués)" % got.size())
	g.stats["coins"] = 700
	check(g.unlocked_skins().size() == 8, "8 apparences à 700 pièces")
	g.options["skin"] = "rainbow"
	check(g.current_skin()["id"] == "rainbow", "apparence arc-en-ciel choisie")
	g.save_game()
	var saved_coins: int = g.stats["coins"]
	g.reset_stats()
	g.load_game()
	check(int(g.stats["coins"]) == saved_coins and g.records.has("adventure") and g.achievements.size() > 5 and g.leaderboard["all"].size() > 0 and g.challenges_done.size() > 0, "sauvegarde / chargement (records, succès, classement, défis)")


# ---------------------------------------------------------------- divers (clés, mises à jour, langue, audio)

func _test_misc() -> void:
	print("== Touches, mises à jour, langue, audio")
	g.reset_keymap()
	g.set_key("jump", KEY_J)
	check(g.key_name("jump") == "J", "touche de saut remappée sur J")
	g.reset_keymap()
	check(g.key_name("jump") == "Space", "touches par défaut rétablies")
	check(UpdateCheck.is_newer("v3.2.0", "3.1.0") and UpdateCheck.is_newer("4.0.0", "3.9.9") and not UpdateCheck.is_newer("3.1.0", "3.1.0") and not UpdateCheck.is_newer("3.0.9", "3.1.0"), "comparaison de versions")
	g.options["language"] = "en"
	g.apply_language()
	check(tr("Nouvelle run") == "New run" and tr("Étape suivante") == "Next stage", "langue anglaise active")
	var all_ok := true
	for k in Translations.EN:
		if String(Translations.EN[k]) == "":
			all_ok = false
	check(all_ok and Translations.EN.size() > 280, "traductions complètes (%d textes)" % Translations.EN.size())
	check("%d" in tr("Étape %d/%d — %s") and tr("Étape %d/%d — %s") % [1, 12, "X"] == "Stage 1/12 — X", "formats traduits")
	check(g.mod_summary() == "No modifiers", "résumé des modificateurs en anglais")
	for pair in [["es", Translations.ES], ["de", Translations.DE], ["it", Translations.IT], ["pt", Translations.PT]]:
		var lang_code: String = pair[0]
		var table: Dictionary = pair[1]
		g.options["language"] = lang_code
		g.apply_language()
		var same := 0
		for k in Translations.EN:
			if not table.has(k) or String(table[k]) == "":
				same += 100000
		check(table.size() == Translations.EN.size() and same == 0, "langue %s : %d textes, aucun manquant" % [lang_code, table.size()])
		check(tr("Nouvelle run") != "Nouvelle run" and tr("Étape %d/%d — %s") % [1, 12, "X"] != "", "langue %s active (%s)" % [lang_code, tr("Nouvelle run")])
		check(g.mod_summary() != "Aucun modificateur" and g.mod_summary() != "No modifiers", "résumé des modificateurs traduit (%s)" % lang_code)
	g.options["language"] = "auto"
	g.apply_language()
	check(["fr", "en", "es", "de", "it", "pt"].has(TranslationServer.get_locale().substr(0, 2)), "langue automatique : %s" % TranslationServer.get_locale())
	g.options["language"] = "fr"
	g.apply_language()
	check(tr("Nouvelle run") == "Nouvelle run" and g.mod_summary() == "Aucun modificateur", "retour au français")
	g.play_music(3)
	g.play_ambient("menu")
	g.play_jingle("win")
	g.play_jingle("run_complete")
	g.stop_music()
	check(g._find_audio("res://audio/sfx/", "jump") != "" and g._find_audio("res://audio/sfx/", "lose") != "", "fichiers audio à double extension reconnus (jump.ogg.wav, loose)")
	check(g.sounds["jump"] is AudioStreamWAV and (g.sounds["jump"] as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, "effet sonore chargé depuis le fichier et sans boucle")
	check(g.sounds.has("boost") and g.sounds.has("achievement") and g.sounds.has("hit") and g.sounds.has("portal") and g.sounds.has("launch") and g.sounds.has("cannon") and g.sounds.has("run_complete"), "nouveaux sons synthétisés présents")
	var f1 := float(g.options["text_scale"])
	g.options["text_scale"] = 1.5
	var lab := Label.new()
	lab.add_theme_font_size_override("font_size", 20)
	check(true, "échelle du texte appliquée (sans erreur)")
	g.options["text_scale"] = f1
	lab.free()


# ---------------------------------------------------------------- menus

func _test_menus() -> void:
	print("== Menus")
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	for lang in ["fr", "en", "es", "de", "it", "pt"]:
		g.options["language"] = lang
		g.apply_language()
		for p in ["main", "run", "worlds", "challenges", "mods", "options", "access", "stats", "skins", "story", "help"]:
			menu._show(p)
			await process_frame
	check(true, "11 pages du menu construites dans les 6 langues")
	g.options["language"] = "fr"
	g.apply_language()
	menu._show("run")
	menu.code_edit.text = "DR1-A-123456-100-0"
	menu._use_code()
	await process_frame
	check(g.run["seed"] == 123456 and g.run["mode"] == "adventure", "le menu lance une run depuis un code")
	menu.seed_edit.text = "abc"
	check(menu._seed_from_text() > 0, "seed texte convertie")
	# capture d'une touche
	menu._show("access")
	menu._begin_capture("jump")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_K
	ev.pressed = true
	menu._input(ev)
	check(g.key_name("jump") == "K", "remappage depuis le menu")
	g.reset_keymap()
	root.remove_child(menu)
	menu.free()


# ---------------------------------------------------------------- tactile et manette

func _test_touch() -> void:
	print("== Commandes tactiles et manette")
	g.reset_mods(false)
	g.options["touch"] = 1
	g.reset_run(321)
	g.run["stages"] = [0]
	g.run["mode"] = "free"
	var lv2 = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv2)
	for f in 20:
		await physics_frame
	check(lv2.touch != null, "contrôles tactiles créés")
	var tc = lv2.touch
	var origin := Vector2(200, 560)
	tc._input(_touch(0, origin, true))
	tc._input(_drag(0, origin + Vector2(0, -80), Vector2(0, -80)))
	var z0: float = lv2.player.global_position.z
	for f in 30:
		await physics_frame
	check(Input.is_action_pressed("forward") and lv2.player.global_position.z < z0 - 1.0, "joystick vers le haut = avance (z %.1f -> %.1f)" % [z0, lv2.player.global_position.z])
	tc._input(_touch(0, origin, false))
	check(not Input.is_action_pressed("forward"), "relâcher le joystick arrête le mouvement")
	var jc: Vector2 = tc._jump_center()
	tc._input(_touch(1, jc, true))
	check(Input.is_action_pressed("jump"), "bouton de saut appuyé")
	tc._input(_touch(1, jc, false))
	var yaw0: float = lv2.player.yaw
	tc._input(_touch(2, Vector2(900, 300), true))
	tc._input(_drag(2, Vector2(940, 300), Vector2(40, 0)))
	check(absf(lv2.player.yaw - yaw0) > 0.05, "glisser à droite tourne la caméra")
	tc._input(_touch(2, Vector2(940, 300), false))
	var paused := [false]
	tc.pause_pressed.connect(func(): paused[0] = true)
	tc._input(_touch(3, tc._pause_center(), true))
	check(paused[0], "bouton pause tactile")
	tc._input(_touch(3, tc._pause_center(), false))
	check(lv2.state == "paused", "le bouton pause met le jeu en pause")
	lv2._resume()
	var ev := InputEventJoypadMotion.new()
	ev.axis = JOY_AXIS_RIGHT_X
	ev.axis_value = 1.0
	Input.parse_input_event(ev)
	var yaw1: float = lv2.player.yaw
	for f in 10:
		await physics_frame
	check(absf(lv2.player.yaw - yaw1) > 0.01, "stick droit de la manette tourne la caméra")
	ev.axis_value = 0.0
	Input.parse_input_event(ev)
	root.remove_child(lv2)
	lv2.free()
	g.options["touch"] = 0


# ---------------------------------------------------------------- accessibilité, ombre, caméra

func _test_accessibility() -> void:
	print("== Accessibilité, ombre de Lumi, caméra")
	g.reset_mods(false)
	g.options["colorblind"] = true
	g.options["assist"] = true
	g.reset_run(555)
	g.run["stages"] = [10]
	g.run["mode"] = "free"
	var lv = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv)
	for f in 20:
		await physics_frame
	var labels := 0
	for p in lv.platforms:
		for c in p.find_children("*", "Label3D", true, false):
			labels += 1
	check(labels > 5, "mode daltonien : symboles sur les dalles (%d)" % labels)
	check(lv.player.coyote_time > 0.2 and lv.player.buffer_time > 0.2, "aide au saut : temps de grâce allongé")
	check(lv.player.shadow.visible, "disque d'ombre sous Lumi")
	# caméra : un mur entre Lumi et la caméra raccourcit la distance
	lv.player.yaw = 0.0
	lv.player.pitch = 0.0
	lv.player._update_shadow_and_camera()
	var free_dist: float = lv.player.want_cam_dist
	check(free_dist > 6.0, "caméra libre à pleine distance (%.1f)" % free_dist)
	var wall := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(10, 10, 1)
	cs.shape = bs
	wall.add_child(cs)
	lv.add_child(wall)
	wall.global_position = lv.player.pivot.global_position + Vector3(0, 0, 3.0)
	await physics_frame
	await physics_frame
	lv.player._update_shadow_and_camera()
	check(lv.player.want_cam_dist < 3.2, "caméra raccourcie devant un obstacle (%.1f)" % lv.player.want_cam_dist)
	root.remove_child(lv)
	lv.free()
	g.options["colorblind"] = false
	g.options["assist"] = false


func _touch(idx: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = pos
	e.pressed = pressed
	return e


func _drag(idx: int, pos: Vector2, rel: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = pos
	e.relative = rel
	return e


# ---------------------------------------------------------------- contenu 3.2.0

func _test_new_content() -> void:
	print("== Contenu 3.2.0 : bumper, glace, mondes secrets, étoiles, cosmétiques, nouveaux modificateurs, astuces")
	g.reset_mods(false)
	g.reset_stats()
	# bumper
	var lv = await _find_level("r")
	check(lv != null, "niveau avec bumper trouvé")
	if lv:
		var r = _first(lv, "r")
		lv.player.teleport(r.global_position + Vector3(0.4, 1.3, 0.2))
		var p0: Vector3 = lv.player.global_position
		var far := 0.0
		for f in 40:
			await physics_frame
			far = maxf(far, Vector2(lv.player.global_position.x - p0.x, lv.player.global_position.z - p0.z).length())
		check(far > 2.0 and int(g.stats["bumps"]) >= 1, "le bumper repousse Lumi (%.1f m) et compte la statistique" % far)
		root.remove_child(lv)
		lv.free()
	# plaque de glace
	lv = await _find_level("g")
	check(lv != null, "niveau avec plaque de glace trouvé")
	if lv:
		var gp = _first(lv, "g")
		lv.player.teleport(gp.global_position + Vector3(0, 1.3, 0))
		for f in 15:
			await physics_frame
		check(lv.player.ice_count >= 1, "la plaque de glace rend le sol glissant (ice_count=%d)" % lv.player.ice_count)
		lv.player.teleport(gp.global_position + Vector3(0, 12, 0))
		for f in 4:
			await physics_frame
		check(lv.player.ice_count == 0, "quitter la plaque rétablit l'adhérence")
		root.remove_child(lv)
		lv.free()
	# mondes secrets
	check(not g.secret_unlocked() and g.playable_worlds().size() == 12, "mondes secrets verrouillés au départ")
	g.achievements["adventure"] = true
	check(g.secret_unlocked() and g.playable_worlds().size() == 15, "mondes secrets débloqués après l'Aventure")
	g.reset_run(31)
	g.run["mode"] = "endless"
	g.run["stage"] = 14
	check(g.current_theme() == 14, "le mode infini inclut les mondes secrets")
	g.run["stage"] = 0
	for w in [12, 13, 14]:
		g.reset_run(900 + w)
		g.run["stages"] = [w]
		g.run["mode"] = "free"
		var lvs = load("res://scenes/level.tscn").instantiate()
		root.add_child(lvs)
		for f in 15:
			await physics_frame
		check(lvs.state == "play" and lvs.platforms.size() > 8, "monde secret %d (%s) se construit" % [w + 1, lvs.data["name"]])
		root.remove_child(lvs)
		lvs.free()
	# étoiles, chapeaux, traînées
	check(g.total_stars() == 0 and g.current_hat() == "none", "aucune étoile au départ")
	g.options["hat"] = "crown"
	check(g.current_hat() == "none", "un chapeau verrouillé n'est pas équipé")
	g.record_stars(0, 3)
	g.record_stars(1, 3)
	g.record_stars(2, 3)
	check(g.total_stars() == 9 and g.current_hat() == "crown", "9 étoiles : la couronne est débloquée")
	check(not g.record_stars(0, 2) and g.total_stars() == 9, "les étoiles ne baissent jamais")
	g.options["trail"] = "sparks"
	g.reset_run(60)
	g.run["stages"] = [0]
	g.run["mode"] = "free"
	var lv2 = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv2)
	for f in 20:
		await physics_frame
	check(lv2.player.trail != null and lv2.player.body_root.get_child_count() > 10, "chapeau et traînée créés sur Lumi")
	for hat in ["beanie", "crown", "tophat", "viking", "halo", "devil"]:
		g.stats["coins"] = 0
		g.world_stars = {0: 3, 1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 3, 8: 3, 9: 3, 10: 3, 11: 3, 12: 3, 13: 3, 14: 3, 15: 3, 16: 3, 17: 3, 18: 3, 19: 3}
		g.options["hat"] = hat
		var test_player = load("res://scripts/player.gd").new()
		root.add_child(test_player)
		await physics_frame
		test_player.queue_free()
	check(true, "les 6 chapeaux se construisent")
	# victoire : étoiles et succès « À la mode »
	var stars_before: int = g.total_stars()
	lv2._win()
	check(lv2.state == "won" and g.achievements.has("stylish") and g.world_stars[0] == 3, "victoire : 3 étoiles (sans chute, pas de pièces manquantes) et succès « À la mode »")
	root.remove_child(lv2)
	lv2.free()
	g.options["hat"] = "none"
	g.options["trail"] = "none"
	g.world_stars = {}
	# nouveaux modificateurs
	g.mods["night"] = true
	g.mods["nocp"] = true
	g.mods["tiny"] = true
	g.reset_run(61)
	g.run["stages"] = [3]
	g.run["mode"] = "free"
	var lv3 = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv3)
	for f in 20:
		await physics_frame
	var cap: CapsuleShape3D = null
	for c in lv3.player.get_children():
		if c is CollisionShape3D:
			cap = c.shape
	check(cap != null and cap.radius < 0.3 and lv3.player.model_base < 0.7, "Lumi miniature : hitbox et modèle réduits")
	var lamp := false
	for c in lv3.player.get_children():
		if c is OmniLight3D:
			lamp = true
	check(lamp, "Nuit noire : Lumi porte une lampe")
	var cp0: Vector3 = lv3.checkpoint
	lv3.set_checkpoint(Vector3(5, 5, 5))
	check(lv3.checkpoint == cp0, "Sans checkpoint : le point de réapparition ne change pas")
	var mult_before: float = g.multiplier()
	check(mult_before > 1.0, "multiplicateur de score avec les 3 modificateurs : x%.2f" % mult_before)
	root.remove_child(lv3)
	lv3.free()
	g.reset_mods(false)
	# astuces
	g.seen_tips = {}
	g.options["tips"] = true
	g.reset_run(62)
	g.run["stages"] = [10]
	g.run["mode"] = "free"
	var lv4 = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv4)
	await physics_frame
	check(g.seen_tips.size() >= 1 and g.seen_tips.size() <= 2, "astuces affichées pour les nouveaux pièges (%d)" % g.seen_tips.size())
	root.remove_child(lv4)
	lv4.free()
	var n_before: int = g.seen_tips.size()
	var lv5 = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv5)
	await physics_frame
	check(g.seen_tips.size() >= n_before, "une astuce déjà vue n'est pas répétée")
	root.remove_child(lv5)
	lv5.free()
	# rayon du boss final
	g.reset_run(63)
	g.run["stages"] = [14]
	g.run["mode"] = "free"
	var lvb = load("res://scenes/level.tscn").instantiate()
	root.add_child(lvb)
	await physics_frame
	check(lvb.boss != null and lvb.boss.variant == 4, "le boss du monde 15 est la variante 5")
	var before: int = lvb.get_child_count()
	lvb.boss._beam(0.5)
	check(lvb.get_child_count() == before + 1, "le boss lance un rayon rotatif")
	root.remove_child(lvb)
	lvb.free()
	# série de défis du jour
	g.reset_stats()
	var today := int(Time.get_unix_time_from_system() / 86400.0)
	g.stats["streak"] = 2
	g.stats["last_day"] = today - 1
	g.start_challenge("daily")
	await process_frame
	g.run["objective"] = {"type": "coins", "value": 0}
	g.run["stages"] = [0]
	g.challenges_done = {}
	var coins0: int = g.stats["coins"]
	g.stage_cleared({"time": 20.0, "score": 100, "coins": 0, "deaths": 0})
	await process_frame
	await process_frame
	check(int(g.stats["streak"]) == 3 and int(g.stats["coins"]) > coins0 + 30 and g.achievements.has("streak_3"), "série de 3 jours : bonus de pièces et succès « Assidu »")
	g.restore_mods()
	# égalisation des effets sonores fournis
	check(g.sfx_gain.size() >= 10 and g.sounds["coin"].get_length() < 0.9, "effets sonores fournis : gain calculé et silence final retiré")
	g.reset_stats()
	g.reset_mods(false)
