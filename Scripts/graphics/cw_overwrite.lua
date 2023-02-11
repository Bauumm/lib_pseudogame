cw_function_names = {
	"cw_create",
	"cw_createDeadly",
	"cw_createNoCollision",
	"cw_destroy",
	"cw_setVertexPos",
	"cw_moveVertexPos",
	"cw_moveVertexPos4Same",
	"cw_setVertexColor",
	"cw_setVertexPos4",
	"cw_setVertexColor4",
	"cw_setVertexColor4Same",
	"cw_setCollision",
	"cw_setDeadly",
	"cw_setKillingSide",
	"cw_getCollision",
	"cw_getDeadly",
	"cw_getKillingSide",
	"cw_getVertexPos",
	"cw_getVertexPos4",
	"cw_clear"
}

if type(cw_create) == "userdata" then
	cw_function_backup = {}
	for _, name in pairs(cw_function_names) do
		cw_function_backup[name] = _G[name]
	end
end

function restore_cw_functions()
	for _, name in pairs(cw_function_names) do
		_G[name] = cw_function_backup[name]
	end
end

function overwrite_cw_functions(polygon_collection)
	cw_create = function()
		local polygon = Polygon:new({0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
		polygon.extra_data = {collision=true, deadly=false, killing_side=0}
		return polygon_collection:add(polygon)
	end
	cw_createDeadly = function()
		local polygon = Polygon:new({0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
		polygon.extra_data = {collision=false, deadly=true, killing_side=0}
		return polygon_collection:add(polygon)
	end
	cw_createNoCollision = function()
		local polygon = Polygon:new({0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
		polygon.extra_data = {collision=false, deadly=false, killing_side=0}
		return polygon_collection:add(polygon)
	end
	cw_destroy = function(handle)
		polygon_collection:remove(handle)
	end
	local function polygon_by_index(index)
		local polygon = polygon_collection:get(index)
		if polygon == nil then
			error("invalid cw handle: " .. index)
		end
		return polygon
	end
	cw_setVertexPos = function(handle, vertex, x, y)
		polygon_by_index(handle):set_vertex_pos(vertex + 1, x, y)
	end
	cw_moveVertexPos = function(handle, vertex, offset_x, offset_y)
		local polygon = polygon_by_index(handle)
		local x, y = polygon:get_vertex_pos(vertex + 1)
		polygon:set_vertex_pos(vertex + 1, x + offset_x, y + offset_y)
	end
	cw_moveVertexPos4Same = function(handle, offset_x0, offset_y0, offset_x1, offset_y1, offset_x2, offset_y2, offset_x3, offset_y3)
		local polygon = polygon_by_index(handle)
		local x0, y0 = polygon:get_vertex_pos(1)
		local x1, y1 = polygon:get_vertex_pos(2)
		local x2, y2 = polygon:get_vertex_pos(3)
		local x3, y3 = polygon:get_vertex_pos(4)
		polygon:set_vertex_pos(1, x0 + offset_x0, y0 + offset_y0)
		polygon:set_vertex_pos(2, x1 + offset_x1, y1 + offset_y1)
		polygon:set_vertex_pos(3, x2 + offset_x2, y2 + offset_y2)
		polygon:set_vertex_pos(4, x3 + offset_x3, y3 + offset_y3)
	end
	cw_setVertexColor = function(handle, vertex, r, g, b, a)
		polygon_by_index(handle):set_vertex_color(vertex + 1, r, g, b, a)
	end
	cw_setVertexPos4 = function(handle, x0, y0, x1, y1, x2, y2, x3, y3)
		local polygon = polygon_by_index(handle)
		polygon:set_vertex_pos(1, x0, y0)
		polygon:set_vertex_pos(2, x1, y1)
		polygon:set_vertex_pos(3, x2, y2)
		polygon:set_vertex_pos(4, x3, y3)
	end
	cw_setVertexColor4 = function(handle, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3)
		local polygon = polygon_by_index(handle)
		polygon:set_vertex_color(1, r0, g0, b0, a0)
		polygon:set_vertex_color(2, r1, g1, b1, a1)
		polygon:set_vertex_color(3, r2, g2, b2, a2)
		polygon:set_vertex_color(4, r3, g3, b3, a3)
	end
	cw_setVertexColor4Same = function(handle, r, g, b, a)
		local polygon = polygon_by_index(handle)
		polygon:set_vertex_color(1, r, g, b, a)
		polygon:set_vertex_color(2, r, g, b, a)
		polygon:set_vertex_color(3, r, g, b, a)
		polygon:set_vertex_color(4, r, g, b, a)
	end
	cw_setCollision = function(handle, collision)
		polygon_by_index(handle).extra_data.collision = collision
	end
	cw_setDeadly = function(handle, deadly)
		polygon_by_index(handle).extra_data.deadly = deadly
	end
	cw_setKillingSide = function(handle, side)
		polygon_by_index(handle).extra_data.killing_side = killing_side
	end
	cw_getCollision = function(handle)
		return polygon_by_index(handle).collision
	end
	cw_getDeadly = function(handle)
		return polygon_by_index(handle).deadly
	end
	cw_getKillingSide = function(handle)
		return polygon_by_index(handle).killing_side
	end
	cw_getVertexPos = function(handle, vertex)
		return polygon_by_index(handle):get_vertex_pos(vertex + 1)
	end
	cw_getVertexPos4 = function(handle)
		local polygon = polygon_by_index(handle)
		local x0, y0 = polygon:get_vertex_pos(1)
		local x1, y1 = polygon:get_vertex_pos(2)
		local x2, y2 = polygon:get_vertex_pos(3)
		local x3, y3 = polygon:get_vertex_pos(4)
		return x0, y0, x1, y1, x2, y2, x3, y3
	end
	cw_clear = function()
		polygon_collection:clear()
	end
end
