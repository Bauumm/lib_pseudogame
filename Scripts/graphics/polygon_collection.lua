PseudoGame.graphics.PolygonCollection = {}
PseudoGame.graphics.PolygonCollection.__index = PseudoGame.graphics.PolygonCollection

--- the constructor for a polygon collection which is basically a list of polygons with a few extra capabilities and more optimized for frequent clearing and refilling
-- @treturn PolygonCollection  the newly created polygon collection
function PseudoGame.graphics.PolygonCollection:new()
	return setmetatable({
		_polygons = {},
		_free_indices = {},
		_highest_index = 0,
		size = 0
	}, PseudoGame.graphics.PolygonCollection)
end

--- add a polygon to the collection
-- @tparam Polygon polygon  the polygon to add
-- @treturn number  the index of the polygon in the collection
function PseudoGame.graphics.PolygonCollection:add(polygon)
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

--- make the collection be a certain size by deleting polygons if it's too big and creating new ones if it's too small
-- @tparam number size  the amount of polygons that will be in the collection
function PseudoGame.graphics.PolygonCollection:resize(size)
	local diff = self._highest_index - #self._free_indices - size
	for i=1,diff do
		self:remove(self._highest_index)
	end
	for i=-1,diff,-1 do
		self:add(PseudoGame.graphics.Polygon:new())
	end
end

--- remove a polygon from the collection (this does not shift other indices)
-- @tparam number index  the index of the polygon that should be deleted
function PseudoGame.graphics.PolygonCollection:remove(index)
	self._polygons[index] = nil
	if index == self._highest_index then
		self._highest_index = self._highest_index - 1
	else
		self._free_indices[#self._free_indices + 1] = index
	end
	self.size = self.size - 1
end

--- get a polygon from the collection
-- @tparam number index  the index of the polygon in the collection
-- @treturn Polygon  the polygon at the index in the collection
function PseudoGame.graphics.PolygonCollection:get(index)
	if index > self._highest_index then
		return
	end
	return self._polygons[index]
end

--- add the polygons from another collection to this one by copying them
-- @tparam PolygonCollection polygon_collection  the collection with the polygons that should be added
function PseudoGame.graphics.PolygonCollection:copy_add(polygon_collection)
	for polygon in polygon_collection:iter() do
		self:add(polygon:copy())
	end
end

--- add the polygons from another collection to this one by referencing them
-- @tparam PolygonCollection polygon_collection  the collection with the polygons that should be added
function PseudoGame.graphics.PolygonCollection:ref_add(polygon_collection)
	for polygon in polygon_collection:iter() do
		self:add(polygon)
	end
end

--[[--
iterate over all polygons like this:
for polygon in mypolygoncollection:iter() do
	...
end
]]
function PseudoGame.graphics.PolygonCollection:iter()
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


--[[--
recreate all polygons while reusing the old ones like this (avoids table allocation so this is very good for performance):
local gen = polygon_collection:generator()
for i=1,100 do
	local polygon = gen()
	-- since it reuses old polygons and creates new empty ones if there is none we don't know what vertex count the polygon has, so it makes sense to set it
	-- setting it to the number you need directly instead of setting it to 0 and adding vertices is better for performance (less memory allocation)
	polygon:resize(4)
	...
end
]]
function PseudoGame.graphics.PolygonCollection:generator()
	local index = 0
	self:clear()
	return function()
		index = index + 1
		self._highest_index = index
		self.size = index
		local polygon = self._polygons[index]
		if polygon == nil then
			polygon = PseudoGame.graphics.Polygon:new()
			self._polygons[index] = polygon
		end
		return polygon
	end
end

--- transform the vertices and vertex colors of all polygons in the collection
-- @tparam function transform_func  a function that takes x, y, r, g, b, a and returns x, y, r, g, b, a
function PseudoGame.graphics.PolygonCollection:transform(transform_func)
	for polygon in self:iter() do
		polygon:transform(transform_func)
	end
end

--- clear all polygons from this collection
function PseudoGame.graphics.PolygonCollection:clear()
	self._highest_index = 0
	self._free_indices = {}
	self.size = 0
end