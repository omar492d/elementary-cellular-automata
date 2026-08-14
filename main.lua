local panel = require("panel")
local util = require("utilities")
local Simulation = require("simulation")

local DEBUG = false --Set to true to overlay FPS, generation, rule and history length

WIDTH = 1280
HEIGHT = 720

--View and playback state. The cellular automaton itself lives in `sim`.
state = {
   cellSize = 2, --Size of each cell in pixels
   isPaused = false,
   shouldRepeat = false,
   speed = 120
}

local sim

function love.load()
   math.randomseed(os.time())
   love.window.setMode(WIDTH, HEIGHT)

   panel.height = HEIGHT
   love.graphics.setBackgroundColor(15/255, 25/255, 35/255)

   sim = Simulation.new{
      rowSize = getRowSize(),
      maxGenerations = getMaxGenerations(),
      ruleNumber = 30,
      initMode = "center",
      scrolling = true
   }
   if DEBUG then
      util.printTable(sim.ruleSet)
   end

   local callbacks = {onFill = onFill, onPause = onPause, onReset = onReset,
                     onNextRule = onNextRule, onPreviousRule = onPreviousRule,
                     onCellChange = changeCellSize,
                     onInitMode = onInitMode, onRuleInput = onRuleInput}
   panel:setCallbacks(callbacks)

   --controls
   print("Press R to enable/disable repeating patterns")
   print("Press SPACE to pause")

end

function love.update(dt)
   if not state.isPaused then
      if not sim:isComplete() then
         sim:step()
      elseif state.shouldRepeat then
         sim:reset()
      else
         sim:nextRule() --Also restarts the run
      end
   end
   panel:update(dt, state, sim)

   local min_dt = 1/state.speed
   if dt < min_dt then
         love.timer.sleep(min_dt - dt)
   end
end

function love.draw()
   drawCA()
   panel:draw()
   if DEBUG then
      drawDebugInfo()
   end
end

function love.keypressed(key)
   if key == "space" then
      state.isPaused = not state.isPaused
   elseif key == "r" then
      state.shouldRepeat = not state.shouldRepeat
   elseif key == "s" then
      sim.scrolling = not sim.scrolling
   elseif key == "left" then
      onPreviousRule()
   elseif key == "right" then
      onNextRule()
   elseif key == "up" then
      changeCellSize(state.cellSize + 1)
   elseif key == "down" then
      changeCellSize(state.cellSize - 1)
   end

   if key == "escape" then
      love.event.quit()
   end
   panel:keypressed(key)
end

function love.textinput(t)
   panel:textinput(t)
end

function drawDebugInfo()
   love.graphics.setColor(0,0,0)
   love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
   love.graphics.print("Generation: "..sim.generation, 10, 20)
   love.graphics.print("Rule: "..sim.ruleNumber, 10, 30)
   love.graphics.print("History length: ".. #sim.history, 10, 40)
end

function drawCA()
   love.graphics.setBackgroundColor(panel.deadColor)
   for i,gen in ipairs(sim.history) do
      for j,cell in ipairs(gen) do
         if cell == 1 then
            love.graphics.setColor(panel.aliveColor)
            love.graphics.rectangle("fill", panel.width + (j - 1) * state.cellSize, (i - 1) * state.cellSize, state.cellSize, state.cellSize)
         end
      end
   end
end

--How many cells fit in one row, and how many rows fit on screen
function getRowSize()
   return math.floor((WIDTH - panel.width) / state.cellSize)
end

function getMaxGenerations()
   return math.floor(HEIGHT / state.cellSize)
end

--callbacks
function onPause()
   state.isPaused = not state.isPaused
end

function onFill()
   if state.isPaused then
      sim:fillScreen()
   end
end

function onReset()
   sim:reset()
end

function onRuleInput(rule)
   sim:setRule(rule)
   sim:reset()
end

function onPreviousRule()
   sim:previousRule()
end

function onNextRule()
   sim:nextRule()
end

function onInitMode(initMode)
   sim:setInitMode(initMode)
end

function changeCellSize(size)
   state.cellSize = util.clamp(size, 1, 10)
   sim:resize(getRowSize(), getMaxGenerations())
end
