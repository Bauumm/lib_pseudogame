u_execScript("cache.lua")

Polygon = {}
Polygon.__index = Polygon

-- The constructor for the Polygon class that represents a 2D polygon with a solid color
-- vertices: table = {x0, y0, x1, y1, ...}
-- color: table = {r, g, b, a}
-- return: Polygon
function Polygon:new(vertices, color)
	if #self.vertices % 2 ~= 0 then
		error("Polygon: vertices must be 2D points in this format: {x0, y0, x1, y1, ...}")
	end
	local obj = setmetatable({
		vertices = vertices or {},
		color = color or {0, 0, 0, 0}
	}, Polygon)
	obj.split4 = Cache:new(Polygon.split4, obj)
	return obj
end

-- This iterator can be used like this:
-- 	for x, y in mypolygon:vertex_pairs() do
-- 		...
-- 	end
function Polygon:vertex_pairs()
	local index = 0
	local count = #self.vertices
	return function()
		index = index + 2
		if index <= count then
			return self.vertices[index - 1], self.vertices[index]
		end
	end
end

-- Implementation of the sutherland hodgman algorithm for polygon clipping
-- Doesn't work with concave polygons
-- clipper_polygon: Polygon	-- the polygon that will contain the newly created clipped polygon
-- copy_vertices: bool		-- if false / nil the current polygon will be edited otherwise a new one is created
-- copy_color: bool		-- if copy_vertices is true this sets whether the color should also be copied
-- return: nil / Polygon	-- Returns a polygon if copy_vertices is true
function Polygon:clip(clipper_polygon, copy_vertices, copy_color)
	-- Don't use this code as reference I made it unreadable to improve performance
	local verts
	if copy_vertices then
		verts = {unpack(self.vertices)}
	else
		verts = self.vertices
	end
	self:_remove_doubles()
	clipper_polygon:_remove_doubles()
	for i=1, #clipper_polygon.vertices, 2 do
		local x1, y1 = clipper_polygon.vertices[i], clipper_polygon.vertices[i + 1]
		local x2, y2 = clipper_polygon.vertices[(i + 1) % #clipper_polygon.vertices + 1], clipper_polygon.vertices[(i + 2) % #clipper_polygon.vertices + 1]
		local dx, dy = x2 - x1, y2 - y1
		local const_num_part = (x1*y2 - y1*x2)
		local first_x, first_y
		local poly_size = 2
		for i = 1, #verts, 2 do
			local ix, iy = verts[i], verts[i + 1]
			local kx, ky = verts[(i + 1) % #verts + 1], verts[(i + 2) % #verts + 1]
			local i_pos, k_pos = dx * (iy-y1) - dy * (ix-x1), dx * (ky-y1) - dy * (kx-x1)
			local case0, case1, case2 = i_pos < 0 and k_pos < 0, i_pos >= 0 and k_pos < 0, i_pos < 0 and k_pos >= 0
			local isect, add_this = case1 or case2, case0 or case1
			if isect then
				local dikx, diky = ix - kx, iy - ky
				local other_num_part = (ix*ky - iy*kx)
				local den = dy * dikx - dx * diky
				if first_x ~= nil then
					poly_size = poly_size + 2
					verts[poly_size - 1] = (const_num_part * dikx + dx * other_num_part) / den
					verts[poly_size] = (const_num_part * diky + dy * other_num_part) / den
				else
					first_x = (const_num_part * dikx + dx * other_num_part) / den
					first_y = (const_num_part * diky + dy * other_num_part) / den
				end
			end
			if add_this then
				if first_x ~= nil then
					poly_size = poly_size + 2
					verts[poly_size - 1] = kx
					verts[poly_size] = ky
				else
					first_x = kx
					first_y = ky
				end
			end
		end
		verts[1] = first_x
		verts[2] = first_y
		while #verts > poly_size do
			verts[#verts] = nil
		end
		self:_remove_doubles()
		if #verts == 0 then
			break
		end
	end
	if copy_vertices then
		if copy_color then
			return Polygon:new(verts, {unpack(self.color)})
		else
			return Polygon:new(verts, self.color)
		end
	end
end

-- slice the polygon into two polygons at a line given by two points
-- x0: number			-- the x coordinate of the first point
-- y0: number			-- the y coordinate of the first point
-- x1: number			-- the x coordinate of the second point
-- y1: number			-- the y coordinate of the second point
-- copy_color: bool		-- if the color should be copied
-- return: Polygon, Polygon	-- the resulting polygons with the first one being on the left side of the line and the second one being on the right side of the line if you go from x0, y0 to x1, y1
function Polygon:slice(x0, y0, x1, y1, copy_color)
	local dx, dy = x1 - x0, y1 - y0
	local left_polygon
	local right_polygon
	if copy_color then
		left_polygon = Polygon:new({}, {unpack(self.color)})
		right_polygon = Polygon:new({}, {unpack(self.color)})
	else
		left_polygon = Polygon:new({}, self.color)
		right_polygon = Polygon:new({}, self.color)
	end
	for i = 1, #self.vertices, 2 do
		local ix, iy = self.vertices[i], self.vertices[i + 1]
		local kx, ky = self.vertices[(i + 1) % #self.vertices + 1], self.vertices[(i + 2) % #self.vertices + 1]
		local i_pos, k_pos = dx * (iy-y0) - dy * (ix-x0), dx * (ky-y0) - dy * (kx-x0)
		local iside, kside = i_pos >= 0, k_pos >= 0
		if iside then
			left_polygon.vertices[#left_polygon.vertices + 1] = ix
			left_polygon.vertices[#left_polygon.vertices + 1] = iy
		else
			right_polygon.vertices[#right_polygon.vertices + 1] = ix
			right_polygon.vertices[#right_polygon.vertices + 1] = iy
		end
		if iside ~= kside then
			local dikx, diky = ix - kx, iy - ky
			local num_part1 = (x0*y1 - y0*x1)
			local num_part2 = (ix*ky - iy*kx)
			local den = dy * dikx - dx * diky
			local x = (num_part1 * dikx + dx * num_part2) / den
			local y = (num_part1 * diky + dy * num_part2) / den
			left_polygon.vertices[#left_polygon.vertices + 1] = x
			left_polygon.vertices[#left_polygon.vertices + 1] = y
			right_polygon.vertices[#right_polygon.vertices + 1] = x
			right_polygon.vertices[#right_polygon.vertices + 1] = y
		end
	end
	return left_polygon, right_polygon
end

-- splits the polygon into tables with 4 vertices each
-- return: table = {{x0, y0, x1, y1, x2, y2, x3, y3}, {x0, y0, x1, y1, x2, y2, x3, y3}, ...}
function Polygon:split4()
	if #self.vertices == 0 then
		return
	end
	local polygons = {}
	local offset = 0
	local polygon_index = 0
	local done = false
	while not done do
		local polygon = {}
		for i=1,8 do
			local coord = self.vertices[i + offset]
			if coord == nil then
				polygon[i] = self.vertices[(i - 1) % 2 + 1]
				done = true
			else
				polygon[i] = coord
			end
		end
		polygon_index = polygon_index + 1
		offset = polygon_index * 6
		polygons[polygon_index] = polygon
	end
	return polygons
end

-- remove duplicate vertices
function Polygon:_remove_doubles()
	for i=#self.vertices, 1, -2 do
		if self.vertices[i - 1] == self.vertices[i - 3] and self.vertices[i] == self.vertices[i - 2] then
			table.remove(self.vertices, i)
			table.remove(self.vertices, i - 1)
		end
	end
end
