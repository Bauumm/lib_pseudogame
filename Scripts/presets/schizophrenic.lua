u_execScript("cw_drawing/layer.lua")
u_execScript("cw_drawing/layers.lua")
u_execScript("game_system/render.lua")
u_execScript("game_system/player.lua")
u_execScript("game_system/death_effect.lua")
u_execScript("game_system/walls.lua")
u_execScript("invisible.lua")
schizophrenic = {
	pulse3DDirection = 1,
	pulse3D = 1
}

function schizophrenic.color_transformation(r, g, b, a)
	return 255 - r, 255 - g, 255 - b, a
end

function schizophrenic.rotate_point(x, y, angle)
	return x * math.cos(angle) - y * math.sin(angle), x * math.sin(angle) + y * math.cos(angle)
end

function schizophrenic.transform_half_mirror(objects, x0, y0, x1, y1, x2, y2, x3, y3, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3, collision, deadly, killing_side)
	local upper_points = {}
	local lower_points = {}
	local points = {x0, y0, x1, y1, x2, y2, x3, y3}
	for i=1,8,2 do
		local x = points[i]
		local y = points[i + 1]
		x, y = schizophrenic.rotate_point(x, y, math.rad(l_getRotation() * 2))
		local is_dup = false
		for j=1,i - 1,2 do
			if points[j] == x and points[j + 1] == y then
				is_dup = true
			end
		end
		if not is_dup then
			if x < 0 then
				lower_points[#lower_points + 1] = x
				lower_points[#lower_points + 1] = y
			else
				upper_points[#upper_points + 1] = x
				upper_points[#upper_points + 1] = y
			end
		end
	end
	if #lower_points >= 2 and #upper_points >= 2 then
		local a, b = unpack(upper_points, #upper_points - 1, #upper_points)
		local c, d = unpack(lower_points, #lower_points - 1, #lower_points)
		local y = (b * c - a * d) / (c - a)
		upper_points[#upper_points + 1] = 0
		upper_points[#upper_points + 1] = y
		lower_points[#lower_points + 1] = 0
		lower_points[#lower_points + 1] = y
		local a, b = unpack(upper_points, 1, 2)
		local c, d = unpack(lower_points, 1, 2)
		local y = (b * c - a * d) / (c - a)
		upper_points[#upper_points + 1] = 0
		upper_points[#upper_points + 1] = y
		lower_points[#lower_points + 1] = 0
		lower_points[#lower_points + 1] = y
	end
	if #upper_points ~= 0 then
		while #upper_points < 8 do
			upper_points[#upper_points + 1] = upper_points[1]
			upper_points[#upper_points + 1] = upper_points[2]
		end
	end
	if #lower_points ~= 0 then
		while #lower_points < 8 do
			lower_points[#lower_points + 1] = lower_points[1]
			lower_points[#lower_points + 1] = lower_points[2]
		end
	end
	local extra = {r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3, false, false, 0}
	if #upper_points == 8 then
		for i=1, #extra do
			upper_points[#upper_points + 1] = extra[i]
		end
		objects[#objects + 1] = upper_points
	end
	if #lower_points == 8 then
		for i=0, 12, 4 do
			extra[1 + i], extra[2 + i], extra[3 + i], extra[4 + i] = schizophrenic.color_transformation(unpack(extra, 1 + i, 4 + i))
		end
		for i=1, #extra do
			lower_points[#lower_points + 1] = extra[i]
		end
		for i=2,8,2 do
			lower_points[i] = -lower_points[i]
		end
		objects[#objects +1] = lower_points
	end
end

function schizophrenic:init()
	self.depth = s_get3dDepth()
	s_set3dDepth(0)
	if self.depth > 0 then
		self.foreground3D = layer:new()
		self.main3D = layer:new()
		self.player3D = player:new()
		self.pivot3D = pivot:new()
	end
	self.main_game_layer = layer:new()
	self.background_layer = layer:new()
	self.background = background:new()
	self.pivot = pivot:new()
	self.wall_layer = layer:new()
	self.foreground_layer = layer:new()
	self.player = player:new()
	self.death_effect = death_effect:new(self.player)
	self.death_effect_layer = layer:new()
	self.main_layer = layer:new()
	layers:select(self.wall_layer)
end

function schizophrenic:onInput(frametime, movement, focus)
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

	layers:select(self.main_game_layer)
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
	layers:refresh()

	layers:select(self.main_layer)
	self.main_game_layer:draw_invisible()
	self.main_game_layer:draw_transformed_extra(self.transform_half_mirror)
	local color_transformation = self.color_transformation
	self.color_transformation = function(r, g, b, a) return r, g, b, a end
	self.death_effect_layer:draw_transformed_extra(self.transform_half_mirror)
	self.color_transformation = color_transformation
	layers:refresh()

	self.death_effect:draw_main(self.main_layer)

	layers:select(self.wall_layer)
	if not self.death_effect.initialized then
		walls:update(frametime)
	end
end

function schizophrenic:onDeath()
	self.death_effect:death()
end

function schizophrenic:onPreDeath()
	self.death_effect:invincible_death()
end

function schizophrenic:onCursorSwap()
	self.player:swap()
end

function schizophrenic:onRenderStage()
	if self.death_effect.initialized then
		self.death_effect:ensure_tickrate(function()
			self:onInput(self.frametime, false)
		end)
	end
end
