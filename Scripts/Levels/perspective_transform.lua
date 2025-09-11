-- Include useful files or existing libraries. These are found in the `Scripts`
-- folder.
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "common.lua")
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "commonpatterns.lua")
u_execDependencyScript("library_pseudogame", "pseudogame", "Baum", "main.lua")

-- remove them, so we can make our own
s_set3dDepth(0)

-- hide the real game
PseudoGame.hide_default_game()

-- create a fake game
local game = PseudoGame.game.Game:new({
    components = {
        background = true,
        walls = true,
        player = true,
        pivot = true,
        pseudo3d = false,
    },
})

-- overwrite the real game's functions (mostly wall functions)
game:overwrite()

-- project coordinates
local function perspective(x, y, z)
    if z < 1e-9 then
        z = 1e-9
    end
    return x / z, y / z
end

-- cache for transformed collections, indexed by the original ones
local transformed_collections = {}

-- draws a polygon collection at a certain depth, also animates a few values, optionally takes an overwrite color
local function transform_and_draw_collection(collection, depth, r, g, b, a)
    -- animate using a sine curve
    local animation_factor = math.sin(l_getLevelTime())
    -- rotate by -45..45° depending on animation_factor
    local rotate = PseudoGame.graphics.effects:rotate(math.rad(animation_factor * 45))

    -- get dimensions
    local width = PseudoGame.graphics.screen:get_width()
    local height = PseudoGame.graphics.screen:get_height()

    -- define the transformation function once instead of every time in the loop
    local function transformation(x, y, ...)
        -- normalize coordinates based on screen dimensions (-0.5..0.5 range)
        x = x / width
        y = y / height

        -- move camera across screen to improve visibility (since the angle changes as well)
        -- (note that the concept of camera doesn't really exist, we are just transforming everything
        --  to the viewport rather than moving some kind of observer (This is how all 3D rendering works))
        y = y + animation_factor * 0.6

        -- define a depth the polygons in this collection are supposed to have
        -- (increasing depth in the middle of the animation makes it look more natural)
        local z = depth + 0.5 * (1.2 - math.abs(animation_factor))

        -- actually apply the rotation using the function we generated above
        y, z = rotate(y, z)

        -- project the 3D coordinates onto a 2D plane
        x, y = perspective(x, y, z)

        -- return values with overwritten color if given
        -- also multiply by screen dimensions to undo normalization
        if r then
            return x * width, y * height, r, g, b, a
        end
        return x * width, y * height, ...
    end

    -- cache the transformed collections in a table (recreating them every frame would be very inefficient)
    transformed_collections[collection] = transformed_collections[collection]
        or PseudoGame.graphics.PolygonCollection:new()
    local transformed = transformed_collections[collection]

    -- copy the polygon data from the original collection and transform it
    local gen = transformed:generator()
    for polygon in collection:iter() do
        gen():copy_data_transformed(polygon, transformation)
    end

    -- draw the transformed collection
    PseudoGame.graphics.screen:draw_polygon_collection(transformed)
end

local custom3D = PseudoGame.graphics.PolygonCollection:new()

function onInput(frametime, movement, focus, swap)
    -- update our game
    game:update(frametime, movement, focus, swap)

    -- create a custom 3D collection so we can make the transformations ourselves
    custom3D:clear()
    custom3D:ref_add(game.component_collections.walls)
    -- game.component_collections.pivot also contains the cap which we don't want here
    custom3D:ref_add(game.pivot.polygon_collection)
    custom3D:ref_add(game.component_collections.player)

    -- transform and draw game collections
    transform_and_draw_collection(game.component_collections.background, 1.2)
    transform_and_draw_collection(custom3D, 1.2, game.style:get_layer_color(3))
    transform_and_draw_collection(custom3D, 1.0, game.style:get_layer_color(2))
    transform_and_draw_collection(custom3D, 0.8, game.style:get_layer_color(1))
    transform_and_draw_collection(game.component_collections.walls, 0.6)
    transform_and_draw_collection(game.component_collections.pivot, 0.6)
    transform_and_draw_collection(game.component_collections.player, 0.6)

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
    if mKey == 0 then
        pAltBarrage(u_rndInt(3, 5), 2)
    elseif mKey == 1 then
        pMirrorSpiral(u_rndInt(2, 5), getHalfSides() - 3)
    elseif mKey == 2 then
        pBarrageSpiral(u_rndInt(0, 3), 1, 1)
    elseif mKey == 3 then
        pInverseBarrage(0)
    elseif mKey == 4 then
        pTunnel(u_rndInt(1, 3))
    elseif mKey == 5 then
        pSpiral(l_getSides() * u_rndInt(1, 2), 0)
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

    -- in this example the rotation that is applied on top of the level
    -- essentially makes the camera roll, which might feel a bit unusual
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

    l_setPulseMin(80)
    l_setPulseMax(80)
    l_setPulseSpeed(1.2)
    l_setPulseSpeedR(1)
    l_setPulseDelayMax(23.9)

    l_setBeatPulseMax(0)
    l_setBeatPulseDelayMax(24.8)

    enableSwapIfDMGreaterThan(2.5)
    disableIncIfDMGreaterThan(3)
end

-- `onLoad` is an hardcoded function that is called when the level is started
-- or restarted.
function onLoad()
    e_messageAdd("welcome to the 13th PseudoGame example level", 150)
    e_messageAdd("Here transformations are used in a more\nadvanced way to create a 3D effect!", 200)
    e_messageAdd(
        "This doesn't really demonstrate any new\nfeatures though, it's still all just basic transformations.",
        400
    )
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
