-- source/main.lua

import "libraries/roxy/roxy"

local pd  <const> = playdate
local r   <const> = roxy

pd.display.setRefreshRate(30)

import "scenes/SceneTest"
import "scenes/TransitionTest"
import "scenes/InputIntegrationTest"
import "scenes/SceneIntegrationTest"
import "scenes/TransitionIntegrationTest"
import "scenes/SequenceCIntegrationTest"
import "scenes/CameraIntegrationTest"
import "scenes/RoxySpriteIntegrationTest"
import "scenes/RoxyAnimationIntegrationTest"
import "scenes/RoxyActorIntegrationTest"
import "scenes/CacheIntegrationTest"
import "scenes/AssetsIntegrationTest"
r.Scene.registerScenes({
  SceneTest = SceneTest,
  TransitionTest = TransitionTest,
  InputIntegrationTest = InputIntegrationTest,
  SceneIntegrationTest = SceneIntegrationTest,
  TransitionIntegrationTest = TransitionIntegrationTest,
  SequenceCIntegrationTest = SequenceCIntegrationTest,
  CameraIntegrationTest = CameraIntegrationTest,
  RoxySpriteIntegrationTest = RoxySpriteIntegrationTest,
  RoxyAnimationIntegrationTest = RoxyAnimationIntegrationTest,
  RoxyActorIntegrationTest = RoxyActorIntegrationTest,
  CacheIntegrationTest = CacheIntegrationTest,
  AssetsIntegrationTest = AssetsIntegrationTest
})

r.new(AssetsIntegrationTest)
