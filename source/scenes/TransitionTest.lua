-- source/scenes/TransitionTest.lua

local pd        <const> = playdate
local Graphics  <const> = pd.graphics

local pushHandler   <const> = pd.inputHandlers.push
local popHandler    <const> = pd.inputHandlers.pop

local clearScreen   <const> = Graphics.clear
local drawText      <const> = Graphics.drawText
local replaceScene  <const> = roxy.Transition.replaceScene

local COLOR_WHITE <const> = Graphics.kColorWhite
local CLEAR_COLOR <const> = COLOR_WHITE

-- ----------------------------------------
-- Class Definition & Init
-- ----------------------------------------

class("TransitionTest").extends(RoxyScene)
local scene = TransitionTest

function scene:init()
  scene.super.init(self)

  self.inputHandlers = {
    AButtonDown = function()
      print("Transition Test → Scene Test")
      replaceScene(SceneTest, "FadeToBlack")
    end
  }
end

-- ----------------------------------------
-- Scene Lifecycle
-- ----------------------------------------

function scene:enter()
  scene.super.enter(self)
  pushHandler(self.inputHandlers)
end

function scene:update(dt)
  clearScreen(CLEAR_COLOR)
  drawText("Transition Test Scene", 20, 20)
end

function scene:cleanup()
  scene.super.cleanup(self)
  popHandler()
  self.inputHandlers = nil
end
