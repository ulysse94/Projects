--[[Ulysse94]]--

--[[
TextMasks reads new input on TextBoxes and deletes banned characters.
You should consider using the Unfiltered event instead of Changed event to record text changes.

IMPORTANT: If the string is longer than 1 character, it will think of it as a character byte code (int).

Presets:
	numbers
		just all the number characters... just in case you need them.

Constructors:
	new (list [{string}?], targets [{TextBox}?], listMode ["WhitelistChar"|"BlacklistChar"|"Interger"|"Float"], characterLimit [number])
		Creates a new TextMask on the targetted TextBoxes.

Properties:
	_Maid [Maid]
		maid.
	
	_Connections [{RBXScriptConnection}]
	
	(READ-ONLY) Targets [{TextBox}]
		The targetted TextBoxes by this text mask.
		
	ListMode ["WhitelistChar"|"BlacklistChar"|"Interger"|"Float"]
		Self-explanatory for list.
	
	List [{string}]
		Blacklisted characters.

	CharacterLimit [number?]
		Sets a character limit to the TextBox. "nil" for none. Will not shorten the text if already above the limit (more likely will get stuck).
	
Methods:
	AddTextBox (target [TextBox]) -> nil
	
	RemoveTextBox (target [TextBox]) -> nil
	
	Destroy () -> nil

Events:
	Filtered (original [string])
		Fires each time a character is filtered. Gives original string.

	Unfiltered ()
		Fired when nothing was filtered from the new input.
	
]]

local Lib = script.Parent
-- local MaidClass = require(Lib.Utilities.Maid)

local Class = {}

export type ListMode = "WhitelistCharacter"|"BlacklistCharacter"|"Integer"|"Float"

Class.__index = Class
Class.__type = "TextMasker"

function Class:__tostring()
	return Class.__type
end

function Class.new(list:{string}?, targets:{TextBox}?, listMode:ListMode?, CharacterLimit:number?):{}
	local self = setmetatable({},Class)

	self._Connections = {}

	self.Targets = targets or {}
	self.ListMode = listMode or "Whitelist"
	self.List = list or {}
	self.CharacterLimit = nil or CharacterLimit
	self._FilteredEvent = Instance.new("BindableEvent")
	self._UnfilteredEvent = Instance.new("BindableEvent")
	self.Filtered = self._FilteredEvent.Event
	self.Unfiltered = self._UnfilteredEvent.Event

	for _, textbox in pairs(self.Targets) do
		self:AddTextBox(textbox)
	end

	return self
end

function Class:Filter(str:string):string
	--Get last char.
	local ret = ""
	local len = str:len()

	if self.ListMode == "BlacklistCharacter" then
		--Blacklist
		ret = string.gsub(str, "["..table.concat(self.List,"").."]")
		
	elseif self.ListMode == "WhitelistCharacter" then
		--Whitelist
		self._FilteredEvent:Fire()
	elseif self.CharacterLimit and len > self.CharacterLimit then
		self._FilteredEvent:Fire()
	elseif self.ListMode == "Float" then
		ret = string.match(str, "%d+%.?%d*") -- "[number] . [number]". allows integers AND floats to be passed.
	elseif self.ListMode == "Integer" then
		ret = string.match(str, "%d+")
	end
	
	if ret ~= str then
		self._FilteredEvent:Fire(str)
	else
		self._UnfilteredEvent:Fire()
	end

	return ret
end

function Class:AddTextBox(textbox:TextBox):nil
	if not self._Connections[textbox] then --prevents redundancy.
		if not table.find(self.Targets,textbox) then
			table.insert(self.Targets, textbox)
		end

		self._Connections[textbox] = textbox.Changed:Connect(function(prop)
			if prop == "Text" then
				textbox.Text = self:Filter(textbox.Text)
			end
		end)
	end

	return
end

function Class:RemoveTextBox(textbox:TextBox):nil
	if self._Connections[textbox] then
		if table.find(self.Targets,textbox) then
			table.remove(self.Targets, table.find(self.Targets,textbox))
		end

		self._Connections[textbox]:Disconnect()
	end

	return
end

function Class:Destroy():nil
	for textbox, connection in pairs(self._Connections) do
		connection:Disconnect()
	end
	if self._FilteredEvent then
		self._FilteredEvent:Destroy()
	end
	if self._UnfilteredEvent then
		self._UnfilteredEvent:Destroy()
	end

	return
end

return Class
