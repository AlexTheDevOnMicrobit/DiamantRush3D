extends RefCounted
## Astuces affichées la première fois qu'un type de dalle apparaît dans une étape.

const TIPS := {
	"m": "Dalle mobile : attends qu'elle revienne près de toi avant de sauter.",
	"f": "Dalle friable : elle tombe peu après ton arrivée, ne traîne pas.",
	"k": "Dalle clignotante : elle clignote vite juste avant de disparaître.",
	"v": "Tapis roulant : il te pousse, garde le rythme pour avancer.",
	"o": "Dalle orbitale : elle tourne en cercle, saute quand elle passe près de toi.",
	"l": "Ascenseur : monte et descend, saute quand il est à ta hauteur.",
	"b": "Trampoline : atterris dessus pour être propulsé très haut.",
	"j": "Lanceur : marche dessus pour être propulsé vers l'avant au-dessus d'un grand vide.",
	"t": "Canon : il rougeoie avant de tirer, saute par-dessus la boule ou passe entre deux tirs.",
	"y": "Interrupteur : marche dessus pour rendre le pont transparent solide pendant 8 secondes.",
	"p": "Portail : entre dans l'anneau pour traverser un vide trop grand pour un saut.",
	"s": "Tourniquet : saute par-dessus la barre rouge quand elle arrive.",
	"r": "Bumper : il te repousse, contourne-le par les côtés ou laisse-toi rebondir.",
	"g": "Glace : le sol est glissant, anticipe tes arrêts.",
	"c": "Checkpoint : si tu tombes, tu repars d'ici.",
}


## Retourne la clé de l'astuce pour un type de dalle (le pont et la sortie de portail partagent celle de leur partenaire).
static func key_for(kind: String) -> String:
	match kind:
		"z": return "y"
		"q": return "p"
	return kind
