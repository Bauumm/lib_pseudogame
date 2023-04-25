--- this script initializes the library
-- @script main

-- compatability with older versions of the game
if u_getVersionMajor() <= 2 and u_getVersionMinor() <= 1 and u_getVersionMicro() <= 6 then
    function u_isHeadless()
        return false
    end
end

u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")

PseudoGame = {
    graphics = {},
    game = {},
}

u_execScript("graphics/polygon_collection.lua")
u_execScript("graphics/polygon.lua")
u_execScript("graphics/screen.lua")
u_execScript("graphics/effects.lua")
u_execScript("game/custom_walls.lua")
u_execScript("game/common.lua")
u_execScript("game/style.lua")
u_execScript("game/background.lua")
u_execScript("game/cap.lua")
u_execScript("game/collision_handlers.lua")
u_execScript("game/player.lua")
u_execScript("game/death_effect.lua")
u_execScript("game/pivot.lua")
u_execScript("game/wall_system.lua")
u_execScript("game/pseudo3d.lua")
u_execScript("game/timeline.lua")
u_execScript("game/game.lua")

--- this function hides the default game components using a shader and default functions
function PseudoGame.hide_default_game()
    if not u_isHeadless() then
        local nothing_shader = shdr_getDependencyShaderId("library_pseudogame", "pseudogame", "Baum", "nothing.frag")
        if nothing_shader < 0 then
            error("Failed loading shader!")
        end
        shdr_setActiveFragmentShader(RenderStage.BACKGROUNDTRIS, nothing_shader)
        shdr_setActiveFragmentShader(RenderStage.PLAYERTRIS, nothing_shader)
        shdr_setActiveFragmentShader(RenderStage.PLAYERTRIS3D, nothing_shader)
        shdr_setActiveFragmentShader(RenderStage.CAPTRIS, nothing_shader)
        shdr_setActiveFragmentShader(RenderStage.PIVOTQUADS, nothing_shader)
        shdr_setActiveFragmentShader(RenderStage.PIVOTQUADS3D, nothing_shader)
        shdr_setActiveFragmentShader(RenderStage.WALLQUADS3D, nothing_shader)
        l_setShowPlayerTrail(false)
        l_setShadersRequired(true)
    end
end
