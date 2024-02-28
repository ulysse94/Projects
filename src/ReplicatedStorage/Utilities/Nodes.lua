--!strict
--[[Ulysse94]]--

-- nodes are like switches.

local node = {}

function node.new()
	local self = {}

    self.FrontConnections = {}
    self.BackConnections = {}

	setmetatable(self, {
		__index = node,
		__tostring = function()
			return "Node"
		end,
	})

	return self
end

return node
