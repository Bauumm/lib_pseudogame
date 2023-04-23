--- Module containing premade collision handlers for use with the Player class
-- @module PseudoGame.game.collision_handlers

--- A function that handles collision of some polygons with a player
-- @tparam Player frametime  the time in 1/60s since the last call of this function
-- @tparam Player player  the player to handle collisions for (it may be moved in the process)
-- @tparam PolygonCollection collide_collection  the collection of polygons to collide with
-- @treturn bool  determines if the player should be killed
function PseudoGame.game.basic_collision_handler(frametime, player, collide_collection)
	local collides = false
	local last_collides = false
	local must_kill = false
	for polygon in collide_collection:iter() do
		local is_in = polygon:contains_point(unpack(player.pos))
		if polygon.extra_data ~= nil and polygon.extra_data.deadly and is_in then
			must_kill = true
		end
		collides = collides or is_in
		if not player.just_swapped then
			last_collides = last_collides or polygon:contains_point(unpack(player.last_pos))
		end
	end
	if collides then
		if player.just_swapped then
			must_kill = true
		elseif last_collides then
			must_kill = true
		elseif not must_kill then
			for i=1, 2 do
				player.pos[i] = player.last_pos[i]
			end
			player.angle = player.last_angle
		end
	end
	return must_kill
end

function PseudoGame.game.default_collision_handler(frametime, player, collide_collection)
	local radius_squared = player.radius * player.radius + 8
	local function push(polygon)
		local function get_normalized(x, y)
			local mag = math.sqrt(x * x + y * y)
			return x / mag, y / mag
		end
		local function check_wall_escape(polygon, pos_x, pos_y)
			-- To find the closest wall side we intersect the circumference of the
			-- possible player positions with the sides of the wall. We use the
			-- intersection closest to the player's position as post collision target.
			-- If an escape route could not be found player is killed.
			
			local saved = false
			local temp_distance, vec1_x, vec1_y, vec2_x, vec2_y
			local safe_distance = player._max_safe_distance or 0
			local vx_increment = 2

			local function get_line_circle_intersection(p1_x, p1_y, p2_x, p2_y)
				local dx = p2_x - p1_x
				local dy = p2_y - p1_y
				local a = dx * dx + dy * dy
				local b = 2 * (dx * p1_x + dy * p1_y)
				local c = p1_x * p1_x + p1_y * p1_y - radius_squared
				local delta = b * b - 4 * a * c

				-- No intersections.
				if delta < 0 then
					return 0
				end

				local t
				local two_a = a * 2

				-- one intersection
				if delta < 1.0e-4 then
					t = -b / two_a
					vec1_x = p1_x + t * dx
					vec1_y = p1_y + t * dy
					return 1
				end

				-- two intersections
				local sqrt_delta = math.sqrt(delta)
				t = (-b + sqrt_delta) / two_a
				vec1_x = p1_x + t * dx
				vec1_y = p1_y + t * dy
				t = (-b - sqrt_delta) / two_a
				vec2_x = p1_x + t * dx
				vec2_y = p1_y + t * dy
				return 2
			end

			local function assign_result()
				temp_distance = (vec1_x - pos_x) ^ 2 + (vec1_y - pos_y) ^ 2
				if temp_distance < safe_distance then
					pos_x = vec1_x
					pos_y = vec1_y
					saved = true
					safe_distance = temp_distance
				end
			end

			for i = 0, 2, 2 do
				local j = 3 - i
				local i_x, i_y = polygon:get_vertex_pos(i + 1)
				local j_x, j_y = polygon:get_vertex_pos(j + 1)
				local result_count = get_line_circle_intersection(i_x, i_y, j_x, j_y)
				if result_count == 1 then
					assign_result()
				elseif result_count == 2 then
					if (vec1_x - pos_x) ^ 2 + (vec1_y - pos_y) ^ 2 > (vec2_x - pos_x) ^ 2 + (vec2_y - pos_y) ^ 2 then
						vec1_x = vec2_x
						vec1_y = vec2_y
					end
					assign_result()
				end
			end
			return saved, pos_x, pos_y
		end
		local test_pos_x = player.pos[1]
		local test_pos_y = player.pos[2]
		local pre_push_pos_x = player.pos[1]
		local pre_push_pos_y = player.pos[2]
		local push_vel_x = 0
		local push_vel_y = 0

		-- If it's a rotating wall push player in the direction the
		-- wall is rotating by the appropriate amount, but only if the direction
		-- of the rotation is different from direction the player is moving.
		-- Save the position difference in case we need to do a second attempt
		-- at saving player.
		if polygon.wall ~= nil then
			if polygon.wall.curving then
				if polygon.wall.speed ~= 0 and polygon.wall.speed > 0 and 1 or -1 ~= player.movement_dir then
					test_pos_x, test_pos_y = PseudoGame.graphics.effects:rotate(polygon.wall.speed * frametime / 60)(test_pos_x, test_pos_y)
					push_vel_x = test_pos_x - player.pos[1]
					push_vel_y = test_pos_y - player.pos[2]
				end
			end

			-- If player is not moving calculate now...
			if player.movement_dir == 0 then
				local nx, ny = get_normalized(test_pos_x - pre_push_pos_x, test_pos_y - pre_push_pos_y)
				player.pos[1] = test_pos_x + nx
				player.pos[2] = test_pos_y + ny
				player.angle = math.atan2(player.pos[2], player.pos[1])

				-- add our own property to the player for carrying over into the next call
				local ox, oy = PseudoGame.game.get_orbit(player.last_angle + math.rad(player.speed), player.radius)
				player._max_safe_distance = (player.last_pos[1] - ox) ^ 2 + (player.last_pos[2] - oy) + 32
				return polygon:contains_point(unpack(player.pos))
			end

			-- ...otherwise make test pos the position of the previous frame plus
			-- the curving wall's velocity, and check an escape on that position.
			-- Using the previous frame's position is essential for levels with
			-- a really high amount of sides. Player might be currently positioned
			-- closer to the side opposite to the one it should intuitively slide
			-- against
			--
			--
			--   BEFORE               AFTER
			--
			--  |       |           |       |
			--  |       |           |       |
			--  |       |   *       |  *    | <- this should be our target wall
			--  |       |  * *      | * *   |    but if we use the current position
			--  |       | *****     |*****  |    it is the other one that is closer
			--  |       |           |       |
			test_pos_x = player.last_pos[1] + push_vel_x
			test_pos_y = player.last_pos[2] + push_vel_y
			local is_in = polygon:contains_point(test_pos_x, test_pos_y)
			local saved, test_pos_x, test_pos_y = check_wall_escape(polygon, test_pos_x, test_pos_y, player.radius ^ 2)
			if is_in or not saved then
				return true
			end

			-- If the player survived assign it the saving test pos, but displace it further
			-- out of the wall border, otherwise player would be lying right on top of the
			-- border.
			local nx, ny = get_normalized(test_pos_x - pre_push_pos_x, test_pos_y - pre_push_pos_y)
			player.pos[1] = test_pos_x + nx * 0.5
			player.pos[2] = test_pos_y + ny * 0.5
			player.angle = math.atan2(player.pos[2], player.pos[1])

			-- add our own property to the player for carrying over into the next call
			local ox, oy = PseudoGame.game.get_orbit(player.last_angle + math.rad(player.speed), player.radius)
			player._max_safe_distance = (player.last_pos[1] - ox) ^ 2 + (player.last_pos[2] - oy) + 32

			return false
		end
	end
	local collided = false
	for polygon in collide_collection:iter() do
		-- If there is no collision skip to the next wall
		if polygon:contains_point(unpack(player.pos)) then
			-- Kill after a swap or if player could not be pushed out to safety
			if player.just_swapped then
				steam_unlockAchievement("a22_swapdeath")
				return true
			elseif push(polygon) then
				return true
			end
			collided = true
		end
	end

	-- There was no collision, so we can stop here.
	if not collided then
		return false
	end

	-- Second round, always deadly...
	for polygon in collide_collection:iter() do
		if polygon:contains_point(unpack(player.pos)) then
			if player.just_swapped then
				steam_unlockAchievement("a22_swapdeath")
			end
			return true
		end
	end
end
