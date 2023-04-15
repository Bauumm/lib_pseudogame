effects = {}

-- get the polygons that represent the intersection two collections
-- polygon_collection1: PolygonCollection		-- the first collection
-- polygon_collection2: PolygonCollection		-- the second collection
-- blend_func: function					-- this function determines the color of the new polygons based on the color of the two intersected ones, so it should take r0, g0, b0, a0, r1, g1, b1, a1 and return r, g, b, a
-- blend_collection: PolygonCollection (optional)	-- the collection the resulting polygons are added to (the collection is cleared before the operation) (not required if draw_directly = true)
-- tmp_gen: function (optional)				-- a polygon generator used to improve clipping performance (the polygons it creates should not be rendered)
-- draw_directly: bool (optional)			-- draws the resulting polygons immediately instead of adding them to a collection
function effects.blend(polygon_collection1, polygon_collection2, blend_func, blend_collection, tmp_gen, draw_directly)
	if not draw_directly then
		blend_collection:clear()
	end
	for polygon1 in polygon_collection1:iter() do
		for polygon2 in polygon_collection2:iter() do
			local clipped_polygon = polygon1:clip(polygon2, tmp_gen)
			if clipped_polygon ~= nil then
				local r, g, b, a = polygon1:get_vertex_color(1)
				for index, x, y in clipped_polygon:vertex_color_pairs() do
					clipped_polygon:set_vertex_color(index, blend_func(r, g, b, a, polygon2:get_vertex_color(1)))
				end
				if draw_directly then
					screen:draw_polygon(clipped_polygon)
				else
					blend_collection:add(clipped_polygon)
				end
			end
		end
	end
end

-- creates polygons along the edges of some polygons
-- polygon_collection: PolygonCollection	-- the polygon collection the outlines should be made for
-- outline_collection: PolygonCollection	-- the polygon collection the outlines will be added to
-- thickness: number				-- the thickness of the outlines
-- color: table					-- the color of the outlines, should be formatted like this: {r, g, b, a}
function effects.outline(polygon_collection, outline_collection, thickness, color)
	local gen = outline_collection:generator()
	for polygon in polygon_collection:iter() do
		for x0, y0, r0, g0, b0, a0, x1, y1, r1, g1, b1, a1 in polygon:double_vertex_color_pairs() do
			local dx, dy = x1 - x0, y1 - y0
			local len = math.sqrt(dx * dx + dy * dy)
			local thick_x, thick_y = dx / len * thickness, dy / len * thickness
			local new_poly = gen()
			new_poly:resize(4)
			new_poly:set_vertex_pos(1, x0 - thick_x - thick_y, y0 - thick_y + thick_x)
			new_poly:set_vertex_pos(2, x0 - thick_x + thick_y, y0 - thick_y - thick_x)
			new_poly:set_vertex_pos(3, x1 + thick_x + thick_y, y1 + thick_y - thick_x)
			new_poly:set_vertex_pos(4, x1 + thick_x - thick_y, y1 + thick_y + thick_x)
			for i=1,4 do
				new_poly:set_vertex_color(i, unpack(color))
			end
		end
	end
end

-- generates a transformation function that rotates vertices
-- angle: number	-- the angle to rotate
-- return: function	-- the transformation function
function effects.rotate(angle)
	local cos, sin = math.cos(angle), math.sin(angle)
	return function(x, y, r, g, b, a)
		return x * cos - y * sin, x * sin + y * cos, r, g, b, a
	end
end

-- generates a transformation function that mirrors vertices
-- mirror_x: bool	-- whether it should mirror along the x axis
-- mirror_y: bool	-- whether it should mirror along the y axis
-- return: function	-- the transformation function
function effects.mirror(mirror_x, mirror_y)
	mirror_x = mirror_x and -1 or 1
	mirror_y = mirror_y and -1 or 1
	return function(x, y, r, g, b, a)
		return x * mirror_x, y * mirror_y, r, g, b, a
	end
end
