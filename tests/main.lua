require("busted.runner")()

-- need to fake some open hexagon functions
module_env = {
    u_getVersionMajor = function()
        return 2
    end,
    u_getVersionMinor = function()
        return 1
    end,
    u_getVersionMicro = function()
        return 7
    end,
    u_execDependencyScript = function() end,
    u_execScript = function(script)
        loadfile("../Scripts/" .. script, "t", module_env)()
    end,
    u_getWidth = function()
        return 1024
    end,
    u_getHeight = function()
        return 768
    end,
    u_isHeadless = function()
        return false
    end,
    s_get3dDepth = function()
        return 0
    end,
    ct_create = function() end,
    ct_wait = function() end,
    ct_eval = function() end,
    s_get3dSkew = function()
        return 0
    end,
}
math.randomseed(os.time())
for k, v in pairs(_G) do
    module_env[k] = v
end
module_env.describe = describe
module_env.it = it
module_env.spy = spy
module_env.assert = assert

module_env.u_execScript("main.lua")

function get_tests(file)
    loadfile(file, "t", module_env)()
end

describe("graphics", function()
    get_tests("graphics/polygon.lua")
    get_tests("graphics/polygon_collection.lua")
    get_tests("graphics/screen.lua")
end)
