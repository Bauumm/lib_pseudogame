u_execScript("main.lua")

local PG = PseudoGame

PG.hide_default_game()

suphexskew = {
	game = PG.game.Game:new(),
	collection = PG.graphics.PolygonCollection:new()
}

function suphexskew:init()
	self.game:overwrite()
end

function suphexskew:onInput(frametime, movement, focus, swap)
	self.game:update(frametime, movement, focus, swap)
	local effect = s_get3dSkew() * self.game.style.pulse3D
	local skew = 1 + effect 
	self.game:draw()
	local gen = self.collection:generator()
	for polygon in self.game.polygon_collection:iter() do
		gen():copy_data_transformed(polygon, function(x, y, r, g, b, a)
			return x * skew, y * (1 / skew), r, g, b, a
		end)
	end
	PG.graphic.screen:draw_polygon_collection(self.collection)
	PG.graphic.screen:update()
end

function suphexskew:onDeath()
	self.game.death_effect:death()
end

function suphexskew:onPreDeath()
	self.game.death_effect:invincible_death()
end

function suphexskew:onRenderStage(rs, frametime)
	self.game.death_effect:ensure_tickrate(rs, frametime, function(frametime)
		self:onInput(frametime, 0, false, false)
	end)
end

function suphexskew:onUnload()
	self.game:restore()
end
