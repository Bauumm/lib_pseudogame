CollidingPlayer = {}
CollidingPlayer.__index = CollidingPlayer

-- the constructor for a player that can handle collisions (without relying on the games internals)
-- use player.polygon to draw it
-- style: Style	-- the style to use (nil will use the default level style)
-- return: CollidingPlayer
function CollidingPlayer:new(style)
	return setmetatable({
		style = style or level_style,
		angle = 0,
		last_angle = 0,
		pos = {0, 0},
		swap_blink_time = 6,
		swap_cooldown_time = math.max(36 * l_getSwapCooldownMult(), 8),
		just_swapped = false,
		polygon = Polygon:new({0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
	}, CollidingPlayer)
end

-- update the players position while handling collisions as well as swap
-- frametime: number				-- the time in 1/60s that passed since the last call of this function
-- move: number					-- the current movement direction, so either -1, 0 or 1
-- focus: bool					-- true if the player is focusing, false otherwise
-- swap: bool					-- true if the swap key is pressed, false otherwise
-- collide_collection: PolygonCollection	-- the collection of polygons the player should collide with
function CollidingPlayer:update(frametime, move, focus, swap, collide_collection)
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
			self.color = get_color_from_hue(self.swap_blink_time * 36)
		else
			self.color = nil
		end
	end
	local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
	local speed = (focus and 4.625 or 9.45) * l_getPlayerSpeedMult() * frametime
	self.angle = self.angle + math.rad(speed * move)
	local x, y = get_orbit(self.angle, radius)
	local collides = false
	local last_collides = false
	local must_kill = false
	for polygon in collide_collection:iter() do
		local is_in = polygon:contains_point(x, y)
		if polygon.extra_data ~= nil and polygon.extra_data.deadly and is_in then
			must_kill = true
		end
		collides = collides or is_in
		if not self.just_swapped then
			last_collides = last_collides or polygon:contains_point(unpack(self.pos))
		end
	end
	if collides then
		if self.just_swapped then
			must_kill = true
		elseif last_collides then
			must_kill = true
		elseif not must_kill then
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
	local size = 7.3 + (focus and -1.5 or 3)
	self.polygon:set_vertex_pos(1, get_orbit(self.angle, 7.3, self.pos))
	self.polygon:set_vertex_pos(2, get_orbit(self.angle - math.rad(100), size, self.pos))
	self.polygon:set_vertex_pos(3, get_orbit(self.angle + math.rad(100), size, self.pos))
	if self.color == nil then
		for i=1,3 do
			self.polygon:set_vertex_color(i, self.style:get_player_color())
		end
	else
		for i=1,3 do
			self.polygon:set_vertex_color(i, unpack(self.color))
		end
	end
end
