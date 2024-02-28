"""
Ce script résout le problème des tours de Hanoï.
Le script a été créé en sorte que d'autres tours (autre que A, B et C) se rajoute au problème (D?).
"""

from math import floor #Pour printASCII.

towers = {
    "A":[],
    "B":[],
    "C":[]
}

globals()["nMove"] = 0
"""
Nombre de déplacement accomplit par la fonction move.
(Utilise globals() car, bizarrement, ne voulait pas la définir comme une global par défaut.)
"""

def printASCII():
    """
    Génère les tours en characters ASCII.
    LES TOURS NE SONT PAS CENTREES (ou presque).
    """
    space = 3
    #Espace entre chaque tour.

    height = 0
    for n in towers:
        height += len(towers[n])
    #Détermine le nombre de disque au total.
    wideness = 0
    for n in towers:
        if len(towers[n]) > 0 and towers[n][0] > wideness:
            wideness = towers[n][0]
    #Détermine le disque le plus large, et donc la largeur de chaque tour. 

    currentString = ""
    for n in towers:
        currentString += n + " " * (wideness + space)
    currentString = "\n" + currentString
    #Ligne du bas, là où l'on peut voir la notation des tours. 

    for i in range(height):
        currentLine = ""
        for n in towers:
            if len(towers[n]) > i: #Verifie qu'il y a un élément à cette position.
                div = (wideness - towers[n][i]) / 2
                if div != floor(div): #div se termine par .5
                    currentLine += str(towers[n][i]) + " " * floor(div) + "▐" + "█" * towers[n][i] + " " * floor(div) #"▌▐"
                else: #div est un entier. Pas de problème. Utiliser floor() car div est un float.
                    currentLine += str(towers[n][i]) + " " * floor(div) + "█" * towers[n][i] + " " * floor(div)
            else: #Sinon, juste mettre des espaces
                currentLine += "N" + " " * wideness
            currentLine += " " * space

        currentString = currentLine + "\n" + currentString

    print(currentString + "\nDéplacement n°" + str(globals()["nMove"]))

def move(start:str="A",end:str="C"):
    """
    Bouge 1 disque de <start> vers <end>, en vérifiant que cela est possible.
    Ensuite mets à jour la console et nMove.
    """
    startIndex = len(towers[start])-1
    endIndex = len(towers[end])-1

    if (endIndex >= 0 and towers[start][startIndex] < towers[end][endIndex]) or endIndex < 0:
        #Vérifie que le dernier élément de la liste start est plus petit que celle de end.
        globals()["nMove"] += 1
        #Ajoute 1 au nombre de déplacement accomplit
        towers[end].append(towers[start][startIndex])
        #Ajoute l'élément à la liste end.
        towers[start].remove(towers[start][startIndex])
        #Supprime le dernier élément de la liste start (celui qui a été déplacé).
    else:
        print("Impossible:", towers, startIndex, endIndex, sep=" ")
    
    printASCII()

def createTower(pos:str="A",n:int=3):
    """
    Créer une tour de n disques en pos.
    """
    for i in range(n,0,-1):
        towers[pos].append(i)

def resolve(n:int, start:str="A", end:str="C", auxiliary:str="B"):
    """
    Fonction principale.
    Résout le problème avec n disques en start, devant aller en end, via auxiliary.
    """
    if n == 1:
        #easy
        move(start, end)
    else:
        resolve(n-1, start, auxiliary, end)
        #déconstruire la tour
        move(start,end)
        #poser le plus gros disque
        resolve(n-1, auxiliary, end, start)
        #on reconstruit la tour par dessus.

createTower(n=5)
resolve(5)
print("Réalisé en ", globals()["nMove"], " déplacements.", sep="")