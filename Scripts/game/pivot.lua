--- Class that represents a game's pivot
-- @classmod PseudoGame.game.Pivot
PseudoGame.game.Pivot = {}
PseudoGame.game.Pivot.__index = PseudoGame.game.Pivot

--- the constructor for a pivot
-- @tparam[opt=level_style] Style style  the style to use (nil will use the default level style)
-- @treturn Pivot
function PseudoGame.game.Pivot:new(style)
    return setmetatable({
        --- @tfield Style  the style the pivot is using
        style = style or PseudoGame.game.level_style,
        --- @tfield PolygonCollection  the polygons representing the visual pivot (use this for drawing)
        polygon_collection = PseudoGame.graphics.PolygonCollection:new(),
    }, PseudoGame.game.Pivot)
end

--- update the pivots shape and color
function PseudoGame.game.Pivot:update()
    self.polygon_collection:resize(l_getSides())
    local it = self.polygon_collection:iter()
    local sides = l_getSides()
    local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
    local pivot_radius = 0.75 * radius
    local div = math.pi / sides
    for i = 0, sides - 1 do
        local s_angle = div * 2 * i
        local polygon = it()
        polygon:resize(4)
        polygon:set_vertex_pos(1, PseudoGame.game.get_orbit(s_angle - div, pivot_radius))
        polygon:set_vertex_pos(2, PseudoGame.game.get_orbit(s_angle + div, pivot_radius))
        polygon:set_vertex_pos(3, PseudoGame.game.get_orbit(s_angle + div, pivot_radius + 5))
        polygon:set_vertex_pos(4, PseudoGame.game.get_orbit(s_angle - div, pivot_radius + 5))
        for i = 1, 4 do
            polygon:set_vertex_color(i, self.style:get_main_color())
        end
    end
end
