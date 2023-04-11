function basic_collision_handler(player, collide_collection)
	local collides = false
	local last_collides = false
	local must_kill = false
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
			for i=1, 2 do
				player.pos[i] = player.last_pos[i]
			end
			player.angle = player.last_angle
		end
	end
	return must_kill
end
