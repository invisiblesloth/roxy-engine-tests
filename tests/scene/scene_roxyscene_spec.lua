-- tests/scene_roxyscene_spec.lua

dofile("tests/spec_helper.lua")

describe('RoxyScene', function()
  it('pause / resume toggles isPaused', function()
    local Dummy = dofile('tests/helpers/dummy_scene.lua')
    local scene = Dummy('Unit')
    scene:pause(); scene:pause()
    assert.is_true(scene.isPaused)
    assert.equal(1, scene.hits.pause)

    scene:resume()
    assert.is_false(scene.isPaused)
    assert.equal(1, scene.hits.resume)
  end)
end)
