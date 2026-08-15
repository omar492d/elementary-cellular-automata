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
local canvasA, canvasB, activeCanvas

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

   local caWidth = WIDTH - panel.width
   canvasA = love.graphics.newCanvas(caWidth, HEIGHT)
   canvasB = love.graphics.newCanvas(caWidth, HEIGHT)
   activeCanvas = canvasA

   --controls
   print("Press R to enable/disable repeating patterns")
   print("Press SPACE to pause")

end

local stepTimer = 0
function love.update(dt)
   if not state.isPaused then
      stepTimer = stepTimer + dt
      local stepInterval = 1 / state.speed
      while stepTimer >= stepInterval do
         if not sim:isComplete() then -- pattern not complete
            sim:step()
            drawRowToCanvas(sim.cells, state.cellSize)
         elseif sim:isComplete() and state.shouldRepeat then -- pattern complete and repeating enabled
            sim:reset()
         else
            sim:nextRule() --Also restarts the run --pattern complete and repeating disabled
         end
         stepTimer = stepTimer - stepInterval
      end
   end
   panel:update(dt, state, sim)
end

function love.draw()
   drawCA()
   panel:draw()
   if DEBUG then
      drawDebugInfo()
   end
end

function drawRowToCanvas(row, cellSize)
   local other = (activeCanvas == canvasA) and canvasB or canvasA
   love.graphics.setCanvas(other)

   local dead = panel.deadColor
   love.graphics.clear(dead[1], dead[2], dead[3], 1)

   love.graphics.setColor(1, 1, 1, 1)
   love.graphics.draw(activeCanvas, 0, -cellSize)  -- shift old content up

   --love.graphics.setBlendMode("alpha")
   love.graphics.setColor(panel.aliveColor)
   for j, cell in ipairs(row) do
      if cell == 1 then
         love.graphics.rectangle("fill", (j-1)*cellSize, HEIGHT - cellSize, cellSize, cellSize)
      end
   end

   love.graphics.setColor(1, 1, 1, 1)
   love.graphics.setCanvas()
   activeCanvas = other
end

function drawCA()
   --[[
   love.graphics.setBackgroundColor(panel.deadColor)
   for i,gen in ipairs(sim.history) do
      for j,cell in ipairs(gen) do
         if cell == 1 then
            love.graphics.setColor(panel.aliveColor)
            love.graphics.rectangle("fill", panel.width + (j - 1) * state.cellSize, (i - 1) * state.cellSize, state.cellSize, state.cellSize)
         end
      end
   end
   ]]
   --love.graphics.setBlendMode("alpha", "premultiplied")
   love.graphics.setColor(1, 1, 1, 1)
   love.graphics.draw(activeCanvas, panel.width, 0)
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