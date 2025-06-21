-- source/main.lua

import "libraries/roxy/roxy"

local pd  <const> = playdate
local r   <const> = roxy

pd.display.setRefreshRate(30)

import "scenes/SceneTest"
import "scenes/TransitionTest"
r.Scene.registerScenes({
  SceneTest = SceneTest,
  TransitionTest = TransitionTest
})

r.new(SceneTest)
