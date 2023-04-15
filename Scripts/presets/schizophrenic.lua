u_execScript("main.lua")
u_execScript("invisible.lua")

schizophrenic = {
	game = Game:new(),
	collection = PolygonCollection:new()
}

function schizophrenic:init()
	self.game:overwrite()
end

function schizophrenic:onInput(frametime, movement, focus, swap)
	self.game:update(frametime, movement, focus, swap)
	self.game:draw()
	self.collection:clear()
	local rot = effects:rotate(math.rad(l_getRotation()))
	local norot = effects:rotate(math.rad(-l_getRotation()))
	for polygon in self.game.polygon_collection:iter() do
		local poly0, poly1 = polygon:copy():transform(rot):slice(0, 0, 1, 0, true, true)
		self.collection:add(poly0:transform(function(x, y, r, g, b, a)
			return -x, y, 255 - r, 255 - g, 255 - b, a
		end))
		self.collection:add(poly1)
	end
	self.collection:transform(norot)
	screen:draw_polygon_collection(self.collection)
	screen:update()
end

function schizophrenic:onDeath()
	self.game.death_effect:death()
end

function schizophrenic:onPreDeath()
	self.game.death_effect:invincible_death()
end

function schizophrenic:onRenderStage(rs, frametime)
	if self.game.death_effect.dead and rs == 0 then
		self:onInput(frametime, 0, false, false)
	end
end
