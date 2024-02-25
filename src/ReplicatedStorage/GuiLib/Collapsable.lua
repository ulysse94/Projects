--[[Ulysse94]]--

--[[

Constructors:
	new (targetFrame [GuiObject?], buttonText [string], ... [Instance])

Properties:
	(READ ONLY) _Maid [Maid]
		maid.

	(READ ONLY) _ToggledEvent [BindableEvent]

	(READ ONLY) _Parent [Frame]

	(READ ONLY) _Button [TextButton]

	(READ ONLY) Canvas [Frame]
		Contains all the elements that will be shown when the collapsable is opened.
		Children can be edited.

	(READ ONLY) Opened [boolean]
		Wether the collapsable is collapsed or not.

	(READ ONLY) Text [string]
		Text shown in the text button. Note that symbols are in the settings.
 
Methods:
	_Create () -> nil

	_Update () -> nil

	Open (toggle [boolean]) -> nil

	Destroy () -> nil

Events:
	Toggled (newState [boolean])
		Fired when the collapsable is opened/closed.
	
]]

local Lib = script.Parent
local MaidClass = require(Lib.Utilities.Maid)

local DEFAULT_SETTINGS = {
	TWEENINFO_ON = TweenInfo.new(.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
	TWEENINFO_OFF = TweenInfo.new(.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),

	BUTTON_TEXT_BACKGROUND_TRANSPARENCY = 1,
	BUTTON_TEXT_BACKGROUND_COLOR3 = Color3.new(0,0,0),
	BUTTON_TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	BUTTON_TEXT_SIZE = 14,
	BUTTON_TEXT_FONT = Enum.Font.Gotham,
	BUTTON_TEXT_WEIGHT = Enum.FontWeight.Medium,
	BUTTON_TEXT_TRUNCATE = false,
	BUTTON_TEXT_WRAP = true, --multiline
	BUTTON_TEXT_AUTO = false, --auto size (incompatible with truncate)
	BUTTON_TEXT_RICH = false, --rich text

	BUTTON_TEXT_SYMBOL_POSITION = Enum.LeftRight.Right,
	BUTTON_TEXT_SYMBOL_OFF = "+", --when opened is false
	BUTTON_TEXT_SYMBOL_ON = "-", --when opened is true

	--PARENT_COMPLEMENTS = . . . --settings for the parent folder, eventually...
}

local Class = {}

Class.__index = Class
Class.__type = "Collapsable"

function Class:__tostring()
	return Class.__type
end

function Class.new(target:GuiObject?, buttonText:string, ...:Instance):{}
	local self = setmetatable({},Class)
	local childElements = {...}

	self._Maid = MaidClass.new()
	self._Settings = DEFAULT_SETTINGS

	self._Parent = target
	self._Canvas = nil
	self._Button = nil

	self.Text = buttonText
	self.Opened = false

	self._ToggledEvent = Instance.new("BindableEvent")
	self.Toggled = self._ToggledEvent.Event
	self._Maid:Mark(self._ToggledEvent)

	self._Create()

	for _, child in pairs(childElements) do
		child.Parent = self._Canvas
	end

	self._Button.MouseButton1Click(function()
		self:Open(not self.Opened)
	end)

	return self
end

function Class:Create():nil

	if not self._Button then
		self._Button = self._Parent:FindFirstChildOfClass("TextButton") or Instance.new("TextButton")

		self._Maid:Mark(self._Button)

		self._Button.Parent = self._Parent
	end

	if not self._Canvas then
		self._Canvas = self._Parent:FindFirstChildOfClass("Frame") or Instance.new("Frame")

		self._Canvas.AnchorPoint = Vector2.new(0,1)
		self._Canvas.Position = UDim2.fromScale(0,1)
		self._Canvas.Size = UDim2.fromScale(1,0)
		self._Canvas.BackgroundTransparency = 1
		self._Canvas.ClipDescendants = true
		self._Canvas.BorderSizePixel = 0

		self._Maid:Mark(self._Canvas)

		self._Canvas.Parent = self._Parent
	end

	self:_Update()

	return nil
end

function Class:Update():nil
	self._Button.Size = UDim2.new(1, 0, 0, self._Parent.AbsoluteSize.Y - self._Canvas.AbsoluteSize.Y)

	self._Maid.LoadText(self._Settings, "BUTTON", self._Button)

	self._Maid.LoadComplements(self._Settings, "PARENT", self._Parent)
end

function Class:UpdateText(newText:string?):nil
	if newText and newText ~= self.Text then
		self.Text = newText
	end

	if self._Settings.BUTTON_TEXT_SYMBOL_POSITION == Enum.LeftRight.Left then
		self._Button.Text = (if self.Opened == true then self._Settings.BUTTON_TEXT_SYMBOL_ON else self._Settings.BUTTON_TEXT_SYMBOL_OFF)..self.Text
	else 
		self._Button.Text = self.Text..(if self.Opened == true then self._Settings.BUTTON_TEXT_SYMBOL_ON else self._Settings.BUTTON_TEXT_SYMBOL_OFF)
	end

	return nil
end

function Class:Open(toggle:boolean):nil
	if self.Opened ~= toggle then
		if toggle == true then
			self._Parent:TweenSize(UDim2.new(1,0,0,self._Canvas.AbsoluteContentSize.Y+self._Button.AbsoluteSize.Y), 
			self._Settings.TWEENINFO_ON.EasingDirection, self._Settings.TWEENINFO_ON.EasingStyle, self._Settings.TWEENINFO_ON.Time)
			self._Canvas:TweenSize(UDim2.new(1,0,0,self._Canvas.AbsoluteContentSize.Y),
			self._Settings.TWEENINFO_ON.EasingDirection, self._Settings.TWEENINFO_ON.EasingStyle, self._Settings.TWEENINFO_ON.Time)
		elseif toggle == false then
			self._Parent:TweenSize(UDim2.new(1,0,0,self._Button.AbsoluteSize.Y),
			self._Settings.TWEENINFO_OFF.EasingDirection, self._Settings.TWEENINFO_OFF.EasingStyle, self._Settings.TWEENINFO_OFF.Time)
			self._Canvas:TweenSize(UDim2.new(1,0,0,0),
			self._Settings.TWEENINFO_OFF.EasingDirection, self._Settings.TWEENINFO_OFF.EasingStyle, self._Settings.TWEENINFO_OFF.Time)
		end

		self.Opened = toggle
		self._ToggledEvent:Fire(toggle)
	end

	return nil
end

function Class:Destroy():nil
	self._Maid:Sweep()

	return
end

return Class
