function get_random_polygon()
	local polygon = PseudoGame.graphics.Polygon:new()
	for i = 1, math.random(0, 20) do
		polygon:add_vertex(math.random(-500, 500), math.random(-500, 500), math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255))
	end
	return polygon
end

describe("screen", function()
	it("get width/height", function()
		-- this is just the resolution with the fake u_getWidth/Height
		-- in the real game it may vary depending on the game window on level start
		assert.equal(PseudoGame.graphics.screen:get_width(), 1024)
		assert.equal(PseudoGame.graphics.screen:get_height(), 768)
	end)
	it("draw polygon", function()
		local polygon = get_random_polygon()
		polygon.extra_data = {collision = true, deadly = true, killing_side = 1}
		PseudoGame.graphics.screen:draw_polygon(polygon)
		PseudoGame.game.cw_function_backup = {
			cw_create = function()
				return 0
			end,
			cw_destroy = function()
			end,
			cw_setVertexPos4 = function(_, x0, y0, x1, y1, x2, y2, x3, y3)
				local is_in_polygon = 0
				for index, x, y, r, g, b, a in polygon:vertex_color_pairs() do
					if x0 == x and y0 == y then
						is_in_polygon = is_in_polygon + 1
					end
					if x1 == x and y1 == y then
						is_in_polygon = is_in_polygon + 1
					end
					if x2 == x and y2 == y then
						is_in_polygon = is_in_polygon + 1
					end
					if x3 == x and y3 == y then
						is_in_polygon = is_in_polygon + 1
					end
				end
				assert.equal(is_in_polygon, 4)
			end,
			cw_setVertexColor4 = function(_, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3)
				local is_in_polygon = 0
				for index, x, y, r, g, b, a in polygon:vertex_color_pairs() do
					if r0 == r and g0 == g and b0 == b and a0 == a then
						is_in_polygon = is_in_polygon + 1
					end
					if r1 == r and g1 == g and b1 == b and a1 == a then
						is_in_polygon = is_in_polygon + 1
					end
					if r2 == r and g2 == g and b2 == b and a2 == a then
						is_in_polygon = is_in_polygon + 1
					end
					if r3 == r and g3 == g and b3 == b and a3 == a then
						is_in_polygon = is_in_polygon + 1
					end
				end
				assert.equal(is_in_polygon, 4)
			end,
			cw_setCollision = function(_, bool)
				assert.equal(bool, true)
			end,
			cw_setDeadly = function(_, bool)
				assert.equal(bool, true)
			end,
			cw_setKillingSide = function(_, side)
				assert.equal(side, 1)
			end
		}
		PseudoGame.graphics.screen:update()
	end)
	it("draw polygon collection", function()
		local collection = PseudoGame.graphics.PolygonCollection:new()
		for i = 1, math.random(10, 20) do
			collection:add(PseudoGame.graphics.Polygon:new({0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}))
		end
		PseudoGame.graphics.screen:draw_polygon_collection(collection)
		local cw_count = 0

		-- can't check for cw_create count otherwise
		PseudoGame.graphics.screen._cw_list = {}

		PseudoGame.game.cw_function_backup = {
			cw_create = function()
				cw_count = cw_count + 1
				return 0
			end,
			cw_destroy = function()
				cw_count = cw_count - 1
			end,
			cw_setVertexPos4 = function()
			end,
			cw_setVertexColor4 = function()
			end,
			cw_setCollision = function(_, bool)
				assert.equal(bool, false)
			end,
			cw_setDeadly = function(_, bool)
				assert.equal(bool, false)
			end
		}
		PseudoGame.graphics.screen:update()
		assert.equal(cw_count, collection.size)
	end)
end)
