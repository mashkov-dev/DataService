local DataServiceUtils = {}


DataServiceUtils.NETWORK_NAME = "__mashkov"


DataServiceUtils.Action = {
	Init = "0",
	Set = "1",
	Insert = "2",
	Remove = "3"
}


export type function equals(typeA: type, typeB: type)
	assert(typeA == typeB)
	return typeB
end


return DataServiceUtils
