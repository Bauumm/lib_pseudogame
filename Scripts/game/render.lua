Background = {}
Background.__index = Background

function Background:new()
	return setmetatable({polygon_collection = PolygonCollection:new()}, Background)
end

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

Pivot = {}
Pivot.__index = Pivot

function Pivot:new()
	return setmetatable({polygon_collection = PolygonCollection:new()}, Pivot)
end

function Pivot:update()
	self.polygon_collection:resize(l_getSides())
	local it = self.polygon_collection:iter()
	local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
	local pivot_radius = 0.75 * radius
	local div = math.pi / l_getSides()
	for i=0, l_getSides() - 1 do
		local s_angle = div * 2 * i
		local polygon = it()
		while polygon.vertex_count < 4 do
			polygon:add_vertex(0, 0, 0, 0, 0, 0)
		end
		polygon:set_vertex_pos(1, get_orbit(s_angle - div, pivot_radius))
		polygon:set_vertex_pos(2, get_orbit(s_angle + div, pivot_radius))
		polygon:set_vertex_pos(3, get_orbit(s_angle + div, pivot_radius + 5))
		polygon:set_vertex_pos(4, get_orbit(s_angle - div, pivot_radius + 5))
		for i=1,4 do
			polygon:set_vertex_color(i, style:get_main_color())
		end
	end
end

Cap = {}
Cap.__index = Cap

function Cap:new()
	return setmetatable({polygon = Polygon:new()}, Cap)
end

function Cap:update()
	local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
	local pivot_radius = 0.75 * radius
	local div = math.pi / l_getSides()
	while self.polygon.vertex_count > l_getSides() do
		self.polygon:remove_vertex(1)
	end
	while self.polygon.vertex_count < l_getSides() do
		self.polygon:add_vertex(0, 0, 0, 0, 0, 0)
	end
	for i=1, l_getSides() do
		local s_angle = div * 2 * i
		self.polygon:set_vertex_pos(i, get_orbit(s_angle - div, pivot_radius))
		self.polygon:set_vertex_color(i, style:get_cap_color())
	end
end
