--!strict
--[[Ulysse94]]--

local line = {}
local matrix = require(game.ReplicatedStorage.Utilities.Matrix)

--[[
	Creates a new Line object
]]
function line.new(controlPoints: {Vector2} | {Vector3 | BasePart}?, resolution:number?)
	local self = {}
	
	self.Type = "Line"
	self.Points = nil
	self.Model = {}
	self.Connections = {} -- Set by the server.
	--[[ Will return a table this way:
	{
		[1] = BackConnectionPoint,
		[2] = FrontConnectionPoint
	}
	]]
	self.Length = 0

	setmetatable(self, {
		__index = line,
		__tostring = function()
			return "Line"
		end,
	})
	
	self:UpdatePoints(controlPoints)

	return self
end

local function getVector(vec:Vector2|Vector3|BasePart):Vector2|Vector3
	if type(vec) == "userdata" then
		return vec.Position
	else 
		return vec
	end
end

--[[
	Tells you how far the next control point (i+1) is.
]]
function line:CalculateLengthBetweenControlPoint(i:number):number
	return (getVector(self.Points[i]) - getVector(self.Points[i+1])).Magnitude
end

--[[
	Calculates the position vector at t.
	Commented this function as it was using the most unefficient (and broken) way of doing it.
]]
--function line:CalculatePositionAt(t:number):Vector3|Vector2
--	assert(t>=0 and t<=1, "t must be in the range [0;1]")
--	local summedLength = 0
--	local i = 1
	
--	while summedLength < t do
--		summedLength += self:CalculateLengthBetweenControlPoint(i)
--		i+=1
--	end
--	-- if the loop ends, it means it went over t, so "t" is between i-1 and i.
--	summedLength -= self:CalculateLengthBetweenControlPoint(i-1)
--	-- get the look vector, will be returned as the derivate.
--	local vector = getVector(self.Points[i]) - getVector(self.Points[i-1])
--	-- we have already passed through summedLength/totalLength.
--	-- we substract this to "t", and then interpolate between the 2 points.
--	local tBetweenPoints = (t-(summedLength/self:CalculateLength()))
--	-- vector is the directional vector, so it will be alright.
--	local position = vector * tBetweenPoints
	
	
--	return position
--end

--[[
	Updates the line model (mathematical thing).
	Updates the "Model" property. It divides the line in multiple vectors depending of "t".
	Returns:
		{
			[t] = {i, directional vector}
		}
]]
function line:UpdatePoints(newControlPoints:{Vector2} | {Vector3 | BasePart}?):{[number]:number}
	self.Points = newControlPoints or {}
	local totalLength = 0
	local t = 0
	local ret = {}
	
	for i = 1,#self.Points-1,1 do
		local length = self:CalculateLengthBetweenControlPoint(i)
		local partRatio = length / totalLength
		ret[t] = {i, getVector(self.Points[i+1]) - getVector(self.Points[i])} -- point number, directional vector.
		t+=partRatio
		totalLength += length
	end
	
	self.Length = totalLength
	self.Model = ret
	
	return ret
end

--[[
	Calculates the position vector at t.
]]
function line:CalculatePositionAt(t:number):Vector3|Vector2
	assert(t>=0 and t<=1, "t must be in the range [0;1]")
	local ret = nil
	local tLowest = 0
	local tUpper = 1
	local point = nil
	local directional = nil
	
	-- do NOT use the next() function, it does NOT work reliably.
	for tPart, parts in pairs(self.Model) do
		if tPart <= t --[[and (next(self.Model, tPart) or 1) > t]] and tLowest <= tPart then 
			-- "<=" because tLowest can be == 0, and then have to take the first point.
			tLowest = tPart
			--tUpper = (next(self.Model, tPart) or 1)
			point = self.Points[parts[1]].Position
			directional = parts[2]
		end
	end
	
	--so i have to look for tUpper manually
	for tPart, parts in pairs(self.Model) do
		if tPart > t and tUpper > tPart then
			tUpper = tPart
		end
	end
	
	-- we multiply the directional vector by the percentage of t that is on this thing.
	local partLength = tUpper-tLowest
	ret = directional * ((t-tLowest)/partLength) + point
	
	return ret
end

function line:CalculateDerivateAt(t:number):Vector3|Vector2
	assert(t>=0 and t<=1, "t must be in the range [0;1]")
	local directional = nil
	local tLowest = 0

	-- do NOT use the next() function, it does NOT work reliably.
	for tPart, parts in pairs(self.Model) do
		if tPart <= t --[[and (next(self.Model, tPart) or 1) > t]] and tLowest <= tPart then 
			directional = parts[2]
			tLowest = tPart
		end
	end

	return directional
end

--[[
	Returns the interpolated value of the banking angle.
	Used to get the UpVector.
	The returned angle is in radians.
]]
function line:GetBankAngleAt(t:number):number
	local startAngle = self.Points[1]:GetAttribute("Angle") or 0
	local endAngle = self.Points[#self.Points]:GetAttribute("Angle") or 0
	local diff = endAngle - startAngle -- This is the angle if you are going in the "positive direction".
	return math.rad(math.deg(diff * t + startAngle)) -- this funny thing clamps the radian between pi and 2pi
end

function line:CalculateCFrameAt(t:number):CFrame
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

return line
