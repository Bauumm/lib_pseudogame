-- this function converts polar coordinates into cartesian ones and adds a start position
-- angle: number	-- the angle in radians
-- distance: number	-- the distance from the start pos
-- start_pos: table	-- the start pos, formatted like this: {x, y}
-- return: x, y		-- the resulting position
function get_orbit(angle, distance, start_pos)
	if start_pos == nil then
		return math.cos(angle) * distance, math.sin(angle) * distance
	end
	return math.cos(angle) * distance + start_pos[1], math.sin(angle) * distance + start_pos[2]
end
