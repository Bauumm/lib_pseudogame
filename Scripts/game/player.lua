Player = {}
Player.__index = Player

-- the constructor for a player that can handle collisions (without relying on the games internals)
-- use player.polygon to draw it
-- style: Style (optional)			-- the style to use (nil will use the default level style)
-- collision_handler: function	(optional)	-- the collision system to use (nil will make it use the real player, so you'll have to draw cws with collision)
-- return: Player
function Player:new(style, collision_handler)
	return setmetatable({
		style = style or level_style,
		angle = 0,
		last_angle = 0,
		pos = {0, 0},
		last_pos = {0, 0},
		swap_blink_time = 6,
		swap_cooldown_time = math.max(36 * l_getSwapCooldownMult(), 8),
		just_swapped = false,
		collision_handler = collision_handler,
		_use_real_player = collision_handler == nil,
		polygon = Polygon:new({0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
	}, Player)
end

-- reset the swap cooldown to show swap blinking effect (should be called in onCursorSwap when using the "real" player)
function Player:reset_swap_cooldown()
	self.just_swapped = true
	self.swap_cooldown_time = self.swap_cooldown
end

-- update the players position while handling collisions as well as swap
-- frametime: number						-- the time in 1/60s that passed since the last call of this function
-- move: number	(optional)					-- the current movement direction, so either -1, 0 or 1 (only required when using a custom collision handler)
-- focus: bool							-- true if the player is focusing, false otherwise
-- swap: bool	(optional)					-- true if the swap key is pressed, false otherwise (only required when using a custom collision handler)
-- collide_collection: PolygonCollection	(optional)	-- the collection of polygons the player should collide with (only required when using a custom collision handler)
function Player:update(frametime, move, focus, swap, collide_collection)
	if l_getSwapEnabled() then
		self.just_swapped = false
		self.swap_cooldown = math.max(36 * l_getSwapCooldownMult(), 8)
		self.swap_cooldown_time = self.swap_cooldown_time - frametime
		if not self._use_real_player then
			if self.swap_cooldown_time <= 0 and swap then
				self.swap_cooldown_time = self.swap_cooldown
				self.angle = self.angle + math.pi
				self.just_swapped = true
			end
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
	self.last_angle = self.angle
	for i=1, 2 do
		self.last_pos[i] = self.pos[i]
	end
	if self._use_real_player then
		self.angle = u_getPlayerAngle()
		-- work around cw collision bug where player angle becomes nan
		if self.angle ~= self.angle then
			self.angle = self.last_angle
			u_setPlayerAngle(self.angle)
		end
	else
		local speed = (focus and 4.625 or 9.45) * l_getPlayerSpeedMult() * frametime
		self.angle = self.angle + math.rad(speed * move)
	end
	self.pos[1], self.pos[2] = get_orbit(self.angle, radius)
	if not self._use_real_player then
		if self.collision_handler(self, collide_collection) then
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
	end
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
