-- tests/physics/physics_roxyphysicsbody_spec.lua

dofile("tests/spec_helper.lua")

describe("RoxyPhysicsBody", function()
  local RoxyPhysicsBody, owner, body, collisionsReceived

  before_each(function()
    -- reload module so tests are isolated
    package.loaded["core.physics.RoxyPhysicsBody"] = nil
    import("core.physics.RoxyPhysicsBody")
    RoxyPhysicsBody = _G.RoxyPhysicsBody

    -- stub owner sprite with position and moveWithCollisions
    owner = { x = 5, y = 10 }
    collisionsReceived = nil
    function owner:moveWithCollisions(tx, ty)
      -- record attempted move
      self._movedTo = { tx, ty }
      return tx, ty, collisionsReceived or {}
    end

    -- create body with initial velocities and custom gravity & collision callback
    body = RoxyPhysicsBody(owner, {
      vx = 1, vy = 2,
      gravity = 9,
      onCollision = function(c) body.collided = c end
    })
  end)

  it("initializes fields correctly", function()
    assert.equals(owner, body.owner)
    assert.equals(1, body.vx)
    assert.equals(2, body.vy)
    assert.equals(0, body.ax)
    assert.equals(9, body.ay)
    assert.is_false(body.onGround)
    assert.is_function(body.onCollision)
  end)

  it("update integrates velocities and moves owner", function()
    body.ax = 3
    roxy.deltaTime = 0.5
    body:update(roxy.deltaTime)
    -- expected velocities after integration
    assert.equals(1 + 3 * 0.5, body.vx)
    assert.equals(2 + 9 * 0.5, body.vy)
    -- owner moved to new position
    local nx = 5 + body.vx * 0.5
    local ny = 10 + body.vy * 0.5
    assert.same({ nx, ny }, owner._movedTo)
  end)

  it("applies friction when onGround", function()
    body.onGround = true
    body.friction = 2      -- friction force per second
    body.vx = 1
    roxy.deltaTime = 1
    body:update(roxy.deltaTime)
    -- frictionForce = 2*1*sign = 2 > vx(1) so vx zeroes out
    assert.equals(0, body.vx)
  end)

  it("handles floor collision (normal.y < -limit)", function()
    collisionsReceived = { { normal = { x = 0, y = -1 } } }
    body.vy = 5
    roxy.deltaTime = 0.1
    body:update(roxy.deltaTime)
    assert.is_true(body.onGround)
    assert.equals(0, body.vy)
  end)

  it("handles ceiling collision (normal.y > limit)", function()
    collisionsReceived = { { normal = { x = 0, y = 1 } } }
    body.vy = -5
    roxy.deltaTime = 0.1
    body:update(roxy.deltaTime)
    assert.is_false(body.onGround)
    assert.equals(0, body.vy)
  end)

  it("handles wall collision (|normal.x| > limit)", function()
    collisionsReceived = { { normal = { x = 1, y = 0 } } }
    body.vx = 5
    roxy.deltaTime = 0.1
    body:update(roxy.deltaTime)
    assert.equals(0, body.vx)
  end)

  it("invokes onCollision callback for each collision", function()
    local called = nil
    -- callback signature: first arg is self, second is the collision
    body.onCollision = function(self_, c)
      called = c
    end
  
    local col = { normal = { x = 0, y = -1 } }
    collisionsReceived = { col }
    roxy.deltaTime = 0.1
    body:update(roxy.deltaTime)
  
    assert.equals(col, called)
  end)

  it("clears ax after update", function()
    body.ax = 10
    roxy.deltaTime = 0.1
    body:update(roxy.deltaTime)
    assert.equals(0, body.ax)
  end)
end)
