-- TODO: side scalings
PseudoGame.game.Style = {}
PseudoGame.game.Style.__index = PseudoGame.game.Style

-- constructor for a style object used to overwrite the default colors and to have more control over them from lua
-- style_table: {
-- 	main_color: {r, g, b, a},		-- the main color of the style
-- 	player_color: {r, g, b, a},		-- the player color, will use the main color if not specified
-- 	wall_color: {r, g, b, a},		-- the wall color, will use the main color if not specified
-- 	cap_color: {r, g, b, a},		-- the cap color of the style
-- 	background_colors: {{r, g, b, a}, ...},	-- the colors used for the background panels
-- 	layer_colors: {{r, g, b, a}, ...}	-- the colors used for the 3d layers
-- 	layer_spacing: number			-- the spacing between 3d layers
-- 	connect_layers: bool			-- specifies if the 3d layers should be connected using extra polygons to create solid 3d
-- }
-- return: Style
function PseudoGame.game.Style:new(style_table)
	local function check_color_property(name, default)
		if style_table[name] == nil then
			if default == nil then
				error("Cannot define style without " .. name .. "!")
			else
				style_table[name] = style_table[default]
			end
		end
		for i=1,4 do
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
			for i=1,4 do
				if color[i] == nil then
					error(name .. " must contain valid color tables!")
				end
			end
		end
	end
	check_color_list_property("background_colors")
	check_color_list_property("layer_colors")
	style_table.layer_spacing = style_table.layer_spacing or 10
	return setmetatable(style_table, Style)
end

-- gets the main color
-- return: r, g, b, a
function PseudoGame.game.Style:get_main_color()
	return unpack(self.main_color)
end

-- gets the player color
-- return: r, g, b, a
function PseudoGame.game.Style:get_player_color()
	return unpack(self.player_color)
end

-- gets the wall color
-- return: r, g, b, a
function PseudoGame.game.Style:get_wall_color()
	return unpack(self.wall_color)
end

-- gets the cap color
-- return: r, g, b, a
function PseudoGame.game.Style:get_cap_color()
	return unpack(self.cap_color)
end

-- gets a background color
-- index: number	-- the index of the background panel
-- return: r, g, b, a
function PseudoGame.game.Style:get_background_color(index)
	return unpack(self.background_colors[(index - 1) % #self.background_colors + 1])
end

-- gets a layer color
-- index: number	-- the index of the 3d layer
-- return: r, g, b, a
function PseudoGame.game.Style:get_layer_color(index)
	return unpack(self.layer_colors[(index - 1) % #self.layer_colors + 1])
end

-- gets the 3d layer spacing
-- return: number
function PseudoGame.game.Style:get_layer_spacing()
	return self.layer_spacing
end

-- gets if the 3d layers are supposed to be connected
-- return: bool
function PseudoGame.game.Style:get_connect_layers()
	return self.connect_layers
end

-- a table that implements the style getters using the game's style functions
PseudoGame.game.level_style = {
	pulse3DDirection = 1,
	pulse3D = 1,
	last_pulse3D_update = -1
}

function PseudoGame.game.level_style:_update_pulse3D(frametime)
	if self.last_pulse3D_update ~= l_getLevelTime() then
		self.last_pulse3D_update = l_getLevelTime()
		self.pulse3D = self.pulse3D + s_get3dPulseSpeed() * self.pulse3DDirection * frametime
		if self.pulse3D > s_get3dPulseMax() then
			self.pulse3DDirection = -1
		elseif self.pulse3D < s_get3dPulseMin() then
			self.pulse3DDirection = 1
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
	return s_get3dSpacing() * s_get3dPerspectiveMult() * s_get3dSkew() * self.pulse3D * 3.6 * 1.4
end

function PseudoGame.game.level_style:get_connect_layers()
	return self.connect_layers
end
