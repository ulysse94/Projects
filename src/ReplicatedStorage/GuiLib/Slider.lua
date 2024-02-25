--[[Ulysse94]]--

--[[

Constructors:
	new (range [NumberRange], target [Frame], inputLabel [TextBox?|TextLabel?], defaultNumber [number?], increment [number?])
		Creates a new slider in a target frame. Note taht the target frame must be horizontal (can be rotated, but X represents the progress on the slider).

Properties:
	(READ ONLY) _Maid [Maid]
		maid.
	
	(READ ONLY) _InputLabelMaid [Maid]

	(READ ONLY) _ChangedEvent [BindableEvent]

	(READ ONLY) _Parent [Frame]

	(READ ONLY) _Settings [{}]

	(READ ONLY) _Active [boolean]
		Wether or not the slider is being used.

	(READ ONLY) Current [number]
		Current value. Use SetValue to edit.

	(READ ONLY) Bar [Frame]

	(READ ONLY) Socket [ImageButton]

	CanSlide [boolean]

	ProgressBar [boolean]
		Show progress bar or not (might need to call _Update afterwards)

	Range [NumberRange]
		When changed, **it will not change the current value, that may be off-limit**, but you can try Slider:SetValue(Slider.Current)

	Increment [number]
		Increment used when Mouse (scroll or pointer) is used on the slider bar. Ignores manual text input.

Methods:
	_Create () -> nil
		(calls _Update too)

	_Update () -> nil

	SetValue (new [number]) -> nil
		Set the current value.

	SetInputLabel (inputLabel [TextLabel?|TextBox?]) -> nil

	Destroy () -> nil

Events:
	Changed (new [number])
		Fired each time a new value is set.
]]


local Lib = script.Parent
local MaidClass = require(Lib.Utilities.Maid)

local UIS = game:GetService("UserInputService")

local TextMaskerClass = require(Lib.TextMasker)

local DEFAULT_SETTINGS = {
	BAR_SIZE_Y = UDim.new(0,5),
	BAR_ROUND = UDim.new(0,0), -- see UICorner
	BAR_BACKGROUND_COLOR3 = Color3.fromRGB(179, 99, 99),
	BAR_BACKGROUND_TRANSPARENCY = .8,
	BAR_BORDER_SIZE = 2, --in px
	BAR_BORDER_COLOR3 = Color3.fromRGB(117, 65, 65),

	BAR_IMAGE = "rbxassetid://0",
	BAR_IMAGE_COLOR3 = Color3.new(),
	BAR_IMAGE_TRANSPARENCY = 0,
	BAR_IMAGE_SCALE = Enum.ScaleType.Stretch,
	BAR_IMAGE_TILE = UDim2.new(),
	BAR_IMAGE_SLICE_CENTER = Rect.new(),
	BAR_IMAGE_SLICE_SCALE = 0,

	SOCKET_SIZE = UDim2.fromOffset(15,15),

	SOCKET_IMAGE = "rbxassetid://0", --rbxassetid://
	SOCKET_IMAGE_COLOR3 = Color3.new(),
	SOCKET_IMAGE_TRANSPARENCY = 0,
	SOCKET_IMAGE_SCALE = Enum.ScaleType.Stretch,
	SOCKET_IMAGE_TILE = UDim2.new(),
	SOCKET_IMAGE_SLICE_CENTER = Rect.new(),
	SOCKET_IMAGE_SLICE_SCALE = 0,

	PROGRESS_IMAGE = "rbxassetid://0",
	PROGRESS_IMAGE_COLOR3 = Color3.new(),
	PROGRESS_IMAGE_TRANSPARENCY = 0,
	PROGRESS_IMAGE_SCALE = Enum.ScaleType.Stretch,
	PROGRESS_IMAGE_TILE = UDim2.new(),
	PROGRESS_IMAGE_SLICE_CENTER = Rect.new(),
	PROGRESS_IMAGE_SLICE_SCALE = 0,

	INPUT_TYPE = {Enum.UserInputType.Touch, Enum.UserInputType.MouseButton1}
}

local Class = {}

Class.__index = Class
Class.__type = "Slider"

function Class:__tostring()
	return Class.__type
end

function Class.new(range:NumberRange, target:Frame, inputLabel:(TextBox?)|(TextLabel?), default:number?, increment:number?):{}
	local self = setmetatable({},Class)

	self._Maid = MaidClass.new()
	self._InputLabelMaid = MaidClass.new()

	self._Settings = DEFAULT_SETTINGS

	self._Active = false

	self.Range = range
	self.Current = default or range.Min

	self.CanSlide = true
	self.ProgressBar = true

	self.Increment = increment or 1
	self.Bar = target:FindFirstChild("SliderBar") or nil
	self.Socket = target:FindFirstChild("SliderSocket")

	self._ChangedEvent = Instance.new("BindableEvent")
	self.Changed = self._ChangedEvent.Event
	self._Maid:Mark(self._ChangedEvent)

	self:_Create()

	self:SetInputLabel(inputLabel)

	local function onInput(action:InputObject) --Input ended is detected after, not here.
		if table.find(self._Settings.INPUT_TYPE, action.UserInputType) and self.CanSlide == true then
			if action.UserInputState == Enum.UserInputState.Begin then
				self._Active = true
			elseif action.UserInputState == Enum.UserInputState.Change then
				local sliderRot = self._Parent.AbsoluteRotation --absolute rotation range: 0 - 360
				--using a trigonometry (circle), we can get the vector in which the slider is pointing.
				local sliderVector = Vector2.new(math.cos(sliderRot), math.sin(sliderRot))
				local mouseDelta = Vector2.new(action.Delta.X, action.Delta.Y) --Z is for scrolling and gamepad trigger.
				--now, to know for how much the mouse "slided" the dot, i have to make the projection of mouseDelta on pointDir
				--formula: proj_sliderVector(mouseDelta) = mouseDetla * Angle(sliderVector,mouseDelta)
				--with Angle(sliderVector,mouseDelta) = arrcos(sliderVector . mouseDelta / (|sliderVector| * |mouseDelta|))
				local valueChange = mouseDelta * math.acos(sliderVector:Dot(mouseDelta) / (sliderVector.Magnitude * mouseDelta.Magnitude))

				self:SetValue(self.Current + valueChange)
			end
		end
	end

	self._Maid:Mark(self.Socket.InputBegan:Connect(onInput))

	self._Maid:Mark(UIS.InputEnded:Connect(function(action--[[,processed]]) --ignore if it's processed or not. i just want to know if focus is released.
		if self._Active == true and table.find(self._Settings.INPUT_TYPE, action.UserInputType) then
			self._Active = false
			--rounding to increment
			self:SetValue(self.Current - self.Current % self.Increment)
		end
	end))

	self._Maid:Mark(self.Bar.MouseWheelForward:Connect(function()
		if self.CanSlide == true then
			self:SetValue(self.Current + self.Increment)
		end
	end))

	self._Maid:Mark(self.Bar.MouseWheelBackward:Connect(function()
		if self.CanSlide == true then
			self:SetValue(self.Current - self.Increment)
		end
	end))

	self._Parent = target

	self._Parent.Destroying:Connect(function()
		self:Destroy()
	end)

	return self
end

function Class:_Create():nil
	if not self.Bar then
		self.Bar = Instance.new("Frame")
		self.Bar.Name = "SliderBar"
		self._Maid:Mark(self.Bar)
		self.Bar.Parent = self._Parent
	end

	if not self.Bar:FindFirstAncestorOfClass("UICorner") then
		local corner = Instance.new("UICorner")
		corner.Parent = self.Bar
	end

	if not self.Bar:FindFirstChild("BackgroundImage") then
		local image = Instance.new("ImageLabel")
		image.Name = "BackgroundImage"
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(1,1)
		image.Parent = self.Bar
	end

	if not self.Bar:FindFirstChild("ProgressImage") then
		local image = Instance.new("ImageLabel")
		image.Name = "ProgressImage"
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(0,1)
		image.Parent = self.Bar
	end

	if not self.Socket then
		self.Socket = Instance.new("ImageButton")
		self.Bar.Name = "SliderSocket"
		self._Maid:Mark(self.Socket)
		self.Socket.Parent = self._Parent
	end

	self:_Update()

	return
end

function Class:_Update():nil
	self.Bar.Size = UDim2.new(UDim.new(1,0), self._Settings.BAR_SIZE_Y)
	

	self.Bar.BackgroundColor3 = self._Settings.BAR_BACKGROUND_COLOR3
	self.Bar.BackgroundTransparency = self._Settings.BAR_BACKGROUND_TRANSPARENCY

	self.Bar.BorderSizePixel = self._Settings.BAR_BORDER_SIZE
	self.Bar.BorderColor3 = self._Settings.BAR_BORDER_COLOR3

	self.Bar:FindFirstAncestorOfClass("UICorner").CornerRadius = self._Settings.BAR_ROUND

	local backImage = self.Bar:FindFirstChild("BackgroundImage")
	MaidClass.LoadImage(self._Settings, "BAR", backImage)

	local progressImage = self.Bar:FindFirstChild("ProgressImage")

	MaidClass.LoadImage(self._Settings, "PROGRESS", progressImage)

	self.Socket.Size = self._Settings.SOCKET_SIZE

	MaidClass.LoadImage(self._Settings, "SOCKET", self.Socket)
	

	-- local barSize = self.Bar.AbsoluteSize - self.Socket.AbsoluteSize
	local absoluteRange = self.Range.Max - self.Range.Min
	local absoluteCurrent = self.Current - self.Range.Min
	self.Socket.Position = UDim2.new(absoluteCurrent / absoluteRange, 0, .5, 0)

	progressImage.Visible = self.ProgressBar
	self.ProgressBar.Size = UDim2.new(absoluteCurrent / absoluteRange, 0, 1, 0)

	return
end

function Class:SetInputLabel(textBox:(TextBox?)|(TextLabel?)):nil
	self._InputLabelMaid:Sweep()

	self.InputLabel = textBox
---@diagnostic disable-next-line invalid-type-name
	if typeof(textBox) == "TextBox" then
		self._TextMasker = TextMaskerClass.new(TextMaskerClass.numbers, self.InputLabel, "Whitelist")
		self._InputLabelMaid:Mark(self._TextMasker)

		self._InputLabelMaid:Mark(self._TextMasker.Unfiltered:Connect(function(new)
			if self.CanSlide == true then
				if new == "" then
					self:SetValue(self.Range.Min)
				else
					self:SetValue(new)
				end
			else
				self.InputLabel.Text = self.Current
			end
		end))
	end

	self._InputLabelMaid:Mark(self.Changed:Connect(function(new)
		self.InputLabel.Text = new
	end))

	return
end

function Class:SetValue(new:number):nil
	local new = tonumber(new)
	if new then
		if self.Range.Min > new then
			new = self.Range.Min
		elseif self.Range.Max < new then
			new = self.Range.Max
		end

		if new ~= self.Current then
			self._ChangedEvent:Fire(self.Current)
		end

		self.Current = new

		self:_Update()
	end

	return
end

function Class:Destroy():nil
	self._Maid:Sweep()
	self._InputLabelMaid:Sweep()

	return
end

return Class