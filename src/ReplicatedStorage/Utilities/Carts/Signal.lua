--!strict
--[[Ulysse94]]--

local signal = {}
local cart = require(script.Parent.Cart)
-- local nodeFunctions = require(game.ReplicatedStorage.Utilities.NodeFunctions)

--[[
	
]]
function signal.new()
	local self = {}

	

	setmetatable(self, {
		__index = signal,
		__tostring = function()
			return "Signal"
		end,
	})

	return self
end

return 
