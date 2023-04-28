--- Some functions that are commonly used in the game logic
-- @module PseudoGame.game.common

--- this function converts polar coordinates into cartesian ones and adds a start position
-- @tparam number angle  the angle in radians
-- @tparam number distance  the distance from the start pos
-- @tparam table start_pos  the start pos, formatted like this: `{x, y}`
-- @treturn number,number  the resulting position
function PseudoGame.game.get_orbit(angle, distance, start_pos)
    if start_pos == nil then
        return math.cos(angle) * distance, math.sin(angle) * distance
    end
    return math.cos(angle) * distance + start_pos[1], math.sin(angle) * distance + start_pos[2]
end

--- get a color from a hue
-- @tparam number hue  a number between 0 and 360
-- @treturn table  the resulting color in this format: `{r, g, b, a}`
function PseudoGame.game.get_color_from_hue(hue)
    hue = hue % 360 / 360
    local i = math.floor(hue * 6)

    local f = (hue * 6) - i
    local q = 1 - f
    local t = f

    function ret(r, g, b)
        return { r * 255, g * 255, b * 255, 255 }
    end

    if i == 0 then
        return ret(1, t, 0)
    elseif i == 1 then
        return ret(q, 1, 0)
    elseif i == 2 then
        return ret(0, 1, t)
    elseif i == 3 then
        return ret(0, q, 1)
    elseif i == 4 then
        return ret(t, 0, 1)
    else
        return ret(1, 0, q)
    end
end

--- transform a color by a hue
-- @tparam number hue  the hue to transform by
-- @tparam number r  the r component of the color to transform
-- @tparam number g  the g component of the color to transform
-- @tparam number b  the b component of the color to transform
-- @treturn number,number,number,number  the resulting color
function PseudoGame.game.transform_hue(hue, r, g, b)
    -- using 3.14 instead of pi for parity with the OH code
    local u = math.cos(hue * 3.14 / 180)
    local w = math.sin(hue * 3.14 / 180)
    return math.floor((0.701 * u + 0.168 * w) * r + (-0.587 * u + 0.330 * w) * g + (-0.114 * u - 0.497 * w) * b) % 256,
        math.floor((-0.299 * u - 0.328 * w) * r + (0.413 * u + 0.035 * w) * g + (-0.114 * u + 0.292 * w) * b) % 256,
        math.floor((-0.3 * u + 1.25 * w) * r + (-0.588 * u - 1.05 * w) * g + (0.886 * u - 0.203 * w) * b) % 256,
        255
end
