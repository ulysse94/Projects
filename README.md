# Projects

Vous trouverez ici mes projets les plus récents en Python et Lua. J'ai aussi fait (dans le cadre d'un exercice guidé en mathématique) une fonction pour résoudre le problème des tours de Hanoï, qui une réécriture. 

Mon code en Lua s'inscrit dans le moteur de [Roblox](https://create.roblox.com/docs/fr-fr/platform), un moteur 3D optimisé pour le jeux-vidéo et sa plateforme massivement-multijoueur. On peut coder sur le moteur de jeu en [Luau](https://luau-lang.org/), qui est une version du Lua avec un typage graduelle à la place d'un typage faible. La plupart des annotations sont en anglais, mais certaines d'entre-elles sont en français. 

Je n'ai pas utilisé d'IA (ChatGPT, Roblox CodeAssist, Blackbox) pour écrire ces scripts. Ces IA ne donnaient d'ailleurs que des réponses très vagues (lorsque je les ai testées pour d'autres choses plus simple), et dans le cas de la programmation, utilisaient des bouts d'API dépréciés/remplacés ou ne comprenaient pas la requête proprement.

J'ai utilisé VSCode, Roblox Studio, Argon (extension de VSCode et Roblox Studio pour la synchronisation), et parfois quelques plug-ins de Roblox Studio pour faciliter la construction et la création d'effets pour l'interface graphique.

## 1 Python

### 1.1 Les parties d'un ensemble
*../Python/PartiesEnsembles.py*

Retourne une liste de toutes les parties d'un ensemble. Par quelques modifications des blocs conditionnels, peut retourner les k-arrangements et les permutations. En écrivant ce code, j'ai pu (re-)découvrir l'importance de devoir cloner les listes, étant des objets. Le code est entièrement annoté.

### 1.2 Les tours de Hanoï
*../Python/ToursHanoi.py*

Ecrit après un exercice guidé de Première spécialité maths, dans lequel on cherchait le temps nécessaire au déplacement de tous les disques. Je pense que le code n'est, même s'il utilise de la récursivité, pas entièrement optimisé. J'ai aussi tenté d'afficher visuellement dans la console les tours.

## 2 Roblox

Dans ce repositoire GitHub, j'ai décidé de n'y faire figurer seulement mon projet le plus récent. Dans celui-ci, j'essaye de construire une simulation ferroviaire, tout en simulant les trains sans utiliser le moteur physique intégré à celui de Roblox ; le moteur de jeu n'est pas optimisé pour ce genre de véhicule.

Les autres projets que j'ai eus et qui ne figure pas ici n'ont jamais été annoté, et rendrai la lecture de ce repositoire bien plus difficile. C'est pourquoi j'ai décidé de ne mettre que ce projet.

Le moteur physique de Roblox ne nécessite pas l'utilisation de Blender pour la création de modèles 3D. Il laisse la possibilité d'utiliser des solides simples (cubes, spheres, etc.) puis d'utiliser de la géométrie de construction de solides pour former des modèles plus complexes. Ce processus reste tout de même moins optimisé qu'importer des modèles provenant de Blender.

### 2.1 Structure et données

#### 2.1.1 Carts

Tout d'abord, tous les objets sur des rails seront appeler des *carts*. Ces carts auront comme propriété : leur position sur un rail/une section, leur direction (1 ou -1), et quelques fonctions qui nous permettront de connaitre la position à une distance d de lui (i.e. la position sur le rail un mètre plus loin). Pour cela, il faut utiliser les propriétés *Connections* des sections (cf. ci-dessous).

La classe *carts* est une super-classe, dont d'autres classes comme "signal" ou "crossing" hériteront.

##### 2.1.2 Section

J'ai choisi de modéliser tous les rails avec des splines (surtout Bézier), ce qui me permettra plus tard de définir et connaitre la position d'un objet ainsi que sa direction très facilement : 1 ou -1 en fonction du premier point de contrôle de la section (et du spline). En effet, contrairement à des listes de points, ces courbes pourront être défini qu'avec un petit nombre de données : les points de contrôle, qui sont uniquement des [Vector3](https://create.roblox.com/docs/fr-fr/reference/engine/datatypes/Vector3). 

Ces rails seront des *sections*. Ces sections pourront être connecter dans leurs propriétés : une *BackConnection* et une *FrontConnection*. Notons que ces deux sections sont dans une liste à deux éléments (*Connections*), sous les propriétés de l'objet *section*.

#### 2.1.3 Nodes

Pour les *points*, ou aiguillages, des *nodes* seront utilisés. Ils seront utilisés comme des *sections* mais dont la longueur est nulle, et seulement leur connections avec les autres sections seront utilisées. Leurs propriétés déterminent ainsi les connections faites : une *BackConnection*, qui désignera uniquement une seule section en arrière du *node*, puis des *FrontConnections* (liste). Une propriété supplémentaire, *SwitchPosition*, détermine quelle *FrontConnection* est en cours d'utilisation.

*Les scripts Nodes.server.lua et NodeFunctions.lua sont des scripts dont les noms risquent de changer, et n'ont strictement rien à voir avec la class Node.*

Les *sections* et les *nodes* sont pré-modélisés dans l'environement par des [Model](https://create.roblox.com/docs/fr-fr/reference/engine/classes/Model), tous dans un [Folder](https://create.roblox.com/docs/fr-fr/reference/engine/classes/Folder) unique, dont les points de contrôles sont modélisés par des [Part](https://create.roblox.com/docs/fr-fr/reference/engine/classes/Part). Cela permet de stocker et préserver le réseau de *sections*/*nodes* sans à avoir modifier un fichier JSON, mais qui peut être visuelement modifié dans Roblox Studio. Ainsi, les objets qui sont créés utiliseront ces Parts et l'environement pour fonctionner correctement (cf. ../scr/ReplicatedStorage/Utilities/NodeFunctions.lua).

#### 2.1.4 Connections

La propriété "Connections" des sections sont des Parts : c'est le point de contrôle de la section connectée (premier ou dernier). Par exemple, pour une section A connectée à l'avant à une section B, et la section B connecté à l'arrière à la sections A, on aura :
- Pour A : Connections = {[1] = rien/nil, [2] = Premier point de la section B}
- Pour B : Connections = {[1] = Dernier point de la section A, [2] = rien/nil}

Ces Connections sont définies dans des [*Attributes* ](https://create.roblox.com/docs/fr-fr/reference/engine/classes/Instance#GetAttribute) des [Model](https://create.roblox.com/docs/fr-fr/reference/engine/classes/Model) des *sections* et *nodes*, sous la forme d'une valeur de type string, qui correspond au nom de la section/noeud (ou numéro). Comme les nodes sont des aiguillages, et ont, par définition, plusieurs connections possibles (seulement sur le côté avant), leurs connections sont séparés par une virgule ",". Ainsi les *nodes* et *sections* ne peuvent qu'avoir des noms différents. 

Ces connections sont permanentes pour les *sections*, et ne peuvent être supprimées ou modifiées tant que la simulation n'est pas réinitialisée. Pour les *nodes*, ces connections peuvent être mises à jour, ce qui pourrait être pratique pour des plaques tournantes.

#### 2.1.5 Indexation des *sections*

Pour indexer les *sections*, ils sont représentées par des [Model](https://create.roblox.com/docs/fr-fr/reference/engine/classes/Model), et sont tous dans le même Folder. Mais les objets (cf. *../src/ReplicatedStorage/Utilities/Splines*) sont, quant à eux, indexés sous _G.SplineIndex (qui est comme un dictionaire, où la clé est le nom de la *section*).

#### 2.1.6 Indexation des *carts*

Pour la simulation des véhicules sur rails, il faut pouvoir détecter ce qu'il y a sur les rails, c'est-à-dire les *carts* qui sont sur les sections. Il faut les indexer pour les trouver. Comme il faut les associer à des emplacements, pour savoir facilement si tel ou tel *cart* se trouve sur une *section*, ils sont indexés dans 2 listes.

### 2.2 Module matrice
*../scr/ReplicatedStorage/Utilities/Matrix.lua*

Ce module me permet de gérer des matrices. Il peut aussi inverser des matrices d'ordre 2 et 3. Je n'ai pas cherché à l'étendre pour des matrices plus grandes, n'en ayant besoin que pour des matrices de vecteurs dans l'espace et le plan.

### 2.3 Splines
*../scr/ReplicatedStorage/Utilities/Splines/ (2 scripts)*

Ces modules me permettent de générer les "rails" du circuit, et les *sections*. En effet, ces rails sont modélisés par des courbes de Bézier, et parfois des lignes droites, comme l'indique les 2 classes. J'aurai pu utiliser une super-class "Spline" dont les classes "Bézier" et "Line" hériteraient, mais comme la manière de calculer et de procéder étaient très différentes, j'ai décidé de faire deux classes séparées.

Pour définir la position des *carts* sur ces courbes, la longueur de celles-ci est calculer par morceaux. La courbe (en question) est découpée en parties égales et la distance parcourue sur chaque partie est ensuite additionner (méthode d'intégration la plus simple).

Ces *sections* ont donc quelques propriétés. Ces propriétés sont visible dans l'espace 3D, sous la forme de *Parts* et de *Model*. Dans les *Attributes* de ces Parts, on peut trouver le *BankAngle*, qui indique l'inclinaison du rail. On peut, grâce à la fonction CalculateCFrameAt connaître la position d'un *cart* pour un certain temps t. 

On rappelle que Roblox défini les orientations grâce à des quaternions. Par conséquent, il nous faut 3 vecteurs : le vecteur "haut" (UpVector), vers la droite et tout droit (resp. RightVector et LookVector). Ces vecteurs s'obtiennent grâce à la fonction dérivée (pour LookVector), par manipulation matricielle (pour les deux autres) et enfin grâce [au constructeur du moteur](https://create.roblox.com/docs/fr-fr/reference/engine/datatypes/CFrame#fromMatrix). Malheureusement, ces vecteurs ont une précision au millième près, à cause des limitations du moteur de Roblox. Ainsi, quand on fera le calcul, le résultat sera arrondit, et les vecteurs très légerement décalés. Ce décalage d'un millième est source de très gros bugs graphique (par exemple, j'ai réussi à avoir des cubes dont on ne voyait que les faces depuis l'intérieur). Pour régler ce problème, on choisit de simplifier le problème : on ne calcule que le "UpVector" et "LookVector" et on utilise [un constructeur différent](https://create.roblox.com/docs/fr-fr/reference/engine/datatypes/CFrame#lookAlong).

Cette simplification peut poser problème. En effet, comme le RightVector n'est pas définie, on peut se retrouver avec des *carts* orientés dans la mauvaise direction. On peut régler ce problème en dissociant le *carts* qui est effectivement sur la *section* et utilise la CFrame calculer, et le modèle apparent de ce *cart*.

### 2.4 GuiLib

GuiLib rassemble plusieurs classes (sans super-classe) qui permettent la création de certains objets d'interface graphique, qui ne sont pas déjà inclu dans le moteur de Roblox. On peut y retrouver Dropdown, Slider, etc. Les classes ne sont pas toutes terminées ou toutes testées, mais doivent fonctionner.

### 2.5 Rails et modélisation (à faire)

La modélisation des rails est un peu plus compliquée. Même si j'ai l'expression de la courbe, il faut placer dans l'espace 3D 2 courbes parallèles, simplifiées en plusieurs segments. 

Il est donc nécessaire de faire un algorithme de pavage qui peut placer ces segments de manière dynamique, sans laisser de trous entre eux. Cet algorithme de pavage pourra aussi être utilisé pour passer les traverses, puis, avec une gestion des données particulières, le placement des fenêtres ou des décorations d'une façade de bâtiment.

### Application aux simulation routières

Avec quelques changements sur la manière dont les *carts* réagissent et bougent, il serait possible d'appliquer ce système à une simulation routière. Deux possibilités s'offrent alors :

- la simulation est gérée par le système : les véhicules (*carts* spéciaux) ne sont ni simulés ni gérés par le moteur physique de Roblox.
- la simulation est en partie gérée par le moteur physique : les *carts* ne seraient alors que des "guides", que des véhicules, gérés par le moteur physique, tenteraient de suivre dans le monde 3D. Cette alternative est le meilleur choix si les véhicules doivent réagir à l'environement.