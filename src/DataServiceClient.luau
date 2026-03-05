local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


if RunService:IsServer() then
	return {} :: DataServiceClient
end


local Network = require(script.Parent.Packages.Network)
local Utils = require(script.Parent.DataServiceUtils)
local DataTemplate = require(script.Parent.DataTemplate)
local Signaller = require(script.Parent.Classes.Signaller)
local Path = require(script.Parent.Classes.Path)
local Signal = require(script.Parent.Packages.Signal)


type equals<T, U> = Utils.equals<T, U>


local DataServiceClient = {}
DataServiceClient.__index = function(self, key)
	return if key ~= "d" then rawget(self, key) else Path
end

setmetatable(DataServiceClient, DataServiceClient)


type Data = DataTemplate.Data
type DataServiceClient = typeof(DataServiceClient) & {
	_data: DataTemplate.Data,
	_network: Network.Client,
	_initThread: thread,
	_signaller: Signaller.Signaller
} & {
	d: Data
}


function DataServiceClient.init(self: DataServiceClient)
	self._network = Network.Client.new(Utils.NETWORK_NAME, self)
	self._signaller = Signaller.new()
	
	self._initThread = coroutine.running()
	coroutine.yield()
	self._initThread = nil
end


function DataServiceClient.onInit(self: DataServiceClient, data: Data)
	self._data = data
	task.spawn(self._initThread)
end


function DataServiceClient.Get<T>(self: DataServiceClient, path: T): T
	local pathTable = if getmetatable(path) then path() else path

	local current = self._data
	for _, v in pathTable do
		assert(current[v] ~= nil, `{v} is not key of {current}`)
		current = current[v]
	end

	return current
end


function DataServiceClient.Set<T, U>(self: DataServiceClient, path: T, value: U & equals<T, U>)
	local pathTable = if getmetatable(path) then path() else path

	local current = self._data
	for i = 1, #pathTable - 1 do
		assert(current[pathTable[i]] ~= nil, `{pathTable[i]} is not key of {current}`)
		current = current[pathTable[i]]
	end

	current[pathTable[#pathTable]] = value
	self._signaller:FireSet(pathTable, value)
end


function DataServiceClient.Update<T, U>(self: DataServiceClient, path: T, callback: (U & equals<T, U>) -> U)
	self:Set(path, callback(self:Get(path)))
end


function DataServiceClient.Insert<T, U>(self: DataServiceClient, path: {T}, value: U & equals<T, U>, index: number?)
	local pathTable = if getmetatable(path) then path() else path
	local insertTable = self:Get(path)

	if index then
		table.insert(insertTable, index, value)
	else
		table.insert(insertTable, value)
	end
	
	self._signaller:FireInsert(pathTable, index or #insertTable, value)
end


function DataServiceClient.Remove<T>(self: DataServiceClient, path: {T}, index: number?): T
	local pathTable = if getmetatable(path) then path() else path
	local removeTable = self:Get(path)
	
	local value = table.remove(removeTable, index)
	self._signaller:FireRemove(pathTable, index or #removeTable + 1, value)
	return value
end


function DataServiceClient.Fetch<T>(self: DataServiceClient, path: T, dontSet: boolean?): T
	local value = self._network:Invoke("Get", path())
	
	if not dontSet then
		self:Set(path, value)
	end
	
	return value
end


function DataServiceClient.GetChangedSignal<T>(self: DataServiceClient, path: T): Signal.s<T>
	return self._signaller:GetChangedSignal(path())
end


function DataServiceClient.GetKeyChangedSignal<T, U>(self: DataServiceClient, path: {[T]: U}): Signal.s<T, U>
	return self._signaller:GetKeyChangedSignal(path())
end


function DataServiceClient.GetInsertSignal<T>(self: DataServiceClient, path: {T}): Signal.s<number, T>
	return self._signaller:GetInsertSignal(path())
end


function DataServiceClient.GetRemoveSignal<T>(self: DataServiceClient, path: {T}): Signal.s<number, T>
	return self._signaller:GetRemoveSignal(path())
end


DataServiceClient[Utils.Action.Init] = DataServiceClient.onInit
DataServiceClient[Utils.Action.Set] = DataServiceClient.Set
DataServiceClient[Utils.Action.Insert] = DataServiceClient.Insert
DataServiceClient[Utils.Action.Remove] = DataServiceClient.Remove


DataServiceClient:init()
return DataServiceClient :: DataServiceClient
