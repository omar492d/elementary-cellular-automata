local panel = require("panel")
local util = require("utilities")
local Simulation = require("simulation")
--local audio = require("audio")

local DEBUG = false --Set to true to overlay FPS, generation, rule and history length

WIDTH = 1280
HEIGHT = 720

--View and playback state. The cellular automaton itself lives in `sim`.
state = {
   cellSize = 1,
   isPaused = false,
   shouldRepeat = false,
   speed = 120
}

local sim
local canvasA, canvasB, activeCanvas

--- Initialize the window, simulation, render canvases, callbacks, and audio.
function love.load()
   love.window.setTitle("CAPE")

   math.randomseed(os.time())
   love.window.setMode(WIDTH, HEIGHT)

   panel.height = HEIGHT
   love.graphics.setBackgroundColor(15/255, 25/255, 35/255)

   sim = Simulation.new{
      rowSize = getRowSize(),
      maxGenerations = getMaxGenerations(),
      ruleNumber = 30,
      initMode = "center",
      scrolling = false
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

   drawRowToCanvas(sim.cells, state.cellSize)

   --audio:buildDefault()

   print("R - toggle repeating patterns. Disable to have changing rules when pattern completes")
   print("SPACE - pause/resume")
   print("S - toggle scrolling. Disable to see the entire pattern at once")
   print("LEFT/RIGHT - previous/next rule")
   print("UP/DOWN - increase/decrease cell size")

end

local stepTimer = 0
--- Advance the simulation at its configured rate and update the panel.
function love.update(dt)
   if not state.isPaused then
      stepTimer = stepTimer + dt
      local stepInterval = 1 / state.speed
      while stepTimer >= stepInterval do
         if not sim:isComplete() then
            sim:step()
            drawRowToCanvas(sim.cells, state.cellSize)
         elseif sim:isComplete() and state.shouldRepeat then
            onReset()
         else
            sim:nextRule() --Also restarts the run --pattern complete and repeating disabled
         end
         stepTimer = stepTimer - stepInterval
      end
   end
   panel:update(dt, state, sim)
end

--- Render the automaton, control panel, and optional debug information.
function love.draw()
   drawCA()
   panel:draw()
   if DEBUG then
      drawDebugInfo()
   end
end

--- Scroll the existing canvas and append one generation at its bottom edge.
function drawRowToCanvas(row, cellSize)
   local other = (activeCanvas == canvasA) and canvasB or canvasA
   love.graphics.setCanvas(other)

   local dead = panel.deadColor
   love.graphics.clear(dead[1], dead[2], dead[3], 1)

   love.graphics.setColor(1, 1, 1, 1)
   love.graphics.draw(activeCanvas, 0, -cellSize)

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

--- Draw the accumulated automaton canvas beside the control panel.
function drawCA()
   love.graphics.setColor(1, 1, 1, 1)
   love.graphics.draw(activeCanvas, panel.width, 0)
end

--- Render stored generations directly from history as an alternate view.
function drawCaOld() 
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

--- Handle application shortcuts and forward key presses to the panel.
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

--- Forward typed characters to the panel's text input widgets.
function love.textinput(t)
   panel:textinput(t)
end

--- Draw runtime counters when debug output is enabled.
function drawDebugInfo()
   love.graphics.setColor(0,0,0)
   love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
   love.graphics.print("Generation: "..sim.generation, 10, 20)
   love.graphics.print("Rule: "..sim.ruleNumber, 10, 30)
   love.graphics.print("History length: ".. #sim.history, 10, 40)
end

--- Return the number of cells that fit horizontally at the current cell size.
function getRowSize()
   return math.floor((WIDTH - panel.width) / state.cellSize)
end

--- Return the number of generations that fit vertically at the current cell size.
function getMaxGenerations()
   return math.floor(HEIGHT / state.cellSize)
end

--- Toggle whether simulation playback is paused.
function onPause()
   state.isPaused = not state.isPaused
end

--- Fast-forward a paused run while drawing each generated row.
function onFill()
   if state.isPaused then
   -- Preserve existing pixels while rendering the generations added by Fill.
      sim:fillScreen(function(row)
         drawRowToCanvas(row, state.cellSize)
      end)
   end
end

--- Reset the simulation and canvas, then draw the initial generation.
function onReset()
   sim:reset()
   love.graphics.setCanvas(activeCanvas)
   love.graphics.clear(panel.deadColor[1], panel.deadColor[2], panel.deadColor[3], 1)
   love.graphics.setCanvas()
   drawRowToCanvas(sim.cells, state.cellSize)
end

--- Apply a rule entered in the panel and draw its initial generation.
function onRuleInput(rule)
   sim:setRule(rule)
   sim:reset()
   drawRowToCanvas(sim.cells, state.cellSize)
end

--- Select the previous rule and draw its initial generation.
function onPreviousRule()
   sim:previousRule()
   drawRowToCanvas(sim.cells, state.cellSize)
end

--- Select the next rule and draw its initial generation.
function onNextRule()
   sim:nextRule()
   drawRowToCanvas(sim.cells, state.cellSize)
end

--- Change the initial pattern and restart the simulation.
function onInitMode(initMode)
   sim:setInitMode(initMode)
end

--- Clamp the cell size and rebuild the simulation grid dimensions.
function changeCellSize(size)
   state.cellSize = util.clamp(size, 1, 10)
   sim:resize(getRowSize(), getMaxGenerations())
end