-- tests/animation/animation_roxyanimation_spec.lua
dofile("tests/spec_helper.lua")
local spy = require("luassert.spy")

describe("RoxyAnimation (core logic only)", function()
  local RoxyAnimation
  local anim
  local dummyImagetable
  local updateSpy

  before_each(function()
    -- simple 4-frame table is enough for the retained tests
    dummyImagetable = {true,true,true,true}
    playdate.graphics.imagetable = {
      new       = spy.new(function(view) return dummyImagetable end),
      drawImage = spy.new(function(...) end),
    }

    -- stub C update (not used by remaining specs, but harmless)
    updateSpy = spy.new(function(c,s,e,loop,rev,first,spd,fd,dt,acc)
      return math.min(c+1,e),0,0
    end)
    roxy.Animation = { update = updateSpy }

    -- reload module after stubs
    package.loaded["core.sprites.RoxyAnimation"] = nil
    import("core.sprites.RoxyAnimation")
    RoxyAnimation = _G.RoxyAnimation

    anim = RoxyAnimation("myView")
  end)

  it("adds an animation and sets default/current names", function()
    anim:addAnimation{ name = "run", startFrame = 2, endFrame = 4 }
    assert.equals("run", anim.defaultName)
    assert.equals("run", anim.currentName)
  end)

  it("getSpeed and setSpeed (global vs currentOnly)", function()
    anim:addAnimation{name="a", speed=2}
    anim:addAnimation{name="b", speed=3}
    anim:setAnimation("a")
    assert.equals(2, anim:getSpeed())

    anim:setSpeed(5)
    assert.equals(5, anim:getSpeed())
    assert.equals(5, anim.animations["b"].speed)

    anim:setSpeed(1, true)
    assert.equals(1, anim:getSpeed())
    assert.equals(5, anim.animations["b"].speed)
  end)

  it("getFrameDuration and setFrameDuration clamp correctly", function()
    anim:addAnimation{name="f", frameDuration=0.05}
    anim:setAnimation("f")
    assert.equals(0.05, anim:getFrameDuration())

    anim:setFrameDuration(0.0001, true) -- below minimum
    assert.equals(0.016, anim:getFrameDuration())
  end)

  it("reverse toggles isReversed and resetAnimationStart resets first-cycle", function()
    anim.isFirstCycle = false
    anim:reverse()
    assert.is_true(anim.isReversed)

    anim:resetAnimationStart()
    assert.is_true(anim.isFirstCycle)
  end)
end)
