--- Class for storing colors and some other visual settings (it does not do any weird calculations on top of them on its own! (like the normal game's styles do))
-- @classmod PseudoGame.game.Style
PseudoGame.game.Style = {}
PseudoGame.game.Style.__index = PseudoGame.game.Style

--- constructor for a style object
-- @tparam table style_table  the table with the initial style options
-- @tparam table style_table.main_color  the main color of the style (formatted like this: `{r, g, b, a}`)
-- @tparam[opt=style_table.main_color] table style_table.player_color  the player color (formatted like this: `{r, g, b, a}`)
-- @tparam[opt=style_table.main_color] table style_table.wall_color  the wall color (formatted like this: `{r, g, b, a}`)
-- @tparam table style_table.cap_color  the cap color of the style (formatted like this: `{r, g, b, a}`)
-- @tparam table style_table.background_colors  background colors (formatted like this: `{{r, g, b, a}, {r, g, b, a}, ...}`)
-- @tparam table style_table.layer_colors  3d layer colors (formatted like this: `{{r, g, b, a}, {r, g, b, a}, ...}`)
-- @tparam[opt=10] number style_table.layer_spacing  the spacing between 3d layers
-- @tparam[opt=false] bool style_table.connect_layers  specifies if the 3d layers should be connected using extra polygons to create solid 3d
-- @tparam[opt=false] bool style_table.gradient  specifies if the connected 3d layers should have gradients between the layers
-- @treturn Style
function PseudoGame.game.Style:new(style_table)
    local function check_color_property(name, default)
        if style_table[name] == nil then
            if default == nil then
                error("Cannot define style without " .. name .. "!")
            else
                style_table[name] = style_table[default]
            end
        end
        for i = 1, 4 do
            if style_table[name][i] == nil then
                error(name .. " must be a valid color table!")
            end
        end
    end
    check_color_property("main_color")
    check_color_property("player_color", "main_color")
    check_color_property("wall_color", "main_color")
    check_color_property("cap_color")
    local function check_color_list_property(name)
        if style_table[name] == nil then
            error(name .. " must be defined!")
        end
        for index, color in pairs(style_table[name]) do
            for i = 1, 4 do
                if color[i] == nil then
                    error(name .. " must contain valid color tables!")
                end
            end
        end
    end
    check_color_list_property("background_colors")
    check_color_list_property("layer_colors")
    style_table.layer_spacing = style_table.layer_spacing or 10
    return setmetatable(style_table, PseudoGame.game.Style)
end

--- gets the main color
-- @treturn table  color formatted like this: `{r, g, b, a}`
function PseudoGame.game.Style:get_main_color()
    return unpack(self.main_color)
end

--- gets the player color
-- @treturn table  color formatted like this: `{r, g, b, a}`
function PseudoGame.game.Style:get_player_color()
    return unpack(self.player_color)
end

--- gets the wall color
-- @treturn table  color formatted like this: `{r, g, b, a}`
function PseudoGame.game.Style:get_wall_color()
    return unpack(self.wall_color)
end

--- gets the cap color
-- @treturn table  color formatted like this: `{r, g, b, a}`
function PseudoGame.game.Style:get_cap_color()
    return unpack(self.cap_color)
end

--- gets a background color
-- @tparam number index  the index of the background panel
-- @treturn table  color formatted like this: `{r, g, b, a}`
function PseudoGame.game.Style:get_background_color(index)
    return unpack(self.background_colors[(index - 1) % #self.background_colors + 1])
end

--- gets a layer color
-- @tparam number index  the index of the 3d layer
-- @treturn table  color formatted like this: `{r, g, b, a}`
function PseudoGame.game.Style:get_layer_color(index)
    return unpack(self.layer_colors[(index - 1) % #self.layer_colors + 1])
end

--- gets the 3d layer spacing
-- @treturn number
function PseudoGame.game.Style:get_layer_spacing()
    return self.layer_spacing
end

--- gets if the 3d layers are supposed to be connected
-- @treturn bool
function PseudoGame.game.Style:get_connect_layers()
    return self.connect_layers
end

--- gets the style's 3d depth
-- @treturn number
function PseudoGame.game.Style:get_depth()
    return #self.layer_colors
end

--- a table that implements the style getters using the game's style functions (use this if you want to keep your existing style)
-- @tfield Style PseudoGame.game.level_style
PseudoGame.game.level_style = {
    _pulse3DDirection = 1,
    _pulse3D = 1,
    _last_pulse3D_update = -1,
    _depth = s_get3dDepth(),
    _s_get3dDepth = s_get3dDepth,
    _s_set3dDepth = s_set3dDepth,
}

function PseudoGame.game.level_style:_overwrite()
    self._depth = s_get3dDepth()
    s_set3dDepth(0)
    s_get3dDepth = function()
        return self._depth
    end
    s_set3dDepth = function(depth)
        self._depth = depth
    end
end

function PseudoGame.game.level_style:_restore()
    s_get3dDepth = self._s_get3dDepth
    s_set3dDepth = self._s_set3dDepth
    s_set3dDepth(self._depth)
end

function PseudoGame.game.level_style:_update_pulse3D(frametime)
    if self._last_pulse3D_update ~= l_getLevelTime() then
        self._last_pulse3D_update = l_getLevelTime()
        self._pulse3D = self._pulse3D + s_get3dPulseSpeed() * self._pulse3DDirection * frametime
        if self._pulse3D > s_get3dPulseMax() then
            self._pulse3DDirection = -1
        elseif self._pulse3D < s_get3dPulseMin() then
            self._pulse3DDirection = 1
        end
    end
end

function PseudoGame.game.level_style:get_main_color()
    return s_getMainColor()
end

function PseudoGame.game.level_style:get_player_color()
    return s_getPlayerColor()
end

function PseudoGame.game.level_style:get_wall_color()
    -- the actual wall color is inaccessible from lua
    -- -> TODO: change this once s_getWallColor exists
    return s_getMainColor()
end

function PseudoGame.game.level_style:get_cap_color()
    return s_getCapColorResult()
end

function PseudoGame.game.level_style:get_background_color(index)
    return s_getColor(index - 1)
end

function PseudoGame.game.level_style:get_layer_color(index)
    local r, g, b, a = s_get3DOverrideColor()
    local darken_mult = s_get3dDarkenMult()
    r = r / darken_mult
    g = g / darken_mult
    b = b / darken_mult
    a = a / s_get3dAlphaMult() - (index - 1) * s_get3dAlphaFalloff()
    if a > 255 then
        a = 255
    elseif a < 0 then
        a = 0
    end
    return r, g, b, a
end

function PseudoGame.game.level_style:get_layer_spacing()
    return s_get3dSpacing() * s_get3dPerspectiveMult() * s_get3dSkew() * self._pulse3D * 3.6 * 1.4
end

function PseudoGame.game.level_style:get_connect_layers()
    return self.connect_layers
end

function PseudoGame.game.level_style:get_depth()
    return self._depth
end
