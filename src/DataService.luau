local DataServiceClient = require(script.DataServiceClient)
local DataServiceServer = require(script.DataServiceServer)


local DataService = {
	Client = DataServiceClient,
	Server = DataServiceServer
}


return DataService
