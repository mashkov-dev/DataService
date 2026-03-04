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
Overridable method which is called before data is sent to client and before any other script starts to modify player data. Doesn't trigger any signals.

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
