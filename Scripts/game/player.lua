Player = {}
Player.__index = Player

function Player:new()
	return setmetatable({
		pos = {0, 0},
		focus = false,
		swap_blink_time = 6,
		swap_cooldown_time = math.max(36 * l_getSwapCooldownMult(), 8),
		polygon = Polygon:new({0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
	}, Player)
end

function Player:swap()
	self.swap_cooldown_time = self.swap_cooldown
end

function Player:update(frametime, focus)
	if focus ~= nil then
		self.focus = focus
	end
	if l_getSwapEnabled() then
		self.swap_cooldown = math.max(36 * l_getSwapCooldownMult(), 8)
		self.swap_cooldown_time = self.swap_cooldown_time - frametime
		if self.swap_cooldown_time < 0 then
			self.swap_cooldown_time = 0
			self.swap_blink_time = (self.swap_blink_time + frametime / 3.6) % 2
			self.color = style.get_color_from_hue(self.swap_blink_time * 36)
		else
			self.color = nil
		end
	end
	local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
	local angle = u_getPlayerAngle()
	if angle ~= angle then
		angle = self.last_angle
		u_setPlayerAngle(angle)
	end
	self.last_angle = angle
	local size = 7.3 + (self.focus and -1.5 or 3)
	self.pos[1], self.pos[2] = get_orbit(angle, radius)
	self.polygon:set_vertex_pos(1, get_orbit(angle, 7.3, self.pos))
	self.polygon:set_vertex_pos(2, get_orbit(angle - math.rad(100), size, self.pos))
	self.polygon:set_vertex_pos(3, get_orbit(angle + math.rad(100), size, self.pos))
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
