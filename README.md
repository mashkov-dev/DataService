<div align="center">

# DataService

## Small player's data handler with autocomplete and typechecking.

</div>

DataService is a Roblox module which handles data of your players. It takes DataStore management from [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore), simple API and data replication from [leif`s DataService](https://github.com/leifstout/dataService) and adds on top of it autocomplete and typechecking which makes it really easy to use in any game.


## Setup

To setup DataService, put it into ReplicatedStorage. Then open `DataTemplate` module and change template to your needs. You can move this file to whatever place you want, but don't forget to update paths in other files and put the file itself in the shared container (we will need it for autocomplete and typechecking). Require DataService on server and initialize it using `:Init(options)` function.


## Requiring DataService

To require DataService, use the following syntax:

```lua
local DataService = require(Path.To.DataService).Client
local d = DataService.d
```

```lua
local DataService = require(Path.To.DataService).Server
local d = DataService.d
```

"d" (shortened from "data") is "autocompleter" which is used to pass data path into methods.

## Server API

`type Options = {`<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`Template: any` — table that contains template of data<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`DatastoreKey: string` — key which will be used in ProfileStore<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`UseMock: boolean?` — use empty Profile (for testing)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`DontSave: boolean?` — don't apply changes to data (for testing)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`ViewedUserId: number?` — play on data of user with id `userId`, but don't apply changes to it (for debugging)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`OverridenUserId: number?` — play on data of user with id `userId` and apply changes to it (for debugging)<br>

#### `DataService:Init(options: Options): ()`
Initializes DataService on server.

```lua
DataService:Init({
	Template = DataTemplate,
	DatastoreKey = "Test"
})
```

> [!WARNING]
> If you have empty tables in DataTemplate you should need to explicitly set their types for typechecking to work correctly:
> ```lua
>local template = {
>	Coins = 0,
>	Weapons = {} :: {string},
>	Friends = {} :: {[string]: number}
>}
>```
---
`type Data = typeof(d)`
#### `DataService.onPlayerInit(player: Player, data: Data): ()`
Overridable method which is called before data is sent to client and before any other script starts to modify player data. Doesn't trigger any signals. Empty by default.

> [!NOTE]
> It is recommended to use `onPlayerInit(...)` only for testing when you want to tweak some values in player data before client and other scripts access it. Use `DataLoaded` signal instead if you want to modify data of a player before it will be sent to him.

> [!CAUTION]
> Override this method before calling `:Init(...)` and use only "raw" data (don't call any API methods such as `:Get(...)`, `:Set(...)`, `:Update(...)` etc).

```lua
type Data = typeof(d)

DataService.onPlayerInit = function(player: Player, data: Data)
	data.Coins = 5
	table.insert(data.Weapons, "Blaster")
end
```
---
#### `DataService.Get<T>(self: DataService, player: Player, path: T): T`
Returns data of `player` on path `path`. You can also index path with different values. And you will still get autocomplete and typechecking.

```lua
local coins = DataService:Get(d.Coins)

local uniqueId = "reg3#./sap"
local blasterDamage = DataService:Get(d.Blasters[uniqueId].Damage)

local firstItem = DataService:Get(d.Items[1])
```
---
#### `DataService.Set<T>(self: DataService, player: Player, path: T, value: T, dontReplicate: boolean?): ()`
Sets value to `value` in data of player `player` on path `path`. Change will not be replicated to client if `dontReplicate` is set to `true`.

```lua
DataService:Set(player, d.Coins, 500)


local blaster = {
	Damage = 300
}

DataService:Set(player, d.Weapons["Blaster"], blaster)
```
---
#### `DataService.Update<T>(self: DataService, player: Player, path: T, callback: (T) -> T, dontReplicate: boolean?): ()`
Sets value to `callback(value)` (where `value` is current value) in data of player `player` on path `path`. Change will not be replicated to client if `dontReplicate` is set to `true`.

```lua
DataService:Update(player, d.Coins, function(coins: number)
	return coins + 10
end)
```
---
#### `DataService.Insert<T>(self: DataService, player: Player, path: {T}, value: T, index: number?, dontReplicate: boolean?): ()`
Inserts value `value` in index `index` into array on path `path`. Change will not be replicated to client if `dontReplicate` is set to `true`.

```lua
DataService:Insert(player, d.FriendIds, 125252232342)
```
---
#### `DataService.Remove<T>(self: DataService, player: Player, path: {T}, index: number?, dontReplicate: boolean?): T`
Removes value in index `index` from array on path `path`. Returns removed value. Change will not be replicated to client if `dontReplicate` is set to `true`.

```lua
local friendId = DataService:Remove(player, d.FriendIds)
```
---
#### `DataService.HasData(self: DataService, player: Player): boolean`
Returns `true` is there is data related to player `player`.

```lua
local hasData = DataService:HasData(player)
```
---
#### `DataService.GetChangedSignal<T>(self: DataService, player: Player, path: T): Signal<T>`
Returns signal which is fired when `DataService:Set(player, path, ...)` or `DataService:Update(player, path, ...)` was called. Callback receives new value of data on path `path`.

```lua
DataService:GetChangedSignal(player, d.Coins):Connect(function(coins: number)
	print(coins) -- 100
end)

DataService:Set(player, d.Coins, 100)
```
---
#### `DataService.GetKeyChangedSignal<T, U>(self: DataService, player: Player, path: {[T]: U}): Signal<T, U>`
Returns signal which is fired when `DataService:Set(player, path[key], ...)` or `DataService:Update(player, path[key], ...)` was called. Callback receives `key` and new value of data on path `path[key]`.

```lua
DataService:GetKeyChangedSignal(player, d.Blasters):Connect(function(blasterId: string, blaster: Blaster)
	print(blasterId, blaster) -- uniqueId, {Damage = 300}

end)


local blaster = {
	Damage = 300
}

DataService:Set(player, d.Blasters[uniqueId], blaster)
```
---
#### `DataService.GetInsertSignal<T>(self: DataService, player: Player, path: {T}): Signal<number, T>`
Returns signal which is fired when `DataService:Insert(player, path, ...)` was called. Callback receives index of inserted value and this value itself.

```lua
DataService:GetInsertSignal(player, d.FriendIds):Connect(function(index: number, friendId: number)
	print(index, friendId) -- index, 212121131
end)


DataService:Insert(player, d.FriendIds, 212121131)
```
---
#### `DataService.GetRemoveSignal<T>(self: DataService, player: Player, path: {T}): Signal<number, T>`
Returns signal which is fired when `DataService:Remove(player, path, ...)` was called. Callback receives index of removed value and this value itself.

```lua
DataService:GetRemoveSignal(player, d.FriendIds):Connect(function(index: number, friendId: number)
	print(index, friendId) -- 3, value
end)


local value = DataService:Remove(player, d.FriendIds, 3)
```
---
#### `DataService.DataLoaded: Signal<Player>`
Returns signal which is fired AFTER `.onPlayerInit(player, data)` finished its execution but BEFORE data was sent to client. Use API methods such as `:Get(...)`, `:Set(...)`, `:Update(...)` etc. to read/write into the data before it will be sent to client. Only server-side data signals will react to this changes.
> [!NOTE]
> If connected callback yields, data changes related to it will arrive to client as "updates", not as a part of initial data.

```lua
DataService.DataLoaded:Connect(function(player: Player)
	if os.clock() - DataService:Get(player, d.DailyGift.LastClaim) > DAY then
		DataService:Update(player, d.DailyGift.Day, function(day: number)
			return day + 1
		end)
	end
end)
```
> [!NOTE]
> If you want to change data right before player leaves, just change it on `PlayerRemoving` event. Currently I simply defer removing Profile of player when `PlayerRemoving` is fired. Make sure that your `PlayerRemoving` callback doesn't yield.
