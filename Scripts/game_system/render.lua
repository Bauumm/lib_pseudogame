u_execScript("game_system/player.lua")
u_execScript("game_system/style.lua")
u_execScript("game_system/math.lua")

function _reserve_cws(tbl, number)
	while #tbl > number do
		cw_destroy(tbl[1])
		table.remove(tbl, 1)
	end
	while #tbl < number do
		table.insert(tbl, cw_createNoCollision())
	end
end

background = {}
background.__index = background

function background:new()
	return setmetatable({cws = {}}, background)
end

function background:render()
	_reserve_cws(self.cws, l_getSides())
	local div = math.pi * 2 / l_getSides()
	local half_div = div / 2
	local distance = s_getBGTileRadius()
	for i=0, l_getSides() - 1 do
		local angle = div * i
		local current_color = {style:get_color(i)}
		if i % 2 == 0 and i == l_getSides() - 1 and l_getDarkenUnevenBackgroundChunk() then
			for i=1,3 do
				current_color[i] = current_color[i] / 1.4
			end
		end
		local vertices = {0, 0, 0, 0}
		vertices[5], vertices[6] = get_orbit(angle + half_div, distance)
		vertices[7], vertices[8] = get_orbit(angle - half_div, distance)
		local cw = self.cws[i + 1]
		cw_setVertexPos4(cw, unpack(vertices))
		cw_setVertexColor4Same(cw, unpack(current_color))
	end
end

pivot = {}
pivot.__index = pivot

function pivot:new()
	return setmetatable({cws = {}}, pivot)
end

function pivot:render(no_cap)
	_reserve_cws(self.cws, l_getSides() * 2)
	local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
	local pivot_radius = 0.75 * radius
	local div = math.pi / l_getSides()
	for i=0, l_getSides() - 1 do
		local s_angle = div * 2 * i
		local vertices = {}
		vertices[1], vertices[2] = get_orbit(s_angle - div, pivot_radius)
		vertices[3], vertices[4] = get_orbit(s_angle + div, pivot_radius)
		vertices[5], vertices[6] = get_orbit(s_angle + div, pivot_radius + 5)
		vertices[7], vertices[8] = get_orbit(s_angle - div, pivot_radius + 5)
		local cw0 = self.cws[i * 2 + 1]
		cw_setVertexPos4(cw0, unpack(vertices))
		cw_setVertexColor4Same(cw0, style:get_main_color())
		local cw1 = self.cws[i * 2 + 2]
		if not no_cap then
			cw_setVertexPos(cw1, 0, 0, 0)
			cw_setVertexPos(cw1, 1, 0, 0)
			cw_setVertexPos(cw1, 2, unpack(vertices, 3, 4))
			cw_setVertexPos(cw1, 3, unpack(vertices, 1, 2))
			cw_setVertexColor4Same(cw1, style:get_cap_color())
		else
			cw_setVertexPos4(cw1, 0, 0, 0, 0, 0, 0, 0, 0)
			cw_setVertexColor4Same(cw1, 0, 0, 0, 0)
		end
	end
end
