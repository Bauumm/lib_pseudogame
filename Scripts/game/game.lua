--- Class that creates and manages all the game components allowing direct access to each renderstage for transformation
-- @classmod PseudoGame.game.Game
PseudoGame.game.Game = {}
PseudoGame.game.Game.__index = PseudoGame.game.Game

--- the constructor for a game object 
-- @tparam[opt] table components  table telling the game what game components it needs to update, draw and which collections to return from `Game:update` (helps reducing lag if e.g. 3D isn't needed), just sets every component to true when not given
-- @tparam[opt=false] bool components.background  update and draw the background
-- @tparam[opt=false] bool components.walls  update and draw the walls
-- @tparam[opt=false] bool components.pivot  update and draw the pivot (including cap)
-- @tparam[opt=false] bool components.player  update and draw the player (including death effect)
-- @tparam[opt=false] bool components.pseudo3d  update and draw the 3d
-- @tparam[opt=level_style] Style style  the style the game should use
-- @treturn Game
function PseudoGame.game.Game:new(components, style)
	local obj = setmetatable({
		-- game data
		--- @tfield number depth  the game's 3d depth
		depth = s_get3dDepth(),
		--- @tfield Style style  the game's style
		style = style or PseudoGame.game.level_style,

		--- @tfield PolygonCollection polygon_collection  the collection the `Game:draw()` method draws into
		polygon_collection = PseudoGame.graphics.PolygonCollection:new(),

		-- inputs
		_frametime = 0,
		_move = 0,
		_focus = false,
		_swap = false,
		_ticked = false,

		--- @tfield table component_collections  a table with the game component names as keys containing the polygon_collections for each component (use this for customized drawing)
		-- @tfield PolygonCollection component_collections.background  the game's background (only exists if `components.background == true`)
		-- @tfield PolygonCollection component_collections.walls  the game's walls (only exists if `components.walls == true`)
		-- @tfield PolygonCollection component_collections.player  the game's player (only exists if `components.player == true`)
		-- @tfield PolygonCollection component_collections.pivot  the game's pivot (only exists if `components.pivot == true`)
		-- @tfield PolygonCollection component_collections.pseudo3d  the game's 3d (only exists if `components.pseudo3d == true`)
		component_collections = {},

		--- @tfield table collections  same as `Game.component_collections` but instead of having named keys it's an ordered list that has the collections in the following order: background, pseudo3d, walls, pivot, player (if one of these components is not defined the list will be shorter and the other components are moved (use `Game.component_collections` for constant keys))
		collections = {},

		-- update functions for game components for internal use
		_component_update = {}

		-- ldoc doesn't like the comments if i put them to the actual definitions

		--- @tfield Background background  the game's background (only exists if `components.background == true`)

		--- @tfield WallSystem walls  the game's wall system (only exists if `components.walls == true`)

		--- @tfield Player player  the game's player (uses `PseudoGame.game.basic_collision_handler` by default) (only exists if `components.player == true`)

		--- @tfield DeathEffect death_effect  the game's player's death effect (only exists if `components.player == true`)

		--- @tfield Pivot pivot  the game's pivot (only exists if `components.pivot == true`)

		--- @tfield Cap cap  the game's cap (only exists if `components.pivot == true`)
	}, PseudoGame.game.Game)
	if components == nil then
		obj:_init({
			background = true,
			walls = true,
			player = true,
			pivot = true,
			pseudo3d = true
		}, style)
	else
		obj:_init(components, style)
	end
	return obj
end

function PseudoGame.game.Game:_init(components, style)
	-- initialize game objects
	if components.background then
		self.background = PseudoGame.game.Background:new(style)
		self.component_collections.background = self.background.polygon_collection
		self.collections[#self.collections + 1] = self.background.polygon_collection
		self._component_update[#self._component_update + 1] = function(self)
			self.background:update()
		end
	end
	if components.pseudo3d then
		self._3d_collection = PseudoGame.graphics.PolygonCollection:new()
		self.component_collections.pseudo3d = self._3d_collection
		self.collections[#self.collections + 1] = self._3d_collection
	end
	if components.walls then
		self.walls = PseudoGame.game.WallSystem:new(style)
		self._cws = PseudoGame.graphics.PolygonCollection:new()
		self._wall_collection = PseudoGame.graphics.PolygonCollection:new()
		self.component_collections.walls = self._wall_collection
		self.collections[#self.collections + 1] = self._wall_collection
		self._component_update[#self._component_update + 1] = function(self)
			if not self.death_effect.dead then
				self.walls:update(self._frametime)
			end
			self._wall_collection:clear()
			self._wall_collection:ref_add(self.walls.polygon_collection)
			self._wall_collection:ref_add(self._cws)
		end
	end
	if components.pivot then
		self.pivot = PseudoGame.game.Pivot:new(style)
		self.cap = PseudoGame.game.Cap:new(style)
		self._pivot_collection = PseudoGame.graphics.PolygonCollection:new()
		self.component_collections.pivot = self._pivot_collection
		self.collections[#self.collections + 1] = self._pivot_collection
		self._component_update[#self._component_update + 1] = function(self)
			self.cap:update()
			self.pivot:update()
			self._pivot_collection:clear()
			self._pivot_collection:ref_add(self.pivot.polygon_collection)
			self._pivot_collection:add(self.cap.polygon)
		end
	end
	if components.player then
		self.player = PseudoGame.game.Player:new(style, PseudoGame.game.basic_collision_handler)
		self.death_effect = PseudoGame.game.DeathEffect:new(self.player)
		self._collide_collection = PseudoGame.graphics.PolygonCollection:new()
		self._player_collection = PseudoGame.graphics.PolygonCollection:new()
		self.component_collections.player = self._player_collection
		self.collections[#self.collections + 1] = self._player_collection
		self._component_update[#self._component_update + 1] = function(self)
			self.death_effect:update(self._frametime)
			self._collide_collection:clear()
			self._collide_collection:ref_add(self.walls.polygon_collection)
			for polygon in self._cws:iter() do
				if polygon.extra_data.collision or polygon.extra_data.deadly then
					self._collide_collection:add(polygon)
				end
			end
			self.player:update(self._frametime, self._move, self._focus, self._swap, self._collide_collection)
			self._player_collection:clear()
			self._player_collection:add(self.player.polygon)
			self._player_collection:ref_add(self.death_effect.polygon_collection)
		end
	end

	-- add later for proper update order while retaining render order
	if components.pseudo3d then
		self._component_update[#self._component_update + 1] = function(self)
			self:_update_3D()
		end
	end

	-- initialize connected layers
	if self.style:get_connect_layers() then
		self._tmp_collection = PseudoGame.graphics.PolygonCollection:new()
		self._tmp_collection2 = PseudoGame.graphics.PolygonCollection:new()
		self._update_3D = PseudoGame.game.Game._update_connected_3D
	end
end

--[[--
overwrites the wall functions as well as custom walls function to modify the walls in this game (only if walls were specified in the components)
IMPORTANT: once this function was called, you have to call `Game:restore()` before exiting your level (e.g. in `onUnload`), otherwise it may break other levels at random, as this function overwrites some default game functions
]]
function PseudoGame.game.Game:overwrite()
	if not u_inMenu() then
		s_set3dDepth(0)
		self._oldSet3dDepth = s_set3dDepth
		self._oldGet3dDepth = s_get3dDepth
		s_set3dDepth = function(depth)
			self.depth = depth
		end
		s_get3dDepth = function()
			return self.depth
		end
		if self.walls ~= nil then
			self.walls:overwrite()
			PseudoGame.game.overwrite_cw_functions(self._cws)
		end
	end
end

--- restores the original wall and custom wall functions
function PseudoGame.game.Game:restore()
	s_set3dDepth = self._oldSet3dDepth
	s_get3dDepth = self._oldGet3dDepth
	s_set3dDepth(self.depth)
	if self.walls ~= nil then
		self.walls:restore()
		PseudoGame.game.restore_cw_functions()
	end
end

function PseudoGame.game.Game:_update_connected_3D()
	if self.style._update_pulse3D ~= nil then
		self.style:_update_pulse3D(self._frametime)
	end
	if self.depth > 0 then
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
		local gen = self._3d_collection:generator()
		local tmp_gen = self._tmp_collection:generator()
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
end

function PseudoGame.game.Game:_update_3D()
	if self.style._update_pulse3D ~= nil then
		self.style:_update_pulse3D(self._frametime)
	end
	if self.depth > 0 then
		local rad_rot = math.rad(l_getRotation() + 90)
		local cos_rot, sin_rot = math.cos(rad_rot), math.sin(rad_rot)
		local gen = self._3d_collection:generator()
		for j=1, self.depth do
			local i = self.depth - j + 1
			local offset = i * self.style:get_layer_spacing()
			local new_pos_x = offset * cos_rot
			local new_pos_y = offset * sin_rot
			local override_color = {self.style:get_layer_color(i)}
			local function process_collection(collection)
				if collection ~= nil then
					for polygon in collection:iter() do
						gen():copy_data_transformed(polygon, function(x, y)
							return x + new_pos_x, y + new_pos_y, unpack(override_color)
						end)
					end
				end
			end
			process_collection(self._wall_collection)
			if self.pivot ~= nil then
				process_collection(self.pivot.polygon_collection)
			end
			process_collection(self._player_collection)
		end
	end
end

--- update the game
-- @tparam number frametime  the time in 1/60s that passed since the last call of this function
-- @tparam number move  the current movement direction, so either -1, 0 or 1
-- @tparam bool focus  true if the player is focusing, false otherwise
-- @tparam bool swap  true if the swap key is pressed, false otherwise
function PseudoGame.game.Game:update(frametime, move, focus, swap)
	self._frametime = frametime
	self._move = move
	self._focus = focus
	self._swap = swap

	for i = 1, #self._component_update do
		self._component_update[i](self)
	end
end

--- puts all component collections polygons into `Game.polygon_collection`
function PseudoGame.game.Game:draw()
	self.polygon_collection:clear()
	for i = 1, #self.collections do
		self.polygon_collection:ref_add(self.collections[i])
	end
end

--- draws all component collections onto the screen and updates it
function PseudoGame.game.Game:draw_to_screen()
	for i = 1, #self.collections do
		PseudoGame.graphics.screen:draw_polygon_collection(self.collections[i])
	end
	PseudoGame.graphics.screen:update()
end
