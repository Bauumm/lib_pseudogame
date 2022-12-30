u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")


-- Attempt to make real player invisible on death too
local nothing_shader = shdr_getShaderId("nothing.frag")
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
