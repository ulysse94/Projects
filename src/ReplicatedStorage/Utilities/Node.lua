--!strict
--[[Ulysse94]]--

-- nodes are like switches.

local node = {}
local nodeFunctions = require(game.ReplicatedStorage.Utilities.NodeFunctions)

--[[
	Creates a new node.
	Note that __back section must be unique__, while there can be multiple front sections.
	Do not use for crossovers.
	backSection and frontSections are spline objects.
	`Model` is the BasePart which represents the node.
]]
function node.new(model:BasePart, backSection, frontSections:{})
	local self = {}

	self.Part = model
    self.BackSection = backSection
	self.FrontSections = frontSections
	self.SwitchPosition = 1

	--[[This property gives the same thing as a spline:

	{
		[1]=back connection point,
		[2]=(current) front connection point
	}
	]]
	self.Connections = {
		[1] = self.BackSection,
		[2] = nil
	}

	setmetatable(self, {
		__index = node,
		__tostring = function()
			return "Node"
		end,
	})

	self:UpdatePosition(1)

	return self
end

function node:UpdatePosition(newPosition:number):nil
	newPosition = newPosition%(#self.FrontSections) -- clamping
	self.SwitchPosition = newPosition
	self.Connections[2] = self.FrontSections[self.SwitchPosition]
	assert(self.Connections[2]["Points"], 'Incorrect connection in node. Does not have a "Points" property set.')

	local section = self.Connections[2]["Points"][1].Parent


	return
end

return node
