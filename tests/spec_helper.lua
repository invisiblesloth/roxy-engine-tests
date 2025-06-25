-- tests/spec_helper.lua

local function noop() end

local spy = require("luassert.spy")

-- ----------------------------------------
-- (0) Minimal Playdate-style OO system
-- ----------------------------------------

function class(name)
  local cls = {}
  cls.__index = cls
  _G[name] = cls

  local function callCtor(self, ...)
    local instance = setmetatable({}, self)
    if instance.init then instance:init(...) end
    return instance
  end
  setmetatable(cls, { __call = callCtor })

  function cls.extends(base)
    local mt = getmetatable(cls) or {}
    mt.__call = mt.__call or callCtor
    if base then
      mt.__index = base
      cls.super = base
    else
      cls.super = {}
    end
    setmetatable(cls, mt)
    return cls
  end

  return cls
end

-- ----------------------------------------
-- (1) Fake Playdate SDK
-- ----------------------------------------

local graphics = {
  kColorBlack         = 0,
  kColorWhite         = 1,
  kDrawModeCopy       = 0,
  setBackgroundColor  = noop,
  setColor            = spy.new(function() end),
  fillRect            = spy.new(function() end),
  drawText            = noop,
  clear               = noop,
  setDrawOffset       = noop,
  image               = { new = function() return {} end },
  pushContext         = noop,
  popContext          = noop,
  getImageDrawMode    = function() return 0 end,
  setImageDrawMode    = noop,
}

local sprite = {
  setBackgroundDrawing          = noop,
  setBackgroundDrawingCallback  = noop,
  redrawBackground              = noop,
}
graphics.sprite = sprite

local display = {
  getRefreshRate = function() return 30 end,
  getSize        = function() return 400, 240 end,
}

local ui = {
  crankIndicator = noop,
}

_G.playdate = {
  getButtonState        = noop,
  graphics              = graphics,
  sprite                = sprite,
  display               = display,
  ui                    = ui,
  getSecondsSinceEpoch  = os.time,
  inputHandlers = {
    push = noop,
    pop  = noop,
  }
}

-- ----------------------------------------
-- (2) Playdate-style import (handles += etc.)
-- ----------------------------------------

local function preprocess(src)
  local function patch(op, repl)
    src = src:gsub("([%w_%.]+)%s*" .. op .. "%s*([^\n\r;]+)",
                   "%1 = %1 " .. repl .. " (%2)")
  end
  patch("%+=", "+")
  patch("%-=", "-")
  patch("%*=", "*")
  patch("/=",  "/")
  patch("//=", "//")
  patch("%%=", "%%")
  patch("<<=", "<<")
  patch(">>=", ">>")
  patch("&=", "&")
  patch("%|=", "|")
  patch("%^=", "^")
  return src
end

local function import(path)
  local file = "source/" .. path:gsub("%.", "/") .. ".lua"
  local f = io.open(file, "r")
  if f then
    local src = f:read("*a"); f:close()
    src = preprocess(src)
    local chunk, err = load(src, "@" .. file)
    if not chunk then error(err, 2) end
    chunk()
  end
end
_G.import = import

-- ----------------------------------------
-- (3) Minimal stubs for Roxy and engine dependencies
-- ----------------------------------------

_G.roxy = _G.roxy or {}

-- Input
_G.__testProcessMask  = 0
_G.__testButtonState  = 0

-- make wrappers that read the globals above
local function processAllButtonsWrapper() return __testProcessMask  end
local function getButtonStateWrapper()    return __testButtonState  end

-- expose so Input.lua captures them
_G.roxy.Input = _G.roxy.Input or {}
_G.roxy.Input.processAllButtons = processAllButtonsWrapper
_G.roxy.Input.setButtonHoldBufferAmount = noop
_G.roxy.Input.flushButtonQueue = noop
_G.playdate.getButtonState = getButtonStateWrapper

-- Easing
_G.roxy.EasingFunctions = {}
_G.roxy.EasingMap = {}

-- Populate easing names
local easingNames = {
  "flat","linear",
  "inQuad","outQuad","inOutQuad","outInQuad",
  "inCubic","outCubic","inOutCubic","outInCubic",
  "inQuart","outQuart","inOutQuart","outInQuart",
  "inQuint","outQuint","inOutQuint","outInQuint",
  "inSine","outSine","inOutSine","outInSine",
  "inExpo","outExpo","inOutExpo","outInExpo",
  "inCirc","outCirc","inOutCirc","outInCirc",
  "inElastic","outElastic","inOutElastic","outInElastic",
  "inBack","outBack","inOutBack","outInBack",
  "outBounce","inBounce","inOutBounce","outInBounce",
}
for i, name in ipairs(easingNames) do
  roxy.EasingFunctions[name] = noop
  roxy.EasingMap[name] = i - 1
end

-- Sequencer
_G.roxy.Sequencer = roxy.Sequencer or {}
_G.roxy.Sequencer.add     = noop
_G.roxy.Sequencer.remove  = noop

-- C-side dummy RoxySequenceC
local function makeDummyArray()
  local arr = {}
  function arr:addEasing(...) end
  function arr:from(...) end
  function arr:to(...) end
  function arr:set(...) end
  function arr:again(...) end
  function arr:reverse(...) end
  function arr:sleep(...) end
  function arr:setLoopType(...) end
  function arr:reset(...) end
  function arr:clear(...) end
  function arr:updateAndGetValue(_, dt) return 0, dt or 0, 0, true end
  function arr:getTotalDuration() return 0 end
  function arr:getEasingData(_, idx) return 0, 0, 0, 0 end
  function arr:isDone() return true end
  return setmetatable(arr, { __len = function() return 0 end })
end

_G.RoxySequenceC = { new = function() return makeDummyArray() end }

-- ----------------------------------------
-- (4) Load the engine
-- ----------------------------------------

import "libraries/roxy/roxy"
import "libraries/roxy/core/modules/Transition"
import "libraries/roxy/core/transitions/RoxyTransition"
import "libraries/roxy/core/transitions/RoxyCutTransition"
import "libraries/roxy/core/transitions/Cut"
import "core.scenes.RoxyScene"

-- Expose classes
roxy.RoxyTransition    = _G.RoxyTransition
roxy.RoxyCutTransition = _G.RoxyCutTransition
roxy.Cut               = _G.Cut
