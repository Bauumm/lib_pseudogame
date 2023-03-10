DeathEffect = {}
DeathEffect.__index = DeathEffect

-- the constructor for a death effect
-- use death_effect.polygon_collection to draw it
-- player: Player / CollidingPlayer	-- the player the death effect is for
-- return: DeathEffect
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

-- this function initializes the death effect for the games actual death screen (should be called in onDeath)
function DeathEffect:death()
	self.rotation_on_death = l_getRotation()
	self.rotation_speed_on_death = l_getRotationSpeed()
	self.real_get_rotation = l_getRotation
	l_getRotation = function()
		return self.rotation_on_death
	end
	self.real_screen_update = screen.update
	screen.update = function(screen)
		local rad_rot = math.rad(self.real_get_rotation() - self.rotation_on_death)
		local sin_rot, cos_rot = math.sin(rad_rot), math.cos(rad_rot)
		for i=1, screen._current_index / 2 do
			local vertices = screen._cw_data[i * 2 - 1]
			for v=1,4 do
				local index = v * 2
				local x, y = vertices[index - 1], vertices[index]
				vertices[index - 1] = x * cos_rot - y * sin_rot
				vertices[index] = x * sin_rot + y * cos_rot
			end
		end
		self.real_screen_update(screen)
	end
	l_setRotationSpeed(self.exploit_rot)
	self.initialized = true
end

-- this function shows the death effect without handling the special workarounds in the games death screen
function DeathEffect:invincible_death()
	self.timer = 100
end

-- update the death effects shape and color
-- frametime: number	-- the time in 1/60s that passed since the last call to this function
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
		local color = get_color_from_hue(360 - self.player_hue)
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
		self.player.color = get_color_from_hue(self.player_hue)
	else
		self.polygon_collection:clear()
		self.player.color = nil
	end
end

-- this function ensures that the given function is called using the games tickrate (240 per second) and should only be called in onRenderStage once the death effect has been initialized (check with death_effect.initialized)
-- func: function	-- the function to call after death, this should contain your drawing logic so the death effect can be rendered
function DeathEffect:ensure_tickrate(func)
	if not self.initialized then
		error("trying to ensure death tick rate without initialization!")
	end
	while l_getRotationSpeed() <= self.exploit_rot * 0.99 do
		self.rotation_speed_on_death = self.rotation_speed_on_death * 0.99
		self.rotation_on_death = (self.rotation_on_death - self.rotation_speed_on_death) % 360
		l_setRotationSpeed(l_getRotationSpeed() / 0.99)
		func(self.frametime)
	end
end
