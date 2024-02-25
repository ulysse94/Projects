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
	Filtered (filteredcharacter [number])
		Fires each time a character is filtered. Passes the byte code of the character.
		
	Unfiltered (newtext [string])
		Fired when nothing was filtered from the new input, and passes the new text.
	
]]

local Lib = script.Parent
-- local MaidClass = require(Lib.Utilities.Maid)

local Class = {}

export type ListMode = "WhitelistChar"|"BlacklistChar"|"Interger"|"Float"

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
	local char = str:sub(len,len-1)

	if (table.find(self.List,char) or table.find(self.List,string.byte(char))) and self.ListMode == "BlacklistChar" then
		--Blacklist
		ret = string.sub(str, 1, length)
		self._FilteredEvent:Fire(char)
	elseif self.ListMode == "WhitelistChar" then
		--Whitelist
		

		self._FilteredEvent:Fire(char)
	elseif self.CharacterLimit and len > self.CharacterLimit then
		

		self._FilteredEvent:Fire(char)
	elseif self.ListMode == "" then
		ret = string.gsub(str, "[^%d.]", "")
	else
		--Unfiltered
		self._UnfilteredEvent:Fire(ret)
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
