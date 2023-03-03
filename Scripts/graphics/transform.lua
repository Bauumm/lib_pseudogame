transform = {}

-- generates a transformation function that rotates vertices
-- angle: number	-- the angle to rotate
-- return: function	-- the transformation function
function transform.rotate(angle)
	local cos, sin = math.cos(angle), math.sin(angle)
	return function(x, y, r, g, b, a)
		return x * cos - y * sin, x * sin + y * cos, r, g, b, a
	end
end

-- generates a transformation function that mirrors vertices
-- mirror_x: bool	-- whether it should mirror along the x axis
-- mirror_y: bool	-- whether it should mirror along the y axis
-- return: function	-- the transformation function
function transform.mirror(mirror_x, mirror_y)
	mirror_x = mirror_x and -1 or 1
	mirror_y = mirror_y and -1 or 1
	return function(x, y, r, g, b, a)
		return x * mirror_x, y * mirror_y, r, g, b, a
	end
end
