-- source/scenes/CameraIntegrationTest.lua

local pd <const> = playdate
local Graphics <const> = pd.graphics
local Camera <const> = roxy.Camera

local tableInsert <const> = table.insert
local tableRemove <const> = table.remove

local clearScreen <const> = Graphics.clear
local drawText <const> = Graphics.drawText

local COLOR_WHITE <const> = Graphics.kColorWhite
local CLEAR_COLOR <const> = COLOR_WHITE

-- ----------------------------------------
-- Helpers
-- ----------------------------------------

local logLines = {}

local function ok(msg)
  table.insert(logLines, "✔️ " .. msg)
end

local function fail(msg)
  table.insert(logLines, "❌ " .. msg)
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
-- Scene Definition
-- ----------------------------------------

class("CameraIntegrationTest").extends(RoxyScene)
local scene = CameraIntegrationTest

function scene:init()
  scene.super.init(self)
  self.testsRun = false
  self.done     = false
end

function scene:enter()
  scene.super.enter(self)
  if not self.testsRun then
    self:runTests(); self.testsRun = true
  end
end

function scene:update(dt)
  clearScreen(CLEAR_COLOR)
  local y = 10
  for i = 1, math.min(#logLines, 18) do
    drawText(logLines[i], 10, y)
    y += 12
  end
  if self.done then drawText("*DONE*", 10, 220) end
end

-- ----------------------------------------
-- Run all tests
-- ----------------------------------------

function scene:runTests()
  -- (1) reset and defaults
  Camera.reset()
  local x, y = Camera.getPosition()
  expect(x == 0 and y == 0, "reset: position reset to (0,0)")
  expect(Camera.getBounds() == nil, "getBounds: no bounds after reset")
  local dx, dy = Camera.getDrawOffset()
  expect(dx == 0 and dy == 0, "getDrawOffset: (0,0) initially")

  -- (2) setPosition & static update
  Camera.setPosition(15, 25)
  Camera.updateStatic(0)
  x, y = Camera.getPosition()
  expect(x == 15 and y == 25, "setPosition: camera at (15,25)")
  dx, dy = Camera.getDrawOffset()
  expect(dx == -15 and dy == -25, "static: drawOffset matches position")

  -- (3) manual pan velocity
  Camera.reset()
  Camera.setPanVelocity(50, 0)
  Camera.updateManualPan(1)
  x, y = Camera.getPosition()
  expect(x == 50 and y == 0, "manualPan: moved 50px in x after dt=1")
  -- no panning input, position remains
  Camera.setPanVelocity(0, 0)
  Camera.updateManualPan(1)
  local x2, _ = Camera.getPosition()
  expect(x2 == 50, "manualPan: stays at 50px when panning stops")

  -- (4) follow target with bounds
  Camera.reset()
  -- dummy sprite at (100,80)
  local sprite = { getPosition = function() return 100, 80 end }
  Camera.setBounds({ x1 = 0, y1 = 0, x2 = 50, y2 = 50 })
  Camera.setTarget(sprite)
  Camera.setSmoothing(0)
  Camera.updateFollow(0)
  x, y = Camera.getPosition()
  expect(x >= 0 and x <= 50 and y >= 0 and y <= 50, "follow: obeys bounds when snapping")

  -- (5) dead zone prevents small movements around center
  Camera.reset()
  Camera.setTarget(sprite)
  Camera.setDeadZone(40, 40)
  -- sprite in center of screen => no move
  local CENTER_X = roxy.Graphics.displayWidthCenter
  local CENTER_Y = roxy.Graphics.displayHeightCenter
  ---@diagnostic disable: duplicate-set-field
  sprite.getPosition = function() return CENTER_X, CENTER_Y end
  Camera.updateFollow(0)
  local x0, y0 = Camera.getPosition()
  expect(x0 == 0 and y0 == 0, "deadZone: no move when sprite in dead zone center")
  -- move sprite outside zone
  sprite.getPosition = function() return CENTER_X + 30, CENTER_Y + 30 end
  Camera.updateFollow(0)
  x, y = Camera.getPosition()
  expect(x ~= 0 or y ~= 0, "deadZone: moves when sprite exits dead zone")

  -- (6) shake effect keeps camera active and resets
  Camera.reset()
  Camera.shake(10, 0.2, 2)
  expect(Camera._isActive, "shake: camera active when shaking")
  Camera.updateStatic(0.1)
  expect(Camera._isActive, "shake: remains active mid-shake")
  Camera.updateStatic(0.2)
  expect(not Camera._isActive, "shake: inactive after shake ends")

  -- (7) clear bounds
  Camera.setBounds({ x1 = 0, y1 = 0, x2 = 10, y2 = 10 })
  Camera.clearBounds()
  expect(Camera.getBounds() == nil, "clearBounds: no bounds after clear")

  -- DONE
  pruneLog()
  for _, line in ipairs(logLines) do print(line) end
  self.done = true
end
