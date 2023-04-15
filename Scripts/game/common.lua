-- this function converts polar coordinates into cartesian ones and adds a start position
-- angle: number	-- the angle in radians
-- distance: number	-- the distance from the start pos
-- start_pos: table	-- the start pos, formatted like this: {x, y}
-- return: x, y		-- the resulting position
function PseudoGame.game.get_orbit(angle, distance, start_pos)
	if start_pos == nil then
		return math.cos(angle) * distance, math.sin(angle) * distance
	end
	return math.cos(angle) * distance + start_pos[1], math.sin(angle) * distance + start_pos[2]
end

-- get a color from a hue
-- hue: number		-- a number between 0 and 360
-- return: table	-- the resulting color in this format: {r, g, b, a}
function PseudoGame.game.get_color_from_hue(hue)
	hue = hue % 360 / 360
	local i = math.floor(hue * 6)

	local f = (hue * 6) - i
	local q = 1 - f
	local t = f

	function ret(r, g, b)
		return {r * 255, g * 255, b * 255, 255}
	end

	if i == 0 then return ret(1, t, 0)
	elseif i == 1 then return ret(q, 1, 0)
	elseif i == 2 then return ret(0, 1, t)
	elseif i == 3 then return ret(0, q, 1)
	elseif i == 4 then return ret(t, 0, 1)
	else return ret(1, 0, q)
	end
end
