--[[Ulysse94]]--

--[[

Constructors:
	new (elements [ [string] ], target [TextButton])
		Creates a new dropdown in the TextButton. Also loads required bullshit related to it (such as the arrow, and the currently selected option).

Properties:
	(READ ONLY) _Maid [Maid]
		maid.

	(READ ONLY) _ShowedEvent [BindableEvent]

	(READ ONLY) _OptionChangedEvent [BindableEvent]

	_OptionTextLabel [TextLabel]

	_OptionArrow [ImageLabel]

	_ListFrame [ScrollingFrame]

	(READ ONLY) _FillWay [number]

	(READ ONLY) Parent [TextButton]
		Target TextButton. Current target of the dropdown.

	(READ ONLY) Current [string]
		Currently selected option.

	Elements [ [string] ]
		Self-explanatory. UpdateListFrame must be called too.

	(READ ONLY) CanDrop [boolean]
		Can the dropdown be opened.

	(READ ONLY) IsOpened [boolean]
		Is dropdown opened.

	AddNilOption [boolean]
		UpdateListFrame should be called while setting this property. Default is false.

	CloseOnSelection [boolean]
		Default is true.

Methods:
	_SetFillWay() -> nil

	_GetRequiredSize() -> number,number

	_Create () -> nil
		Creates everything required to make the dropdown work (button, if not set, listframe, etc.)

	_Update () -> nil
		Self-explanatory. Updates everything (calls _Create to add back the UIGridLayout... as always).

	_CreateButton (value [string?]) -> nil

	Destroy () -> nil

	SetCanDrop (toggle [boolean]) -> nil

	Show (toggle [boolean]) -> nil
		Toggles the dropdown.

	Set (option [string?]) -> nil
		Set dropdown to a new option. Errors if the element is invalid. Shows "N/A" if nil.

	Get () -> string?
		Current option selected.

Events:
	OptionChanged (newop [string])
		you got it. Fires when the user changes options.

	Showed ()
		Fires when dropdown is opened/closed.

]]

local Lib = script.Parent

local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")

local DEFAULT_SETTINGS = {
	ARROW = "rbxassetid://5143165549",

	TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	TEXT_SIZE = 14,
	TEXT_FONT = Enum.Font.Gotham,
	TEXT_WEIGHT = Enum.FontWeight.Medium,

	LIST_BACKGROUND_COLOR3 = Color3.fromRGB(30, 30, 30),
	LIST_BACKGROUND_TRANSPARENCY = .4,
	LIST_BUTTON_TRANSPARENCY = .15,
	LIST_SCROLLBAR_SIZE = 5,
	LIST_PADDING = 3,
	LIST_MINIMUM_X = 40, --Minimum frame size: 80 pixels.
	LIST_MINIMUM_Y = 14 + 4, --TEXT_SIZE + 4
	LIST_BORDER_PADDING = 10,

	TWEENINFO = TweenInfo.new(.25,Enum.EasingStyle.Quart,Enum.EasingDirection.In,0,false,0)
}
--local ARROW_UP = "rbxassetid://5154078925"

local Class = {}

Class.__index = Class
Class.__type = "Dropdown"

function Class:__tostring()
	return Class.__type
end

function Class.new(elements:{string}, target:TextButton):{}
	assert(elements ~= nil and #elements > 0, "Missing elements.")
	assert(target, "Missing target TextButton.")

	local self = setmetatable({},Class)

	self._Maid = require(Lib.Utilities.Maid).new()

	--Check for redundancy in the elements table
	local temp = {}
	for i,v in ipairs(elements) do
		if not table.find(temp,v) then
			table.insert(temp,v)
		else
			warn("Redundancy detected while generating dropdown:",v)
		end
	end

	--Properties
	self.Elements = temp
	self.Current = self.Elements[1]
	self.CanDrop = true
	self.IsOpened = false
	self.AddNilOption = false
	self.CloseOnSelected = true
	self.Parent = target

	self._Settings = DEFAULT_SETTINGS

	self.Parent.ClipsDescendants = false

	--Events
	self._ShowedEvent = Instance.new("BindableEvent")
	self.Showed = self._ShowedEvent.Event

	self._OptionChangedEvent = Instance.new("BindableEvent")
	self.OptionChanged = self._OptionChangedEvent.Event

	self._Maid:Mark(self._ShowedEvent)
	self._Maid:Mark(self._OptionChangedEvent)

	--UI
	self._OptionTextLabel = self.Parent:FindFirstChild("OptionTextLabel")
	self._OptionArrow = self.Parent:FindFirstChild("OptionArrow")
	self._ListFrame = self.Parent:FindFirstChild("ListFrame")

	self:_Create()
	self:_Update() --_SetFillWay is here.

	self._Maid:Mark(self.Parent.Changed:Connect(function(property)
		if property == "Size" or property == "Position" then
			self:_Update()
		end
	end))

	self._Maid:Mark(self.Parent.Destroying:Connect(function()
		self:Destroy()
	end))

	self._Maid:Mark(self.Parent.MouseButton1Click:Connect(function()
		self:Show(not self.IsOpened)
	end))

	return self
end

function Class:_SetFillWay()
	local availableSpace = self._Settings.LIST_MINIMUM_Y --default
	local screenSize = self._ListFrame.Parent.AbsoluteSize.Y --Absolute size of the screen gui.
	local listLength = self._ListFrame:FindFirstChildOfClass("ScrollingFrame").CanvasSize.Y.Offset
	--print(listLength, screenSize - self.Parent.AbsolutePosition.Y - self.Parent.AbsoluteSize.Y)
	--Where is there the most space (in px)? Up or down?
	if screenSize - self.Parent.AbsolutePosition.Y - self.Parent.AbsoluteSize.Y > listLength + self._Settings.LIST_BORDER_PADDING then
		--Have enough space down.
		availableSpace = listLength + 6
		--print("full down")
	elseif self.Parent.AbsolutePosition.Y > listLength + self._Settings.LIST_BORDER_PADDING then
		--Not enough space down, looking up.
		availableSpace = -(listLength + 6)
		--print("full up")
	elseif screenSize - self.Parent.AbsolutePosition.Y - self.Parent.AbsoluteSize.Y > self.Parent.AbsolutePosition.Y then
		--Neither. Looking for best.
		--Down
		availableSpace = screenSize - self.Parent.AbsolutePosition.Y - self.Parent.AbsoluteSize.Y - self._Settings.LIST_BORDER_PADDING
		--print("down")
	else --Up
		availableSpace = -self.Parent.AbsolutePosition.Y + self._Settings.LIST_BORDER_PADDING
		--print("up")
	end

	self._FillWay = availableSpace

	return
end

function Class:_GetRequiredSize():number
	--What size should be the scrolling frame (and listFrame Y)?
	local YSize = self._FillWay

	if YSize < 0 then
		YSize *= -1
	end
	if YSize < self._Settings.LIST_MINIMUM_Y then
		YSize = self._Settings.LIST_MINIMUM_Y
	end

	local XSize = self.Parent.AbsoluteSize.X
	if XSize < self._Settings.LIST_MINIMUM_X then
		XSize = self._Settings.LIST_MINIMUM_X
	end

	return XSize,YSize
end

function Class:Set(option:string?):nil
	if option ~= self.Current then
		if option ~= nil then
			assert(self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild(option), "Option is invalid.")

			self.Current = option
		else
			self.Current = nil
		end

		self:_Update()
		--self:Show(true)

		self._OptionChangedEvent:Fire(option)
	end

	return
end

function Class:Show(toggle:boolean):nil
	--self:_SetFillWay()
	self:_Update()

	if toggle ~= self.IsOpened then
		local XSize,YSize = self:_GetRequiredSize()

		if self.CanDrop == true and toggle == true then
			--Open
			self.IsOpened = true
		else
			--Close
			self.IsOpened = false
		end

		if self._ListFrame then
			--print(XSize,YSize)
			self._ListFrame.Visible = self.IsOpened
			TS:Create(self._ListFrame,self._Settings.TWEENINFO,{Size=UDim2.new(0,XSize, 0, (self.IsOpened and YSize or 0))}):Play()
		end

		task.wait(self._Settings.TWEENINFO.Time)

		self._ShowedEvent:Fire()
	end

	self:_Update()

	return
end

function Class:Get():string?
	return self.Current
end

function Class:SetCanDrop(toggle:boolean):nil
	self.CanDrop = false
	self:Show(false)

	return
end

function Class:_CreateButton(value:string?):nil
	local nButton = Instance.new("TextButton")
	nButton.Text = value or "N/A"
	nButton.Font = self._Settings.TEXT_FONT
	nButton.TextSize = self._Settings.TEXT_SIZE
	nButton.FontFace.Weight = self._Settings.TEXT_WEIGHT
	nButton.TextColor3 = self._Settings.TEXT_COLOR3

	nButton.BackgroundColor3 = self._Settings.LIST_BACKGROUND_COLOR3
	nButton.BackgroundTransparency = self._Settings.LIST_BUTTON_TRANSPARENCY
	nButton.BorderSizePixel = 0
	nButton.Size = UDim2.new(0,nButton.TextBounds.X, 0, nButton.TextSize + 2)

	nButton.Name = value or "N/A"
	if self.Current == value then
		nButton.Visible = false
	else
		nButton.Visible = true
	end

	self._Maid:Mark(nButton.MouseButton1Click:Connect(function()
		self:Set((value ~= nil and nButton.Name or nil))
		if self.CloseOnSelected == true then
			self:Show(false)
		end
	end))

	nButton.Parent = self._ListFrame:FindFirstChildOfClass("ScrollingFrame")

	return
end

function Class:_Create():nil
	--Create every instances that are required.
	if not self._ListFrame then
		self._ListFrame = Instance.new("Frame")
		self._ListFrame.Name = "DropdownFrame"

		self._ListFrame.ClipsDescendants = true
		self._ListFrame.BorderSizePixel = 0

		self._ListFrame.Parent = self.Parent:FindFirstAncestorOfClass("ScreenGui")

		self._Maid:Mark(self._ListFrame)
	end

	if not self._ListFrame:FindFirstChildOfClass("ScrollingFrame") then
		local nScrollingFrame = Instance.new("ScrollingFrame")

		nScrollingFrame.Position = UDim2.fromOffset(3,3)
		nScrollingFrame.Size = UDim2.new(1,-6,0,-6)
		nScrollingFrame.BackgroundTransparency = 1
		nScrollingFrame.ClipsDescendants = true
		nScrollingFrame.ScrollingEnabled = true
		nScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.XY

		nScrollingFrame.Parent = self._ListFrame

		--self._Maid:Mark(nScrollingFrame)
	end

	if not self._OptionArrow then
		self._OptionArrow = Instance.new("ImageLabel")
		self._OptionArrow.BackgroundTransparency = 1
		self._OptionArrow.AnchorPoint = Vector2.new(1,0)
		self._OptionArrow.Position = UDim2.fromScale(1,0)
		self._OptionArrow.Size = UDim2.new(0,40,1,0)
		self._OptionArrow.ScaleType = Enum.ScaleType.Fit
		self._OptionArrow.Parent = self.Parent

		self._Maid:Mark(self._OptionArrow)
	end

	if not self._OptionTextLabel then
		self._OptionTextLabel = Instance.new("TextLabel")
		self._OptionTextLabel.BackgroundTransparency = 1

		self._OptionTextLabel.Position = UDim2.new(0,0,0,0)
		self._OptionTextLabel.Size = UDim2.fromScale(1,1)
		self._OptionTextLabel.TextXAlignment = Enum.TextXAlignment.Left
		self._OptionTextLabel.Parent = self.Parent

		self._Maid:Mark(self._OptionTextLabel)
	end
end

function Class:_Update():nil

	-- self:_Create() -- yeah uh... it's kinda dumb you know?

	--noramlly, everything's here... or maybe not.

	-- if not self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChildOfClass("UIGridLayout") then
	local nGrid = self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstAncestorOfClass("UIGridLayout") or Instance.new("UIGridLayout")

	nGrid.CellPadding = UDim2.new(0,0,0,self._Settings.LIST_PADDING)
	nGrid.CellSize =  UDim2.new(1,-self._Settings.LIST_SCROLLBAR_SIZE,0,self._Settings.TEXT_SIZE+2)
	nGrid.Parent = self._ListFrame:FindFirstChildOfClass("ScrollingFrame")
	-- end

	-- okay NOW everything's here

	self._OptionTextLabel.TextColor3 = self._Settings.TEXT_COLOR3
	self._OptionTextLabel.TextSize = self._Settings.TEXT_SIZE
	self._OptionTextLabel.Font = self._Settings.TEXT_FONT
	self._OptionTextLabel.FontFace.Weight = self._Settings.TEXT_WEIGHT

	self._ListFrame:FindFirstAncestorOfClass("ScrollingFrame").ScrollBarThickness = self._Settings.LIST_SCROLLBAR_SIZE

	self._OptionArrow.Image = self._Settings.ARROW

	self._ListFrame.BackgroundColor3 = self._Settings.LIST_BACKGROUND_COLOR3
	self._ListFrame.BackgroundTransparency = self._Settings.LIST_BACKGROUND_TRANSPARENCY

	--checks for missing elements, and sets button visible to false just in case.
	for _,value in pairs(self.Elements) do
		if not self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild(value) then
			self:_CreateButton(value)
		else
			if value == self.Current then
				self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild(value).Visible = false
			elseif self.Current == nil and self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild("N/A") then
				self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild("N/A").Visible = false
				--it will be created if not already there.
			else
				self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild(value).Visible = true
				if self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild("N/A") and self.AddNilOption then
					self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild("N/A").Visible = true
				end
			end
		end
	end

	if self.AddNilOption == true and not self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild("N/A") then
		self:_CreateButton(nil)
	end

	--checks for to-be-removed buttons
	for _,button in pairs(self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):GetChildren()) do
		if button:IsA("TextButton") then
			if not table.find(self.Elements, button.Name) and button.Name ~= "N/A" then
				button:Destroy()
			elseif button.Name == "N/A" and self.AddNilOption == false then
				button:Destroy()
			end
		end
	end

	self._ListFrame.Visible = self.IsOpened
	--self._ListFrame.Position = UDim2.fromOffset(self.Parent.AbsolutePosition.X, self.Parent.AbsolutePosition.Y)

	self:_SetFillWay()

	local XSize,YSize = self:_GetRequiredSize()

	--Put list up or down. Also set anchor so size animation isn't messed up.
	if self._FillWay >= 0 then
		self._ListFrame.AnchorPoint = Vector2.new(0,0)
		self._ListFrame.Position = UDim2.fromOffset(self.Parent.AbsolutePosition.X,
			self.Parent.AbsolutePosition.Y + self.Parent.AbsoluteSize.Y)
	else
		self._ListFrame.AnchorPoint = Vector2.new(0,1)
		self._ListFrame.Position = UDim2.fromOffset(self.Parent.AbsolutePosition.X, self.Parent.AbsolutePosition.Y)
	end

	--Set the actual size.
	self._ListFrame.Size = UDim2.new(0,XSize, 0, (self.IsOpened and YSize or 0))

	--Scrolling frame size is always the same, wether the dropdown is opened or not.
	self._ListFrame:FindFirstChildOfClass("ScrollingFrame").Size = UDim2.new(1,-6,1,-6) -- -6px for the 3px margin.

	--Canvas size for scrolling frame. I'm not leaving it to math.huge. I'm not an idiot.
	self._ListFrame:FindFirstChildOfClass("ScrollingFrame").AutomaticCanvasSize = Enum.AutomaticSize.XY
	-- if self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChildOfClass("UIGridLayout") then
	-- 	self._ListFrame:FindFirstChildOfClass("ScrollingFrame").CanvasSize = UDim2.new(
	-- 		0,self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChildOfClass("UIGridLayout").AbsoluteContentSize.X,
	-- 		0,self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):FindFirstChildOfClass("UIGridLayout").AbsoluteContentSize.Y
	-- 	)
	-- else --fallsafe.. nobody knows what can happen.
	-- 	self._ListFrame:FindFirstChildOfClass("ScrollingFrame").CanvasSize = UDim2.new(
	-- 		0,LIST_MINIMUM_X,
	-- 		0,LIST_MINIMUM_Y * #self._ListFrame:FindFirstChildOfClass("ScrollingFrame"):GetChildren()
	-- 	)
	-- end

	--Updating other stuff (arrow)
	if self._FillWay then
		if self.IsOpened == true then
			if self._FillWay > 0 then
				--Down
				self._OptionArrow.Rotation = 180
			elseif self._FillWay < 0 then
				--Up
				self._OptionArrow.Rotation = 0
			end
		else
			if self._FillWay > 0 then
				--Down
				self._OptionArrow.Rotation = 0
			elseif self._FillWay < 0 then
				--Up
				self._OptionArrow.Rotation = 180
			end
		end
	end

	--and the option text
	self._OptionTextLabel.Text = self.Current or "N/A"

	return
end

function Class:Destroy():nil
	self._Maid:Sweep()
	if self._ListFrame then
		self._ListFrame:Destroy()
	end

	return
end

return Class
