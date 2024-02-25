--[[Ulysse94]]--

--[[

TODO: BACKGROUND_COLOR_OFF tween.

Constructors:
	new (text [string], image [rbxassetid (string)], defaultState [boolean?], checkBox [TextButton?|Frame?], orientation [CheckBoxOrientation?], sizeMode [CheckBoxSizeMode?])
		Creates a new check box. Note that if a frame is given, it will consider the frame as the box.

Properties:
	(READ ONLY) _Maid [Maid]
		maid.

	(READ ONLY) _ToggledEvent [BindableEvent]

	(READ ONLY) _Settings [{}]
		Various settings for the creation of the UI elements.

	(READ ONLY) _Main [TextButton]
		Edit this object if you don't set checkBox in the constructor (size/pos).

	(READ ONLY) _Image [ImageLabel]

	(READ ONLY) _CheckBox [Frame]

	(READ ONLY) OnImage [rbxassetid (string)]
		Image shown when on in the check box.

	(READ ONLY) State [boolean]

	Orientation [CheckBoxOrientation]

	(READ ONLY) Text [string?]
		Text shown next to the checkbox.

	CanChangeState [boolean]
		Determines if the user can change the state of the CheckBox or not.

	CheckBoxSizeMode [CheckBoxSizeMode]

	CheckBoxSize [Vector2]
		Can be changed when CheckBoxSizeMode is "Fixed" (needs "_Update" to be called tho.)

Methods:
	_Create () -> nil
		Used to create every UI elements. Can also be used to update the checkbox after a _Settings change.

	_Update () -> nil
		Updates everything to fit the settings, alongside the size, etc.

	SetState (toggle [boolean]) -> nil

	SetImage (new [rbxassetid (string)]) -> nil

	SetText (text [string?]) -> nil

	Destroy () -> nil

Events:
	Toggled (newState [boolean])
		Fired each time the state changes.

]]

export type CheckBoxOrientation = "Left"|"Right"

export type CheckBoxSizeMode = "Fixed"|"Auto"|"Minimum"

local Lib = script.Parent
local TweenService = game:GetService("TweenService")
local MaidClass = require(Lib.Utilities.Maid)

local Class = {}

local DEFAULT_SETTINGS = {
	CHECKBOX_SIZE = NumberRange.new(16,75),
	CHECKBOX_STROKE = 3,
	CHECKBOX_STROKECOLOR = Color3.fromHSV(0,0,.4),
	CHECKBOX_CORNER = 5,
	CHECKBOX_BACKGROUND_COLOR_OFF = Color3.fromHSV(0, 0, 0.15),
	CHECKBOX_BACKGROUND_COLOR_ON = Color3.fromHSV(0, 0, 0.15),
	CHECKBOX_BACKGROUND_TRANSPARENCY = .4,

	IMAGE_COLOR = Color3.new(0,1,0),
	IMAGE_TRANSPARENCY = 0,

	TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	TEXT_SIZE = 14,
	TEXT_FONT = Enum.Font.Gotham,
	TEXT_WEIGHT = Enum.FontWeight.Medium,
	TEXT_TRUNCATE = false,
	TEXT_WRAP = true, --multiline
	TEXT_AUTO = false, --auto size (incompatible with truncate)

	TWEENINFO = TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

Class.__index = Class
Class.__type = "CheckButton"

function Class:__tostring()
	return Class.__type
end

function Class.new(text:string, image:string?,defaultState:boolean?,checkBox:(Frame?)|(TextButton?), orientation:CheckBoxOrientation?, sizeMode:CheckBoxSizeMode?):{}
	local self = setmetatable({},Class)

	self._Maid = MaidClass.new()

	self._Main = checkBox or nil
	self._CheckBox = checkBox and checkBox:FindFirstChild("CheckBox") or nil
	self._Image = checkBox:FindFirstAncestorOfClass("ImageLabel") or nil

	self.Orientation = orientation or "Left"

	self.Text = text or nil

	if checkBox then
		if checkBox:IsA("Frame") then
			self._CheckBox = checkBox
			self._Main = checkBox.Parent
		elseif checkBox:IsA("TextButton") then
			self._Main = checkBox
		end
	end

	self.State = defaultState or false
	self.CanChangeState = true
	self._Settings = DEFAULT_SETTINGS
	self.CheckBoxSizeMode = sizeMode or "Minimum"
	self.CheckBoxSize = Vector2.new()

	self.OnImage = image or "rbxassetid://9754130783"

	self:_Create()
	self:_Update() --Creates everything too, if required.

	self._Maid:Mark(self._CheckBox.MouseButton1Click:Connect(function()
		if self.CanChangeState then
			self:SetState(not self.State)
		end
	end))

	--(no need to mark, as if the button is being destroyed the connection is automatically broken.)
	self._Main.Destroying:Connect(function()
		self:Destroy()
	end)

	self._ToggledEvent = Instance.new("BindableEvent")
	self.Toggled = self._ToggledEvent.Event
	self._Maid:Mark(self._ToggledEvent)

	return self
end

function Class:_Create():nil
	if not self._Main then
		self._Main = Instance.new("TextButton")

		self._Main.Text = ""
		self._Main.BackgroundTransparency = 1
		self._Main.Size = UDim2.fromOffset(self._Settings.CHECKBOX_SIZE.Min*2,self._Settings.CHECKBOX_SIZE.Min)
		self._Main.ClipsDescendants = false

		local textLabel = Instance.new("TextLabel")
		textLabel.BackgroundTransparency = 1
		textLabel.Text = self.Text or "N/A"
		textLabel.Name = "CheckBoxLabel"
		textLabel.AnchorPoint = Vector2.new(0,.5)
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.ClipsDescendants = false

		textLabel.Parent = self._Main
		self._Maid:Mark(self._Main)
		--No parent set.
	end

	if not self._CheckBox then
		self._CheckBox = Instance.new("Frame")
		self._CheckBox.Name = "CheckBox"

		self._Maid:Mark(self._CheckBox)
		self._CheckBox.Parent = self._Main
	end

	if not self._Image then
		self._Image = Instance.new("ImageLabel")
		self._Image.BackgroundTransparency = 1
		self._Image.BorderSizePixel = 0
		self._Image.Visible = true
		self._Image.Image = self.Image
		self._Image.ScaleType = Enum.ScaleType.Fit
		self._Image.Size = UDim2.new(1,-3,1,-3)
		self._Image.AnchorPoint = Vector2.new(.5,.5)
		self._Image.Position = UDim2.fromScale(.5,.5)

		self._Maid:Mark(self._Image)
		self._Image.Parent = self._CheckBox
	end

	return
end

function Class:_Update():nil
	-- self:_Create() --For the constructor (and just in case...)

	if self._Main:FindFirstAncestorOfClass("TextLabel") then
		local textLabel = self._Main:FindFirstAncestorOfClass("TextLabel")
		-- local textSize = TextService:GetTextSize(self.Text or "N/A", self._Settings.TEXT_SIZE, self._Settings.TEXT_FONT, self._Settings.TEXT)

		MaidClass.LoadText(self._Settings, "", textLabel)
		textLabel.TextXAlignment = Enum.TextXAlignment[self.Orientation] --"Left" or "Right"
	
		textLabel.Size = UDim2.new(1,-self._CheckBox.AbsoluteSize.X, 1, 0)

		if self.Orientation == "Left" then
			textLabel.Position = UDim2.fromOffset(0,0)
		else textLabel.Position = UDim2.fromOffset(self._CheckBox.AbsoluteSize.X, 0)
		end
	end

	self._Image.ImageColor3 = self._Settings.IMAGE_COLOR
	self._Image.ImageTransparency = self._Settings.IMAGE_TRANSPARENCY

	--updating the checkbox to fit settings & size.
	local UIConstraint = self._CheckBox:FindFirstAncestorOfClass("UISizeConstraint") or Instance.new("UISizeConstraint")
	UIConstraint.MinSize = Vector2.new(self._Settings.CHECKBOX_SIZE.Min, self._Settings.CHECKBOX_SIZE.Min)
	UIConstraint.MaxSize = Vector2.new(self._Settings.CHECKBOX_SIZE.Max, self._Settings.CHECKBOX_SIZE.Max)
	UIConstraint.Parent = self._CheckBox

	self._CheckBox.BorderSizePixel = self._Settings.CHECKBOX_STROKE
	self._CheckBox.BorderMode = Enum.BorderMode.Outline
	self._CheckBox.BorderColor3 = self._Settings.CHECKBOX_STROKECOLOR

	self._CheckBox.BackgroundColor3 = self._Settings.CHECKBOX_BACKGROUND_COLOR_OFF
	self._CheckBox.BackgroundTransparency = self._Settings.CHECKBOX_BACKGROUND_TRANSPARENCY

	local UICorner = self._CheckBox:FindFirstAncestorOfClass("UICorner") or Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0,self._Settings.CHECKBOX_CORNER)
	UICorner.Parent = self._CheckBox

	if self.CheckBoxSizeMode == "Auto" then
		--Makes sure the ImageLabel is square.
		if self._Main.AbsoluteSize.Y >= self._Main.AbsoluteSize.X then
			self._CheckBox.Size = UDim2.fromOffset(self._Main.AbsoluteSize.Y,self._Main.AbsoluteSize.Y)
		else self._CheckBox.Size = UDim2.fromOffset(self._Main.AbsoluteSize.X,self._Main.AbsoluteSize.X)
		end
		self.CheckBoxSize = self._CheckBox.AbsoluteSize

	elseif self.CheckBoxSizeMode == "Minimum" then
		self._CheckBox.Size = UDim2.fromOffset(self._Settings.CHECKBOX_SIZE.Min, self._Settings.CHECKBOX_SIZE.Min)
		self.CheckBoxSize = self._CheckBox.AbsoluteSize

	elseif self.CheckBoxSizeMode == "Fixed" then
		-- sets size according to CheckBoxSize
		self._CheckBox.Size = UDim2.fromOffset(self._CheckBox.AbsoluteSize.X, self._CheckBox.AbsoluteSize.Y)
	end

	--orientation + size update
	if self.Orientation == "Left" then
		--Left
		self._CheckBox.AnchorPoint = Vector2.new(0,.5)
		self._CheckBox.Position = UDim2.fromScale(0,.5)
		-- self._CheckBox.Size = UDim2.fromScale(1,1)
	else
		--Right
		self._CheckBox.AnchorPoint = Vector2.new(1,.5)
		self._CheckBox.Position = UDim2.fromScale(1,.5)
		-- self._CheckBox.Size = UDim2.fromScale(1,1)
	end

	self._Image.Visible = true

	--Animation
	if self.State == true then
		TweenService:Create(self._Image, self._Settings.TWEENINFO, {Size = UDim2.fromScale(1,1)}):Play()
	else
		TweenService:Create(self._Image, self._Settings.TWEENINFO, {Size = UDim2.fromScale(0,0)}):Play()
	end

	return
end

function Class:SetText(text:string?):nil
	self.Text = text
	if self._Main and self._Main:FindFirstChild("CheckBoxLabel") then
		self._CheckBox:FindFirstChild("CheckBoxLabel").Text = self.Text or "N/A"
	end

	return
end

function Class:SetState(state:boolean):nil
	if self.State ~= state then
		self.State = state
		self._ToggledEvent:Fire(state)

		self:_Update()
	end

	return
end

function Class:SetImage(image:string):nil
	self._Image.Image = image

	return
end

function Class:Destroy():nil
	self._Maid:Sweep()

	return
end

return Class
