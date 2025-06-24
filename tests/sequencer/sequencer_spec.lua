-- tests/sequencer/sequencer_spec.lua

dofile("tests/spec_helper.lua")

-- Load the core Sequencer implementation
import("libraries/roxy/core/modules/Sequencer")

local stub = require("luassert.stub")
local Sequencer = roxy.Sequencer

describe("Sequencer core module", function()
  local dummySequence

  before_each(function()
    -- fresh dummy sequence for each test
    dummySequence = {
      update = stub.new(),
      stop   = stub.new()
    }
    -- clear Sequencer state
    Sequencer.removeAll()
  end)

  it("add inserts sequence and update forwards dt", function()
    Sequencer.add(dummySequence)
    Sequencer.update(0.5)
    assert.stub(dummySequence.update).was_called_with(dummySequence, 0.5)
  end)

  it("remove deletes a specific sequence", function()
    local seqA = { update = stub.new(), stop = stub.new() }
    local seqB = { update = stub.new(), stop = stub.new() }
    Sequencer.add(seqA)
    Sequencer.add(seqB)
    Sequencer.remove(seqA)
    Sequencer.update(1/30) -- a frame
    assert.stub(seqA.update).was_not_called()
    assert.stub(seqB.update).was_called()
  end)

  it("stopAll calls stop on each running sequence", function()
    local seqA = { update = stub.new(), stop = stub.new() }
    local seqB = { update = stub.new(), stop = stub.new() }
    Sequencer.add(seqA)
    Sequencer.add(seqB)
    Sequencer.stopAll()
    assert.stub(seqA.stop).was_called()
    assert.stub(seqB.stop).was_called()
  end)

  it("removeAll clears the running list", function()
    Sequencer.add(dummySequence)
    Sequencer.removeAll()
    Sequencer.update(0.1)
    assert.stub(dummySequence.update).was_not_called()
  end)
end)
