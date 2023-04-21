--- Class for creating a pseudo 3d effect for a polygon collection
PseudoGame.game.Pseudo3D = {}
PseudoGame.game.Pseudo3D.__index = PseudoGame.game.Pseudo3D

--- the constructor for a Pseudo3D object
-- @tparam PolygonCollection polygon_collection  the collection of polygons to create a 3d effect for
-- @tparam[opt=level_style] Style style  the style to use (also defines which 3d effect to use)
function PseudoGame.game.Pseudo3D:new(polygon_collection, style)
	return setmetatable({
		--- @tfield Style style  the 3d effect's style
		style = style or level_style,
		--- @tfield PolygonCollection source_collection  the collection it's making a 3d effect for
		source_collection = polygon_collection,
		--- @tfield PolygonCollection polygon_collection  the polygons representing the 3d effect (use this for drawing)
		polygon_collection = PseudoGame.graphics.PolygonCollection:new()
	}, PseudoGame.game.Pseudo3D)
end

--- function to refill the polygon collection with the traditional layered 3d effect
-- @tparam number frametime  the time in 1/60s that passed since the last call of this function
function PseudoGame.game.Pseudo3D:update_layered(frametime)
	if self.style._update_pulse3D ~= nil then
		self.style._update_pulse3D(frametime)
	end
	local spacing = self.style:get_layer_spacing()
	local rad_rot = math.rad(l_getRotation() + 90)
	local cos_rot, sin_rot = math.cos(rad_rot), math.sin(rad_rot)
	local gen = self.polygon_collection:generator()
	for j=1, self._depth do
		local i = self._depth - j + 1
		local offset = i * spacing
		local new_pos_x = offset * cos_rot
		local new_pos_y = offset * sin_rot
		local override_color = {self.style:get_layer_color(i)}
		for polygon in collection:iter() do
			gen():copy_data_transformed(polygon, function(x, y)
				return x + new_pos_x, y + new_pos_y, unpack(override_color)
			end)
		end
	end
end

--- function to refill the polygon colection with a solid gradient 3d effect
-- @tparam number frametime  the time in 1/60s that passed since the last call of this function
function PseudoGame.game.Pseudo3D:update_gradient(frametime)
	if self.style._update_pulse3D ~= nil then
		self.style._update_pulse3D(frametime)
	end
	local function get_sorted_edges(collections, cb)
		local tmp_gen2 = self._tmp_collection2:generator()
		local rottrans = PseudoGame.graphics.effects:rotate(math.rad(-l_getRotation()))
		local nrottrans = PseudoGame.graphics.effects:rotate(math.rad(l_getRotation()))
		local edges = {}
		for i=1,#collections do
			for p in collections[i]:iter() do
				p:transform(rottrans)
				for x0, y0, r0, g0, b0, a0, x1, y1, r1, g1, b1, a1 in p:edge_color_pairs() do
					edges[#edges + 1] = {x0, y0, x1, y1}
				end
				p:transform(nrottrans)
			end
		end
		table.sort(edges, function(e0, e1)
			--return (e0[2]+e0[4])/2>(e1[2]+e1[4])/2
			local function show_line(x0, y0, x1, y1)
				local p=tmp_gen2()
				p:resize(4)
				p:set_vertex_pos(1, x0, y0)
				p:set_vertex_pos(2, x0, y0)
				p:set_vertex_pos(3, x1, y1)
				p:set_vertex_pos(4, x1, y1)
				for i=1,4 do
					p:set_vertex_color(i, 0, 0, 255, 255)
				end
				p:transform(nrottrans)
			end
			local function getyofx(x, e)
				return (e[4] - e[2]) / (e[3] - e[1]) * (x - e[1]) + e[2]
			end
			local isecta_start = math.max(math.min(e0[1], e0[3]), math.min(e1[1], e1[3]))
			local isecta_end = math.min(math.max(e0[1], e0[3]), math.max(e1[1], e1[3]))
			if isecta_start >= isecta_end then
				local avgy0 = (e0[2] + e0[4]) / 2
				local avgy1 = (e1[2] + e1[4]) / 2
				return avgy0 < avgy1
			else
			--	show_line(isecta_start, getyofx(isecta_start, e0), isecta_start, getyofx(isecta_start, e1))
				local function check_weird(num)
					if num ~= num then
						print("nan")
					elseif num >= math.huge then
						print("inf")
					end
				end
				check_weird(getyofx(isecta_start, e0))
				check_weird(getyofx(isecta_start, e1))
				check_weird(getyofx(isecta_end, e0))
				check_weird(getyofx(isecta_end, e1))
				return (getyofx(isecta_start, e0) - getyofx(isecta_start, e1) + getyofx(isecta_end, e0) - getyofx(isecta_end, e1)) < 0
			end
		end)
		for i=1,#edges do
			e = edges[i]
			e[1], e[2] = nrottrans(e[1], e[2])
			e[3], e[4] = nrottrans(e[3], e[4])
			cb(unpack(e))
		end
	end
	local rad_rot = math.rad(l_getRotation() + 90)
	local cos_rot, sin_rot = math.cos(rad_rot), math.sin(rad_rot)
	local gen = self.polygon_collection:generator()
	for j=1, self.depth do
		local i = self.depth - j + 1
		local offset = i * self.style:get_layer_spacing()
		local new_pos_x = offset * cos_rot
		local new_pos_y = offset * sin_rot
		local next_offset = (i - 1) * self.style:get_layer_spacing()
		local next_new_pos_x = next_offset * cos_rot
		local next_new_pos_y = next_offset * sin_rot
		local override_color = {self.style:get_layer_color(i)}
		local next_override_color = {self.style:get_layer_color(i - 1)}
		local cs = {}
		if self._wall_collection ~= nil then
			cs[#cs + 1] = self._wall_collection
		end
		if self.pivot ~= nil then
			cs[#cs + 1] = self.pivot.polygon_collection
		end
		if self._player_collection ~= nil then
			cs[#cs + 1] = self._player_collection
		end
		get_sorted_edges(cs, function(x0, y0, x1, y1)
			local side = gen()
			side:resize(4)
			side:set_vertex_pos(1, x0 + next_new_pos_x, y0 + next_new_pos_y)
			side:set_vertex_pos(2, x1 + next_new_pos_x, y1 + next_new_pos_y)
			side:set_vertex_pos(3, x1 + new_pos_x, y1 + new_pos_y)
			side:set_vertex_pos(4, x0 + new_pos_x, y0 + new_pos_y)
			for i=1,2 do
				side:set_vertex_color(i, unpack(next_override_color))
			end
			for i=3,4 do
				side:set_vertex_color(i, unpack(override_color))
			end
		end)
	end
end
