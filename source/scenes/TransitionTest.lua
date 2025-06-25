-- source/scenes/TransitionTest.lua

local pd        <const> = playdate
local Graphics  <const> = pd.graphics

local pushHandler <const> = pd.inputHandlers.push
local popHandler  <const> = pd.inputHandlers.pop

local setImageDrawMode  <const> = Graphics.setImageDrawMode
local drawText          <const> = Graphics.drawText

local replaceScene <const> = roxy.Transition.replaceScene

local COLOR_WHITE <const> = Graphics.kColorWhite
local COLOR_BLACK <const> = Graphics.kColorBlack
local CLEAR_COLOR <const> = COLOR_BLACK

local DRAW_MODE_COPY  <const> = Graphics.kDrawModeCopy
local DRAW_FILL_WHITE <const> = Graphics.kDrawModeFillWhite

-- ----------------------------------------
-- ! Class Definition & Init
-- ----------------------------------------

class("TransitionTest").extends(RoxyScene)
local scene = TransitionTest

function scene:init()
  scene.super.init(self, COLOR_BLACK)

  self.inputHandler = {
    AButtonDown = function()
      print("Transition Test → Scene Test")
      replaceScene(SceneTest, "FadeToBlack")
    end
  }
end

-- ----------------------------------------
-- ! Scene Lifecycle
-- ----------------------------------------

function scene:enter()
  scene.super.enter(self)
  setImageDrawMode(DRAW_FILL_WHITE)
end

function scene:update(dt)
  drawText("Transition Test Scene", 20, 20)
end

function scene:cleanup()
  scene.super.cleanup(self)
  self.inputHandlers = nil
  setImageDrawMode(DRAW_MODE_COPY)
end
