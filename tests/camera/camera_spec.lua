-- tests/modules/camera_spec.lua

-- Unit tests for roxy.Camera
-- Focus on setter/getter behavior, bounds, reset, and utility methods.

dofile("tests/spec_helper.lua")
local spy = require("luassert.spy")

describe("roxy.Camera basic API", function()
  local Camera = roxy.Camera
  local setDrawOffsetSpy, redrawBackgroundSpy

  -- Helper to reload module after stubbing
  local function reloadCamera()
    package.loaded["core.modules.Camera"] = nil
    import("core.modules.Camera")
  end

  before_each(function()
    -- Stub draw offset and background redraw before import
    setDrawOffsetSpy = spy.new(function() end)
    redrawBackgroundSpy = spy.new(function() end)
    playdate.graphics.setDrawOffset = setDrawOffsetSpy
    playdate.graphics.sprite.redrawBackground = redrawBackgroundSpy

    -- Ensure math helpers exist
    roxy.Math = roxy.Math or {}
    roxy.Math.clamp = function(v,mn,mx) if v<mn then return mn elseif v>mx then return mx else return v end end
    roxy.Math.lerp = function(a,b,t) return a + (b-a)*t end
    roxy.Math.roundInt = function(x) return math.floor(x + 0.5) end

    -- Stub display size for isOnScreen
    playdate.display = { getWidth = function() return 100 end, getHeight = function() return 50 end }

    -- Reload Camera so it picks up stubs
    reloadCamera()

    -- Always reset camera state before each test
    Camera.reset()
    -- Clear any leftover updateFunc flags
    Camera._isActive = false
  end)

  it("setPosition: sets x,y and resets velocity and target", function()
    assert.has_error(function() Camera.setPosition("x", "y") end)
    Camera.setPosition(15, -7)
    assert.equals(15, Camera.x)
    assert.equals(-7, Camera.y)
    assert.equals(15, Camera._targetX)
    assert.equals(-7, Camera._targetY)
    assert.equals(0, Camera._velocityX)
    assert.equals(0, Camera._velocityY)
    assert.equals(Camera.updateStatic, Camera._updateFunc)
    assert.is_true(Camera._isActive)
  end)

  it("setPanVelocity: applies defaults and custom, errors on invalid", function()
    assert.has_error(function() Camera.setPanVelocity("foo") end)
    -- default when nil: uses CAMERA_SPEED_DEFAULT
    Camera.setPanVelocity()
    assert.equals(120, Camera._velocityX)
    assert.equals(120, Camera._velocityY)
    assert.equals(Camera.updateManualPan, Camera._updateFunc)

    -- custom values
    Camera.setPanVelocity(5, 9)
    assert.equals(5, Camera._velocityX)
    assert.equals(9, Camera._velocityY)
  end)

  it("setTarget: assigns target and smoothing, errors on invalid", function()
    local dummy = { getPosition = function() return 1,2 end }
    assert.has_error(function() Camera.setTarget({}, 0.5) end)
    Camera.setTarget(dummy)
    assert.equals(dummy, Camera.target)
    assert.equals(Camera.updateFollow, Camera._updateFunc)

    Camera.setTarget(nil)
    assert.equals(Camera.updateStatic, Camera._updateFunc)

    Camera.setTarget(dummy, 3)
    assert.equals(3, Camera.smoothing)
  end)

  it("setSmoothing: sets smoothing and clamps negative", function()
    assert.has_error(function() Camera.setSmoothing("bad") end)
    Camera.setSmoothing(2.5)
    assert.equals(2.5, Camera.smoothing)
    Camera.setSmoothing(-1)
    assert.equals(0, Camera.smoothing)
  end)

  it("shake: sets shake parameters and resets timer, errors on invalid", function()
    assert.has_error(function() Camera.shake("a",1,1) end)
    Camera.shake(5, 0.2, 4)
    assert.equals(5, Camera._shakeAmplitude)
    assert.equals(0.2, Camera.shakeDuration)
    assert.equals(4, Camera._shakeFrequency)
    assert.equals(0, Camera._shakeTimer)
    assert.is_true(Camera._isActive)
  end)

  it("setDeadZone: sets width/height, errors on invalid", function()
    assert.has_error(function() Camera.setDeadZone("w", 2) end)
    Camera.setDeadZone(10, 7)
    assert.equals(10, Camera._deadZoneWidth)
    assert.equals(7,  Camera._deadZoneHeight)
  end)

  it("setFriction: clamps between 0 and 1, errors on invalid", function()
    assert.has_error(function() Camera.setFriction("f") end)
    Camera.setFriction(0.3)
    assert.equals(0.3, Camera.friction)
    Camera.setFriction(2)
    assert.equals(1, Camera.friction)
    Camera.setFriction(-1)
    assert.equals(0, Camera.friction)
  end)

  it("setBounds and clearBounds", function()
    assert.has_error(function() Camera.setBounds({}) end)
    Camera.setBounds({ x1=0, y1=1, x2=5, y2=6 })
    assert.is_true(Camera._hasBounds)
    local b = Camera.getBounds()
    assert.same({ x1=0, y1=1, x2=5, y2=6 }, b)

    Camera.clearBounds()
    assert.is_false(Camera._hasBounds)
    assert.is_nil(Camera.getBounds())
  end)
end)
