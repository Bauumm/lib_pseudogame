PolyLayer = {}
PolyLayer.__index = PolyLayer

function PolyLayer:new()
	return setmetatable({
		polygons = {}
	}, PolyLayer)
end
