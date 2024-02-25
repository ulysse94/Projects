--[[Ulysse94]]--

--[[

Constructors:
	new (elements [ {[string] = [string|table]} ], target [Frame|ScrollingFrame])

Properties:
	(READ ONLY) _Maid [Maid]
		maid.

	(READ ONLY) _Buttons [{TextButton}]

	(READ ONLY) _Collapsables [{Collaspable}]

	(READ ONLY) _UIList [UIListLayout]

	(READ ONLY) _Settings [{}]

	(READ ONLY) _Parent [Frame|ScrollingFrame]

	(READ ONLY) _ElementSelectedEvent [BindableEvent]

	(READ ONLY) Selected [string]

	(READ ONLY) Elements [ {[string] = [string|table]} ]
	
Methods:
	_Create () -> nil

	_Update () -> nil

	ChooseElement (element [string]) -> nil

	UpdateElements (elements [ {[string] = [string|table]} ]) -> nil

	Destroy () -> nil

Events:
	ElementSelected (newElement [string])
		
	
]]

local Lib = script.Parent
local CollapsableClass = require(Lib.Collapsable)
local MaidClass = require(Lib.Utilities.Maid)

local DEFAULT_SETTINGS = {
	LIST_PADDING = UDim.new(0,5),

	LIST_BUTTON_ON_TEXT_BACKGROUND_TRANSPARENCY = .5,
	LIST_BUTTON_ON_TEXT_BACKGROUND_COLOR3 = Color3.new(1,1,1),
	LIST_BUTTON_ON_TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	LIST_BUTTON_ON_TEXT_SIZE = 14,
	LIST_BUTTON_ON_TEXT_FONT = Enum.Font.Gotham,
	LIST_BUTTON_ON_TEXT_WEIGHT = Enum.FontWeight.Medium,
	LIST_BUTTON_ON_TEXT_TRUNCATE = false,
	LIST_BUTTON_ON_TEXT_WRAP = true, --multiline
	LIST_BUTTON_ON_TEXT_AUTO = false, --auto size (incompatible with truncate)
	LIST_BUTTON_ON_TEXT_RICH = false, --rich text

	LIST_BUTTON_OFF_TEXT_BACKGROUND_TRANSPARENCY = 1,
	LIST_BUTTON_OFF_TEXT_BACKGROUND_COLOR3 = Color3.new(0,0,0),
	LIST_BUTTON_OFF_TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	LIST_BUTTON_OFF_TEXT_SIZE = 14,
	LIST_BUTTON_OFF_TEXT_FONT = Enum.Font.Gotham,
	LIST_BUTTON_OFF_TEXT_WEIGHT = Enum.FontWeight.Medium,
	LIST_BUTTON_OFF_TEXT_TRUNCATE = false,
	LIST_BUTTON_OFF_TEXT_WRAP = true, --multiline
	LIST_BUTTON_OFF_TEXT_AUTO = false, --auto size (incompatible with truncate)
	LIST_BUTTON_OFF_TEXT_RICH = false, --rich text

	COLLAPSE_TWEENINFO_ON = TweenInfo.new(.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
	COLLAPSE_TWEENINFO_OFF = TweenInfo.new(.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),

	COLLAPSE_BUTTON_TEXT_BACKGROUND_TRANSPARENCY = 1,
	COLLAPSE_BUTTON_TEXT_BACKGROUND_COLOR3 = Color3.new(0,0,0),
	COLLAPSE_BUTTON_TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	COLLAPSE_BUTTON_TEXT_SIZE = 14,
	COLLAPSE_BUTTON_TEXT_FONT = Enum.Font.Gotham,
	COLLAPSE_BUTTON_TEXT_WEIGHT = Enum.FontWeight.Medium,
	COLLAPSE_BUTTON_TEXT_TRUNCATE = false,
	COLLAPSE_BUTTON_TEXT_WRAP = true, --multiline
	COLLAPSE_BUTTON_TEXT_AUTO = false, --auto size (incompatible with truncate)
	COLLAPSE_BUTTON_TEXT_RICH = false, --rich text

	BUTTON_TEXT_SYMBOL_POSITION = Enum.LeftRight.Right,
	COLLAPSE_BUTTON_TEXT_SYMBOL_OFF = "+",
	COLLAPSE_BUTTON_TEXT_SYMBOL_ON = "-",
}

local Class = {}

Class.__index = Class
Class.__type = "SummaryView"

function Class:__tostring()
	return Class.__type
end

function Class.new(elements:{[string]:string|table}, target:Frame|ScrollingFrame):{}
	local self = setmetatable({},Class)

	self._Maid = MaidClass.new()
	self._Parent = target
	self._Settings = DEFAULT_SETTINGS
	self._UIList = self._Parent:FindFirstAncestorOfClass("UIListLayout")
	self._Collapsables = {}
	self._Buttons = {}

	self.Selected = nil
	self.Elements = elements

	self._ElementSelectedEvent = Instance.new("BindableEvent")
	self.ElementSelected = self._ElementSelectedEvent.Event
	self._Maid:Mark(self._ElementSelectedEvent)

	self:_Create()

	return self
end

function Class:_Create():nil
	if not self._UIList then
		self._UIList = Instance.new("UIListLayout")
		self._Maid:Mark(self._UIList)
		self._UIList.Parent = self._Parent
	end

	local function addCollapsable(parent, text)
		local new = CollapsableClass.new(parent, text)
		table.insert(self._Collapsables, new)
		local nList = Instance.new("UIListLayout")
		nList.Parent = new.Canvas

		self._Maid:Mark(new)
		return new
	end

	local function addButton(n, parent)
		local nButton = Instance.new("TextButton")
		table.insert(self._Buttons, nButton)
		nButton.Text = n
		nButton.Name = n
		nButton.Size = UDim2.new(0,nButton.TextSize,1,0)
		
		nButton.MouseButton1Click:Connect(function()
			self:ChooseElement(n)
		end)
		self._Maid:Mark(nButton)
		nButton.Parent = parent
	end

	local function addElement(n,e, parent)
		local collapsable = addCollapsable(parent, n)
		for i, element in pairs(e) do
			if type(element) == "table" then
				--recursive, add collapsable in parent
				addElement(i, element, collapsable.Canvas)
			else
				--add button in parent
				addButton(i, collapsable.Canvas)
			end
		end
	end
	addElement("Objects", self.Elements, self._Parent)

	self:_Update()

	return nil
end

function Class:ChooseElement(elementName:string):nil
	if self.Current ~= elementName then
		self.Current = elementName
		for _, button in pairs(self._Buttons) do
			if self.Current == button.Name then
				self._Maid.LoadText(self._Settings, "LIST_BUTTON_ON", button)
				self._Maid.LoadComplements(self._Settings, "LIST_BUTTON_ON", button)
			else 
				self._Maid.LoadText(self._Settings, "LIST_BUTTON_OFF", button)
				self._Maid.LoadComplements(self._Settings, "LIST_BUTTON_OFF", button)
			end
		end
		self._ElementSelectedEvent:Fire(self.Current)
	end

	return nil
end

function Class:UpdateElements(newElements):nil
	self._Maid:Sweep()
	self.Elements = newElements
	self._Create()

	return nil
end

function Class:_Update():nil
	self._UIList.Padding = self._Settings.LIST_PADDING

	for _, collapsable in pairs(self._Collapsables) do
		local subSettings = MaidClass.FetchSettingsByPrefix(settings, "COLLAPSE")
		collapsable._Settings = subSettings
		collapsable:_Update()
		if collapsable.Canvas:FindFirstAncestorOfClass("UIListLayout") then
			collapsable.Canvas:FindFirstAncestorOfClass("UIListLayout").Padding = self._Settings.LIST_PADDING
		end
	end

	for _, button in pairs(self._Buttons) do
		if self.Current == button.Name then
			self._Maid.LoadText(self._Settings, "LIST_BUTTON_ON", button)
			self._Maid.LoadComplements(self._Settings, "LIST_BUTTON_ON", button)
		else 
			self._Maid.LoadText(self._Settings, "LIST_BUTTON_OFF", button)
			self._Maid.LoadComplements(self._Settings, "LIST_BUTTON_OFF", button)
		end
	end
end

function Class:Destroy():nil
	self._Maid:Sweep()

	return
end

return Class
