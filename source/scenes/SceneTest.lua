-- source/scenes/SceneTest.lua

local pd        <const> = playdate
local Graphics  <const> = pd.graphics

local drawText  <const> = Graphics.drawText

-- ----------------------------------------
-- Class Definition & Init
-- ----------------------------------------

class("SceneTest").extends(RoxyScene)
local scene = SceneTest

-- ----------------------------------------
-- Scene Lifecycle (Core Methods)
-- ----------------------------------------

function scene:update(dt)
  drawText("Scene Test Scene", 20, 20)
end
