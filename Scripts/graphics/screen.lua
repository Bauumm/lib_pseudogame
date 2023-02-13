screen = {
	cw_list = {}
}

-- update the screen with a polygon collection
-- polygon_collection: PolygonCollection	-- the polygon collection to render onto the screen
function screen:update(polygon_collection)
	local size = 0
	for polygon in polygon_collection:iter() do
		if polygon.vertex_count <= 4 and polygon.vertex_count ~= 0 then
			size = size + 1
		else
			size = size + math.ceil(polygon.vertex_count / 3)
		end
	end
	while #self.cw_list < size do
		self.cw_list[#self.cw_list + 1] = cw_function_backup.cw_create()
	end
	while #self.cw_list > size do
		cw_function_backup.cw_destroy(self.cw_list[#self.cw_list])
		self.cw_list[#self.cw_list] = nil
	end
	table.sort(self.cw_list)
	local cw_index = 1
	for polygon in polygon_collection:iter() do
		if polygon.vertex_count == 4 then
				local cw = self.cw_list[cw_index]
				cw_function_backup.cw_setVertexPos4(cw, unpack(polygon._vertices))
				cw_function_backup.cw_setVertexColor4(cw, unpack(polygon._colors))
				if polygon.extra_data == nil then
					cw_function_backup.cw_setCollision(cw, false)
					cw_function_backup.cw_setDeadly(cw, false)
				else
					cw_function_backup.cw_setCollision(cw, polygon.extra_data.collision)
					cw_function_backup.cw_setDeadly(cw, polygon.extra_data.deadly)
					cw_function_backup.cw_setKillingSide(cw, polygon.extra_data.killing_side)
				end
				cw_index = cw_index + 1
		else
			local cws = polygon:split4()
			if cws ~= nil then
				for i=1,#cws,2 do
					local cw = self.cw_list[cw_index]
					cw_function_backup.cw_setVertexPos4(cw, unpack(cws[i]))
					cw_function_backup.cw_setVertexColor4(cw, unpack(cws[i + 1]))
					if polygon.extra_data == nil then
						cw_function_backup.cw_setCollision(cw, false)
						cw_function_backup.cw_setDeadly(cw, false)
					else
						cw_function_backup.cw_setCollision(cw, polygon.extra_data.collision)
						cw_function_backup.cw_setDeadly(cw, polygon.extra_data.deadly)
						cw_function_backup.cw_setKillingSide(cw, polygon.extra_data.killing_side)
					end
					cw_index = cw_index + 1
				end
			end
		end
	end
end
