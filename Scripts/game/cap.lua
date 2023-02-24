Cap = {}
Cap.__index = Cap

-- the constructor for a cap
-- use cap.polygon to draw it
-- return: Cap
function Cap:new()
	return setmetatable({polygon = Polygon:new()}, Cap)
end

-- update the caps shape and color
function Cap:update()
	local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
	local sides = l_getSides()
	local pivot_radius = 0.75 * radius
	local div = math.pi / sides
	while self.polygon.vertex_count > sides do
		self.polygon:remove_vertex(1)
	end
	while self.polygon.vertex_count < sides do
		self.polygon:add_vertex(0, 0, 0, 0, 0, 0)
	end
	for i=1, sides do
		local s_angle = div * 2 * i
		self.polygon:set_vertex_pos(i, get_orbit(s_angle - div, pivot_radius))
		self.polygon:set_vertex_color(i, style:get_cap_color())
	end
end
