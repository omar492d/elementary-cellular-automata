local panel = require("panel")
local util = require("utilities")

local DEBUG = false --Set to true to overlay FPS, generation, rule and history length

WIDTH = 1280
HEIGHT = 720
state = {
   cellSize = 2, --Size of each cell in pixels,
   generation = 1,
   ruleNumber = 30, --Current rule being followed
   isPaused = false,
   shouldRepeat = false,
   speed = 120,
   initMode = "center",
   ruleSet = {0,0,0,1,1,1,1,0}, --Current rule represented in binary
   initialState = {}, --Stores the very first generation
   cells = {}, --Represents a single generation of cells
   history = {} --2D array, stores all the previous generations
}

function love.load()
   math.randomseed(os.time())
   love.window.setMode(WIDTH, HEIGHT)

   panel.height = HEIGHT
   love.graphics.setBackgroundColor(15/255, 25/255, 35/255)
   initializeCells()
   table.insert(state.history, state.cells)
   state.ruleSet = util.toBinary(state.ruleNumber, #state.ruleSet)
   util.printTable(util.toBinary(state.ruleNumber, #state.ruleSet))

   local callbacks = {onStep = onStep, onPause = onPause, onReset = resetSimulation,
                     onNextRule = onNextRule, onPreviousRule = onPreviousRule,
                     onCellChange = changeCellSize,
                     onInitializeCells = initializeCells, onRuleInput = onRuleInput}
   panel:setCallbacks(callbacks)

   --controls
   print("Press R to enable/disable repeating patterns")
   print("Press SPACE to pause")
   
end

function love.update(dt)
   local max = math.floor(HEIGHT / state.cellSize)
   if not state.isPaused then
      if state.generation <= max then
         state.cells = nextGeneration(state.cells)
         table.insert(state.history, state.cells)
         state.generation = state.generation + 1
      else
         if not state.shouldRepeat then
            state.ruleNumber = (state.ruleNumber + 1) % 256
            state.ruleSet = util.toBinary(state.ruleNumber, #state.ruleSet)
         end
         state.generation = 1
         state.cells = util.shallow_copy(state.initialState)
         state.history = {util.shallow_copy(state.cells)}
      end
   end
   panel:update(dt, state)

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

function changeCellSize(size)
   state.cellSize = util.clamp(size, 1, 10)
   initializeCells()
end

function drawDebugInfo()
   love.graphics.setColor(0,0,0)
   love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
   love.graphics.print("Generation: "..state.generation, 10, 20)
   love.graphics.print("Rule: "..state.ruleNumber, 10, 30)
   love.graphics.print("History length: ".. #state.history, 10, 40)
end

function drawCA()
   love.graphics.setBackgroundColor(panel.deadColor)
   for i,gen in ipairs(state.history) do
      for j,cell in ipairs(gen) do
         if state.history[i][j] == 1 then
            love.graphics.setColor(panel.aliveColor)
            love.graphics.rectangle("fill", panel.width + (j - 1) * state.cellSize, (i - 1) * state.cellSize, state.cellSize, state.cellSize)
         end
      end
   end
end

function initializeCells()
   if state.initMode == "center" then
      state.initialState = initCenter()
   elseif state.initMode == "random" then
      state.initialState = initRandom()
   elseif state.initMode == "aliveEnds" then
      state.initialState = initAliveEnds()
   elseif state.initMode == "custom" then
      state.initialState = initCustom()
   elseif state.initMode == "alternate" then
      state.initialState = initAlternate()
   elseif state.initMode == "sineWave" then
      state.initialState = initSineWave()
   elseif state.initMode == "halfHalf" then
      state.initialState = initHalfHalf()
   elseif state.initMode == "tangent" then
      state.initialState = initTangentWave()
    end
    resetSimulation()
end

function initCenter() 
   local cells = {}
   local rowSize = getRowSize()
   for i=1,rowSize do
      table.insert(cells, 0)
   end
   cells[math.floor(rowSize/2)] = 1;
   return cells
end

function initRandom()
   local cells = {}
   local rowSize = getRowSize()
   for i=1,rowSize do
      table.insert(cells, math.random(0, 1))
   end
   return cells
end

function initAliveEnds()
   local cells = {}
   local rowSize = getRowSize()
   for i=1,rowSize do
      table.insert(cells, 0)
   end
   cells[1] = 1
   cells[2] = 1
   cells[rowSize] = 1
   cells[rowSize-1] = 1
   return cells
end

function initCustom()
   --TODO
   local cells = {}
   return cells
end

function initAlternate()
   local cells = {}
   local rowSize = getRowSize()
   for i=1,rowSize do
      if i % 2 == 0 then
         table.insert(cells, 0)
      else
         table.insert(cells, 1)
      end
   end
   return cells
end

function initSineWave()
   local cells = {}
   local rowSize = getRowSize()
   for i=1,rowSize do
      if math.sin(i) > 0 then
         table.insert(cells, 1)
      else
         table.insert(cells, 0)
      end
   end
   return cells
end

function initHalfHalf()
   local cells = {}
   local rowSize = getRowSize()
   local mid = math.floor(rowSize/2)
   for i=1,rowSize do
      if i <= mid then
         table.insert(cells, 1)
      else
         table.insert(cells, 0)
      end
   end
   return cells
end

function initTangentWave()
   local cells = {}
   local rowSize = getRowSize()
   for i=1,rowSize do
      if math.tan(i) > 0 then
         table.insert(cells, 1)
      else
         table.insert(cells, 0)
      end
   end
   return cells
end

function rules(left, mid, right)
   --From Nature of Code by Daniel Shiffman

   --Negihborhood can be regarded as 3-bit number
   local binary = left .. mid .. right
   local index = tonumber(binary, 2)
   return state.ruleSet[8 - index] --Ruleset array convention: from 111 to 000; 
                                   --e.g. in 01100010, 111 maps to 0; 110 maps to 1; 000 maps to 0
end

--Applies the rules to a single generation, and returns the new generation
function nextGeneration(currGen)
   local nextGen = util.shallow_copy(currGen)
   local rowSize = getRowSize()
   nextGen[1] = rules(currGen[rowSize], currGen[1], currGen[2])
   nextGen[rowSize] = rules(currGen[rowSize-1], currGen[rowSize], currGen[1])
   for i=2,rowSize-1 do
      local left = currGen[i - 1]
      local mid = currGen[i]
      local right = currGen[i + 1]
      nextGen[i] = rules(left, mid, right)
   end
   return nextGen
end

--callbacks
function onPause()
   state.isPaused = not state.isPaused
end

function onStep()
   local max = math.floor(HEIGHT / state.cellSize)
   if state.isPaused then
      while state.generation <= max do
         state.cells = nextGeneration(state.cells)
         table.insert(state.history, state.cells)
         state.generation = state.generation + 1
      end
   end
end

function resetSimulation()
   state.cells = util.shallow_copy(state.initialState)
   state.history = {util.shallow_copy(state.cells)}
   state.generation = 1
end

function onRuleInput(rule) 
   resetSimulation()
   state.ruleNumber = rule
   state.ruleSet = util.toBinary(state.ruleNumber, #state.ruleSet)
end

function onPreviousRule()
   resetSimulation()
   state.ruleNumber = (state.ruleNumber - 1 + 256) % 256
   state.ruleSet = util.toBinary(state.ruleNumber, #state.ruleSet)
end

function onNextRule()
   resetSimulation()
   state.ruleNumber = (state.ruleNumber + 1) % 256
   state.ruleSet = util.toBinary(state.ruleNumber, #state.ruleSet)
end

function getRowSize()
   return math.floor((WIDTH - panel.width) / state.cellSize)
end


