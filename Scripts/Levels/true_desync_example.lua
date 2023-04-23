-- Include useful files or existing libraries. These are found in the `Scripts`
-- folder.
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "common.lua")
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "commonpatterns.lua")
u_execDependencyScript("library_pseudogame", "pseudogame", "Baum", "main.lua")

-- remove 3d as it would look very weird
s_set3dDepth(0)

-- hide the real game
PseudoGame.hide_default_game()

-- create a fake game
game = PseudoGame.game.Game:new()

-- overwrite the real game's functions (mostly wall functions)
game:overwrite()

-- transform functions for the two copies of the game (this time without alpha reduction)
transforms = {
	function(x, y, r, g, b, a)
		local rotate_other_dir = PseudoGame.graphics.effects:rotate(math.rad(2 * l_getRotation()))
		x, y = rotate_other_dir(-x, y)
		return x, y, 255 - r, g, b, a
	end,
	function(x, y, r, g, b, a)
		return x, y, r, g, b, a
	end
}

-- create two tmp collections used for the blending operations
tmp_collections = {PseudoGame.graphics.PolygonCollection:new(), PseudoGame.graphics.PolygonCollection:new()}

-- draw directly to screen instead of filling up a collection
PseudoGame.graphics.effects.draw_directly = true

function onInput(frametime, movement, focus, swap)
	-- update our game
	game:update(frametime, movement, focus, swap)

	-- iterate over all of the game's collections in render order
	for j = 1, #game.collections do
		-- for each transform...
		for i = 1, 2 do
			-- add the polygons of the current collection to the tmp collections depending on the transform
			local tmp_gen = tmp_collections[i]:generator()
			for polygon in game.collections[j]:iter() do
				local new_polygon = tmp_gen()
				new_polygon:copy_data_transformed(polygon, transforms[i])
				
				-- immediately draw the polygons to the screen
				PseudoGame.graphics.screen:draw_polygon(new_polygon)
			end
		end
		for i = 1, 2 do
			-- get the intersection polygons of the two collections (their color is calculated using the blending function)
			-- (draws result directly to the screen as draw_directly is true)
			PseudoGame.graphics.effects:blend(tmp_collections[1], tmp_collections[2], function(r0, g0, b0, a0, r1, g1, b1, a1)
				local function clamp(c)
					if c > 255 then
						return 255
					elseif c < 0 then
						return 0
					end
					return c
				end
				return clamp(r0 + r1) / 1.3, clamp(g0 + g1) / 1.3, clamp(b0 + b1) / 1.3, 255
			end)
		end
	end
	
	-- update the screen
	PseudoGame.graphics.screen:update()
end

-- show a death effect when the player dies
function onDeath()
	game.death_effect:death()
end

-- show a death effect for 5/3 seconds when dying in invincible mode (that's what the real game does)
function onPreDeath()
	game.death_effect:invincible_death()
end

-- show and update the death effect even in the death screen
function onRenderStage(render_stage, frametime)
	game.death_effect:ensure_tickrate(render_stage, frametime, function(new_frametime)
		-- updating and drawing the game again is required for the death effect to show properly
		-- (make sure no game logic is progressing if `game.death_effect.dead == true`)
		onInput(new_frametime, 0, false, false)
	end)
end

-- This function adds a pattern to the level "timeline" based on a numeric key.
function addPattern(mKey)
        if mKey == 0 then pAltBarrage(u_rndInt(3, 5), 2)
    elseif mKey == 1 then pMirrorSpiral(u_rndInt(2, 5), getHalfSides() - 3)
    elseif mKey == 2 then pBarrageSpiral(u_rndInt(0, 3), 1, 1)
    elseif mKey == 3 then pInverseBarrage(0)
    elseif mKey == 4 then pTunnel(u_rndInt(1, 3))
    elseif mKey == 5 then pSpiral(l_getSides() * u_rndInt(1, 2), 0)
    end
end

-- Shuffle the keys, and then call them to add all the patterns.
-- Shuffling is better than randomizing - it guarantees all the patterns will
-- be called.
keys = { 0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 5 }
shuffle(keys)
index = 0
achievementUnlocked = false

-- `onInit` is an hardcoded function that is called when the level is first
-- loaded. This can be used to setup initial level parameters.
function onInit()
    l_setSpeedMult(1.55)
    l_setSpeedInc(0.125)
    l_setSpeedMax(3.5)
    l_setRotationSpeed(0.07)
    l_setRotationSpeedMax(0.75)
    l_setRotationSpeedInc(0.04)
    l_setDelayMult(1.0)
    l_setDelayInc(-0.01)
    l_setFastSpin(0.0)
    l_setSides(6)
    l_setSidesMin(5)
    l_setSidesMax(6)
    l_setIncTime(15)

    l_setPulseMin(75)
    l_setPulseMax(91)
    l_setPulseSpeed(1.2)
    l_setPulseSpeedR(1)
    l_setPulseDelayMax(23.9)

    l_setBeatPulseMax(17)
    l_setBeatPulseDelayMax(24.8)

    enableSwapIfDMGreaterThan(2.5)
    disableIncIfDMGreaterThan(3)
end

-- `onLoad` is an hardcoded function that is called when the level is started
-- or restarted.
function onLoad()
    e_messageAdd("welcome to the sixth PseudoGame example level", 150)
    e_messageAdd("Here transformations are used in a more\nadvanced way to create a desync level!", 200)
    e_messageAdd("Additionally custom color blending is used here!", 200)
end

-- `onStep` is an hardcoded function that is called when the level "timeline"
-- is empty. The level timeline is a queue of pending actions.
-- `onStep` should generally contain your pattern spawning logic.
function onStep()
    addPattern(keys[index])
    index = index + 1

    if index - 1 == #keys then
        index = 1
        shuffle(keys)
    end
end

-- `onIncrement` is an hardcoded function that is called when the level
-- difficulty is incremented.
function onIncrement()
    -- ...
end

function onPreUnload()
	-- overwriting game functions may cause issues, so it's important to undo it
	game:restore()
end

-- `onUpdate` is an hardcoded function that is called every frame. `mFrameTime`
-- represents the time delta between the current and previous frame.
function onUpdate(mFrameTime)
    -- ...
end
