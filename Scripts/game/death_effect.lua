DeathEffect = {}
DeathEffect.__index = DeathEffect

-- the constructor for a death effect
-- use death_effect.polygon_collection to draw it
-- player: Player	-- the player the death effect is for
-- return: DeathEffect
function DeathEffect:new(player)
	return setmetatable({
		polygon_collection = PolygonCollection:new(),
		player_hue = 0,
		dead = false,
		transform = nil,
		timer = 0,
		player = player
	}, DeathEffect)
end

-- this function causes the death effect ot be shown permanently (should be called in onDeath)
-- make sure to update and draw the death effect in onRenderStage as the other functions aren't called after death
function DeathEffect:death()
	self.dead = true
end

-- this function shows the death effect for a moment (should be called in onPreDeath)
function DeathEffect:invincible_death()
	self.timer = 100
end

-- update the death effects shape and color
-- frametime: number	-- the time in 1/60s that passed since the last call to this function
function DeathEffect:update(frametime)
	self.timer = self.timer - frametime
	if self.timer < 0 then
		self.timer = 0
	end
	if self.dead or self.timer > 0 then
		self.player_hue = self.player_hue + 18 * frametime
		if self.player_hue > 360 then
			self.player_hue = 0
		end
		local div = math.pi / 6
		local radius = self.player_hue / 8
		local thickness = self.player_hue / 20
		local color = get_color_from_hue(360 - self.player_hue)
		local it = self.polygon_collection:creation_iter()
		for i=0, 5 do
			local angle = div * i * 2
			local polygon = it()
			polygon:resize(4)
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
