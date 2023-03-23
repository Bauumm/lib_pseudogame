effects = {}

-- get the polygons that represent the intersection two collections
-- polygon_collection1: PolygonCollection	-- the first collection
-- polygon_collection2: PolygonCollection	-- the second collection
-- blend_func: function				-- this function determines the color of the new polygons based on the color of the two intersected ones, so it should take r0, g0, b0, a0, r1, g1, b1, a1 and return r, g, b, a
-- blend_collection: PolygonCollection		-- the collection the resulting polygons are added to (the collection is cleared before the operation)
function effects.blend(polygon_collection1, polygon_collection2, blend_func, blend_collection)
	blend_collection:clear()
	for polygon1 in polygon_collection1:iter() do
		for polygon2 in polygon_collection2:iter() do
			local clipped_polygon = polygon1:clip(polygon2, true)
			if clipped_polygon ~= nil then
				local r, g, b, a = polygon1:get_vertex_color(1)
				for index, x, y in clipped_polygon:vertex_color_pairs() do
					clipped_polygon:set_vertex_color(index, blend_func(r, g, b, a, polygon2:get_vertex_color(1)))
				end
				blend_collection:add(clipped_polygon)
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
