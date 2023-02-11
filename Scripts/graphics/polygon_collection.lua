PolygonCollection = {}
PolygonCollection.__index = PolygonCollection

function PolygonCollection:new()
	return setmetatable({
		_polygons = {},
		size = 0
	}, PolygonCollection)
end

function PolygonCollection:add(polygon)
	self.size = self.size + 1
	self._polygons[self.size] = polygon
end

function PolygonCollection:copy_over(polygon_collection)
	self:clear()
	self:copy_add(polygon_collection)
end

function PolygonCollection:ref_over(polygon_collection)
	self:clear()
	self:ref_add(polygon_collection)
end

function PolygonCollection:copy_add(polygon_collection)
	for polygon in polygon_collection:iter() do
		self.size = self.size + 1
		self._polygons[self.size] = polygon:copy()
	end
end

function PolygonCollection:ref_add(polygon_collection)
	for polygon in polygon_collection:iter() do
		self.size = self.size + 1
		self._polygons[self.size] = polygon
	end
end

function PolygonCollection:blend(polygon_collection, blend_func, blend_collection)
	blend_collection:clear()
	for polygon0 in self:iter() do
		for polygon1 in polygon_collection:iter() do
			local clipped_polygon = polygon0:clip(polygon1)
			if clipped_polygon.vertex_count > 0 then
				blend_collection:add(clipped_polygon)
			end
		end
	end
end

function PolygonCollection:iter()
	local index = 0
	return function()
		index = index + 1
		if index <= self.size then
			return self._polygons[index]
		end
	end
end

function PolygonCollection:clear()
	self.size = 0
end
