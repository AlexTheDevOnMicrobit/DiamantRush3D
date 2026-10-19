extends RefCounted
## Les 12 mondes du jeu. Les parcours sont générés par generator.gd.
##   difficulty : 1 (très facile) à 10 (très dur)
##   weights    : poids de tirage des plateformes
##     n normale | m mobile | f qui tombe | s tourniquet | b trampoline
##     k clignotante | v tapis roulant | o orbitale | l ascenseur
##     t canon | j lanceur | y interrupteur (+ pont) | p portail (+ sortie)
##   ice / wind : le monde est naturellement glissant / venteux

const WORLD_COUNT := 12


static func get_themes() -> Array:
	return [
		{
			"name": "Prairies Suspendues", "difficulty": 1.0,
			"sky_top": Color(0.28, 0.55, 0.95), "sky_horizon": Color(0.78, 0.92, 1.0),
			"top": Color(0.35, 0.8, 0.38), "side": Color(0.55, 0.38, 0.25),
			"particle": Color(1.0, 0.7, 0.85), "fog": 0.004,
			"weights": {"n": 7.0, "m": 2.0, "f": 0.3, "s": 0.1, "b": 0.6, "k": 0.0, "v": 0.0, "o": 0.0, "l": 0.0, "t": 0, "j": 0.5, "y": 0, "p": 0},
		},
		{
			"name": "Forêt des Murmures", "difficulty": 2.0,
			"sky_top": Color(0.05, 0.2, 0.18), "sky_horizon": Color(0.4, 0.75, 0.6),
			"top": Color(0.2, 0.6, 0.35), "side": Color(0.3, 0.2, 0.14),
			"particle": Color(0.8, 1.0, 0.5), "fog": 0.012,
			"weights": {"n": 6.0, "m": 2.0, "f": 0.8, "s": 0.2, "b": 0.8, "k": 0.5, "v": 0.0, "o": 0.0, "l": 0.5, "t": 0.3, "j": 0, "y": 0.6, "p": 0},
		},
		{
			"name": "Dunes d'Ambre", "difficulty": 3.0,
			"sky_top": Color(0.95, 0.6, 0.3), "sky_horizon": Color(1.0, 0.88, 0.62),
			"top": Color(0.95, 0.8, 0.45), "side": Color(0.75, 0.5, 0.28),
			"particle": Color(0.95, 0.8, 0.55), "fog": 0.007,
			"weights": {"n": 3.0, "m": 1.0, "f": 4.0, "s": 0.3, "b": 1.0, "k": 0.0, "v": 1.5, "o": 0.0, "l": 0.0, "t": 0.5, "j": 0.8, "y": 0, "p": 0},
		},
		{
			"name": "Récif Céleste", "difficulty": 3.5,
			"sky_top": Color(0.05, 0.35, 0.6), "sky_horizon": Color(0.55, 0.95, 0.9),
			"top": Color(1.0, 0.55, 0.5), "side": Color(0.2, 0.45, 0.6),
			"particle": Color(0.7, 1.0, 1.0), "fog": 0.006,
			"weights": {"n": 4.0, "m": 2.0, "f": 1.0, "s": 0.2, "b": 2.0, "k": 0.0, "v": 0.0, "o": 2.5, "l": 1.5, "t": 0, "j": 0.4, "y": 0, "p": 0.8},
		},
		{
			"name": "Toundra de Givre", "difficulty": 4.5, "ice": true,
			"sky_top": Color(0.45, 0.6, 0.8), "sky_horizon": Color(0.9, 0.96, 1.0),
			"top": Color(0.85, 0.95, 1.0), "side": Color(0.45, 0.6, 0.75),
			"particle": Color(1.0, 1.0, 1.0), "fog": 0.01,
			"weights": {"n": 4.0, "m": 2.0, "f": 1.0, "s": 1.5, "b": 1.0, "k": 1.0, "v": 0.0, "o": 0.5, "l": 0.5, "t": 1.0, "j": 0, "y": 0.5, "p": 0},
		},
		{
			"name": "Grotte des Cristaux", "difficulty": 5.0,
			"sky_top": Color(0.15, 0.07, 0.38), "sky_horizon": Color(0.6, 0.42, 0.88),
			"top": Color(0.62, 0.5, 0.98), "side": Color(0.25, 0.2, 0.45),
			"particle": Color(0.5, 0.95, 1.0), "fog": 0.008,
			"weights": {"n": 3.0, "m": 2.0, "f": 1.0, "s": 3.0, "b": 1.5, "k": 1.0, "v": 0.0, "o": 1.0, "l": 0.0, "t": 0, "j": 0, "y": 0.6, "p": 1.0},
		},
		{
			"name": "Usine d'Engrenages", "difficulty": 6.0,
			"sky_top": Color(0.18, 0.15, 0.12), "sky_horizon": Color(0.75, 0.6, 0.35),
			"top": Color(0.72, 0.55, 0.28), "side": Color(0.3, 0.3, 0.33),
			"particle": Color(1.0, 0.75, 0.3), "fog": 0.009,
			"weights": {"n": 2.0, "m": 2.0, "f": 0.5, "s": 3.0, "b": 1.0, "k": 1.0, "v": 3.5, "o": 1.5, "l": 2.0, "t": 2.0, "j": 1.2, "y": 1.0, "p": 0},
		},
		{
			"name": "Ruines Dorées", "difficulty": 6.5,
			"sky_top": Color(0.35, 0.3, 0.5), "sky_horizon": Color(1.0, 0.85, 0.6),
			"top": Color(0.9, 0.78, 0.45), "side": Color(0.55, 0.48, 0.38),
			"particle": Color(1.0, 0.9, 0.5), "fog": 0.008,
			"weights": {"n": 2.0, "m": 1.5, "f": 4.0, "s": 2.0, "b": 1.0, "k": 3.0, "v": 0.0, "o": 1.0, "l": 1.0, "t": 1.0, "j": 0, "y": 1.5, "p": 0.6},
		},
		{
			"name": "Marais Spectral", "difficulty": 7.5, "wind": true,
			"sky_top": Color(0.08, 0.12, 0.1), "sky_horizon": Color(0.4, 0.6, 0.45),
			"top": Color(0.4, 0.62, 0.4), "side": Color(0.2, 0.25, 0.2),
			"particle": Color(0.6, 1.0, 0.7), "fog": 0.02,
			"weights": {"n": 2.0, "m": 2.5, "f": 2.0, "s": 1.5, "b": 1.0, "k": 2.5, "v": 0.5, "o": 2.5, "l": 1.0, "t": 1.0, "j": 0, "y": 1.0, "p": 1.5},
		},
		{
			"name": "Volcan Endormi", "difficulty": 8.0,
			"sky_top": Color(0.16, 0.03, 0.03), "sky_horizon": Color(0.95, 0.35, 0.12),
			"top": Color(0.5, 0.32, 0.28), "side": Color(0.2, 0.15, 0.15),
			"particle": Color(1.0, 0.5, 0.15), "fog": 0.009,
			"weights": {"n": 2.0, "m": 2.5, "f": 3.0, "s": 3.0, "b": 0.5, "k": 1.5, "v": 1.5, "o": 1.5, "l": 1.5, "t": 2.0, "j": 1.0, "y": 0, "p": 0.8},
		},
		{
			"name": "Cité Néon", "difficulty": 9.0,
			"sky_top": Color(0.03, 0.0, 0.12), "sky_horizon": Color(0.8, 0.1, 0.6),
			"top": Color(0.1, 0.9, 1.0), "side": Color(0.15, 0.08, 0.3),
			"particle": Color(1.0, 0.3, 0.9), "fog": 0.007,
			"weights": {"n": 1.5, "m": 2.5, "f": 2.0, "s": 2.5, "b": 2.0, "k": 3.0, "v": 2.5, "o": 2.5, "l": 2.5, "t": 2.0, "j": 2.0, "y": 1.5, "p": 1.5},
		},
		{
			"name": "Ciel Infini", "difficulty": 10.0,
			"sky_top": Color(0.01, 0.02, 0.1), "sky_horizon": Color(0.2, 0.3, 0.62),
			"top": Color(0.85, 0.92, 1.0), "side": Color(0.3, 0.38, 0.6),
			"particle": Color(1.0, 1.0, 1.0), "fog": 0.003,
			"weights": {"n": 1.5, "m": 2.0, "f": 2.0, "s": 2.0, "b": 2.0, "k": 2.0, "v": 2.0, "o": 2.0, "l": 2.0, "t": 2.0, "j": 1.5, "y": 1.5, "p": 1.5},
		},
	]


static func difficulty_stars(d: float) -> String:
	var n := clampi(int(round(d / 2.0)), 1, 5)
	return "[" + "#".repeat(n) + ".".repeat(5 - n) + "]"
