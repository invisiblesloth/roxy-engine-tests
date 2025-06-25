-- tests/input/input_spec.lua

dofile("tests/spec_helper.lua")

local stub = require("luassert.stub")

-- Load the Input module (adds roxy.Input)
import "libraries/roxy/core/modules/Input"

local Input    <const> = roxy.Input
local playdate <const> = _G.playdate

local function patch_upvalue(fn, upvalue_name, new_value)
  local i = 1
  while true do
    local name = debug.getupvalue(fn, i)
    if not name then break end
    if name == upvalue_name then
      debug.setupvalue(fn, i, new_value)
      return true
    end
    i = i + 1
  end
  return false
end

local function fakeProcessAllButtons() return __testProcessMask end

-- ----------------------------------------
-- Test Suite
-- ----------------------------------------

describe("roxy.Input", function()
  -- Test‑level shared vars
  local pushStub, popStub, getStateStub

  before_each(function()
    __testProcessMask  = 0      -- reset mask for buttons
    __testButtonState  = 0      -- reset button state
    Input._blocked     = false
    Input.setIsEnabled(true)
    Input.clearAllHandlers()
  
    -- Optionally stub Playdate SDK hooks (for push/pop coverage)
    pushStub = stub(playdate.inputHandlers, "push")
    popStub  = stub(playdate.inputHandlers, "pop")
    getStateStub = stub(playdate, "getButtonState"):invokes(function()
      return __testButtonState
    end)
    
    roxy.Input.processAllButtons = fakeProcessAllButtons
    Input.processAllButtons      = fakeProcessAllButtons
    assert(patch_upvalue(Input.handleInput, "processAllButtons", fakeProcessAllButtons))
  end)

  after_each(function()
    pushStub:revert()
    popStub:revert()
    getStateStub:revert()
  end)

  -------------------------------------------------------------------
  -- (1) handler registration
  -------------------------------------------------------------------
  it("addHandler registers, replaces, and removes correctly", function()
    local h1 = { name = "h1" }
    local h2 = { name = "h2" }

    Input.addHandler(h1, h1, 0)
    assert.equal(1, #Input.listHandlers())

    Input.addHandler(h1, h2, 5)
    local entry = Input.listHandlers()[1]
    assert.equal(1, #Input.listHandlers())
    assert.equals(h1, entry.owner)
    assert.equals(h2, entry.tbl)
    assert.equals(5,  entry.priority)

    Input.removeHandler(h1)
    assert.equal(0, #Input.listHandlers())
  end)

  -------------------------------------------------------------------
  -- (2) makeModalHandler fills all keys
  -------------------------------------------------------------------
  it("makeModalHandler back‑fills all supported callbacks", function()
    local modal = Input.makeModalHandler({ AButtonDown = function() end })
    local expectedKeys = {
      "AButtonDown","AButtonHeld","AButtonUp","AButtonHold",
      "BButtonDown","BButtonHeld","BButtonUp","BButtonHold",
      "downButtonDown","downButtonUp","downButtonHold",
      "leftButtonDown","leftButtonUp","leftButtonHold",
      "rightButtonDown","rightButtonUp","rightButtonHold",
      "upButtonDown","upButtonUp","upButtonHold",
      "cranked","crankDocked","crankUndocked"
    }
    for _, k in ipairs(expectedKeys) do
      assert.is_function(modal[k])
    end
  end)

  -------------------------------------------------------------------
  -- (3) handleInput dispatch path
  -------------------------------------------------------------------
  it("handleInput dispatches hold callbacks when enabled", function()
    local fired = 0
    local handler = { AButtonHold = function() fired = fired + 1 end }
    Input.addHandler(handler, handler, 0)
    __testProcessMask = 0x01 -- simulate A-button held (is this the right bit in your engine?)
    Input.handleInput()
    assert.equals(1, fired)
  end)
  
  -------------------------------------------------------------------
  -- (4) blockUntilClear gating
  -------------------------------------------------------------------
  it("blockUntilClear holds input until buttons released", function()
    local fired = 0
    local handler = {
      AButtonHold = function() fired = fired + 1 end
    }
    Input.addHandler(handler, handler, 0)
  
    Input.blockUntilClear()
    __testButtonState  = 1     -- buttons still down
    __testProcessMask  = 0x01  -- would fire, but should be gated
    Input.handleInput()
    assert.equals(0, fired)
  
    __testButtonState  = 0
    __testProcessMask  = 0      -- nothing held during the unblock call
    Input.handleInput()         -- gate lifted
    
    __testProcessMask  = 0x01   -- A-button held
    Input.handleInput()         -- single dispatch
    assert.equals(1, fired)
  end)

  -------------------------------------------------------------------
  -- (5) crank indicator helpers
  -------------------------------------------------------------------
  it("crank indicator status helpers round‑trip", function()
    Input.setCrankIndicatorStatus(true, true)
    local active, forced = Input.getCrankIndicatorStatus()
    assert.is_true(active)
    assert.is_true(forced)

    Input.setCrankIndicatorStatus(false, false)
    active, forced = Input.getCrankIndicatorStatus()
    assert.is_false(active)
    assert.is_false(forced)
  end)
end)
