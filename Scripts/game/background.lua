Background = {}
Background.__index = Background

-- the constructor for a games background
-- use background.polygon_collection to draw it
-- return: Background
function Background:new()
	return setmetatable({polygon_collection = PolygonCollection:new()}, Background)
end

-- update the backgrounds color, position and shape
function Background:update()
	self.polygon_collection:resize(l_getSides())
	local it = self.polygon_collection:iter()
	local div = math.pi * 2 / l_getSides()
	local half_div = div / 2
	local distance = s_getBGTileRadius()
	for i=0, l_getSides() - 1 do
		local angle = div * i + math.rad(s_getBGRotationOffset())
		local current_color = {style:get_color(i)}
		if i % 2 == 0 and i == l_getSides() - 1 and l_getDarkenUnevenBackgroundChunk() then
			for i=1,3 do
				current_color[i] = current_color[i] / 1.4
			end
		end
		local polygon = it()
		while polygon.vertex_count < 3 do
			polygon:add_vertex(0, 0, 0, 0, 0, 0)
		end
		polygon:set_vertex_pos(2, get_orbit(angle + half_div, distance))
		polygon:set_vertex_pos(3, get_orbit(angle - half_div, distance))
		for i=1,3 do
			polygon:set_vertex_color(i, unpack(current_color))
		end
	end
end
