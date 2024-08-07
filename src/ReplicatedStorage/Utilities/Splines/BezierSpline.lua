--!strict
--[[Ulysse94]]--

local bezierSpline = {}
local matrix = require(game.ReplicatedStorage.Utilities.Matrix)

--[[
	Creates a new Spline object
]]
function bezierSpline.new(controlPoints: {BasePart}, resolution:number?)
	local self = {}
	
	self.Type = "Bezier"
	self.Points = nil
	-- the resolution helps calculating the length. divides the curve into <resolution> segments.
	self.Resolution = resolution or 100
	--[[ Set by the server. Will return a table this way:
	{
		[1] = BackConnectionPoint,
		[2] = FrontConnectionPoint
	}
	]]
	self.Connections = {}
	self.Model = {} -- lazy arclength parameterization
	self.Length = 0
	
	setmetatable(self, {
		__index = bezierSpline,
		__tostring = function()
			return "BezierSpline"
		end,
	})
	
	self:UpdatePoints(controlPoints)
	
	return self
end

-- Updates control points and updates the length (approximately) of the spline.
function bezierSpline:UpdatePoints(controlPoints: {Vector2} | {Vector3 | BasePart}?)
	self.Points = controlPoints
	
	if controlPoints then
		-- local length = 0
		-- local n = 100 -- precise enough
		-- for k = 0,n-1,1 do 
		-- 	length += (self:CalculatePositionAt(k/n)+self:CalculatePositionAt(k+1/n)).Magnitude
		-- end
		-- self.Length = length

		self:CalculateLength()
	end
end

local function getVector(vec:Vector2|Vector3|BasePart):Vector2|Vector3
	if type(vec) == "userdata" then
		return vec.Position
	else 
		return vec
	end
end

-- for binomial coefficient. stupid thing.
local function factorial(n:number):number
	if n == 0 then
		return 1
	else 
		return n * factorial(n-1)
	end
end

-- Function to calculate binomial coefficient (n choose k)
local function nCk(n:number, k:number):number
	return factorial(n) / (factorial(k) * factorial(n - k))
end


--[[
	Position of the CFrame at t.
]]
function bezierSpline:CalculatePositionAt(t:number):Vector3|Vector2
	-- Should return the position on the Bezier spline at t
	local n = #self.Points - 1
	
	if n == 0 then return getVector(self.Points[1]) end -- you fool.
	
	-- This loop uses the EXPLICIT formula to get the position.
	local posSum = nil
	
	for i=0,n do
		-- https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Explicit_definition
		-- it's... an interpretation. tho idk how to calculate binomial coefficient. had to ask an AI... then made the factorial thing.
		local binomialCoefficient = nCk(n,i)
		local term = binomialCoefficient * (1 - t)^(n - i) * t^i * getVector(self.Points[i + 1]) --i+1 cuz i=0 doesnt exist.
		-- bernstein coefficient: B_{n,i} = (n;i) * (1-t)^(n-i) * t^i
		
		if not posSum then
			posSum = term
		else 
			posSum += term
		end
	end
	
	return posSum
end


--[[
	LookVector of the CFrame at t.
]]
function bezierSpline:CalculateDerivateAt(t:number):Vector3|Vector2

	-- guess what? we are calculating the derivate of that bezier spline at t.

	local n = #self.Points - 1

	local posSum = nil

	for i=0,n do

		-- it was very hard to find the correct formula...
		local res = 1
		for i = 1, math.min(i, n - i) do
			res = res * (n - i + 1) / i
		end

		local term1 = res * (-1) * (n - i) * ((1 - t) ^ (n - i - 1)) * (t ^ i)
		local term2 = res * i * ((1 - t) ^ (n - i)) * (t ^ (i - 1))

		if not posSum then
			posSum = (term1+term2)*getVector(self.Points[i+1])
		else 
			posSum += (term1+term2)*getVector(self.Points[i+1])
		end
	end

	-- now you pray for it to work 〒▽〒
	return posSum
end

--[[
	Returns the interpolated value of the banking angle.
	Used to get the UpVector.
	The returned angle is in radians.
	The attribute "BankAngle" must be in **DEGREES**.
]]
function bezierSpline:GetBankAngleAt(t:number):number
	local startAngle = self.Points[1]:GetAttribute("BankAngle") or 0
	local endAngle = self.Points[#self.Points]:GetAttribute("BankAngle") or 0
	local diff = endAngle - startAngle
	return math.rad(diff * t + startAngle) -- math.rad clamps the radian between 0 and 2pi.
end

function bezierSpline:CalculateCFrameAt(t:number):CFrame
	local Zangle:number = self:GetBankAngleAt(t) -- Z (banking) angle for the CFrame.
	local lookAt:Vector3 = self:CalculateDerivateAt(t).Unit

	-- We transform the lookAt vector using matrixes, to get the Right and Up vectors.
	-- Considering CFrame.lookAlong, we do not need the RightVector. Only the UpVector.
	-- Please also note that ToVector() on matrixes often round the numbers, causing serious incoherence for the CFrames.
	-- So we are not using CFrame.fromMatrix
	
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
	
	local resultCFrame = CFrame.lookAlong(self:CalculatePositionAt(t), lookAt, upVector3:ToVector())
	
	return resultCFrame
end

function bezierSpline:CalculateLength():number
	if #self.Points == 2 then
		-- right.
		table.clear(self.Model)
		self.Length = (getVector(self.Points[#self.Points])-getVector(1)).Magnitude
		self.Model[1] = {1,self.Length}
		return self.Length
	elseif self.Points >= 3 then
		-- plan is: divide it into multiple little segments and approximate the length.
		-- not the most efficient way to calculate the length of a Bezier spline
		-- best would be to represent the curve mathematically and then calculate the length.
		-- looked into it on stackexchange for better results, didnt find much... except this, which recommended the same thing:
		-- https://gamedev.stackexchange.com/questions/5373/moving-ships-between-two-planets-along-a-bezier-missing-some-equations-for-acce/5427#5427

		-- we set self.Model and self.Length, the same way Line class does it.
		local N = self.Resolution or 100
		table.clear(self.Model)
		local totalLength = 0
		for i = 1, N do
			local point = self:CalculatePositionAt(i/N)
			local previousPoint = if self.Model[i-1] then self:CalculatePositionAt(self.Model[i-1][1]) else getVector(self.Points[1])
			totalLength += (point - previousPoint).Magnitude
			self.Model[i/N] = {totalLength, point-previousPoint} -- we wont put the point number first, but the length, then the vector to get there
		end

		self.Length = totalLength

		return totalLength
	end
	
	return 0
end

return bezierSpline
