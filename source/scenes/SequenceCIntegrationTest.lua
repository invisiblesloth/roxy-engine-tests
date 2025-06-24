-- source/scenes/SequenceCIntegrationTest.lua

-- Integration-style checks that exercise the real C implementation of
-- RoxySequenceC inside the Playdate runtime.

local pd        <const> = playdate
local Graphics  <const> = pd.graphics

local max <const> = math.max
local min <const> = math.min

local tableInsert <const> = table.insert
local tableRemove <const> = table.remove

local pushHandler <const> = pd.inputHandlers.push
local popHandler  <const> = pd.inputHandlers.pop

local clearScreen <const> = Graphics.clear
local drawText    <const> = Graphics.drawText

local replaceScene  <const> = roxy.Transition.replaceScene

local COLOR_WHITE <const> = Graphics.kColorWhite
local CLEAR_COLOR <const> = COLOR_WHITE

-- ----------------------------------------
-- Helpers
-- ----------------------------------------

local logLines  = {}

local function ok(msg)
  tableInsert(logLines, "✔️ "..msg)
end

local function fail(msg)
  tableInsert(logLines, "❌ "..msg)
end

local function expect(cond, msg)
  if cond then
    ok(msg) else fail(msg)
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

class("SequenceCIntegrationTest").extends(RoxyScene)
local scene = SequenceCIntegrationTest

function scene:init()
    scene.super.init(self)
    self.index = 1 -- Which visual line to show at top
    self.done = false
    self.testsRun = false -- Run once in enter()

    -- self.inputHandler = {}
end

-- ----------------------------------------
-- Scene Lifecycle
-- ----------------------------------------

function scene:enter()
  scene.super.enter(self)
  -- pushHandler(self.inputHandler)

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
    -- popHandler()
    -- self.inputHandler = nil
end

-- ----------------------------------------
-- Integration Tests
-- ----------------------------------------

function scene:runTests()
  local sequence = RoxySequenceC.new()

  -- From
  sequence:from(0)
  expect(#sequence == 1, "from() adds 1st segment")

  -- TimeStamp, from, to, duration
  local timeStamp, fr, to = sequence:getEasingData(1)
  expect(timeStamp == 0 and fr == 0 and to == 0, "Initial segment values")

  -- To
  sequence:to(10, 1)
  expect(#sequence == 2, "to() appends 2nd segment")
  expect(math.abs(sequence:getTotalDuration()-1) < 0.0001, "totalDuration updated")

  -- Set
  local durationBefore = sequence:getTotalDuration()
  sequence:set(20)
  expect(#sequence == 3, "set() adds instantaneous seg")
  expect(sequence:getTotalDuration() == durationBefore, "set() keeps totalDuration")

  -- Sleep
  sequence:sleep(0.5)
  expect(#sequence == 4, "sleep() added")
  expect(math.abs(sequence:getTotalDuration() - (durationBefore + 0.5)) < 0.0001, "Sleep extends totalDuration")

  -- Update / Value
  local _, newTime, currentValue = sequence:updateAndGetValue(0.5)
  expect(newTime > 0, "updateAndGetValue advances time")
  expect(currentValue ~= nil, "updateAndGetValue returns value")

  -- Loop
  sequence:setLoopType(1, 0) -- normal infinite
  sequence:updateAndGetValue(sequence:getTotalDuration() + 0.2)
  expect(sequence:getCurrentTime() < sequence:getTotalDuration(), "Normal loop wraps time")

  -- Again
  local segmentCount = #sequence
  sequence:again(2)
  expect(#sequence == segmentCount + 2, "again(2) duplicates segments")

  -- Reverse
  sequence:reverse(true)
  expect(#sequence == segmentCount + 3, "reverse(true) appends reversed seg")

  -- Clear
  sequence:clear()
  expect(#sequence == 0 and sequence:getTotalDuration()==0, "clear() wipes segments")

  -- Reset
  sequence:from(0):to(5, 1)
  sequence:updateAndGetValue(0.5)
  sequence:reset()
  expect(sequence:getCurrentTime() == 0, "reset() rewinds time")

  -- Summary
  pruneLog()
  for _, line in ipairs(logLines) do print(line) end
  self.done = true
end
