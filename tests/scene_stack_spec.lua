-- tests/scene_stack_spec.lua

dofile("tests/spec_helper.lua")

describe('Scene stack', function()
  it('push / pop pauses & resumes', function()
    local Dummy = dofile('tests/helpers/dummy_scene.lua')
    local Scene = roxy.Scene

    local A = Dummy('A')
    local B = Dummy('B')

    Scene.replaceScene(A)
    Scene.pushScene(B)
    assert.equal(1, A.hits.pause)
    assert.is_true(B._didEnter)

    Scene.popScene()
    assert.equal(1, B.hits.cleanup)
    assert.equal(1, A.hits.resume)
  end)
end)
