-- source/main.lua

local pd <const> = playdate

import "libraries/roxy/roxy"

pd.display.setRefreshRate(30)

import "scenes/SceneTest"
roxy.Scene.registerScenes({ SceneTest = SceneTest })

roxy.new(SceneTest)
