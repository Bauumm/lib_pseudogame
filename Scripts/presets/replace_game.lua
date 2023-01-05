u_execScript("cw_drawing/layer.lua")
u_execScript("cw_drawing/layers.lua")
u_execScript("game_system/render.lua")
u_execScript("game_system/player.lua")
u_execScript("game_system/death_effect.lua")
u_execScript("game_system/walls.lua")
u_execScript("invisible.lua")
replace_game = {
	pulse3DDirection = 1,
	pulse3D = 1
}

function replace_game:init()
	self.depth = s_get3dDepth()
	s_set3dDepth(0)
	if self.depth > 0 then
		self.foreground3D = layer:new()
		self.main3D = layer:new()
		self.player3D = player:new()
		self.pivot3D = pivot:new()
	end
	self.background_layer = layer:new()
	self.background = background:new()
	self.pivot = pivot:new()
	self.wall_layer = layer:new()
	self.foreground_layer = layer:new()
	self.player = player:new()
	self.death_effect = death_effect:new(self.player)
	self.death_effect_layer = layer:new()
	layers:select(self.wall_layer)
end

function replace_game:onInput(frametime, movement, focus)
	self.frametime = frametime
	self.player:update(frametime, focus)
	self.death_effect:update(frametime)

	layers:select(self.background_layer)
	self.background:render()

	layers:select(self.foreground_layer)
	self.pivot:render()
	self.player:render()

	layers:select(self.death_effect_layer)
	self.death_effect:render()

	if self.depth > 0 then
		self.player3D:update(frametime, focus)
		layers:select(self.foreground3D)
		self.pivot3D:render(true)
		self.player3D:render()
		layers:select(self.main3D)
		self.wall_layer:draw()
		self.foreground3D:draw()
		self.death_effect_layer:draw()
		layers:refresh()
	end

	layers:select()
	self.background_layer:draw()
	if self.depth > 0 then
		self.pulse3D = self.pulse3D + s_get3dPulseSpeed() * self.pulse3DDirection * frametime
		if self.pulse3D > s_get3dPulseMax() then
			self.pulse3DDirection = -1
		elseif self.pulse3D < s_get3dPulseMin() then
			self.pulse3DDirection = 1
		end
		local effect = s_get3dSkew() * self.pulse3D
		local skew = 1 + effect
		local rad_rot = math.rad(l_getRotation() + 90)
		local cos_rot, sin_rot = math.cos(rad_rot), math.sin(rad_rot)
		local function adjust_alpha(a, i)
			local new_alpha = (a / s_get3dAlphaMult()) - i * s_get3dAlphaFalloff()
			if new_alpha > 255 then
				new_alpha = 255
			elseif new_alpha < 0 then
				new_alpha = 0
			end
			return new_alpha
		end
		for j=1, self.depth do
			local i = self.depth - j
			local offset = s_get3dSpacing() * (i + 1) * s_get3dPerspectiveMult() * effect * 3.6 * 1.4
			local new_pos_x = offset * cos_rot
			local new_pos_y = offset * sin_rot
			local override_color = {s_get3DOverrideColor()}
			for i=1, 3 do
				override_color[i] = override_color[i] / s_get3dDarkenMult()
			end
			override_color[4] = adjust_alpha(override_color[4], i)
			self.main3D:draw_transformed(
				function(x, y)
					return x + new_pos_x, y + new_pos_y, unpack(override_color)
				end,
				function(collision, deadly, killing_side)
					return false, false, 0
				end
			)
		end
	end
	self.wall_layer:draw()
	self.foreground_layer:draw()
	self.death_effect_layer:draw()
	layers:refresh()

	layers:select(self.wall_layer)
	if not self.death_effect.initialized then
		walls:update(frametime)
	end
end

function replace_game:onDeath()
	self.death_effect:death()
end

function replace_game:onPreDeath()
	self.death_effect:invincible_death()
end

function replace_game:onCursorSwap()
	self.player:swap()
end

function replace_game:onRenderStage()
	if self.death_effect.initialized then
		self.death_effect:ensure_tickrate(function()
			self:onInput(self.frametime, false)
		end)
	end
end
