-- source/scenes/SceneTest.lua

local pd        <const> = playdate
local Graphics  <const> = pd.graphics

local clearScreen <const> = Graphics.clear
local newImage    <const> = Graphics.image.new
local drawText    <const> = Graphics.drawText

local replaceScene <const> = roxy.Transition.replaceScene

local COLOR_WHITE <const> = Graphics.kColorWhite
local COLOR_BLACK <const> = Graphics.kColorBlack
local CLEAR_COLOR <const> = COLOR_WHITE

-- ----------------------------------------
-- ! Class Definition & Init
-- ----------------------------------------

class("SceneTest").extends(RoxyScene)
local scene = SceneTest

function scene:init()
  local background = newImage("assets/images/nebula-bg")
  scene.super.init(self, background)

  self.inputHandler = {
    AButtonDown = function()
      print("Scene Test → Transition Test")
      replaceScene(TransitionTest)
    end
  }
end

-- ----------------------------------------
-- ! Scene Lifecycle
-- ----------------------------------------

function scene:enter()
  scene.super.enter(self)
end

function scene:update(dt)
  drawText("Scene Test Scene", 20, 20)
end

function scene:cleanup()
  scene.super.cleanup(self)
end
