--[[Ulysse94]]--

--[[

Constructors:
	new ()

Properties:
	(READ ONLY) _Maid [Maid]
		maid.
	
Methods:
	Destroy () -> nil

Events:
	Event ()
		
	
]]

local Lib = script.Parent

local TweenService = game:GetService("TweenService")

local DEFAULT_SETTINGS = {
    CENTER_IMAGE = "rbxassetid://0",
	CENTER_IMAGE_COLOR3 = Color3.new(),
	CENTER_IMAGE_TRANSPARENCY = 0,
	CENTER_IMAGE_SCALE = Enum.ScaleType.Stretch,
	CENTER_IMAGE_TILE = UDim2.new(),
	CENTER_IMAGE_SLICE_CENTER = Rect.new(),
	CENTER_IMAGE_SLICE_SCALE = 0,

    TWEEN_INFO = TweenInfo.new()
}

local Class = {}

Class.__index = Class
Class.__type = "Radial"

function Class:__tostring()
	return Class.__type
end

function Class.new(elements:{string}, radius:number, target:ScreenGui|Frame):{}
	local self = setmetatable({},Class)

	self._Maid = require(Lib.Utilities.Maid).new()
    self._Settings = DEFAULT_SETTINGS

    self.Elements = {}
    table.foreach(elements, function(n,str)
        self.Elements[str] = true
    end)
    self.MainFrame = target:FindFirstChild("RadialMenu")

    self._OpenedEvent = Instance.new("BindableEvent")
    self._Maid:Mark(self._OpenedEvent)
    self._ClickedEvent = Instance.new("BindableEvent")
    self._Maid:Mark(self._ClickedEvent)
    self._HoveredEvent = Instance.new("BindableEvent")
    self._Maid:Mark(self._HoveredEvent)

    self._Parent = target

	return self
end

function Class:_Create():nil
    if not self.MainFrame then
        self.MainFrame = Instance.new("Frame")
        self.MainFrame.Name = "RadialMenu"
        self.MainFrame.BackgroundTransparency = 1
        self.MainFrame.Size = UDim2.fromScale(1,1)
        self.MainFrame.Parent = self._Parent
    end

    if not self.MainFrame:FindFirstChild("CenterImage") then
        local nImage = Instance.new("ImageLabel")
        nImage.Name = "CenterImage"
        nImage.Size = UDim2.fromScale(0,0)
        nImage.AnchorPoint = Vector2.new(.5,.5)
        nImage.Position = UDim2.fromScale(.5,.5)
        nImage.Parent = self.MainFrame
    end


    for _, element in pairs(self.Elements) do
        if not self.MainFrame:FindFirstChild(element.."_button") then
            local nButton = Instance.new("TextButton")
            
        end
    end

    return
end

function Class:Destroy():nil
	self._Maid:Sweep()

	return
end

return Class
