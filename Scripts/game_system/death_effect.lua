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
		timer = 0,
		player = player
	}, death_effect)
end

function death_effect:death()
	self.rotation_on_death = l_getRotation()
	l_setRotationSpeed(1000000)
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

function death_effect:ensure_tickrate(func)
	if not self.initialized then
		error("trying to ensure death tick rate without initialization!")
	end
	l_setRotation(self.rotation_on_death)
	while l_getRotationSpeed() <= 990000 do
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
