function get_random_collection_and_data()
    local polygon_collection = PseudoGame.graphics.PolygonCollection:new()
    local ininital_size = math.random(10, 20)
    polygon_collection:resize(ininital_size)
    local delete_amount = 0
    for i = 1, math.random(1, 8) do
        local index = math.random(1, polygon_collection._highest_index)
        if polygon_collection:get(index) ~= nil then
            polygon_collection:remove(index)
            delete_amount = delete_amount + 1
        end
    end
    -- ensure there's a nil in between
    if polygon_collection:get(1) ~= nil then
        polygon_collection:remove(1)
        delete_amount = delete_amount + 1
    end

    return polygon_collection, ininital_size, delete_amount
end

describe("polygon collection", function()
    it("add/remove", function()
        local polygon_collection, ininital_size, delete_amount = get_random_collection_and_data()
        assert.is_not.equal(polygon_collection.size, polygon_collection._highest_index)
        assert.equal(polygon_collection.size, ininital_size - delete_amount)
        polygon_collection:clear()
        assert.equal(polygon_collection.size, 0)
    end)
    it("get", function()
        local polygon_collection = get_random_collection_and_data()
        local polygon = PseudoGame.graphics.Polygon:new()
        local index = polygon_collection:add(polygon)
        assert.equal(polygon, polygon_collection:get(index))
    end)
    it("iter", function()
        local polygon_collection = get_random_collection_and_data()
        local index = 1
        local count = 0
        for polygon in polygon_collection:iter() do
            while polygon_collection:get(index) == nil do
                index = index + 1
            end
            assert.equal(polygon_collection:get(index), polygon)
            index = index + 1
            count = count + 1
        end
        assert.equal(count, polygon_collection.size)
    end)
    it("copy/ref add other collection", function()
        local polygon_collection0 = get_random_collection_and_data()
        local polygon_collection1 = get_random_collection_and_data()
        local size0, size1 = polygon_collection0.size, polygon_collection1.size
        polygon_collection0:ref_add(polygon_collection1)
        assert.equal(polygon_collection0.size, size0 + size1)
        local first_polygon = polygon_collection1:iter()()
        local is_in = false
        for polygon in polygon_collection0:iter() do
            if polygon == first_polygon then
                is_in = true
            end
        end
        assert.is_true(is_in)
        polygon_collection0:clear()
        polygon_collection0:copy_add(polygon_collection1)
        is_in = false
        for polygon in polygon_collection0:iter() do
            if polygon == first_polygon then
                is_in = true
            end
        end
        assert.is_false(is_in)
    end)
    it("generator", function()
        local polygon_collection = get_random_collection_and_data()
        local gen = polygon_collection:generator()
        assert.equal(polygon_collection.size, 0)
        local new_size = math.random(10, 20)
        local first = gen()
        for i = 2, new_size do
            gen()
        end
        assert.equal(polygon_collection.size, new_size)
        gen = polygon_collection:generator()
        assert.equal(gen(), first)
    end)
    it("transform", function()
        local polygon_collection = get_random_collection_and_data()
        for polygon in polygon_collection:iter() do
            spy.on(polygon, "transform")
        end
        local transform = function(x, y, r, g, b, a)
            return x, y, r, g, b, a
        end
        polygon_collection:transform(transform)
        for polygon in polygon_collection:iter() do
            assert.spy(polygon.transform).was.called()
            assert.spy(polygon.transform).was.called_with(polygon, transform)
        end
    end)
end)
