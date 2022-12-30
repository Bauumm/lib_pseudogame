fake_cw_container = {}
fake_cw_container.__index = fake_cw_container

function fake_cw_container:new()
	return setmetatable({
		_data = {},
		_freed = {},
		_must_apply_all = false,
		_data_apply_queue = {},
		highest_handle = 0,
		size = 0
	}, fake_cw_container)
end

function fake_cw_container:create()
	local handle
	if self._freed[1] == nil then
		self.highest_handle = self.highest_handle + 1
		handle = self.highest_handle
	else
		handle = self._freed[1]
		table.remove(self._freed, 1)
	end
	self._data[handle] = {
		vertices = {0, 0, 0, 0, 0, 0, 0, 0},
		colors = {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}},
		collision = true,
		killing_side = 0,
		deadly = false
	}
	self.size = self.size + 1
	self._must_apply_all = true
	return handle
end

function fake_cw_container:destroy(handle)
	self._data[handle] = nil
	table.insert(self._freed, handle)
	self.size = self.size - 1
	self._must_apply_all = true
end

function fake_cw_container:clear()
	self._data = {}
	self.highest_handle = 0
	self._freed = {}
	self.size = 0
	self._must_apply_all = true
end

function fake_cw_container:set_vertex_color(handle, vertex, r, g, b, a)
	local data = self._data[handle]
	data.colors[vertex + 1][1] = r
	data.colors[vertex + 1][2] = g
	data.colors[vertex + 1][3] = b
	data.colors[vertex + 1][4] = a
	self._data_apply_queue[handle] = true
end

function fake_cw_container:set_color(handle, r, g, b, a)
	local data = self._data[handle]
	for vertex=1, 4 do
		data.colors[vertex][1] = r
		data.colors[vertex][2] = g
		data.colors[vertex][3] = b
		data.colors[vertex][4] = a
	end
	self._data_apply_queue[handle] = true
end

function fake_cw_container:set_vertex_pos(handle, vertex, x, y)
	local vertices = self._data[handle].vertices
	vertices[vertex * 2 + 1] = x
	vertices[vertex * 2 + 2] = y
	self._data_apply_queue[handle] = true
end

function fake_cw_container:get_vertex_pos(handle, vertex)
	local vertices = self._data[handle].vertices
	return vertices[vertex * 2 + 1], vertices[vertex * 2 + 2]
end

function fake_cw_container:get_vertices(handle)
	return self._data[handle].vertices
end

function fake_cw_container:set_vertices(handle, x0, y0, x1, y1, x2, y2, x3, y3)
	self._data[handle].vertices[1] = x0
	self._data[handle].vertices[2] = y0
	self._data[handle].vertices[3] = x1
	self._data[handle].vertices[4] = y1
	self._data[handle].vertices[5] = x2
	self._data[handle].vertices[6] = y2
	self._data[handle].vertices[7] = x3
	self._data[handle].vertices[8] = y3
	self._data_apply_queue[handle] = true
end

function fake_cw_container:set_collision(handle, collision)
	self._data[handle].collision = collision
end

function fake_cw_container:set_deadly(handle, deadly)
	self._data[handle].deadly = deadly
end

function fake_cw_container:set_killing_side(handle, side)
	self._data[handle].killing_side = side
end

function fake_cw_container:get_collision(handle)
	return self._data[handle].collision
end

function fake_cw_container:get_deadly(handle)
	return self._data[handle].deadly
end

function fake_cw_container:get_killing_side(handle)
	return self._data[handle].killing_side
end

function fake_cw_container:size()
	return self.size
end

function fake_cw_container:make_invisible()
	for handle=1, self.highest_handle do
		local data = self._data[handle]
		if data ~= nil then
			self:set_color(handle, 0, 0, 0, 0)
		end
	end
end

-- applies the fake containers data onto cws
function fake_cw_container:apply(cw_list, start_index, vertex_function, cw_function)
	local cw_index = start_index or 1
	if #cw_list - cw_index + 1 < self.size then
		error("The given cw_list is too short to hold all data!")
	end
	for handle=1, self.highest_handle do
		local data = self._data[handle]
		if data ~= nil then
			if self._must_apply_all or self._data_apply_queue[handle] then
				self._data_apply_queue[handle] = nil
				local cw = cw_list[cw_index]
				if vertex_function == nil then
					cw_setVertexPos4(cw, unpack(data.vertices))
					for i=1,4 do
						cw_setVertexColor(cw, i - 1, unpack(data.colors[i]))
					end
				else
					for i=1,4 do
						local x, y, r, g, b, a = vertex_function(data.vertices[i * 2 - 1], data.vertices[i * 2], unpack(data.colors[i]))
						cw_setVertexPos(cw, i - 1, x, y)
						if r == nil or g == nil or b == nil or a == nil then
							cw_setVertexColor(cw, i - 1, unpack(data.colors[i]))
						else
							cw_setVertexColor(cw, i - 1, r, g, b, a)
						end
					end
				end
				local collision, deadly, killing_side
				if cw_function ~= nil then
					collision, deadly, killing_side = cw_function(data.collision, data.deadly, data.killing_side)
					cw_setKillingSide(cw, killing_side)
					cw_setCollision(cw, collision)
					cw_setDeadly(cw, deadly)
				else
					cw_setKillingSide(cw, data.killing_side)
					cw_setCollision(cw, data.collision)
					cw_setDeadly(cw, data.deadly)
				end
			end
			cw_index = cw_index + 1
		end
	end
end
