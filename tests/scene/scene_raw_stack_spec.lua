-- tests/scene_raw_stack_spec.lua

dofile("tests/spec_helper.lua")

describe("Scene raw stack operations", function()
  it("replaceRaw simply clears & sets without calling enter/exit/cleanup", function()
    local Dummy = dofile("tests/helpers/dummy_scene.lua")
    local Scene = roxy.Scene

    local A = Dummy("A")
    -- prime some hits to show they don't change
    A:enter(); A:exit(); A:cleanup()
    assert.equal(1, A.hits.enter)
    assert.equal(1, A.hits.exit)
    assert.equal(1, A.hits.cleanup)

    -- now replaceRaw
    Scene.replaceRaw(A)
    assert.same(1, Scene.getStackDepth())
    assert.equal(A, Scene.getCurrentScene())

    -- no additional lifecycle calls
    assert.equal(1, A.hits.enter)
    assert.equal(1, A.hits.exit)
    assert.equal(1, A.hits.cleanup)
  end)

  it("pushRaw pushes without pausing old scene or entering new one", function()
    local Dummy = dofile("tests/helpers/dummy_scene.lua")
    local Scene = roxy.Scene

    local A, B = Dummy("A"), Dummy("B")
    Scene.replaceRaw(A)
    -- clear out any accidental hits
    A.hits = setmetatable({}, {__index=function() return 0 end})

    Scene.pushRaw(B)
    assert.same(2, Scene.getStackDepth())
    assert.equal(B, Scene.getCurrentScene())

    -- raw shouldn’t call pause or enter
    assert.equal(0, A.hits.pause)
    assert.equal(0, B.hits.enter)
  end)

  it("popRaw pops and returns the top without cleanup/resume", function()
    local Dummy = dofile("tests/helpers/dummy_scene.lua")
    local Scene = roxy.Scene

    local A, B = Dummy("A"), Dummy("B")
    Scene.replaceRaw(A)
    Scene.pushRaw(B)

    -- reset hits
    A.hits = setmetatable({}, {__index=function() return 0 end})
    B.hits = setmetatable({}, {__index=function() return 0 end})
    A.isPaused = false

    local popped = Scene.popRaw()
    assert.equal(B, popped)
    assert.same(1, Scene.getStackDepth())
    assert.equal(A, Scene.getCurrentScene())

    -- raw shouldn’t call cleanup or resume
    assert.equal(0, B.hits.cleanup)
    assert.is_false(A.isPaused)
  end)

  it("popRaw on empty stack is a no-op and returns nil", function()
    local Scene = roxy.Scene

    -- ensure empty
    while Scene.getStackDepth() > 0 do
      Scene.popRaw()
    end

    local popped = Scene.popRaw()
    assert.is_nil(popped)
    assert.same(0, Scene.getStackDepth())
    assert.is_nil(Scene.getCurrentScene())
  end)

  it("pushRaw errors when exceeding max depth", function()
    local Dummy = dofile("tests/helpers/dummy_scene.lua")
    local Scene = roxy.Scene
  
    -- The engine uses 32 as its cap (MAX_SCENE_DEPTH).
    local cap = 32
  
    Scene.replaceRaw(Dummy("root"))
    -- push up to the cap
    for i = 1, cap-1 do
      Scene.pushRaw(Dummy("S"..i))
    end
  
    -- now at depth == cap
    assert.equal(cap, Scene.getStackDepth())
  
    -- and one more pushRaw should error
    local ok, err = pcall(Scene.pushRaw, Dummy("overflow"))
    assert.is_false(ok)
    assert.matches("Stack depth exceeded", err)
  end)
end)
