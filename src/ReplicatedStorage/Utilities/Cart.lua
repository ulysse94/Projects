--!strict
--[[Ulysse94]]--

local cart = {}
local SplineIndex = _G.SplineIndex
local CartIndex = _G.CartIndex
local CartSplineIndex = _G.CartSplineIndex

assert(SplineIndex and CartIndex, "Cannot load module without _G.SplineIndex and _G.CartIndex defined.")

export type cartPosition = {
	["Spline"]:string, -- spline object NAME (same as the one in _G.SplineIndex)
	["Time"]:number, -- t position on the spline object
	["Direction"]:number, -- in what direction.
	-- <0: the train is going towards point 1 of the spline.
	-- >0: the train is going towards the last point of the spline.
	-- this direction is set WHEN THE OBJECT IS SPAWNED, AND SHOULD NOT CHANGE.

	-- ["CFrame"]:CFrame
}

--[[
	Creates a new cart object.
	The cart object is ONLY representing objects on tracks, and eventually handling moving objects on those.
]]
function cart.new(name:string, startPosition:cartPosition?)
	assert(CartIndex[name] == nil, "Cart name already in use. Change name to avoid collisions.")
	local self = {}
	self.Name = name

	setmetatable(self, {
		__index = cart,
		__tostring = function()
			return "Cart"
		end,
	})

	self._LastUpdatedSplinePos = nil
	self.Position = nil

	if startPosition then
		self:Move(startPosition)
	end

	table.insert(CartIndex, self)
	return self
end

-- Moves the cart while (eventually) updating the cart-spline index.
function cart:Move(newPosition:cartPosition, updateCartSplineIndex:boolean?):nil
	if updateCartSplineIndex == nil then updateCartSplineIndex = true end
	updateCartSplineIndex = (if not updateCartSplineIndex then false else true)

	self._LastUpdatedSplinePos = (if updateCartSplineIndex then self.Position else self._LastUpdatedSplinePos)
	self.Position = newPosition

	assert(CartSplineIndex[newPosition.Spline] and CartSplineIndex[self._LastUpdatedSplinePos.Spline], "")
	if updateCartSplineIndex then
		-- checks if the new position is another spline.
		if newPosition.Spline ~= self._LastUpdatedSplinePos.Spline then
			table.remove(CartSplineIndex[self._LastUpdatedSplinePos.Spline],
				table.find(CartSplineIndex[self._LastUpdatedSplinePos.Spline], self.Name)
			)
			table.insert(CartSplineIndex[newPosition.Spline], 1, self.Name)
		else -- just check if it's already in the CartSplineIndex
			if not table.find(CartSplineIndex[newPosition.Spline], self.Name) then
				table.insert(CartSplineIndex[newPosition.Spline], 1, self.Name)
			end
		end
	end

	return
end

--[[
	Scans the section for other potential carts. filterTag should be part of the cart's name.
	Distance can be negative, depending on the cart's direction.
	Returns the list of cart names.
]]
function cart:ScanSection(distance:number, filterTag:string?):{string}
	local found = {}
	-- fetch all splines in that direction, and distance.
	local pos, broken, passed = self:GetRelativePosition(distance)

	--[[ there are 3 zones to check:
		1. the starting spline, between the cart and the target goal (if the target goal is on the starting spline!)
		2. the ENTIRETY of the passed splines
		3. the LAST passed spline, between its begining and the target goal
	]]
	if broken then
		warn("Scan section shortened: broken tracks.")
	end

	assert(#passed ~= 0, "Did not get any passed splines from GetRelativePosition.")

	-- 1. in the starting spline
	for _, cartName in pairs(CartSplineIndex[passed[1][1]]) do
		local fC = CartIndex[cartName]

		local inDistance = false --avoid redundancy
		if passed[1][2] < 0 then
			if fC.Position.Time - passed[1][3] >= 0 and fC.Position.Time <= self.Position.Time then
				inDistance = true
			end
		elseif passed[1][2] > 0 then
			if passed[1][3] - passed[1][3] <= 0 and fC.Position.Time >= self.Position.Time then
				inDistance = true
			end
		end

		if inDistance and filterTag and string.find(cartName, filterTag, 1, true) then
			table.insert(found, 1, cartName)
		elseif inDistance and not filterTag then
			table.insert(found, 1, cartName)
		end
	end

	-- 2. check the other splines (fully, no distance check)
	if #passed > 2 then
		for i = 2, #passed-1, 1 do
			for _, cartName in pairs(CartSplineIndex[passed[i][1]]) do
				if filterTag and string.find(cartName, filterTag, 1, true) then
					table.insert(found, 1, cartName)
				elseif not filterTag then
					table.insert(found, 1, cartName)
				end
			end
		end
	end

	-- 3. check the last spline
	if #passed >= 2 then
		for _, cartName in pairs(CartSplineIndex[passed[#passed][1]]) do
			local fC = CartIndex[cartName]

			local inDistance = false --avoid redundancy
			if passed[1][2] < 0 then
				if fC.Position.Time - passed[1][3] >= 0 then
					inDistance = true
				end
			elseif passed[1][2] > 0 then
				if passed[1][3] - passed[1][3] <= 0 then
					inDistance = true
				end
			end

			if inDistance and filterTag and string.find(cartName, filterTag, 1, true) then
				table.insert(found, 1, cartName)
			elseif inDistance and not filterTag then
				table.insert(found, 1, cartName)
			end
		end
	end

	return found
end

--[[ gets the position that is forward/backward, movingDistance being a distance in studs (+/-).

	Returns **TUPLES**:

-- CartPosition as usual

-- Boolean, determines if the loop was forcibly broken because the connections did not allow to go that far.

-- used splines in an index (splines it used to reach the goal position): { {spline name, direction, time passed in (0 if node)} }
]]
function cart:GetRelativePosition(movingDistance:number):any
	assert(self.Position~=nil, "Cart doesn't have a position yet.")

	local currentSplineLength = SplineIndex[self.Position.Spline].Length
	local currentSplineTime = self.Position.Time
	local currentDirection:number = self.Position.Direction

	local newPosition = {
		["Spline"] = nil,
		["Direction"] = nil,
		["Time"] = nil,
		-- ["CFrame"] = nil
	}

	local broken = false

	local passedSplines = {}

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

		table.insert(passedSplines, 1, {self.Position.Spline, currentDirection, newTime})
	else -- Situation 2.
		-- On cherche la distance qui "overflow".
		local newDirection = self.Position.Direction
		if newTime>1 then -- Le temps "overflow" vers l'avant. On cherche vers les sections avants.
			newDirection = 1
		elseif newTime<0 then -- Le temps "overflow" vers l'arrière.
			newDirection = -1
		end

		movingDistance *= math.sign(currentDirection) --we make it positive. the direction is handled by newDirection.

		local newSplineName = self.Position.Spline
		local newSpline = SplineIndex[newSplineName]

		table.insert(passedSplines, {newSplineName, newDirection, newSpline.Length})

		-- tant qu'on n'est pas au bout, on continue à chercher plus loin.
		while movingDistance > newSpline.Length do
			local p = newSpline.Connections[math.sign(if newDirection < 0 then 1 else 2)]

			-- this is not the spline yet, only its control point.
			-- to get the spline from a point, look for its parent name in the SplineIndex.
			if p then
				if SplineIndex[p.Parent.Name] then
					-- it is a control point (part of spline).

					newSpline = SplineIndex[p.Parent.Name]
					-- assert(newSpline~=nil, "Incorrect connection: Spline not found: "..p.Parent.Name.." from "..newSplineName)
					newSplineName = p.Parent.Name

					-- now set the new direction
					if p.Name == "1" then
						newDirection = 1 -- we are coming from the back section, going forward.
					else
						newDirection = -1 -- we are coming from the forward section, going backward.
					end

					table.insert(passedSplines, {newSplineName, newDirection, newSpline.Length})

					movingDistance -= newSpline.Length
				elseif SplineIndex[p.Name] then
					-- it is a node.
					--movingDistance -= newSpline.Length -- it is 0! not setting it!

					-- to determine the direction now, we need to check the entry point (where we are entering the node)
					-- since it is a node, we have to use the point, and not the section. we use the .Connections, much easier this way.
					local oldPoint = newSpline.Points
					if newDirection == -1 then -- we determine the last point by using the last direction used.
						oldPoint = oldPoint[1]
					else
						oldPoint = oldPoint[#oldPoint]
					end

					newSpline = SplineIndex[p.Name]
					-- assert(newSpline~=nil, "Incorrect connection: Spline not found: "..p.Name.." from "..newSplineName)
					newSplineName = p.Name

					if newSpline.Connections[1] == oldPoint then -- Connections[1] of a node is always set. Sometimes, Connections[2] isn't.
						newDirection = 1
					else
						newDirection = -1
					end

					table.insert(passedSplines, {newSplineName, newDirection, 0})
				else -- JUST in case.
					broken = true
					warn("Incorrect control-point/node:", p:GetFullName())
					break
				end
			else
				-- cannot go forward, no connections, loop broken.
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
		newPosition.Spline = newSplineName
		newPosition.Direction = newDirection
		-- newPosition.CFrame = newSpline:CalculateCFrameAt(newTime)

		table.insert(passedSplines, {newSplineName, newDirection, movingDistance})
	end

	return newPosition, broken, passedSplines
end

return cart
