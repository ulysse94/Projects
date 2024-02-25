--[[Ulysse94]]--

--[[

TODO: Make Focus animation a NumberSequence (for now, lerping.)

Constructors:
	new (target [GuiObject], startingFocus [Vector2?], size [Vector2?], startingZoom [number?])
		Create a map frame in the target (anything that is UI).

Properties:
	(READ ONLY) _Maid [Maid]
		maid.

	_Moving [boolean]
		Is the map moving?

	(READ ONLY) _RenderStepName [string]

	(READ ONLY) _Settings [{}]

	Render [boolean]
		Wether or not the automatic RenderFrame should be called.

	CenterTarget [Vector2]

	MapSize [Vector2]

	Focus [Vector2]
		Current point that is in the middle of the map.

	Zoom [number]
		Number of pixels rendered on the X axis.

	Rotation [number]
		Same as GuiObject.Rotation

	ZoomIncrement [number]

	Sensitivity [number]

	(READ ONLY) ShowOverlay [boolean]
		Small buttons, which are for: center, zoom and unzoom.

	ClipDescendants [boolean]

	(READ ONLY) MainFrame [Frame]

	(READ ONLY) Overlay [Frame]

Methods:
	_Create () -> nil

	_Update () -> nil

	RenderFrame () -> nil
		Called automatically every frames with Render property.
		Simply adjusts the map according to the zoom, focus and rotation.

	SetFocus (newFocus [Vector2]) -> nil
		Lerping current focus to newFocus.

	SetOverlay (setVisible [boolean]) -> nil
		Sets visible the overlay.

	Destroy () -> nil

Events:
	Event ()
		
	
]]

local Lib = script.Parent.Parent
local RS = game:GetService("RunService")
local MaidClass = require(Lib.Utilities.Maid)

local Class = {}

local DEFAULT_SETTINGS = {
	SCROLL_BAR_THICKNESS = 5,
	SCROLL_BAR_COLOR3 = Color3.fromHSV(0,0,.7),

	BACKGROUND_IMAGE = "rbxassetid://0",
	BACKGROUND_IMAGE_COLOR3 = Color3.new(),
	BACKGROUND_IMAGE_TRANSPARENCY = 0,
	BACKGROUND_IMAGE_SCALE = Enum.ScaleType.Tile,
	BACKGROUND_IMAGE_TILE = UDim2.fromOffset(100,100),
	BACKGROUND_IMAGE_SLICE_CENTER = Rect.new(),
	BACKGROUND_IMAGE_SLICE_SCALE = 0,

	OVERLAY_BACKGROUND_TRANSPARENCY = .7,
	OVERLAY_BACKGROUND_COLOR3 = Color3.fromRGB(210, 210, 210),
	-- OVERLAY_CORNER = UDim.new(1,0),

	OVERLAY_UNZOOM_IMAGE = "rbxassetid://0",
	OVERLAY_UNZOOM_IMAGE_COLOR3 = Color3.new(),
	OVERLAY_UNZOOM_IMAGE_TRANSPARENCY = 0,
	OVERLAY_UNZOOM_IMAGE_SCALE = Enum.ScaleType.Stretch,
	OVERLAY_UNZOOM_IMAGE_TILE = UDim2.fromOffset(100,100),
	OVERLAY_UNZOOM_IMAGE_SLICE_CENTER = Rect.new(),
	OVERLAY_UNZOOM_IMAGE_SLICE_SCALE = 0,
	OVERLAY_UNZOOM_IMAGE_CORNER = UDim.new(1,0),
	OVERLAY_UNZOOM_IMAGE_BACKGROUND_COLOR3 = Color3.new(0,0,0),
	OVERLAY_UNZOOM_IMAGE_BACKGROUND_TRANSPARENCY = .5,

	OVERLAY_ZOOM_IMAGE = "rbxassetid://0",
	OVERLAY_ZOOM_IMAGE_COLOR3 = Color3.new(),
	OVERLAY_ZOOM_IMAGE_TRANSPARENCY = 0,
	OVERLAY_ZOOM_IMAGE_SCALE = Enum.ScaleType.Stretch,
	OVERLAY_ZOOM_IMAGE_TILE = UDim2.fromOffset(100,100),
	OVERLAY_ZOOM_IMAGE_SLICE_CENTER = Rect.new(),
	OVERLAY_ZOOM_IMAGE_SLICE_SCALE = 0,
	OVERLAY_ZOOM_IMAGE_CORNER = UDim.new(1,0),
	OVERLAY_ZOOM_IMAGE_BACKGROUND_COLOR3 = Color3.new(0,0,0),
	OVERLAY_ZOOM_IMAGE_BACKGROUND_TRANSPARENCY = .5,

	OVERLAY_CENTER_IMAGE = "rbxassetid://0",
	OVERLAY_CENTER_IMAGE_COLOR3 = Color3.new(),
	OVERLAY_CENTER_IMAGE_TRANSPARENCY = 0,
	OVERLAY_CENTER_IMAGE_SCALE = Enum.ScaleType.Stretch,
	OVERLAY_CENTER_IMAGE_TILE = UDim2.fromOffset(100,100),
	OVERLAY_CENTER_IMAGE_SLICE_CENTER = Rect.new(),
	OVERLAY_CENTER_IMAGE_SLICE_SCALE = 0,
	OVERLAY_CENTER_IMAGE_CORNER = UDim.new(1,0),
	OVERLAY_CENTER_IMAGE_BACKGROUND_COLOR3 = Color3.new(0,0,0),
	OVERLAY_CENTER_IMAGE_BACKGROUND_TRANSPARENCY = .5,
}

Class.__index = Class
Class.__type = "MapFrame"

function Class:__tostring()
	return Class.__type
end

function Class.new(target:GuiObject, startingFocus:Vector2?, size:Vector2?, zoom:number?):{}
	assert(target == nil, "No target parent set.")
	local self = setmetatable({},Class)

	self._Maid = MaidClass.new()
	self._RenderStepName = "MapUpdate_"..self._Parent.Name
	self._Settings = DEFAULT_SETTINGS
	self._Parent = target
	self._Parent.ClipsDescendants = true
	self._Moving = false

	self.Render = true
	self.CenterTarget = startingFocus or Vector2.zero
	self.MapSize = size or Vector2.new(2000,2000)

	self.Focus = self.CenterTarget
	self.Zoom = zoom or self._Parent.AbsoluteSize.X --zoom=1
	self.Rotation = 0

	self.ZoomIncrement = 15
	self.Sensitivity = 1

	self.ShowOverlay = true
	self.ClipsDescendants = true

	self.MainFrame = self._Parent:FindFirstChild("MapMain")
	self.Overlay = self._Parent:FindFirstChild("MapOverlay")

	self:_Create()

	RS:BindToRenderStep(self._RenderStepName, Enum.RenderPriority.Last, function()
		if self.Render then
			self:RenderFrame()
		end
	end)

	self._Maid:Mark(self.Overlay:FindFirstChild("UnZoomButton").MouseButton1Click:Connect(function()
		self.Zoom += self.ZoomIncrement
	end))
	self._Maid:Mark(self.Overlay:FindFirstChild("ZoomButton").MouseButton1Click:Connect(function()
		self.Zoom -= self.ZoomIncrement
	end))
	self._Maid:Mark(self.Overlay:FindFirstChild("CenterButton").MouseButton1Click:Connect(function()
		self:SetFocus(self.CenterTarget)
	end))

	self._Maid:Mark(self.MainFrame.MouseWheelBackward:Connect(function()
		self.Zoom += self.ZoomIncrement
	end))
	self._Maid:Mark(self.MainFrame.MouseWheelForward:Connect(function()
		self.Zoom -= self.ZoomIncrement
	end))

	local function applyDelta(input)
		self.Focus += input.Delta * self.Sensitivity
	end

	self._Maid:Mark(self.MainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._Moving = true
		end
	end))

	self._Maid:Mark(self.MainFrame.InputChanged:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and self._Moving then
			applyDelta(input)
		end
	end))

	self._Maid:Mark(self.MainFrame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._Moving = false
		end
	end))

	self._Maid:Mark(self._Parent.Destroying:Connect(function()
		self:Destroy()
	end))

	return self
end

function Class:_Create():nil
	if not self.MainFrame then
		self.MainFrame = Instance.new("Frame")
		self.MainFrame.Name = "MapMain"
		self.MainFrame.Size = UDim2.fromOffset(self.MapSize.X, self.MapSize.Y)

		self._Maid:Mark(self.MainFrame)

		self.MainFrame.Parent = self._Parent
	end

	if not self.MainFrame:FindFirstChildOfClass("UIScale") then
		local nRatio = Instance.new("UIScale")
		nRatio.Scale = 1

		nRatio.Parent = self.MainFrame
	end

	if not self.MainFrame:FindFirstChild("TileFrame") then
		local nImage = Instance.new("ImageLabel")
		nImage.Name = "TileFrame"
		nImage.Size = UDim2.fromScale(1,1)
		nImage.AnchorPoint = Vector2.new(.5,.5)
		nImage.Position = UDim2.fromScale(.5,.5)
		nImage.Size = UDim2.fromScale(1,1)

		self._Maid:Mark(nImage)

		nImage.Parent = self.MainFrame
	end

	if not self.Overlay then
		self.Overlay = Instance.new("Frame")
		self.Overlay.Size = UDim2.fromOffset(16,52)
		self.Overlay.Position = UDim2.new(1,-18,1,-54)
		self.Overlay.Name = "MapOverlay"
		self.Overlay.BackgroundTransparency = 1

		self._Maid:Mark(self.Overlay)

		self.Overlay.Parent = self._Parent
	end

	if not self.Overlay:FindFirstChild("UnZoomButton") then
		local nButton = Instance.new("ImageButton")
		nButton.Name = "UnZoomButton"
		nButton.Size = UDim2.fromOffset(16,16)
		nButton.Position = UDim2.fromOffset(0,0)

		self._Maid:Mark(nButton)

		nButton.Parent = self.Overlay
	end

	if not self.Overlay:FindFirstChild("ZoomButton") then
		local nButton = Instance.new("ImageButton")
		nButton.Name = "ZoomButton"
		nButton.Size = UDim2.fromOffset(16,16)
		nButton.Position = UDim2.fromOffset(0,18)

		self._Maid:Mark(nButton)

		nButton.Parent = self.Overlay
	end

	if not self.Overlay:FindFirstChild("CenterButton") then
		local nButton = Instance.new("ImageButton")
		nButton.Name = "CenterButton"
		nButton.Size = UDim2.fromOffset(16,16)
		nButton.Position = UDim2.fromOffset(0,36)

		self._Maid:Mark(nButton)

		nButton.Parent = self.Overlay
	end

	self:_Update()

	return
end

function Class:_Update():nil

	MaidClass.LoadImage(self._Settings, "BACKGROUND", self.MainFrame:FindFirstChild("TileFrame"))
	MaidClass.LoadImage(self._Settings, "OVERLAY_UNZOOM",self.Overlay:FindFirstChild("UnZoomButton"))
	MaidClass.LoadImage(self._Settings, "OVERLAY_ZOOM",self.Overlay:FindFirstChild("ZoomButton"))
	MaidClass.LoadImage(self._Settings, "OVERLAY_CENTER",self.Overlay:FindFirstChild("CenterButton"))

	self.MainFrame.CanvasSize = self.MapSize
	self.MainFrame.ClipsDescendants = self.ClipsDescendants
	self.Overlay.Visible = self.ShowOverlay

	self:RenderFrame()

	return
end

function Class:RenderFrame():nil
	--zoom is in pixels
	--meaning: the size of the MainFrame (which contains all the content)
	--will be of a size so the X size takes "zoom pixels".
	self.MainFrame:FindFirstChildOfClass("UIScale").Scale = self.Zoom/self._Parent.AbsoluteSize.X

	--offsetting original position.
	self.MainFrame.Position = UDim2.new(.5, self.Focus.X, .5, self.Focus.Y)

	--ez
	self.MainFrame.Rotation = self.Rotation

	return
end

function Class:SetOverlay(active:boolean):nil
	self.Overlay.Visible = active

	return
end

function Class:SetFocus(target:Vector2):nil
	--only animation. otherwise, set the property directly.

	for i = 1, 100, 1 do
		self.Focus:Lerp(self.Focus, i) --s m o o t h

		task.wait()
	end

	return
end

function Class:Destroy():nil
	self._Maid:Sweep()
	RS:UnbindFromRenderStep(self._RenderStepName)
	if self.MainFrame then
		for _, child in pairs(self.MainFrame:GetChildren()) do
			child:Destroy()
		end
	end

	return
end

return Class
