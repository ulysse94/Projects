--!strict
--[[Ulysse94]]--

local cart = {}
local SplineIndex = _G.SplineIndex
local CartIndex = _G.CartIndex

assert(SplineIndex and CartIndex, "Cannot load module without _G.SplineIndex and _G.CartIndex defined.")

export type cartPosition = {
	["Spline"]:{}, -- spline object
	["Time"]:number, -- t position on the spline object
	["Direction"]:number -- in what direction.
	-- <0: the train is going towards point 1 of the spline.
	-- >0: the train is going towards the last point of the spline.
	-- this direction is set WHEN THE OBJECT IS SPAWNED, AND SHOULD NOT CHANGE.
}

--[[
	Creates a new cart object.
	The cart object is ONLY representing objects on tracks, and eventually handling moving objects on those.
]]
function cart.new(name:string, startPosition:cartPosition, model:Model)
	local self = {}

	self.Name = name

	setmetatable(self, {
		__index = cart,
		__tostring = function()
			return "Cart"
		end,
	})

	self.Model = model
	self.Position = startPosition
	self.ForwardSpace = 0
	self.BackwardSpace = 0

	return self
end

-- scans the section
function cart:ScanSection(...:number?):any?
	local orders = {...}

	for _, direction in pairs(orders) do

	end

	return
end

function cart:UpdateModel():nil


	return
end

--[[ gets the position that is forward/backward, movingDistance being a distance in studs (+/-).
Returns **TUPLES**:

-- CartPosition as usual

-- Boolean, determines if the loop was forcibly broken because the connections did not allow to go that far.
]]
function cart:GetRelativePosition(movingDistance:number):any
	local currentSplineLength = self.Position.Spline.Length
	local currentSplineTime = self.Position.Time
	local currentDirection:number = self.Position.Direction

	local newPosition = {
		["Spline"] = nil,
		["Direction"] = nil,
		["Time"] = nil
	}
	local broken = false

	--[[
	2 situations:

	1. La nouvelle position est sur la section.
		On doit tout simplement diviser la nouvelle position par la longueur du spline... et voilà.

	2. La nouvelle position n'est pas sur la section, il faut chercher la(les) suivante(s).
	]]

	local newTime = currentSplineTime + ((movingDistance * math.sign(currentDirection)) / currentSplineLength)

	if newTime >= 0 and newTime <= 1 then
		-- Situation 1.
		newPosition.Time = newTime
		newPosition.Spline = self.Position.Spline
		newPosition.Direction = currentDirection
	else -- Situation 2.
		-- On cherche la distance qui "overflow".
		local newDirection = self.Position.Direction
		if newTime>1 then -- Le temps "overflow" vers l'avant. On cherche vers les sections avants.
			newDirection = 1
		elseif newTime<0 then -- Le temps "overflow" vers l'arrière.
			newDirection = -1
		end

		local newSpline = self.Position.Spline
		-- tant qu'on n'est pas au bout, on continue à chercher plus loin.
		while movingDistance > newSpline.Length do
			local p = newSpline.Connections[math.sign(if newDirection < 0 then 1 else 2)]
			-- this is not the spline yet, only its control point.
			-- to get the spline from a point, look for its parent name in the SplineIndex.
			if p then
				if SplineIndex[p.Parent.Name] then
					-- it is a control point.
					movingDistance -= newSpline.Length
					newSpline = SplineIndex[p.Parent.Name]

					-- now set the new direction
					if p.Name == "1" then
						newDirection = 1 -- we are coming from the back section, going forward.
					else
						newDirection = -1 -- we are coming from the forward section, going backward.
					end
				elseif SplineIndex[p.Name] then
					-- it is a point.
					--movingDistance -= newSpline.Length -- it is 0! not setting it!
					local oldPoint = newSpline.Points
					if newDirection == -1 then
						oldPoint = oldPoint[1]
					else
						oldPoint = oldPoint[#oldPoint]
					end

					newSpline = SplineIndex[p.Name]

					if newSpline.Connections[1] == oldPoint then -- Connections[1] of a node is always set. Sometimes, Connections[2] isn't.
						newDirection = 1
					else
						newDirection = -1
					end

					-- now set the new direction
					if p.Name == "1" then
						newDirection = 1
					else
						newDirection = -1 -- we are coming from the forward section, going backward.
					end
				end
			else
				-- cannot go forward, loop broken.
				broken = true
				break
			end
		end

		-- clamp it if the loop was broken (no point forward)
		if math.sign(newDirection) == -1 then
			newTime = math.clamp((newSpline.Length - movingDistance) / newSpline.Length,0,1)
		else
			newTime = math.clamp(movingDistance / newSpline.Length,0,1)
		end

		newPosition.Time = newTime
		newPosition.Spline = newSpline
		newPosition.Direction = newDirection
	end

	return newPosition, broken
end

return cart
