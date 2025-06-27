-- source/scenes/CacheIntegrationTest.lua

local pd <const> = playdate
local Graphics <const> = pd.graphics
local Cache <const> = roxy.Cache

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

class("CacheIntegrationTest").extends(RoxyScene)
local scene = CacheIntegrationTest

function scene:init()
  scene.super.init(self)
  self.testsRun = false
  self.done     = false
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
  -------------------------------------------------
  -- (1) newBucket default and custom
  -------------------------------------------------
  local b1 = Cache.newBucket()
  expect(b1.maxCacheSize == 50, "newBucket: default maxCacheSize is 50")
  local b2 = Cache.newBucket(2)
  expect(b2.maxCacheSize == 2, "newBucket: custom maxCacheSize")

  -------------------------------------------------
  -- (2) setMaxCacheSize and eviction
  -------------------------------------------------
  Cache.setMaxCacheSize(b2, 1)
  expect(b2.maxCacheSize == 1, "setMaxCacheSize: sets custom max")
  Cache.clearCache(b2)
  Cache.cacheAsset(b2, "k1", function() return "v1" end)
  Cache.cacheAsset(b2, "k2", function() return "v2" end)
  expect(not Cache.getIsAssetCached(b2, "k1") and Cache.getIsAssetCached(b2, "k2"),
    "cacheAsset: evicts LRU when over max")

  -------------------------------------------------
  -- (3) cacheAsset & getCachedAsset on default bucket
  -------------------------------------------------
  Cache.clearCache()
  local ok1 = Cache.cacheAsset("keyA", function() return "assetA" end)
  expect(ok1 == true, "cacheAsset: caches new asset on default bucket")
  expect(Cache.getIsAssetCached("keyA"), "getIsAssetCached: true after cacheAsset")
  local gotA = Cache.getCachedAsset("keyA")
  expect(gotA == "assetA", "getCachedAsset: returns correct asset")

  -------------------------------------------------
  -- (4) getOrLoadAsset behavior
  -------------------------------------------------
  Cache.clearCache()
  local val = Cache.getOrLoadAsset("kX", function() return 123 end)
  expect(val == 123, "getOrLoadAsset: loads and returns new asset")
  expect(Cache.getIsAssetCached("kX"), "getOrLoadAsset: caches new asset")
  local val2 = Cache.getOrLoadAsset("kX", function() error("should not load again") end)
  expect(val2 == 123, "getOrLoadAsset: returns cached asset without reloading")

  -------------------------------------------------
  -- (5) getCachedAsset on missing
  -------------------------------------------------
  local missing = Cache.getCachedAsset("noKey")
  expect(missing == nil, "getCachedAsset: nil for missing key")

  -------------------------------------------------
  -- (6) evictAsset removes and handles non-existent
  -------------------------------------------------
  Cache.clearCache()
  Cache.cacheAsset("kY", function() return "yy" end)
  expect(Cache.getIsAssetCached("kY"), "cacheAsset: caches kY")
  local e1 = Cache.evictAsset("kY")
  expect(e1 == true, "evictAsset: removes existing key")
  expect(not Cache.getIsAssetCached("kY"), "getIsAssetCached: false after eviction")
  local e2 = Cache.evictAsset("kY")
  expect(e2 == false, "evictAsset: returns false when key missing")

  -------------------------------------------------
  -- (7) clearCache empties
  -------------------------------------------------
  Cache.clearCache()
  Cache.cacheAsset("kA", function() return "a" end)
  Cache.cacheAsset("kB", function() return "b" end)
  Cache.clearCache()
  expect(not Cache.getIsAssetCached("kA") and not Cache.getIsAssetCached("kB"),
    "clearCache: empties all entries")

  -- DONE
  pruneLog()
  for _, line in ipairs(logLines) do print(line) end
  self.done = true
end
