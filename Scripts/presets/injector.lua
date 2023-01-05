injector = {
	injected = {}
}

function injector:inject(func_name, func)
	local old_func = _G[func_name]
	if old_func == nil or self.injected[func_name] ~= old_func then
		if old_func == nil then
			_G[func_name] = func
		else
			_G[func_name] = function(...)
				old_func(...)
				func(...)
			end
		end
		self.injected[func_name] = _G[func_name]
	end
end

function injector:wrap(func_name, func)
	local old_func = _G[func_name]
	if old_func == nil or self.injected[func_name] ~= old_func then
		if old_func == nil then
			_G[func_name] = func
		else
			_G[func_name] = function(...)
				return func(old_func, ...)
			end
		end
		self.injected[func_name] = _G[func_name]
	end
end

function injector:update()
	for name, func in pairs(self.injected) do
		if _G[name] ~= func then
			self:inject(name, func)
			return
		end
	end
end

function injector:inject_preset(preset)
	for name, member in pairs(preset) do
		if type(member) == "function" and name:sub(1, 2) == "on" then
			self:inject(name, function(...)
				member(preset, ...)
			end)
		end
	end
	preset:init()
end
