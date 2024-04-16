--!strict
--[[Ulysse94]]--

-- nodes are like switches.

local node = {}
local nodeFunctions = require(game.ReplicatedStorage.Utilities.NodeFunctions)

--[[
	Creates a new node.
	Note that **back section must be unique**, while there can be multiple front sections.
	Do not use for crossovers.
	backSection and frontSections are spline objects.
	backSection is unique, while frontSections is a list.
	`Model` is the BasePart which represents the node.
]]
function node.new(model:BasePart, backSection:Model, frontSections:{Model?})
	local self = {}

	self.Length = 0
	self.Part = model
    self.BackSection = backSection -- unique
	self.FrontSections = frontSections -- list
	self.SwitchPosition = 1

	--[[
	This property gives the same thing as a spline:
	{
		[1]=back connection point,
		[2]=(current) front connection point
	}
	]]
	self.Connections = {}

	setmetatable(self, {
		__index = node,
		__tostring = function()
			return "Node"
		end,
	})

	self:UpdatePosition(1)

	return self
end

-- Update Connections property.
function node:UpdatePosition(newPosition:number):nil
	newPosition = newPosition%(#self.FrontSections) -- clamping
	self.SwitchPosition = newPosition
	local nSection = self.FrontSections[self.SwitchPosition]

	if not nSection then
		self.Connections[2] = nil
		return -- empty connection!
	end
	assert(self.FrontSections[self.SwitchPosition]:GetAttribute("BackConnection") or self.FrontSections[self.SwitchPosition]:GetAttribute("FrontConnection"), 
	'Incorrect connection with node. FrontSection does not have a "Back"/"Front"Connection attribute set.')
	local fPoint = nil

	local side = nodeFunctions.getConnectedSectionSide(self.Part, nSection)

	if side == 1 then -- back
		fPoint = nSection:FindFirstChild("1")
	elseif side == 2 then -- front
		fPoint = nSection:FindFirstChild(tostring(#nSection:GetChildren()))
	end

	self.Connections[2] = fPoint

	return
end

function node:UpdateFrontSections(newConnections:{Model?}):nil
	--checking if the attribute is the same
	local nS = ""
	table.foreachi(newConnections, function(k,v)
		nS = nS..","..v.Name
	end)
	self.Part:SetAttribute("FrontConnection",nS)

	--updating properties
	self.FrontSections = newConnections
	self.SwitchPosition = self.SwitchPosition%(#self.FrontSections)

	--updating position
	node:UpdatePosition(self.SwitchPosition)

	--done!

	return
end

return node
