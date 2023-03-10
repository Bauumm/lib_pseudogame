u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")

Game = {}
Game.__index = Game

-- the constructor for a game object that recreates the game and allows direct access to each renderstage for transformation
-- style: Style	-- the style the game should use (nil will use the default level style)
-- return: Game
function Game:new(style)
	local obj = setmetatable({
		-- game objects
		background = Background:new(),
		walls = WallSystem:new(),
		player = CollidingPlayer:new(),
		pivot = Pivot:new(),
		cap = Cap:new(),

		-- game data
		depth = s_get3dDepth(),
		style = style or level_style,

		-- additional collections
		_collide_collection = PolygonCollection:new(),
		_cws = PolygonCollection:new(),
		wall_collection = PolygonCollection:new(),
		player_collection = PolygonCollection:new(),
		walls3d = PolygonCollection:new(),
		pivot3d = PolygonCollection:new(),
		player3d = PolygonCollection:new(),
		polygon_collection = PolygonCollection:new(),

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
				if not self.death_effect.initialized then
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
	}, Game)

	-- can't define at the top as it needs the player object
	obj.death_effect = DeathEffect:new(obj.player)
	return obj
end

-- overwrites the wall functions as well as custom walls function to modify the walls in this game
function Game:overwrite()
	overwrite_cw_functions(self._cws)
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

-- restores the original wall and custom wall functions
function Game:restore()
	restore_cw_functions()
	s_set3dDepth = self._oldSet3dDepth
	s_get3dDepth = self._oldGet3dDepth
	s_set3dDepth(self.depth)
	self.walls:restore()
end

function Game:_update_3D(walls, pivot, player)
	if self.style._update_pulse3D ~= nil then
		self.style:_update_pulse3D(self._frametime)
	end
	if self.depth > 0 then
		local rad_rot = math.rad(l_getRotation() + 90)
		local cos_rot, sin_rot = math.cos(rad_rot), math.sin(rad_rot)
		if walls then
			self.walls3d:clear()
		end
		if pivot then
			self.pivot3d:clear()
		end
		if player then
			self.player3d:clear()
		end
		for j=1, self.depth do
			local i = self.depth - j + 1
			local offset = i * self.style:get_layer_spacing()
			local new_pos_x = offset * cos_rot
			local new_pos_y = offset * sin_rot
			local override_color = {self.style:get_layer_color(i)}
			if walls then
				for polygon in self.wall_collection:iter() do
					self.walls3d:add(polygon:copy():transform(function(x, y)
						return x + new_pos_x, y + new_pos_y, unpack(override_color)
					end))
				end
			end
			if pivot then
				for polygon in self.pivot.polygon_collection:iter() do
					self.pivot3d:add(polygon:copy():transform(function(x, y)
						return x + new_pos_x, y + new_pos_y, unpack(override_color)
					end))
				end
			end
			if player then
				for polygon in self.player_collection:iter() do
					self.player3d:add(polygon:copy():transform(function(x, y)
						return x + new_pos_x, y + new_pos_y, unpack(override_color)
					end))
				end
			end
		end
	end
end

-- get the polygon / polygon collection of a renderstage (the enum can be found in utils.lua in the base pack)
-- this function also updates the renderstages using the data provided to the update method, renderstages that aren't required also won't be updated
-- render_stages: table	-- a table of numbers that represent the render stages (e.g. {RenderStage.WALLQUADS, RenderStage.PLAYERTRIS})
-- return: table	-- a table of polygon collections or polygons depending on the renderstage (CAPTRIS is the only render stage that only consists of a single polygon)
function Game:get_render_stages(render_stages)
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

-- update the game
-- frametime: number	-- the time in 1/60s that passed since the last call of this function
-- move: number		-- the current movement direction, so either -1, 0 or 1
-- focus: bool		-- true if the player is focusing, false otherwise
-- swap: bool		-- true if the swap key is pressed, false otherwise
function Game:update(frametime, move, focus, swap)
	self._ticked = true
	self._frametime = frametime
	self._move = move
	self._focus = focus
	self._swap = swap
end

-- puts all the renderstage's polygons into game.polygon_collection
function Game:draw()
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

-- draws all the renderstages onto the screen and updates it
function Game:draw_to_screen()
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
			screen:draw_polygon(collections[i])
		else
			screen:draw_polygon_collection(collections[i])
		end
	end
	screen:update()
end
