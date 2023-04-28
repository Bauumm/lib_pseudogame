function get_random_polygon_with_data()
    local vertices = {}
    local colors = {}
    for i = 1, math.random(10, 20) do
        for j = 1, 2 do
            table.insert(vertices, math.random(-500, 500))
        end
        for j = 1, 4 do
            table.insert(colors, math.random(0, 255))
        end
    end
    return PseudoGame.graphics.Polygon:new(vertices, colors), vertices, colors
end

function get_quad(size)
    local polygon = PseudoGame.graphics.Polygon:new()
    polygon:add_vertex(0, 0, 0, 0, 0, 0)
    polygon:add_vertex(size, 0, 0, 0, 0, 0)
    polygon:add_vertex(size, size, 0, 0, 0, 0)
    polygon:add_vertex(0, size, 0, 0, 0, 0)
    return polygon
end

describe("polygon", function()
    it("vertex creation/deletion", function()
        for i = 0, 10 do
            local polygon
            if i == 0 then
                polygon = PseudoGame.graphics.Polygon:new()
            else
                local vertices = {}
                local colors = {}
                for j = 1, i do
                    for i = 1, 2 do
                        table.insert(vertices, 0)
                    end
                    for i = 1, 4 do
                        table.insert(colors, 0)
                    end
                end
                polygon = PseudoGame.graphics.Polygon:new(vertices, colors)
            end
            assert.equal(polygon.vertex_count, i)
            for j = 1, i do
                polygon:add_vertex(0, 0, 0, 0, 0, 0)
            end
            assert.equal(polygon.vertex_count, i * 2)
            polygon:resize(i)
            assert.equal(polygon.vertex_count, i)
            for j = 1, i do
                polygon:remove_vertex(1)
            end
            assert.equal(polygon.vertex_count, 0)
        end
    end)
    it("iterators", function()
        local polygon, vertices, colors = get_random_polygon_with_data()
        for index, x, y, r, g, b, a in polygon:vertex_color_pairs() do
            assert.equal(x, vertices[index * 2 - 1])
            assert.equal(y, vertices[index * 2])
            assert.equal(r, colors[index * 4 - 3])
            assert.equal(g, colors[index * 4 - 2])
            assert.equal(b, colors[index * 4 - 1])
            assert.equal(a, colors[index * 4])
        end
        local index = 1
        local wrap_index = 2
        for x0, y0, r0, g0, b0, a0, x1, y1, r1, g1, b1, a1 in polygon:edge_color_pairs() do
            assert.equal(x0, vertices[index * 2 - 1])
            assert.equal(y0, vertices[index * 2])
            assert.equal(r0, colors[index * 4 - 3])
            assert.equal(g0, colors[index * 4 - 2])
            assert.equal(b0, colors[index * 4 - 1])
            assert.equal(a0, colors[index * 4])
            assert.equal(x1, vertices[wrap_index * 2 - 1])
            assert.equal(y1, vertices[wrap_index * 2])
            assert.equal(r1, colors[wrap_index * 4 - 3])
            assert.equal(g1, colors[wrap_index * 4 - 2])
            assert.equal(b1, colors[wrap_index * 4 - 1])
            assert.equal(a1, colors[wrap_index * 4])
            index = index + 1
            wrap_index = index % polygon.vertex_count + 1
        end
    end)
    it("vertex pos/color set/get", function()
        local polygon, vertices, colors = get_random_polygon_with_data()
        local function check_table_equal()
            for i = 1, polygon.vertex_count do
                local x, y = polygon:get_vertex_pos(i)
                assert.equal(x, vertices[i * 2 - 1])
                assert.equal(y, vertices[i * 2])
                local r, g, b, a = polygon:get_vertex_color(i)
                assert.equal(r, colors[i * 4 - 3])
                assert.equal(g, colors[i * 4 - 2])
                assert.equal(b, colors[i * 4 - 1])
                assert.equal(a, colors[i * 4])
            end
        end
        check_table_equal()
        for i = 1, polygon.vertex_count do
            local x, y = math.random(-500, 500), math.random(-500, 500)
            polygon:set_vertex_pos(i, x, y)
            vertices[i * 2 - 1] = x
            vertices[i * 2] = y
            local r, g, b, a = math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255)
            polygon:set_vertex_color(i, r, g, b, a)
            colors[i * 4 - 3] = r
            colors[i * 4 - 2] = g
            colors[i * 4 - 1] = b
            colors[i * 4] = a
        end
        check_table_equal()
    end)
    it("copy/copy_data...", function()
        local polygon = get_random_polygon_with_data()
        local copy = polygon:copy()
        assert.same(polygon, copy)
        -- bounds of get_random_polygon_with_data is -500 to 500, so should no longer be the same
        copy:set_vertex_pos(math.random(1, copy.vertex_count), 1000, 1000)
        assert.is_not.same(polygon, copy)
        polygon:copy_data(copy)
        assert.same(polygon, copy)
    end)
    it("transform", function()
        local polygon, vertices, colors = get_random_polygon_with_data()
        local copy = polygon:copy()
        local function check_transform(change)
            for index, x, y, r, g, b, a in copy:vertex_color_pairs() do
                local xp, yp = polygon:get_vertex_pos(index)
                assert.equal(x, xp - change)
                assert.equal(y, yp - change)
                local rp, gp, bp, ap = polygon:get_vertex_color(index)
                assert.equal(r, rp - change)
                assert.equal(g, gp - change)
                assert.equal(b, bp - change)
                assert.equal(a, ap - change)
            end
        end
        local change = math.random(1, 10)
        polygon:transform(function(x, y, r, g, b, a)
            return x + change, y + change, r + change, g + change, b + change, a + change
        end)
        check_transform(change)
        local change = -math.random(1, 10)
        polygon:copy_data_transformed(copy, function(x, y, r, g, b, a)
            return x + change, y + change, r + change, g + change, b + change, a + change
        end)
        check_transform(change)
    end)
    it("contains point", function()
        local polygon = get_quad(1)
        assert.is_false(polygon:contains_point(-0.01, 0))
        assert.is_true(polygon:contains_point(0.99, 0))
    end)
    it("slice", function()
        -- slicing quad into two same sized squares, mirroring one back and checking that the second contains all vertices of the first
        local polygon = get_quad(1)
        local polygon0, polygon1 = polygon:slice(0.5, 0, 0.5, 1, true, true)
        polygon1:transform(function(x, y, r, g, b, a)
            return 1 - x, y, r, g, b, a
        end)
        assert.equal(polygon0.vertex_count, polygon1.vertex_count)
        for _, x0, y0 in polygon0:vertex_color_pairs() do
            local has_vertex = false
            for _, x1, y1 in polygon1:vertex_color_pairs() do
                if x0 == x1 and y0 == y1 then
                    has_vertex = true
                end
            end
            assert.is_true(has_vertex)
        end
    end)
    it("clip", function()
        local polygon = get_random_polygon_with_data()
        local clipper = get_quad(501)
        local clipped = polygon:clip(clipper)
        if clipped == nil then
            for _, x, y in polygon:vertex_color_pairs() do
                assert.is_false(clipper:contains_point(x, y))
            end
        else
            for _, x, y in clipped:vertex_color_pairs() do
                assert.is_true(clipper:contains_point(x, y))
            end
        end
    end)
end)
