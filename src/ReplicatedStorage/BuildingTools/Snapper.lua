--[[Ulysse94]]--

--TODO: Make it chunk-based (like Octree), eventually switching to Nevermore/Quenty's Octree.

--[[

Constructors:
	new (snapPoints [{Vector3|BasePart}], currentPos [Vector3?])
		Controls the Mouse to snap build models to the given snapPoints.

Properties:
	(READ ONLY) _Maid [Maid]
		maid.

	SnapPoints [{Vector3|BasePart}]

	(READ ONLY) CurrentPosition [Vector3]

Methods:
	ChangePosition (newPos [Vector3]) -> Vector3|BasePart
		Changes the current position and returns the closest snap point.

Events:
	None
]]

local Class = {}

Class.__index = Class
Class.__type = "Snapper"

function Class:__tostring()
	return Class.__type
end

-- Generates quickly a set of snap points for a grid.
function Class.GridSnapPoints(sizeX:NumberRange, xIncrement:number, sizeY:NumberRange, yIncrement:number, sizeZ:NumberRange, zIncrement:number):{Vector3}
	local snapPoints = {}
	for x = sizeX.Min,sizeX.Max,xIncrement do
		for y = sizeY.Min,sizeY.Max,yIncrement do
			for z = sizeZ.Min,sizeZ.Max,zIncrement do
				table.insert(snapPoints, Vector3.new(x,y,z))
			end
		end
	end
	return snapPoints
end

function Class.new(snapPoints:{BasePart|Vector3}, currentPos:Vector3?):{}
	local self = setmetatable({},Class)

	self.SnapPoints = snapPoints
	self.CurrentPosition = currentPos or Vector3.zero
	self.ClosestSnapPoint = nil

	self:ChangePosition(self.CurrentPosition)

	return self
end

function Class:ChangePosition(newPos:Vector3):Vector3|BasePart
	self.CurrentPosition = newPos
	local closest = nil

	for i, snapPoint in pairs(self.SnapPoints) do
		local distance
		if typeof(snapPoint) == "Vector3" then
			distance = (snapPoint - self.CurrentPosition).Magnitude
---@diagnostic disable-next-line: invalid-class-name
		elseif typeof(snapPoint) == "BasePart" then
			distance = (snapPoint.Position - self.CurrentPosition).Magnitude
		end
		if distance < (closest or math.huge) then -- math.huge because closest==nil at the begining.
			closest = snapPoint
		end
	end

	self.ClosestSnapPoint = closest
	return closest
end

return Class