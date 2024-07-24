--[[Ulysse94]]--

--[[

Constructors:
	new (RedoFunction [function], UndoFunction [function])
        The logger is a class used for tracing back actions. A bit like the studio ChangeHistoryService.

Properties:
	RedoFunction [function]
		The function called when redoing.

	UndoFunction [function]
		The function called when undoing.

	(READ ONLY) _Dumped [{LoggerWaypoints}]
		Used for undoing and redoing.

	(READ ONLY) Waypoints [{LoggerWaypoint}]
		Last actions.

Methods:
	Record (name [string], user [string|number], action [{any}]) -> nil
		Record a new action.

	Redo () -> nil

	Undo () -> nil

	Destroy () -> nil

Events:
	None
]]

export type LoggerWaypoint = {["Name"]:string,["Timestamp"]:number,["User"]:string|number?, ["Action"]:{}}

local Class = {}

Class.__index = Class
Class.__type = "Logger"

local function createWaypoint(name:string,
	user:string|number?,
	timestamp:number,
	actionData:any):LoggerWaypoint
	local n = {}
	n.Name = name
	n.Timestamp = timestamp
	n.User = user
	n.Details = actionData

	return n
end

function Class:__tostring()
	return Class.__type
end

function Class.new(RedoFunction, UndoFunction):{}
	local self = setmetatable({},Class)

    self.Waypoints = {}
	self._Dumped = {}

	self.OnRedo = RedoFunction
	self.OnUndo = UndoFunction

	return self
end

function Class:Record(name:string, user:string|number?, actionData:any):nil
	table.insert(self.Waypoints, createWaypoint(name, user, time(), actionData))

	self._Dumped = {}
end

function Class:Undo():nil
	if self.Waypoints[1] then
		table.insert(self._Dumped, 1, self.Waypoints[1])


		if self.OnUndo then
			self.OnUndo(self.Waypoints[1])
		end

		table.remove(self.Waypoints, 1)
	end
end

function Class:Redo():nil
	if self._Dumped[1] then
		table.insert(self.Waypoints, 1, self._Dumped[1])

		if self.OnRedo then
			self.OnRedo(self._Dumped[1])
		end

		table.remove(self._Dumped, 1)
	end
end

function Class:Clear():nil
	self._Dumped = table.clone(self.Waypoints)
    self.Waypoints = {}

	return
end

return Class