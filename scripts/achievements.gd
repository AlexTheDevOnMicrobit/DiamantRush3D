extends RefCounted
## Succès : définitions et règles de déblocage.

const DEFS := [
	["first_stage", "Premier éclat", "Termine une étape."],
	["no_fall", "Sans une chute", "Termine une étape sans tomber."],
	["all_coins", "Pilleur", "Ramasse toutes les pièces d'une étape."],
	["speedy", "Éclair de génie", "Termine une étape en moins de 60 % du temps de référence."],
	["marathon", "Marathon", "Termine une étape avec la longueur « Très longue » ou plus."],
	["chaos", "Chaos organisé", "Termine une étape avec au moins 4 modificateurs actifs."],
	["iron_heart", "Cœur de fer", "Termine une étape en mode Hardcore."],
	["expert", "Pour les experts", "Termine une étape en difficulté Expert."],
	["power", "Dopé", "Ramasse un bonus de vitesse et une aile dans la même étape."],
	["quick_run", "Éclair", "Termine une Run éclair."],
	["adventure", "Gardien du phare", "Termine l'Aventure complète."],
	["hardcore_run", "Intouchable", "Termine une run complète en mode Hardcore."],
	["daily", "Rendez-vous quotidien", "Termine une run du jour."],
	["globetrotter", "Globe-trotter", "Termine chacun des 12 mondes au moins une fois."],
	["coins_200", "Collectionneur", "Ramasse 200 pièces au total."],
	["dandy", "Dandy", "Débloque 4 apparences pour Lumi."],
]


static func name_of(id: String) -> String:
	for d in DEFS:
		if d[0] == id:
			return d[1]
	return id


## info : {time, par, deaths, coins, coins_total, length, mods, hardcore, expert, boost, wing}
## Retourne les identifiants nouvellement débloqués.
static func evaluate_stage(g: Node, info: Dictionary) -> Array:
	var got: Array = []
	_try(g, got, "first_stage", true)
	_try(g, got, "no_fall", int(info["deaths"]) == 0)
	_try(g, got, "all_coins", int(info["coins_total"]) > 0 and int(info["coins"]) >= int(info["coins_total"]))
	_try(g, got, "speedy", float(info["time"]) < 0.6 * float(info["par"]))
	_try(g, got, "marathon", int(info["length"]) >= 2)
	_try(g, got, "chaos", int(info["mods"]) >= 4)
	_try(g, got, "iron_heart", bool(info["hardcore"]))
	_try(g, got, "expert", bool(info["expert"]))
	_try(g, got, "power", bool(info["boost"]) and bool(info["wing"]))
	_try(g, got, "coins_200", int(g.stats["coins"]) >= 200)
	_try(g, got, "dandy", g.unlocked_skins().size() >= 4)
	var worlds: Array = g.stats["worlds"]
	_try(g, got, "globetrotter", worlds.size() >= 12)
	return got


static func evaluate_run(g: Node, mode: String, hardcore: bool, daily: bool) -> Array:
	var got: Array = []
	_try(g, got, "quick_run", mode == "quick")
	_try(g, got, "adventure", mode == "adventure")
	_try(g, got, "hardcore_run", hardcore and mode != "free")
	_try(g, got, "daily", daily and mode != "free")
	return got


static func _try(g: Node, got: Array, id: String, cond: bool) -> void:
	if cond and not g.achievements.has(id):
		g.achievements[id] = true
		got.append(id)
