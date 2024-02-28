# Projects

Vous trouverez ici mes projets les plus récents en Python et Lua. J'ai aussi fait (dans le cadre d'un éxercice guidé en mathématique) une fonction pour résoudre le problème des tours de Hanoï, qui une réécriture. 

Mon code en Lua s'inscrit dans le moteur de [Roblox](https://create.roblox.com/docs/fr-fr/platform), un moteur 3D optimisé pour le jeux-vidéo et sa plateforme massivement-multijoueur. La plupart des annotations sont en __anglais__, mais certaines d'entre-elles sont en français. 

Je n'ai pas utilisé d'IA (ChatGPT, Roblox CodeAssist) pour écrire ces scripts, mais j'ai utilisé ces IA pour comprendre et mieux modéliser certains phénomènes physique. Ces IA ne donnaient d'ailleurs que des réponses très vagues, et dans le cas de la programmation, utilisaient des bouts d'API soit dépréciées ou ne comprenaient pas la requête.

J'ai utilisé VSCode, RobloxStudio, Argon (extension de VSCode/Roblox Studio pour la synchronisation), et parfois quelque plug-ins de Roblox Studio pour faciliter la construction et la création d'effets pour l'interface graphique.

## Python

### Les parties d'un ensemble
*../Python/PartiesEnsembles.py*

Retourne une liste de toutes les parties d'un ensemble. Par quelques modifications des blocs conditionnels, peut retourner les k-arrangements et les permutations. En écrivant ce code, j'ai pu (re)découvrir l'importance de devoir cloner les listes, étant des objets. Le code est entièrement annoté.

### Les tours de Hanoï
*../Python/ToursHanoi.py*

Ecrit après un éxercice guidé de Première spécialité maths, dans lequel on cherchait le temps nécessaire au déplacement de tous les disques.
Je pense que le code n'est, même s'il utilise de la récursivité, pas entièrement optimisé. J'ai aussi tenté d'afficher visuelement dans la console les tours.

## Roblox

Dans ce repositoire GitHub, j'ai décidé de n'y faire figurer seulement mon projet le plus récent. Dans celui-ci, j'essaye de construire une simulation ferroviaire, tout en simulant les trains sans utilisé le moteur physique intégré à celui de Roblox (qui n'est PAS optimisé pour ce genre de véhicule).

Les autres projets que j'ai eu et qui ne figure pas ici n'ont jamais été annoté, et rendrai la lecture de ce repositoire bien plus difficile. C'est pourquoi j'ai décidé de ne mettre que ce projet.

### Matrix
*../scr/ReplicatedStorage/Utilities/Matrix.lua*

Ce module me permet de gérer des matrices. Il peut aussi inverser des matrices d'ordre 2 et 3. Je n'ai pas cherché à l'étendre pour des matrices plus grandes, n'en ayant besoin que pour des matrices de vecteurs dans l'espace et le plan.

### Splines
*../scr/ReplicatedStorage/Utilities/Splines/ (2 scripts)*

*(CatmullRomSpline.lua exclut. Ce module n'a pas été fait par moi et m'a servi exclusivement de test et pour l'inspiration.)*

Ces modules me permettent de générer les "rails" du circuit. En effet, ces rails sont modélisés par des courbes de Bézier, et parfois des lignes droites (comme l'indique les 2 classes). 

## Roadmap
