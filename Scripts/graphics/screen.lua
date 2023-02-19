screen = {
	_current_index = 0,
	_extra_index = 1,
	_cw_data = {},
	_extra_cw_data = {},
	_cw_list = {}
}

function screen:draw_polygon(polygon)
	local last_index = self._current_index
	self._current_index = polygon:_to_cw_data(self._cw_data, self._current_index)
	for i = 1, self._current_index - last_index do
		self._extra_cw_data[self._extra_index] = polygon.extra_data
		self._extra_index = self._extra_index + 1
	end
end

function screen:draw_polygon_collection(polygon_collection)
	for polygon in polygon_collection:iter() do
		self:draw_polygon(polygon)
	end
end

-- update the screen with a polygon collection
-- polygon_collection: PolygonCollection	-- the polygon collection to render onto the screen
function screen:update()
	local size = self._current_index / 2
	while #self._cw_list < size do
		self._cw_list[#self._cw_list + 1] = cw_function_backup.cw_create()
	end
	while #self._cw_list > size do
		cw_function_backup.cw_destroy(self._cw_list[#self._cw_list])
		self._cw_list[#self._cw_list] = nil
	end
	table.sort(self._cw_list)
	for i=1,size do
		local cw = self._cw_list[i]
		local data_index = i * 2
		cw_function_backup.cw_setVertexPos4(cw, unpack(self._cw_data[data_index - 1]))
		cw_function_backup.cw_setVertexColor4(cw, unpack(self._cw_data[data_index]))
		local extra_data = self._extra_cw_data[i]
		if extra_data == nil then
			cw_function_backup.cw_setCollision(cw, false)
			cw_function_backup.cw_setDeadly(cw, false)
		else
			cw_function_backup.cw_setCollision(cw, extra_data.collision)
			cw_function_backup.cw_setDeadly(cw, extra_data.deadly)
			cw_function_backup.cw_setKillingSide(cw, extra_data.killing_side)
		end
	end
	self._extra_index = 1
	self._current_index = 0
end
