--[[Ulysse94]]--

--[[

Constructors:
	new ( target [Frame], entries [{string}], mode [RadioMode] )
		Creates a new radio list. Also creates a scrolling frame in the case the target frame isn't enough.
		Also allows 2 modes: unique (only one entry can be selected at a time) and non-unique (multiple entries can be selected).
		Returns the radio list object.

Properties (READ ONLY, preferably):
	(READ ONLY) _Maid [Maid]
		maid.

	_InternalSetSelectedEvent [BindableEvent]

	_SelectedEvent [BindableEvent]

	_DeSelectedEvent [BindableEvent]

	(READ ONLY) _Settings [{}]

	(READ ONLY) _Main [Frame]

	(READ ONLY) _Parent [Frame|ScrollingFrame]
		Sometimes the same as _Main

	(READ ONLY) Entries [{string}]

	(READ ONLY) Selected [{string}]
		All selected entries in a table.

	RadioMode [RadioMode]
		Unique or multiple.

Methods:
	_Update () -> nil

	_Create () -> nil
		Creates the UILayout element.

	SetMode (mode [RadioMode]) -> nil
		Clears the selected entries if "Unique" is chosen.

	AddEntry ( text [string] ) -> TextButton
		Adds an entry to the radio list. Returns the new button object.

	RemoveEntry ( index [number] ) -> nil
		Removes an entry from the radio list.

	SetSelected (entry [string], state [boolean?] ) -> nil
		Sets whether or not an entry is selected.

	ClearSelected () -> nil

	IsSelected (entry [string]) -> boolean
		Errors if entry isn't in Entries.

	Destroy () -> nil

Events:
	Selected (option [string])
		Fired when an entry is selected (automatically or manually)
	Deselected (option [string])
		Fired when an entry is un-selected (automatically or manually).
		(note: on "Unique" mode, Selected is fired BEFORE Deselected)

	_InternalSetSelected (option [string], toggle [boolean])


]]
export type RadioMode = "Unique"|"Multiple"

local Lib = script.Parent
local CheckButtonClass = require(Lib.CheckButton)
local TextService = game:GetService("TextService")
local MaidClass = require(Lib.Utilities.Maid)

local DEFAULT_SETTINGS = {
	--List specific
	SCROLL_BAR_THICKNESS = 5,
	SCROLL_BAR_COLOR3 = Color3.fromRGB(1,1,1),
	LIST_PADDING = 3,
	LIST_MARGIN = 6,

	--CheckBox specific
	CHECKBOX_SIZE = NumberRange.new(16,75),
	CHECKBOX_STROKE = 3,
	CHECKBOX_STROKECOLOR = Color3.fromHSV(0, 0.0, 0.4),
	CHECKBOX_CORNER = 5,
	CHECKBOX_BACKGROUND_COLOR_OFF = Color3.fromHSV(0, 0, 0.15),
	CHECKBOX_BACKGROUND_COLOR_ON = Color3.fromHSV(0, 0, 0.15),
	CHECKBOX_BACKGROUND_TRANSPARENCY = .4,

	IMAGE_COLOR = Color3.new(1,1,1),
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

local Class = {}

Class.__index = Class
Class.__type = "Radio"

function Class:__tostring()
	return Class.__type
end

--type has been defined in CheckButton.luau, Roblox LSP isn't importing exported types correctly.
---@diagnostic disable-next-line: undefined-type
function Class.new(elements:{string}?, target:Frame|ScrollingFrame, mode:RadioMode, orientation:CheckBoxOrientation?):{}
	assert(target, "Missing target Frame/ScrollingFrame.")

	local self = setmetatable({},Class)

	self._Maid = MaidClass.new()

	self._Settings = DEFAULT_SETTINGS

	self._InternalSetSelectedEvent = Instance.new("BindableEvent")
	self._InternalSetSelected = self._InternalSetSelectedEvent.Event
	self._SelectedEvent = Instance.new("BindableEvent")
	self._DeselectedEvent = Instance.new("BindableEvent")
	self._Maid:Mark(self._SelectedEvent)
	self._Maid:Mark(self._DeselectedEvent)
	self._Maid:Mark(self._InternalSetSelectedEvent)

	self._Parent = target

	if target:IsA("Frame") then
		self._Main = nil
	else self._Main = target
	end

	self.RadioMode = mode
	self.Entries = elements or {}
	self.Selected = {}
	self.Orientation = orientation

	self:_Update()


	return self
end

function Class:AddEntry(entry:string):Frame
	if not table.find(self.Entries, entry) then
		table.insert(self.Entries, entry)
	end

	if not self._Main:FindFirstChild(entry) then
		--Create checkbutton
		local nFrame = Instance.new("Frame")
		nFrame.Name = entry
		local textSizeY = TextService:GetTextSize(entry, self._Settings.TEXT_SIZE, self._Settings.TEXT_FONT, self._Main.AbsoluteCanvasSize)
		nFrame.Size = UDim2.new(1, -self._Settings.SCROLL_BAR_THICKNESS + 2, 0,
			(textSizeY > self._Settings.CHECKBOX_SIZE.Min and textSizeY or self._Settings.CHECKBOX_SIZE.Min))
		nFrame.Parent = self._Main

		local nCheck = CheckButtonClass.new(entry, nil, false, nFrame, self.Orientation)
		nCheck._Settings = self._Settings
		nCheck:_Update()

		nCheck._Maid:Mark(nCheck.Toggled:Connect(function(selected)
			if selected then
				self._SelectedEvent:Fire(entry)
				table.insert(self.Selected, entry)
			else
				self._DeselectedEvent:Fire(entry)
				table.remove(self.Selected, table.find(self.Selected, entry))
			end
		end))

		nCheck._Maid:Mark(self.Selected:Connect(function(selected)
			if selected ~= entry and self.RadioMode == "Unique" then
				--unselects.
				nCheck:SetState(false)
			end
		end))

		nCheck._Maid:Mark(self._InternalSetSelected:Connect(function(selected, newstate)
			if selected == entry then
				nCheck:SetState(newstate)
			end
		end))

		return nFrame
	else
		return self._Main:FindFirstChild(entry)
	end
end

function Class:RemoveEntry(entry:string):nil
	if table.find(self.Entries, entry) then
		table.remove(self.Entries, table.find(self.Entries, entry))
	end

	if self._Main:FindFirstChild(entry) then
		self._Main:FindFirstChild(entry):Destroy()
	end

	return
end

function Class:_Create():nil
	if not self._Main then
		self._Main = Instance.new("ScrollingFrame")

		self._Main.BackgroundTransparency = 1
		self._Main.ScrollBarThickness = 5
		self._Main.Size = UDim2.new(1,-self._Settings.LIST_MARGIN,1,-self._Settings.LIST_MARGIN)
		self._Main.Visible = true

		self._Main.ScrollingDirection = Enum.ScrollingDirection.Y
		self._Main.AutomaticCanvasSize = Enum.AutomaticSize.Y

		self._Main.ScrollBarThickness = self._Settings.SCROLL_BAR_THICKNESS
		self._Main.ScrollBarImageColor3 = self._Settings.SCROLL_BAR_COLOR3

		self._Maid:Mark(self._Main)
		self._Main.Parent = self._Parent
	end

	if not self._Main:FindFirstChildWhichIsA("UILayout") then
		local grid = Instance.new("UIListLayout")
		grid.Padding = UDim.new(0,self._Settings.LIST_PADDING)

		grid.Parent = self._Main
	end
end

function Class:_Update():nil

	for _, entry in pairs(self.Entries) do
		if not self._Main:FindFirstChild(entry) then
			self:AddEntry(entry)
		end
	end

	for _, button in pairs(self._Main:GetChildren()) do
		if button:IsA("TextButton") then
			if not table.find(self.Entries, button.Name) then
				self:RemoveEntry(button.Name)
			end
		end
	end

	return
end

function Class:IsSelected(entry:string):boolean
	assert(table.find(self.Entries, entry), "Invalid entry.")
	if table.find(self.Selected, entry) then
		return true
	else return false
	end
end

function Class:SetSelected(entry:string, toggled:boolean):nil
	if toggled and not table.find(self.Selected, entry) then
		self._InternalSetSelectedEvent:Fire(entry, toggled)
	elseif not toggled and table.find(self.Selected, entry) then
		self._InternalSetSelectedEvent:Fire(entry, toggled)
	end
end

function Class:ClearSelected():nil
	for _, entry in pairs(self.Selected) do
		self:SetSelected(entry, false)
	end
end

function Class:SetMode(mode:RadioMode):nil
	self.RadioMode = mode
	if mode == "Unique" then
		self._SelectedEvent:Fire(nil)
	end

	return nil
end

function Class:Destroy():nil
	self._Maid:Sweep()

	return
end

return Class
