-- Include useful files or existing libraries. These are found in the `Scripts`
-- folder.
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "common.lua")
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "commonpatterns.lua")
u_execDependencyScript("library_pseudogame", "pseudogame", "Baum", "main.lua")

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

-- onStep for custom timeline, not calling it onStep as it would be called by the default game
function onFakeStep()
    addPattern(keys[index])
    index = index + 1

    if index - 1 == #keys then
        index = 1
        shuffle(keys)
    end
end

-- `onInit` is an hardcoded function that is called when the level is first
-- loaded. This can be used to setup initial level parameters.
function onInit()
	l_setSpeedMult(1.55)
	l_setSpeedInc(0.125)
	l_setSpeedMax(3.5)
	l_setRotationSpeed(0)
	l_setRotationSpeedMax(0)
	l_setRotationSpeedInc(0)
	l_setDelayMult(1.0)
	l_setDelayInc(-0.01)
	l_setFastSpin(0.0)
	l_setSides(6)
	l_setSidesMin(5)
	l_setSidesMax(6)
	l_setIncTime(15)

	-- would wait until all games don't have walls, which is a pretty long time
	l_setIncEnabled(false)

	l_setPulseMin(75)
	l_setPulseMax(75)
	l_setPulseSpeed(1.2)
	l_setPulseSpeedR(1)
	l_setPulseDelayMax(23.9)

	l_setBeatPulseMax(17)
	l_setBeatPulseDelayMax(24.8)

	enableSwapIfDMGreaterThan(2.5)
	disableIncIfDMGreaterThan(3)
	if not u_inMenu() then
		-- adjust 3d
		s_set3dDepth(0)
		s_set3dSkew(0)

		-- hide the real game
		PseudoGame.hide_default_game()

		-- grid size
		if u_getDifficultyMult() < 1 then
			w = 1
			h = 2
		elseif u_getDifficultyMult() > 1 then
			w = 3
			h = 3
			rot_disabled = true
		else
			w = 2
			h = 2
		end

		-- create games
		games = {}
		-- make games rotate individually
		rotation_values = {}
		for i = 1, w * h do
			table.insert(games, PseudoGame.game.Game:new({
				-- making our own timeline for each game using onFakeStep to spawn patterns
				walls = {
					timeline = PseudoGame.game.Timeline:new(onFakeStep)
				}
			}))
			table.insert(rotation_values, 0)
		end

		-- position them in a grid
		game_grid = {{}}
		for i = 1, #games do
			-- update every game once so there's something to draw
			games[i]:overwrite()
			games[i]:update(0, 0, false, false)
			games[i]:restore()
			-- have to overwrite for updating here as the game's timeline is empty calling onFakeStep (which uses default game functions)

			-- start a new grid line every 3rd element
			if #game_grid[#game_grid] == w then
				game_grid[#game_grid + 1] = {}
			end

			-- append to current grid line
			table.insert(game_grid[#game_grid], games[i])
		end

		-- overwrite the real game's functions (mostly wall functions) with the last game
		games[1]:overwrite()

		-- keep track of the selected game
		game = games[1]
		current_index = 1

		-- change which game is being accessed every 5s
		overwrite_timeline = ct_create()
		ct_wait(overwrite_timeline, 300)
		ct_eval(overwrite_timeline, [[next_game()]])

		function next_game()
			game:restore()
			current_index = current_index + 1
			if current_index > #games then
				current_index = 1
			end
			game = games[current_index]
			game:overwrite()
			ct_wait(overwrite_timeline, 300)
			ct_eval(overwrite_timeline, [[next_game()]])
		end

		-- tmp collection for better clipping performance
		tmp_collection = PseudoGame.graphics.PolygonCollection:new()

		width = PseudoGame.graphics.screen:get_width()
		height = PseudoGame.graphics.screen:get_height()
		screen_bounds = PseudoGame.graphics.Polygon:new({-width / 2, -height / 2, -width / 2, height / 2, width / 2, height / 2, width / 2, -height / 2}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
	end
end

function onInput(frametime, movement, focus, swap)
	local game_width = width / #game_grid[1]
	local game_height = height / #game_grid
	local to_side = -width / 2 + game_width / 2
	local to_top = -height / 2 + game_height / 2
	local tmp_gen = tmp_collection:generator()

	-- update current game
	game:update(frametime, movement, focus, swap)
	rotation_values[current_index] = rotation_values[current_index] + frametime / 60

	-- draw games
	for j = 1, #game_grid do
		local row = game_grid[j]
		for i = 1, #row do
			row[i]:draw()
			for polygon in row[i].polygon_collection:iter() do
				local in_polygon

				-- apply rotation before clipping if rotation is enabled
				if rot_disabled then
					in_polygon = polygon:clip(screen_bounds, tmp_gen)
				else
					local new_polygon = tmp_gen()
					new_polygon:copy_data_transformed(polygon, PseudoGame.graphics.effects:rotate(rotation_values[(j - 1) * #game_grid[1] + i]))
					in_polygon = new_polygon:clip(screen_bounds, tmp_gen)
				end

				-- if polygon is within clipping area, transform it to its part in the grid and draw it
				if in_polygon ~= nil then
					in_polygon:transform(function(x, y, r, g, b, a)
						return x / #game_grid[1] + to_side + (i - 1) * game_width, y / #game_grid + to_top + (j - 1) * game_height, r, g, b, a
					end)
					PseudoGame.graphics.screen:draw_polygon(in_polygon)
				end
			end
		end
	end

	-- update the screen
	PseudoGame.graphics.screen:update()
end

-- show a death effect when the player dies
function onDeath()
	for i = 1, #games do
		games[i].death_effect:death()
	end
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

-- `onLoad` is an hardcoded function that is called when the level is started
-- or restarted.
function onLoad()
    e_messageAdd("welcome to the seventh PseudoGame example level", 150)
    e_messageAdd("This example is using multiple game objects.", 200)
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
