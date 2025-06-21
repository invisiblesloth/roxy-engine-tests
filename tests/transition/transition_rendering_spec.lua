-- tests/transition/transition_rendering_spec.lua

dofile("tests/spec_helper.lua")

local Transition = roxy.Transition
local Graphics   = playdate.graphics

describe("Transition Rendering helpers", function()
  local t
  before_each(function()
    t = { captureScreenshotsDuringTransition = true }
    Transition.currentTransition = t
    Transition.isTransitioning   = true
  end)

  it("prepareTransitionScreenshot is a no-op when inactive", function()
    Transition.currentTransition = nil
    assert.is_nil(Transition.prepareTransitionScreenshot())
  end)

  it("prepareTransitionScreenshot pushes context & captures", function()
    Graphics.image.new = function(w,h) return { w = w, h = h } end
    Transition.prepareTransitionScreenshot()
    assert.is_true(t._screenshotContextPushed)
    assert.is_table(t.newSceneScreenshot)
  end)

  it("executeTransitionDrawing restores previous draw mode", function()
    local mode = 5
    Graphics.getImageDrawMode = function() return mode end
    Graphics.setImageDrawMode = function(m) mode = m end

    t.drawMode  = 7
    t.draw      = function() t.didDraw = true end
    t.captureScreenshotsDuringTransition = false

    Transition.executeTransitionDrawing()
    assert.is_true(t.didDraw)
    assert.equal(5, mode) -- Back to original
  end)
end)
