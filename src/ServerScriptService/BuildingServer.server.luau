--[[Ulysse94]]--

local ws = workspace
local cs = game:GetService("CollectionService")
local pg = require(script.Parent.PolygonGenerator)
local storage = game.ServerStorage.BuildingStorage
--local clientEditEvents = game.ReplicatedStorage.BuildingEvents
local debugMode = false
--

function generateWall(model)
	--Walls are parts that are put between 2 points, and are rotated to face the correct direction.
	--The wall is then stretched to fit between the 2 points.
	
	if model:FindFirstChildWhichIsA("BasePart") then
		model:FindFirstChildWhichIsA("BasePart"):Destroy()
	end
	
	local startPos = model.Parent:FindFirstChild(model:GetAttribute("StartPoint"))
	local endPos = model.Parent:FindFirstChild(model:GetAttribute("StartPoint")+1) or model.Parent:FindFirstChild("1")

	--ugly fail-safe
	if startPos then
		startPos = startPos.Position
	else return
	end
	if endPos then
		endPos = endPos.Position
	else return
	end

	local wall = Instance.new("Part")

	--funny vector is for: fat, stoned, & elongation
	if tonumber(model:GetAttribute("Height")) then
		--defined height
		wall.Size = Vector3.new(model:GetAttribute("Thickness") or 1, 
			(model:GetAttribute("Height") or 10), 
			(startPos - endPos).Magnitude + (model:GetAttribute("Thickness") or 1))
	else --auto height
		wall.Size = Vector3.new(model:GetAttribute("Thickness") or 1, 
			(model.Parent:GetAttribute("CeilingEnabled") or 10)-(model.Parent:GetAttribute("BaseYOffset") or 0)+(model.Parent:GetAttribute("Thickness")*2 or 1),
			(startPos - endPos).Magnitude + (model:GetAttribute("Thickness") or 1))
	end

	wall.CFrame = CFrame.new((startPos + endPos) / 2, startPos)
	wall.Position += Vector3.new(0,wall.Size.Y/2 + (model.Parent:GetAttribute("BaseYOffset") or 0)*2,0)
	wall.CFrame += wall.CFrame.RightVector * ((model:GetAttribute("Thickness") or 1) / 2)

	wall.BrickColor = model:GetAttribute("WallBrickColor") or BrickColor.Gray()
	wall.Material = Enum.Material[model:GetAttribute("WallMaterial") ~= "" and model:GetAttribute("WallMaterial") or "Plastic"]
	wall.MaterialVariant = model:GetAttribute("WallMaterialVariant") or ""

	wall.CanCollide = true
	wall.CanTouch = true
	wall.Anchored = true

	wall.Parent = model
end

function generateBase(model)
	--Get the points and destroy past works.
	local baseParts = {}
	for _, part in pairs(model:GetChildren()) do
		if part:IsA("Model") and (part.Name == "FloorMesh" or part.Name == "Walls" or part.Name == "") then
			part:Destroy()
		elseif part:IsA("BasePart") and tonumber(part.Name) then
			baseParts[tonumber(part.Name)] = part
			part.Transparency = debugMode == false and 1 or 0
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Anchored = true
		end
	end

	--Generating floor.
	local mesh = pg(baseParts, model, model:GetAttribute("Thickness") or 1)
	mesh.Name = "FloorMesh"
	mesh:SetAttribute("ObjectType","FloorMesh")

	local unionParts = mesh:GetChildren()
	local floorPart = mesh:FindFirstChildWhichIsA("BasePart")

	--properties must be set here, and shared with all parts
	for _, part in pairs(unionParts) do
		part.BrickColor = model:GetAttribute("BaseBrickColor") or BrickColor.Gray()
		part.Material = Enum.Material[model:GetAttribute("BaseMaterial") or "Plastic"]
		part.MaterialVariant = model:GetAttribute("BaseMaterialVariant") or ""
		part.CanCollide = true
		part.CanTouch = true
	end

	--Generating ceiling by cloning floor mesh
	if model:GetAttribute("CeilingEnabled") and model:GetAttribute("CeilingEnabled") > 0 then
		local ceiling = mesh:Clone()
		ceiling.Name = "CeilingMesh"
		ceiling:SetAttribute("ObjectType","CeilingMesh")
		ceiling.Parent = model
		local ceilingPart = ceiling:FindFirstChildWhichIsA("BasePart")

		--properties must be set here, and shared with all parts
		for _, part in pairs(ceiling:GetChildren()) do
			part.BrickColor = model:GetAttribute("BaseBrickColor") or BrickColor.Gray()
			part.Material = Enum.Material[model:GetAttribute("BaseMaterial") ~= "" and model:GetAttribute("BaseMaterial") or "Plastic"]
			part.MaterialVariant = model:GetAttribute("BaseMaterialVariant") or ""
			part.CanCollide = true
			part.CanTouch = true
		end
		
		--TO AVOID BUGS WITH SUBTRACTASYNC, OR FURTHER UNIONING:
		--Remove the floor part from the union parts
		local ceilingParts = ceiling:GetChildren()
		table.remove(ceilingParts, table.find(ceilingParts, ceilingPart))

		--Unioning ceiling
		ceilingPart = ceilingPart:UnionAsync(ceilingParts, Enum.CollisionFidelity.Hull, Enum.RenderFidelity.Automatic)
		ceiling:ClearAllChildren()
		ceilingPart.Name = "Mesh"

		ceilingPart.CanCollide = true
		ceilingPart.CanTouch = true
		ceilingPart.Anchored = true

		--making sure properties are the same
		ceilingPart.Position += Vector3.new(0, (model:GetAttribute("CeilingEnabled") or 10) + model:GetAttribute("Thickness")/2, 0)
		ceilingPart.BrickColor = model:GetAttribute("CeilingBrickColor") or BrickColor.Gray()
		ceilingPart.Material = Enum.Material[model:GetAttribute("CeilingMaterial") ~= "" and model:GetAttribute("CeilingMaterial") or "Plastic"]
		ceilingPart.MaterialVariant = model:GetAttribute("CeilingMaterialVariant") or ""

		ceilingPart.Parent = ceiling
		ceiling.PrimaryPart = ceilingPart
	end
	----
	
	--TO AVOID BUGS WITH SUBTRACTASYNC, OR FURTHER UNIONING:
	--Remove the floor part from the union parts
	table.remove(unionParts, table.find(unionParts, floorPart))
	
	--Unioning floor
	floorPart = floorPart:UnionAsync(unionParts, Enum.CollisionFidelity.Default, Enum.RenderFidelity.Automatic)
	mesh:ClearAllChildren()
	floorPart.Name = "Mesh"

	floorPart.CanCollide = true
	floorPart.CanTouch = true
	floorPart.Anchored = true

	--making sure properties are the same
	floorPart.Position += Vector3.new(0, (model:GetAttribute("BaseYOffset") or 0) - model:GetAttribute("Thickness")/2, 0)
	floorPart.BrickColor = model:GetAttribute("BaseBrickColor") or BrickColor.Gray()
	floorPart.Material = Enum.Material[model:GetAttribute("BaseMaterial") ~= "" and model:GetAttribute("BaseMaterial") or "Plastic"]
	floorPart.MaterialVariant = model:GetAttribute("BaseMaterialVariant") or ""

	floorPart.Parent = mesh
	mesh.PrimaryPart = floorPart
end

function generateItem(model)
	local base = model.Parent

	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildOfClass("Part")
	end

	if debugMode then
		model.PrimaryPart.Transparency = 0
	else model.PrimaryPart.Transparency = 1
	end

	if model:FindFirstChildOfClass("Model") then
		model:FindFirstChildOfClass("Model"):Destroy()
	end

	if storage:FindFirstChild(model:GetAttribute("ModelName")) then
		local found = storage:FindFirstChild(model:GetAttribute("ModelName")):Clone()

		found:PivotTo(model.PrimaryPart.CFrame
			* CFrame.new(model.PrimaryPart.CFrame.LookVector * (found:GetAttribute("DefaultOffset") and found:GetAttribute("DefaultOffset").Z or 0))
			* CFrame.new(model.PrimaryPart.CFrame.RightVector * (found:GetAttribute("DefaultOffset") and found:GetAttribute("DefaultOffset").X or 0))
			* CFrame.new(model.PrimaryPart.CFrame.UpVector * (found:GetAttribute("DefaultOffset") and found:GetAttribute("DefaultOffset").Y or 0))
			--model.PrimaryPart.CFrame
			--* found.PrimaryPart.CFrame
		)

		found.Parent = model

		--Actually, at this point, it would be enough if there was no wall.
		--But what if it's a window? What if it's a wall item?
		--1. Cyle through negative operations
		for _, operation in pairs(found:GetChildren()) do
			if operation:IsA("NegateOperation") then
				--2. Get hitted parts
				local intersectingParts = workspace:GetPartsInPart(operation)
				--3. Cycle through hitted parts (or unions) and check if they are walls, then list them.
				local union
				for _, part in intersectingParts do
					if part:FindFirstAncestorOfClass("Model") and 
						(part:FindFirstAncestorOfClass("Model"):GetAttribute("ObjectType") == "Wall" 
							or part:FindFirstAncestorOfClass("Model"):GetAttribute("ObjectType") == "FloorMesh"
							or part:FindFirstAncestorOfClass("Model"):GetAttribute("ObjectType") == "CeilingMesh"
						)
					then
						--4. Union
						union = part:SubtractAsync({operation},Enum.CollisionFidelity.Default, Enum.RenderFidelity.Automatic)
						union.Parent = part.Parent

						--5. Destroy remains.
						part:Destroy()
					end
				end

				operation:Destroy()
			end
		end
	end
end

function updateTag(bz)
	local bz = ws.BuildingZone
	local flrs = bz.Floors

	for _, floor in pairs(flrs:GetChildren()) do
		for _, model in pairs(floor:GetDescendants()) do
			if model:GetAttribute("ObjectType") and model:IsA("Model") then

				if model:GetAttribute("ObjectType") == "Base" or model:GetAttribute("ObjectType") == "FloorBase" then
					cs:AddTag(model, bz.Name.."_FloorBase")

				elseif model:GetAttribute("ObjectType") == "BaseItem" and model:FindFirstChildOfClass("Part") then
					cs:AddTag(model, bz.Name.."_BaseItem")

				elseif model:GetAttribute("ObjectType") == "Wall" and model:GetAttribute("StartPoint") and model:GetAttribute("StartPoint") > 0 then
					cs:AddTag(model, bz.Name.."_Wall")

				end
			end
		end
	end
end

function update(bz)
	local bz = ws.BuildingZone
	local flrs = bz.Floors

	--Building order: 1. FloorBase 2. Walls 3. BaseItems
	--FloorBase:
	for _, base in pairs(cs:GetTagged(bz.Name.."_FloorBase")) do
		if base:IsDescendantOf(bz) then
			generateBase(base)
		end
	end
	--Walls:
	for _, wall in pairs(cs:GetTagged(bz.Name.."_Wall")) do
		if wall:IsDescendantOf(bz) then
			generateWall(wall)
		end
	end
	--BaseItems: 
	for _, item in pairs(cs:GetTagged(bz.Name.."_BaseItem")) do
		if item:IsDescendantOf(bz) then
			generateItem(item)
		end
	end
end

function save(bz)

end

updateTag(ws.BuildingZone)
update(ws.BuildingZone)
