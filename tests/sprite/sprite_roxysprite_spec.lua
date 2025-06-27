-- tests/sprite/roxy_sprite_spec.lua

dofile("tests/spec_helper.lua")

describe("RoxySprite", function()
  local RoxySprite

  before_each(function()
    -- (re)load the class under test
    import("core.sprites.RoxySprite")
    RoxySprite = _G.RoxySprite

    -- stub out the Playdate flip constants
    local g = playdate.graphics
    g.kImageUnflipped   = 0
    g.kImageFlippedX    = 1
    g.kImageFlippedY    = 2
    g.kImageFlippedXY   = 3
  end)

  it("initializes with correct defaults", function()
    local s = RoxySprite()
    assert.is_true(s.isRoxySprite)
    assert.equals("RoxySprite", s.name)
    assert.is_true(s:getIsPaused())
    assert.is_false(s:isAdded())
    assert.equals(0, s:getOrientation())
  end)

  it("chains setIsPaused and flips paused state", function()
    local s = RoxySprite()
    -- false
    assert.equals(s, s:setIsPaused(false))
    assert.is_false(s:getIsPaused())
    -- true
    assert.equals(s, s:setIsPaused(true))
    assert.is_true(s:getIsPaused())
  end)

  it("add() and remove() manage the isAdded flag", function()
    local s = RoxySprite()
    assert.equals(s, s:add())
    assert.is_true(s:isAdded())
    assert.equals(s, s:remove())
    assert.is_false(s:isAdded())
  end)

  it("chains play/pause/toggle/replay/stop", function()
    local s = RoxySprite()
    assert.equals(s, s:play())
    assert.equals(s, s:pause())
    assert.equals(s, s:togglePlayPause())
    assert.equals(s, s:togglePlayPause())
    assert.equals(s, s:replay())
    assert.equals(s, s:stop())
  end)

  it("flipX/Y/XY/unflip set orientation correctly", function()
    local s = RoxySprite()
    assert.equals(s, s:flipX())
    assert.equals(1, s:getOrientation())
    assert.equals(s, s:flipY())
    assert.equals(2, s:getOrientation())
    assert.equals(s, s:flipXY())
    assert.equals(3, s:getOrientation())
    assert.equals(s, s:unflip())
    assert.equals(0, s:getOrientation())
  end)
end)
