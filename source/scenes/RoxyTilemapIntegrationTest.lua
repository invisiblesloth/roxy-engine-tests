-- source/scenes/RoxyTilemapIntegrationTest.lua

local pd         <const> = playdate
local Graphics   <const> = pd.graphics
local Sprite     <const> = Graphics.sprite

local Cache      <const> = roxy.Cache
local Camera     <const> = roxy.Camera
local JSON       <const> = roxy.JSON

local tableInsert <const> = table.insert

local clearScreen <const> = Graphics.clear
local drawText    <const> = Graphics.drawText

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

class("RoxyTilemapIntegrationTest").extends(RoxyScene)
local scene = RoxyTilemapIntegrationTest

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

function scene:update(dt)
  clearScreen(CLEAR_COLOR)
  local y = 10
  for i = 1, math.min(#logLines, 18) do
    drawText(logLines[i], 10, y)
    y = y + 12
  end
  if self.done then drawText("*DONE*", 10, 220) end
end

-- ----------------------------------------
-- Run Tests
-- ----------------------------------------

function scene:runTests()
    -- Clear cache and reset camera
    Cache.clearCache()
    Camera.reset()

    -- Create tilemap
    local tm = RoxyTilemap("assets/maps/dummy.json", { cameraBounds = true }, self)
    -- Restore JSON loader
    JSON.loadJson = origLoad

    -- Test world size
    local w,h = tm:getWorldSize()
    expect(w == 2 * 16 and h == 2 * 16, "getWorldSize returns correct size")

    -- Test getTileAt
    expect(tm:getTileAt("layer1", 1, 1) == 1,   "getTileAt returns correct tile at (1,1)")
    expect(tm:getTileAt("layer1", 2, 1) == nil, "getTileAt returns nil at (2,1) because tile is empty")
    expect(tm:getTileAt("layer1", 1, 2) == 2,   "getTileAt returns correct tile at (1,2)")
    expect(tm:getTileAt("layer1", 2, 2) == nil, "getTileAt returns nil at (2,2) because tile is empty")

    -- Test setTileAt without sprite update
    tm:setTileAt("layer1", 1, 2, 5, false)
    expect(tm:getTileAt("layer1", 1, 2) == 5, "setTileAt updates tile when updateSprite=false")

    -- Test setTileAt with sprite update calls addDirtyRect
    Camera.setPosition(0, 0)
    local called = false
    local origAdd = Sprite.addDirtyRect
    Sprite.addDirtyRect = function(x,y,w,h) called = true end
    tm:setTileAt("layer1", 2, 2, 7, true)
    local okUpdate = pcall(function()
        tm:setTileAt("layer1", 2, 2, 7, true)
    end)
    expect(okUpdate, "setTileAt with updateSprite=true runs without error")
    Sprite.addDirtyRect = origAdd

    -- Test forEachTile
    local list = {}
    tm:forEachTile("layer1", function(x,y,id) table.insert(list, {x,y,id}) end)
    expect(#list == 4, "forEachTile iterates all tiles")

    -- Test getObjects
    local objs = tm:getObjects("obj1")
    expect(objs and #objs == 1, "getObjects returns object layer entries")

    -- Test camera bounds applied
    local b = Camera.getBounds()
    expect(b and b.x1 == 0 and b.y1 == 0, "cameraBounds set when requested")

    -- Test sprite visibility and hide/show
    local spr = tm:getSprite("layer1")
    expect(spr ~= nil, "getSprite returns sprite for layer1")
    expect(spr:isVisible(), "sprite initially visible")
    tm:hideLayer("layer1")
    expect(not spr:isVisible(), "hideLayer hides sprite")
    tm:showLayer("layer1")
    expect(spr:isVisible(), "showLayer shows sprite")

    -- Test removeLayer
    tm:removeLayer("layer1")
    expect(tm:getTilemap("layer1") == nil, "removeLayer removes tilemap")
    expect(tm:getSprite("layer1") == nil, "removeLayer removes sprite")

    -- Test destroy
    tm:destroy()
    expect(next(tm.layers) == nil, "destroy clears layers")
    expect(tm.tilesets == nil, "destroy clears tilesets")

    -- Done
    pruneLog()
    for _,line in ipairs(logLines) do print(line) end
    self.done = true
end
