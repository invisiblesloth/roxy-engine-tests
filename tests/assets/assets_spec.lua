-- tests/modules/assets_spec.lua

dofile("tests/spec_helper.lua")
local spy = require("luassert.spy")

describe("roxy.Assets (Asset Pool)", function()
  local Assets

  before_each(function()
    -- Reload the Assets module to reset internal pools
    package.loaded["core.modules.Assets"] = nil
    import("core.modules.Assets")
    Assets = roxy.Assets
  end)

  it("registerPool rejects non-function loader and duplicates", function()
    -- invalid loader
    assert.is_false(Assets.registerPool("key", 1, nil))
    -- valid
    local loader = function() return {} end
    assert.is_true(Assets.registerPool("key", 2, loader))
    -- duplicate key
    assert.is_false(Assets.registerPool("key", 2, loader))
  end)

  it("getIsPoolRegistered reports registration status", function()
    assert.is_false(Assets.getIsPoolRegistered("foo"))
    Assets.registerPool("foo", 1, function() return 42 end)
    assert.is_true(Assets.getIsPoolRegistered("foo"))
  end)

  it("getAsset returns assets, grows pool once, then nil at max", function()
    -- initialCount=1, default maxSize=2, growthFactor=1
    local loads = 0
    local function loader()
      loads = loads + 1
      return "A"..loads
    end

    Assets.registerPool("p", 1, loader)

    -- 1st call: uses preloaded asset
    local a1 = Assets.getAsset("p")
    assert.equals("A1", a1)
    assert.equals(1, loads)

    -- 2nd call: pool empty → grows by 1 (creates A2)
    local a2 = Assets.getAsset("p")
    assert.equals("A2", a2)
    assert.equals(2, loads)

    -- 3rd call: pool at maxSize and empty → returns nil, no new loads
    local a3 = Assets.getAsset("p")
    assert.is_nil(a3)
    assert.equals(2, loads)
  end)

  it("recycleAsset returns asset to pool for reuse", function()
    local loads = 0
    local function loader() loads = loads + 1; return {id = loads} end

    Assets.registerPool("r", 1, loader)

    -- pull first asset
    local a1 = Assets.getAsset("r")
    assert.equals(1, loads)

    -- pool empty now; pull again to force growth (makes a2)
    local a2 = Assets.getAsset("r")
    assert.equals(2, loads)
    assert.is_not_nil(a2)

    -- recycle first asset
    assert.is_true(Assets.recycleAsset("r", a1))

    -- getAsset should now return a1 (no additional load)
    local a3 = Assets.getAsset("r")
    assert.equals(2, loads)   -- loader not called again
    assert.equal(a1, a3)
  end)

  it("recycleAsset rejects invalid pool or nil asset", function()
    assert.is_false(Assets.recycleAsset("nope", {}))
    Assets.registerPool("q", 1, function() return "Z" end)
    assert.is_false(Assets.recycleAsset("q", nil))
  end)
end)
