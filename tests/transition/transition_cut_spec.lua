-- tests/transition/transition_cut_spec.lua

dofile("tests/spec_helper.lua")

local Transition        = roxy.Transition
local Scene             = roxy.Scene
local RoxyCutTransition = roxy.RoxyCutTransition

describe("RoxyCutTransition", function()
  before_each(function()
    Scene.replaceRaw(dofile("tests/helpers/dummy_scene.lua")("root"))
    Transition.loadTransitions({ Cut = roxy.Cut })
  end)

  it("inherits default timing and stackOp", function()
    local cut = RoxyCutTransition()
    assert.equal(1.5,   cut.duration)
    assert.equal(0.25,  cut.holdTime)
    assert.equal(Transition.STACK_OP_REPLACE, cut.stackOp)
  end)

  it("instantly swaps scenes (Cut)", function()
    local A = dofile("tests/helpers/dummy_scene.lua")("A")
    Transition.pushScene(function() return A end, "Cut", 0, 0)
    assert.equal(A, Scene.getCurrentScene())
  end)
end)
