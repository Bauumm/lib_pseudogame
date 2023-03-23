u_execScript("main.lua")
u_execScript("invisible.lua")

desync = {
	game = Game:new(),
	collection = PolygonCollection:new(),
	main_collection = PolygonCollection:new(),
	back_collection = PolygonCollection:new(),
	back_blend_collection = PolygonCollection:new(),
	blend_collection = PolygonCollection:new(),
	final_collection = PolygonCollection:new(),
	fps_limit = 120,
	passed_time = 0
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
	self.game:update(frametime, movement, focus, swap)
	local collections = self.game:get_render_stages({0, 1, 2, 3, 4, 5, 6, 7})
	self.passed_time = self.passed_time + frametime
	while self.passed_time >= 60 / self.fps_limit do
		self.passed_time = self.passed_time - 60 / self.fps_limit
		local it = self.back_collection:creation_iter()
		for polygon in collections[1]:iter() do
			it():copy_data_transformed(polygon, self.transform)
		end
		effects.blend(collections[1], self.back_collection, self.blend, self.back_blend_collection)
		self.main_collection:clear()
		for i = 2, #collections do
			if i == 6 then
				self.main_collection:add(collections[i])
			else
				self.main_collection:copy_add(collections[i])
			end
		end
		self.collection:clear()
		self.collection:copy_add(self.main_collection)
		self.main_collection:transform(self.transform)
		effects.blend(self.main_collection, self.collection, self.blend, self.blend_collection)
		self.collection:ref_add(self.main_collection)
		self.collection:ref_add(self.blend_collection)
		self.final_collection:clear()
		self.final_collection:ref_add(self.back_blend_collection)
		self.final_collection:ref_add(self.collection)
		screen:draw_polygon_collection(self.final_collection)
		screen:update()
	end
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
