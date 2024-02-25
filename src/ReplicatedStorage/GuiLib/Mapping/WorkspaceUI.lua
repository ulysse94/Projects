--[[Ulysse94]]--

--[[

This object uses intensively DragDetectors and loops (and is probably not optimized... but still cool).

Constructors:
	new (buildWorkspace:DataModel|Model)
		buildWorkspace is self-explanatory.
		Please note that THIS OBJECT ONLY HANDLES THE USER INTERACTIONS.

Properties:
	(READ ONLY) _Maid [Maid]
		maid.
	
Methods:
	Destroy () -> nil

Events:
	Event ()
]]

local Lib = script.Parent.Parent
local MaidClass = require(Lib.Utilities.Maid)
local SummaryViewClass = require(Lib.SummaryView)
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local RENDER_PRIORITY = Enum.RenderPriority.Camera.Value + 10

local DEFAULT_SETTINGS = {
	SELECT_HIGHTLIGHT_OUTLINE_COLOR3_OFF = Color3.fromRGB(13, 105, 172),
	SELECT_HIGHTLIGHT_OUTLINE_TRANSPARENCY_OFF = 0,
	SELECT_HIGHTLIGHT_FILL_COLOR3_OFF = Color3.fromRGB(237, 237, 245),
	SELECT_HIGHTLIGHT_FILL_TRANSPARENCY_OFF = .5,

	SELECT_HIGHTLIGHT_OUTLINE_COLOR3_ON = Color3.fromRGB(13, 105, 172),
	SELECT_HIGHTLIGHT_OUTLINE_TRANSPARENCY_ON = 0,
	SELECT_HIGHTLIGHT_FILL_COLOR3_ON = Color3.fromRGB(237, 237, 245),
	SELECT_HIGHTLIGHT_FILL_TRANSPARENCY_ON = .5,

	OTHER_HIGHTLIGHT_OUTLINE_COLOR3 = Color3.fromRGB(79, 98, 110),
	OTHER_HIGHTLIGHT_OUTLINE_TRANSPARENCY = 0,
	OTHER_HIGHTLIGHT_FILL_COLOR3 = Color3.fromRGB(237, 237, 245),
	OTHER_HIGHTLIGHT_FILL_TRANSPARENCY = 1,
	

	HANDLE_MOVE_COLOR3 = Color3.fromRGB(172, 117, 22),
	HANDLE_MOVE_TRANSPARENCY = 0,
	HANDLE_RESIZE_TRANSPARENCY = 0,
	HANDLE_RESIZE_COLOR3 = Color3.fromRGB(13, 105, 172),
	HANDLE_ROTATE_TRANSPARENCY = 0,
	HANDLE_ROTATE_COLOR3 = Color3.fromRGB(16, 172, 21),

	--SummaryView settings... very long.
	TOOLBOX_FRAME_SIZE = UDim2.new(),
	TOOLBOX_FRAME_POSITION = UDim2.new(),
	--TOOLBOX_FRAME can bear complements.

	TOOLBOX_LIST_PADDING = UDim.new(0,5),

	TOOLBOX_LIST_BUTTON_ON_TEXT_BACKGROUND_TRANSPARENCY = .5,
	TOOLBOX_LIST_BUTTON_ON_TEXT_BACKGROUND_COLOR3 = Color3.new(1,1,1),
	TOOLBOX_LIST_BUTTON_ON_TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	TOOLBOX_LIST_BUTTON_ON_TEXT_SIZE = 14,
	TOOLBOX_LIST_BUTTON_ON_TEXT_FONT = Enum.Font.Gotham,
	TOOLBOX_LIST_BUTTON_ON_TEXT_WEIGHT = Enum.FontWeight.Medium,
	TOOLBOX_LIST_BUTTON_ON_TEXT_TRUNCATE = false,
	TOOLBOX_LIST_BUTTON_ON_TEXT_WRAP = true, --multiline
	TOOLBOX_LIST_BUTTON_ON_TEXT_AUTO = false, --auto size (incompatible with truncate)
	TOOLBOX_LIST_BUTTON_ON_TEXT_RICH = false, --rich text

	TOOLBOX_LIST_BUTTON_OFF_TEXT_BACKGROUND_TRANSPARENCY = 1,
	TOOLBOX_LIST_BUTTON_OFF_TEXT_BACKGROUND_COLOR3 = Color3.new(0,0,0),
	TOOLBOX_LIST_BUTTON_OFF_TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	TOOLBOX_LIST_BUTTON_OFF_TEXT_SIZE = 14,
	TOOLBOX_LIST_BUTTON_OFF_TEXT_FONT = Enum.Font.Gotham,
	TOOLBOX_LIST_BUTTON_OFF_TEXT_WEIGHT = Enum.FontWeight.Medium,
	TOOLBOX_LIST_BUTTON_OFF_TEXT_TRUNCATE = false,
	TOOLBOX_LIST_BUTTON_OFF_TEXT_WRAP = true, --multiline
	TOOLBOX_LIST_BUTTON_OFF_TEXT_AUTO = false, --auto size (incompatible with truncate)
	TOOLBOX_LIST_BUTTON_OFF_TEXT_RICH = false, --rich text

	TOOLBOX_COLLAPSE_TWEENINFO_ON = TweenInfo.new(.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
	TOOLBOX_COLLAPSE_TWEENINFO_OFF = TweenInfo.new(.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),

	TOOLBOX_COLLAPSE_BUTTON_TEXT_BACKGROUND_TRANSPARENCY = 1,
	TOOLBOX_COLLAPSE_BUTTON_TEXT_BACKGROUND_COLOR3 = Color3.new(0,0,0),
	TOOLBOX_COLLAPSE_BUTTON_TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	TOOLBOX_COLLAPSE_BUTTON_TEXT_SIZE = 14,
	TOOLBOX_COLLAPSE_BUTTON_TEXT_FONT = Enum.Font.Gotham,
	TOOLBOX_COLLAPSE_BUTTON_TEXT_WEIGHT = Enum.FontWeight.Medium,
	TOOLBOX_COLLAPSE_BUTTON_TEXT_TRUNCATE = false,
	TOOLBOX_COLLAPSE_BUTTON_TEXT_WRAP = true, --multiline
	TOOLBOX_COLLAPSE_BUTTON_TEXT_AUTO = false, --auto size (incompatible with truncate)
	TOOLBOX_COLLAPSE_BUTTON_TEXT_RICH = false, --rich text

	TOOLBOX_BUTTON_TEXT_SYMBOL_POSITION = Enum.LeftRight.Right,
	TOOLBOX_COLLAPSE_BUTTON_TEXT_SYMBOL_OFF = "+",
	TOOLBOX_COLLAPSE_BUTTON_TEXT_SYMBOL_ON = "-",
}

local Class = {}

Class.__index = Class
Class.__type = "WorkspaceUI"

function Class:__tostring()
	return Class.__type
end

function Class.new(buildWorkspace:DataModel, toolboxTree:{[string]:{[string]:{{}}}}):{}
	local self = setmetatable({},Class)

	self._Maid = MaidClass.new()
	self._Camera = workspace.CurrentCamera

	self._Hightlight = nil
	self._SummaryViewFrame = nil
	self._SummaryView = nil

	self._Settings = DEFAULT_SETTINGS

	self.Workspace = buildWorkspace
	self.WorkspaceEvent = self.Workspace:WaitForChild("ClientEvents"):WaitForChild("Building")

	self.Selection = {} --if empty or has 1 element, select element and goodbye
	self._SelectionHighlighters = {} --contains temporary ClickDetector and Highlight (Select mode)
	self.Selected = nil
	self._Hovered = nil

	--self.Plan = nil --if on 2D plan, not 3D, and no dragging

	--[[
		allowed inputs for each actions

		SELECT
		Select: input used when a model is hovered.

		EDIT
		Rotate_L/R: used when rotating on the Y axis (flat one)

		EDIT / DRAG
		Finish: used alongside the little button to confirm action
		Cancel: opposite of finish, used to cancel action

		DRAG
		Move: used when dragging
	]]
	self.Inputs = { 
		["Select"] = {
			[Enum.UserInputType.MouseButton1] = function(state, input)
				--select
				if state == Enum.UserInputState.End then
					if self._Hovered then
						self:Select(self._Hovered)
					end
				end
			end,
		},
		["Edit"] = {
			[Enum.KeyCode.F] = function(state, input)
				--Finish

			end,
			[Enum.KeyCode.Q] = function(state, input)
				--Rotate L

			end,
			[Enum.KeyCode.E] = function(state, input)
				--Rotate R

			end,
		},
		["Drag"] = {
			[Enum.KeyCode.F] = function(state, input)
				--Finish
				
			end,
			[Enum.UserInputType.MouseMovement] = function(state, input)
				--Drag
				if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
					
				end
			end,
		},
	}

	self.Mode = "Toolbox"
	--[[
		many modes available: Select|Drag|Edit|Toolbox
		Select - selects elements in the workspace
		Drag - moves selected elements around
		Edit - edit select element using handles, eventually property frames
		Toolbox - using toolbox UI, choosing a model to build, basically just doing nothing.
	]]

	--snap points properties. ONLY USED IN "DRAG" MODE.
	self.SnapFilters = { --additional informations such as image label for snappoints modes
		--[[Example:
			["Line"] = {
				["ImageId"] = "rbxassetid://0",
				["KeyCode"] = Enum.KeyCode.One,
			}
		]]
	}
	self.SnapPoints = { --ok so snap points are then categorised into multiple modes, type is {[string]:{string}}

	}

	self.EditAllowResize = false
	self.EditMoveIncrement = .5 --increment for precise edition tool, movement/resize one.
	self.EditRotateIncrement = 5

	self._EditHandles = Instance.new("Handles")
	self._RotateHandles = Instance.new("ArcHandles")
	self._Maid:Mark(self._EditHandles)
	self._Maid:Mark(self._RotateHandles)

	self.ToolboxTree = toolboxTree

	self._SelectedEvent = Instance.new("BindableEvent")
	self._Maid:Mark(self._SelectedEvent)
	self.SelectionChanged = self._SelectedEvent.Event

	self._SelectionChangedEvent = Instance.new("BindableEvent")
	self._Maid:Mark(self._SelectionChangedEvent)
	self.SelectionChanged = self._SelectionChangedEvent.Event

	self._ModeChanged = Instance.new("BindableEvent")
	self._Maid:Mark(self._ModeChanged)
	self.SelectionChanged = self._ModeChanged.Event

	self._ToolboxSelectedEvent = Instance.new("BindableEvent")
	self._Maid:Mark(self._ToolboxSelectedEvent)
	self.ToolboxSelected = self._ToolboxSelectedEvent.Event

	self:_Create()

	return self
end

function Class:ChangeMode(newMode:"Select"|"Drag"|"Edit"|"Toolbox"):nil
	self.Mode = newMode
	self._ModeChanged:Fire(newMode)

	return nil
end

function Class:UpdateGridPoints(newSnapGrid:{[string]:{string}}):nil
	self.SnapPoints = newSnapGrid

	return nil
end

function Class:_ProcessInput(object:InputObject, processed:boolean)
	if processed == false and object.UserInputState and (object.KeyCode or object.UserInputType) then
		if self.Inputs[self.Mode] and (self.Inputs[self.Mode][object.KeyCode] or self.Inputs[self.Mode][object.UserInputType]) then
			--ok!
			self.Inputs[self.Mode][object.UserInputType](object.UserInputState, object)
		end
	else return
	end
end

function Class:_Create():nil
	if not game.Players.LocalPlayer.PlayerGui:FindFirstChild("WorkspaceUI") then
		local workspaceUI = Instance.new("ScreenGui")
		workspaceUI.Name = "WorkspaceUI"
		workspaceUI.ResetOnSpawn = true
		workspaceUI.Enabled = true
		workspaceUI.Parent = game.Players.LocalPlayer.PlayerGui
	end
	--create the main UI frame
	if not game.Players.LocalPlayer.PlayerGui:FindFirstChild("WorkspaceUI"):FindFirstChild("ToolboxFrame") then
		self._SummaryViewFrame = Instance.new("Frame")

		self._Maid.LoadImage(self._Settings, "", self._SummaryViewFrame)

		self._SummaryViewFrame = game.Players.LocalPlayer.PlayerGui:FindFirstChild("WorkspaceUI")
	elseif not self._SummaryViewFrame then
		self._SummaryViewFrame = game.Players.LocalPlayer.PlayerGui:FindFirstChild("WorkspaceUI"):FindFirstChild("ToolboxFrame")
	end

	if not self._Hightlight then
		self._Hightlight = Instance.new("Highlight")
		self._Hightlight.Parent = workspace.Camera
		self._Maid:Mark(self._Hightlight)
	end

	if not self._SummaryView then
		self._SummaryView = SummaryViewClass.new(self.ToolboxTree, self._SummaryViewFrame)
		self._Maid:Mark(self._SummaryView)
	end

	if not self._Handles then
		self._Handles = Instance.new("Handles")
		self._Handles.Parent = workspace.Camera
		self._Maid:Mark(self._Handles)
	end

	self:_Update()

	self._Maid:Mark(UIS.InputBegan:Connect(function(object:InputObject, processed:boolean)
		self:_ProcessInput(object, processed)
	end))
	self._Maid:Mark(UIS.InputChanged:Connect(function(object:InputObject, processed:boolean)
		self:_ProcessInput(object, processed)
	end))
	self._Maid:Mark(UIS.InputEnded:Connect(function(object:InputObject, processed:boolean)
		self:_ProcessInput(object, processed)
	end))

	RS:BindToRenderStep("WorkspaceUI", RENDER_PRIORITY, function()
		self:_OnRenderStep()
	end)

	return nil
end

function Class:_Update():nil
	if self._SummaryViewFrame then
		self._SummaryViewFrame.Position = self._Settings.TOOLBOX_FRAME_POSITION
		self._SummaryViewFrame.Position = self._Settings.TOOLBOX_FRAME_SIZE
	end
	if self._SummaryView then
		self._SummaryView._Settings = self._Maid.FetchSettingsByPrefix(self._Settings, "TOOLBOX")
		self._SummaryView:_Update()
	end
	if self._Hightlight then
		if not self.Selected then
			self._Hightlight.OutlineColor = self._Settings.SELECT_HIGHTLIGHT_OUTLINE_COLOR3_OFF
			self._Hightlight.OutlineTransparency = self._Settings.SELECT_HIGHTLIGHT_OUTLINE_TRANSPARENCY_OFF

			self._Hightlight.FillColor = self._Settings.SELECT_HIGHTLIGHT_FILL_COLOR3_OFF
			self._Hightlight.FillTransparency = self._Settings.SELECT_HIGHTLIGHT_FILL_TRANSPARENCY_OFF
		elseif self.Selected then
			self._Hightlight.OutlineColor = self._Settings.SELECT_HIGHTLIGHT_OUTLINE_COLOR3_ON
			self._Hightlight.OutlineTransparency = self._Settings.SELECT_HIGHTLIGHT_OUTLINE_TRANSPARENCY_ON

			self._Hightlight.FillColor = self._Settings.SELECT_HIGHTLIGHT_FILL_COLOR3_ON
			self._Hightlight.FillTransparency = self._Settings.SELECT_HIGHTLIGHT_FILL_TRANSPARENCY_ON
		end
	end

	for _, highlighter in pairs(self._SelectionHighlighters) do
		highlighter.OutlineColor = self._Settings.OTHER_HIGHTLIGHT_OUTLINE_COLOR3
		highlighter.OutlineTransparency = self._Settings.OTHER_HIGHTLIGHT_OUTLINE_TRANSPARENCY

		highlighter.FillColor = self._Settings.OTHER_HIGHTLIGHT_FILL_COLOR3
		highlighter.FillTransparency = self._Settings.OTHER_HIGHTLIGHT_FILL_TRANSPARENCY
	end
end

function Class:UpdateSelection(newSelection:{}, showHighlight:boolean):nil
	self.Selection = newSelection
	self._SelectionChangedEvent:Fire(newSelection)

	if showHighlight then
		--removes unecessary stuff
		for _, object in pairs(self._SelectionHighlighters) do
			if not table.find(self.Selection, object.Adornee) then
				object:Destroy()
			end
		end

		for _, object in pairs(self.Selection) do
			local f = nil
			-- local c = nil
			for _, highlighter in pairs(self._SelectionHighlighters) do
				if highlighter:IsA("Highlight") and highlighter.Adornee == object then
					f = highlighter
				-- elseif highlighter:IsA("ClickDetector") and highlighter.Parent == object then
				-- 	c = highlighter
				end
			end
			if not f then
				local n = Instance.new("Highlight")
				n.Adornee = object
				self._Maid:Mark(n)
				table.insert(self._SelectionHighlighters, n)
				n.Parent = workspace.CurrentCamera
			end
			-- if not c then
			-- 	local m = Instance.new("ClickDetector")
			-- 	m.MaxActivationDistance = math.huge
			-- 	self._Maid:Mark(m)
			-- 	table.insert(self._SelectionHighlighters, m)
			-- 	m.Parent = object
			-- end
		end

		self:_Update()
	else for _,highlight in pairs(self._SelectionHighlighters) do
			highlight:Destroy()
		end
	end

	return nil
end

function Class:Select(element:Instance?):nil
	if element then
		assert(table.find(self.Selection, element), "Selected element is not in selection.")

		self.Selected = element
		self._SelectedEvent:Fire(self.Selected)

		self._Hightlight.Adornee = self.Selected
	else 
		self.Selected = nil
		self._SelectedEvent:Fire(nil)

		self._Hightlight.Adornee = nil
	end

	return nil
end

local function fetchMouseTarget(camera:Camera, filter:{}, filterType:Enum.RaycastFilterType?)
--look for the selection the mouse is pointing to
	--first get the position of the mouse on the viewport
	local mousePosition = UIS:GetMouseLocation()
	--get the ray using the camera object. length is 1.
	local ray = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y, 1)
	--set raycastparams (cant be directly set inside the function call)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = filter
	params.IgnoreWater = true
	params.RespectCanCollide = false
	params.FilterType = filterType or Enum.RaycastFilterType.Include
	--cast the ray into the world
	local cast = workspace:Raycast(ray.Origin, ray.Direction, params)
	local hit = if cast then cast.Instance else nil

	return hit
end
function Class:_OnRenderStep():nil
	if self.Mode == "Select" then
		assert(self._Hightlight, "No Highlight.")
		if #self.Selection == 0 then
			--ok bye
			return
		elseif #self.Selection == 1 then
			--single select mode
			self:Select(self.Selection[1])
		elseif #self.Selection > 1 then
			local hit = fetchMouseTarget(self._Camera, self.Selection)

			if hit then
				--highlight it!
				self._Hightlight.Adornee = hit
				self._Hovered = hit
			end
		end
	-- elseif self.Mode == "Drag" and self.Selected then
		--let the input thing handle everything : )

	end

	return
end

function Class:SetMode(mode:string):nil
	if mode ~= self.Mode then
		self._Hightlight.Adornee = self.Selected

		if self.Selected then
			self.Mode = mode
			if mode == "Drag" then
				
			elseif mode == "Edit" then

			end
			for _, highlighter in pairs(self._SelectionHighlighters) do
				highlighter:Destroy()
			end
		else error("No selected model given. Check self.Selected.")
		end
		if mode == "Select" then
			self.Mode = "Select"
		elseif mode == "Toolbox" then
			self.Mode = "Toolbox"
		end
	end
end

function Class:_GetClosestSnapPoint(position:Vector3)


	return nil
end

function Class:Destroy():nil
	self._Maid:Sweep()
	RS:UnbindFromRenderStep("WorkspaceUI")

	return
end

return Class
