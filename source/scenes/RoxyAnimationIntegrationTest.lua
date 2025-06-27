-- source/scenes/RoxyAnimationIntegrationTest.lua

local pd <const> = playdate
local Graphics <const> = pd.graphics
local Sprite <const> = Graphics.sprite
local r <const> = roxy

local clamp <const> = roxy.Math.clamp

local tableInsert <const> = table.insert
local tableRemove <const> = table.remove

local clearScreen <const> = Graphics.clear
local newImagetable <const> = Graphics.imagetable.new
local drawText <const> = Graphics.drawText

local COLOR_WHITE <const> = Graphics.kColorWhite
local CLEAR_COLOR <const> = COLOR_WHITE

-- ----------------------------------------
-- Helpers
-- ----------------------------------------

local logLines = {}

local function ok(msg)
  tableInsert(logLines, "✔️ " .. msg)
end

local function fail(msg)
  tableInsert(logLines, "❌ " .. msg)
end

local function expect(cond, msg)
  if cond then
    ok(msg)
  else
    fail(msg)
  end
end

local function pruneLog()
  if #logLines > 60 then
    tableRemove(logLines, 1)
  end
end

-- ----------------------------------------
-- Class Definition & Init
-- ----------------------------------------

class("RoxyAnimationIntegrationTest").extends(RoxyScene)
local scene = RoxyAnimationIntegrationTest

function scene:init()
  scene.super.init(self)
  self.done     = false
  self.testsRun = false
end

-- ----------------------------------------
-- Scene Lifecycle
-- ----------------------------------------

function scene:enter()
  scene.super.enter(self)
  if not self.testsRun then
    self:runTests()
    self.testsRun = true
  end
end

function scene:update(dt)
  clearScreen(CLEAR_COLOR)

  -- Draw logs
  local y = 10
  for i = 1, math.min(#logLines, 18) do
    drawText(logLines[i], 10, y)
    y += 12
  end
  if self.done then
    drawText("*DONE*", 10, 220)
  end
end

-- ----------------------------------------
-- Integration Tests
-- ----------------------------------------

function scene:runTests()
  -----------------------------------------------------
  -- (1) Initialization
  -----------------------------------------------------
  local view = "assets/images/circle"
  local anim = RoxyAnimation(view)
  expect(anim.isRoxyAnimation == true, "init: isRoxyAnimation set")
  expect(anim.imagetable ~= nil, "init: imagetable created")

  -----------------------------------------------------
  -- (2) Basic animation add & defaults
  -----------------------------------------------------
  anim:addAnimation { name = "spin", startFrame = 1, endFrame = 4 }
  expect(anim.animations["spin"] ~= nil, "addAnimation: animation added")
  expect(anim.defaultName == "spin", "addAnimation: defaultName set")
  expect(anim.currentName == "spin", "addAnimation: currentName set")
  expect(anim.currentFrame == 1, "addAnimation: currentFrame initialized")
  expect(anim:getSpeed() == 1, "getSpeed: default speed")
  expect(math.abs(anim:getFrameDuration() - 0.033) < 0.0001, "getFrameDuration: default frameDuration")

  -----------------------------------------------------
  -- (3) Global speed change
  -----------------------------------------------------
  anim:setSpeed(2) -- all animations so far
  expect(anim:getSpeed() == 2, "setSpeed: set speed for current")
  expect(anim.animations["spin"].speed == 2, "setSpeed: speed updated in animation def")

  -----------------------------------------------------
  -- (4) Current‑only speed change
  -----------------------------------------------------
  anim:addAnimation { name = "other", startFrame = 2, endFrame = 3, speed = 0.5 }
  anim:setAnimation("other")
  anim:setSpeed(3, true) -- current only
  expect(anim:getSpeed() == 3, "setSpeed(currentOnly): set speed on current only")
  expect(anim.animations["spin"].speed == 2, "setSpeed(currentOnly): other animations unaffected")

  -----------------------------------------------------
  -- (5) Global frameDuration change
  -----------------------------------------------------
  anim:setFrameDuration(0.2)
  expect(math.abs(anim:getFrameDuration() - 0.2) < 0.0001, "setFrameDuration: frameDuration updated for all")

  -----------------------------------------------------
  -- (6) shouldPreventAnimationChange guard
  -----------------------------------------------------
  anim:setAnimation("spin")
  anim:setAnimation("other", false, "spin")
  expect(anim.currentName == "spin", "shouldPreventAnimationChange: no change when unlessThis matches")

  -----------------------------------------------------
  -- (7) Continuity calculation
  -----------------------------------------------------
  anim:addAnimation { name = "cont1", startFrame = 1, endFrame = 5 }
  anim:setAnimation("cont1")
  anim.currentFrame = 3
  anim:addAnimation { name = "cont2", startFrame = 10, endFrame = 14 }
  anim:setAnimation("cont2", true) -- continuity
  expect(anim.currentFrame == 12, "setAnimation: continuity preserves progress")

  -----------------------------------------------------
  -- (8) Frame jump & wrapping helpers
  -----------------------------------------------------
  anim:setAnimation("cont1")
  anim:jumpToSpecificFrame(100)
  expect(anim.currentFrame == anim.currentAnimation.endFrame, "jumpToSpecificFrame: clamps to endFrame")
  anim:jumpToSpecificFrame(0)
  expect(anim.currentFrame == anim.currentAnimation.startFrame, "jumpToSpecificFrame: clamps to startFrame")

  anim.currentFrame = anim.currentAnimation.startFrame
  anim:stepFrame()
  expect(anim.currentFrame == anim.currentAnimation.startFrame + 1, "stepFrame: increments frame")
  anim.currentFrame = anim.currentAnimation.endFrame
  anim:stepFrame()
  expect(anim.currentFrame == anim.currentAnimation.startFrame, "stepFrame: wraps around")
  anim:stepFrame(-1)
  expect(anim.currentFrame == anim.currentAnimation.endFrame, "stepFrame: backward wraps to endFrame")

  -----------------------------------------------------
  -- (8.5) stepFrame on non-1 startFrame range
  -----------------------------------------------------
  anim:addAnimation { name = "custom", startFrame = 2, endFrame = 4 }
  anim:setAnimation("custom")

  anim.currentFrame = anim.currentAnimation.startFrame -- 2
  anim:stepFrame()
  expect(anim.currentFrame == 3, "stepFrame: custom anim increments to 3")
  anim:stepFrame()
  expect(anim.currentFrame == 4, "stepFrame: custom anim increments to 4")
  anim:stepFrame()
  expect(anim.currentFrame == 2, "stepFrame: custom anim wraps to startFrame (2)")
  anim:stepFrame(-1)
  expect(anim.currentFrame == 4, "stepFrame: custom anim wraps to endFrame (4) when stepping back")
  anim:stepFrame(-1)
  expect(anim.currentFrame == 3, "stepFrame: custom anim steps back to 3")

  -----------------------------------------------------
  -- (9) reverse() & resetAnimationStart()
  -----------------------------------------------------
  anim.isReversed = false
  anim:reverse()
  expect(anim.isReversed == true, "reverse: toggles isReversed")
  anim.isFirstCycle = false
  anim:resetAnimationStart()
  expect(anim.isFirstCycle == true, "resetAnimationStart: sets isFirstCycle true")

  -----------------------------------------------------
  -- (10) update() forward progression
  -----------------------------------------------------
  anim.isReversed = false -- ensure forward direction
  r.deltaTime = anim.currentAnimation.frameDuration
  anim.isFirstCycle = true
  anim.currentFrame = anim.currentAnimation.startFrame
  anim.accumulator = 0
  anim:update() -- init cycle
  expect(anim.currentFrame == anim.currentAnimation.startFrame, "update: first cycle sets to startFrame")
  anim:update() -- should advance 1 frame
  expect(anim.currentFrame == anim.currentAnimation.startFrame + 1, "update: advances frame after frameDuration")

  -----------------------------------------------------
  -- (11) update() reversed looping progression
  -----------------------------------------------------
  anim:reverse() -- now reversed
  anim:resetAnimationStart()
  r.deltaTime = anim.currentAnimation.frameDuration
  anim:update() -- init cycle (reversed)
  anim:update() -- step backwards one – should wrap to endFrame
  expect(anim.currentFrame == anim.currentAnimation.endFrame, "update: reversed animation wraps backwards")

  -----------------------------------------------------
  -- (12) Non‑looping animation & onComplete callback
  -----------------------------------------------------
  anim.isReversed = false -- ensure standard direction
  local flag = false
  anim:addAnimation {
    name = "once",
    startFrame = 1,
    endFrame = 3,
    loop = false,
    onComplete = function() flag = true end,
    frameDuration = 0.1,
    speed = 1
  }
  anim:setAnimation("once")
  r.deltaTime = 1.0 -- plenty to finish
  anim:update()     -- init
  anim:update()     -- progress & finish
  expect(anim.currentFrame == 3, "update: non-looping animation ends at endFrame")
  expect(flag == true, "onCompleteCallback: called for non-looping animation")

  -----------------------------------------------------
  -- (13) next‑animation chaining
  -----------------------------------------------------
  local chainFlag = false
  anim:addAnimation { name = "A", startFrame = 1, endFrame = 2, loop = false, next = "B", frameDuration = 0.1, speed = 1 }
  anim:addAnimation { name = "B", startFrame = 1, endFrame = 2, loop = false, onComplete = function() chainFlag = true end, frameDuration = 0.1, speed = 1 }
  anim:setAnimation("A")
  r.deltaTime = 1.0
  anim:update() -- init A
  anim:update() -- finish A -> chain to B
  expect(anim.currentName == "B", "update: next animation chaining from A to B")
  anim:update() -- init B
  anim:update() -- finish B
  expect(chainFlag == true, "update: onComplete called for B if no next")

  -----------------------------------------------------
  -- (14) destroy()
  -----------------------------------------------------
  anim:destroy()
  expect(anim.currentAnimation == nil, "destroy: currentAnimation nil")
  expect(next(anim.animations) == nil, "destroy: animations cleared")
  expect(anim.imagetable == nil, "destroy: imagetable nil")

  -----------------------------------------------------
  -- Finish
  -----------------------------------------------------
  pruneLog()
  for _, line in ipairs(logLines) do print(line) end
  self.done = true
end
