--- Module for drawing polygon objects to the screen (by converting them to cw data which is applied on real custom walls in the right render order)
-- @module PseudoGame.graphics.screen
PseudoGame.graphics.screen = {
    _current_index = 0,
    _extra_index = 1,
    _cw_data = {},
    _extra_cw_data = {},
    _cw_list = {},
    _is_headless = u_isHeadless(),
    _polygons_with_extra_data = false,
}

--- get the width of the screen, so you put polygons directly on the edge
-- @treturn number
function PseudoGame.graphics.screen:get_width()
    local zoom_factor = math.max(1024 / u_getWidth(), 768 / u_getHeight())
    return u_getWidth() * zoom_factor
end

--- get the height of the screen, so you put polygons directly on the edge (adjusted for skew, so need to refresh every tick if 3d is changing)
-- @treturn number
function PseudoGame.graphics.screen:get_height()
    local zoom_factor = math.max(1024 / u_getWidth(), 768 / u_getHeight())
    return u_getHeight() * zoom_factor * (1 + s_get3dSkew() * PseudoGame.game.level_style._pulse3D)
end

--- draw a polygon to the screen (only shown once `screen:update()` is called)
-- @tparam Polygon polygon  the polygon to draw
function PseudoGame.graphics.screen:draw_polygon(polygon)
    local needs_it_for_collisions = polygon.extra_data ~= nil
        and (polygon.extra_data.collision or polygon.extra_data.deadly)
    if self._is_headless and needs_it_for_collisions then
        self._polygons_with_extra_data = true
    end
    if not self._is_headless or needs_it_for_collisions then
        local last_index = self._current_index
        self._current_index = polygon:_to_cw_data(self._cw_data, self._current_index)
        for _ = 1, self._current_index - last_index, 2 do
            self._extra_cw_data[self._extra_index] = polygon.extra_data
            self._extra_index = self._extra_index + 1
        end
    end
end

--- draw a polygon collection to the screen (only shown once `screen:update()` is called)
-- @tparam PolygonCollection polygon_collection  the polygon collection to draw
function PseudoGame.graphics.screen:draw_polygon_collection(polygon_collection)
    for polygon in polygon_collection:iter() do
        self:draw_polygon(polygon)
    end
end

--- update the screen after drawing, this applies the purely virtual data onto real custom walls
function PseudoGame.graphics.screen:update()
    if not self._is_headless or self._polygons_with_extra_data then
        self._polygons_with_extra_data = false
        local size = self._current_index / 2
        while #self._cw_list < size do
            self._cw_list[#self._cw_list + 1] = PseudoGame.game.cw_function_backup.cw_create()
        end
        while #self._cw_list > size do
            PseudoGame.game.cw_function_backup.cw_destroy(self._cw_list[#self._cw_list])
            self._cw_list[#self._cw_list] = nil
        end
        table.sort(self._cw_list)
        for i = 1, size do
            local cw = self._cw_list[i]
            local data_index = i * 2
            PseudoGame.game.cw_function_backup.cw_setVertexPos4(cw, unpack(self._cw_data[data_index - 1]))
            PseudoGame.game.cw_function_backup.cw_setVertexColor4(cw, unpack(self._cw_data[data_index]))
            local extra_data = self._extra_cw_data[i]
            if extra_data == nil then
                PseudoGame.game.cw_function_backup.cw_setCollision(cw, false)
                PseudoGame.game.cw_function_backup.cw_setDeadly(cw, false)
            else
                PseudoGame.game.cw_function_backup.cw_setCollision(cw, extra_data.collision)
                PseudoGame.game.cw_function_backup.cw_setDeadly(cw, extra_data.deadly)
                PseudoGame.game.cw_function_backup.cw_setKillingSide(cw, extra_data.killing_side)
            end
        end
        self._extra_index = 1
        self._current_index = 0
    end
end
