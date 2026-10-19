extends SceneTree
## Vérifie quels fichiers audio ont été fournis et lesquels manquent (les manquants gardent leur son synthétisé).
##   godot --headless --path . --script tools/check_audio.gd
## Affiche aussi la durée, la crête et le silence final de chaque effet sonore.

const MUSIC := [
	["menu", "Menu principal", true], ["story", "Écrans d'histoire", true], ["boss", "Combat de boss", true],
	["world_01_prairies", "Monde 1", true], ["world_02_foret", "Monde 2", true], ["world_03_dunes", "Monde 3", true],
	["world_04_recif", "Monde 4", true], ["world_05_toundra", "Monde 5", true], ["world_06_cristaux", "Monde 6", true],
	["world_07_usine", "Monde 7", true], ["world_08_ruines", "Monde 8", true], ["world_09_marais", "Monde 9", true],
	["world_10_volcan", "Monde 10", true], ["world_11_neon", "Monde 11", true], ["world_12_ciel", "Monde 12", true],
	["world_13_abysses", "Monde secret 13", true], ["world_14_sucreries", "Monde secret 14", true], ["world_15_forteresse", "Monde secret 15", true],
	["win", "Jingle : étape terminée", false], ["lose", "Jingle : run perdue", false], ["run_complete", "Jingle : fin de run", false],
]
const SFX := [
	"jump", "jump2", "coin", "bounce", "land", "checkpoint", "fall", "crumble", "click", "boost", "wing", "achievement",
	"hit", "portal", "launch", "cannon", "bumper", "star", "boss_wake", "boss_shot", "boss_beam", "equip", "streak", "tip",
]


func _initialize() -> void:
	await process_frame
	var g = root.get_node("Global")
	var missing := 0
	print("== Musiques (audio/music/)")
	for m in MUSIC:
		var path: String = g._find_audio("res://audio/music/", m[0])
		if path == "" and m[0] == "lose":
			path = g._find_audio("res://audio/sfx/", "lose")
		print("  %s %-22s %s" % ["OK     " if path != "" else "MANQUE ", m[0], m[1] + ("" if path == "" else "  <- " + path.get_file())])
		if path == "":
			missing += 1
	print("== Effets sonores (audio/sfx/)")
	for n in SFX:
		var path: String = g._find_audio("res://audio/sfx/", n)
		var info := ""
		if path != "":
			var raw = load(path)
			var used = g.sounds[n]
			if used is AudioStreamWAV:
				var gain: float = g.sfx_gain.get(n, 0.0)
				info = "%.2f s (fichier %.2f s, silence final retiré), gain auto %+.1f dB" % [used.get_length(), raw.get_length(), gain]
			elif raw != null:
				info = "%.2f s" % raw.get_length()
		print("  %s %-12s %s" % ["OK     " if path != "" else "MANQUE ", n, info])
		if path == "":
			missing += 1
	print("\n%d fichier(s) manquant(s) : ils utilisent la version synthétisée du jeu." % missing)
	quit()
