-- this scrip hides the default game components using a shader and default functions
u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")

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
l_setShadersRequired(true)
