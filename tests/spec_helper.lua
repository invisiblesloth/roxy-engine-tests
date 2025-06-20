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
local graphics = {
  kColorBlack   = 0,
  kColorWhite   = 1,
  kDrawModeCopy = 0,
  clear         = stub.new(),
  setDrawOffset = stub.new(),
  sprite        = sprite,
}
_G.playdate = {
  graphics              = graphics,
  getSecondsSinceEpoch  = os.time,
}

-- --------------------------------------------------------
-- (2) Playdate-style `import` that also rewrites += and -=
-- --------------------------------------------------------

local function preprocess(src)
  -- Rewrite “foo += bar”  →  “foo = foo + (bar)”
  src = src:gsub("([%w_]+)%s*%+=%s*([^\n\r;]+)",
                 "%1 = %1 + (%2)")
  -- Rewrite “foo -= bar”  →  “foo = foo - (bar)”
  src = src:gsub("([%w_]+)%s*-=%s*([^\n\r;]+)",
                 "%1 = %1 - (%2)")
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

-- -----------------------------------------------
-- (3) Load the engine exactly like main.lua would
-- -----------------------------------------------

import "libraries/roxy/roxy" -- Brings in Scene, RoxyScene, etc.
