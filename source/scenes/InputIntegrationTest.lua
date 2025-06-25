-- source/scenes/InputIntegrationTest.lua

local pd        <const> = playdate
local Graphics  <const> = pd.graphics
local Scene     <const> = roxy.Scene
local Input     <const> = roxy.Input

local max <const> = math.max
local min <const> = math.min

local insertTable <const> = table.insert
local removeTable <const> = table.remove

local clearScreen <const> = Graphics.clear
local drawText    <const> = Graphics.drawText

local COLOR_WHITE <const> = Graphics.kColorWhite
local CLEAR_COLOR <const> = COLOR_WHITE

-- ----------------------------------------
-- Helpers
-- ----------------------------------------

local logLines = {}

local function ok(msg)
  insertTable(logLines, "✔️ " .. msg)
end

local function fail(msg)
  insertTable(logLines, "❌ " .. msg)
end

local function expect(cond, msg)
  if cond then ok(msg) else fail(msg) end
end

local function pruneLog()
  if #logLines > 60 then removeTable(logLines, 1) end
end

-- ----------------------------------------
-- Class Definition & Init
-- ----------------------------------------

class("InputIntegrationTest").extends(RoxyScene)
local scene = InputIntegrationTest

function scene:init()
  scene.super.init(self)
  self.index     = 1
  self.done      = false
  self.testsRun  = false
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
  -- Start from a known‑good baseline
  Input.clearAllHandlers()
  expect(#Input.listHandlers() == 0, "Registry empty after clearAllHandlers()")

  -- (1) Handler add / replace / remove
  local H1 = { name = "H1", AButtonHold = function() end }
  Input.addHandler(H1, H1, 0)
  expect(#Input.listHandlers() == 1, "addHandler() registers handler")

  -- Replace same owner with new table & priority
  local H1b = { name = "H1b", BButtonHold = function() end }
  Input.addHandler(H1, H1b, 10)
  local reg = Input.listHandlers()[1]
  expect(#Input.listHandlers() == 1, "addHandler() replaces existing owner entry")
  expect(reg.tbl == H1b and reg.priority == 10, "Replacement updated table & priority")

  -- Add second handler with lower priority
  local H2 = { name = "H2", AButtonHold = function() end }
  Input.addHandler(H2, H2, 5)
  expect(#Input.listHandlers() == 2, "Second handler added correctly")

  -- Remove H1 owner
  Input.removeHandler(H1)
  expect(#Input.listHandlers() == 1 and Input.listHandlers()[1].owner == H2, "removeHandler() removed correct entry")

  -- (2) suspendAutoFlush / resumeAutoFlush
  Input.clearAllHandlers()
  Input.suspendAutoFlush()
  Input.addHandler(H1, H1, 0)
  Input.addHandler(H2, H2, 0)
  expect(#Input.listHandlers() == 2, "Handlers collected while auto‑flush suspended")
  Input.resumeAutoFlush() -- should flush without error
  expect(#Input.listHandlers() == 2, "resumeAutoFlush() kept registry intact & flushed")

  -- (3) makeModalHandler fills all keys
  local partial = { AButtonDown = function() end }
  local modal   = Input.makeModalHandler(partial)
  local expectedKeys = {
    "AButtonDown","AButtonHeld","AButtonUp","AButtonHold",
    "BButtonDown","BButtonHeld","BButtonUp","BButtonHold",
    "downButtonDown","downButtonUp","downButtonHold",
    "leftButtonDown","leftButtonUp","leftButtonHold",
    "rightButtonDown","rightButtonUp","rightButtonHold",
    "upButtonDown","upButtonUp","upButtonHold",
    "cranked","crankDocked","crankUndocked"
  }
  local allKeysFilled = true
  for _, k in ipairs(expectedKeys) do
    if modal[k] == nil then allKeysFilled = false break end
  end
  expect(allKeysFilled, "makeModalHandler() back‑fills missing callbacks")

  -- (4) Enable / disable flag
  Input.setIsEnabled(false)
  expect(Input.getIsEnabled() == false, "setIsEnabled(false) disables input")
  Input.setIsEnabled(true)
  expect(Input.getIsEnabled() == true, "setIsEnabled(true) re‑enables input")

  -- (5) Crank indicator controls
  Input.setCrankIndicatorStatus(true, true)
  local active, forced = Input.getCrankIndicatorStatus()
  expect(active and forced, "setCrankIndicatorStatus() updates state")
  Input.setCrankIndicatorStatus(false, false)
  active, forced = Input.getCrankIndicatorStatus()
  expect(not active and not forced, "Crank indicator can be disabled again")

  -- (6) Crank direction helpers
  Input.resetCrankDirection()
  local dir0 = Input.getCrankDirection()
  Input.setCrankDirection(-1)
  expect(Input.getCrankDirection() == -1, "setCrankDirection(-1) works")
  Input.setCrankDirection() -- toggle
  expect(Input.getCrankDirection() == 1, "setCrankDirection(nil) toggles direction")
  Input.resetCrankDirection()
  expect(Input.getCrankDirection() == dir0, "resetCrankDirection() restores default")

  -- (7) clearAllHandlers baseline restore
  Input.clearAllHandlers()
  expect(#Input.listHandlers() == 0, "clearAllHandlers() empties registry again")

  -- DONE
  pruneLog()
  for _, line in ipairs(logLines) do print(line) end
  self.done = true
end
