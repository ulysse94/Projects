--!strict
--[[Ulysse94]]--
---@diagnostic disable: undefined-type
local signalIndex = _G.SignalIndex

local signal = {}
local cart = require(script.Parent.Cart)
-- local nodeFunctions = require(game.ReplicatedStorage.Utilities.NodeFunctions)

--[[
	Uses Cart as super-class.
	Simulates a signals, eventually a sign. Used for carts that do not move and give informations.
	It does not detect carts, but it can be used by carts that move.
]]
function signal.new(name:string, informations:{[string]:any}, position:cartPosition?, modelReference:Model?, modelOffset:Vector3?)
	local self = cart.new("SIGNAL_"..name)
	self.Info = informations
	self.ModelOffset = modelOffset or Vector3.zero

	setmetatable(self, {
		__index = signal,
		__tostring = function()
			return "Signal"
		end,
	})

	self:UpdatePosition(position)
	self:SetModel(modelReference)
	self:UpdateModel()

	table.insert(signalIndex, self)

	return self
end

--[[
	Sets the model of the signal and places it in the 3D world.
]]
function signal:SetModel(modelReference:Model?):nil
	if not self.Model then
		self.Model = modelReference:Clone()
	else
		self.Model:Destroy()
		self.Model = modelReference:Clone()
	end

	self.Model:SetAttribute("Signal", self.Name)
	self:UpdatePosition(self.Position)

	return
end

--[[
	Updates the model, not to a new one, but to show new informations (such as for traffic lights or speed limits).
]]
function signal:UpdateModel():nil
	if self.Model then
		local moduleName = self.Model:GetAttribute("ModuleScript")
		local module = require(game.ServerStorage.SignalsStorage.Plugins:FindFirstChild(moduleName))

		module(self.Model, self.Info)
	end

	return
end

--[[
	Sets new informations to the signal, and eventually updates the model.
]]
function signal:UpdateInformations(newInformations:{[string]:any}, updateModel:boolean?):nil
	self.Info = newInformations
	updateModel = (if updateModel then updateModel else true)

	if updateModel then
		self:UpdateModel()
	end

	return
end

--[[
	Returns the informations of the signal.
]]
function signal:GetInformations():{[string]:any}
	return self.Info
end

--[[
	Sets the model offset.
]]
function signal:SetModelOffset(offset:Vector3):nil
	self.ModelOffset = offset
	self:UpdatePosition(self.Position)

	return
end

--[[
	Sets the model position alongside the cart's one.
]]
function signal:UpdatePosition(newPosition:cartPosition):nil
	self:Move(newPosition)
	if self.Model then
		self.Model:PivotTo(self.Position + self.ModelOffset)
	end

	return
end

return
