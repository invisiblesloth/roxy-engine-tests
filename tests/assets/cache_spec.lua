-- tests/assets/cache_spec.lua

dofile("tests/spec_helper.lua")
local spy = require("luassert.spy")

describe("roxy.Cache (LRU cache)", function()
  local Cache
  before_each(function()
    -- Reload the Cache module to reset internal state
    package.loaded["core.modules.Cache"] = nil
    import("core.modules.Cache")
    Cache = roxy.Cache
  end)

  it("newBucket initializes empty bucket with default max size", function()
    local bucket = Cache.newBucket()
    assert.equals(0, bucket.currentSize)
    assert.equals(50, bucket.maxCacheSize)
    assert.is_nil(bucket.head)
    assert.is_nil(bucket.tail)
    assert.same({}, bucket.cache)

    local bucket2 = Cache.newBucket(10)
    assert.equals(10, bucket2.maxCacheSize)
  end)

  it("setMaxCacheSize sets max size and evicts overflows", function()
    local bucket = Cache.newBucket(2)
    -- populate via cacheAsset
    assert.is_true(Cache.cacheAsset(bucket, "a", function() return 1 end))
    assert.is_true(Cache.cacheAsset(bucket, "b", function() return 2 end))
    assert.equals(2, bucket.currentSize)

    -- increase limit
    assert.is_true(Cache.setMaxCacheSize(bucket, 3))
    assert.equals(3, bucket.maxCacheSize)
    assert.equals(2, bucket.currentSize)

    -- shrink below current size => evicts from tail
    assert.is_true(Cache.setMaxCacheSize(bucket, 1))
    assert.equals(1, bucket.maxCacheSize)
    assert.equals(1, bucket.currentSize)
  end)

  it("cacheAsset adds new assets, enforces max size, and rejects invalid", function()
    local bucket = Cache.newBucket(2)
    local loadCount = 0
    local function loader()
      loadCount = loadCount + 1
      return {data = true}
    end

    -- valid adds
    assert.is_true(Cache.cacheAsset(bucket, "x", loader))
    assert.equals(1, loadCount)
    assert.is_not_nil(bucket.cache["x"])
    assert.equals(1, bucket.currentSize)

    assert.is_true(Cache.cacheAsset(bucket, "y", loader))
    assert.is_not_nil(bucket.cache["y"])
    assert.equals(2, bucket.currentSize)

    -- overflow evicts oldest (x)
    assert.is_true(Cache.cacheAsset(bucket, "z", loader))
    assert.equals(2, bucket.currentSize)
    assert.is_nil(bucket.cache["x"])
    assert.is_not_nil(bucket.cache["z"])

    -- reject duplicate key
    assert.is_false(Cache.cacheAsset(bucket, "z", loader))
    -- reject bad key or loader
    assert.is_false(Cache.cacheAsset(bucket, {}, loader))
    assert.is_false(Cache.cacheAsset(bucket, "k", nil))

    -- loader returns nil
    local badLoader = function() return nil end
    assert.is_false(Cache.cacheAsset(bucket, "bad", badLoader))
  end)

  it("getCachedAsset returns asset and updates MRU, rejects misses", function()
    local bucket = Cache.newBucket()
    Cache.cacheAsset(bucket, "a", function() return "A" end)
    Cache.cacheAsset(bucket, "b", function() return "B" end)
    -- initial head should be b
    assert.equals("b", bucket.head.key)

    local a = Cache.getCachedAsset(bucket, "a")
    assert.equals("A", a)
    -- now a should be head
    assert.equals("a", bucket.head.key)

    -- missing key returns nil
    assert.is_nil(Cache.getCachedAsset(bucket, "c"))
  end)

  it("getOrLoadAsset loads when missing and reuses existing", function()
    local bucket = Cache.newBucket()
    local loads = 0
    local function loader()
      loads = loads + 1
      return 123
    end

    -- missing: should load
    local val1 = Cache.getOrLoadAsset(bucket, "key", loader)
    assert.equals(123, val1)
    assert.equals(1, loads)

    -- existing: should not call loader again
    local val2 = Cache.getOrLoadAsset(bucket, "key", loader)
    assert.equals(123, val2)
    assert.equals(1, loads)
  end)

  it("getIsAssetCached correctly reports presence", function()
    local bucket = Cache.newBucket()
    assert.is_false(Cache.getIsAssetCached(bucket, "x"))
    Cache.cacheAsset(bucket, "x", function() return true end)
    assert.is_true(Cache.getIsAssetCached(bucket, "x"))
  end)

  it("evictAsset removes entries and rejects missing or invalid keys", function()
    local bucket = Cache.newBucket()
    Cache.cacheAsset(bucket, "a", function() return 1 end)
    assert.is_true(Cache.evictAsset(bucket, "a"))
    assert.is_false(Cache.getIsAssetCached(bucket, "a"))
    -- evict again => false
    assert.is_false(Cache.evictAsset(bucket, "a"))
    -- invalid key type
    assert.is_false(Cache.evictAsset(bucket, {}))
  end)

  it("clearCache empties the bucket", function()
    local bucket = Cache.newBucket()
    Cache.cacheAsset(bucket, "a", function() return 1 end)
    assert.equals(1, bucket.currentSize)
    assert.is_true(Cache.clearCache(bucket))
    assert.equals(0, bucket.currentSize)
    assert.is_nil(bucket.head)
    assert.is_nil(bucket.tail)
    assert.same({}, bucket.cache)
  end)
end)
