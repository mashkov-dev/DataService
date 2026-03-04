local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


if RunService:IsClient() then
	return {} :: DataServiceServer
end


local ProfileStore = require(script.Parent.Packages.ProfileStore)
local Network = require(script.Parent.Packages.Network)
local Utils = require(script.Parent.DataServiceUtils)
local DataTemplate = require(script.Parent.DataTemplate)
local Signaller = require(script.Parent.Classes.Signaller)
local Path = require(script.Parent.Classes.Path)
local Signal = require(script.Parent.Packages.Signal)


local function storeCancel(player: Player)
	return {
		Cancel = function()
			return player.Parent ~= Players
		end,
	}
end


type equals<T, U> = Utils.equals<T, U>
type Profile = ProfileStore.Profile<any>
type ProfileStore = typeof(ProfileStore.New(...))
type Options = {
	Template: any,
	DatastoreKey: string,
	
	UseMock: boolean?,
	DontSave: boolean?,
	
	ViewedUserId: number?,
	OverriddenUserId: number?,
}


local DataServiceServer = {}
DataServiceServer.__index = function(self, key)
	return if key ~= "d" then rawget(self, key) else Path
end

setmetatable(DataServiceServer, DataServiceServer)


type Data = DataTemplate.Data
type DataServiceServer = typeof(DataServiceServer) & {
	_options: Options,

	_profiles: {[Player]: Profile},
	_signallers: {[Player]: Signaller.Signaller},
	_initialized: {[Player]: boolean},

	_profileStore: ProfileStore,
	_network: Network.Server,
	
	DataLoaded: Signal.s<Player>
} & {
	d: Data
}


function DataServiceServer.init(self: DataServiceServer)
	self._profiles = {}
	self._signallers = {}
	self._initialized = {}
	self._network = Network.Server.new(Utils.NETWORK_NAME, self, self.Get)
	
	self.DataLoaded = Signal.new()
end


function DataServiceServer.Init(self: DataServiceServer, options: Options)
	assert(RunService:IsServer(), "Attempt to init Server DataService on client")
	assert(not self._profileStore, "DataService has been already initialized")
	
	self._options = options
	self._profileStore = ProfileStore.New(options.DatastoreKey, options.Template)
	
	for _, player in Players:GetPlayers() do
		self:onPlayerAdded(player)
	end
	
	Players.PlayerAdded:Connect(function(player: Player)
		self:onPlayerAdded(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player: Player)
		self:onPlayerRemoving(player)
	end)
end


function DataServiceServer.getPlayerKey(self: DataServiceServer, userId: number): string
	return `{userId}`
end


function DataServiceServer.onPlayerAdded(self: DataServiceServer, player: Player)
	local userId = self._options.OverriddenUserId or self._options.ViewedUserId or player.UserId
	local playerKey = self:getPlayerKey(userId)
	
	local profile: Profile
	if self._options.UseMock then
		profile = self._profileStore.Mock:StartSessionAsync(playerKey, storeCancel(player))
	elseif self._options.ViewedUserId or self._options.DontSave then
		profile = self._profileStore:GetAsync(playerKey)
	else
		profile = self._profileStore:StartSessionAsync(playerKey, storeCancel(player))
	end
	
	if not profile then
		player:Kick("Data failed to load - please rejoin.")
		return
	end
	
	profile:AddUserId(userId)
	profile:Reconcile()
	
	profile.OnSessionEnd:Connect(function()
		self._profiles[player] = nil
		player:Kick("Session ended - please rejoin.")
	end)
	
	if not player:IsDescendantOf(Players) then
		player:Kick("Data failed to load - please rejoin.")
		return
	end
	
	self._profiles[player] = profile
	self:initPlayer(player)
	
	if not player:IsDescendantOf(Players) then
		player:Kick("Data failed to load - please rejoin.")
		return
	end
end


function DataServiceServer.onPlayerRemoving(self: DataServiceServer, player: Player)
	if self._signallers[player] then
		self._signallers[player]:Destroy()
	end

	self._signallers[player] = nil
	self._initialized[player] = nil
	
	local profile = self._profiles[player]

	if not profile then
		return
	end
	
	task.defer(function()
		profile:EndSession()
		self._profiles[player] = nil
	end)
end


function DataServiceServer.initPlayer(self: DataServiceServer, player: Player)
	self.onPlayerInit(player, self._profiles[player].Data)
	
	self._signallers[player] = Signaller.new()
	
	self._initialized[player] = false
	self.DataLoaded:Fire(player)
	self._initialized[player] = true
	
	self._network:Fire(Utils.Action.Init, player, self._profiles[player].Data)
end


function DataServiceServer.onPlayerInit(player: Player, data: Data)
	-- override
end


function DataServiceServer.HasData(self: DataServiceServer, player: Player): boolean
	return self._profiles[player] ~= nil
end


function DataServiceServer.Get<T>(self: DataServiceServer, player: Player, path: T): T	
	local pathTable = if getmetatable(path) then path() else path
	
	local current = self._profiles[player].Data
	for _, v in pathTable do
		assert(current[v], `{v} is not key of {current}`)
		current = current[v]
	end
	
	return current
end


function DataServiceServer.Set<T, U>(
	self: DataServiceServer,
	player: Player,
	path: T,
	value: U & equals<T, U>,
	dontReplicate: boolean?
)
	local pathTable = path()
	
	local current = self._profiles[player].Data
	for i = 1, #pathTable - 1 do
		assert(current[pathTable[i]], `{pathTable[i]} is not key of {current}`)
		current = current[pathTable[i]]
	end
	
	current[pathTable[#pathTable]] = value
	self._signallers[player]:FireSet(pathTable, value)
	
	if self._initialized[player] and not dontReplicate then
		self._network:Fire(Utils.Action.Set, player, pathTable, value)
	end
end


function DataServiceServer.Update<T, U>(
	self: DataServiceServer,
	player: Player,
	path: T,
	callback: (U & equals<T, U>) -> U,
	dontReplicate: boolean?
)
	self:Set(player, path, callback(self:Get(player, path)), dontReplicate)
end


function DataServiceServer.Insert<T, U>(
	self: DataServiceServer,
	player: Player,
	path: {T},
	value: U & equals<T, U>,
	index: number?,
	dontReplicate: boolean?
)
	local insertTable = self:Get(player, path)
	
	if index then
		table.insert(insertTable, index, value)
	else
		table.insert(insertTable, value)
	end
	
	self._signallers[player]:FireInsert(path(), index or #insertTable, value)
	
	if self._initialized[player] and not dontReplicate then
		self._network:Fire(Utils.Action.Insert, player, path(), value, index)
	end
end


function DataServiceServer.Remove<T>(
	self: DataServiceServer,
	player: Player,
	path: {T},
	index: number?,
	dontReplicate: boolean?
): T
	local removeTable = self:Get(player, path)
	local value = table.remove(removeTable, index)
	self._signallers[player]:FireRemove(path(), index or #removeTable + 1, value)

	if self._initialized[player] and not dontReplicate then
		self._network:Fire(Utils.Action.Remove, player, path(), index)
	end
	
	return value
end


function DataServiceServer.GetChangedSignal<T>(self: DataServiceServer, player: Player, path: T): Signal.s<T>
	return self._signallers[player]:GetChangedSignal(path())
end


function DataServiceServer.GetKeyChangedSignal<T, U>(self: DataServiceServer, player: Player, path: {[T]: U}): Signal.s<T, U>
	return self._signallers[player]:GetKeyChangedSignal(path())
end


function DataServiceServer.GetInsertSignal<T>(self: DataServiceServer, player: Player, path: {T}): Signal.s<number, T>
	return self._signallers[player]:GetInsertSignal(path())
end


function DataServiceServer.GetRemoveSignal<T>(self: DataServiceServer, player: Player, path: {T}): Signal.s<number, T>
	return self._signallers[player]:GetRemoveSignal(path())
end


DataServiceServer:init()
return DataServiceServer :: DataServiceServer
