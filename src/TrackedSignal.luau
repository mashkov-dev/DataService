local Signal = require(script.Parent.Parent.Packages.Signal)


local TrackedSignal = {
	_connected = {} :: {[s<...any>]: number}
}


export type s<T...> = Signal.s<T...>
type Connection = Signal.Connection


local function getDisconnect(signal: s<...any>, disconnect: (Connection) -> ()): (Connection) -> ()
	return function(self: Connection)
		local connected = self.Connected
		disconnect(self)
		
		if connected then
			TrackedSignal._connected[signal] -= 1
			if TrackedSignal._connected[signal] <= 0 then
				TrackedSignal._connected[signal] = nil
			end
		end
	end
end


function TrackedSignal.new(): s<...any>
	local signal = Signal.new()
	
	local connect = signal.Connect
	local disconnectAll = signal.DisconnectAll
	
	signal.Connect = function(self: s<...any>, callback: (...any) -> ()): Connection		
		local connection = connect(self, callback)
		
		TrackedSignal._connected[signal] = TrackedSignal._connected[signal] or 0
		TrackedSignal._connected[signal] += 1
		
		connection.Disconnect = getDisconnect(signal, connection.Disconnect)
		
		return connection
	end
	
	signal.DisconnectAll = function(self: s<...any>)
		disconnectAll(self)
		TrackedSignal._connected[signal] = nil
	end
	
	return signal
end


return TrackedSignal
