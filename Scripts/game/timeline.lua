--- Custom timeline class (it can be used with the game object, but it's disabled by default as it doesn't support increments)
-- @classmod PseudoGame.game.Timeline
PseudoGame.game.Timeline = {}
PseudoGame.game.Timeline.__index = PseudoGame.game.Timeline

--- constructor for a new timeline
-- @tparam function on_empty_function  function that is called once the timeline is empty (should append new things to the timeline) (basically the same as onStep)
-- @treturn Timeline
function PseudoGame.game.Timeline:new(on_empty_function)
	return setmetatable({
		on_empty_function = on_empty_function,
		_timeline = {},
		_finish_time = 0,
		_timer = 0,
		_original_functions = {}
	}, PseudoGame.game.Timeline)
end

--- overwrite the default t_ functions with this timeline
function PseudoGame.game.Timeline:overwrite()
	self._original_functions = {t_eval, t_clear, t_kill, t_wait, t_waitS, t_waitUntilS}
	function t_eval(code)
		self:eval(loadstring(code))
	end
	function t_clear()
		self:clear()
	end
	function t_kill()
		self:eval(t_kill)
	end
	function t_wait(duration)
		self:wait(duration)
	end
	function t_waitS(duration)
		self:wait(duration * 60)
	end
	function t_waitUntilS(duration)
		self:wait_until(duration * 60)
	end
end

--- restore the t_ functions that were present before overwriting
function PseudoGame.game.Timeline:restore()
	t_eval = self._original_functions[1]
	t_clear = self._original_functions[2]
	t_kill = self._original_functions[3]
	t_wait = self._original_functions[4]
	t_waitS = self._original_functions[5]
	t_waitUntilS = self._original_functions[6]
	self._original_functions = {}
end

--- function that is called when the timeline is empty (defined using the parameter in the constructor)
function PseudoGame.game.Timeline:on_empty_function()
end

--- update the timeline
-- @tparam number frametime  time in 1/60s that passed since the last call of this function
function PseudoGame.game.Timeline:update(frametime)
	self._timer = self._timer + frametime / 60
	local finished = false
	while not finished do
		local cmd = self._timeline[1]
		if cmd == nil then
			self:on_empty_function()
			finished = true
		else
			finished = cmd(frametime)
			if not finished then
				table.remove(self._timeline, 1)
			end
		end
	end
end

--- append to the timeline: wait
-- @tparam number time  time in 1/60s to wait until (starts counting from where `Timeline:update` is called for the first time)
function PseudoGame.game.Timeline:wait_until(time)
	self._timeline[#self._timeline + 1] = function(frametime)
		return self._timer < time
	end
end

--- append to the timeline: wait
-- @tparam number time  time in 1/60s to wait
function PseudoGame.game.Timeline:wait(time)
	self._timeline[#self._timeline + 1] = function(frametime)
		time = time - frametime
		return time > 0
	end
end

--- append to the timeline: eval
-- @tparam function func  the function to execute once this is reached
function PseudoGame.game.Timeline:eval(func)
	self._timeline[#self._timeline + 1] = function()
		func()
		return false
	end
end

--- remove all entries from the timeline
function PseudoGame.game.Timeline:clear()
	self._timeline = {}
end
