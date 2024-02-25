--[[Ulysse94]]--

--[[

Constructors:
	new ()

Properties:
	(READ ONLY) _Maid [Maid]
		maid.
	
Methods:
	Destroy () -> nil

Events:
	Event ()
		
	
]]

local Lib = script.Parent
local MaidClass = require(Lib.Utilities.Maid)

local Class = {}

Class.__index = Class
Class.__type = "ClassSample"

function Class:__tostring()
	return Class.__type
end

function Class.new(elements:{string}, target:TextButton):{}
	local self = setmetatable({},Class)

	self._Maid = MaidClass.new()

	return self
end

function Class:Destroy():nil
	self._Maid:Sweep()

	return
end

return Class
