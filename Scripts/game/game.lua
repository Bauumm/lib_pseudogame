--- Class that creates and manages all the game components allowing direct access to each component's polygons for transformation
-- @classmod PseudoGame.game.Game
PseudoGame.game.Game = {}
PseudoGame.game.Game.__index = PseudoGame.game.Game

--- the constructor for a game object
-- @tparam[opt] table options  options for the game object
-- @tparam[opt] table options.components  table telling the game what game components it needs to update, draw and which collections to return from `Game:update` (helps reducing lag if e.g. 3D isn't needed), just sets every component to true when not given
-- @tparam[opt=false] bool options.components.background  update and draw the background
-- @tparam[opt=false] bool options.components.walls  update and draw the walls
-- @tparam[opt=false] bool options.components.pivot  update and draw the pivot (including cap)
-- @tparam[opt=false] bool options.components.player  update and draw the player (including death effect)
-- @tparam[opt=false] bool options.components.pseudo3d  update and draw the 3d
-- @tparam[opt=level_style] Style options.style  the style the game should use
-- @tparam[opt] table options.walls  wall system options
-- @tparam[opt] table options.player  player options
-- @tparam[opt] table options.pivot  pivot options (only for the game component, not the actual pivot object)
-- @tparam[opt=true] bool options.pivot.cap  disables the cap if false
-- @treturn Game
function PseudoGame.game.Game:new(options)
    if options == nil then
        options = {}
    end
    local obj = setmetatable({
        -- game data
        --- @tfield Style style  the game's style
        style = options.style or PseudoGame.game.level_style,

        --- @tfield table options  the game's options
        options = options,

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
        _component_update = {},

        -- ldoc doesn't like the comments if i put them to the actual definitions

        --- @tfield Background background  the game's background (only exists if `components.background == true`)

        --- @tfield WallSystem walls  the game's wall system (only exists if `components.walls == true`)

        --- @tfield Player player  the game's player (uses `PseudoGame.game.basic_collision_handler` by default) (only exists if `components.player == true`)

        --- @tfield DeathEffect death_effect  the game's player's death effect (only exists if `components.player == true`)

        --- @tfield Pivot pivot  the game's pivot (only exists if `components.pivot == true`)

        --- @tfield Cap cap  the game's cap (only exists if `components.pivot == true`)

        --- @tfield Pseudo3D pseudo3d  the game's 3d effect (only exists if `components.pseudo3d == true`)
    }, PseudoGame.game.Game)
    if options.components == nil then
        options.components = {
            background = true,
            walls = true,
            player = true,
            pivot = true,
            pseudo3d = true,
        }
    end
    obj:_init()
    return obj
end

function PseudoGame.game.Game:_init()
    -- initialize game objects
    local headless = u_isHeadless()
    if self.options.components.background then
        self.background = PseudoGame.game.Background:new(self.options.style)
        self.component_collections.background = self.background.polygon_collection
        self.collections[#self.collections + 1] = self.background.polygon_collection
        if not headless then
            self._component_update[#self._component_update + 1] = function(self)
                self.background:update()
            end
        end
    end
    if self.options.components.pseudo3d then
        self._3d_collection = PseudoGame.graphics.PolygonCollection:new()
        self.pseudo3d = PseudoGame.game.Pseudo3D:new(self._3d_collection, self.options.style)
        self.component_collections.pseudo3d = self.pseudo3d.polygon_collection
        self.collections[#self.collections + 1] = self.pseudo3d.polygon_collection
    end
    if self.options.components.walls then
        self.walls = PseudoGame.game.WallSystem:new(self.options.walls, self.options.style)
        self._cws = PseudoGame.graphics.PolygonCollection:new()
        self._wall_collection = PseudoGame.graphics.PolygonCollection:new()
        self.component_collections.walls = self._wall_collection
        self.collections[#self.collections + 1] = self._wall_collection
        self._component_update[#self._component_update + 1] = function(self)
            if self.death_effect == nil or not self.death_effect.dead then
                self.walls:update(self._frametime)
            end
            self._wall_collection:clear()
            self._wall_collection:ref_add(self.walls.polygon_collection)
            self._wall_collection:ref_add(self._cws)
        end
    end
    if self.options.components.pivot then
        self.options.pivot = self.options.pivot or {}
        self.pivot = PseudoGame.game.Pivot:new(self.options.style)
        if self.options.pivot.cap == nil or self.options.pivot.cap then
            self.cap = PseudoGame.game.Cap:new(self.options.style)
            self._pivot_collection = PseudoGame.graphics.PolygonCollection:new()
        else
            self._pivot_collection = self.pivot.polygon_collection
        end
        self.component_collections.pivot = self._pivot_collection
        self.collections[#self.collections + 1] = self._pivot_collection
        if not headless then
		if self.options.pivot.cap == nil or self.options.pivot.cap then
		    self._component_update[#self._component_update + 1] = function(self)
			self.cap:update()
			self.pivot:update()
			self._pivot_collection:clear()
			self._pivot_collection:ref_add(self.pivot.polygon_collection)
			self._pivot_collection:add(self.cap.polygon)
		    end
		else
		    self._component_update[#self._component_update + 1] = function(self)
			self.pivot:update()
		    end
		end
	end
    end
    if self.options.components.player then
        if self.options.player == nil then
            self.options.player = {
                collision_handler = PseudoGame.game.basic_collision_handler,
            }
        end
        self.player = PseudoGame.game.Player:new(self.options.player, self.options.style)
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
    if self.options.components.pseudo3d and not headless then
        self._component_update[#self._component_update + 1] = function(self)
            self._3d_collection:clear()
            if self.options.components.walls then
                self._3d_collection:ref_add(self._wall_collection)
            end
            if self.options.components.pivot then
                self._3d_collection:ref_add(self.pivot.polygon_collection)
            end
            if self.options.components.player then
                self._3d_collection:ref_add(self._player_collection)
            end
            self.pseudo3d:update(self._frametime)
        end
    end
end

--[[--
overwrites the wall functions as well as custom walls function to modify the walls in this game (only if walls were specified in the components)
IMPORTANT: once this function was called, you have to call `Game:restore()` before exiting your level (e.g. in `onPreUnload`), otherwise it may break other levels at random, as this function overwrites some default game functions
]]
function PseudoGame.game.Game:overwrite()
    if not u_inMenu() then
        if self.style._overwrite ~= nil then
            self.style:_overwrite()
        end
        if self.walls ~= nil then
            self.walls:overwrite()
            PseudoGame.game.overwrite_cw_functions(self._cws)
        end
    end
end

--- restores the original wall and custom wall functions
function PseudoGame.game.Game:restore()
    if self.style._overwrite ~= nil then
        self.style:_restore()
    end
    if self.walls ~= nil then
        self.walls:restore()
        PseudoGame.game.restore_cw_functions()
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
