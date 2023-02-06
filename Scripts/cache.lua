Cache = {}
Cache.__index = Cache

function Cache:new(func, obj)
	return setmetatable({func = func, obj = obj}, Cache)
end

function Cache:__call()
	if self.value == nil then
		self.value = self.func(self.obj)
	end
	return self.value
end

function Cache:invalidate()
	self.value = nil
end
