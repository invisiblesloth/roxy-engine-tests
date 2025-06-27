-- source/scenes/RoxyActorIntegrationTest.lua

local pd        <const> = playdate
local Graphics  <const> = pd.graphics

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

class("RoxyActorIntegrationTest").extends(RoxyScene)
local scene = RoxyActorIntegrationTest

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

function scene:update(dt)
    clearScreen(CLEAR_COLOR)
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
    -----------------------------------------------------
    -- (1) Initialization with manifest
    -----------------------------------------------------
    local manifest = {
        sheet = "assets/images/circle",
        frames = 1,
        rows = { idle = 1, run = 2, jump = 3, fall = 4 },
        transitions = {
            { state = "jump", onGround = false, vyLessThan = 0 }
        }
    }
    local actor = RoxyActor(manifest, "idle")
    expect(actor.currentState == "idle", "init: default state set to 'idle'")

    -----------------------------------------------------
    -- (2) setState with unknown state
    -----------------------------------------------------
    actor:setState("unknown")
    expect(actor.currentState == "idle", "setState: unknown state does not change currentState")

    -----------------------------------------------------
    -- (3) queueState
    -----------------------------------------------------
    actor:queueState("run")
    expect(actor.nextState == "run", "queueState: nextState set to 'run'")

    -----------------------------------------------------
    -- (4) playOnce and callback
    -----------------------------------------------------
    local called = false
    actor:playOnce("run", function(self) called = true end)
    expect(actor.currentState == "run", "playOnce: switches to 'run'")
    expect(actor.nextState == "idle", "playOnce: queues return to 'idle'")
    actor:_onAnimationComplete("run")
    expect(actor.currentState == "idle", "playOnce: returns to previous state")
    expect(called == true, "playOnce: onFinish callback invoked")

    -----------------------------------------------------
    -- (5) setFacing flips actor
    -----------------------------------------------------
    actor:setFacing(-5)
    expect(actor.facing == -1, "setFacing: facing = -1 when vx < 0")
    actor:setFacing(3)
    expect(actor.facing == 1, "setFacing: facing = 1 when vx > 0")

    -----------------------------------------------------
    -- (6) addPhysics & fallback state transitions
    -----------------------------------------------------
    local body = { vx = -2, vy = 0, onGround = true, update = function(self, dt) self.vx = self.vx end }
    actor:addPhysics(body)
    actor:update(0.1)
    expect(actor.facing == -1, "addPhysics/update: sets facing via fallback logic")
    expect(actor.currentState == "run", "addPhysics/update: transitions to 'run' when vx != 0 and onGround")

    -----------------------------------------------------
    -- (7) transitions cache: jump when in air
    -----------------------------------------------------
    body.vx = 0; body.vy = -5; body.onGround = false
    actor:update(0.1)
    expect(actor.currentState == "jump", "updatePhysics: uses transition rule to switch to 'jump'")

    -----------------------------------------------------
    -- Finish
    -----------------------------------------------------
    pruneLog()
    for _, line in ipairs(logLines) do print(line) end
    self.done = true
end
