--- Class that represents a simple convex 2D Polygon
-- @classmod PseudoGame.graphics.Polygon
PseudoGame.graphics.Polygon = {}
PseudoGame.graphics.Polygon.__index = PseudoGame.graphics.Polygon

--- The constructor for a Polygon
-- @tparam table vertices  the polygon's vertices in this format: `{x0, y0, x1, y1, ...}`
-- @tparam table colors  the vertex colors in this format: `{r0, g0, b0, a0, r1, g1, b1, a1, ...}`
-- @treturn Polygon
function PseudoGame.graphics.Polygon:new(vertices, colors)
    vertices = vertices or {}
    colors = colors or {}
    if #vertices % 2 ~= 0 then
        error("Polygon: vertices must be 2D points in this format: {x0, y0, x1, y1, ...}")
    end
    local vertex_count = #vertices / 2
    if vertex_count ~= #colors / 4 then
        error("Polygon: the number of colors and vertices doesn't match")
    end
    local obj = setmetatable({
        _vertices = vertices,
        _colors = colors,
        --- @tfield number vertex_count  the amount of vertexes the polygon has
        vertex_count = vertex_count,
    }, PseudoGame.graphics.Polygon)
    return obj
end

--- Iterate over vertices and colors
-- @usage
-- for index, x, y, r, g, b, a in mypolygon:vertex_color_pairs() do
--    ...
-- end
function PseudoGame.graphics.Polygon:vertex_color_pairs()
    local index = 0
    return function()
        index = index + 1
        if index <= self.vertex_count then
            local vertex_index = index * 2
            local color_index = index * 4
            return index,
                self._vertices[vertex_index - 1],
                self._vertices[vertex_index],
                self._colors[color_index - 3],
                self._colors[color_index - 2],
                self._colors[color_index - 1],
                self._colors[color_index]
        end
    end
end

--- Iterate over edges and their colors
-- @usage
-- for x0, y0, r0, g0, b0, a0, x1, y1, r1, g1, b1, a1 in mypolygon:edge_color_pairs() do
--    ...
-- end
function PseudoGame.graphics.Polygon:edge_color_pairs()
    local index = 0
    return function()
        index = index + 1
        if index <= self.vertex_count then
            local vertex_index = index * 2
            local color_index = index * 4
            local index2 = index % self.vertex_count + 1
            local vertex_index2 = index2 * 2
            local color_index2 = index2 * 4
            return self._vertices[vertex_index - 1],
                self._vertices[vertex_index],
                self._colors[color_index - 3],
                self._colors[color_index - 2],
                self._colors[color_index - 1],
                self._colors[color_index],
                self._vertices[vertex_index2 - 1],
                self._vertices[vertex_index2],
                self._colors[color_index2 - 3],
                self._colors[color_index2 - 2],
                self._colors[color_index2 - 1],
                self._colors[color_index2]
        end
    end
end

--- adds a vertex with a vertex color to the polygon
-- @tparam number x  the x coordinate of the vertex
-- @tparam number y  the y coordinate of the vertex
-- @tparam[opt=0] number r  the r component of the vertex color
-- @tparam[opt=0] number g  the g component of the vertex color
-- @tparam[opt=0] number b  the b component of the vertex color
-- @tparam[opt=0] number a  the a component of the vertex color
function PseudoGame.graphics.Polygon:add_vertex(x, y, r, g, b, a)
    self.vertex_count = self.vertex_count + 1
    self:set_vertex_pos(self.vertex_count, x, y)
    self:set_vertex_color(self.vertex_count, r or 0, g or 0, b or 0, a or 0)
end

function PseudoGame.graphics.Polygon:_check_vert_index(index)
    if index > self.vertex_count or index <= 0 then
        error("Polygon: the index of " .. index .. " is out of bounds!")
    end
end

--- removes a vertex and and its color from the polygon
-- @tparam number index  the index of the vertex
function PseudoGame.graphics.Polygon:remove_vertex(index)
    self:_check_vert_index(index)
    self.vertex_count = self.vertex_count - 1
    local vertex_index = index * 2
    for i = 0, 1 do
        table.remove(self._vertices, vertex_index - i)
    end
    local color_index = index * 4
    for i = 0, 3 do
        table.remove(self._colors, color_index - i)
    end
end

--- sets the position of a vertex
-- @tparam number index  the index of the vertex
-- @tparam number x  the x coordinate the vertex should be set to
-- @tparam number y  the y coordinate the vertex should be set to
function PseudoGame.graphics.Polygon:set_vertex_pos(index, x, y)
    self:_check_vert_index(index)
    local vertex_index = index * 2
    self._vertices[vertex_index - 1] = x
    self._vertices[vertex_index] = y
end

--- gets a vertex position
-- @tparam number index  the index of the vertex
-- @treturn number,number  the position of the vertex
function PseudoGame.graphics.Polygon:get_vertex_pos(index)
    self:_check_vert_index(index)
    local vertex_index = index * 2
    return self._vertices[vertex_index - 1], self._vertices[vertex_index]
end

--- sets the color of a vertex
-- @tparam number index  the index of the vertex
-- @tparam number r  the r component of the vertex color
-- @tparam number g  the g component of the vertex color
-- @tparam number b  the b component of the vertex color
-- @tparam number a  the a component of the vertex color
function PseudoGame.graphics.Polygon:set_vertex_color(index, r, g, b, a)
    self:_check_vert_index(index)
    local color_index = index * 4
    self._colors[color_index - 3] = r
    self._colors[color_index - 2] = g
    self._colors[color_index - 1] = b
    self._colors[color_index] = a
end

--- gets a vertex color
-- @tparam number index  the index of the vertex
-- @treturn number,number,number,number  the color of the vertex
function PseudoGame.graphics.Polygon:get_vertex_color(index)
    self:_check_vert_index(index)
    local color_index = index * 4
    return self._colors[color_index - 3],
        self._colors[color_index - 2],
        self._colors[color_index - 1],
        self._colors[color_index]
end

--[[--
creates or removes vertices until the given size (vertex count) is reached
new vertices are initialized at (0, 0) with the color black
]]
-- @tparam number size  the vertex count the polygon will have after the operation
function PseudoGame.graphics.Polygon:resize(size)
    while self.vertex_count > size do
        self:remove_vertex(self.vertex_count)
    end
    while self.vertex_count < size do
        self:add_vertex(0, 0, 0, 0, 0, 0)
    end
end

--- checks if the polygon is defined in clockwise order
-- @treturn ?bool  returns nil if order is undefined (polygon with no area)
function PseudoGame.graphics.Polygon:is_clockwise()
    local area = 0
    for x0, y0, r, g, b, a, x1, y1 in self:edge_color_pairs() do
        area = area + (x1 - x0) * (y1 + y0)
    end
    if area == 0 then
        return
    end
    return area > 0
end

--- Implementation of the sutherland hodgman algorithm for polygon clipping
-- @tparam Polygon clipper_polygon  the polygon that will contain the newly created clipped polygon
-- @tparam[opt] function generator  use a generator instead of always creating new polygons (will create a polygon for every edge of the clipper polygon, so don't render this collection, this is just for improved performance)
-- @treturn ?Polygon  Returns the clipped polygon or nil if no intersecting area exists
function PseudoGame.graphics.Polygon:clip(clipper_polygon, generator)
    local return_polygon = self
    local cw = clipper_polygon:is_clockwise()
    if cw == nil then
        -- don't bother clipping if the polygon has no area
        return
    end
    for x0, y0, r, g, b, a, x1, y1 in clipper_polygon:edge_color_pairs() do
        return_polygon = return_polygon:slice(x0, y0, x1, y1, not cw, cw, generator, generator)
        if return_polygon == nil then
            return
        end
    end
    return return_polygon
end

--- slice the polygon into two polygons at a line given by two points
-- @tparam number x0  the x coordinate of the first point
-- @tparam number y0  the y coordinate of the first point
-- @tparam number x1  the x coordinate of the second point
-- @tparam number y1  the y coordinate of the second point
-- @tparam bool left  specifies if the part of the polygon on the left side of the line should be returned
-- @tparam bool right  specifies if the part of the polygon on the right side of the line should be returned
-- @tparam[opt] function generator_left  use a generator instead of creating new left polygons (this is good for performance)
-- @tparam[opt] function generator_right  use a generator instead of creating new right polygons (this is good for performance)
-- @treturn ?|Polygon,Polygon|Polygon|nil  returns either no, one or two polygons depending on left/right (returns nil when no part of the polygon is on a return side)
function PseudoGame.graphics.Polygon:slice(x0, y0, x1, y1, left, right, generator_left, generator_right)
    local function add_vert(generator, poly, index, x, y, r, g, b, a)
        if poly == nil then
            if generator == nil then
                poly = PseudoGame.graphics.Polygon:new()
            else
                poly = generator()
            end
        end
        if index > poly.vertex_count then
            poly:add_vertex(x, y, r, g, b, a)
        else
            poly:set_vertex_pos(index, x, y)
            poly:set_vertex_color(index, r, g, b, a)
        end
        return poly
    end
    local dx, dy = x1 - x0, y1 - y0
    local left_vert_count = 0
    local right_vert_count = 0
    local left_polygon, right_polygon
    if not left and not right then
        error("Polygon: slice called without specifying which polygon to return!")
    end
    for ix, iy, ir, ig, ib, ia, kx, ky, kr, kg, kb, ka in self:edge_color_pairs() do
        local i_pos, k_pos = dx * (iy - y0) - dy * (ix - x0), dx * (ky - y0) - dy * (kx - x0)
        local iside, kside = i_pos >= 0, k_pos >= 0
        if iside then
            -- point is on the left side
            if left then
                left_vert_count = left_vert_count + 1
                left_polygon = add_vert(generator_left, left_polygon, left_vert_count, ix, iy, ir, ig, ib, ia)
            end
        else
            -- point is on the right side
            if right then
                right_vert_count = right_vert_count + 1
                right_polygon = add_vert(generator_right, right_polygon, right_vert_count, ix, iy, ir, ig, ib, ia)
            end
        end
        if iside ~= kside or k_pos == 0 or i_pos == 0 then
            -- next point will be on the other side, so add the intersection point with the line
            local dikx, diky = ix - kx, iy - ky
            local num_part1 = (x0 * y1 - y0 * x1)
            local num_part2 = (ix * ky - iy * kx)
            local den = dy * dikx - dx * diky
            if math.abs(den) > 1e-10 then
                local x = (num_part1 * dikx + dx * num_part2) / den
                local y = (num_part1 * diky + dy * num_part2) / den

                -- interpolate between vertex colors to keep gradients (not sure if this actually works)
                local fac = (x - kx) / dikx
                if dikx == 0 then
                    fac = 0
                end
                local r = ir * fac + kr * (1 - fac)
                local g = ig * fac + kg * (1 - fac)
                local b = ib * fac + kb * (1 - fac)
                local a = ia * fac + ka * (1 - fac)

                -- add to both polygons since they share the point on the line
                if left then
                    left_vert_count = left_vert_count + 1
                    left_polygon = add_vert(generator_left, left_polygon, left_vert_count, x, y, r, g, b, a)
                end
                if right then
                    right_vert_count = right_vert_count + 1
                    right_polygon = add_vert(generator_right, right_polygon, right_vert_count, x, y, r, g, b, a)
                end
            end
        end
    end
    if left and left_polygon ~= nil then
        left_polygon:resize(left_vert_count)
    end
    if right and right_polygon ~= nil then
        right_polygon:resize(right_vert_count)
    end
    if left and right then
        return left_polygon, right_polygon
    elseif right then
        return right_polygon
    elseif left then
        return left_polygon
    end
end

function PseudoGame.graphics.Polygon:_to_cw_data(data, current_index)
    if self.vertex_count < 3 then
        return current_index
    end
    if self.vertex_count == 4 then
        current_index = current_index + 2
        if data[current_index - 1] == nil then
            data[current_index - 1] = {}
        end
        if data[current_index] == nil then
            data[current_index] = {}
        end
        local vertices = data[current_index - 1]
        local colors = data[current_index]
        for i = 1, 4 do
            local index = i * 2
            vertices[index - 1] = self._vertices[index - 1]
            vertices[index] = self._vertices[index]
            index = index * 2
            for i = 3, 0, -1 do
                colors[index - i] = self._colors[index - i]
            end
        end
    elseif self.vertex_count < 4 then
        current_index = current_index + 2
        if data[current_index - 1] == nil then
            data[current_index - 1] = {}
        end
        if data[current_index] == nil then
            data[current_index] = {}
        end
        local vertices = data[current_index - 1]
        local colors = data[current_index]
        for i = 1, 4 do
            local wrap_index = ((i - 1) % self.vertex_count + 1) * 2
            local index = i * 2
            vertices[index - 1] = self._vertices[wrap_index - 1]
            vertices[index] = self._vertices[wrap_index]
            index = index * 2
            wrap_index = wrap_index * 2
            for i = 1, 4 do
                colors[index - 4 + i] = self._colors[wrap_index - 4 + i]
            end
        end
    else
        -- fan "triangulation", only works for convex polygons
        current_index = current_index + 2
        if data[current_index - 1] == nil then
            data[current_index - 1] = {}
        end
        if data[current_index] == nil then
            data[current_index] = {}
        end
        local quad = data[current_index - 1]
        quad[1], quad[2] = self:get_vertex_pos(1)
        local colors = data[current_index]
        colors[1], colors[2], colors[3], colors[4] = self:get_vertex_color(1)
        local quad_index = 3
        for i = 2, self.vertex_count do
            local color_index = quad_index * 2 - 1
            quad[quad_index], quad[quad_index + 1] = self:get_vertex_pos(i)
            colors[color_index], colors[color_index + 1], colors[color_index + 2], colors[color_index + 3] =
                self:get_vertex_color(i)
            quad_index = quad_index + 2
            if quad_index > 8 and i ~= self.vertex_count then
                quad_index = 5
                current_index = current_index + 2
                if data[current_index - 1] == nil then
                    data[current_index - 1] = {}
                end
                if data[current_index] == nil then
                    data[current_index] = {}
                end
                quad = data[current_index - 1]
                quad[1], quad[2] = self:get_vertex_pos(1)
                quad[3], quad[4] = self:get_vertex_pos(i)
                colors = data[current_index]
                colors[1], colors[2], colors[3], colors[4] = self:get_vertex_color(1)
                colors[5], colors[6], colors[7], colors[8] = self:get_vertex_color(i)
            end
        end
        while quad_index < 8 do
            quad[quad_index] = quad[1]
            quad[quad_index + 1] = quad[2]
            local color_index = quad_index * 2 - 1
            for i = 0, 3 do
                colors[color_index + i] = colors[1 + i]
            end
            quad_index = quad_index + 2
        end
    end
    return current_index
end

--- copies the polygon (this function is bad for performance if used a lot)
-- @treturn Polygon
function PseudoGame.graphics.Polygon:copy()
    return PseudoGame.graphics.Polygon:new({ unpack(self._vertices) }, { unpack(self._colors) })
end

--- copy the vertex and color data of another polygon onto this one
-- @tparam Polygon polygon  the polygon to copy data from
function PseudoGame.graphics.Polygon:copy_data(polygon)
    while self.vertex_count > polygon.vertex_count do
        self:remove_vertex(1)
    end
    for index, x, y, r, g, b, a in polygon:vertex_color_pairs() do
        if index > self.vertex_count then
            self:add_vertex(x, y, r, g, b, a)
        else
            self:set_vertex_pos(index, x, y)
            self:set_vertex_color(index, r, g, b, a)
        end
    end
end

--- copy the vertex and color data of another polygon onto this one after transforming it
-- @tparam Polygon polygon  the polygon to copy data from
-- @tparam function transform_func  a function that takes `x, y, r, g, b, a` and returns `x, y, r, g, b, a`
function PseudoGame.graphics.Polygon:copy_data_transformed(polygon, transform_func)
    while self.vertex_count > polygon.vertex_count do
        self:remove_vertex(1)
    end
    for index, x, y, r, g, b, a in polygon:vertex_color_pairs() do
        x, y, r, g, b, a = transform_func(x, y, r, g, b, a)
        if index > self.vertex_count then
            self:add_vertex(x, y, r, g, b, a)
        else
            self:set_vertex_pos(index, x, y)
            self:set_vertex_color(index, r, g, b, a)
        end
    end
end

--- transform the vertices and vertex colors of the polygon
-- @tparam function transform_func  a function that takes `x, y, r, g, b, a` and returns `x, y, r, g, b, a`
-- @treturn Polygon  returns itself for convenient chaining of operations
function PseudoGame.graphics.Polygon:transform(transform_func)
    for index, x, y, r, g, b, a in self:vertex_color_pairs() do
        x, y, r, g, b, a = transform_func(x, y, r, g, b, a)
        self:set_vertex_pos(index, x, y)
        self:set_vertex_color(index, r, g, b, a)
    end
    return self
end

-- @tparam number x  the x coordinate of the point to check
-- @tparam number y  the y coordinate of the point to check
-- @treturn bool  true if the point is inside the polygon
function PseudoGame.graphics.Polygon:contains_point(x, y)
    local result = false
    for x0, y0, r, g, b, a, x1, y1 in self:edge_color_pairs() do
        if (y0 > y) ~= (y1 > y) and x < (x1 - x0) * (y - y0) / (y1 - y0) + x0 then
            result = not result
        end
    end
    return result
end
