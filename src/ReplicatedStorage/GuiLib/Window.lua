--[[Ulysse94]]--

--[[

TODO: documentation + debugging

Constructors:
	new (parent [Instance], baseSize [UDim2], canClose [boolean?], canMove [boolean?], canMinimize [boolean?], canResize [boolean?])
        Creates a new window.

Properties:
	

Methods:
	Move(acceleration [Vector2]) -> nil
        Moves the window. Used internally when the window is selected.

Events:
	None
]]

local DEFAULT_SETTINGS = {
    --For the topbar, symbols and size:
	TOPBAR_BACKGROUND_COLOR3 = Color3.fromRGB(30, 30, 30),
	TOPBAR_BACKGROUND_TRANSPARENCY = .4,
	TOPBAR_PADDING = UDim.new(0,2),
	TOPBAR_SIZE_Y = UDim.new(0,25),
	TOPBAR_BUTTON_SIZE_X = UDim.new(0,18),

	TOPBAR_MINIMIZE_TEXT_BACKGROUND_COLOR3 = Color3.fromRGB(30, 30, 30),
	TOPBAR_MINIMIZE_TEXT_BACKGROUND_TRANSPARENCY = .4,
	TOPBAR_MINIMIZE_TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	TOPBAR_MINIMIZE_TEXT_SIZE = 12,
	TOPBAR_MINIMIZE_TEXT_FONT = Enum.Font.SourceSans,
	TOPBAR_MINIMIZE_TEXT_WEIGHT = Enum.FontWeight.Medium,
	TOPBAR_MINIMIZE_TEXT = "-",

	TOPBAR_EXTEND_TEXT_BACKGROUND_COLOR3 = Color3.fromRGB(30, 30, 30),
	TOPBAR_EXTEND_TEXT_BACKGROUND_TRANSPARENCY = .4,
	TOPBAR_EXTEND_TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	TOPBAR_EXTEND_TEXT_SIZE = 12,
	TOPBAR_EXTEND_TEXT_FONT = Enum.Font.SourceSans,
	TOPBAR_EXTEND_TEXT_WEIGHT = Enum.FontWeight.Medium,
	TOPBAR_EXTEND_TEXT = "+",

	TOPBAR_CLOSE_TEXT_BACKGROUND_COLOR3 = Color3.fromRGB(30, 30, 30),
	TOPBAR_CLOSE_TEXT_BACKGROUND_TRANSPARENCY = .4,
	TOPBAR_CLOSE_TEXT_COLOR3 = Color3.fromRGB(255, 0, 0),
	TOPBAR_CLOSE_TEXT_SIZE = 12,
	TOPBAR_CLOSE_TEXT_FONT = Enum.Font.SourceSans,
	TOPBAR_CLOSE_TEXT_WEIGHT = Enum.FontWeight.Medium,
	TOPBAR_CLOSE_TEXT = "x",

	-- not acutally in the topbar
	TOPBAR_RESIZE_TEXT_BACKGROUND_COLOR3 = Color3.fromRGB(30, 30, 30),
	TOPBAR_RESIZE_TEXT_BACKGROUND_TRANSPARENCY = .4,
	TOPBAR_RESIZE_TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	TOPBAR_RESIZE_TEXT_SIZE = 12,
	TOPBAR_RESIZE_TEXT_FONT = Enum.Font.SourceSans,
	TOPBAR_RESIZE_TEXT_WEIGHT = Enum.FontWeight.Medium,
	TOPBAR_RESIZE_SIZE = UDim2.fromOffset(15,15),
	TOPBAR_RESIZE_TEXT = "x",

    --For the container (ScrollingFrame):
    CONTAINER_BACKGROUND_COLOR3 = Color3.fromRGB(30, 30, 30),
	CONTAINER_BACKGROUND_TRANSPARENCY = .4,
	CONTAINER_SCROLLBAR_SIZE = 5,

	--For the background/main frame.
	MAIN_BACKGROUND_COLOR3 = Color3.fromRGB(30, 30, 30),
	MAIN_BACKGROUND_TRANSPARENCY = .4,
}

local Lib = script.Parent

local Class = {}

Class.__index = Class
Class.__type = "Window"

function Class:__tostring()
	return Class.__type
end

function Class.new(parent:GuiObject, baseSize:UDim2, name:string?, canClose:boolean?, canMinimize:boolean?, canMove:boolean?, canResize:boolean?):{}
	local self = setmetatable({},Class)

	self._Maid = require(Lib.Utilities.Maid).new()

	self._Parent = parent
	self._Settings = DEFAULT_SETTINGS

	self.CurrentSize = baseSize
	self.CanClose = canClose or true
	self.CanMinimize = canMinimize or true
	self.CanMove = canMove or true
	self.CanResize = canResize or true

	self.Minimized = false
	self.Closed = false

	self.Name = name or "WindowFrame"

	self:_Create()

	self._Maid:Mark(self._CloseButton.MouseButton1Click:Connect(function()
		self:Close(true) -- considering the frame can only be visible to be closed.
	end))

	self._Maid:Mark(self._MinimizeButton.MouseButton1Click:Connect(function()
		self:Minimize()
	end))

	self._Maid:Mark(self._ResizeButton.MouseButton1Down:Connect(function(x,y)
		
	end))

	self._Maid:Mark(self._TopBar.MouseButton1Down)

	return self
end

function Class:_Create():nil
	--/!\ For _Topbar, make sure the names of the buttons respect alphabetical order (because of UIListLayout).

	if not self._Main then
		self._Main = Instance.new("Frame")
		self._Main.Name = self.Name
		self._Main.Size = self.CurrentSize
		self._Main.Parent = self._Parent
		self._Main.Active = true
		self._Main.

		self._Maid:Mark(self._Main)
	end

	if not self._TopBar then
		self._TopBar = Instance.new("TextButton")
		self._TopBar.Name = "TopBar"
		self._TopBar.Parent = self._Main

		self._Maid:Mark(self._TopBar)
	end

	if not self._TopBar:FindFirstChildOfClass("UIListLayout") then
		local n = Instance.new("UIListLayout")
		n.FillDirection = Enum.FillDirection.Horizontal
		n.HorizontalAlignment = Enum.HorizontalAlignment.Right
		n.HorizontalFlex = Enum.UIFlexAlignment.None
		n.SortOrder = Enum.SortOrder.Name
		n.ItemLineAlignment = Enum.ItemLineAlignment.Start
		n.Wraps = false
		n.Parent = self._TopBar

		self._Maid:Mark(n)
	end

	if not self.Container then
		self.Container = Instance.new("ScrollingFrame")
		self.Container = "MainContainer"
		self.Container.ScrollingDirection = Enum.ScrollingDirection.XY
		self.Container.Parent = self._Main

		self._Maid:Mark(self.Container)
	end

	if not self._MinimizeButton then
		self._MinimizeButton = Instance.new("TextButton")
		self._MinimizeButton.Name = "Minimize_Extend"
		self._MinimizeButton.Parent = self._TopBar

		self._Maid:Mark(self._MinimizeButton)
	end

	if not self._CloseButton then
		self._CloseButton = Instance.new("TextButton")
		self._CloseButton.Name = "Close"
		self._CloseButton.Parent = self._TopBar

		self._Maid:Mark(self._CloseButton)
	end

	if not self._ResizeButton then
		self._ResizeButton = Instance.new("TextButton")
		self._ResizeButton.Name = "Resize"
		self._ResizeButton.Parent = self._Main
		self._ResizeButton.AnchorPoint = Vector2.new(1,1)
		self._ResizeButton.Position = UDim2.fromScale(1,1)

		self._Maid:Mark(self._ResizeButton)
	end

	if not self._WindowName then
		self._ResizeButton = Instance.new("TextLabel")
		self._ResizeButton.Name = "WindowName"
		self._ResizeButton.Parent = self._TopBar

		self._Maid:Mark(self._ResizeButton)
	end

	if not self._Main:FindFirstAncestorOfClass("UIDragDetector") then
		local n = Instance.new("UIDragDetector")

		n.DragStyle = Enum.UIDragDetectorDragStyle.TranslatePlane
		n.DragRelativity = Enum.UIDragDetectorDragRelativity.Absolute
		n.ResponseStyle = Enum.UIDragDetectorResponseStyle.Offset

		n.Parent = self._TopBar
	end

	self:_Update()

	return
end

function Class:_Update():nil
	self._Main.BackgroundColor3 = self._Settings.MAIN_BACKGROUND_COLOR3
	self._Main.BackgroundTransparency = self._Settings.MAIN_BACKGROUND_TRANSPARENCY
	self._Maid.LoadComplements(self._Settings, "MAIN", self._Main)

	self._TopBar.Size = UDim2.new(UDim.new(1,0),self._Settings.TOPBAR_SIZE_Y)
	self._TopBar.BackgroundColor3 = self._Settings.TOPBAR_BACKGROUND_COLOR3
	self._TopBar.BackgroundTransparency = self._Settings.TOPBAR_BACKGROUND_TRANSPARENCY
	self._TopBar.Text = ""
	self._TopBar.AutoButtonColor = false
	self._Maid.LoadComplements(self._Settings, "TOPBAR", self._TopBar)

	self.Container.BackgroundTransparency = 1
	self.Container.Size = UDim2.new(UDim.new(1,0),UDim.new(1-self._Settings.TOPBAR_SIZE_Y.Scale,1-self._Settings.TOPBAR_SIZE_Y.Offset)) -- not sure you can substract UDim
	self._Maid.LoadComplements(self.Container, "CONTAINER", self.Container)
	self.Container.ScrollBarThickness = self._Settings.CONTAINER_SCROLLBAR_SIZE

	self._TopBar:FindFirstChildOfClass("UIListLayout").Padding = self._Settings.TOPBAR_PADDING

	self._MinimizeButton.Size = UDim2.new(self._Settings.TOPBAR_BUTTON_SIZE_X,UDim.new(1,0))
	self._CloseButton.Size = UDim2.new(self._Settings.TOPBAR_BUTTON_SIZE_X,UDim.new(1,0))

	self._Maid.LoadText(self._Settings, "TOPBAR_CLOSE", self._CloseButton)

	-- Loads the minimize button
	self:Minimize(self.Minimized)

	self._Maid.LoadText(self._Settings, "TOPBAR_RESIZE", self._ResizeButton)
	self._ResizeButton.Size = self._Settings.TOPBAR_RESIZE_SIZE
	self._ResizeButton.Position = UDim2.fromScale(1,1)
	self._ResizeButton.AnchorPoint = Vector2.one

	return
end

function Class:SetCan(canMinimize:boolean?, canClose:boolean?, canMove:boolean?, canResize:boolean?):nil
	self.CanMinimize = (if canMinimize ~= nil then canMinimize else self.CanMinimize)
	self.CanClose = (if canClose ~= nil then canClose else self.CanClose)
	self.CanMove = (canMove ~= nil and canMove or self.CanMove)
	self.CanResize = (canMinimize ~= nil and canResize or self.CanResize)

	return
end

function Class:Close(toggle:boolean):nil
	if toggle == nil then
		self.Closed = not self.Minimized
	else self.Closed = toggle
	end

	if self.Closed == true then
		self._Main.Visible = false
		self._Main.Active = false
	elseif self.Closed == false then
		self._Main.Visible = true
		self._Main.Active = true
	end

	return
end

function Class:Move(acceleration:UDim2):nil
	self._Main.Position += acceleration

	return
end

function Class:Resize(acceleration:UDim2):nil
	self.CurrentSize += acceleration
	self._Main.Size = self.CurrentSize

	return
end

function Class:Minimize(toggle:boolean?):nil
	if toggle == nil then
		self.Minimized = not self.Minimized
	else self.Minimized = toggle
	end

	if self.Minimized == true then
		self._Maid.LoadText(self._Settings, "TOPBAR_EXTEND", self._MinimizeButton)
		self._MinimizeButton.Text = self._Settings.TOPBAR_EXTEND_TEXT
		self.Container.Size = UDim2.new(1,0,0,0)
		self._Main.Size = UDim2.new(self._Main.Size.X, self._Settings.TOPBAR_SIZE_Y)
	elseif self.Minimized == false then
		self._Maid.LoadText(self._Settings, "TOPBAR_MINIMIZE", self._MinimizeButton)
		self._MinimizeButton.Text = self._Settings.TOPBAR_MINIMIZE_TEXT
		self.Container.Size = UDim2.new(UDim.new(1,0),UDim.new(1-self._Settings.TOPBAR_SIZE_Y.Scale,1-self._Settings.TOPBAR_SIZE_Y.Offset)) -- not sure you can substract UDim
		self._Main.Size = self.CurrentSize
	end

	return
end

function Class:Destroy():nil
	self._Maid:Sweep()

	return
end

return Class