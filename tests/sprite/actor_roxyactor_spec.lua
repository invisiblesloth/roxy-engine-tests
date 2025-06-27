-- tests/actor/actor_roxyactor_spec.lua
-- Focus on pure‑Lua logic; minimal Playdate stubbing.

dofile("tests/spec_helper.lua")
local spy = require("luassert.spy")

describe("RoxyActor (logic unit tests)", function()
  local RoxyActor
  local actor

  ---------------------------------------------------------------------------
  -- Test‑level scaffolding --------------------------------------------------
  ---------------------------------------------------------------------------
  before_each(function()
    -- ── Stub a super‑simple RoxySprite base (if not already defined) ──────
    if not _G.RoxySprite then
      class("RoxySprite").extends()
      function RoxySprite:init() self.isRoxySprite = true end
      function RoxySprite:markDirty() end
      function RoxySprite:flipX() end
      function RoxySprite:unflip() end
      function RoxySprite:setView(...)      -- provide dummy animation container
        self.animation = {currentAnimation = {startFrame = 1, loop = true}, animations = {}}
      end
      function RoxySprite:update() end
    end

    -- ── Dummy RoxyAnimation (just to satisfy setAnimation) ────────────────
    if not _G.RoxyAnimation then
      class("RoxyAnimation").extends()
      function RoxyAnimation:init() end
      function RoxyAnimation:setAnimation() end
    end

    -- Basic globals used by actor code
    roxy.deltaTime = 0.033

    -- (re)load fresh module after stubs are ready
    package.loaded["core.sprites.RoxyActor"] = nil
    import("core.sprites.RoxyActor")
    RoxyActor = _G.RoxyActor

    -- Create an actor with no sheet to skip imagetable plumbing
    actor = RoxyActor({}, "idle")
    actor.animations = { idle = {}, run = {}, jump = {}, fall = {}, atk = {} }
  end)

  ---------------------------------------------------------------------------
  -- Specs ------------------------------------------------------------------
  ---------------------------------------------------------------------------

  it("setState changes currentState and marks dirty", function()
    local dirtySpy = spy.on(actor, "markDirty")
    actor:setState("idle", true)
    assert.equals("idle", actor.currentState)
    assert.spy(dirtySpy).was.called()
  end)

  it("queueState stores nextState", function()
    actor:queueState("run")
    assert.equals("run", actor.nextState)
  end)

  it("playOnce queues previous state and invokes callback", function()
    local called = 0
    local function cb(self) called = called + 1 end

    actor.currentState = "idle"
    actor:playOnce("atk", cb)   -- should queue idle, switch to atk

    -- simulate animation finishing
    actor:_onAnimationComplete("atk")

    assert.equals(1, called)               -- callback fired exactly once
    assert.is_nil(actor._onPlayOnceFinish) -- cleared after use
    assert.equals("idle", actor.currentState) -- returned to queued state
  end)

  it("setFacing flips / unflips correctly", function()
    local fx = spy.on(actor, "flipX")
    local ux = spy.on(actor, "unflip")

    actor:setFacing(-5)
    assert.equals(-1, actor.facing)
    assert.spy(fx).was.called()

    actor:setFacing(6)
    assert.equals(1, actor.facing)
    assert.spy(ux).was.called()
  end)

  it("_cacheTransitionRules extracts rules", function()
    actor.manifest.transitions = {
      { state = "jump", onGround = false, vyLessThan = 0 },
      { state = "fall", onGround = false, vyGreaterThan = 100 },
    }
    actor:_cacheTransitionRules()
    assert.equals(2, #actor._transitionRulesCache)
    assert.same("jump", actor._transitionRulesCache[1].state)
  end)

  it("updatePhysics chooses idle / run / jump / fall", function()
    -- helper to reset and check state quickly
    local function expectState(props, expected)
      actor.currentState = "idle"
      actor:updatePhysics(props)
      assert.equals(expected, actor.currentState)
    end

    expectState({vy = -10, onGround = false}, "jump")   -- upward air
    expectState({vy =  30, onGround = false}, "fall")   -- downward air
    expectState({vx =  50, desiredVX = 50, onGround = true}, "run") -- run
    expectState({vx =  0,  desiredVX = 0,  onGround = true}, "idle") -- idle
  end)
end)
