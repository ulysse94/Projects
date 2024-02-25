# c'est en essayant de faire ce petit "challenge" que j'ai (re)découvert que les listes devait être copiée, étant des objets.
# pour l'instant, ce code trouve les parties d'un ensemble.
# mais modifier les blocs conditionnels de la fonction "parts" peut le faire retourner les k-arrangements (et permutations). 
# certaines des annotations sont des commandes print pour le debugging.
def isIn(A,B):
    #est-ce que des listes similaires à B sont dans A?
    #juste une fonction pour éviter les redondances.
    result = False

    for i in range(len(A)):
        similar = 0
        for n in range(len(B)):
            if B[n] in A[i]:
                similar += 1
        if similar == len(A[i]) and similar == len(B):
            result = True
            break

    return result

def exclude(A,B): #exclure B de A: A\B
    result = A.copy() # copier, sinon A est modifié... même pour les scopes supérieurs.
    for i in range(len(B)):
        if B[i] in result:
            result.remove(B[i]) #assuming there's only 1 occurence
    return result

def parts(A):
    result = []

    def complete(current):
        chooseFrom = exclude(A, current)
        # print("---------------------", "      ITERATION       ", sep="\n")
        # print("CURRENT=", current)
        # print("CHOOSEFROM=", chooseFrom)
        if len(current) <= len(A): # on peut changer ce bout pour avoir des k-arrangements, en changeant "len(A)" en "k" et "<="
            if not isIn(result, current): # a supprimer si on se fiche de l'ordre, pour les k-arrangements, on peut remplacer par : "if len(current) == k"
                result.append(current)
                # print("APPEND=", current)
            else: 
                # print("NOTAPPEND=", current)
                return # existe deja, pas besoin d'en faire plus...

            if len(chooseFrom) > 0:
                for i in range(len(chooseFrom)):
                    new = current.copy()
                    # print("DEBUG=",new, chooseFrom, i, len(chooseFrom))
                    new.append(chooseFrom[i])
                    # print("NEW=",new)
                    complete(new)
    complete([])

    return result

print(parts([["A",1],["B",2],["C",3]])) 
# il faut bien que les valeurs désignent des objets différents.
# i.e: on ne peut pas avec 2 "1", mais on peut avoir deux "[1]".