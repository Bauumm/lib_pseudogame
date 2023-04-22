-- Include useful files or existing libraries. These are found in the `Scripts`
-- folder.
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "common.lua")
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "commonpatterns.lua")
u_execDependencyScript("library_pseudogame", "pseudogame", "Baum", "main.lua")

-- WARNING: This example has become pretty complicated as both copies of the game have 3D effect that goes downward, only use this as reference if you really need that (otherwise checkout the other desync example)

-- reduce 3d layers as too many custom walls may lag for some people
s_set3dSpacing(10)
s_set3dDepth(3)

-- hide the real game
PseudoGame.hide_default_game()

-- create a fake game
game = PseudoGame.game.Game:new()

-- overwrite the real game's functions (mostly wall functions)
game:overwrite()

-- transform functions for the two copies of the game
function transform_function(x, y, r, g, b, a)
	local rotate_other_dir = PseudoGame.graphics.effects:rotate(math.rad(2 * l_getRotation()))
	x, y = rotate_other_dir(x, y)
	return x, y, 255 - r, 255 - g, 255 - b, a
end

function transform_half_alpha(x, y, r, g, b, a)
	return x, y, r, g, b, a / 2
end

function transform_just_color(x, y, r, g, b, a)
	return x, y, 255 - r, 255 - g, 255 - b, a
end

-- create another 3d effect for the 2nd copy of the game as we want both of them to have their layers below
-- it will also need another collection to put the polygons to make the 3d effect for in
-- (you can ignore this part if you're not interested in your desync level having proper 3d)
new_3d_collection = PseudoGame.graphics.PolygonCollection:new()
pseudo3d = PseudoGame.game.Pseudo3D:new(new_3d_collection)

-- create our own polygon collections that will contain the transformed polygons (of the walls, pivot and player) that are gonna be drawn to the screen (and used for the new 3d)
transformed_collections = {}
for i = 1, 3 do
	transformed_collections[i] = PseudoGame.graphics.PolygonCollection:new()
end

function onInput(frametime, movement, focus, swap)
	-- update our game
	game:update(frametime, movement, focus, swap)

	-- draw the game's background
	-- half the alpha of the background
	game.component_collections.background:transform(transform_half_alpha)
	-- draw it
	PseudoGame.graphics.screen:draw_polygon_collection(game.component_collections.background)
	-- transform it to the other half
	game.component_collections.background:transform(transform_function)
	-- draw it again
	PseudoGame.graphics.screen:draw_polygon_collection(game.component_collections.background)
	-- the transformation doesn't need to be undone as the background will be set back in the next tick (this does not apply to walls, they move relatively)
	
	-- draw the default 3d with half alpha
	game.component_collections.pseudo3d:transform(transform_half_alpha)
	PseudoGame.graphics.screen:draw_polygon_collection(game.component_collections.pseudo3d)

	-- transform walls, pivot and player but don't draw them yet
	for i = 1, 3 do
		local game_index = i + 2  -- 3: walls, 4: pivot, 5: player
		game.collections[game_index]:transform(transform_half_alpha)
		-- polygons have to be copied since both copies have to be drawn later
		-- (could actually copy the polygons directly, but creating new polygons all the time is bad for performance)
		local gen = transformed_collections[i]:generator()
		for polygon in game.collections[game_index]:iter() do
			gen():copy_data_transformed(polygon, transform_function)
		end
	end

	-- draw the transformed 3d effect
	-- clear the collection
	new_3d_collection:clear()
	-- add the polygons to make 3d for
	for i = 1, 3 do
		if i == 2 then
			-- can't just use the pivot collection as it includes the cap
			-- need to index and transform the pivot object's collection directly
			game.pivot.polygon_collection:transform(transform_function)
			new_3d_collection:ref_add(game.pivot.polygon_collection)
		else
			new_3d_collection:ref_add(transformed_collections[i])
		end
	end
	-- make the 3d
	pseudo3d:update(frametime)
	-- do color transformation as the 3d uses style information
	pseudo3d.polygon_collection:transform(transform_just_color)
	-- draw it
	PseudoGame.graphics.screen:draw_polygon_collection(pseudo3d.polygon_collection)

	-- draw the walls, the pivot and the player
	for i = 1, 3 do
		local game_index = i + 2  -- 3: walls, 4: pivot, 5: player
		PseudoGame.graphics.screen:draw_polygon_collection(game.collections[game_index])
		PseudoGame.graphics.screen:draw_polygon_collection(transformed_collections[i])
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
    e_messageAdd("welcome to the fifth PseudoGame example level", 150)
    e_messageAdd("Here transformations are used in a more\nadvanced way to create a desync level!", 200)
    e_messageAdd("This example also uses the 3D component\nindividually to make the desynced 3D look good!", 200)
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

-- `onUnload` is an hardcoded function that is called when the level is
-- closed/restarted.
function onUnload()
	-- overwriting game functions may cause issues, so it's important to undo it
	game:restore()
end

-- `onUpdate` is an hardcoded function that is called every frame. `mFrameTime`
-- represents the time delta between the current and previous frame.
function onUpdate(mFrameTime)
    -- ...
end
