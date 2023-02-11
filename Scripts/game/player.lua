player = {}
player.__index = player

function player:new()
	return setmetatable({
		pos = {0, 0},
		swap_blink_time = 6,
		swap_cooldown_time = 0,
		focus = false
	}, player)
end

function player:swap()
	self.swap_cooldown_time = self.swap_cooldown
end

function player:update(frametime, focus)
	self.focus = focus
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
end

function player:render()
	if self.cw == nil then
		self.cw = cw_createNoCollision()
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
	local vertices = {}
	vertices[1], vertices[2] = get_orbit(angle, 7.3, self.pos)
	vertices[3], vertices[4] = get_orbit(angle, 7.3, self.pos)
	vertices[5], vertices[6] = get_orbit(angle - math.rad(100), size, self.pos)
	vertices[7], vertices[8] = get_orbit(angle + math.rad(100), size, self.pos)
	cw_setVertexPos4(self.cw, unpack(vertices))
	if self.color == nil then
		cw_setVertexColor4Same(self.cw, style:get_main_color())
	else
		cw_setVertexColor4Same(self.cw, unpack(self.color))
	end
end
