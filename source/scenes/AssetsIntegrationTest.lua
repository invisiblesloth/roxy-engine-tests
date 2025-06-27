-- source/scenes/AssetsIntegrationTest.lua

local pd <const> = playdate
local Graphics <const> = pd.graphics
local Assets <const> = roxy.Assets

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

class("AssetsIntegrationTest").extends(RoxyScene)
local scene = AssetsIntegrationTest

function scene:init()
  scene.super.init(self)
  self.done     = false
  self.testsRun = false
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
  -- (1) isPoolRegistered before and after register
  -------------------------------------------------
  expect(not Assets.getIsPoolRegistered("pool1"), "getIsPoolRegistered: false for unregistered")

  -- loader that returns sequential numbers
  local counter = 0
  local loader = function()
    counter += 1; return counter
  end

  local ok1 = Assets.registerPool("pool1", 2, loader)
  expect(ok1 == true, "registerPool: registers new pool successfully")
  expect(Assets.getIsPoolRegistered("pool1"), "getIsPoolRegistered: true after register")

  local okDup = Assets.registerPool("pool1", 1, loader)
  expect(okDup == false, "registerPool: false when registering duplicate pool")

  -------------------------------------------------
  -- (2) getAsset consumes initial assets
  -------------------------------------------------
  -- initialCount=2, loader called twice at register, assets {1,2}
  local a1 = Assets.getAsset("pool1")
  expect(a1 == 2, "getAsset: returns most recently loaded asset (2)")
  local a2 = Assets.getAsset("pool1")
  expect(a2 == 1, "getAsset: returns next asset (1)")

  -------------------------------------------------
  -- (3) getAsset grows pool when empty
  -------------------------------------------------
  -- pool.totalSize 2, maxSize default=4, growthFactor=1
  local a3 = Assets.getAsset("pool1")
  expect(a3 == 3, "getAsset: grows and returns new asset (3)")
  local a4 = Assets.getAsset("pool1")
  expect(a4 == 4, "getAsset: grows again up to maxSize and returns (4)")

  -------------------------------------------------
  -- (4) getAsset returns nil at max capacity
  -------------------------------------------------
  local a5 = Assets.getAsset("pool1")
  expect(a5 == nil, "getAsset: returns nil when pool empty and at max capacity")

  -------------------------------------------------
  -- (5) recycleAsset and reuse
  -------------------------------------------------
  local okRecFail = Assets.recycleAsset("poolX", {})
  expect(okRecFail == false, "recycleAsset: false for unregistered pool")
  local okRecNil = Assets.recycleAsset("pool1", nil)
  expect(okRecNil == false, "recycleAsset: false for nil asset")

  -- recycle a4 back into pool
  local okRec = Assets.recycleAsset("pool1", a4)
  expect(okRec == true, "recycleAsset: true for valid asset")
  local a6 = Assets.getAsset("pool1")
  expect(a6 == a4, "getAsset: returns recycled asset first")

  -------------------------------------------------
  -- (6) clear pools and loader failure handling
  -------------------------------------------------
  -- clear internal pools by reassigning a fresh module
  roxy.Cache = roxy.Cache or {}   -- ensure no conflict
  roxy.Assets = roxy.Assets or {} -- keep module table
  -- simulate loader that returns nil
  local loaderNil = function() return nil end
  local okReg2 = Assets.registerPool("pool2", 1, loaderNil)
  -- loader returns nil during registration, initialCount dumps to 0
  expect(okReg2 == true, "registerPool: still returns true even if loader returns nil")
  local aNil = Assets.getAsset("pool2")
  expect(aNil == nil, "getAsset: returns nil if loader fails when growing")

  -- DONE
  pruneLog()
  for _, line in ipairs(logLines) do print(line) end
  self.done = true
end
