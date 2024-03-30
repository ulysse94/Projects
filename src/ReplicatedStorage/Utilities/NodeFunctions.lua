--!strict
--[[Ulysse94]]--

-- Multiple functions dedicated to nodes & splines manipulations and acquiring data on them.

local nodeFunctions = {}
local railFolder = workspace.Rails

--[[
	Returns the back and front connections of the rail (models).
	Always return something like this:
		{
			[1] = back connection,
			[2] = front connection
		}
]]
function nodeFunctions.getConnectedSection(section:Model):{[number]:Model}
	return {railFolder:FindFirstChild(section:GetAttribute("BackConnection") or "") or nil, railFolder:FindFirstChild(section:GetAttribute("FrontConnection") or "")}
end

--[[
	Accepts 2 connections that are supposedly connected.
	Tells wether or not the "connectedSection" is connected from the Front or the Back TO the "section".
	3 cases:
		- 1: back
		- 2: front (CAN BE A NODE, AND NOT BEING CONNECTED.)
		- nil: not connected
]]
function nodeFunctions.getConnectedSectionSide(section:Model|BasePart?, connectedSection:Model|BasePart?):number?
---@diagnostic disable-next-line: invalid-class-name
	if typeof(connectedSection)=="Model" then
		if connectedSection:GetAttribute("FrontConnection") == section.Name then
			return 2
		elseif connectedSection:GetAttribute("BackConnection") == section.Name then
			return 1
		end
---@diagnostic disable-next-line: invalid-class-name
	elseif typeof(connectedSection)=="BasePart" then
		-- it's a node.
		if connectedSection:GetAttribute("BackConnection") == section.Name then
			return 1
		else
			return 2
		end
	end
	return
end

--[[
	Takes a section, then finds the parts that are after and before this connection.
	Will return a table this way:
		{
			[1] = BackConnectionPoint,
			[2] = FrontConnectionPoint
		}
]]
function nodeFunctions.getBackAndFrontPoints(section:Model):{[number]:BasePart}
	-- we got the main table.
	-- add the +1 and -1 part to get something more coherent.
	-- only useful if you use Catmull Rom splines, but we use bezier here, so bye bye
	local result = {}
	local connections = nodeFunctions.getConnectedSection(section)

	if connections[1] then --back connection
		if nodeFunctions.getConnectedSectionSide(section, connections[1]) == 1 then -- 1 = back
			result[1] = connections[1]:FindFirstChild("1")
		else -- 2 = front
			result[1] = connections[1]:FindFirstChild(tostring(#connections[1]:GetChildren()))
		end
	end

	if connections[2] then --front connection
		if nodeFunctions.getConnectedSectionSide(section, connections[2]) == 2 then -- 2 = front
			result[2] = connections[2]:FindFirstChild(tostring(#connections[1]:GetChildren()))
		else -- 1 = back
			result[2] = connections[2]:FindFirstChild("1")
		end
	end

	return result
end

--[[
	Takes a curve, and sorts all the parts in the correct order.
	Eventually removes unecessary ones.
]]
function nodeFunctions.sortPoints(section:Model):{BasePart}
	local sorted = section:GetChildren()
	for i, inst in ipairs(sorted) do
---@diagnostic disable-next-line: invalid-class-name
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