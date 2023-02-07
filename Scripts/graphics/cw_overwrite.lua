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

function overwrite_cw_functions(container)
	cw_create = function()
		return container:create()
	end
	cw_createDeadly = function()
		local handle = container:create()
		container:set_deadly(true)
		return handle
	end
	cw_createNoCollision = function()
		local handle = container:create()
		container:set_collision(handle, false)
		return handle
	end
	cw_destroy = function(handle)
		container:destroy(handle)
	end
	cw_setVertexPos = function(handle, vertex, x, y)
		container:set_vertex_pos(handle, vertex, x, y)
	end
	cw_moveVertexPos = function(handle, vertex, offset_x, offset_y)
		local x, y = container:get_vertex_pos(handle, vertex)
		container:set_vertex_pos(handle, vertex, x + offset_x, y + offset_y)
	end
	cw_moveVertexPos4Same = function(handle, offset_x0, offset_y0, offset_x1, offset_y1, offset_x2, offset_y2, offset_x3, offset_y3)
		local vertices = container:get_vertices(handle)
		vertices[1] = vertices[1] + offset_x0
		vertices[2] = vertices[2] + offset_y0
		vertices[3] = vertices[3] + offset_x1
		vertices[4] = vertices[4] + offset_y1
		vertices[5] = vertices[5] + offset_x2
		vertices[6] = vertices[6] + offset_y2
		vertices[7] = vertices[7] + offset_x3
		vertices[8] = vertices[8] + offset_y3
		container:set_vertices(handle, unpack(vertices))
	end
	cw_setVertexColor = function(handle, vertex, r, g, b, a)
		container:set_vertex_color(handle, vertex, r, g, b, a)
	end
	cw_setVertexPos4 = function(handle, x0, y0, x1, y1, x2, y2, x3, y3)
		local vertices = container:get_vertices(handle)
		vertices[1] = x0
		vertices[2] = y0
		vertices[3] = x1
		vertices[4] = y1
		vertices[5] = x2
		vertices[6] = y2
		vertices[7] = x3
		vertices[8] = y3
		container:set_vertices(handle, unpack(vertices))
	end
	cw_setVertexColor4 = function(handle, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3)
		container:set_vertex_color(handle, 0, r0, g0, b0, a0)
		container:set_vertex_color(handle, 1, r1, g1, b1, a1)
		container:set_vertex_color(handle, 2, r2, g2, b2, a2)
		container:set_vertex_color(handle, 3, r3, g3, b3, a3)
	end
	cw_setVertexColor4Same = function(handle, r, g, b, a)
		container:set_color(handle, r, g, b, a)
	end
	cw_setCollision = function(handle, collision)
		container:set_collision(handle, collision)
	end
	cw_setDeadly = function(handle, deadly)
		container:set_deadly(handle, deadly)
	end
	cw_setKillingSide = function(handle, side)
		container:set_killing_side(handle, side)
	end
	cw_getCollision = function(handle, collision)
		return container:get_collision(handle, collision)
	end
	cw_getDeadly = function(handle, deadly)
		return container:get_deadly(handle, deadly)
	end
	cw_getKillingSide = function(handle, side)
		return container:get_killing_side(handle, side)
	end
	cw_getVertexPos = function(handle, vertex)
		return container:get_vertex_pos(handle, vertex)
	end
	cw_getVertexPos4 = function(handle)
		return unpack(container:get_vertices(handle))
	end
	cw_clear = function()
		container:clear()
	end
end
