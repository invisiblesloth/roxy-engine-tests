-- source/main.lua

local pd <const> = playdate

-- (1) Initialize the Roxy game engine
import "libraries/roxy/roxy"

pd.display.setRefreshRate(30)

-- (2) Launch the game
roxy.new()
