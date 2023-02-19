u_execScript("main.lua")
u_execScript("invisible.lua")
suphexskew = {
	game = Game:new(),
	collection = PolygonCollection:new()
}

function suphexskew:init()
	self.game:overwrite()
end

function suphexskew:onInput(frametime, movement, focus, swap)
	self.game:update(frametime, movement, focus, swap)
	local effect = s_get3dSkew() * self.game.pulse3D
	local skew = 1 + effect 
	self.game:draw()
	local it = self.collection:creation_iter()
	for polygon in self.game.polygon_collection:iter() do
		it():copy_data_transformed(polygon, function(x, y, r, g, b, a)
			return x * skew, y * (1 / skew), r, g, b, a
		end)
	end
	screen:draw_polygon_collection(self.collection)
	screen:update()
end

function suphexskew:onDeath()
	self.game.death_effect:death()
end

function suphexskew:onPreDeath()
	self.game.death_effect:invincible_death()
end

function suphexskew:onRenderStage()
	if self.game.death_effect.initialized then
		self.game.death_effect:ensure_tickrate(function(frametime)
			self:onInput(frametime, 0, false, false)
		end)
	end
end
