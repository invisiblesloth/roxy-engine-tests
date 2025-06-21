-- tests/transition/transition_manager_spec.lua

dofile("tests/spec_helper.lua")

local stub = require("luassert.stub")
local Transition = roxy.Transition
local Scene      = roxy.Scene

describe("Transition Manager (roxy.Transition)", function()
  before_each(function()
    Transition.currentTransition = nil
    Transition.isTransitioning   = false
    Transition.stackOp           = Transition.STACK_OP_REPLACE
    Scene.replaceRaw(dofile("tests/helpers/dummy_scene.lua")("root"))
    Transition.loadTransitions({ Cut = roxy.Cut })
  end)

  it("loadTransitions rejects invalid tables", function()
    local ok, err = pcall(function() Transition.loadTransitions("nope") end)
    assert.is_false(ok)
    assert.matches("transitionsTable must be a table", err)

    ok, err = pcall(function() Transition.loadTransitions({ [123] = {} }) end)
    assert.is_false(ok)
    assert.matches("Transition key must be a string", err)
  end)

  it("pushScene sets stackOp and completes instantly for Cut", function()
    local B = dofile("tests/helpers/dummy_scene.lua")("B")
    Transition.pushScene(function() return B end, "Cut", 0, 0)

    -- Cut finishes synchronously, so transition flag is already false
    assert.equal(Transition.STACK_OP_PUSH, Transition.stackOp)
    assert.is_false(Transition.isTransitioning)
    assert.equal(B, Scene.getCurrentScene())
  end)

  it("popScene sets stackOp POP (Cut ends immediately)", function()
    Transition.popScene("Cut", 0, 0)
    assert.equal(Transition.STACK_OP_POP, Transition.stackOp)
    assert.is_false(Transition.isTransitioning)
  end)

  it("warns and falls back on unknown transition", function()
    Transition.loadTransitions({ Cut = roxy.Cut })

    -- Capture warn()
    local warnStub = stub(_G, "warn")

    local A = dofile("tests/helpers/dummy_scene.lua")("A")
    local ok = pcall(function()
      Transition.transitionToScene(function() return A end, "NoSuch")
    end)

    assert.is_true(ok) -- no crash
    assert.stub(warnStub).was_called()
    local called_msg = warnStub.calls[1].vals[1]
    assert.is_truthy(called_msg:find("Unknown transition NoSuch", 1, true))

    warnStub:revert()
  end)
end)
