--- Class that creates and manages all the game components allowing direct access to each renderstage for transformation
-- @classmod PseudoGame.game.Game
PseudoGame.game.Game = {}
PseudoGame.game.Game.__index = PseudoGame.game.Game

--- the constructor for a game object 
-- @tparam[opt=level_style] Style style  the style the game should use (nil will use the default level style)
-- @treturn Game
function PseudoGame.game.Game:new(style)
	local obj = setmetatable({
		-- game objects
		--- @tfield Background background  the game's background
		background = PseudoGame.game.Background:new(style),
		--- @tfield WallSystem walls  the game's wall system
		walls = PseudoGame.game.WallSystem:new(style),
		--- @tfield Player player  the game's player (uses `PseudoGame.game.basic_collision_handler` by default)
		player = PseudoGame.game.Player:new(style, PseudoGame.game.basic_collision_handler),
		--- @tfield Pivot pivot  the game's pivot
		pivot = PseudoGame.game.Pivot:new(style),
		--- @tfield Cap cap  the game's cap
		cap = PseudoGame.game.Cap:new(style),

		-- game data
		--- @tfield number depth  the game's 3d depth
		depth = s_get3dDepth(),
		--- @tfield Style style  the game's style
		style = style or PseudoGame.game.level_style,

		-- additional collections
		_collide_collection = PseudoGame.graphics.PolygonCollection:new(),
		_cws = PseudoGame.graphics.PolygonCollection:new(),
		--- @tfield PolygonCollection wall_collection  a collection containing all walls (and custom walls) of the game
		wall_collection = PseudoGame.graphics.PolygonCollection:new(),
		--- @tfield PolygonCollection player_collection  a collection containing the game's player and its death effect
		player_collection = PseudoGame.graphics.PolygonCollection:new(),
		--- @tfield PolygonCollection walls3d  a collection containing the 3d layers of all walls (and custom walls)
		walls3d = PseudoGame.graphics.PolygonCollection:new(),
		--- @tfield PolygonCollection pivot3d  a collection containing the 3d layers of the pivot
		pivot3d = PseudoGame.graphics.PolygonCollection:new(),
		--- @tfield PolygonCollection player3d  a collection containing the 3d layers of the player (and its death effect)
		player3d = PseudoGame.graphics.PolygonCollection:new(),
		--- @tfield PolygonCollection polygon_collection  the collection the `Game:draw()` method draws into
		polygon_collection = PseudoGame.graphics.PolygonCollection:new(),

		-- inputs
		_frametime = 0,
		_move = 0,
		_focus = false,
		_swap = false,
		_ticked = false,

		-- collection update/getting
		_render_stages = {
			[RenderStage.BACKGROUNDTRIS] = function(self)
				self.background:update()
				return self.background.polygon_collection
			end,
			[RenderStage.WALLQUADS] = function(self)
				if not self.death_effect.dead then
					self.walls:update(self._frametime)
				end
				self.wall_collection:clear()
				self.wall_collection:ref_add(self.walls.polygon_collection)
				self.wall_collection:ref_add(self._cws)
				return self.wall_collection
			end,
			[RenderStage.CAPTRIS] = function(self)
				self.cap:update()
				return self.cap.polygon
			end,
			[RenderStage.PIVOTQUADS] = function(self)
				self.pivot:update()
				return self.pivot.polygon_collection
			end,
			[RenderStage.PLAYERTRIS] = function(self)
				self.death_effect:update(self._frametime)
				self._collide_collection:clear()
				self._collide_collection:ref_add(self.walls.polygon_collection)
				for polygon in self._cws:iter() do
					if polygon.extra_data.collision or polygon.extra_data.deadly then
						self._collide_collection:add(polygon)
					end
				end
				self.player:update(self._frametime, self._move, self._focus, self._swap, self._collide_collection)
				self.player_collection:clear()
				self.player_collection:add(self.player.polygon)
				self.player_collection:ref_add(self.death_effect.polygon_collection)
				return self.player_collection
			end,
			[RenderStage.WALLQUADS3D] = function(self)
				return self.walls3d
			end,
			[RenderStage.PIVOTQUADS3D] = function(self)
				return self.pivot3d
			end,
			[RenderStage.PLAYERTRIS3D] = function(self)
				return self.player3d
			end
		}
	}, PseudoGame.game.Game)

	-- can't define at the top as it needs the player object
	obj.death_effect = PseudoGame.game.DeathEffect:new(obj.player)
	if obj.style:get_connect_layers() then
		obj._tmp_collection = PseudoGame.game.PolygonCollection:new()
		obj._update_3D = PseudoGame.game.Game._update_connected_3D
	end
	return obj
end

--[[--
overwrites the wall functions as well as custom walls function to modify the walls in this game
IMPORTANT: once this function was called, you have to call Game:restore() before exiting your level (e.g. in onUnload), otherwise it may break other levels at random, as this function overwrites some default game functions
]]
function PseudoGame.game.Game:overwrite()
	if not u_inMenu() then
		PseudoGame.game.overwrite_cw_functions(self._cws)
		s_set3dDepth(0)
		self._oldSet3dDepth = s_set3dDepth
		self._oldGet3dDepth = s_get3dDepth
		s_set3dDepth = function(depth)
			self.depth = depth
		end
		s_get3dDepth = function()
			return self.depth
		end
		self.walls:overwrite()
	end
end

--- restores the original wall and custom wall functions
function PseudoGame.game.Game:restore()
	PseudoGame.game.restore_cw_functions()
	s_set3dDepth = self._oldSet3dDepth
	s_get3dDepth = self._oldGet3dDepth
	s_set3dDepth(self.depth)
	self.walls:restore()
end

function PseudoGame.game.Game:_update_connected_3D(walls, pivot, player)
	if self.style._update_pulse3D ~= nil then
		self.style:_update_pulse3D(self._frametime)
	end
	if self.depth > 0 then
		local rad_rot = math.rad(l_getRotation() + 90)
		local cos_rot, sin_rot = math.cos(rad_rot), math.sin(rad_rot)
		local wall_gen, pivot_gen, player_gen
		if walls then
			wall_gen = self.walls3d:generator()
		end
		if pivot then
			pivot_gen = self.pivot3d:generator()
		end
		if player then
			player_gen = self.player3d:generator()
		end
		local tmp_gen = self._tmp_collection:generator()
		for j=1, self.depth do
			local i = self.depth - j + 1
			local offset = i * self.style:get_layer_spacing()
			local new_pos_x = offset * cos_rot
			local new_pos_y = offset * sin_rot
			local override_color = {self.style:get_layer_color(i)}
			local function process_collection(collection, generator)
				for polygon in collection:iter() do
					local new_polygon = tmp_gen()
					new_polygon:copy_data_transformed(polygon, function(x, y)
						return x + new_pos_x, y + new_pos_y, 0, 0, 0, 0
					end)
					for i=1,polygon.vertex_count do
						local next_i = i % polygon.vertex_count + 1
						local side = generator()
						side:resize(4)
						side:set_vertex_pos(1, polygon:get_vertex_pos(i))
						side:set_vertex_pos(2, polygon:get_vertex_pos(next_i))
						side:set_vertex_pos(3, new_polygon:get_vertex_pos(next_i))
						side:set_vertex_pos(4, new_polygon:get_vertex_pos(i))
						for i=1,4 do
							side:set_vertex_color(i, unpack(override_color))
						end
					end
				end
			end
			if walls then
				process_collection(self.wall_collection, wall_gen)
			end
			if pivot then
				process_collection(self.pivot.polygon_collection, pivot_gen)
			end
			if player then
				process_collection(self.player_collection, player_gen)
			end
		end
	end
end

function PseudoGame.game.Game:_update_3D(walls, pivot, player)
	if self.style._update_pulse3D ~= nil then
		self.style:_update_pulse3D(self._frametime)
	end
	if self.depth > 0 then
		local rad_rot = math.rad(l_getRotation() + 90)
		local cos_rot, sin_rot = math.cos(rad_rot), math.sin(rad_rot)
		local wall_gen, pivot_gen, player_gen
		if walls then
			wall_gen = self.walls3d:generator()
		end
		if pivot then
			pivot_gen = self.pivot3d:generator()
		end
		if player then
			player_gen = self.player3d:generator()
		end
		for j=1, self.depth do
			local i = self.depth - j + 1
			local offset = i * self.style:get_layer_spacing()
			local new_pos_x = offset * cos_rot
			local new_pos_y = offset * sin_rot
			local override_color = {self.style:get_layer_color(i)}
			if walls then
				for polygon in self.wall_collection:iter() do
					wall_gen():copy_data_transformed(polygon, function(x, y)
						return x + new_pos_x, y + new_pos_y, unpack(override_color)
					end)
				end
			end
			if pivot then
				for polygon in self.pivot.polygon_collection:iter() do
					pivot_gen():copy_data_transformed(polygon, function(x, y)
						return x + new_pos_x, y + new_pos_y, unpack(override_color)
					end)
				end
			end
			if player then
				for polygon in self.player_collection:iter() do
					player_gen():copy_data_transformed(polygon, function(x, y)
						return x + new_pos_x, y + new_pos_y, unpack(override_color)
					end)
				end
			end
		end
	end
end

--[[--
get the polygon / polygon collection of a renderstage (the enum can be found in utils.lua in the base pack)
this function also updates the renderstages using the data provided to the update method, renderstages that aren't required also won't be updated
]]
-- @tparam tab render_stages  a table of numbers that represent the render stages (e.g. {RenderStage.WALLQUADS, RenderStage.PLAYERTRIS})
-- @treturn tab  a table of polygon collections or polygons depending on the renderstage (CAPTRIS is the only render stage that only consists of a single polygon)
function PseudoGame.game.Game:get_render_stages(render_stages)
	local walls3d, pivot3d, player3d = false, false, false
	local result = {}
	for i=1,#render_stages do
		local render_stage = render_stages[i]
		result[i] = self._render_stages[render_stage](self)
		if render_stage == RenderStage.WALLQUADS3D then
			walls3d = true
		end
		if render_stage == RenderStage.PIVOTQUADS3D then
			pivot3d = true
		end
		if render_stage == RenderStage.PLAYERTRIS3D then
			player3d = true
		end
	end
	if (walls3d or pivot3d or player3d) and self._ticked then
		self._ticked = false
		self:_update_3D(walls3d, pivot3d, player3d)
	end
	return result
end

--- update the game
-- @tparam number frametime  the time in 1/60s that passed since the last call of this function
-- @tparam number move  the current movement direction, so either -1, 0 or 1
-- @tparam bool focus  true if the player is focusing, false otherwise
-- @tparam bool swap  true if the swap key is pressed, false otherwise
function PseudoGame.game.Game:update(frametime, move, focus, swap)
	self._ticked = true
	self._frametime = frametime
	self._move = move
	self._focus = focus
	self._swap = swap
end

--- puts all the renderstage's polygons into game.polygon_collection
function PseudoGame.game.Game:draw()
	local collections = self:get_render_stages({
		RenderStage.BACKGROUNDTRIS,
		RenderStage.WALLQUADS3D,
		RenderStage.PIVOTQUADS3D,
		RenderStage.PLAYERTRIS3D,
		RenderStage.WALLQUADS,
		RenderStage.CAPTRIS,
		RenderStage.PIVOTQUADS,
		RenderStage.PLAYERTRIS
	})
	self.polygon_collection:clear()
	for i=1,8 do
		if i == 6 then
			self.polygon_collection:add(collections[i])
		else
			self.polygon_collection:ref_add(collections[i])
		end
	end
end

--- draws all the renderstages onto the screen and updates it
function PseudoGame.game.Game:draw_to_screen()
	local collections = self:get_render_stages({
		RenderStage.BACKGROUNDTRIS,
		RenderStage.WALLQUADS3D,
		RenderStage.PIVOTQUADS3D,
		RenderStage.PLAYERTRIS3D,
		RenderStage.WALLQUADS,
		RenderStage.CAPTRIS,
		RenderStage.PIVOTQUADS,
		RenderStage.PLAYERTRIS
	})
	for i=1,8 do
		if i == 6 then
			PseudoGame.graphics.screen:draw_polygon(collections[i])
		else
			PseudoGame.graphics.screen:draw_polygon_collection(collections[i])
		end
	end
	PseudoGame.graphics.screen:update()
end
