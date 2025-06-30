-- tests/sprites/roxyparticles_spec.lua

dofile("tests/spec_helper.lua")
local spy = require("luassert.spy")

describe("RoxyParticles (particle emitter)", function()
  local RoxyParticles

  before_each(function()
    -- Stub a minimal RoxySprite *before* we import RoxyParticles,
    -- so moveTo() will record x/y.
    if not _G.RoxySprite then
      function RoxySprite:moveTo(x, y)
        self.x, self.y = x, y
      end
    end
  
    -- reload class after stub in place
    package.loaded["core.sprites.RoxyParticles"] = nil
    import("core.sprites.RoxyParticles")
    RoxyParticles = _G.RoxyParticles
  end)

  it("constructs with default opts and pool", function()
    -- inside the “constructs with default opts and pool” test
    local p = RoxyParticles(10, 20)
    assert.equals(20, #p.pool)          -- pool size
    assert.is_number(p.emitterOffsetX)  -- emitter offsets
    assert.is_number(p.emitterOffsetY)
  end)

  it("emits the right number of particles (emit), sets them alive", function()
    local p = RoxyParticles(0, 0, { maxCount = 5 })
    p:emit(3)
    local alive = 0
    for i = 1, #p.pool do
      if p.pool[i].alive then alive = alive + 1 end
    end
    assert.equals(3, alive)
  end)

  it("does not emit more than maxCount", function()
    local p = RoxyParticles(0, 0, { maxCount = 4 })
    p:emit(10)
    local alive = 0
    for i = 1, #p.pool do
      if p.pool[i].alive then alive = alive + 1 end
    end
    assert.equals(4, alive)
  end)

  it("clear() sets all particles to not alive", function()
    local p = RoxyParticles(0, 0, { maxCount = 4 })
    p:emit(4)
    p:clear()
    for i = 1, #p.pool do
      assert.is_false(p.pool[i].alive)
    end
  end)

  it("spawn() returns false if pool is full, true if spawnable", function()
    local p = RoxyParticles(0, 0, { maxCount = 2 })
    assert.is_true(p:spawn())
    assert.is_true(p:spawn())
    assert.is_false(p:spawn())
  end)

  it("update() kills particles at end of lifetime", function()
    local p = RoxyParticles(0, 0, { maxCount = 2, lifetime = {0.01, 0.01}})
    p:emit(2)
    roxy.deltaTime = 0.02
    p:update()
    for i = 1, #p.pool do
      assert.is_false(p.pool[i].alive)
    end
  end)

  it("setRate enables continuous emission via update", function()
    local p = RoxyParticles(0, 0, { maxCount = 5 })
    roxy.deltaTime = 0.1
    p:setRate(10) -- 1 particle per 0.1s
    p:update()
    local alive = 0
    for i = 1, #p.pool do if p.pool[i].alive then alive = alive + 1 end end
    assert.is_true(alive > 0)
  end)

  it("setMaxCount shrinks or grows the pool", function()
    local p = RoxyParticles(0, 0, { maxCount = 5 })
    assert.equals(5, #p.pool)
    p:setMaxCount(3)
    assert.equals(3, #p.pool)
    p:setMaxCount(7)
    assert.equals(7, #p.pool)
  end)

  it("setLifetimeRange, setSpeedRange, setAngleRange, setAccel, setSizeRange update opts", function()
    local p = RoxyParticles(0, 0)
    p:setLifetimeRange(0.1, 2.2)
    assert.same({0.1, 2.2}, p.opts.lifetime)
    p:setSpeedRange(4, 5)
    assert.same({4, 5}, p.opts.speed)
    p:setAngleRange(-90, 90)
    assert.same({-90, 90}, p.opts.angleRange)
    p:setAccel(3, 4)
    assert.same({x=3, y=4}, p.opts.accel)
    p:setSizeRange(5, 6)
    assert.same({5, 6}, p.opts.size)
  end)

  it("setColor, setPattern, setShape all update opts", function()
    local p = RoxyParticles(0, 0)
    p:setColor("foo")
    assert.equals("foo", p.opts.color)
    p:setPattern("bar")
    assert.equals("bar", p.opts.pattern)
    p:setShape("square")
    assert.equals("square", p.opts.shape)
  end)

  it("setFrameMode and setStaticFrame clamp static frame correctly", function()
    -- Simulate imageTable
    local fakeImgTable = {
      getLength = function() return 5 end,
      getImage = function() return { getSize = function() return 8,8 end } end,
    }
    local p = RoxyParticles(0, 0, { imageTable = fakeImgTable })
    p:setFrameMode("static", 7)
    assert.equals(5, p.staticFrameClamped)
    p:setStaticFrame(3)
    assert.equals(3, p.staticFrameClamped)
  end)
end)
