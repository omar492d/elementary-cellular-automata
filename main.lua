local panel = require("panel")
local util = require("utilities")

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
--ruleSet = {0,1,0,1,1,0,1,0}

function love.load()
   math.randomseed(os.time())
   love.window.setMode(WIDTH, HEIGHT)

   --local font = love.graphics.newFont()
   --love.graphics.setFont(font)
   --suit.theme.font = font
   --love.graphics.setDefaultFilter("linear", "linear")

   panel.height = HEIGHT
   --love.graphics.setBackgroundColor(255,255,255)
   love.graphics.setBackgroundColor(15/255, 25/255, 35/255)
   --state.cells = initializeCells()
   --state.cells = randomizeCells()
   --state.cells = customCells()
   --state.initialState = util.shallow_copy(state.cells)
   initializeCells()
   table.insert(state.history, state.cells)
   state.ruleSet = util.toBinary(state.ruleNumber, #state.ruleSet)
   util.printTable(util.toBinary(state.ruleNumber, #state.ruleSet))

   local callbacks = {onStep = onStep, onPause = onPause, onReset = resetSimulation,
                     onNextRule = onNextRule, onPreviousRule = onPreviousRule,
                     onCellChange = changeCellSize, onSpeedChange = changeSpeed, 
                     onInitializeCells = initializeCells, onRuleInput = onRuleInput}
   panel:setCallbacks(callbacks)

   --controls
   print("Press R to enable/disable repeating patterns")
   print("Press SPACE to pause")
   
end

function love.update(dt)
   max = math.floor(HEIGHT / state.cellSize)
   if not state.isPaused then
      if state.generation <= max then
         state.cells = nextGeneration(state.cells)
         table.insert(state.history, state.cells)
         state.generation = state.generation + 1
      else
         if not state.shouldRepeat then
            --state.ruleNumber = state.ruleNumber + 1
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
   --love.timer.sleep(0.1)
end

function love.draw()
   --love.graphics.setScissor(panel.width, 0, WIDTH - panel.width, HEIGHT)
   drawCA()
   --love.graphics.setScissor()
   panel:draw()
   local midX = panel.width + (getRowSize() / 2) * state.cellSize
   --love.graphics.line(midX, 0, midX, HEIGHT)
   --love.graphics.line(WIDTH/2 - panel.width, 0, WIDTH/2 - panel.width, HEIGHT)
   --drawDebugInfo()
   --util.createRuler()
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
   --rowSize = math.floor(WIDTH / state.cellSize)
   --rowSize = math.floor((WIDTH - panel.width) / state.cellSize)
   --state.cells = initializeCells()
   --state.initialState = util.shallow_copy(state.cells)
   --state.initialState = initializeCells()
   initializeCells()
   --resetSimulation()
   --state.history = {util.shallow_copy(state.cells)}
   --state.generation = 1
end

function changeSpeed(dt, speed)
   --speed: measured in fps
   local min_dt = 1/speed
   if dt < min_dt then
         love.timer.sleep(min_dt - dt)
   end
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
            --love.graphics.setColor(0, 0, 0)
            --love.graphics.setColor(100/255, 180/255, 220/255)
            love.graphics.setColor(panel.aliveColor)
            love.graphics.rectangle("fill", panel.width + (j - 1) * state.cellSize, (i - 1) * state.cellSize, state.cellSize, state.cellSize)
            --love.graphics.rectangle("fill", (j - 1) * state.cellSize, i * state.cellSize, state.cellSize, state.cellSize)
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

function drawGen(gen)
   local rowSize = getRowSize()
   for i=1,rowSize do
      if gen[i] == 1 or gen[i] == "1" then
         love.graphics.setColor(0, 0, 0)
         love.graphics.rectangle("fill", i * state.cellSize, state.generation, state.cellSize, state.cellSize)
      end
   end
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
      left = currGen[i - 1]
      mid = currGen[i]
      right = currGen[i + 1]
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


