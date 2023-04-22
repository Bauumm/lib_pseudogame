--- Class that handles a game's walls by implementing `w_wall`, `w_wallAdj` and `w_wallAcc`
-- @classmod PseudoGame.game.WallSystem

-- ensure the w_ functions don't get overwritten by executing this file multiple times
if PseudoGame.game.WallSystem == nil then
	PseudoGame.game.WallSystem = {
		_systems = {},
		_selected_system = nil,
		_w_wall = w_wall,
		_w_wallAdj = w_wallAdj,
		_w_wallAcc = w_wallAcc,
		_w_wallHModSpeedData = w_wallHModSpeedData,
		_w_wallHModCurveData = w_wallHModCurveData,
		_u_clearWalls = u_clearWalls,
		_has_real_wall = false
	}
	PseudoGame.game.WallSystem.__index = PseudoGame.game.WallSystem
end

--- the constructor for a wall system
-- @tparam[opt=level_style] Style style  the style to use
-- @treturn WallSystem
function PseudoGame.game.WallSystem:new(style)
	local obj = setmetatable({
		--- @tfield Style  the style the wall system is using
		style = style or PseudoGame.game.level_style,
		_walls = {},
		--- @tfield PolygonCollection  the collection of polygons representing the walls (use this for drawing)
		polygon_collection = PseudoGame.graphics.PolygonCollection:new()
	}, PseudoGame.game.WallSystem)
	PseudoGame.game.WallSystem._systems[#PseudoGame.game.WallSystem._systems + 1] = obj
	return obj
end

--- create a wall in the system
-- @tparam[opt=0] number hue_modifier  the modifier the hue of the wall will be adjusted by
-- @tparam number side  the side to spawn the wall at
-- @tparam number thickness  the thickness the wall should have
-- @tparam[opt=1] number speed_mult  the speed_mult (will be multiplied with u_getSpeedMultDM())
-- @tparam[opt=0] number acceleration  the acceleration (it will be adjusted using the difficulty mult)
-- @tparam[opt=0] number min_speed  the minimum speed the wall should have (will be multiplied with u_getSpeedMultDM())
-- @tparam[opt=0] number max_speed  the maximum speed the wall should have (will be multiplied with u_getSpeedMultDM())
-- @tparam[opt=false] bool ping_pong  will bounce between max and min speed if true
-- @tparam[opt=false] bool curving  will make the wall a curving wall if true (uses speed_mult, acceleration, min/max_speed for curve speed instead of wall speed)
function PseudoGame.game.WallSystem:wall(hue_modifier, side, thickness, speed_mult, acceleration, min_speed, max_speed, ping_pong, curving)
	hue_modifier = hue_modifier or 0
	side = math.floor(side)
	speed_mult = speed_mult or 1
	acceleration = acceleration or 0
	min_speed = min_speed or 0
	max_speed = max_speed or 0
	local distance = l_getWallSpawnDistance()
	local div = math.pi / l_getSides()
	local angle = div * 2 * side
	local polygon = PseudoGame.graphics.Polygon:new()
	polygon:add_vertex(PseudoGame.game.get_orbit(angle - div, distance))
	polygon:add_vertex(PseudoGame.game.get_orbit(angle + div, distance))
	polygon:add_vertex(PseudoGame.game.get_orbit(angle + div + l_getWallAngleLeft(), distance + thickness + l_getWallSkewLeft()))
	polygon:add_vertex(PseudoGame.game.get_orbit(angle - div + l_getWallAngleRight(), distance + thickness + l_getWallSkewRight()))
	if not curving then
		speed_mult = speed_mult * u_getSpeedMultDM()
	end
	table.insert(self._walls, {
		polygon = self.polygon_collection:add(polygon),
		speed = speed_mult,
		accel = acceleration / (u_getDifficultyMult() ^ 0.65),
		min_speed = min_speed * u_getSpeedMultDM(),
		max_speed = max_speed * u_getSpeedMultDM(),
		hue_modifier = hue_modifier,
		ping_pong = ping_pong and -1 or 1,
		old_speed_dm = u_getSpeedMultDM(),	-- used for curving walls actual speed
		curving = curving
	})
end

--- update the walls position
-- @tparam number frametime  the time in 1/60s that passed since the last call of this function
function PseudoGame.game.WallSystem:update(frametime)
	local half_radius = 0.5 * (l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse())
	local outer_bounds = l_getWallSpawnDistance() * 1.1
	local del_queue = {}
	for i, wall in pairs(self._walls) do
		if wall.accel ~= 0 then
			wall.speed = wall.speed + wall.accel * frametime
			if wall.speed > wall.max_speed then
				wall.speed = wall.max_speed
				wall.accel = wall.accel * wall.ping_pong
			elseif wall.speed < wall.min_speed then
				wall.speed = wall.min_speed
				wall.accel = wall.accel * wall.ping_pong
			end
		end
		local points_on_center = 0
		local points_out_of_bounds = 0
		local polygon = self.polygon_collection:get(wall.polygon)
		for vertex=1,4 do
			local x, y = polygon:get_vertex_pos(vertex)
			local x_dist, y_dist = math.abs(x), math.abs(y)
			if x_dist > outer_bounds or y_dist > outer_bounds then
				points_out_of_bounds = points_out_of_bounds + 1
			end
			if x_dist < half_radius and y_dist < half_radius then
				points_on_center = points_on_center + 1
			else
				local magnitude = math.sqrt(x ^ 2 + y ^ 2)
				local move_distance
				if wall.curving then
					move_distance = wall.old_speed_dm * 5 * frametime
				else
					move_distance = wall.speed * 5 * frametime
				end
				polygon:set_vertex_pos(vertex, x - x / magnitude * move_distance, y - y / magnitude * move_distance)
			end
			if wall.hue_modifier == 0 then
				polygon:set_vertex_color(vertex, self.style:get_wall_color())
			else
				polygon:set_vertex_color(vertex, PseudoGame.game.transform_hue(wall.hue_modifier, self.style:get_wall_color()))
			end
		end
		if points_on_center == 4 or points_out_of_bounds == 4 then
			table.insert(del_queue, 1, i)
			self.polygon_collection:remove(wall.polygon)
		end
		if wall.curving and wall.speed ~= 0 then
			polygon:transform(PseudoGame.graphics.effects:rotate(wall.speed / 60 * frametime))
		end
	end
	for _, i in pairs(del_queue) do
		table.remove(self._walls, i)
	end
	local no_walls = true
	for i=1,#self._systems do
		local system = self._systems[i]
		no_walls = no_walls and #system._walls == 0
	end
	if no_walls and self._has_real_wall then
		self._u_clearWalls()
		PseudoGame.game.WallSystem._has_real_wall = false
	end
	if not no_walls and not self._has_real_wall then
		PseudoGame.game.WallSystem._has_real_wall = true
		self._w_wallAdj(0, 0, 0)
	end
end

--- overwrite the `w_wall`, `w_wallAdj`, `w_wallAcc` and `u_clearWalls` functions to create/clear walls in this system
function PseudoGame.game.WallSystem:overwrite()
	if not u_inMenu() then
		PseudoGame.game.WallSystem._selected_system = self
		w_wall = function(side, thickness)
			t_eval("PseudoGame.game.WallSystem._selected_system:wall(0, " .. side .. ", " .. thickness .. ")")
		end
		w_wallAdj = function(side, thickness, speed_mult)
			t_eval("PseudoGame.game.WallSystem._selected_system:wall(0, " .. side .. ", " .. thickness .. ", " .. speed_mult .. ")")
		end
		w_wallAcc = function(side, thickness, speed_mult, acceleration, min_speed, max_speed)
			t_eval("PseudoGame.game.WallSystem._selected_system:wall(0, " .. side .. ", " .. thickness .. ", " .. speed_mult .. ", " .. acceleration .. ", " .. min_speed .. ", " .. max_speed .. ")")
		end
		w_wallHModSpeedData = function(hue_modifier, side, thickness, speed_mult, acceleration, min_speed, max_speed, ping_pong)
			t_eval("PseudoGame.game.WallSystem._selected_system:wall(" .. hue_modifier .. ", " .. side .. ", " .. thickness .. ", " .. speed_mult .. ", " .. acceleration .. ", " .. min_speed .. ", " .. max_speed .. ", " .. (ping_pong and "true" or "false") .. ")")
		end
		w_wallHModCurveData = function(hue_modifier, side, thickness, speed_mult, acceleration, min_speed, max_speed, ping_pong)
			t_eval("PseudoGame.game.WallSystem._selected_system:wall(" .. hue_modifier .. ", " .. side .. ", " .. thickness .. ", " .. speed_mult .. ", " .. acceleration .. ", " .. min_speed .. ", " .. max_speed .. ", " .. (ping_pong and "true" or "false") .. ", true)")
		end
		u_clearWalls = function()
			for i=1, #self._walls do
				local wall = self._walls[i]
				cw_destroy(wall.cw)
			end
			self._walls = {}
		end
	end
end

--- restore the original `w_wall`, `w_wallAdj`, `w_wallAcc` and `u_clearWalls` functions
function PseudoGame.game.WallSystem:restore()
	w_wall = self._w_wall
	w_wallAdj = self._w_wallAdj
	w_wallAcc = self._w_wallAcc
	w_wallHModSpeedData = self._w_wallHModSpeedData
	w_wallHModCurveData = self._w_wallHModCurveData
	u_clearWalls = self._u_clearWalls
end
