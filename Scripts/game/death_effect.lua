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
		player = player,
		post_death_frametime_accumulator = 0
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
		local gen = self.polygon_collection:generator()
		for i=0, 5 do
			local angle = div * i * 2
			local polygon = gen()
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

-- ensures that a function is called 240 times per second in onRenderStage after death (does nothing if the death method wasn't called)
-- (only works if shaders are loaded, but that is usually the case when using this function as there's no need for a fake death effect if the player isn't hidden)
-- render_stage: number		-- the render stage that onRenderStage is being called for
-- frametime: number		-- the inconsistent frametime that onRenderStage gets as second parameter
-- draw_function: function	-- a function that will be called 240 times per second (should contain your drawing logic so the death effect can be drawn)
function DeathEffect:ensure_tickrate(render_stage, frametime, draw_function)
	if self.dead and render_stage == 0 then
		self.post_death_frametime_accumulator = self.post_death_frametime_accumulator + frametime
		while self.post_death_frametime_accumulator >= 0.25 do
			self.post_death_frametime_accumulator = self.post_death_frametime_accumulator - 0.25
			draw_function(0.25)
		end
	end
end
