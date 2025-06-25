-- tests/scene/scene_roxyscene_background_spec.lua

dofile("tests/spec_helper.lua")
local spy = require("luassert.spy")

describe("RoxyScene background handling", function()
  local Dummy, real_type

  before_each(function()
    -- Clear spies using method syntax
    playdate.graphics.setColor:clear()
    playdate.graphics.fillRect:clear()

    -- Load Dummy subclass
    package.loaded["tests/helpers/dummy_scene.lua"] = nil
    Dummy = dofile("tests/helpers/dummy_scene.lua")
  end)

  it("accepts a solid color", function()
    local s = Dummy()
    s:setBackground(42)

    assert.equals(42, s.backgroundColor)
    assert.is_nil(s.backgroundImage)

    s.backgroundDrawFn(1,2,3,4)
    assert.spy(playdate.graphics.setColor).was.called_with(42)
    assert.spy(playdate.graphics.fillRect).was.called_with(1,2,3,4)
  end)

  it("re-uses the cached colour callback", function()
    local s = Dummy()
    s:setBackground(7)
    local cb1 = s.backgroundDrawFn
    s:setBackground(7)
    assert.is_true(cb1 == s.backgroundDrawFn, "same callback object for same colour")
  end)

  it("accepts a background image", function()
    local img = { draw = spy.new(function() end) }
    real_type = type
    _G.type = function(x)
      if x == img then return "userdata" end
      return real_type(x)
    end

    local s = Dummy()
    s:setBackground(img)

    assert.is_nil(s.backgroundColor)
    assert.equals(img, s.backgroundImage)

    s.backgroundDrawFn(10,20,30,40)
    assert.spy(img.draw).was.called_with(img,10,20,nil,10,20,30,40)

    _G.type = real_type
  end)

  it("falls back on unknown values", function()
    local s = Dummy()
    s:setBackground("not a colour or image")

    assert.equals(playdate.graphics.kColorWhite, s.backgroundColor)
    assert.is_nil(s.backgroundImage)

    s.backgroundDrawFn(5,6,7,8)
    assert.spy(playdate.graphics.setColor).was.called_with(playdate.graphics.kColorWhite)
    assert.spy(playdate.graphics.fillRect).was.called_with(5,6,7,8)
  end)
end)