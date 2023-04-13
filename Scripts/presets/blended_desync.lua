u_execScript("main.lua")
u_execScript("invisible.lua")
blended_desync = {
	game = Game:new()
}

function blended_desync:init()
	self.game:overwrite()
	self.half_transparent = function(x, y, r, g, b, a)
		return x, y, r, g, b, a / 2
	end
	self.transform = function(x, y, r, g, b, a)
		local rad_rot = math.rad(2 * l_getRotation())
		local sin_rot, cos_rot = math.sin(rad_rot), math.cos(rad_rot)
		local new_x = x * cos_rot - y * sin_rot
		local new_y = x * sin_rot + y * cos_rot
		return new_x, new_y, 255 - r, 255 - g, 255 - b, a / 2
	end
end

function blended_desync:onInput(frametime, movement, focus, swap)
	self.game:update(frametime, movement, focus, swap)
	local collections = self.game:get_render_stages({0, 1, 2, 3, 4, 5, 6, 7})
	local it = self.game.polygon_collection:creation_iter()
	for i = 1, 2 do
		local transform = i == 1 and self.half_transparent or self.transform
		for polygon in collections[1]:iter() do
			it():copy_data_transformed(polygon, transform)
		end
	end
	for i = 1, 2 do
		local transform = i == 1 and self.half_transparent or self.transform
		for i = 2, #collections do
			if i == 6 then
				it():copy_data_transformed(collections[i], transform)
			else
				for polygon in collections[i]:iter() do
					it():copy_data_transformed(polygon, transform)
				end
			end
		end
	end
	screen:draw_polygon_collection(self.game.polygon_collection)
	screen:update()
end

function blended_desync:onDeath()
	self.game.death_effect:death()
end

function blended_desync:onPreDeath()
	self.game.death_effect:invincible_death()
end

function blended_desync:onRenderStage(rs, frametime)
	if self.game.death_effect.dead and rs == 0 then
		self:onInput(frametime, 0, false, false)
	end
end
