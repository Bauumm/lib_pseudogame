u_execScript("main.lua")
u_execScript("invisible.lua")

desync = {
	game = Game:new(),
	collection = PolygonCollection:new(),
	blend_collection = PolygonCollection:new()
}

function desync:init()
	self.game:overwrite()
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

function desync:onInput(frametime, movement, focus, swap)
	self.game:overwrite(frametime, movement, focus, swap)
	self.game:draw()
	local it = self.collection:creation_iter()
	for polygon in self.game.polygon_collection:iter() do
		it():copy_data_transformed(polygon, self.transform)
	end
	self.game.polygon_collection:blend(self.collection, self.blend, self.blend_collection)
	self.collection:ref_add(self.game.polygon_collection)
	self.collection:ref_add(self.blend_collection)
	screen:update(self.collection)
end

function desync:onDeath()
	self.game.death_effect:death()
end

function desync:onPreDeath()
	self.game.death_effect:invincible_death()
end

function desync:onRenderStage()
	if self.game.death_effect.initialized then
		self.game.death_effect:ensure_tickrate(function(frametime)
			self:onInput(frametime, 0, false)
		end)
	end
end
