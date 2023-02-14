u_execScript("main.lua")
u_execScript("invisible.lua")

schizophrenic = {
	game = Game:new(),
	collection = PolygonCollection:new()
}

function schizophrenic.color_transformation(r, g, b, a)
	return 255 - r, 255 - g, 255 - b, a
end

function schizophrenic.rotate_points(pts, angle)
	for i=1,#pts,2 do
		local x, y = pts[i], pts[i + 1]
		pts[i] = x * math.cos(angle) - y * math.sin(angle)
		pts[i + 1] = x * math.sin(angle) + y * math.cos(angle)
	end
end

function schizophrenic.transform_half_mirror(objects, x0, y0, x1, y1, x2, y2, x3, y3, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3, collision, deadly, killing_side)
	local points = {x0, y0, x1, y1, x2, y2, x3, y3}
	local angle = math.rad(l_getRotation() * 2)
	schizophrenic.rotate_points(points, angle)
	local extra = {r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3, collision, deadly, killing_side}
	clipping:remove_doubles(points)
	local pts1, pts2 = clipping:slice(points, 0, 0, -1, 0)
	local polys = {clipping:divide_poly(pts1), clipping:divide_poly(pts2)}
	for j=1, #polys do
		local polys = polys[j]
		if polys ~= nil then
			for i=1,#polys do
				local poly = polys[i]
				if j == 2 then
					for i=1,16,4 do
						for j=0,2 do
							extra[i + j] = 255 - extra[i + j]
						end
					end
					for i=1,8,2 do
						poly[i] = -poly[i]
					end
				end
				schizophrenic.rotate_points(poly, angle)
				for i=1,#extra do
					poly[#poly + 1] = extra[i]
				end
				objects[#objects + 1] = poly
			end
		end
	end
end

function schizophrenic:init()
	self.game:overwrite()
end

function schizophrenic:onInput(frametime, movement, focus, swap)
	self.game:overwrite(frametime, movement, focus, swap)
	self.game:draw()
	self.collection:clear()
	local norot = transform:rotate(math.rad(-l_getRotation()))
	local rot = transform:rotate(math.rad(l_getRotation() * 0.5))
	for polygon in self.game.polygon_collection do
		local poly0, poly1 = polygon:transform(norot):transform(rot):slice(0, 0, 1, 0, true, true)
		self.collection:add(poly0:transform(function(x, y, r, g, b, a)
			return -x, y, 255 - r, 255 - g, 255 - b, a
		end))
		self.collection:add(poly1)
	end
	self.collection:transform(rot)
end

function schizophrenic:onDeath()
	self.game.death_effect:death()
end

function schizophrenic:onPreDeath()
	self.game.death_effect:invincible_death()
end

function schizophrenic:onRenderStage()
	if self.game.death_effect.initialized then
		self.game.death_effect:ensure_tickrate(function(frametime)
			self:onInput(frametime, 0, false, false)
		end)
	end
end
