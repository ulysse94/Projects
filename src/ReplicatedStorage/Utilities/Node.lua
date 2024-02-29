--!strict
--[[Ulysse94]]--

-- nodes are like switches.

local node = {}

--[[
	Creates a new node.
	Note that __back section must be unique__, while there can be multiple front sections.
	Do not use for crossovers.
	`Model` is the BasePart which represents the node.
]]
function node.new(model:BasePart, backSection, frontSections:{})
	local self = {}

    self.BackSection = backSection
	self.FrontSections = frontSections
	self.SwitchPosition = 1

	setmetatable(self, {
		__index = node,
		__tostring = function()
			return "Node"
		end,
	})

	return self
end

return node
