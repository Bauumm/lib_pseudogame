u_execScript("game_system/render.lua")
u_execScript("game_system/math.lua")

death_effect = {}
death_effect.__index = death_effect

function death_effect:new(player)
	return setmetatable({
		cws = {},
		player_hue = 0,
		initialized = false,
		rotation_on_death = 0,
		rotation_speed_on_death = 0,
		transform = nil,
		timer = 0,
		player = player,
		real_get_rotation = nil,
		exploit_rot = 100
	}, death_effect)
end

function death_effect:death()
	self.rotation_on_death = l_getRotation()
	self.rotation_speed_on_death = l_getRotationSpeed()
	self.real_get_rotation = l_getRotation
	l_getRotation = function()
		return self.rotation_on_death
	end
	l_setRotationSpeed(self.exploit_rot)
	self.initialized = true
end

function death_effect:invincible_death()
	self.timer = 100
end

function death_effect:update(frametime)
	self.timer = self.timer - frametime
	if self.timer < 0 then
		self.timer = 0
	end
end

function death_effect:draw_main(main_layer)
	layers:select()
	if self.initialized then
		main_layer:draw_transformed(self.transform)
	else
		main_layer:draw()
	end
	layers:refresh()
end

function death_effect:ensure_tickrate(func)
	if not self.initialized then
		error("trying to ensure death tick rate without initialization!")
	end
	while l_getRotationSpeed() <= self.exploit_rot * 0.99 do
		self.rotation_speed_on_death = self.rotation_speed_on_death * 0.99
		local rad_rot = math.rad(self.real_get_rotation() - self.rotation_on_death)
		local sin_rot, cos_rot = math.sin(rad_rot), math.cos(rad_rot)
		self.transform = function(x, y, r, g, b, a)
			local new_x = x * cos_rot - y * sin_rot
			local new_y = x * sin_rot + y * cos_rot
			return new_x, new_y, r, g, b, a
		end
		self.rotation_on_death = (self.rotation_on_death - self.rotation_speed_on_death) % 360
		l_setRotationSpeed(l_getRotationSpeed() / 0.99)
		func()
	end
end

function death_effect:render()
	if self.initialized or self.timer > 0 then
		_reserve_cws(self.cws, 7)
		self.player_hue = self.player_hue + 18 * 0.25
		if self.player_hue > 360 then
			self.player_hue = 0
		end
		local div = math.pi / 6
		local radius = self.player_hue / 8
		local thickness = self.player_hue / 20
		local color = style.get_color_from_hue(360 - self.player_hue)
		for i=0, 5 do
			local angle = div * i * 2
			local vertices = {}
			vertices[1], vertices[2] = get_orbit(angle - div, radius, self.player.pos)
			vertices[3], vertices[4] = get_orbit(angle + div, radius, self.player.pos)
			vertices[5], vertices[6] = get_orbit(angle + div, radius + thickness, self.player.pos)
			vertices[7], vertices[8] = get_orbit(angle - div, radius + thickness, self.player.pos)
			local cw = self.cws[i + 1]
			cw_setVertexPos4(cw, unpack(vertices))
			cw_setVertexColor4Same(cw, unpack(color))
		end
		local player_cw = self.player.cw
		self.player.cw = self.cws[7]
		self.player.color = style.get_color_from_hue(self.player_hue)
		self.player:render()
		self.player.color = nil
		self.player.cw = player_cw
	else
		if #self.cws ~= 0 then
			for i=1, #self.cws do
				local cw = self.cws[i]
				cw_setVertexPos4(cw, 0, 0, 0, 0, 0, 0, 0, 0)
				cw_setVertexColor4Same(cw, 0, 0, 0, 0)
			end
		end
	end
end
