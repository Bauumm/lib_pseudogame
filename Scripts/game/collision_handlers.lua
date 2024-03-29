--- Module containing premade collision handlers for use with the Player class
-- @module PseudoGame.game.collision_handlers

--- A function that handles collision of some polygons with a player
-- @tparam Player frametime  the time in 1/60s since the last call of this function
-- @tparam Player player  the player to handle collisions for (it may be moved in the process)
-- @tparam PolygonCollection collide_collection  the collection of polygons to collide with
-- @treturn bool  determines if the player should be killed
function PseudoGame.game.basic_collision_handler(frametime, player, collide_collection)
    local collides = false
    local last_collides = false
    local must_kill = false
    for polygon in collide_collection:iter() do
        if polygon.wall ~= nil and polygon.wall.curving then
            if polygon.wall.speed ~= 0 and polygon.wall.speed > 0 and 1 or -1 ~= player.movement_dir then
                if polygon:contains_point(unpack(player.pos)) then
                    player.pos[1], player.pos[2] =
                        PseudoGame.graphics.effects:rotate(polygon.wall.speed * frametime / 60)(unpack(player.last_pos))
                    player.angle = math.atan2(player.pos[2], player.pos[1])
                end
            end
        end
    end
    for polygon in collide_collection:iter() do
        local is_in = polygon:contains_point(unpack(player.pos))
        if polygon.extra_data ~= nil and polygon.extra_data.deadly and is_in then
            must_kill = true
        end
        collides = collides or is_in
        if not player.just_swapped then
            last_collides = last_collides or polygon:contains_point(unpack(player.last_pos))
        end
    end
    if collides then
        if player.just_swapped then
            must_kill = true
        elseif last_collides then
            must_kill = true
        elseif not must_kill then
            for i = 1, 2 do
                player.pos[i] = player.last_pos[i]
            end
            player.angle = player.last_angle
        end
    end
    return must_kill
end
