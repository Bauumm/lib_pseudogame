-- Include useful files or existing libraries. These are found in the `Scripts`
-- folder.
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "common.lua")
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "commonpatterns.lua")
u_execDependencyScript("library_pseudogame", "pseudogame", "Baum", "main.lua")

-- no need to hide or recreate the game as we just need walls
-- so we just make a wall system
walls = PseudoGame.game.WallSystem:new({
	despawn_distance = 3200
})

function onInput(frametime, movement, focus, swap)
	-- pattern spawning
	if walls.wall_height < 1600 then
		-- add space between patterns
		local height = walls.wall_height + 200

		-- add more space on level start
		if height == 200 then
			height = 1600
		end

		local pattern = math.random(0, 1)
		if pattern == 0 then
			-- tunnel
			local start_side = math.random(1, l_getSides())
			local dir = 1 - math.random(0, 1) * 2
			for times = 1, math.random(1, 4) do
				walls:wall(height, 0, start_side, 300)
				for side = 1, l_getSides() - 2  do
					walls:wall(height, 0, start_side + side * dir, 50)
				end
				dir = -dir
				height = height + 300
			end
			for side = 0, l_getSides() - 2  do
				walls:wall(height, 0, start_side + side * dir, 50)
			end
		elseif pattern == 1 then
			-- mirror spiral
			local start_side = math.random(1, l_getSides())
			local dir = 1 - math.random(0, 1) * 2
			for side = 1, math.random(8, 20) do
				walls:wall(height, 0, start_side + side * dir, 50)
				walls:wall(height, 0, start_side + side * dir + l_getSides() / 2, 50)
				height = height + 50
			end
		end
	end

	-- update our wall system
	walls:update(frametime)

	-- make walls collide with the player using the game's actual custom wall collisions
	for polygon in walls.polygon_collection:iter() do
		polygon.extra_data = {
			collision = true
		}
	end

	-- draw the walls to the screen
	PseudoGame.graphics.screen:draw_polygon_collection(walls.polygon_collection)
	PseudoGame.graphics.screen:update()
end

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

    l_setIncEnabled(false)

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
    e_messageAdd("welcome to the seventh PseudoGame example level", 150)
    e_messageAdd("This is a normal level using height based walls.", 200)
end

-- `onIncrement` is an hardcoded function that is called when the level
-- difficulty is incremented.
function onIncrement()
    -- ...
end

-- `onUpdate` is an hardcoded function that is called every frame. `mFrameTime`
-- represents the time delta between the current and previous frame.
function onUpdate(mFrameTime)
    -- ...
end
