-- tests/scene_empty_pop_spec.lua

dofile("tests/spec_helper.lua")

describe("Scene stack edge cases", function()
  it("does nothing and does not error when popping from empty stack", function()
    local Scene = roxy.Scene
    -- Should not error, should just set currentScene to nil
    Scene.popScene()
    assert.is_nil(Scene.getCurrentScene())
  end)
end)
