extends RefCounted
## Textes de l'histoire.

const INTRO_TITLE := "Le Royaume d'Éclat"
const INTRO := "Dans le Royaume d'Éclat, des îles flottent dans le ciel, toutes éclairées par un seul trésor : le Grand Diamant.\n\nUne nuit, l'Ombre l'a brisé en cinq éclats, dispersés aux quatre coins du royaume. Depuis, la lumière faiblit.\n\nTu es Lumi, un petit robot gardien du phare. Personne d'autre n'ira les chercher. Il est temps de sauter."

const STAGES := [
	{
		"title": "I — Les Prairies Suspendues",
		"before": "Le premier éclat brille quelque part au-dessus des prairies. Ici, tout est calme... pour l'instant. Ne regarde pas en bas.",
		"after": "Le premier éclat vibre dans ta main. Il est chaud, comme s'il te reconnaissait.",
	},
	{
		"title": "II — Les Dunes d'Ambre",
		"before": "Le sable a tout avalé, sauf quelques dalles friables. Elles ne tiendront pas longtemps sous tes pieds : avance vite.",
		"after": "Deux éclats. Au loin, le Phare s'allume une seconde. C'est bon signe.",
	},
	{
		"title": "III — La Grotte des Cristaux",
		"before": "Les cristaux chantent ici. L'Ombre y a installé ses tourniquets pour ralentir les curieux. Elle sait que tu viens.",
		"after": "Trois éclats. Les cristaux se taisent, comme pour te laisser passer.",
	},
	{
		"title": "IV — Le Volcan Endormi",
		"before": "On l'appelait endormi. Il s'est réveillé quand l'éclat est tombé dans son cratère. La lave est loin en bas, mais elle écoute.",
		"after": "Quatre éclats, et une dernière île au-dessus des nuages. L'Ombre t'attend là-haut.",
	},
	{
		"title": "V — Le Ciel Infini",
		"before": "Plus de sol, plus de murs, seulement des étoiles et des plateformes minuscules. Le dernier éclat est au bout. Respire, Lumi.",
		"after": "Cinq éclats. Il ne reste qu'à les réunir.",
	},
]

const ENDING_TITLE := "La lumière revient"
const ENDING := "Les cinq éclats s'assemblent dans le ciel et le Grand Diamant se reforme, plus brillant que jamais. L'Ombre se dissipe sans un bruit.\n\nLes îles du Royaume d'Éclat s'illuminent une à une. Au phare, un petit robot s'assoit enfin pour regarder la lumière.\n\nMerci, Lumi."

const GAME_OVER_TITLE := "L'Ombre l'emporte..."
const GAME_OVER := "Les éclats retombent dans le vide. Mais un gardien ne reste pas à terre : le phare t'attend pour un nouvel essai."
