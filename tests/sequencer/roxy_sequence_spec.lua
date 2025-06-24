-- tests/sequencer/roxy_sequence_spec.lua

dofile("tests/spec_helper.lua")

local stub = require("luassert.stub")
-- Ensure RoxySequenceC uses our test double:
local originalCtor

-- helper: build a minimal easingArray that tracks segments and length
local function makeTestEasingArray()
  local ea = { segments = {} }
  local function updateLen()
    for i, seg in ipairs(ea.segments) do ea[i] = seg end
  end

  function ea:addEasing(ts, fr, to, dur, ease)
    self.segments[#self.segments + 1] = { ts=ts, from=fr, to=to, dur=dur, endTime = ts + dur, ease = ease }
    updateLen()
  end
  function ea:set(value)
    local ts = #self.segments > 0 and self.segments[#self.segments].endTime or 0
    self:addEasing(ts, value, value, 0, 0)
    return self
  end
  function ea:sleep(dur)
    local ts = #self.segments > 0 and self.segments[#self.segments].endTime or 0
    local v  = #self.segments > 0 and self.segments[#self.segments].to or 0
    self:addEasing(ts, v, v, dur, 0)
    return self
  end
  function ea:updateAndGetValue(dt)
    return 0, dt, (self.segments[1] and self.segments[1].to or 0), true
  end
  function ea:getTotalDuration() return 1 end
  function ea:getEasingData(_, idx)
    local seg = self[idx] or self.segments[idx]
    if seg then return seg.ts, seg.from, seg.to, seg.dur end
    return 0,0,0,0
  end
  function ea:setLoopType() end
  function ea:again() end
  function ea:reverse() end
  function ea:reset() end
  function ea:clear() self.segments = {}; updateLen() end
  function ea:isDone() return true end
  function ea:from(v) self:addEasing(0, v, v, 0, 0); return self end
  function ea:to(to, dur, ease)
    local lastEnd = self.segments[#self.segments].endTime
    self:addEasing(lastEnd, self.segments[#self.segments].to, to, dur or 0.04, ease or 1)
    return self
  end
  return ea
end

describe("RoxySequence high-level wrapper", function()
  local seq, seqAddStub, seqRemoveStub

  before_each(function()
    seqAddStub    = stub(roxy.Sequencer, "add")
    seqRemoveStub = stub(roxy.Sequencer, "remove")

    originalCtor    = _G.RoxySequenceC.new
    _G.RoxySequenceC.new = function() return makeTestEasingArray() end

    _G.RoxySequence = nil
    import("libraries/roxy/core/sequences/RoxySequence")
    roxy.RoxySequence = RoxySequence
    seq = roxy.RoxySequence()
  end)

  after_each(function()
    seqAddStub:revert()
    seqRemoveStub:revert()
    _G.RoxySequenceC.new = originalCtor
  end)

  it("can set pacing value", function()
    seq:setPacing(2)
    assert.equals(2, seq:getPacing())
  end)

  it("clear(true) removes all easing segments", function()
    seq:from(0):to(5,1)
    seq:clear(true)
    assert.equals(0, #seq.easingArray.segments)
  end)

  it("set() jumps to target value", function()
    seq:from(0):to(5,1)
    seq:set(3)
    local last = seq.easingArray.segments[#seq.easingArray.segments]
    assert.equals(3, last.to)   -- confirm segment was written
  end)

  it("sleep() adds a delay segment", function()
    seq:from(0):sleep(1):to(10,1)
    assert.equals(1, seq.easingArray.segments[2].dur)
  end)

  it("multiple callbacks can be triggered at correct times", function()
    local cb1, cb2 = false, false
    seq:from(0):to(10,1)
       :callback(function() cb1 = true end, 0)
       :callback(function() cb2 = true end, 1)
       :start()
    seq:update(0.5)
    assert.is_true(cb1)
    assert.is_false(cb2)
    seq:update(1)
    assert.is_true(cb2)
  end)

  it("loop() sets loopType to looping", function()
    seq:from(0):to(10,1):loop()
    assert.equals(1, seq.loopType)
  end)

  it("pingPong() sets loopType to ping-pong", function()
    seq:from(0):to(10,1):pingPong()
    assert.equals(2, seq.loopType)   -- 2 == ping-pong
  end)

  it("again() calls easingArray:again with correct count and returns self", function()
    local againStub = stub(seq.easingArray, "again")
    local ret = seq:from(0):to(5,1):again(3)
    assert.stub(againStub).was_called_with(seq.easingArray, 3)
    assert.equals(seq, ret)
    againStub:revert()
  end)

  it("reverse() calls easingArray:reverse and returns self", function()
    local revStub = stub(seq.easingArray, "reverse")
    seq:from(0):to(5,1)
    local ret1 = seq:reverse()        -- default nil/false
    assert.stub(revStub).was_called_with(seq.easingArray, nil)
    local ret2 = seq:reverse(true)    -- explicit append
    assert.stub(revStub).was_called_with(seq.easingArray, true)
    assert.equals(seq, ret1)
    assert.equals(seq, ret2)
    revStub:revert()
  end)

  it("reset() clears running state, resets currentValue and callback flags", function()
    local triggered = false
    seq:from(0):to(5,1)
       :callback(function() triggered = true end, 0)
       :start()
    seq:update(1)
    assert.is_true(triggered)
    seq:reset()
    assert.is_false(seq.isRunning)
    assert.equals(0, seq.currentValue)
    for _, cb in ipairs(seq.callbacks) do
      assert.is_false(cb[3])  -- callback triggered flag reset
    end
  end)

  -- existing start/stop/restart/callback specs
  it("start() calls Sequencer.add and marks running", function()
    seq:from(0):to(10,1)
    seq:start()
    assert.stub(seqAddStub).was_called()
    assert.is_true(seq.isRunning)
  end)

  it("stop() calls Sequencer.remove and resets running flag", function()
    seq:from(0):to(5,1):start()
    seq:stop()
    assert.stub(seqRemoveStub).was_called()
    assert.is_false(seq.isRunning)
  end)

  it("restart() re-adds and resets easingArray", function()
    local resetStub = stub(seq.easingArray, "reset")
    seq:from(0):to(5,1):start()
    seq:restart()
    assert.stub(seqRemoveStub).was_called()
    assert.stub(resetStub).was_called()
    assert.stub(seqAddStub).was_called()
    resetStub:revert()
  end)

  it("callback() fires when update passes timestamp", function()
    local triggered = false
    seq:from(0):to(10,1)
       :callback(function() triggered = true end, 0)
       :start()
    seq:update(1)
    assert.is_true(triggered)
  end)
end)
