--disable
local matrix = require(game.ReplicatedStorage.Utilities.Matrix)
local part = workspace.TestPart

local position = Vector3.new(50, 2, 34)
local Zangle:number = math.rad(45) -- Z (banking) angle for the CFrame.
local lookAt = {
	X = 1,
	Y = 1,
	Z = 1
}

-- On cherche un vecteur qui va (relativement) vers le HAUT.
-- Pour ce faire, on va transformer notre vecteur en un vecteur 2D (sqrt(x^2+z^2);y),
-- Puis le transformer en utilisant la matrice {{0,-1},{1,0}} (dans le plan, on change l'axe x par l'axe y).
-- On a un nouveau vecteur, que l'on re-transforme en un vecteur 3D.
-- On peut ensuite appliquer la matrice qui nous donne l'inclinaison du rail (bankingAngleMatrix).
local upVector2 = matrix.new{math.sqrt(lookAt.X^2+lookAt.Z^2),lookAt.Y}
local upMatrix = matrix.new{{0,-1},{1,0}}
upVector2 = upMatrix * upVector2
-- On a le vecteur défini par (x,z). On le multiplie par les nouvelles coordonnées, puis on y ajoute la composante y. 
local upVector3 = matrix.new{lookAt.X, 0, lookAt.Z}*upVector2:Get(1,1)
upVector3:Set(upVector2:Get(2,1),2,1) -- composante y

local bankingAngleMatrix = matrix.new({{1,0,0},{0,math.cos(Zangle),math.sin(Zangle)},{0,math.sin(Zangle),math.cos(Zangle)}})
upVector3 = bankingAngleMatrix * upVector3

print(upVector3:GetString())