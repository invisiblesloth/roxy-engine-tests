-- source/scenes/RoxyParticlesIntegrationTest.lua

local pd        <const> = playdate
local Graphics  <const> = pd.graphics
local r         <const> = roxy

local tableInsert <const> = table.insert
local tableRemove <const> = table.remove

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

class("RoxyParticlesIntegrationTest").extends(RoxyScene)
local scene = RoxyParticlesIntegrationTest

function scene:init()
    scene.super.init(self)
    self.testsRun = false
    self.done = false
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
    -- (1) init defaults
    local p = RoxyParticles(100,100,{maxCount=5})
    expect(p.opts.maxCount==5, "init: maxCount set from opts")
    expect(#p.pool==5, "init: pool length equals maxCount")
    local alive=0
    for _,v in ipairs(p.pool) do if v.alive then alive=alive+1 end end
    expect(alive==0, "init: no particles alive initially")

    -- (2) spawn until full
    local success=true local n=0
    while success do
        success = p:spawn()
        if success then n+=1 end
    end
    expect(n==5, "spawn: can spawn maxCount particles")
    expect(p:spawn()==false, "spawn: returns false once pool exhausted")

    -- (3) clear
    p:clear()
    alive=0
    for _,v in ipairs(p.pool) do if v.alive then alive=alive+1 end end
    expect(alive==0, "clear: all particles dead after clear")
    expect(p.accumulator==0, "clear: accumulator reset")

    -- (4) emit(count)
    p:clear()
    p:emit(3)
    alive=0
    for _,v in ipairs(p.pool) do if v.alive then alive=alive+1 end end
    expect(alive==3, "emit: spawns specified count")

    -- (5) setRate and update spawns
    p:clear()
    p:setRate(4)
    expect(p.opts.rate==4, "setRate: updates rate")
    r.deltaTime = 0.5
    p.accumulator=0
    p:update()
    alive=0
    for _,v in ipairs(p.pool) do if v.alive then alive=alive+1 end end
    expect(alive==2, "update: spawns floor(rate**dt) particles")

    -- (6) setMaxCount changes pool
    p:setMaxCount(2)
    expect(#p.pool==2, "setMaxCount: pool resized to new maxCount")

    -- DONE
    pruneLog()
    for _, line in ipairs(logLines) do print(line) end
    self.done = true
end
