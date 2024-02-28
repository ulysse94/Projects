--!strict
--[[Ulysse94]]--

local Splines = {}
for _, module in pairs(game.ReplicatedStorage.Utilities.Splines:GetChildren()) do
	if module:IsA("ModuleScript") then
		Splines[module.Name] = require(module)
	end
end

local railFolder = workspace.Rails

local splineIndex = {}
local cartIndex = {}
local partIndex = {}

_G.SplineIndex = splineIndex -- _G is like shared
_G.CartIndex = cartIndex

local step = .01 -- 1/step iteration per curve

--[[
	Returns the back and front connections of the rail (models).
	Always return something like this:
		{
			[1] = back connection,
			[2] = front connection
		}
]]
function getConnectedSection(section:Model):{[number]:Model}
	return {railFolder:FindFirstChild(section:GetAttribute("BackConnection") or "") or nil, railFolder:FindFirstChild(section:GetAttribute("FrontConnection") or "")}
end

--[[
	Accepts 2 connections that are supposedly connected.
	Tells wether or not the "connectedSection" is connected on the Front or the Back to the "section".
	3 cases:
		- 1: back
		- 2: front
		- nil: not connected
]]
function getConnectedSectionSide(section:Model, connectedSection:Model):number?
	if connectedSection:GetAttribute("FrontConnection") == section.Name then
		return 2
	elseif connectedSection:GetAttribute("BackConnection") == section.Name then
		return 1
	end
	
	return
end

--[[
	Fixes back/front connections (in the case where some are missing).
	i.e: if a section is connected on the "front" to another, but the other doesnt have this connection, it will be removed.
	Will also fix the section points numbering eventually.
]]
function fixConnections():nil
	for _, section in pairs(railFolder:GetChildren()) do
		local connections = getConnectedSection(section)
		if connections[1] and getConnectedSectionSide(section, connections[1]) == nil then
			section:SetAttribute("BackConnection", nil)
		end
		if connections[2] and getConnectedSectionSide(section, connections[2]) == nil then
			section:SetAttribute("FrontConnection", nil)
		end
		
		if section:IsA("Model") then
			local points = sortPoints(section)
			
			for i, part in ipairs(points) do
				part.Name = tostring(i)
			end
		end
	end
	
	return
end

--[[
	Takes a curve, and sorts all the parts in the correct order.
	Eventually removes unecessary ones.
]]
function sortPoints(section:Model):{BasePart}
	local sorted = section:GetChildren()
	for i, inst in ipairs(sorted) do
		if typeof(inst) ~= "BasePart" and not tonumber(inst.Name) then
			table.remove(sorted, i)
		end
	end
	table.sort(sorted, function(a, b)
		-- Extract the numbers from the BasePart names
		local numA = tonumber(a.Name) or 1 --not using string.match(b.Name, "%d+")
		local numB = tonumber(b.Name) or 2

		-- Compare the numbers
		return numA < numB
	end)
	
	return sorted
end

--[[
	Takes a section, then finds the parts that are after and before this connection.
	Will return a table this way:
		{
			[1] = BackConnectionPoint,
			[2] = FrontConnectionPoint
		}
]]
function getBackAndFrontPoints(section:Model):{[number]:BasePart}
	-- we got the main table.
	-- add the +1 and -1 part to get something more coherent.
	-- only useful if you use Catmull Rom splines, but we use bezier here, so bye bye
	local result = {}
	local connections = getConnectedSection(section)

	if connections[1] then --back connection
		if getConnectedSectionSide(section, connections[1]) == 1 then -- 1 = back
			result[1] = connections[1]:FindFirstChild("1")
		else -- 2 = front
			result[1] = connections[1]:FindFirstChild(tostring(#connections[1]:GetChildren()))
		end
	end

	if connections[2] then --front connection
		if getConnectedSectionSide(section, connections[2]) == 2 then -- 2 = front
			result[2] = connections[2]:FindFirstChild(tostring(#connections[1]:GetChildren()))
		else -- 1 = back
			result[2] = connections[2]:FindFirstChild("1")
		end
	end
	
	return result
end

function generateCurves():nil
	for _, section in pairs(railFolder:GetChildren()) do
		if section:IsA("Model") then
			local sortedPoints = sortPoints(section)
			if #sortPoints(section) >= 2 then
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

				spline["Connections"] = getBackAndFrontPoints(section)

				splineIndex[section.Name] = spline
			else error("Section "..section.." does not have enough points (>=2)")
			end
		elseif section:IsA("Part") then
			-- The section turns out to be a node... not a part!
			-- TODO: node.
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