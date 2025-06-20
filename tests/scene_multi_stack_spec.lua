-- tests/scene_multi_stack_spec.lua

dofile("tests/spec_helper.lua")

describe("Scene stack", function()
  it("handles multiple pushes and pops in order", function()
    local Dummy = dofile("tests/helpers/dummy_scene.lua")
    local Scene = roxy.Scene

    local A, B, C = Dummy("A"), Dummy("B"), Dummy("C")
    Scene.replaceScene(A)   -- stack: [A]
    Scene.pushScene(B)      -- stack: [A, B]
    Scene.pushScene(C)      -- stack: [A, B, C]

    assert.is_true(C._didEnter)
    assert.is_true(B.isPaused)
    assert.is_true(A.isPaused)

    Scene.popScene()        -- back to [A, B]
    assert.is_true(B._didEnter)
    assert.is_true(B.isPaused == false)   -- B should have resumed
    assert.equal(1, C.hits.cleanup)

    Scene.popScene()        -- back to [A]
    assert.is_true(A.isPaused == false)
    assert.equal(1, B.hits.cleanup)

    Scene.popScene()        -- stack empty
    assert.is_nil(Scene.getCurrentScene())
  end)
end)
