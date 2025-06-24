-- source/main.lua

import "libraries/roxy/roxy"

local pd  <const> = playdate
local r   <const> = roxy

pd.display.setRefreshRate(30)

import "scenes/SceneTest"
import "scenes/TransitionTest"
import "scenes/SceneIntegrationTest"
import "scenes/TransitionIntegrationTest"
import "scenes/SequenceCIntegrationTest"
r.Scene.registerScenes({
  SceneTest = SceneTest,
  TransitionTest = TransitionTest,
  SceneIntegrationTest = SceneIntegrationTest,
  TransitionIntegrationTest = TransitionIntegrationTest,
  SequenceCIntegrationTest = SequenceCIntegrationTest
})

r.new(SceneIntegrationTest)
