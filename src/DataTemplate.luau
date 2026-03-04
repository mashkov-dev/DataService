--[[
	You can move this file wherever you want, just don't forget to update
	paths in both DataServiceClient and DataServiceServer files.
	This file should be accessible by both Client and Server.
]]



local template = {
	Weapons = {} :: {[string]: Blaster}
}


type Blaster = {
	Damage: number
}


export type Data = typeof(template)


return template
