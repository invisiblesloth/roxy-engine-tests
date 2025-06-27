-- source/scenes/TransitionIntegrationTest.lua

-- Integration-style checks for roxy.Transition (Cut/Fallback paths).

local pd <const> = playdate
local Graphics <const> = pd.graphics
local Scene <const> = roxy.Scene
local Transition <const> = roxy.Transition

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

-- Dummy-scene factory
local function makeScene(name)
  local scene = { name = name }
  function scene:enter() self._entered = true end

  function scene:pause() self._paused = true end

  function scene:update() end

  function scene:resume() self._resumed = true end

  function scene:exit() self._exited = true end

  function scene:cleanup() self._cleaned = true end

  return scene
end
local A, B, C = makeScene("A"), makeScene("B"), makeScene("C")
local AClass = function() return A end
local BClass = function() return B end
local CClass = function() return C end

-- ----------------------------------------
-- Class Definition & Init
-- ----------------------------------------

class("TransitionIntegrationTest").extends(RoxyScene)
local scene = TransitionIntegrationTest

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

function scene:cleanup()
  scene.super.cleanup(self)
end

-- ----------------------------------------
-- Integration Tests
-- ----------------------------------------

function scene:runTests()
  -- (1) replaceScene via Cut transition
  Transition.replaceScene(AClass, "Cut")
  expect(Scene.getCurrentScene() == A, "replaceScene(A) switches current")
  expect(A._entered, "A:enter() called")
  expect(not Transition.isTransitioning, "Transition finished instantly")

  -- (2) pushScene via Cut transition
  Transition.pushScene(BClass, "Cut")
  expect(Scene.getCurrentScene() == B, "pushScene(B) on top")
  expect(B._entered, "B:enter() called")
  expect(A._paused, "A:pause() called")

  -- (3) popScene via Cut transition
  Transition.popScene("Cut")
  expect(Scene.getCurrentScene() == A, "popScene() returns to A")
  expect(B._cleaned, "B:cleanup() called")
  expect(A._resumed, "A:resume() called")

  -- (4) Unknown transition name falls back to Cut
  Transition.replaceScene(CClass, "ThisDoesNotExist")
  expect(Scene.getCurrentScene() == C, "Unknown transition falls back to Cut")
  expect(C._entered, "C:enter() called")

  -- (5) FadeToBlack (animated) transition
  Transition.replaceScene(BClass, "FadeToBlack", 0.1, 0.05)
  expect(Transition.isTransitioning, "FadeToBlack starts transitioning")
  -- drive the sequencer until it ends
  while Transition.isTransitioning do
    roxy.Sequencer.update(0.1)
  end
  expect(Scene.getCurrentScene() == B, "FadeToBlack finishes and switches to B")
  expect(not Transition.isTransitioning, "FadeToBlack resets isTransitioning")

  -- (6) Default‐name fallback
  Transition.pushScene(CClass) -- no name → should default to Cut
  expect(Scene.getCurrentScene() == C, "pushScene() no name falls back to Cut")

  -- (7) popScene default‐name
  Transition.popScene()
  expect(Scene.getCurrentScene() == B, "popScene() no name --> Cut pop")

  -- (8a) loadTransitions rejects non-table
  local ok1 = not pcall(Transition.loadTransitions, "not a table")
  expect(ok1, "loadTransitions rejects non-table")

  -- (8b) loadTransitions rejects bad-key
  local ok2 = not pcall(Transition.loadTransitions, { [123] = RoxyCutTransition })
  expect(ok2, "loadTransitions rejects non-string key")

  -- (8c) loadTransitions rejects bad-value
  local ok3 = not pcall(Transition.loadTransitions, { Foo = "not a class" })
  expect(ok3, "loadTransitions rejects non-class value")

  -- (9) reentrancy guard
  Transition.replaceScene(AClass, "FadeToBlack", 0.2)
  Transition.popScene("FadeToBlack", 0.2)
  expect(Transition.isTransitioning, "Ignores second call while running")

  -- (10) Clean up and restore self so update() keeps drawing
  Scene.replaceRaw(self)

  -- DONE
  pruneLog()
  for _, line in ipairs(logLines) do print(line) end
  self.done = true
end
