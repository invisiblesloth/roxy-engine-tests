-- source/scenes/RoxyPhysicsBodyIntegrationTest.lua

local pd          <const> = playdate

local tableInsert <const> = table.insert
local tableRemove <const> = table.remove

local clearScreen <const> = pd.graphics.clear
local drawText    <const> = pd.graphics.drawText

local COLOR_WHITE <const> = pd.graphics.kColorWhite
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

class("RoxyPhysicsBodyIntegrationTest").extends(RoxyScene)
local scene = RoxyPhysicsBodyIntegrationTest

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
-- Integration Tests
-- ----------------------------------------

function scene:runTests()
    -------------------------------------------------
    -- (1) Stub sprite for collisions
    -------------------------------------------------
    local sprite = {
        x = 0,
        y = 0,
        collisions = {}
    }
    function sprite:moveWithCollisions(targetX, targetY)
        self.x, self.y = targetX, targetY
        return targetX, targetY, self.collisions
    end

    -------------------------------------------------
    -- (2) init defaults
    -------------------------------------------------
    local body = RoxyPhysicsBody(sprite, { vx = 0, vy = 0, gravity = 100 })
    expect(body.vx == 0 and body.vy == 0, "init: velocities start at provided values")
    expect(body.ax == 0 and body.ay == 100, "init: accel and gravity set")
    expect(body.onGround == false, "init: onGround false initially")

    -------------------------------------------------
    -- (3) Acceleration integration and gravity
    -------------------------------------------------
    body.ax = 50; body.vx = 0; body.vy = 0
    body:update(0.1)
    expect(math.abs(body.vx - 5) < 1e-6, "update: vx integrates ax**dt")
    expect(math.abs(body.vy - 10) < 1e-6, "update: vy integrates gravity**dt")

    -------------------------------------------------
    -- (4) Friction when onGround
    -------------------------------------------------
    body.onGround = true; body.friction = 20; body.vx = 10; body.vy = 0
    body:update(0.1)
    expect(body.vx < 10 and math.abs(body.vx - 8) < 1e-6, "update: friction reduces vx when onGround")

    -------------------------------------------------
    -- (5) Floor collision resets vy and sets onGround
    -------------------------------------------------
    sprite.collisions = {{ normal = { x = 0, y = -1 } }}
    body.vy = 50; body.vx = 0; body.onGround = false
    body:update(0.1)
    expect(body.vy == 0, "collision: floor normals zero vy")
    expect(body.onGround == true, "collision: floor normals set onGround true")

    -------------------------------------------------
    -- (6) Ceiling collision resets vy but onGround false
    -------------------------------------------------
    sprite.collisions = {{ normal = { x = 0, y = 1 } }}
    body.vy = 30; body.onGround = false
    body:update(0.1)
    expect(body.vy == 0, "collision: ceiling normals zero vy")
    expect(body.onGround == false, "collision: ceiling normals do not set onGround")

    -------------------------------------------------
    -- (7) Wall collision resets vx
    -------------------------------------------------
    sprite.collisions = {{ normal = { x = 1, y = 0 } }}
    body.vx = 20; body.vy = 0; body.onGround = false
    body:update(0.1)
    expect(body.vx == 0, "collision: wall normals zero vx")

    -------------------------------------------------
    -- (8) Collision callback
    -------------------------------------------------
    local called, last = false, nil
    local function onColl(_, c) called = true; last = c end
    sprite.collisions = {{ normal = { x = -1, y = 0 } }}
    body = RoxyPhysicsBody(sprite, { onCollision = onColl, gravity = 0 })
    body.vx = -5; body.vy = 0
    body:update(0.1)
    expect(called == true, "callback: onCollision invoked on collision")
    expect(last.normal.x == -1, "callback: collision passed correctly")

    -------------------------------------------------
    -- Finish
    -------------------------------------------------
    pruneLog()
    for _, line in ipairs(logLines) do print(line) end
    self.done = true
end
