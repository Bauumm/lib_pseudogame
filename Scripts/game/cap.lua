PseudoGame.game.Cap = {}
PseudoGame.game.Cap.__index = PseudoGame.game.Cap

-- the constructor for a cap
-- use cap.polygon to draw it
-- style: Style (optional)	-- the style to use (nil will use the default level style)
-- return: Cap
function PseudoGame.game.Cap:new(style)
	return setmetatable({
		style = style or PseudoGame.game.level_style,
		polygon = PseudoGame.graphics.Polygon:new()
	}, PseudoGame.game.Cap)
end

-- update the caps shape and color
function PseudoGame.game.Cap:update()
	local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
	local sides = l_getSides()
	local pivot_radius = 0.75 * radius
	local div = math.pi / sides
	self.polygon:resize(sides)
	for i=1, sides do
		local s_angle = div * 2 * i
		self.polygon:set_vertex_pos(i, PseudoGame.game.get_orbit(s_angle - div, pivot_radius))
		self.polygon:set_vertex_color(i, self.style:get_cap_color())
	end
end
