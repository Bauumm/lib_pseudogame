style = {
	background_colors = {}
}

function style.get_color_from_hue(hue)
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

function style:set_main_color(color)
	self.main_color = color
end

function style:get_main_color()
	if self.main_color == nil then
		return s_getMainColor()
	end
	return unpack(self.main_color)
end

function style:set_cap_color(color)
	self.cap_color = color
end

function style:get_cap_color()
	if self.cap_color == nil then
		return s_getCapColorResult()
	end
	return unpack(self.cap_color)
end

function style:set_color(index, color)
	self.background_colors[index + 1] = color
end

function style:get_color(index)
	if #self.background_colors == 0 then
		return s_getColor(index)
	end
	return unpack(self.background_colors[index % #self.background_colors + 1])
end
