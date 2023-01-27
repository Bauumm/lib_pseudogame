clipping = {}

function clipping:divide_poly(points)
	if #points == 0 then
		return
	end
	local polys = {}
	local offset = 0
	local done = false
	while not done do
		local poly = {}
		for i=1,8 do
			local coord = points[i + offset]
			if coord == nil then
				poly[#poly + 1] = points[(i - 1) % 2 + 1]
				done = true
			end
			poly[#poly + 1] = coord
		end
		offset = offset + 6
		polys[#polys + 1] = poly
	end
	return polys
end

function clipping:remove_doubles(points)
	for i=#points, 1, -2 do
		if points[i - 1] == points[i - 3] and points[i] == points[i - 2] then
			table.remove(points, i)
			table.remove(points, i - 1)
		end
	end
end

-- Implementation of the sutherland hodgman algorithm for polygon clipping
-- Don't use this as reference I made it unreadable to improve performance
function clipping:get_clipped_poly(poly_points, clipper_points)
	clipping:remove_doubles(poly_points)
	clipping:remove_doubles(clipper_points)
	for i=1, #clipper_points, 2 do
		local x1, y1 = clipper_points[i], clipper_points[i + 1]
		local x2, y2 = clipper_points[(i + 1) % #clipper_points + 1], clipper_points[(i + 2) % #clipper_points + 1]
		local dx, dy = x2 - x1, y2 - y1
		local const_num_part = (x1*y2 - y1*x2)
		local first_x, first_y
		local poly_size = 2
		for i = 1, #poly_points, 2 do
			local ix, iy = poly_points[i], poly_points[i + 1]
			local kx, ky = poly_points[(i + 1) % #poly_points + 1], poly_points[(i + 2) % #poly_points + 1]
			local i_pos, k_pos = dx * (iy-y1) - dy * (ix-x1), dx * (ky-y1) - dy * (kx-x1)
			local case0, case1, case2 = i_pos < 0 and k_pos < 0, i_pos >= 0 and k_pos < 0, i_pos < 0 and k_pos >= 0
			local isect, add_this = case1 or case2, case0 or case1
			if isect then
				local dikx, diky = ix - kx, iy - ky
				local other_num_part = (ix*ky - iy*kx)
				local den = dy * dikx - dx * diky
				if first_x ~= nil then
					poly_size = poly_size + 2
					poly_points[poly_size - 1] = (const_num_part * dikx + dx * other_num_part) / den
					poly_points[poly_size] = (const_num_part * diky + dy * other_num_part) / den
				else
					first_x = (const_num_part * dikx + dx * other_num_part) / den
					first_y = (const_num_part * diky + dy * other_num_part) / den
				end
			end
			if add_this then
				if first_x ~= nil then
					poly_size = poly_size + 2
					poly_points[poly_size - 1] = kx
					poly_points[poly_size] = ky
				else
					first_x = kx
					first_y = ky
				end
			end
		end
		poly_points[1] = first_x
		poly_points[2] = first_y
		while #poly_points > poly_size do
			poly_points[#poly_points] = nil
		end
		clipping:remove_doubles(poly_points)
		if #poly_points == 0 then
			break
		end
	end
end

function clipping:slice(poly_points, x1, y1, x2, y2)
	local dx, dy = x2 - x1, y2 - y1
	local side1poly = {}
	local side2poly = {}
	for i = 1, #poly_points, 2 do
		local ix, iy = poly_points[i], poly_points[i + 1]
		local kx, ky = poly_points[(i + 1) % #poly_points + 1], poly_points[(i + 2) % #poly_points + 1]
		local i_pos, k_pos = dx * (iy-y1) - dy * (ix-x1), dx * (ky-y1) - dy * (kx-x1)
		local iside, kside = i_pos >= 0, k_pos >= 0
		if iside then
			side1poly[#side1poly + 1] = ix
			side1poly[#side1poly + 1] = iy
		else
			side2poly[#side2poly + 1] = ix
			side2poly[#side2poly + 1] = iy
		end
		if iside ~= kside then
			local dikx, diky = ix - kx, iy - ky
			local num_part1 = (x1*y2 - y1*x2)
			local num_part2 = (ix*ky - iy*kx)
			local den = dy * dikx - dx * diky
			local x = (num_part1 * dikx + dx * num_part2) / den
			local y = (num_part1 * diky + dy * num_part2) / den
			side1poly[#side1poly + 1] = x
			side1poly[#side1poly + 1] = y
			side2poly[#side2poly + 1] = x
			side2poly[#side2poly + 1] = y
		end
	end
	return side1poly, side2poly
end
