u_execScript("cw_drawing/layer.lua")
u_execScript("cw_drawing/layers.lua")
u_execScript("game_system/render.lua")
u_execScript("game_system/player.lua")
u_execScript("game_system/death_effect.lua")
u_execScript("game_system/walls.lua")
u_execScript("invisible.lua")
desync = {}

function desync:init()
	s_set3dDepth(0)
	self.background_layer1 = layer:new()
	self.background_layer2 = layer:new()
	self.background = background:new()
	self.pivot = pivot:new()
	self.wall_layer1 = layer:new()
	self.wall_layer2 = layer:new()
	self.foreground_layer1 = layer:new()
	self.foreground_layer2 = layer:new()
	self.player = player:new()
	self.death_effect = death_effect:new(self.player)
	self.death_effect_layer1 = layer:new()
	self.death_effect_layer2 = layer:new()
	self.main_layer = layer:new()
	layers:select(self.wall_layer1)
	self.transform = function(x, y, r, g, b, a)
		local rad_rot = math.rad(2 * l_getRotation())
		local sin_rot, cos_rot = math.sin(rad_rot), math.cos(rad_rot)
		local new_x = x * cos_rot - y * sin_rot
		local new_y = x * sin_rot + y * cos_rot
		return new_x, new_y, 255 - r, 255 - g, 255 - b, a
	end
	self.blend = function(r0, g0, b0, a0, r1, g1, b1, a1)
		local function clamp(c)
			if c > 255 then
				return 255
			elseif c < 0 then
				return 0
			end
			return c
		end
		return clamp(r0 + r1) / 1.3, clamp(g0 + g1) / 1.3, clamp(b0 + b1) / 1.3, 255
	end
end

function desync:onInput(frametime, movement, focus)
	layers:refresh()

	self.frametime = frametime
	self.player:update(frametime, focus)
	self.death_effect:update(frametime)

	layers:select(self.background_layer1)
	self.background:render()
	layers:refresh()

	layers:select(self.foreground_layer1)
	self.pivot:render()
	self.player:render()
	layers:refresh()

	layers:select(self.death_effect_layer1)
	self.death_effect:render()
	layers:refresh()

	layers:select(self.background_layer2)
	self.background_layer1:draw_transformed(self.transform, function() return false, false, 0 end)
	layers:refresh()
	layers:select(self.foreground_layer2)
	self.foreground_layer1:draw_transformed(self.transform, function() return false, false, 0 end)
	layers:refresh()
	layers:select(self.wall_layer2)
	self.wall_layer1:draw_transformed(self.transform, function() return false, false, 0 end)
	layers:refresh()
	layers:select(self.death_effect_layer2)
	self.death_effect_layer1:draw_transformed(self.transform, function() return false, false, 0 end)
	layers:refresh()

	layers:select(self.main_layer)
	self.background_layer1:draw()
	self.background_layer2:draw_extra_blend(self.blend, self.background_layer1)
	self.wall_layer1:draw()
	self.wall_layer2:draw_extra_blend(self.blend, self.wall_layer1)
	self.foreground_layer1:draw()
	self.foreground_layer2:draw_extra_blend(self.blend, self.foreground_layer1)
	self.death_effect_layer1:draw()
	self.death_effect_layer2:draw_extra_blend(self.blend, self.death_effect_layer1)
	layers:refresh()

	self.death_effect:draw_main(self.main_layer)

	layers:select(self.wall_layer1)
	if not self.death_effect.initialized then
		walls:update(frametime)
	end
end

function desync:onDeath()
	self.death_effect:death()
end

function desync:onPreDeath()
	self.death_effect:invincible_death()
end

function desync:onCursorSwap()
	self.player:swap()
end

function desync:onRenderStage()
	if self.death_effect.initialized then
		self.death_effect:ensure_tickrate(function()
			self:onInput(self.frametime, false)
		end)
	end
end
