--- Class that creates and manages all the game components allowing direct access to each renderstage for transformation
-- @classmod PseudoGame.game.Game
PseudoGame.game.Game = {}
PseudoGame.game.Game.__index = PseudoGame.game.Game

--- the constructor for a game object 
-- @tparam[opt=level_style] Style style  the style the game should use
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
		_wall_collection = PseudoGame.graphics.PolygonCollection:new(),
		_player_collection = PseudoGame.graphics.PolygonCollection:new(),
		_pivot_collection = PseudoGame.graphics.PolygonCollection:new(),
		_3d_collection = PseudoGame.graphics.PolygonCollection:new(),
		--- @tfield PolygonCollection polygon_collection  the collection the `Game:draw()` method draws into
		polygon_collection = PseudoGame.graphics.PolygonCollection:new(),

		-- inputs
		_frametime = 0,
		_move = 0,
		_focus = false,
		_swap = false,
		_ticked = false,

		-- collection update/getting
		render_stages = {
			background = function(self)
				self.background:update()
				return self.background.polygon_collection
			end,
			walls = function(self)
				if not self.death_effect.dead then
					self.walls:update(self._frametime)
				end
				self.wall_collection:clear()
				self.wall_collection:ref_add(self.walls.polygon_collection)
				self.wall_collection:ref_add(self._cws)
				return self.wall_collection
			end,
			pivot = function(self)
				self.cap:update()
				self.pivot:update()
				self._pivot_collection:clear()
				self._pivot_collection:ref_add(self.pivot.polygon_collection)
				self._pivot_collection:add(self.cap.polygon)
				return self._pivot_collection
			end,
			player = function(self)
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
			pseudo3d = function(self)
				self._update_3D()
				return self._3d_collection
			end
		}
	}, PseudoGame.game.Game)

	-- can't define at the top as it needs the player object
	obj.death_effect = PseudoGame.game.DeathEffect:new(obj.player)
	if obj.style:get_connect_layers() then
		obj._tmp_collection = PseudoGame.graphics.PolygonCollection:new()
		obj._update_3D = PseudoGame.game.Game._update_connected_3D
	end
	return obj
end

--[[--
overwrites the wall functions as well as custom walls function to modify the walls in this game
IMPORTANT: once this function was called, you have to call `Game:restore()` before exiting your level (e.g. in `onUnload`), otherwise it may break other levels at random, as this function overwrites some default game functions
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

--- give the game the data it needs to update (it doesn't update anything in this function)
-- @tparam number frametime  the time in 1/60s that passed since the last call of this function
-- @tparam number move  the current movement direction, so either -1, 0 or 1
-- @tparam bool focus  true if the player is focusing, false otherwise
-- @tparam bool swap  true if the swap key is pressed, false otherwise
function PseudoGame.game.Game:set_inputs(frametime, move, focus, swap)
	self._frametime = frametime
	self._move = move
	self._focus = focus
	self._swap = swap
end

--- puts all the renderstage's polygons into `Game.polygon_collection`
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
