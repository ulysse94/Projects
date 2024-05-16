--!strict
--[[Ulysse94]]--

local Splines = {}
for _, module in pairs(game.ReplicatedStorage.Utilities.Splines:GetChildren()) do
	if module:IsA("ModuleScript") then
		Splines[module.Name] = require(module)
	end
end
local NodeClass = require(game.ReplicatedStorage.Utilities.Node)

local railFolder = workspace.Rails

local nodeFunctions = require(game.ReplicatedStorage.Utilities.NodeFunctions)

local splineIndex = {}
local cartIndex = {}
local cartSplineIndex = {}
local partIndex = {}

_G.SplineIndex = splineIndex
_G.CartIndex = cartIndex
_G.CartSplineIndex = cartSplineIndex

local step = .01 -- 1/step iteration per curve

--[[
	Fixes back/front connections (in the case where some are missing).
	i.e: if a section is connected on the "front" to another, but the other doesnt have this connection, it will be removed.
	Will also fix the section points numbering eventually.
]]
function fixConnections():nil
	for _, section in pairs(railFolder:GetChildren()) do
		local connections = nodeFunctions.getConnectedSection(section)
		if connections[1] and nodeFunctions.getConnectedSectionSide(section, connections[1]) == nil then
			section:SetAttribute("BackConnection", nil)
		end
		if connections[2] and nodeFunctions.getConnectedSectionSide(section, connections[2]) == nil then
			section:SetAttribute("FrontConnection", nil)
		end

		if section:IsA("Model") then
			local points = nodeFunctions.sortPoints(section)

			for i, part in ipairs(points) do
				part.Name = tostring(i)
			end
		end
	end

	return
end

function generateCurves():nil
	for _, section in pairs(railFolder:GetChildren()) do
		if section:IsA("Model") then
			local sortedPoints = nodeFunctions.sortPoints(section)
			if #nodeFunctions.sortPoints(section) >= 2 then
				local resolution = section:GetAttribute("SectionResolution") or nil
				local spline = Splines[section:GetAttribute("SplineType") or "BezierSpline"].new(sortedPoints, resolution)

				for i = step, 1, step do
					local part = Instance.new("Part")
					part.Anchored = true
					part.CanCollide = false
					part.Size = Vector3.one

					part.CFrame = spline:CalculateCFrameAt(i)

					part.Name = "RailPart"..string.format("%.2f", i)
					part.Parent = section

					table.insert(partIndex, part)
				end

				spline["Connections"] = nodeFunctions.getBackAndFrontPoints(section)

				splineIndex[section.Name] = spline
			else error("Section "..section.." does not have enough points (>=2)")
			end
		elseif section:IsA("Part") then
			-- The section turns out to be a node... not a spline!
			local back = section:GetAttribute("BackConnection")
			local front = section:GetAttribute("FrontConnections")
			front = string.split(front, ",") --cf readme

			back = railFolder:FindFirstChild(back)
			table.foreach(front, function(i,v)
				front[i] = railFolder:FindFirstChild(v)
			end)

			local node = NodeClass.new(section, back, front)
			splineIndex[section.Name] = node

			local fPoint = nil
			local side = nodeFunctions.getConnectedSectionSide(section, back)
			if side == 1 then -- back
				fPoint = back:FindFirstChild("1")
			elseif side == 2 then -- front
				fPoint = back:FindFirstChild(tostring(#back:GetChildren()))
			end
			node.Connections[1] = fPoint

			-- node:UpdatePosition(1)
		end
	end

	return
end

--[[
	Scans all rails and checks if an update has been made. If so, will update each of them.
]]
function scanChanges():nil


	return
end

-- Executing
fixConnections()
generateCurves()