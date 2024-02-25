--[[Ulysse94]]--

--[[

Constructors:
	new (target [GuiObject], inputSources[{GuiObject}?])

Properties:
	(READ ONLY) _Maid [Maid]
		maid.

	(READ ONLY) RelativePosition [Vector2]
		Position relative to where the mouse clicked / selection gained.

	(READ ONLY) Dragging [boolean]
		Wether or not the target is being dragged atm.
	
	(READ ONLY) InputSources [{GuiObject}]

Methods:
	Destroy () -> nil

Events:
	Dragged (state [UserInputState])
		Fired each time the target is dragged, with the input state (began / changed / ended).

]]

local Lib = script.Parent
local MaidClass = require(Lib.Utilities.Maid)

local Class = {}

Class.__index = Class
Class.__type = "Dragger"

function Class:__tostring()
	return Class.__type
end

function Class.new(target:GuiObject, inputSources:{GuiObject}?):{}
	local self = setmetatable({},Class)

	self._Maid = MaidClass.new()
	self.RelativePosition = Vector2.new()

	self.Target = target
	self.InputSources = {}
	self.Dragging = false

	self.AllowedInputTypes = {
		Enum.UserInputType.MouseButton1,
		Enum.UserInputType.MouseButton2,
	}

	self._DraggedEvent = Instance.new("BindableEvent")
	self.Dragged = self._DraggedEvent.Event

	if inputSources then
		for _, source in pairs(inputSources) do
			self:AddInputSource(source)
		end
	end

	return self
end

function Class:AddInputSource(inputSource:GuiObject):nil
	table.insert(self.InputSources, inputSource)

	local function disconnect()
		if self.Dragging == true then
			self._DraggedEvent:Fire(Enum.UserInputState.End)
		end
		self.Dragging = false
	end

	local cn1
	local cn2
	local cn3

	cn1 = inputSource.InputBegan:Connect(function(inobj:InputObject)
		if table.find(self.InputSources, inputSource) then
			if table.find(self.AllowedInputTypes, inobj.UserInputType) then
				self._DraggedEvent:Fire(Enum.UserInputState.Begin)
				self.RelativePosition = Vector2.new(inobj.Position.X, inobj.Position.Y)
				self.Dragging = true
			end
		else
			disconnect()
			cn1:Disconnect()
		end
	end)

	cn2 = inputSource.InputChanged:Connect(function(inobj:InputObject)
		if table.find(self.InputSources, inputSource) then
			if self.Dragging == true and table.find(self.AllowedInputTypes, inobj.UserInputType) then
				self._DraggedEvent:Fire(Enum.UserInputState.Change)
				self:_Process(Vector2.new(inobj.Position.X, inobj.Position.Y))
			end
		else
			disconnect()
			cn2:Disconnect()
		end
	end)

	cn3 = inputSource.InputEnded:Connect(function(inobj:InputObject)
		if not table.find(self.InputSources, inputSource) then
			cn3:Disconnect()
		end
		disconnect()
	end)

	return nil
end

function Class:RemoveInputSource(inputSource:GuiObject):nil
	if table.find(self.InputSources, inputSource) then
		table.remove(self.InputSources, table.find(self.InputSources, inputSource))
	end
end

function Class:_Process(newPosition:Vector2):nil
	self.Target.Position = UDim2.fromOffset(newPosition.X-self.RelativePosition.X,newPosition.Y-self.RelativePosition.Y)

	return nil
end

function Class:Destroy():nil
	self._Maid:Sweep()

	return
end

return Class
