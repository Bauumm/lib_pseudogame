CollidingPlayer = {}
CollidingPlayer.__index = CollidingPlayer

function CollidingPlayer:new()
	return setmetatable({
		angle = 0,
		focus = false,
		last_angle = 0,
		pos = {0, 0},
		swap_blink_time = 6,
		swap_cooldown_time = math.max(36 * l_getSwapCooldownMult(), 8),
		just_swapped = false,
		polygon = Polygon:new({0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
	}, CollidingPlayer)
end

function CollidingPlayer:update(frametime, move, focus, swap, collide_collection)
	if focus ~= nil then
		self.focus = focus
	end
	if frametime ~= nil then
		if l_getSwapEnabled() then
			self.swap_cooldown = math.max(36 * l_getSwapCooldownMult(), 8)
			self.swap_cooldown_time = self.swap_cooldown_time - frametime
			if self.swap_cooldown_time <= 0 and swap then
				self.swap_cooldown_time = self.swap_cooldown
				self.angle = self.angle + math.pi
				self.just_swapped = true
			else
				self.just_swapped = false
			end
			if self.swap_cooldown_time < 0 then
				self.swap_cooldown_time = 0
				self.swap_blink_time = (self.swap_blink_time + frametime / 3.6) % 2
				self.color = style.get_color_from_hue(self.swap_blink_time * 36)
			else
				self.color = nil
			end
		end
		local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
		local speed = (self.focus and 4.625 or 9.45) * l_getPlayerSpeedMult() * frametime
		self.angle = self.angle + math.rad(speed * move)
		local x, y = get_orbit(self.angle, radius)
		local collides = false
		local last_collides = false
		for polygon in collide_collection:iter() do
			collides = collides or polygon:contains_point(x, y)
			if not self.just_swapped then
				last_collides = last_collides or polygon:contains_point(unpack(self.pos))
			end
		end
		local must_kill = false
		if collides then
			if self.just_swapped then
				must_kill = true
			elseif last_collides then
				must_kill = true
			else
				x, y = unpack(self.pos)
				self.angle = self.last_angle
			end
		end
		if must_kill then
			if self.kill_cw == nil then
				self.kill_cw = cw_function_backup.cw_createDeadly()
			end
			cw_function_backup.cw_setVertexColor4Same(self.kill_cw, 0, 0, 0, 0)
			cw_function_backup.cw_setVertexPos4(self.kill_cw, -1600, -1600, -1600, 1600, 1600, 1600, 1600, -1600)
		else
			if self.kill_cw ~= nil then
				cw_function_backup.cw_destroy(self.kill_cw)
				self.kill_cw = nil
			end
		end
		self.last_angle = self.angle
		self.pos[1], self.pos[2] = x, y
	end
	local size = 7.3 + (self.focus and -1.5 or 3)
	self.polygon:set_vertex_pos(1, get_orbit(self.angle, 7.3, self.pos))
	self.polygon:set_vertex_pos(2, get_orbit(self.angle - math.rad(100), size, self.pos))
	self.polygon:set_vertex_pos(3, get_orbit(self.angle + math.rad(100), size, self.pos))
	if self.color == nil then
		for i=1,3 do
			self.polygon:set_vertex_color(i, style:get_main_color())
		end
	else
		for i=1,3 do
			self.polygon:set_vertex_color(i, unpack(self.color))
		end
	end
end
