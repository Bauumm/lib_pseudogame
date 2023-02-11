function get_orbit(angle, distance, start_pos)
	if start_pos == nil then
		return math.cos(angle) * distance, math.sin(angle) * distance
	end
	return math.cos(angle) * distance + start_pos[1], math.sin(angle) * distance + start_pos[2]
end
