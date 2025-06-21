-- tests/scene_call_order_spec.lua

dofile("tests/spec_helper.lua")

describe("Scene lifecycle call order", function()
  it("calls enter/exit/cleanup correctly when switching scenes", function()
    local Dummy = dofile("tests/helpers/dummy_scene.lua")
    local Scene = roxy.Scene

    local A  = Dummy("A")
    local B1 = Dummy('B')
    local B2 = Dummy('B')

    Scene.replaceScene(A)
    assert.equal(1, A.hits.enter)

    Scene.pushScene(B1)
    assert.equal(1, A.hits.pause)
    assert.equal(1, B1.hits.enter)

    Scene.popScene()
    assert.equal(1, B1.hits.cleanup)
    assert.equal(1, A.hits.resume)

    Scene.replaceScene(B2)
    assert.equal(1, A.hits.exit)
    assert.equal(1, A.hits.cleanup)
    assert.equal(1, B2.hits.enter)
  end)
end)
