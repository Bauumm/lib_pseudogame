Background = {}
Background.__index = Background

-- the constructor for a games background
-- use background.polygon_collection to draw it
-- style: Style	(optional)	-- the style to use (nil will use the default level style)
-- return: Background
function Background:new(style)
	return setmetatable({
		style = style or level_style,
		polygon_collection = PolygonCollection:new()
	}, Background)
end

-- update the backgrounds color, position and shape
function Background:update()
	local it = self.polygon_collection:creation_iter()
	local sides = l_getSides()
	local div = math.pi * 2 / sides
	local half_div = div / 2
	local distance = s_getBGTileRadius()
	for i=0, sides - 1 do
		local angle = div * i + math.rad(s_getBGRotationOffset())
		local current_color = {self.style:get_background_color(i + 1)}
		if i % 2 == 0 and i == sides - 1 and l_getDarkenUnevenBackgroundChunk() then
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
