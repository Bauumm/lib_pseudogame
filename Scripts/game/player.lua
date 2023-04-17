--- Class that represents a game's player
-- @classmod PseudoGame.game.Player
PseudoGame.game.Player = {}
PseudoGame.game.Player.__index = PseudoGame.game.Player

--- the constructor for a player that can handle collisions (without relying on the game's internals)
-- @tparam[opt=level_style] Style style  the style to use
-- @tparam[opt=nil] function collision_handler  the collision system to use (nil will make it use the real player, so you'll have to draw cws with collision)
-- @treturn Player
function PseudoGame.game.Player:new(style, collision_handler)
	return setmetatable({
		--- @tfield Style style  the style the player is using
		style = style or PseudoGame.game.level_style,
		--- @tfield number  the player's current angle
		angle = 0,
		--- @tfield number  the angle the player had in the last tick
		last_angle = 0,
		--- @tfield table pos  the current position of the player (formatted like this: {x, y})
		pos = {0, 0},
		--- @tfield table last_pos  the position the player had in the last tick (formatted like this: {x, y})
		last_pos = {0, 0},
		--- @tfield number  a number that indicates the current state of the swap blinking animation (the current blink hue is swap_blink_time * 36)
		swap_blink_time = 6,
		--- @tfield number  the time in 1/60s the player has until it can swap again after swapping
		swap_cooldown_time = math.max(36 * l_getSwapCooldownMult(), 8),
		--- @tfield bool  this field is true if the player swapped this tick, it's false otherwise
		just_swapped = false,
		--- @tfield function  the collision handler the player is currently using
		collision_handler = collision_handler,
		_use_real_player = collision_handler == nil,
		--- @tfield Polygon polygon  the player triangle (use this for drawing)
		polygon = PseudoGame.graphics.Polygon:new({0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
	}, PseudoGame.game.Player)
end

--- reset the swap cooldown to show swap blinking effect (should be called in `onCursorSwap` when using the "real" player)
function PseudoGame.game.Player:reset_swap_cooldown()
	self.just_swapped = true
	self.swap_cooldown_time = self.swap_cooldown
end

--- update the players position while handling collisions as well as swap
-- @tparam number frametime  the time in 1/60s that passed since the last call of this function
-- @tparam[opt] number move  the current movement direction, so either -1, 0 or 1 (only required when using a custom collision handler)
-- @tparam bool focus  true if the player is focusing, false otherwise
-- @tparam[opt] bool swap  true if the swap key is pressed, false otherwise (only required when using a custom collision handler)
-- @tparam[opt] PolygonCollection collide_collection  the collection of polygons the player should collide with (only required when using a custom collision handler)
function PseudoGame.game.Player:update(frametime, move, focus, swap, collide_collection)
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
			self.color = PseudoGame.game.get_color_from_hue(self.swap_blink_time * 36)
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
	self.pos[1], self.pos[2] = PseudoGame.game.get_orbit(self.angle, radius)
	if not self._use_real_player and collide_collection ~= nil then
		if self.collision_handler(self, collide_collection) then
			if self.kill_cw == nil then
				self.kill_cw = PseudoGame.game.cw_function_backup.cw_createDeadly()
			end
			PseudoGame.game.cw_function_backup.cw_setVertexColor4Same(self.kill_cw, 0, 0, 0, 0)
			PseudoGame.game.cw_function_backup.cw_setVertexPos4(self.kill_cw, -1600, -1600, -1600, 1600, 1600, 1600, 1600, -1600)
		else
			if self.kill_cw ~= nil then
				PseudoGame.game.cw_function_backup.cw_destroy(self.kill_cw)
				self.kill_cw = nil
			end
		end
	end
	local size = 7.3 + (focus and -1.5 or 3)
	self.polygon:set_vertex_pos(1, PseudoGame.game.get_orbit(self.angle, 7.3, self.pos))
	self.polygon:set_vertex_pos(2, PseudoGame.game.get_orbit(self.angle - math.rad(100), size, self.pos))
	self.polygon:set_vertex_pos(3, PseudoGame.game.get_orbit(self.angle + math.rad(100), size, self.pos))
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
