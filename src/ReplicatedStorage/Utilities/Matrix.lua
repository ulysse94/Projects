--!strict
--[[Ulysse94]]--
-- simple matrix module. can only support normal numbers.

local matrix = {}

local MT = {
	__index = matrix,
	__newindex = function()
		error("Cannot add index to matrix object.")
	end,
	__tostring = function()
		return "Matrix"
	end,

	__unm = function(A)
		local new = table.clone(A)
		local dimA = new.Dim

		for j = 1, dimA[1] do
			for k = 1, dimA[2] do
				new:Set(-A:Get(j,k),j,k)
			end
		end

		return new
	end,

	__add = function(A,B)
		local C = table.clone(A)
		local dimA = A.Dim

		if tostring(B) == "Matrix" then
			local dimB = B.Dim

			assert(dimA[1]==dimB[1] and dimA[2]==dimB[2], 'Tried to sum 2 matrixes with different dimensions.')

			for j = 1, dimA[1] do
				for k = 1, dimA[2] do
					C:Set(A:Get(j,k)+B:Get(j,k),j,k)
				end
			end
		else -- B is a number
			for j = 1, dimA[1] do
				for k = 1, dimA[2] do
					C:Set(A:Get(j,k)+B,j,k)
				end
			end
		end

		return C
	end,

	__sub = function(A,B)
		return A + (-B)
	end,

	__mul = function(A,B)
		if typeof(A) == "number" then -- if A is a number, then B is a number.
			A,B=B,A
		end
		local dimA = A.Dim
		local result

		if tostring(B) == "Matrix" then
			local dimB = B.Dim
			assert(dimA[2] == dimB[1], "Trying to multiply 2 matrixes of incompatible dimensions.")

			result = matrix.new(nil, dimA[1], dimB[2])
			-- if A matrix type (m,n) and B (n,p), then C is (m,p) and:
			-- c_{ij}=\sum_{k=1}^{n} a_{ik} b_{kj} = a_{i1}b_{1j} + a_{i2}b_{2j} + \cdots +a_{in}b_{nj}}

			for j = 1, dimA[1] do
				for k = 1, dimB[2] do
					local c = 0
					for i = 1, dimA[2] do
						c+=A:Get(j,i)*B:Get(i,k)
					end
					result:Set(c,j,k)
				end
			end
		else -- B is a number, not a matrix.
			result = table.clone(A)
			for j = 1, dimA[1] do
				for k = 1, dimA[2] do
					result:Set(A:Get(j,k)*B,j,k)
				end
			end
		end

		return result
	end,

	__div = function(A,B)
		error("Cannot divide matrixes. Power the matrix to a negative number, then multiply.")
	end,

	__idiv = function(A,B)
		error("Cannot divide matrixes. Power the matrix to a negative number, then multiply.")
	end,

	__mod = function(A,B)
		error("Cannot divide matrixes. Power the matrix to a negative number, then multiply.")
	end,

	__pow = function(A,n)
		-- only works on square matrxies.
		assert(A.Dim[1] == A.Dim[2], "Cannot put a non-rectangular matrix to a power.")
		local C = table.clone(A)
		if n > 0 then
			for i = 1, n do
				C = C*A
			end
			return C
		elseif n < 0 then
			--TODO: get inversed, then multiply it.
		else -- n==0
			-- Returning identity matrix.
			local dim = C.Dim
			for j = 1,dim[1] do
				for k = 1,dim[2] do
					if j==k then
						C:Set(1,j,k)
					else C:Set(0,j,k)
					end
				end
			end
		end
		return C
	end,

	--__metatable = "MatrixMetatable",

	__eq = function(A,B)
		local dimA = A.Dim
		local dimB = B.Dim

		if not (dimA[1]==dimB[1] and dimA[2]==dimB[2]) then
			return false
		end

		for j = 1, dimA[1] do
			for k = 1, dimA[2] do
				if not A:Get(j,k) == B:Get(j,k) then
					return false
				end
			end
		end
		return true
	end,

	__lt = function(A,B)
		error('Cannot do "<" operation on matrixes.')
	end,

	__le = function(A,B)
		error('Cannot do "<=" operation on matrixes.')
	end,

	__len = function(A)
		return A.Dim[1] * A.Dim[2]
	end,
}

--[[
	values are {LINES = {ROWS/COLUMNS}} (i.e. {{2,5}, {3,4}} has 2 and 5 on the same line, and 2 and 3 in the same row).
	Dimensions are automatically set if no value is given.
	To use lines and columns options, set values to nil, and it will return a blank matrix.
	Power it to 0 to get the identity matrix.
]]
function matrix.new(values:{}?, lines:number?, columns:number?)
	local self = {}

	if typeof(values) == "table" then
		self.Value = values
	else
		self.Value = {}
		for j = 1,lines do
			if columns > 1 then
				self.Value[j] = {}
				for k = 1, columns do
					self.Value[j][k] = 0
				end
			else
				self.Value[j] = 0
			end
		end
	end

	for _,t in pairs(self.Value) do
		assert(typeof(t) == "table" or typeof(t) == "number", "Cannot insert other things than real number type values in matrixes.")
		if typeof(t) == "table" then
			for i,v in pairs(t) do
				assert(typeof(v) == "number", "Cannot insert other things than real number type values in matrixes.")
			end
		end
	end

	-- finds dimensions
	if typeof(self.Value[1]) == "table" then
		self.Dim = {#self.Value, #self.Value[1]}
	else
		self.Dim = {#self.Value, 1}
	end

	setmetatable(self, MT)

	return self
end

-- Spins around the matrix. Switches j and k positions.
function matrix:Turn():nil
	local nVals = {}
	local nDim = table.clone(self.Dim)
	nDim[1],nDim[2]=nDim[2],nDim[1] -- double.

	for j = 1, nDim[1] do
		if nDim[2]>1 then
			nVals[j] = {}
		end
		for k = 1, nDim[2] do
			if nDim[2]>1 then
				nVals[j][k] = self:Get(k,j)
			else
				nVals[j] = self:Get(k,j)
			end
		end
	end

	self.Dim = nDim
	self.Value = nVals

	return
end

-- Returns a neatly formatted string representing the matrix.
function matrix:GetString():string
	local result = "[ \n"
	local dimA = self.Dim

	for j = 1, dimA[1] do
		for k = 1, dimA[2] do
			result = result..tostring(self:Get(j,k))
			if dimA[2]-k>0 then
				result = result..", "
			end
		end
		if dimA[1]-j>0 then
			result = result..", \n "
		end
	end

	result = result.." \n ]"

	return result
end

-- Set value on line j, column k
function matrix:Set(value:number, j:number, k:number)
	assert(typeof(value)=="number","Cannot insert other things than real number type values in matrixes.")
	assert(j<=self.Dim[1],k<=self.Dim[2],"Trying to set a value outside of the matrix dimensions.")
	if typeof(self.Value[j]) == "table" then
		self.Value[j][k] = value
	else
		self.Value[j] = value
	end
end

-- Transforms line/column matrix to vector 3/2
function matrix:ToVector():Vector3|Vector2
	assert(#self == 2 or #self == 3, "Matrix is not a vector-matrix.")

	local v
	local X
	local Y
	if #self == 2 then
		if self.Dim[2] == 2 then -- {{X,Y}}
			X = self:Get(1,1)
			Y = self:Get(1,2)
		else -- {{X},{Y}}
			X = self:Get(1,1)
			Y = self:Get(2,1)
		end
		v=Vector2.new(X,Y)
	elseif #self == 3 then
		local Z
		if self.Dim[2] == 3 then -- {{X,Y,Z}}
			X = self:Get(1,1)
			Y = self:Get(1,2)
			Z = self:Get(1,3)
		else -- {{X},{Y},{Z}}
			X = self:Get(1,1)
			Y = self:Get(2,1)
			Z = self:Get(3,1)
		end
		v=Vector3.new(X,Y,Z)
	end

	return v
end

-- Get value on line j, column k
function matrix:Get(j:number, k:number):number?
	local ret = nil
	if typeof(self.Value[j])=="table" then
		ret = self.Value[j][k]
	else
		ret = self.Value[j]
	end
	return tonumber(ret)
end

-- 3x3 matrix only. returns the cofactor matrix.
function matrix:Cofactors()
	assert(self.Dim[1]==self.Dim[2] and #self==9, "Can only calculate cofactors for 3x3 matrices.")
	local C = matrix.new(nil, self.Dim[1], self.Dim[1])

	-- on calcule le determinant par extension des cofacteurs
	-- on doit calculer les minorants et la matrice des cofacteurs com(A)

	local allRows = {1,2,3}
	local allLines = {1,2,3}
	for j = 1,#allLines do
		for k = 1,#allRows do
			-- on calcule le déterminant de la matrice 2x2, obtenu en excluent la ligne j et la colonne k.
			local rows = table.clone(allRows)
			local lines = table.clone(allLines)
			table.remove(rows, k)
			table.remove(lines, j)
			--print("rows:",rows[1], rows[2])
			--print("lines:", lines[1],lines[2])
			local minor = self:Get(lines[1],rows[1])*self:Get(lines[2], rows[2]) - self:Get(lines[1], rows[2])*self:Get(lines[2], rows[1])
			--print("Minor:",minor)
			-- on ajoute le minorant, on a le cofacteur. on le multiplie aussi par la valeur j,k.
			C:Set(((-1)^(j+k))*minor, j,k)
		end
	end

	--print("COFACTORS:",C:GetString())

	return C
end

-- Det for 2x2 and 3x3 matrices ONLY! Provide Cofactors if it is a 3x3 matrix.
function matrix:Det(cofactor:any?):number
	assert(self.Dim[1] == self.Dim[2], "Not a square matrix.")
	assert(#self == 4 or #self == 9, "Not a supported dimension.")

	local det = 0

	if #self == 4 then -- 2x2
		-- multiply diagonals, then sum.
		det = self:Get(1,1)*self:Get(2,2) - self:Get(1,2)*self:Get(2,1)
	elseif #self == 9 then -- 3x3
		-- on calcule le determinant par extension des cofacteurs, dans la colonne 2 (ou 1, ou 3)
		for i = 1,3 do
			det+=cofactor:Get(2,i)*self:Get(2,i)
		end
	end

	return det
end

-- guess what it does. only works for 2x2 and 3x3
function matrix:Inverse()
	assert(self.Dim[1] == self.Dim[2], "Not a square matrix.")
	assert(#self == 4 or #self == 9, "Not a supported dimension.")

	local cofactors = nil -- la matrice cofacteur est calculée 3 fois si on ne la sauvegarde pas dans une variable locale.
	if #self == 9 and self.Dim[1] == 3 then
		cofactors = self:Cofactors()
	end

	local det = self:Det(cofactors)
	assert(det~=0, "Matrix cannot be inversed.")

	if #self == 4 then
		return (matrix.new({{self:Get(2,2),-self:Get(2,1)},
		{-self:Get(1,2),self:Get(1,1)}})*det)
	elseif #self == 9 then
		local det = 1/det
		-- la dernière étape de l'inversion: il faut passer les colonnes en lignes. on retourne la matrice com(A)
		cofactors:Turn()

		return cofactors*det
	end
end

return matrix

--[[
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
]]
