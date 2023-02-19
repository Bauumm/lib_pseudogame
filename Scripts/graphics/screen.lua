screen = {
	cw_data = {},
	extra_cw_data = {},
	cw_list = {}
}

-- update the screen with a polygon collection
-- polygon_collection: PolygonCollection	-- the polygon collection to render onto the screen
function screen:update(polygon_collection)
	local current_index = 0
	local last_index
	local extra_index = 1
	for polygon in polygon_collection:iter() do
		last_index = current_index
		current_index = polygon:_to_cw_data(self.cw_data, current_index)
		for i = 1, current_index - last_index do
			self.extra_cw_data[extra_index] = polygon.extra_data
			extra_index = extra_index + 1
		end
	end
	local size = current_index / 2
	while #self.cw_list < size do
		self.cw_list[#self.cw_list + 1] = cw_function_backup.cw_create()
	end
	while #self.cw_list > size do
		cw_function_backup.cw_destroy(self.cw_list[#self.cw_list])
		self.cw_list[#self.cw_list] = nil
	end
	table.sort(self.cw_list)
	for i=1,size do
		local cw = self.cw_list[i]
		local data_index = i * 2
		cw_function_backup.cw_setVertexPos4(cw, unpack(self.cw_data[data_index - 1]))
		cw_function_backup.cw_setVertexColor4(cw, unpack(self.cw_data[data_index]))
		local extra_data = self.extra_cw_data[i]
		if extra_data == nil then
			cw_function_backup.cw_setCollision(cw, false)
			cw_function_backup.cw_setDeadly(cw, false)
		else
			cw_function_backup.cw_setCollision(cw, extra_data.collision)
			cw_function_backup.cw_setDeadly(cw, extra_data.deadly)
			cw_function_backup.cw_setKillingSide(cw, extra_data.killing_side)
		end
	end
end
