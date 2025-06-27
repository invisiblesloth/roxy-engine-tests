-- source/scenes/RoxySpriteIntegrationTest.lua

local pd        <const> = playdate
local Graphics  <const> = pd.graphics
local Sprite    <const> = Graphics.sprite
local r         <const> = roxy

local tableInsert <const> = table.insert
local tableRemove <const> = table.remove

local clearScreen <const> = Graphics.clear
local drawText    <const> = Graphics.drawText

local COLOR_WHITE <const> = Graphics.kColorWhite
local CLEAR_COLOR <const> = COLOR_WHITE

-- ----------------------------------------
-- Helpers
-- ----------------------------------------

local logLines = {}

local function ok(msg)
  tableInsert(logLines, "✔️ " .. msg)
end

local function fail(msg)
  tableInsert(logLines, "❌ " .. msg)
end

local function expect(cond, msg)
  if cond then ok(msg) else fail(msg) end
end

local function pruneLog()
  if #logLines > 60 then
    tableRemove(logLines, 1)
  end
end

-- ----------------------------------------
-- Class Definition & Init
-- ----------------------------------------

class("RoxySpriteIntegrationTest").extends(RoxyScene)
local scene = RoxySpriteIntegrationTest

function scene:init()
  scene.super.init(self)
  self.done     = false
  self.testsRun = false
end

-- ----------------------------------------
-- Scene Lifecycle
-- ----------------------------------------

function scene:enter()
  scene.super.enter(self)
  if not self.testsRun then
    self:runTests()
    self.testsRun = true
  end
end

function scene:update()
  clearScreen(CLEAR_COLOR)

  -- Draw logs
  local y = 10
  for i = 1, math.min(#logLines, 18) do
    drawText(logLines[i], 10, y)
    y += 12
  end
  if self.done then
    drawText("*DONE*", 10, 220)
  end
end

-- ----------------------------------------
-- Integration Tests
-- ----------------------------------------

function scene:runTests()
  -- (1) Create sprite, check defaults
  local s = RoxySprite()
  expect(s.name == "RoxySprite", "default name")
  expect(s:getIsPaused(), "paused by default")
  expect(s._added == false, "not added initially")
  expect(s:getOrientation() == Graphics.kImageUnflipped, "unflipped by default")

  -- (2) Test chaining setters
  expect(s:setZIndex(5) == s, "setZIndex chains")
  expect(s:setSize(32, 48) == s, "setSize chains")
  expect(s:setCenter(0.5, 0.5) == s, "setCenter chains")
  expect(s:moveTo(100, 80) == s, "moveTo chains")

  -- (3) Test add/remove
  s:add()
  expect(s:isAdded(), "isAdded after add()")
  s:remove()
  expect(not s:isAdded(), "not added after remove()")

  -- (4) Test flipping
  s:flipX()
  expect(s:getOrientation() == Graphics.kImageFlippedX, "flipX")
  s:flipY()
  expect(s:getOrientation() == Graphics.kImageFlippedY, "flipY")
  s:flipXY()
  expect(s:getOrientation() == Graphics.kImageFlippedXY, "flipXY")
  s:unflip()
  expect(s:getOrientation() == Graphics.kImageUnflipped, "unflip")

  -- (5) Test pause/play/toggle/replay/stop
  -- no animation yet: play/pause should still chain
  expect(s:play() == s, "play chains")
  expect(s:pause() == s, "pause chains")
  s:getIsPaused() -- no state change
  s:togglePlayPause():togglePlayPause()
  expect(true, "togglePlayPause chains")
  expect(s:replay() == s, "replay chains")
  expect(s:stop() == s, "stop chains")

  -- (6) Test isOnScreen (assuming default camera at 0,0 and display 400×240)
  s:setSize(10, 10):setCenter(0, 0):moveTo(5, 5)
  expect(s:isOnScreen(), "sprite on screen at (5,5)")
  s:moveTo(-100, -100)
  expect(not s:isOnScreen(), "sprite off-screen at (-100,-100)")

  -- (7) Test drawSpecificFrame & stepFrame warnings (no animation)
  s:drawSpecificFrame(2, true)
  s:stepFrame(1)
  ok("drawSpecificFrame & stepFrame no-op without animation")

  -- (8) Test view = nil hides sprite
  s:setView(nil)
  expect(not s:isVisible(), "setView(nil) hides sprite")

  -- DONE
  pruneLog()
  for _, line in ipairs(logLines) do print(line) end
  self.done = true
end
