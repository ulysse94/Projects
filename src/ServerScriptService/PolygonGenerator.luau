--polygon filler algorithm. found opensourced (forgot where tho). very cool.

--local toPolygon = game.Workspace.Shape
--local t = {
--	{137.00, 281.00},
--	{131.00, 292.00},
--	{88.00, 300.00},
--	{87.00, 310.00},
--	{101.00, 319.00},
--	{90.00, 342.00},
--	{39.00, 310.00},
--	{75.00, 250.00},
--	{146.00, 248.00},
--	{192.00, 241.00},
--	{199.00, 254.00},
--	{190.00, 265.00},
--	{167.00, 256.00},
--	{137.00, 276.00}
--}

--local points = {}
--for i,v in pairs(t) do
--	local p = Instance.new("Part")
--	p.Size = Vector3.new(1,1,1)
--	p.BrickColor = BrickColor.Red()
--	p.CFrame = CFrame.new(v[1], 15, v[2])
--	p.Anchored = true
--	p.CanCollide = false
--	p.Parent = game.Workspace
--	p.Name = i
--	table.insert(points, p)
--end

--points = toPolygon:GetChildren()
--table.sort(points, function(a,b) return tonumber(a.Name) < tonumber(b.Name) end)
--local verticeCount = #toPolygon:GetChildren()
function GetPointInFront(point, listOfPoints)
	if point == #listOfPoints then
		return listOfPoints[1]
	else
		return listOfPoints[point+1]
	end
end

function GetPointBehind(point, listOfPoints)
	if point == 1 then
		return listOfPoints[#listOfPoints]
	else
		--if point == 4 then
			--print("______")
			--print(listOfPoints[point-1])
		--end
		return listOfPoints[point-1]
	end
end

function IsPointConvex(behind, point, infront, previousDirection)
	local v1 = point.Position - behind.Position
	local v2 = infront.Position - point.Position

	local crossproduct = v2:Cross(v1)
	local currentDirection

	if crossproduct.Y > 0 then
		currentDirection = 1
	else
		currentDirection = -1
	end
	return currentDirection ~= previousDirection
end

function GetAreaOfTriangle(A, B, C)
	local BA = A.Position - B.Position
	local CA = C.Position - B.Position

	return (BA:Cross(CA).magnitude/2)
end

function GetEarOfPolygon(parts, direction, folder, thickness)
	local i = 1
	local earFound = false
	local newTable
	while not earFound and i <= #parts do 
		local point = parts[i]
		local A, B, C = GetPointBehind(i, parts), point, GetPointInFront(i, parts)
		
		if IsPointConvex(A,B,C, direction) then
			-- Check no parts contained within this triangle now

			local contained = false
			for x,v in pairs(parts) do


				if v ~= A and v ~= B and v ~= C then


					-- check if this triangle contains any stray verticles. If so, can't do anything :(
					local a1,a2,a3 = GetAreaOfTriangle(A, B, v), GetAreaOfTriangle(A, C, v), GetAreaOfTriangle(B, C, v)

					if a1 + a2 + a3 == GetAreaOfTriangle(A, B, C) then
						contained = true
					end
				end


			end				
						
			if not contained then


				--[[print("i is " .. tostring(i))
				print("I've decided " .. point.Name .. " is a concave point.")
				print(GetPointBehind(i, parts).Name .. " is behind")
				print(GetPointInFront(i, parts).Name .. " is infront")--]]
				earFound = point
				drawTriangle(A.Position, B.Position, C.Position, folder, thickness)
				newTable = {}
				for x,v in pairs(parts) do
					if v ~= point then
						table.insert(newTable, v)
					end
				end
			end
		end
		i=i+1
	end
	return earFound, newTable
end


function TriangulatePolygon(points, parent, thickness)
	local folder = Instance.new("Model", parent)
	local newTable = points
	local done = false
	
	while newTable and #newTable > 2 do
		done,newTable = GetEarOfPolygon(newTable, -1, folder, thickness) --TODO: understand why i had to change director (from 1 to -1)
		if newTable then
			table.sort(newTable, function(a,b) return tonumber(a.Name) < tonumber(b.Name) end)
		end
	end
	return folder
end


local wedge = Instance.new("WedgePart")
wedge.Material = Enum.Material.SmoothPlastic
wedge.Transparency = 0
wedge.Anchored = true
wedge.CanCollide = false
wedge.TopSurface = Enum.SurfaceType.Smooth
wedge.BottomSurface = Enum.SurfaceType.Smooth
wedge.Color = Color3.fromRGB(125, 125, 125)
--local wedgeMesh = Instance.new("SpecialMesh", wedge)
--wedgeMesh.MeshType = Enum.MeshType.Wedge
--wedgeMesh.Scale = Vector3.new(1,1,1)



function drawTriangle(a, b, c, parent, thickness)
	local edges = {
		{longest = (c - b), other = (a - b), position = b};
		{longest = (a - c), other = (b - c), position = c};
		{longest = (b - a), other = (c - a), position = a};
	};
	table.sort(edges, function(a, b) return a.longest.magnitude > b.longest.magnitude end);
	local edge = edges[1];

	local theta = math.acos(edge.longest.unit:Dot(edge.other.unit))
	local s1 = Vector2.new(edge.other.magnitude * math.cos(theta), edge.other.magnitude * math.sin(theta));
	local s2 = Vector2.new(edge.longest.magnitude - s1.x, s1.y);

	local p1 = edge.position + edge.other * 0.5
	local p2 = edge.position + edge.longest + (edge.other - edge.longest) * 0.5

	local right = edge.longest:Cross(edge.other).unit;
	local up = right:Cross(edge.longest).unit;
	local back = edge.longest.unit;

	local cf1 = CFrame.new(
		p1.x, p1.y, p1.z,
		-right.x, up.x, back.x,
		-right.y, up.y, back.y,
		-right.z, up.z, back.z
	);
	local cf2 = CFrame.new(
		p2.x, p2.y, p2.z,
		right.x, up.x, -back.x,
		right.y, up.y, -back.y,
		right.z, up.z, -back.z
	);

	local w1 = wedge:Clone();
	local w2 = wedge:Clone();
	w1.Parent = parent;
	w2.Parent = parent;
	w1.Size = Vector3.new(thickness, s1.y, s1.x);
	w2.Size = Vector3.new(thickness, s2.y, s2.x);
	w1.CFrame = cf1;
	w2.CFrame = cf2;
end;

return TriangulatePolygon