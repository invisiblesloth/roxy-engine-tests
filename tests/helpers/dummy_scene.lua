-- tests/helpers/dummy_scene.lua

class('Dummy').extends(RoxyScene)

function Dummy:init(name, opts)
  Dummy.super.init(self)
  self.name             = name or 'Dummy'
  self.alwaysUpdate     = opts and opts.alwaysUpdate
  self.updateBackground = opts and opts.updateBackground
  self.hits             = setmetatable({}, { __index = function() return 0 end })
end

local function bump(self, key) self.hits[key] = self.hits[key] + 1 end

function Dummy:enter()
  Dummy.super.enter(self)
  bump(self, 'enter')
end

function Dummy:pause()
  -- call base first; it returns early if already paused
  local wasPaused = self.isPaused -- store flag
  Dummy.super.pause(self)
  if not wasPaused then -- only bump on first real pause
    bump(self, 'pause')
  end
end

function Dummy:resume()
  local wasPaused = self.isPaused
  Dummy.super.resume(self)
  if wasPaused then -- bump only when a real resume happens
    bump(self, 'resume')
  end
end

function Dummy:exit()
  Dummy.super.exit(self)
  bump(self,'exit')
end

function Dummy:cleanup()
  Dummy.super.cleanup(self)
  bump(self,'cleanup')
end

return Dummy
