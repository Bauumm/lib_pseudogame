--- Class for creating a pseudo 3d effect for a polygon collection
-- @classmod PseudoGame.game.Pseudo3D
PseudoGame.game.Pseudo3D = {}
PseudoGame.game.Pseudo3D.__index = PseudoGame.game.Pseudo3D

--- the constructor for a Pseudo3D object
-- @tparam PolygonCollection polygon_collection  the collection of polygons to create a 3d effect for
-- @tparam[opt=level_style] Style style  the style to use (also defines which 3d effect to use)
function PseudoGame.game.Pseudo3D:new(polygon_collection, style)
    return setmetatable({
        --- @tfield Style style  the 3d effect's style
        style = style or PseudoGame.game.level_style,
        --- @tfield PolygonCollection source_collection  the collection it's making a 3d effect for
        source_collection = polygon_collection,
        --- @tfield PolygonCollection polygon_collection  the polygons representing the 3d effect (use this for drawing)
        polygon_collection = PseudoGame.graphics.PolygonCollection:new(),

        _edges = {},
    }, PseudoGame.game.Pseudo3D)
end

--- function to refill the polygon collection with the a 3d effect (which one is specified in the style)
function PseudoGame.game.Pseudo3D:update()
    if self.style:get_connect_layers() then
        self:_update_gradient()
    else
        self:_update_layered()
    end
end

function PseudoGame.game.Pseudo3D:_update_layered()
    local spacing = self.style:get_layer_spacing()
    local depth = self.style:get_depth()
    local rad_rot = math.rad(l_getRotation() + 90)
    local cos_rot, sin_rot = math.cos(rad_rot), math.sin(rad_rot)
    local gen = self.polygon_collection:generator()
    for j = 1, depth do
        local i = depth - j + 1
        local offset = i * spacing
        local new_pos_x = offset * cos_rot
        local new_pos_y = offset * sin_rot
        local override_color = { self.style:get_layer_color(i) }
        for polygon in self.source_collection:iter() do
            gen():copy_data_transformed(polygon, function(x, y)
                return x + new_pos_x, y + new_pos_y, unpack(override_color)
            end)
        end
    end
end

-- this code is pretty messy and experimental
function PseudoGame.game.Pseudo3D:_update_gradient()
    local undo_rot = PseudoGame.graphics.effects:rotate(math.rad(-l_getRotation()))
    local do_rot = PseudoGame.graphics.effects:rotate(math.rad(l_getRotation()))
    local edge_index = 0
    for polygon in self.source_collection:iter() do
        polygon:transform(undo_rot)
        for x0, y0, r0, g0, b0, a0, x1, y1, r1, g1, b1, a1 in polygon:edge_color_pairs() do
            edge_index = edge_index + 1
            local edge = self._edges[edge_index]
            if edge == nil then
                self._edges[edge_index] = { x0, y0, x1, y1 }
            else
                edge[1] = x0
                edge[2] = y0
                edge[3] = x1
                edge[4] = y1
            end
        end
        polygon:transform(do_rot)
    end
    for i = #self._edges, edge_index + 1, -1 do
        self._edges[i] = nil
    end
    table.sort(self._edges, function(edge0, edge1)
        local function get_y_from_x(x, edge)
            return (edge[4] - edge[2]) / (edge[3] - edge[1]) * (x - edge[1]) + edge[2]
        end
        local isect_x_range_start = math.max(math.min(edge0[1], edge0[3]), math.min(edge1[1], edge1[3]))
        local isect_x_range_end = math.min(math.max(edge0[1], edge0[3]), math.max(edge1[1], edge1[3]))
        if isect_x_range_start >= isect_x_range_end then
            local avg_y0 = (edge0[2] + edge0[4]) / 2
            local avg_y1 = (edge1[2] + edge1[4]) / 2
            return avg_y0 < avg_y1
        else
            return (
                get_y_from_x(isect_x_range_start, edge0)
                - get_y_from_x(isect_x_range_start, edge1)
                + get_y_from_x(isect_x_range_end, edge0)
                - get_y_from_x(isect_x_range_end, edge1)
            ) < 0
        end
    end)
    for i = 1, edge_index do
        edge = self._edges[i]
        edge[1], edge[2] = do_rot(edge[1], edge[2])
        edge[3], edge[4] = do_rot(edge[3], edge[4])
    end
    local spacing = self.style:get_layer_spacing()
    local depth = self.style:get_depth()
    local rad_rot = math.rad(l_getRotation() + 90)
    local cos_rot, sin_rot = math.cos(rad_rot), math.sin(rad_rot)
    local gen = self.polygon_collection:generator()
    for j = 1, depth do
        local i = depth - j + 1
        local offset = i * spacing
        local new_pos_x = offset * cos_rot
        local new_pos_y = offset * sin_rot
        local next_i = i - 1
        local next_offset = next_i * spacing
        local next_new_pos_x = next_offset * cos_rot
        local next_new_pos_y = next_offset * sin_rot
        local override_color = { self.style:get_layer_color(i) }
        for i = 1, edge_index do
            local x0, y0, x1, y1 = unpack(self._edges[i])
            local side = gen()
            side:resize(4)
            side:set_vertex_pos(1, x0 + next_new_pos_x, y0 + next_new_pos_y)
            side:set_vertex_pos(2, x1 + next_new_pos_x, y1 + next_new_pos_y)
            side:set_vertex_pos(3, x1 + new_pos_x, y1 + new_pos_y)
            side:set_vertex_pos(4, x0 + new_pos_x, y0 + new_pos_y)
            if self.style.gradient then
                local next_override_color
                if next_i == 0 then
                    next_override_color = { self.style:get_main_color() }
                else
                    next_override_color = { self.style:get_layer_color(next_i) }
                end
                for i = 1, 2 do
                    side:set_vertex_color(i, unpack(next_override_color))
                end
                for i = 3, 4 do
                    side:set_vertex_color(i, unpack(override_color))
                end
            else
                for i = 1, 4 do
                    side:set_vertex_color(i, unpack(override_color))
                end
            end
        end
    end
end
