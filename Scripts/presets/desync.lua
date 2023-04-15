u_execScript("main.lua")

local PG = PseudoGame

PG.hide_default_game()

desync = {
	game = PG.game.Game:new(),
	collection = PG.graphics.PolygonCollection:new(),
	main_collection = PG.graphics.PolygonCollection:new(),
	back_collection = PG.graphics.PolygonCollection:new(),
	tmp_collection = PG.graphics.PolygonCollection:new()
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
	PG.graphics.effects.draw_directly = true
end

function desync:onInput(frametime, movement, focus, swap)
	self.game:update(frametime, movement, focus, swap)
	local collections = self.game:get_render_stages({0, 1, 2, 3, 4, 5, 6, 7})
	local gen = self.back_collection:generator()
	for polygon in collections[1]:iter() do
		gen():copy_data_transformed(polygon, self.transform)
	end
	local tmp_gen = self.tmp_collection:generator()
	PG.graphics.effects:blend(collections[1], self.back_collection, self.blend)
	local main_gen = self.main_collection:generator()
	local gen = self.collection:generator()
	for i = 2, #collections do
		if i == 6 then
			main_gen():copy_data(collections[i])
			gen():copy_data_transformed(collections[i], self.transform)
		else
			for polygon in collections[i]:iter() do
				main_gen():copy_data(polygon)
				gen():copy_data_transformed(polygon, self.transform)
			end
		end
	end
	PG.graphics.screen:draw_polygon_collection(self.main_collection)
	PG.graphics.screen:draw_polygon_collection(self.collection)
	PG.graphics.effects:blend(self.main_collection, self.collection, self.blend)
	PG.graphics.screen:update()
end

function desync:onDeath()
	self.game.death_effect:death()
end

function desync:onPreDeath()
	self.game.death_effect:invincible_death()
end

function desync:onRenderStage(rs, frametime)
	self.game.death_effect:ensure_tickrate(rs, frametime, function(frametime)
		self:onInput(frametime, 0, false, false)
	end)
end

function desync:onUnload()
	self.game:restore()
end
