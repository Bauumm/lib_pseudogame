--- a module with some premade visual effects
-- @module PseudoGame.graphics.effects
PseudoGame.graphics.effects = {
    --- setting `effects.draw_directly` to true will make the effects, that take a polygon collection to output to, draw directly to the screen instead
    draw_directly = false,
    _tmp_collection = PseudoGame.graphics.PolygonCollection:new(),
    _headless = u_isHeadless(),
}

--- get the polygons that represent the intersection of two collections
-- @tparam PolygonCollection polygon_collection1  the first collection
-- @tparam PolygonCollection polygon_collection2  the second collection
-- @tparam function blend_func  this function determines the color of the new polygons based on the color of the two intersected ones, so it should take `r0, g0, b0, a0, r1, g1, b1, a1` and return `r, g, b, a`
-- @tparam[opt] PolygonCollection blend_collection  the collection the resulting polygons are added to (the collection is cleared before the operation) (not required if direct drawing is enabled)
function PseudoGame.graphics.effects:blend(polygon_collection1, polygon_collection2, blend_func, blend_collection)
    if not self.draw_directly then
        blend_collection:clear()
    end
    if not self.draw_directly or not self._headless then
        local tmp_gen = self._tmp_collection:generator()
        for polygon1 in polygon_collection1:iter() do
            for polygon2 in polygon_collection2:iter() do
                local clipped_polygon = polygon1:clip(polygon2, tmp_gen)
                if clipped_polygon ~= nil then
                    local r, g, b, a = polygon1:get_vertex_color(1)
                    for index, x, y in clipped_polygon:vertex_color_pairs() do
                        clipped_polygon:set_vertex_color(index, blend_func(r, g, b, a, polygon2:get_vertex_color(1)))
                    end
                    if self.draw_directly then
                        PseudoGame.graphics.screen:draw_polygon(clipped_polygon)
                    else
                        blend_collection:add(clipped_polygon)
                    end
                end
            end
        end
    end
end

--- creates polygons along the edges of some polygons
-- @tparam PolygonCollection polygon_collection  the polygon collection the outlines should be made for
-- @tparam number thickness  the thickness of the outlines
-- @tparam table color  the color of the outlines, should be formatted like this: `{r, g, b, a}`
-- @tparam[opt] PolygonCollection outline_collection  the polygon collection the outlines will be added to (the collection is cleared before the operation) (not required if direct drawing is enabled)
function PseudoGame.graphics.effects:outline(polygon_collection, thickness, color, outline_collection)
    if not self.draw_directly or not self._headless then
        local gen
        if self.draw_directly then
            gen = self._tmp_collection:generator()
        else
            gen = outline_collection:generator()
        end
        for polygon in polygon_collection:iter() do
            for x0, y0, r0, g0, b0, a0, x1, y1, r1, g1, b1, a1 in polygon:edge_color_pairs() do
                local dx, dy = x1 - x0, y1 - y0
                local len = math.sqrt(dx * dx + dy * dy)
                local thick_x, thick_y = dx / len * thickness, dy / len * thickness
                local new_poly = gen()
                new_poly:resize(4)
                new_poly:set_vertex_pos(1, x0 - thick_x - thick_y, y0 - thick_y + thick_x)
                new_poly:set_vertex_pos(2, x0 - thick_x + thick_y, y0 - thick_y - thick_x)
                new_poly:set_vertex_pos(3, x1 + thick_x + thick_y, y1 + thick_y - thick_x)
                new_poly:set_vertex_pos(4, x1 + thick_x - thick_y, y1 + thick_y + thick_x)
                for i = 1, 4 do
                    new_poly:set_vertex_color(i, unpack(color))
                end
                if self.draw_directly then
                    PseudoGame.graphics.screen:draw_polygon(new_poly)
                end
            end
        end
    end
end

--- renders a glow effect by rendering polygons many times, this is extremely laggy
-- @tparam PolygonCollection polygon_collection  the polygon collection the glow should be made for
-- @tparam number intensity  the intensity of the effect (should be between 0 and 1)
-- @tparam number radius  the radius of the effect
-- @tparam number radius_step  the step size of the effect in the outer direction (lower values can lead to a lot of lag)
-- @tparam number angle_step  the step size of the effect around the object (lower values can lead to a lot of lag)
-- @tparam[opt] PolygonCollection glow_collection  the polygon collection the glow will be added to (the collection is cleared before the operation) (not required if direct drawing is enabled)
function PseudoGame.graphics.effects:glow(polygon_collection, intensity, radius, radius_step, angle_step, glow_collection)
    if not self.draw_directly or not self._headless then
        local gen
        if self.draw_directly then
            gen = self._tmp_collection:generator()
        else
            gen = glow_collection:generator()
        end
        for polygon in polygon_collection:iter() do
            for cr = 1, radius, radius_step do
                for angle = 0, 360 - angle_step, angle_step do
                    local new_poly = gen()
                    local rad = math.rad(angle)
                    local push_x = math.cos(rad) * cr
                    local push_y = math.sin(rad) * cr
                    new_poly:copy_data_transformed(polygon, function(x, y, r, g, b, a)
                        return x + push_x, y + push_y, r, g, b, a / cr * intensity
                    end)
                    if self.draw_directly then
                        PseudoGame.graphics.screen:draw_polygon(new_poly)
                    end
                end
            end
        end
    end
end

--- renders a glow effect by creating gradients around the polygons
-- @tparam PolygonCollection polygon_collection  the polygon collection the glow should be made for
-- @tparam number size  the size of the effect (in non zoom factor adjusted pixels)
-- @tparam number initial_alpha_divisor  the number the alpha right at the edge of the polygon will be divided by (to create some contrast, otherwise the effect looks like a blur)
-- @tparam number corner_resolution  the amount of vertices to add in the corners (has to be >= 1)
-- @tparam[opt] PolygonCollection glow_collection  the polygon collection the glow will be added to (the collection is cleared before the operation) (not required if direct drawing is enabled)
function PseudoGame.graphics.effects:gradient_glow(polygon_collection, size, initial_alpha_divisor, corner_resolution, glow_collection)
    if not self.draw_directly or not self._headless then
        local gen
        if self.draw_directly then
            gen = self._tmp_collection:generator()
        else
            gen = glow_collection:generator()
        end
        for polygon in polygon_collection:iter() do
            local cw_mult = polygon:is_clockwise() and 1 or -1
            local last_move_x, last_move_y
            do
                local x0, y0 = polygon:get_vertex_pos(polygon.vertex_count)
                local x1, y1 = polygon:get_vertex_pos(1)
                local dx = x1 - x0
                local dy = y1 - y0
                local mag = math.sqrt(dx * dx + dy * dy)
                last_move_x = -dy / mag * size * cw_mult
                last_move_y = dx / mag * size * cw_mult
            end
            for x0, y0, r0, g0, b0, a0, x1, y1, r1, g1, b1, a1 in polygon:edge_color_pairs() do
                local dx = x1 - x0
                local dy = y1 - y0
                local mag = math.sqrt(dx * dx + dy * dy)
                local move_x = -dy / mag * size * cw_mult
                local move_y = dx / mag * size * cw_mult

                -- corner
                local angle0 = math.atan2(last_move_y, last_move_x) % (2 * math.pi)
                local angle1 = math.atan2(move_y, move_x) % (2 * math.pi)
                local delta_angle = angle1 - angle0
                if delta_angle > math.pi then
                    delta_angle = delta_angle - 2 * math.pi
                    angle1 = angle0 + delta_angle
                end
                local vert_index = 1
                local corner_polygon = gen()
                corner_polygon:resize(corner_resolution + 2)
                corner_polygon:set_vertex_pos(1, x0, y0)
                corner_polygon:set_vertex_color(1, r0, g0, b0, a0 / initial_alpha_divisor)
                corner_polygon:set_vertex_pos(corner_polygon.vertex_count, x0 + move_x, y0 + move_y)
                corner_polygon:set_vertex_color(corner_polygon.vertex_count, r0, g0, b0, 0)
                for angle = angle0, angle1, delta_angle / corner_resolution do
                    vert_index = vert_index + 1
                    corner_polygon:set_vertex_pos(vert_index, x0 + math.cos(angle) * size, y0 + math.sin(angle) * size)
                    corner_polygon:set_vertex_color(vert_index, r0, g0, b0, 0)
                end
                last_move_x = move_x
                last_move_y = move_y
                if self.draw_directly then
                    PseudoGame.graphics.screen:draw_polygon(corner_polygon)
                end

                -- edge
                local new_polygon = gen()
                new_polygon:resize(4)
                new_polygon:set_vertex_pos(1, x0, y0)
                new_polygon:set_vertex_color(1, r0, g0, b0, a0 / initial_alpha_divisor)
                new_polygon:set_vertex_pos(2, x1, y1)
                new_polygon:set_vertex_color(2, r1, g1, b1, a1 / initial_alpha_divisor)
                new_polygon:set_vertex_pos(3, x1 + move_x, y1 + move_y)
                new_polygon:set_vertex_color(3, r1, g1, b1, 0)
                new_polygon:set_vertex_pos(4, x0 + move_x, y0 + move_y)
                new_polygon:set_vertex_color(4, r0, g0, b0, 0)
                if self.draw_directly then
                    PseudoGame.graphics.screen:draw_polygon(new_polygon)
                end
            end
        end
    end
end

--- generates a transformation function that rotates vertices
-- @tparam number angle  the angle to rotate
-- @treturn function  the transformation function
function PseudoGame.graphics.effects:rotate(angle)
    local cos, sin = math.cos(angle), math.sin(angle)
    return function(x, y, r, g, b, a)
        return x * cos - y * sin, x * sin + y * cos, r, g, b, a
    end
end

--- generates a transformation function that mirrors vertices
-- @tparam bool mirror_x  whether it should mirror along the x axis
-- @tparam bool mirror_y  whether it should mirror along the y axis
-- @treturn function  the transformation function
function PseudoGame.graphics.effects:mirror(mirror_x, mirror_y)
    mirror_x = mirror_x and -1 or 1
    mirror_y = mirror_y and -1 or 1
    return function(x, y, r, g, b, a)
        return x * mirror_x, y * mirror_y, r, g, b, a
    end
end
