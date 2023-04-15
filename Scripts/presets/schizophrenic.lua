u_execScript("main.lua")

local PG = PseudoGame

PG.hide_default_game()

schizophrenic = {
	game = PG.game.Game:new(),
	collection = PG.graphics.PolygonCollection:new()
}

function schizophrenic:init()
	self.game:overwrite()
end

function schizophrenic:onInput(frametime, movement, focus, swap)
	self.game:update(frametime, movement, focus, swap)
	self.game:draw()
	local rot = effects:rotate(math.rad(l_getRotation()))
	local norot = effects:rotate(math.rad(-l_getRotation()))
	local gen = self.collection:generator()
	for polygon in self.game.polygon_collection:iter() do
		local poly0 = polygon:copy():transform(rot):slice(0, 0, 1, 0, true, true, gen, gen)
		if poly0 ~= nil then
			poly0:transform(function(x, y, r, g, b, a)
				return -x, y, 255 - r, 255 - g, 255 - b, a
			end)
		end
	end
	self.collection:transform(norot)
	PG.graphics.screen:draw_polygon_collection(self.collection)
	PG.graphics.screen:update()
end

function schizophrenic:onDeath()
	self.game.death_effect:death()
end

function schizophrenic:onPreDeath()
	self.game.death_effect:invincible_death()
end

function schizophrenic:onRenderStage(rs, frametime)
	self.game.death_effect:ensure_tickrate(rs, frametime, function(frametime)
		self:onInput(frametime, 0, false, false)
	end)
end
