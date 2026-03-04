local Path = {
	__index = function(self, key)
		
		local path = {
			__mashkov = {key},
			
			__index = function(self, key)
				table.insert(self.__mashkov, key)
				return self
			end,
			
			__call = function(self)
				return self.__mashkov
			end,
		}
		
		return setmetatable(path, path)
	end,
	
	__call = function()
		return {}
	end,
}


setmetatable(Path, Path)
return Path
