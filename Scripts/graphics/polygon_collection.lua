PolygonCollection = {}
PolygonCollection.__index = PolygonCollection

function PolygonCollection:new()
	return setmetatable({
		_polygons = {},
		_free_indices = {},
		_highest_index = 0
	}, PolygonCollection)
end

function PolygonCollection:add(polygon)
	local index
	if #self._free_indices == 0 then
		self._highest_index = self._highest_index + 1
		index = self._highest_index
	else
		index = self._free_indices[1]
		table.remove(self._free_indices, 1)
	end
	self._polygons[index] = polygon
	return index
end

function PolygonCollection:remove(index)
	self._polygons[index] = nil
	if index == self._highest_index then
		self._highest_index = self._highest_index - 1
	else
		self._free_indices[#self._free_indices + 1] = index
	end
end

function PolygonCollection:get(index)
	return self._polygons[index]
end

function PolygonCollection:copy_add(polygon_collection)
	for polygon in polygon_collection:iter() do
		self:add(polygon:copy())
	end
end

function PolygonCollection:ref_add(polygon_collection)
	for polygon in polygon_collection:iter() do
		self:add(polygon)
	end
end

function PolygonCollection:blend(polygon_collection, blend_func, blend_collection)
	blend_collection:clear()
	for polygon0 in self:iter() do
		for polygon1 in polygon_collection:iter() do
			local clipped_polygon = polygon0:clip(polygon1)
			local r, g, b, a = polygon0:get_vertex_color(1)
			for index, x, y in clipped_polygon:vertex_color_pairs() do
				clipped_polygon:set_vertex_color(index, blend_func(r, g, b, a, polygon1:get_vertex_color(1)))
			end
			if clipped_polygon.vertex_count > 0 then
				blend_collection:add(clipped_polygon)
			end
		end
	end
end

function PolygonCollection:iter()
	local index = 0
	return function()
		local polygon
		while polygon == nil do
			index = index + 1
			if index > self._highest_index then
				return
			end
			polygon = self._polygons[index]
		end
		return polygon
	end
end

function PolygonCollection:clear()
	self._highest_index = 0
	self._free_indices = {}
end
