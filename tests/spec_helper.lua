-- tests/spec_helper.lua

-- ----------------------------------------------------------
-- (0) Mini-OO system: Playdate’s CoreLibs/object replacement
-- ----------------------------------------------------------

function class(name)
  local cls   = {}
  cls.__index = cls
  _G[name]    = cls        -- global, like Playdate

  -- ---- root metatable with __call ----
  local function callCtor(self, ...)
    local instance = setmetatable({}, self)
    if instance.init then instance:init(...) end
    return instance
  end
  setmetatable(cls, { __call = callCtor })

  -- ---------- inheritance -------------
  function cls.extends(base)
    -- keep whatever metatable we already had (with __call) …
    local mt = getmetatable(cls) or {}
    mt.__call  = mt.__call or callCtor     -- ensure still callable
    -- and just add / overwrite __index for inheritance
    if base then
      mt.__index = base
      cls.super  = base
    else
      cls.super  = {}
    end
    setmetatable(cls, mt)
    return cls
  end

  return cls
end

-- ----------------------------------------
-- (1) Fake a subset of the Playdate SDK
-- ----------------------------------------

local stub = require 'luassert.stub'

local sprite = { redrawBackground = stub.new() }
local image  = { new = function() return {} end }

local graphics = {
  kColorBlack       = 0,
  kColorWhite       = 1,
  kDrawModeCopy     = 0,
  clear             = stub.new(),
  setDrawOffset     = stub.new(),
  sprite            = sprite,
  image             = image,
  pushContext       = function() end,
  popContext        = function() end,
  getImageDrawMode  = function() return 0 end,
  setImageDrawMode  = function() return 0 end,
}

local display = {
  getRefreshRate = function() return 30 end,
  getSize = function() return 400, 240 end,
}

_G.playdate = {
  graphics = graphics,
  display = display,
  getSecondsSinceEpoch = os.time,
}

-- --------------------------------------------------------
-- (2) Playdate-style `import` that also rewrites += and -=
-- --------------------------------------------------------

local function preprocess(src)

  -- helper that patches one operator at a time
  local function patch(op, repl)
    -- allow dotted names (`self.state`)
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
  patch("%^=", "^")   -- exponent, not XOR
  return src
end

local function import(path)
  local file = "source/" .. path:gsub("%.", "/") .. ".lua"
  local f = io.open(file, "r")
  if f then
    local src = f:read("*a"); f:close()
    src = preprocess(src)
    local chunk, err = load(src, "@" .. file)
    if not chunk then
      error(err, 2)
    end
    chunk()
  else
    -- CoreLibs/* and any other SDK-only files end up here; ignore.
  end
end
_G.import = import

-- ----------------------------------------
-- (3) Load the engine
-- ----------------------------------------

-- Provide a bare-bones roxy table that already contains the easing table
_G.roxy                 = _G.roxy or {}
_G.roxy.EasingFunctions = {}  -- must exist *now*
_G.roxy.EasingMap       = {}  -- optional, but keeps code happy

local noop = function() end
local names = {
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

for i, name in ipairs(names) do
  roxy.EasingFunctions[name]  = noop  -- placeholder C function
  roxy.EasingMap[name]        = i - 1 -- any dummy numeric code
end

-- 1)  A dummy Sequencer table because RoxySequence adds / removes itself
roxy.Sequencer = roxy.Sequencer or {}
roxy.Sequencer.add    = function() end
roxy.Sequencer.remove = function() end

-- 2)  Stub for the C class “RoxySequenceC”
local function makeDummyArray()
  local arr = {}

  --  tiny helpers that RoxySequence expects to call on the array…
  function arr:addEasing(...)      end
  function arr:from(...)           end
  function arr:to(...)             end
  function arr:set(...)            end
  function arr:again(...)          end
  function arr:reverse(...)        end
  function arr:sleep(...)          end
  function arr:setLoopType(...)    end
  function arr:reset()             end
  function arr:clear()             end

  -- value fetchers - keep the signature intact
  function arr:updateAndGetValue(_, dt)  -- oldTime, newTime, value, done
    return 0, dt or 0, 0, true
  end
  function arr:getTotalDuration()  return 0 end
  function arr:getEasingData(_, idx)        -- timestamp, from, to, dur
    return 0, 0, 0, 0
  end
  function arr:isDone()            return true end

  -- let “#array” return 0 so the high-level code thinks it’s empty
  return setmetatable(arr, { __len = function() return 0 end })
end

-- The “C constructor”
_G.RoxySequenceC = {
  new = function() return makeDummyArray() end
}

-- Import Roxy just like you would in main.lua
import "libraries/roxy/roxy"

-- now pull in all of the transition modules *through* import:
import "libraries/roxy/core/modules/Transition"
import "libraries/roxy/core/transitions/RoxyTransition"
import "libraries/roxy/core/transitions/RoxyCutTransition"
import "libraries/roxy/core/transitions/Cut"

-- expose the classes onto your roxy table so your specs can refer to them:
_G.roxy.RoxyTransition    = _G.RoxyTransition
_G.roxy.RoxyCutTransition = _G.RoxyCutTransition
_G.roxy.Cut               = _G.Cut
