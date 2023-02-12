DeathEffect = {}
DeathEffect.__index = DeathEffect

function DeathEffect:new(player)
	return setmetatable({
		polygon_collection = PolygonCollection:new(),
		player_hue = 0,
		initialized = false,
		rotation_on_death = 0,
		rotation_speed_on_death = 0,
		transform = nil,
		timer = 0,
		player = player,
		real_get_rotation = nil,
		exploit_rot = 100,
		frametime = 0
	}, DeathEffect)
end

function DeathEffect:death()
	self.rotation_on_death = l_getRotation()
	self.rotation_speed_on_death = l_getRotationSpeed()
	self.real_get_rotation = l_getRotation
	l_getRotation = function()
		return self.rotation_on_death
	end
	self.real_screen_update = screen.update
	self.real_collection = PolygonCollection:new()
	screen.update = function(screen, polygon_collection)
		self.real_collection:clear()
		for polygon in polygon_collection:iter() do
			local transformed_poly = polygon:copy()
			transformed_poly:transform(self.transform)
			self.real_collection:add(transformed_poly)
		end
		self.real_screen_update(screen, self.real_collection)
	end
	l_setRotationSpeed(self.exploit_rot)
	self.initialized = true
end

function DeathEffect:invincible_death()
	self.timer = 100
end

function DeathEffect:update(frametime)
	self.frametime = frametime
	self.timer = self.timer - frametime
	if self.timer < 0 then
		self.timer = 0
	end
	if self.initialized or self.timer > 0 then
		if self.polygon_collection:get(1) == nil then
			for i=1,6 do
				self.polygon_collection:add(Polygon:new({0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}))
			end
		end
		self.player_hue = self.player_hue + 18 * frametime
		if self.player_hue > 360 then
			self.player_hue = 0
		end
		local div = math.pi / 6
		local radius = self.player_hue / 8
		local thickness = self.player_hue / 20
		local color = style.get_color_from_hue(360 - self.player_hue)
		local it = self.polygon_collection:iter()
		for i=0, 5 do
			local angle = div * i * 2
			local polygon = it()
			polygon:set_vertex_pos(1, get_orbit(angle - div, radius, self.player.pos))
			polygon:set_vertex_pos(2, get_orbit(angle + div, radius, self.player.pos))
			polygon:set_vertex_pos(3, get_orbit(angle + div, radius + thickness, self.player.pos))
			polygon:set_vertex_pos(4, get_orbit(angle - div, radius + thickness, self.player.pos))
			for i=1,4 do
				polygon:set_vertex_color(i, unpack(color))
			end
		end
		self.player.color = style.get_color_from_hue(self.player_hue)
	else
		self.polygon_collection:clear()
		self.player.color = nil
	end
end

function DeathEffect:ensure_tickrate(func)
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
		func(self.frametime)
	end
end
