u_execScript("game_system/style.lua")
u_execScript("game_system/math.lua")

render = {
	player_pos = {0, 0},
	player_cw = nil,
	pivot_cws = {},
	background_cws = {}
}

function render:_reserve_cws(tbl, number)
	while #tbl > number do
		cw_destroy(tbl[1])
		table.remove(tbl, 1)
	end
	while #tbl < number do
		table.insert(tbl, cw_createNoCollision())
	end
end

function render:background()
	self:_reserve_cws(self.background_cws, l_getSides())
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
		local cw = self.background_cws[i + 1]
		cw_setVertexPos4(cw, unpack(vertices))
		cw_setVertexColor4Same(cw, unpack(current_color))
	end
end

function render:pivot()
	self:_reserve_cws(self.pivot_cws, l_getSides() * 2)
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
		local cw0 = self.pivot_cws[i * 2 + 1]
		cw_setVertexPos4(cw0, unpack(vertices))
		cw_setVertexColor4Same(cw0, style:get_main_color())
		local cw1 = self.pivot_cws[i * 2 + 2]
		cw_setVertexPos4(cw1, 0, 0, 0, 0, unpack(vertices, 1, 4))
		cw_setVertexColor4Same(cw1, style:get_cap_color())
	end
end

function render:player(focus)
	if self.player_cw == nil then
		self.player_cw = cw_createNoCollision()
	end
	local radius = l_getRadiusMin() * (l_getPulse() / l_getPulseMin()) + l_getBeatPulse()
	local player_angle = u_getPlayerAngle()
	local player_size = 7.3 + (focus and -1.5 or 3)
	self.player_pos[1], self.player_pos[2] = get_orbit(player_angle, radius)
	local vertices = {}
	vertices[1], vertices[2] = get_orbit(player_angle, 7.3, self.player_pos)
	vertices[3], vertices[4] = get_orbit(player_angle + math.rad(100), player_size, self.player_pos)
	vertices[5], vertices[6] = get_orbit(player_angle - math.rad(100), player_size, self.player_pos)
	vertices[7], vertices[8] = get_orbit(player_angle, 7.3, self.player_pos)
	cw_setVertexPos4(self.player_cw, unpack(vertices))
	cw_setVertexColor4Same(self.player_cw, style:get_main_color())
end
