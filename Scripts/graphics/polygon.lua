u_execScript("cache.lua")

Polygon = {}
Polygon.__index = Polygon

-- The constructor for the Polygon class that represents a 2D polygon with a solid color
-- vertices: table = {x0, y0, x1, y1, ...}
-- colors: table = {r0, g0, b0, a0, r1, g1, b1, a1, ...}
-- return: Polygon
function Polygon:new(vertices, colors)
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
		vertex_count = vertex_count,
		_has_changed = true
	}, Polygon)
	obj.split4 = Cache:new(Polygon.split4, obj)
	obj.is_clockwise = Cache:new(Polygon.is_clockwise, obj)
	return obj
end

-- This iterator can be used like this:
-- 	for index, x, y, r, g, b, a in mypolygon:vertex_color_pairs() do
-- 		...
-- 	end
function Polygon:vertex_color_pairs()
	local index = 0
	return function()
		index = index + 1
		if index <= self.vertex_count then
			local vertex_index = index * 2
			local color_index = index * 4
			return index, self._vertices[vertex_index - 1], self._vertices[vertex_index], self._colors[color_index - 3], self._colors[color_index - 2], self._colors[color_index - 1], self._colors[color_index]
		end
	end
end

-- This iterator always gives the next vertex as well (and wraps around), so it can be used like this:
-- 	for x0, y0, r0, g0, b0, a0, x1, y1, r1, g1, b1, a1 in mypolygon:double_vertex_color_pairs() do
-- 		...
-- 	end
function Polygon:double_vertex_color_pairs()
	local index = 0
	return function()
		index = index + 1
		if index <= self.vertex_count then
			local vertex_index = index * 2
			local color_index = index * 4
			local index2 = index % self.vertex_count + 1
			local vertex_index2 = index2 * 2
			local color_index2 = index2 * 4
			return self._vertices[vertex_index - 1], self._vertices[vertex_index], self._colors[color_index - 3], self._colors[color_index - 2], self._colors[color_index - 1], self._colors[color_index], self._vertices[vertex_index2 - 1], self._vertices[vertex_index2], self._colors[color_index2 - 3], self._colors[color_index2 - 2], self._colors[color_index2 - 1], self._colors[color_index2]
		end
	end
end

-- adds a vertex with a vertex color to the polygon
-- x: number	-- the x coordinate of the vertex
-- y: number	-- the y coordinate of the vertex
-- r: number	-- the r component of the vertex color
-- g: number	-- the g component of the vertex color
-- b: number	-- the b component of the vertex color
-- a: number	-- the a component of the vertex color
function Polygon:add_vertex(x, y, r, g, b, a)
	self.vertex_count = self.vertex_count + 1
	self:set_vertex_pos(self.vertex_count, x, y)
	self:set_vertex_color(self.vertex_count, r, g, b, a)
	self:_changed()
end

function Polygon:_check_vert_index(index)
	if index > self.vertex_count or index <= 0 then
		error("Polygon: index is out of bounds!")
	end
end

-- removes a vertex and and its color from the polygon
-- index: number	-- the index of the vertex
function Polygon:remove_vertex(index)
	self:_check_vert_index(index)
	local vertex_index = index * 2
	for i=0,1 do
		table.remove(self._vertices, vertex_index - i)
	end
	local color_index = index * 4
	for i=0,3 do
		table.remove(self._colors, color_index - i)
	end
	self:_changed()
end

-- sets the position of a vertex
-- index: number	-- the index of the vertex
-- x: number		-- the x coordinate the vertex should be set to
-- y: number		-- the y coordinate the vertex should be set to
function Polygon:set_vertex_pos(index, x, y)
	self:_check_vert_index(index)
	local vertex_index = index * 2
	self._vertices[vertex_index - 1] = x
	self._vertices[vertex_index] = y
	self:_changed()
end

-- gets a vertex position
-- index: number		-- the index of the vertex
-- returns: number, number	-- the position of the vertex
function Polygon:get_vertex_pos(index)
	self:_check_vert_index(index)
	local vertex_index = index * 2
	return self._vertices[vertex_index - 1], self._vertices[vertex_index]
end

-- sets the color of a vertex
-- index: number	-- the index of the vertex
-- r: number		-- the r component of the vertex color
-- g: number		-- the g component of the vertex color
-- b: number		-- the b component of the vertex color
-- a: number		-- the a component of the vertex color
function Polygon:set_vertex_color(index, r, g, b, a)
	self:_check_vert_index(index)
	local color_index = index * 4
	self._colors[color_index - 3] = r
	self._colors[color_index - 2] = g
	self._colors[color_index - 1] = b
	self._colors[color_index] = a
	self:_changed()
end

-- gets a vertex color
-- index: number				-- the index of the vertex
-- returns: number, number, number, number	-- the color of the vertex
function Polygon:get_vertex_color(index)
	self:_check_vert_index(index)
	local color_index = index * 4
	return self._colors[color_index - 3], self._colors[color_index - 2], self._colors[color_index - 1], self._colors[color_index]
end

-- checks if the polygon is defined in clockwise order
-- return: bool
function Polygon:is_clockwise()
	local area = 0
	for x0, y0, r, g, b, a, x1, y1 in self:double_vertex_color_pairs() do
		area = area + (x1 - x0) * (y1 + y0)
	end
	return area > 0
end

-- Implementation of the sutherland hodgman algorithm for polygon clipping
-- Doesn't work with concave polygons
-- clipper_polygon: Polygon	-- the polygon that will contain the newly created clipped polygon
-- return: Polygon		-- Returns a polygon if copy is true
function Polygon:clip(clipper_polygon)
	local return_polygon = self
	local cw = self:is_clockwise()
	for x0, y0, r, g, b, a, x1, y1 in clipper_polygon:double_vertex_color_pairs() do
		return_polygon = return_polygon:slice(x0, y0, x1, y1, not cw, cw)
		if return_polygon.vertex_count == 0 then
			break
		end
	end
	return return_polygon
end

-- slice the polygon into two polygons at a line given by two points
-- x0: number			-- the x coordinate of the first point
-- y0: number			-- the y coordinate of the first point
-- x1: number			-- the x coordinate of the second point
-- y1: number			-- the y coordinate of the second point
-- left: bool			-- specifies if the part of the polygon on the left side of the line should be returned
-- right: bool			-- specifies if the part of the polygon on the right side of the line should be returned
-- return: Polygon, Polygon	-- returns either one or two polygons depending on left/right
function Polygon:slice(x0, y0, x1, y1, left, right)
	local dx, dy = x1 - x0, y1 - y0
	local left_polygon, right_polygon
	if left then
		left_polygon = Polygon:new()
	end
	if right then
		right_polygon = Polygon:new()
	end
	if not left and not right then
		error("Polygon: slice called without specifying which polygon to return!")
	end
	for ix, iy, ir, ig, ib, ia, kx, ky, kr, kg, kb, ka in self:double_vertex_color_pairs() do
		local i_pos, k_pos = dx * (iy-y0) - dy * (ix-x0), dx * (ky-y0) - dy * (kx-x0)
		local iside, kside = i_pos >= 0, k_pos >= 0
		if iside then
			-- point is on the left side
			if left then
				left_polygon:add_vertex(ix, iy, ir, ig, ib, ia)
			end
		else
			-- point is on the right side
			if right then
				right_polygon:add_vertex(ix, iy, ir, ig, ib, ia)
			end
		end
		if iside ~= kside then
			-- next point will be on the other side, so add the intersection point with the line
			local dikx, diky = ix - kx, iy - ky
			local num_part1 = (x0*y1 - y0*x1)
			local num_part2 = (ix*ky - iy*kx)
			local den = dy * dikx - dx * diky
			local x = (num_part1 * dikx + dx * num_part2) / den
			local y = (num_part1 * diky + dy * num_part2) / den

			-- interpolate between vertex colors to keep gradients
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
				left_polygon:add_vertex(x, y, r, g, b, a)
			end
			if right then
				right_polygon:add_vertex(x, y, r, g, b, a)
			end
		end
	end
	if left and right then
		return left_polygon, right_polygon
	elseif right then
		return right_polygon
	elseif left then
		return left_polygon
	end
end

-- splits the polygon into pairs of tables with 4 vertices and 4 colors each
-- return: table = {{x0, y0, x1, y1, x2, y2, x3, y3}, {r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3}, {x0, y0, x1, y1, x2, y2, x3, y3}, {r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3}, ...}
function Polygon:split4()
	if self.vertex_count == 0 then
		return
	end
	if self.vertex_count == 4 then
		return {self._vertices, self._colors}
	end
	local polygons = {}
	local offset = 0
	local polygon_index = 0
	local done = false
	while not done do
		local vertices = {}
		local colors = {}
		local color_size = 1
		for i=1,8 do
			local index = i + offset
			local coord = self._vertices[index]
			if coord == nil then
				index = (i - 1) % 2 + 1
				coord = self._vertices[index]
				done = true
			end
			vertices[i] = coord
			if i % 2 == 1 then
				local color_index = (index - 1) * 2 + 1
				for i=0,3 do
					colors[color_size + i] = self._colors[color_index + i]
				end
				color_size = color_size + 4
			end
		end
		polygon_index = polygon_index + 1
		offset = polygon_index * 6
		polygons[polygon_index * 2 - 1] = vertices
		polygons[polygon_index * 2] = colors
	end
	return polygons
end

-- copies the polygon
-- return: Polygon
function Polygon:copy()
	return Polygon:new({unpack(self._vertices)}, {unpack(self._colors)})
end

-- transform the vertices and vertex colors of the polygon
-- transform_func: function	-- a function that takes x, y, r, g, b, a and returns x, y, r, g, b, a
function Polygon:transform(transform_func)
	for index, x, y, r, g, b, a in self:vertex_color_pairs() do
		x, y, r, g, b, a = transform_func(x, y, r, g, b, a)
		self:set_vertex_pos(index, x, y)
		self:set_vertex_color(index, r, g, b, a)
	end
end

-- remove duplicate vertices, does not respect color
function Polygon:_remove_doubles()
	for i=self.vertex_count * 2, 1, -2 do
		if self._vertices[i - 1] == self._vertices[i - 3] and self._vertices[i] == self._vertices[i - 2] then
			self:remove_vertex(i / 2)
		end
	end
end

function Polygon:_changed()
	self.split4:invalidate()
	self.is_clockwise:invalidate()
	self._has_changed = true
end

-- returns: true if any data about the polygon has changed since the last call of this function (returns true if never called before)
function Polygon:has_changed()
	if self.has_changed then
		self.has_changed = false
		return true
	end
	return false
end
