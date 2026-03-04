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

`type Options = {`
`  Template: any` fff
`

`DataService`
