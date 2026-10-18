extends RefCounted
## Les 5 thèmes d'une run (un par étape). Les parcours sont générés par generator.gd.
##   weights : poids de tirage des plateformes
##     n normale | m mobile | f qui tombe | s tourniquet | b trampoline


static func get_themes() -> Array:
	return [
		{
			"name": "Prairies Suspendues",
			"sky_top": Color(0.28, 0.55, 0.95), "sky_horizon": Color(0.78, 0.92, 1.0),
			"top": Color(0.35, 0.8, 0.38), "side": Color(0.55, 0.38, 0.25),
			"particle": Color(1.0, 0.7, 0.85), "fog": 0.004,
			"weights": {"n": 6.0, "m": 2.0, "f": 0.4, "s": 0.2, "b": 0.5},
		},
		{
			"name": "Dunes d'Ambre",
			"sky_top": Color(0.95, 0.6, 0.3), "sky_horizon": Color(1.0, 0.88, 0.62),
			"top": Color(0.95, 0.8, 0.45), "side": Color(0.75, 0.5, 0.28),
			"particle": Color(0.95, 0.8, 0.55), "fog": 0.007,
			"weights": {"n": 3.0, "m": 1.0, "f": 4.0, "s": 0.3, "b": 1.0},
		},
		{
			"name": "Grotte des Cristaux",
			"sky_top": Color(0.15, 0.07, 0.38), "sky_horizon": Color(0.6, 0.42, 0.88),
			"top": Color(0.62, 0.5, 0.98), "side": Color(0.25, 0.2, 0.45),
			"particle": Color(0.5, 0.95, 1.0), "fog": 0.008,
			"weights": {"n": 3.0, "m": 2.0, "f": 1.0, "s": 3.0, "b": 1.5},
		},
		{
			"name": "Volcan Endormi",
			"sky_top": Color(0.16, 0.03, 0.03), "sky_horizon": Color(0.95, 0.35, 0.12),
			"top": Color(0.5, 0.32, 0.28), "side": Color(0.2, 0.15, 0.15),
			"particle": Color(1.0, 0.5, 0.15), "fog": 0.009,
			"weights": {"n": 2.0, "m": 2.5, "f": 3.0, "s": 3.0, "b": 0.5},
		},
		{
			"name": "Ciel Infini",
			"sky_top": Color(0.01, 0.02, 0.1), "sky_horizon": Color(0.2, 0.3, 0.62),
			"top": Color(0.85, 0.92, 1.0), "side": Color(0.3, 0.38, 0.6),
			"particle": Color(1.0, 1.0, 1.0), "fog": 0.003,
			"weights": {"n": 2.0, "m": 2.0, "f": 2.0, "s": 2.0, "b": 2.0},
		},
	]
