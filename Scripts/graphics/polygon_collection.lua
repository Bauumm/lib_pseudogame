PolygonCollection = {}
PolygonCollection.__index = PolygonCollection

-- the constructor for a polygon collection which is basically a list of polygons with a few extra capabilities and more optimized for frequent clearing and refilling
-- return: PolygonCollection	-- the newly created polygon collection
function PolygonCollection:new()
	return setmetatable({
		_polygons = {},
		_free_indices = {},
		_highest_index = 0,
		size = 0
	}, PolygonCollection)
end

-- add a polygon to the collection
-- polygon: Polygon	-- the polygon to add
-- return: number	-- the index of the polygon in the collection
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
	self.size = self.size + 1
	return index
end

-- make the collection be a certain size by deleting polygons if it's too big and creating new ones if it's too small
-- size: number	-- the amount of polygons that will be in the collection
function PolygonCollection:resize(size)
	local diff = self._highest_index - #self._free_indices - size
	for i=1,diff do
		self:remove(self._highest_index)
	end
	for i=-1,diff,-1 do
		self:add(Polygon:new())
	end
end

-- remove a polygon from the collection (this does not shift other indices)
-- index: number	-- the index of the polygon that should be deleted
function PolygonCollection:remove(index)
	self._polygons[index] = nil
	if index == self._highest_index then
		self._highest_index = self._highest_index - 1
	else
		self._free_indices[#self._free_indices + 1] = index
	end
	self.size = self.size - 1
end

-- get a polygon from the collection
-- index: number	-- the index of the polygon in the collection
-- return: Polygon	-- the polygon at the index in the collection
function PolygonCollection:get(index)
	if index > self._highest_index then
		return
	end
	return self._polygons[index]
end

-- add the polygons from another collection to this one by copying them
-- polygon_collection: PolygonCollection	-- the collection with the polygons that should be added
function PolygonCollection:copy_add(polygon_collection)
	for polygon in polygon_collection:iter() do
		self:add(polygon:copy())
	end
end

-- add the polygons from another collection to this one by referencing them
-- polygon_collection: PolygonCollection	-- the collection with the polygons that should be added
function PolygonCollection:ref_add(polygon_collection)
	for polygon in polygon_collection:iter() do
		self:add(polygon)
	end
end

-- get the polygons that represent the intersection of of this collection with another one
-- polygon_collection: PolygonCollection	-- the collection to intersect with
-- blend_func: function				-- this function determines the color of the new polygons based on the color of the two intersected ones, so it should take r0, g0, b0, a0, r1, g1, b1, a1 and return r, g, b, a
-- blend_collection: PolygonCollection		-- the collection the resulting polygons are added to (the collection is cleared before the operation)
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

-- iterate over all polygons like this:
-- for polygon in mypolygoncollection:iter() do
-- 	...
-- end
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


-- recreate all polygons while reusing the old ones like this (avoids table allocation so this is good for performance):
-- local it = polygon_collection:creation_iter()
-- for i=1,100 do
-- 	local polygon = it()
-- 	...
-- end
function PolygonCollection:creation_iter()
	local index = 0
	self:clear()
	return function()
		index = index + 1
		self._highest_index = index
		self.size = index
		local polygon = self._polygons[index]
		if polygon == nil then
			polygon = Polygon:new()
			self._polygons[index] = polygon
		end
		return polygon
	end
end

-- transform the vertices and vertex colors of all polygons in the collection
-- transform_func: function	-- a function that takes x, y, r, g, b, a and returns x, y, r, g, b, a
function PolygonCollection:transform(transform_func)
	for polygon in PolygonCollection:iter() do
		polygon:transform(transform_func)
	end
end

-- clear all polygons from this collection
function PolygonCollection:clear()
	self._highest_index = 0
	self._free_indices = {}
	self.size = 0
end
