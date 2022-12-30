u_execScript("cw_drawing/sorted_cw_list.lua")
u_execScript("cw_drawing/cw_overwrite.lua")

layers = {
	selected_layer = nil,
	_real_cw_list = sorted_cw_list:new()
}

function layers:select(layer)
	if layer ~= self.selected_layer then
		self.selected_layer = layer
		if layer == nil then
			restore_cw_functions()
		else
			overwrite_cw_functions(layer.container)
		end
	end
end

function layers:refresh()
	self:_get_render_target():apply()
end

function layers:_get_render_target()
	if self.selected_layer == nil then
		return self._real_cw_list
	else
		return self.selected_layer.cw_list
	end
end
