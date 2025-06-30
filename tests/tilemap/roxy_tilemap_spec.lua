-- tests/tilemap/roxy_tilemap_spec.lua

dofile("tests/spec_helper.lua")

describe("RoxyTilemap (tilemap loader)", function()
  local RoxyTilemap, loadJsonOrig

  before_each(function()
    -- Stub json.decodeFile before anything loads roxy.JSON
    json.decodeFile = function(path)
      if path == "bad.json" then
        return nil, "failed to load"
      end
      return { width = 2, height = 3, tilewidth = 8, tileheight = 16,
               tilesets = {}, layers = {} }, nil
    end
    
    -- reload module
    package.loaded["core.tilemaps.RoxyTilemap"] = nil
    -- stub JSON loader
    loadJsonOrig = roxy.JSON and roxy.JSON.loadJson
    roxy.JSON = roxy.JSON or {}
    roxy.JSON.loadJson = function(path)
      if path == "bad.json" then
        return nil, "failed to load"
      end
      -- minimal valid mapData
      return {
        width = 2,
        height = 3,
        tilewidth = 8,
        tileheight = 16,
        tilesets = {},
        layers = {},
      }
    end
    
    package.loaded["utilities.JSON"] = nil
    package.loaded["core.tilemaps.RoxyTilemap"] = nil

    import("utilities.JSON")
    import("core.tilemaps.RoxyTilemap")
    RoxyTilemap = _G.RoxyTilemap
  end)

  after_each(function()
    -- restore JSON loader
    roxy.JSON.loadJson = loadJsonOrig
  end)

  it("errors on invalid JSON path", function()
    assert.has_error(function()
      RoxyTilemap("bad.json")
    end)
  end)

  -- All behavioral, loader, layer and API tests are now covered by integration.

end)
