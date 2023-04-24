--- Class to create the blinking hexagonal death effects around a player
-- @classmod PseudoGame.game.DeathEffect
PseudoGame.game.DeathEffect = {}
PseudoGame.game.DeathEffect.__index = PseudoGame.game.DeathEffect

--- the constructor for a death effect
-- @tparam Player player  the player the death effect is for
-- @treturn DeathEffect
function PseudoGame.game.DeathEffect:new(player)
    return setmetatable({
        --- @tfield PolygonCollection polygon_collection  The collection of polygons representing the visual death effect (use this for drawing)
        polygon_collection = PseudoGame.graphics.PolygonCollection:new(),
        --- @tfield number player_hue  The hue the player and the death effect currently have
        player_hue = 0,
        --- @tfield bool dead  True if the player has died
        dead = false,
        --- @tfield number timer  The time the death effect is going to be shown for in invincible mode (counts down and stops showing the death effect once it reaches 0)
        timer = 0,
        --- @tfield Player player  The player the death effect is for
        player = player,
        _post_death_frametime_accumulator = 0,
    }, PseudoGame.game.DeathEffect)
end

--[[--
this function causes the death effect ot be shown permanently (should be called in `onDeath`)
make sure to update and draw the death effect in onRenderStage as the other functions aren't called after death
]]
function PseudoGame.game.DeathEffect:death()
    self.dead = true
    self.player.dead = true
end

--- this function shows the death effect for a moment (should be called in `onPreDeath`)
function PseudoGame.game.DeathEffect:invincible_death()
    self.timer = 100
end

--- update the death effects shape and color
-- @tparam number frametime  the time in 1/60s that passed since the last call to this function
function PseudoGame.game.DeathEffect:update(frametime)
    self.timer = self.timer - frametime
    if self.timer < 0 then
        self.timer = 0
    end
    if self.dead or self.timer > 0 then
        self.player_hue = self.player_hue + 18 * frametime
        if self.player_hue > 360 then
            self.player_hue = 0
        end
        local div = math.pi / 6
        local radius = self.player_hue / 8
        local thickness = self.player_hue / 20
        local color = PseudoGame.game.get_color_from_hue(360 - self.player_hue)
        local gen = self.polygon_collection:generator()
        for i = 0, 5 do
            local angle = div * i * 2
            local polygon = gen()
            polygon:resize(4)
            polygon:set_vertex_pos(1, PseudoGame.game.get_orbit(angle - div, radius, self.player.pos))
            polygon:set_vertex_pos(2, PseudoGame.game.get_orbit(angle + div, radius, self.player.pos))
            polygon:set_vertex_pos(3, PseudoGame.game.get_orbit(angle + div, radius + thickness, self.player.pos))
            polygon:set_vertex_pos(4, PseudoGame.game.get_orbit(angle - div, radius + thickness, self.player.pos))
            for i = 1, 4 do
                polygon:set_vertex_color(i, unpack(color))
            end
        end
        self.player.color = PseudoGame.game.get_color_from_hue(self.player_hue)
    else
        self.polygon_collection:clear()
        self.player.color = nil
    end
end

--[[--
ensures that a function is called 240 times per second in onRenderStage after death (does nothing if the death method wasn't called)
(only works if shaders are loaded, but that is usually the case when using this function as there's no need for a fake death effect if the player isn't hidden)
]]
-- @tparam number render_stage  the render stage that onRenderStage is being called for
-- @tparam number frametime  the inconsistent frametime that onRenderStage gets as second parameter
-- @tparam function draw_function  a function that will be called 240 times per second (should contain your drawing logic so the death effect can be drawn)
function PseudoGame.game.DeathEffect:ensure_tickrate(render_stage, frametime, draw_function)
    if self.dead and render_stage == 0 then
        self._post_death_frametime_accumulator = self._post_death_frametime_accumulator + frametime
        while self._post_death_frametime_accumulator >= 0.25 do
            self._post_death_frametime_accumulator = self._post_death_frametime_accumulator - 0.25
            draw_function(0.25)
        end
    end
end
