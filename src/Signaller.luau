local Signal = require(script.Parent.TrackedSignal)


type Container<T...> = setmetatable<{[string]: Signal.s<T...>}, typeof({__mode = "v"})>


local Signaller = {}
Signaller.__index = Signaller


export type Signaller = typeof(setmetatable(
	{} :: {
		_changed: Container<any>,
		_keyChanged: Container<string | number, any>,
		_insert: Container<number, any>,
		_remove: Container<number, any>
	},
	Signaller
	))


function Signaller.new(): Signaller
	local self = setmetatable({
		_changed = setmetatable({}, {__mode = "v"}),
		_keyChanged = setmetatable({}, {__mode = "v"}),
		_insert = setmetatable({}, {__mode = "v"}),
		_remove = setmetatable({}, {__mode = "v"}),
	}, Signaller)
	return self
end


function Signaller.getStringPath(self: Signaller, path: {string}, parent: boolean?): string
	return table.concat(path, "ъ", nil, if parent then #path - 1 else #path)
end


function Signaller.getSignal(self: Signaller, path: {string}, key: string): Signal.s<...any>
	local stringPath = self:getStringPath(path)
	
	local signal = self[key][stringPath] or Signal.new()
	self[key][stringPath] = signal
	return signal
end


function Signaller.GetChangedSignal(self: Signaller, path: {string}): Signal.s<...any>
	return self:getSignal(path, "_changed")
end


function Signaller.GetKeyChangedSignal(self: Signaller, path: {string}): Signal.s<...any>
	return self:getSignal(path, "_keyChanged")
end


function Signaller.GetInsertSignal(self: Signaller, path: {string}): Signal.s<...any>
	return self:getSignal(path, "_insert")
end


function Signaller.GetRemoveSignal(self: Signaller, path: {string}): Signal.s<...any> 
	return self:getSignal(path, "_remove")
end


function Signaller.FireSet(self: Signaller, path: {string}, newValue: any)
	local stringPath = self:getStringPath(path)

	if self._changed[stringPath] then
		self._changed[stringPath]:Fire(newValue)
	end

	if #path == 0 then
		return
	end

	local parentStringPath = self:getStringPath(path, true)

	if self._keyChanged[parentStringPath] then
		self._keyChanged[parentStringPath]:Fire(path[#path], newValue)
	end
end


function Signaller.FireInsert(self: Signaller, path: {string}, index: number, value: any)
	local stringPath = self:getStringPath(path)

	if self._insert[stringPath] then
		self._insert[stringPath]:Fire(index, value)
	end
end


function Signaller.FireRemove(self: Signaller, path: {string}, index: number, value: any)
	local stringPath = self:getStringPath(path)

	if self._remove[stringPath] then
		self._remove[stringPath]:Fire(index, value)
	end
end


function Signaller.Destroy(self: Signaller)
	for _, container in {self._changed, self._insert, self._keyChanged, self._remove} do
		for key, signal in container do
			signal:DisconnectAll()
			container[key] = nil
		end
	end
end


return Signaller
