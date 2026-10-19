extends RefCounted
## Textes de l'histoire (un chapitre par monde, dans l'ordre de l'Aventure).

const INTRO_TITLE := "Le Royaume d'Éclat"
const INTRO := "Dans le Royaume d'Éclat, des îles flottent dans le ciel, toutes éclairées par un seul trésor : le Grand Diamant.\n\nUne nuit, l'Ombre l'a brisé en douze éclats, dispersés dans les douze mondes du royaume. Depuis, la lumière faiblit.\n\nTu es Lumi, un petit robot gardien du phare. Personne d'autre n'ira les chercher. Il est temps de sauter."

const QUICK_TITLE := "Course contre l'Ombre"
const QUICK_INTRO := "L'Ombre gagne du terrain. Lumi n'a pas le temps de visiter tous les mondes : il choisira cinq éclats, les plus proches du phare, et les rapportera à toute vitesse."

const STAGES := [
	{
		"title": "I — Les Prairies Suspendues",
		"before": "Le premier éclat brille quelque part au-dessus des prairies. Ici, tout est calme... pour l'instant. Ne regarde pas en bas.",
		"after": "Le premier éclat vibre dans ta main. Il est chaud, comme s'il te reconnaissait.",
	},
	{
		"title": "II — La Forêt des Murmures",
		"before": "Les arbres chuchotent ton nom. Des lucioles guident, ou égarent : certaines dalles clignotent comme si la forêt respirait.",
		"after": "Deux éclats. La forêt se tait enfin, et une luciole te suit un moment.",
	},
	{
		"title": "III — Les Dunes d'Ambre",
		"before": "Le sable a tout avalé, sauf quelques dalles friables. Elles ne tiendront pas longtemps sous tes pieds : avance vite.",
		"after": "Trois éclats. Au loin, le Phare s'allume une seconde. C'est bon signe.",
	},
	{
		"title": "IV — Le Récif Céleste",
		"before": "Un océan a été renversé dans le ciel. Les coraux flottent en orbite et des courants invisibles font monter les îles. Garde ton calme.",
		"after": "Quatre éclats. Ton reflet dans le diamant te sourit.",
	},
	{
		"title": "V — La Toundra de Givre",
		"before": "Ici, la glace ne pardonne pas : impossible de s'arrêter net. Anticipe chaque saut, et laisse glisser.",
		"after": "Cinq éclats. Tes circuits sont gelés, mais ton cœur de robot bat plus vite.",
	},
	{
		"title": "VI — La Grotte des Cristaux",
		"before": "Les cristaux chantent ici. L'Ombre y a installé ses tourniquets pour ralentir les curieux. Elle sait que tu viens.",
		"after": "Six éclats. Les cristaux se taisent, comme pour te laisser passer.",
	},
	{
		"title": "VII — L'Usine d'Engrenages",
		"before": "L'Ombre a bâti une usine pour fabriquer des pièges. Les tapis roulants, les ascenseurs, les pistons : tout est contre toi.",
		"after": "Sept éclats. Tu éteins la dernière machine d'un coup de poing métallique.",
	},
	{
		"title": "VIII — Les Ruines Dorées",
		"before": "Un ancien royaume gît ici. Ses dalles se dérobent sans prévenir, et les colonnes semblent te regarder.",
		"after": "Huit éclats. Les ruines murmurent un « merci » ancien.",
	},
	{
		"title": "IX — Le Marais Spectral",
		"before": "Le brouillard colle à tes capteurs et le vent change de direction sans cesse. Suis les lueurs vertes, mais méfie-toi de celles qui bougent.",
		"after": "Neuf éclats. Le marais se dissipe, et les fantômes te saluent.",
	},
	{
		"title": "X — Le Volcan Endormi",
		"before": "On l'appelait endormi. Il s'est réveillé quand l'éclat est tombé dans son cratère. La lave est loin en bas, mais elle écoute.",
		"after": "Dix éclats. Le volcan se rendort, la montagne soupire.",
	},
	{
		"title": "XI — La Cité Néon",
		"before": "Une cité que l'Ombre a construite avec ses rêves : des néons, des rails, des sauts impossibles. Elle ne dort jamais, et toi non plus.",
		"after": "Onze éclats. La ville s'éteint d'un coup, puis se rallume, plus douce.",
	},
	{
		"title": "XII — Le Ciel Infini",
		"before": "Plus de sol, plus de murs, seulement des étoiles et des plateformes minuscules. Le dernier éclat est au bout. Respire, Lumi.",
		"after": "Douze éclats. Il ne reste qu'à les réunir.",
	},
	{
		"title": "XIII — Les Abysses Lumineuses",
		"before": "Sous les îles, un océan secret brille de mille lueurs. Les méduses dansent en orbite, les courants montent et descendent. Un monde caché, réservé à celles et ceux qui ont tout fini.",
		"after": "Les abysses s'illuminent, une dernière fois, rien que pour toi.",
	},
	{
		"title": "XIV — Le Pays des Sucreries",
		"before": "Des sucettes géantes, des nuages de barbe à papa, des bumpers en caramel : l'Ombre n'a jamais osé venir ici. Amuse-toi, Lumi, tu l'as bien mérité.",
		"after": "Un parfum de vanille flotte dans l'air. Le phare a presque faim.",
	},
	{
		"title": "XV — La Forteresse de l'Ombre",
		"before": "Au cœur du royaume se cache la forteresse de l'Ombre. Chaque salle est un piège, chaque couloir une épreuve. Au sommet t'attend son ultime sentinelle.",
		"after": "La forteresse s'effondre dans un grand silence. Cette fois, l'Ombre ne reviendra plus.",
	},
	{
		"title": "XVI — L'Atelier de Lumi",
		"before": "Derrière le phare, une petite salle que Lumi garde pour s'entraîner : un exemplaire de chaque dalle du royaume. Prends ton temps, personne ne te chronomètre ici.",
		"after": "Lumi range ses outils avec un sourire. Il est prêt pour n'importe quel piège.",
	},
]

const BOSS_TITLE := "Le Défi des Ombres"
const BOSS_INTRO := "Les cinq sentinelles de l'Ombre se tiennent prêtes, l'une après l'autre. Pas de détour, pas de repos : Lumi n'a que trois vies pour toutes les affronter."
const BOSS_ENDING_TITLE := "Les cinq sentinelles ont chuté"
const BOSS_ENDING := "Plus une seule sentinelle ne garde le royaume. L'Ombre est seule face à la lumière."

const ENDING_TITLE := "La lumière revient"
const ENDING := "Les douze éclats s'assemblent dans le ciel et le Grand Diamant se reforme, plus brillant que jamais. L'Ombre se dissipe sans un bruit.\n\nLes îles du Royaume d'Éclat s'illuminent une à une. Au phare, un petit robot s'assoit enfin pour regarder la lumière.\n\nMerci, Lumi."

const QUICK_ENDING_TITLE := "Course gagnée"
const QUICK_ENDING := "Cinq éclats suffisent à rallumer le phare, juste à temps. Le Grand Diamant n'est pas encore entier, mais le royaume tient bon. Lumi sait qu'il reviendra pour les autres."

const WORLD_ENDING_TITLE := "Monde terminé"
