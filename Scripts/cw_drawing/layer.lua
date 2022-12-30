u_execScript("cw_drawing/fake_cw_container.lua")
u_execScript("cw_drawing/sorted_cw_list.lua")

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

function layer:draw_invisible()
	self:draw_transformed(function(x, y)
		return x, y, 0, 0, 0, 0
	end)
end
