--- Class representing a game's background
-- @classmod PseudoGame.game.Background
PseudoGame.game.Background = {}
PseudoGame.game.Background.__index = PseudoGame.game.Background

--- the constructor for a game's background
-- @tparam[opt=level_style] Style style  the style to use
-- @treturn Background
function PseudoGame.game.Background:new(style)
    return setmetatable({
        --- @tfield Style style  The style object the background is using
        style = style or PseudoGame.game.level_style,
        --- @tfield PolygonCollection polygon_collection  The collection of polygons representing the visual background (use this for drawing)
        polygon_collection = PseudoGame.graphics.PolygonCollection:new(),
    }, PseudoGame.game.Background)
end

--- update the backgrounds color, position and shape
function PseudoGame.game.Background:update()
    local gen = self.polygon_collection:generator()
    local sides = l_getSides()
    local div = math.pi * 2 / sides
    local half_div = div / 2
    local distance = s_getBGTileRadius()
    for i = 0, sides - 1 do
        local angle = div * i + math.rad(s_getBGRotationOffset())
        local current_color = { self.style:get_background_color(i + 1) }
        if i % 2 == 0 and i == sides - 1 and l_getDarkenUnevenBackgroundChunk() then
            for i = 1, 3 do
                current_color[i] = current_color[i] / 1.4
            end
        end
        local polygon = gen()
        polygon:resize(3)
        polygon:set_vertex_pos(2, PseudoGame.game.get_orbit(angle + half_div, distance))
        polygon:set_vertex_pos(3, PseudoGame.game.get_orbit(angle - half_div, distance))
        for i = 1, 3 do
            polygon:set_vertex_color(i, unpack(current_color))
        end
    end
end
