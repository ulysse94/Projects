-- Generic maid module (not from NevermoreEngine, but do the job)

-- As this is an UI utility, this module has additional functions

-- CONSTANTS

local FORMAT_STR = "Maid does not support type \"%s\""

local DESTRUCTORS = {
	["function"] = function(item)
		item()
	end;
	["RBXScriptConnection"] = function(item)
		item:Disconnect()
	end;
	["Instance"] = function(item)
		item:Destroy()
	end;
	["table"] = function(item)
		if item["Destroy"] and type(item["Destroy"]) == "function" then
			item:Destroy()
		else error(FORMAT_STR:format("table"), 2)
		end
	end,
	["nil"] = function(item)
		return
	end;
}

-- Class

local MaidClass = {}
MaidClass.__index = MaidClass
MaidClass.__type = "Maid"

function MaidClass:__tostring()
	return MaidClass.__type
end

-- Public Functions

function MaidClass.FetchSettingsByPrefix(settings:{}, settingPrefix:string):{}
	--/!\ MaidClass.LoadComplements has a custom fetching function.
	local subSettings = {}
	settingPrefix = settingPrefix.."_"

	table.foreach(settings,
	function(key, value)
		local s,e = string.find(key,settingPrefix)
		if s and e then
			subSettings[string.sub(key,1,e)] = value
		end
	end)

	return subSettings
end

function MaidClass.LoadSegment(settings:{}, settingPrefix:string, object:Frame?):{Frame}
	--note: will use "object" to store the list of lines.
	--can also edit the "object" to make it a line.

	local subSettings = MaidClass.FetchSettingsByPrefix(settings, settingPrefix)

	--[[
	POINTS = {
		{Vector2.zero, Vector2.zero},
	},
	LINE_THICKNESS = Vector2.zero,
	LINE_COLOR3 = Color3.new(1,1,1)
	LINE_TRANSPARENCY = 0,
	LINE_ANCHOR = Vector2.new(0,.5),
	]]

	if not object then
		object = Instance.new("Frame")
		object.BackgroundTransparency = 1
		object.Position = UDim2.new()
		object.Size = UDim2.fromScale(1,1)
	end

	for i, points in pairs(subSettings["POINTS"] or {}) do
		local nLineSettings = subSettings
		nLineSettings["LINE_START"] = points[1]
		nLineSettings["LINE_END"] = points[2]
		local nLine = MaidClass.LoadLine(nLineSettings, settingPrefix, object:FindFirstChild(tostring(i)))
		nLine.Name = tostring(i)
		nLine.Parent = object
	end

	for _,frame in pairs(object:GetChildren()) do
		if tonumber(frame.Name) > #subSettings["POINTS"] then
			frame:Destroy()
		end
	end

	return object
end

function MaidClass.LoadLine(settings:{}, settingPrefix:string, object:Frame?):Frame

	local subSettings = MaidClass.FetchSettingsByPrefix(settings, settingPrefix)

	--[[
	note: can bear gradiant / stroke
	can also edit the "object" and edit it (if needed)

	LINE_START = Vector2.zero,
	LINE_END = Vector2.zero,
	LINE_THICKNESS = Vector2.zero,
	LINE_COLOR3 = Color3.new(1,1,1)
	LINE_TRANSPARENCY = 0,
	LINE_ANCHOR = Vector2.new(0,.5),
	]]

	local line = Instance.new("Frame") or object

	if #subSettings > 2 then
		line.AnchorPoint = subSettings.LINE_ANCHOR
		line.BackgroundColor3 = subSettings.LINE_COLOR3
		line.BackgroundTransparency = subSettings.LINE_TRANSPARENCY
	end

	--vector from start to end.
	local vector = (subSettings.LINE_END - subSettings.LINE_START)

	local dist = vector.Magnitude
	line.Size = UDim2.new(0,dist,0,subSettings["LINE_THICKNESS"] or 1) --not sure it is existing...

	line.Position = subSettings.LINE_START

	--the formula is: acos(adjacent / hypothenuse) = acos(|vector_x|/||vector||)
	--note that since roblox has a funny rotation (range = [0;360[),
	--need to determine where the vector is pointing to,
	--in the pov of the **x axis**

	local angle = math.acos(math.abs(vector.X) / vector.Magnitude)
	if vector.Y >= 0 then --up
		if vector.X >= 0 then --right
			--do nothing
		else --left
			angle = 180 - angle
		end
	elseif vector.Y < 0 then --down
		if vector.X >= 0 then --right
			angle = 180 + angle
		else --left
			angle = 360 - angle --or -angle
		end
	end

	line.Rotation = angle


	MaidClass.LoadComplements(subSettings, "LINE")

	return line
end

function MaidClass.LoadImage(settings:{}, settingPrefix:string, object:ImageLabel|ImageButton):nil
	if not object then return end

	local subSettings = MaidClass.FetchSettingsByPrefix(settings, settingPrefix)

	--[[
	IMAGE = "rbxassetid://0",
	IMAGE_COLOR3 = Color3.new(),
	IMAGE_TRANSPARENCY = 0,
	IMAGE_SCALE = Enum.ScaleType.Stretch,
	IMAGE_TILE = UDim2.new(),
	IMAGE_SLICE_CENTER = Rect.new(),
	IMAGE_SLICE_SCALE = 0,
	IMAGE_BACKGROUND_COLOR3 = Color3.new(0,0,0), -- optional
	IMAGE_BACKGROUND_TRANSPARENCY = 0, --optional
	]]

	object.BackgroundColor3 = subSettings["IMAGE_BACKGROUND_COLOR3"] or Color3.new()
	object.BackgroundColor3 = subSettings["IMAGE_BACKGROUND_TRANSPARENCY"] or 1

	object.Image = subSettings.IMAGE
	object.ImageColor3 = subSettings.IMAGE_COLOR3
	object.ImageTransparency = subSettings.IMAGE_TRANSPARENCY
	object.ScaleType = subSettings.IMAGE_SCALE
	if subSettings.IMAGE_SCALE == Enum.ScaleType.Slice then
		object.SliceCenter = subSettings.IMAGE_SLICE_CENTER
		object.SliceScale = subSettings.IMAGE_SLICE_SCALE
	elseif subSettings.IMAGE_SCALE == Enum.ScaleType.Tile then
		object.TileSize = subSettings.IMAGE_TILE
	end

	MaidClass.LoadComplements(subSettings, "IMAGE")

	return
end

function MaidClass.LoadText(settings:{}, settingPrefix:string, object:TextLabel|TextButton):nil
	if not object then return end

	local subSettings = MaidClass.FetchSettingsByPrefix(settings, settingPrefix)

	--[[
	TEXT_BACKGROUND_TRANSPARENCY = 1,
	TEXT_BACKGROUND_COLOR3 = Color3.new(0,0,0),
	TEXT_COLOR3 = Color3.fromRGB(255, 255, 255),
	TEXT_SIZE = 14,
	TEXT_FONT = Enum.Font.Gotham,
	TEXT_WEIGHT = Enum.FontWeight.Medium,
	TEXT_TRUNCATE = false,
	TEXT_WRAP = true, --multiline
	TEXT_AUTO = false, --auto size (incompatible with truncate)
	TEXT_RICH = false, --rich text
	]]

	object.BackgroundColor3 = subSettings.TEXT_BACKGROUND_COLOR3
	object.BackgroundTransparency = subSettings.TEXT_BACKGROUND_TRANSPARENCY
	object.TextColor3 = subSettings.TEXT_COLOR3
	object.TextSize = subSettings.TEXT_SIZE
	object.Font = subSettings.TEXT_FONT
	object.FontFace.Weight = subSettings.TEXT_WEIGHT
	object.TextScaled = subSettings.TEXT_AUTO
	object.TextTruncate = subSettings.TEXT_TRUNCATE
	object.TextWrapped = subSettings.TEXT_WRAP
	object.RichText = subSettings.TEXT_RICH

	MaidClass.LoadComplements(subSettings, "TEXT")

	return
end

function MaidClass.LoadComplements(settings:{}, settingPrefix:string, object:GuiObject)
	if not object then return end

	local subSettings = {}
	local hasStroke = false
	local hasGradient = false
	local hasCorner = false
	settingPrefix = settingPrefix.."_" --custom fetch

	table.foreach(settings, --apparently deprecated, but who cares.
	function(key, value)
		local s,e = string.find(key,settingPrefix)
		if s == 1 and e then
			local sub = string.sub(key,1,e)
			subSettings[sub] = value
			hasStroke = (string.find(sub, "STROKE", 1, true) ~= nil)
			hasGradient = (string.find(sub, "GRADIENT", 1, true) ~= nil)
			hasCorner = (string.find(sub, "CORNER", 1, true) ~= nil)
		end
	end)

	--[[
	STROKE_COLOR3 = Color3.fromRGB(0,0,0),
	STROKE_SIZE = 4,
	STROKE_TRANSPARENCY = 0,
	STROKE_TYPE = Enum.LineJoinMode.Round,

	GRADIENT_COLOR = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,0,0)),
	GRADIENT_TRANSPARENCY = NumberSequence.new(0,1),
	GRADIENT_OFFSET = Vector2.zero,
	GRADIENT_ROTATION = 0,

	CORNER = UDim.new(),
	]]

	if hasStroke then
		local stroke = object:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")

		stroke.Color = subSettings.STROKE_COLOR3
		stroke.Thickness = subSettings.STROKE_SIZE
		stroke.Transparency = subSettings.STROKE_TRANSPARENCY
		stroke.LineJoinMode = subSettings.STROKE_TYPE
		stroke.ApplyStrokeMode = if object:IsA("TextLabel") then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border

		MaidClass.LoadComplements(settings, settingPrefix.."STROKE", stroke) --and yes! stroke can have gradient.

		stroke.Parent = object
	end
	if hasGradient then
		local gradient = object:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")

		gradient.Color = subSettings.GRADIENT_COLOR
		gradient.Offset = subSettings.GRADIENT_OFFSET
		gradient.Transparency = subSettings.GRADIENT_TRANSPARENCY
		gradient.Rotation = subSettings.GRADIENT_ROTATION

		gradient.Parent = object
	end
	if hasCorner then
		local corner = object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")

		corner.CornerRadius = subSettings.CORNER

		corner.Parent = object
	end
end

-- Public Constructors

function MaidClass.new()
	local self = setmetatable({}, MaidClass)

	self.Trash = {}

	return self
end

-- Public Methods

function MaidClass:Mark(item)
	local tof = typeof(item)

	if (DESTRUCTORS[tof]) then
		self.Trash[item] = tof
	else
		error(FORMAT_STR:format(tof), 2)
	end
end

function MaidClass:Unmark(item)
	if (item) then
		self.Trash[item] = nil
	else
		self.Trash = {}
	end
end

function MaidClass:Sweep()
	for item, tof in next, self.Trash do
		DESTRUCTORS[tof](item)
	end
	self.Trash = {}
end

--

return MaidClass