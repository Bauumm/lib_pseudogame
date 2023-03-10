Pivot = {}
Pivot.__index = Pivot

-- the constructor for a pivot
-- draw it using pivot.polygon_collection
-- style: Style	-- the style to use (nil will use the default level style)
-- return: Pivot
function Pivot:new(style)
	return setmetatable({
		style = style or level_style,
		polygon_collection = PolygonCollection:new()
	}, Pivot)
end

-- update the pivots shape and color
function Pivot:update()
	self.polygon_collection:resize(l_getSides())
	local it = self.polygon_collection:iter()
	local sides = l_getSides()
	local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
	local pivot_radius = 0.75 * radius
	local div = math.pi / sides
	for i=0, sides - 1 do
		local s_angle = div * 2 * i
		local polygon = it()
		while polygon.vertex_count < 4 do
			polygon:add_vertex(0, 0, 0, 0, 0, 0)
		end
		polygon:set_vertex_pos(1, get_orbit(s_angle - div, pivot_radius))
		polygon:set_vertex_pos(2, get_orbit(s_angle + div, pivot_radius))
		polygon:set_vertex_pos(3, get_orbit(s_angle + div, pivot_radius + 5))
		polygon:set_vertex_pos(4, get_orbit(s_angle - div, pivot_radius + 5))
		for i=1,4 do
			polygon:set_vertex_color(i, self.style:get_main_color())
		end
	end
end
