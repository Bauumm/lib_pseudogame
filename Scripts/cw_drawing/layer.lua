u_execScript("cw_drawing/fake_cw_container.lua")
u_execScript("cw_drawing/sorted_cw_list.lua")
u_execScript("cw_drawing/clipping.lua")

layer = {}
layer.__index = layer

function layer:new()
	return setmetatable({
		container = fake_cw_container:new(),
		cw_list = sorted_cw_list:new()
	}, layer)
end

function layer:draw()
	layers:_get_render_target():queue_apply(self.container)
end

function layer:draw_transformed(vertex_function, cw_function)
	layers:_get_render_target():queue_apply(self.container, vertex_function, cw_function)
end

function layer:draw_transformed_extra(transform_function)
	layers:_get_render_target():queue_apply_extra(self.container, transform_function)
end

function layer:draw_invisible()
	self:draw_transformed(function(x, y)
		return x, y, 0, 0, 0, 0
	end)
end

function layer:draw_extra_blend(blend_function, blend_layer)
	self:draw_transformed_extra(function(x0, y0, x1, y1, x2, y2, x3, y3, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3, collision, deadly, killing_side)
		local objs = {{x0, y0, x1, y1, x2, y2, x3, y3, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3, collision, deadly, killing_side}}
		local pts = {unpack(objs[1], 1, 8)}
		for x0, y0, x1, y1, x2, y2, x3, y3, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3, collision, deadly, killing_side in blend_layer.container:iter() do
			local poly = {x0, y0, x1, y1, x2, y2, x3, y3}
			clipping:get_clipped_poly(poly, pts)
			local clipped_polys = clipping:divide_poly(poly)
			if clipped_polys ~= nil and #clipped_polys ~= 0 then
				local extra = {unpack(objs[1], 9, 24)}
				local this = {r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3}
				for i=1,16,4 do
					extra[i], extra[i + 1], extra[i + 2], extra[i + 3] = blend_function(extra[i], extra[i + 1], extra[i + 2], extra[i + 3], this[i], this[i + 1], this[i + 2], this[i + 3])
				end
				for j=1, #clipped_polys do
					local clipped_poly = clipped_polys[j]
					for i=1, #extra do
						table.insert(clipped_poly, extra[i])
					end
					table.insert(objs, clipped_poly)
				end
			end
		end
		return objs
	end)
end
