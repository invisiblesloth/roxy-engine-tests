-- tests/scene_update_bg_spec.lua

dofile("tests/spec_helper.lua")

describe("Scene update/background lists", function()
  it("populates update and background lists correctly", function()
    local Dummy = dofile("tests/helpers/dummy_scene.lua")
    local Scene = roxy.Scene

    local A = Dummy("A", { alwaysUpdate = true })
    local B = Dummy("B", { updateBackground = true })
    local C = Dummy("C")

    Scene.replaceScene(A)
    Scene.pushScene(B)
    Scene.pushScene(C)

    local updateList = Scene.getUpdateList()
    local bgList = Scene.getBackgroundList()

    -- Should update top (C) and alwaysUpdate (A)
    local names = {}
    for i=1, #updateList do table.insert(names, updateList[i].name) end
    assert.are.same({ "A", "C" }, names)

    -- Should updateBackground for B
    assert.are.equal(1, #bgList)
    assert.are.equal("B", bgList[1].name)
  end)
end)
