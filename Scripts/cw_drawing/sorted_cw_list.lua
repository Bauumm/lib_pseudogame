u_execScript("cw_drawing/cw_overwrite.lua")

sorted_cw_list = {}
sorted_cw_list.__index = sorted_cw_list

function sorted_cw_list:new()
	return setmetatable({
		handles = {},
		_apply_queue = {},
		_apply_queue_size = 0
	}, sorted_cw_list)
end

function sorted_cw_list:create()
	table.insert(self.handles, cw_createNoCollision())
	self._must_sort = true
end

function sorted_cw_list:destroy(handle)
	cw_destroy(self.handles[handle])
	table.remove(self.handles, handle)
	self._must_sort = true
end

function sorted_cw_list:resize(target_size)
	if target_size ~= nil then
		while target_size > #self.handles do
			self:create()
		end
		while target_size < #self.handles do
			self:destroy(1)
		end
	end
	if self._must_sort then
		self._must_sort = false
		table.sort(self.handles)
	end
end

function sorted_cw_list:queue_apply(container, vertex_function, cw_function)
	table.insert(self._apply_queue, {container, vertex_function, cw_function})
	self._apply_queue_size = self._apply_queue_size + container.size
end

function sorted_cw_list:apply()
	self:resize(self._apply_queue_size)
	self._apply_queue_size = 0
	local current_index = 1
	for i=1, #self._apply_queue do
		local container, vertex_function, cw_function = unpack(self._apply_queue[i])
		container:apply(self.handles, current_index, vertex_function, cw_function)
		current_index = current_index + container.size
	end
	for i=#self._apply_queue, 1, -1 do
		self._apply_queue[i] = nil
	end
end
