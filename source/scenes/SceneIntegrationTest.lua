-- source/scenes/SceneIntegrationTest.lua

local pd <const> = playdate
local Graphics <const> = pd.graphics
local Scene <const> = roxy.Scene

local max <const> = math.max
local min <const> = math.min

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
  tableInsert(logLines, "✔️ " .. msg)
end

local function fail(msg)
  tableInsert(logLines, "❌ " .. msg)
end

local function expect(cond, msg)
  if cond then
    ok(msg)
  else
    fail(msg)
  end
end

local function pruneLog()
  if #logLines > 60 then
    tableRemove(logLines, 1)
  end
end

-- ----------------------------------------
-- Class Definition & Init
-- ----------------------------------------

class("SceneIntegrationTest").extends(RoxyScene)
local scene = SceneIntegrationTest

function scene:init()
  scene.super.init(self)

  self.index = 1
  self.done = false
  self.testsRun = false

  -- self.inputHandler = {}
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

function scene:update(dt)
  clearScreen(CLEAR_COLOR)

  -- Draw log
  local y = 10
  for i = self.index, min(#logLines, self.index + 17) do
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
  -- Simple dummy scenes
  local A = { name = "A" }
  function A:enter() self._entered = true end

  function A:pause() self._paused = true end

  function A:update() end

  function A:resume() self._resumed = true end

  function A:exit() self._exited = true end

  function A:cleanup() self._cleaned = true end

  local B = { name = "B" }
  function B:enter() self._entered = true end

  function B:pause() self._paused = true end

  function B:update() end

  function B:resume() self._resumed = true end

  function B:exit() self._exited = true end

  function B:cleanup() self._cleaned = true end

  local C = { name = "C" }
  function C:enter() self._entered = true end

  function C:update() end

  -- (1) Clear stack
  while Scene.getStackDepth() > 0 do
    Scene.popScene()
  end
  expect(Scene.getCurrentScene() == nil, "Stack empty at start")

  -- (2) replaceScene (invokes A:enter)
  Scene.replaceScene(A)
  expect(Scene.getCurrentScene() == A, "replaceScene(A) sets current scene")
  expect(A._entered, "A:enter() called")

  -- (3) pushScene(B)
  Scene.pushScene(B)
  expect(Scene.getCurrentScene() == B, "pushScene(B) pushed on top")
  expect(B._entered, "B:enter() called")
  expect(A._paused, "A:pause() called")

  -- (4) popScene()
  Scene.popScene()
  expect(Scene.getCurrentScene() == A, "popScene() returns to A")
  expect(B._cleaned, "B:cleanup() called")
  expect(A._resumed, "A:resume() called")

  -- (5) pushRaw(C) / popRaw()
  Scene.pushRaw(C)
  expect(Scene.getCurrentScene() == C, "pushRaw(C) pushes without old enter/exit")
  expect(C._entered == nil, "C:enter() NOT called on pushRaw")
  local popped = Scene.popRaw()
  expect(popped == C, "popRaw() returns popped table")
  expect(Scene.getCurrentScene() == A, "popRaw restores A")
  expect(C._cleaned == nil, "C:cleanup() NOT called on popRaw")

  -- (6) Stack depth & lists
  Scene.replaceScene(A)
  expect(Scene.getStackDepth() == 1, "stackDepth == 1 after replaceScene")
  Scene.pushScene(B)
  expect(Scene.getStackDepth() == 2, "stackDepth == 2 after pushScene")

  -- (7) Update/bg lists are always tables
  local ulist = Scene.getUpdateList()
  local blist = Scene.getBackgroundList()
  expect(type(ulist) == "table" and type(blist) == "table", "Update/bg lists are tables")

  -- (8) Clean up and restore self so update() keeps drawing
  Scene.replaceRaw(self)

  -- DONE
  pruneLog()
  for _, line in ipairs(logLines) do print(line) end
  self.done = true
end
