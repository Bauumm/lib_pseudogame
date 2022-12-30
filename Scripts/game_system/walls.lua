u_execScript("game_system/math.lua")

walls = {
	walls = {},
	has_fake_wall = false
}

function walls:wall(side, thickness, speed_mult, acceleration, min_speed, max_speed)
	side = math.floor(side)
	speed_mult = speed_mult or 1
	acceleration = acceleration or 0
	min_speed = min_speed or 0
	max_speed = max_speed or 0
	local distance = l_getWallSpawnDistance()
	local div = math.pi / l_getSides()
	local angle = div * 2 * side
	local vertices = {}
	vertices[1], vertices[2] = get_orbit(angle - div, distance)
	vertices[3], vertices[4] = get_orbit(angle + div, distance)
	vertices[5], vertices[6] = get_orbit(angle + div + l_getWallAngleLeft(), distance + thickness + l_getWallSkewLeft())
	vertices[7], vertices[8] = get_orbit(angle - div + l_getWallAngleRight(), distance + thickness + l_getWallSkewRight())
	local cw = cw_create()
	cw_setVertexPos4(cw, unpack(vertices))
	table.insert(self.walls, {
		cw = cw,
		speed = speed_mult * u_getSpeedMultDM(),
		accel = acceleration,
		min_speed = min_speed,
		max_speed = max_speed
	})
end

function walls:update(frametime)
	if not self.has_fake_wall then
		real_w_wallAdj(0, 0, 0)
		self.has_fake_wall = true
	end
	local half_radius = 0.5 * (l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse())
	local outer_bounds = l_getWallSpawnDistance() * 1.1
	local del_queue = {}
	for i, wall in pairs(self.walls) do
		if wall.accel ~= 0 then
			wall.speed = wall.speed + wall.accel * frametime
			if wall.speed > wall.max_speed then
				wall.speed = wall.max_speed
				wall.accel = 0
			elseif wall.speed < wall.min_speed then
				wall.speed = wall.min_speed
				wall.accel = 0
			end
		end
		local points_on_center = 0
		local points_out_of_bounds = 0
		for vertex=0,3 do
			local x, y = cw_getVertexPos(wall.cw, vertex)
			local x_dist, y_dist = math.abs(x), math.abs(y)
			if x_dist > outer_bounds or y_dist > outer_bounds then
				points_out_of_bounds = points_out_of_bounds + 1
			end
			if x_dist < half_radius and y_dist < half_radius then
				points_on_center = points_on_center + 1
			else
				local magnitude = math.sqrt(x ^ 2 + y ^ 2)
				local move_distance = wall.speed * 5 * frametime
				cw_moveVertexPos(wall.cw, vertex, -x / magnitude * move_distance, -y / magnitude * move_distance)
			end
		end
		cw_setVertexColor4Same(wall.cw, style:get_main_color())
		if points_on_center == 4 or points_out_of_bounds == 4 then
			table.insert(del_queue, 1, i)
			cw_destroy(wall.cw)
		end
	end
	for _, i in pairs(del_queue) do
		table.remove(self.walls, i)
	end
	if #self.walls == 0 then
		real_u_clearWalls()
		self.has_fake_wall = false
	end
end


if type(w_wall) == "userdata" then
	real_w_wallAdj = w_wallAdj
	real_u_clearWalls = u_clearWalls
	w_wall = function(side, thickness)
		t_eval("walls:wall(" .. side .. ", " .. thickness .. ")")
	end
	w_wallAdj = function(side, thickness, speed_mult)
		t_eval("walls:wall(" .. side .. ", " .. thickness .. ", " .. speed_mult .. ")")
	end
	w_wallAcc = function(side, thickness, speed_mult, acceleration, min_speed, max_speed)
		t_eval("walls:wall(" .. side .. ", " .. thickness .. ", " .. speed_mult .. ", " .. acceleration .. ", " .. min_speed .. ", " .. max_speed .. ")")
	end
	u_clearWalls = function()
		for i=1, #walls.walls do
			local wall = walls.walls[i]
			cw_destroy(wall.cw)
		end
		walls.walls = {}
	end
end
