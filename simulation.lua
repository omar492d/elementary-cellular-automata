local util = require("utilities")

local Simulation = {}
Simulation.__index = Simulation

local RULE_COUNT = 256 --Elementary CA rules are numbered 0..255
local RULE_BITS = 8    --One bit per possible 3-cell neighborhood

--- Build a row with one live cell at its center.
local function initCenter(rowSize)
   local cells = {}
   for i=1,rowSize do
      table.insert(cells, 0)
   end
   cells[math.floor(rowSize/2)] = 1
   return cells
end

--- Build a row with randomly selected live cells.
local function initRandom(rowSize)
   local cells = {}
   for i=1,rowSize do
      table.insert(cells, math.random(0, 1))
   end
   return cells
end

--- Build a row with two live cells at each end.
local function initAliveEnds(rowSize)
   local cells = {}
   for i=1,rowSize do
      table.insert(cells, 0)
   end
   cells[1] = 1
   cells[2] = 1
   cells[rowSize] = 1
   cells[rowSize-1] = 1
   return cells
end

--- Build an empty row for a custom starting pattern.
local function initCustom(rowSize)
   local cells = {}
   for i=1,rowSize do
      table.insert(cells, 0)
   end
   return cells
end

--- Build an alternating row with every other cell alive.
local function initAlternate(rowSize)
   local cells = {}
   for i=1,rowSize do
      if i % 2 == 0 then
         table.insert(cells, 0)
      else
         table.insert(cells, 1)
      end
   end
   return cells
end

--- Build a row from the positive portions of a sine wave.
local function initSineWave(rowSize)
   local cells = {}
   for i=1,rowSize do
      if math.sin(i) > 0 then
         table.insert(cells, 1)
      else
         table.insert(cells, 0)
      end
   end
   return cells
end

--- Build a row with its left half alive and right half empty.
local function initHalfHalf(rowSize)
   local cells = {}
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

--- Build a row from the positive portions of a tangent wave.
local function initTangentWave(rowSize)
   local cells = {}
   for i=1,rowSize do
      if math.tan(i) > 0 then
         table.insert(cells, 1)
      else
         table.insert(cells, 0)
      end
   end
   return cells
end

--Every starting state, in the order the panel lists them. pairs() has no defined
--iteration order, so an array is what keeps the button order stable. Adding a
--pattern here is all that is needed to expose it in the panel.
Simulation.MODES = {
   {key = "center",    generate = initCenter},
   {key = "random",    generate = initRandom},
   {key = "aliveEnds", generate = initAliveEnds},
   {key = "custom",    generate = initCustom},
   {key = "alternate", generate = initAlternate},
   {key = "sineWave",  generate = initSineWave},
   {key = "halfHalf",  generate = initHalfHalf},
   {key = "tangent",   generate = initTangentWave}
}

--Lookup by mode, built from the list above so the two cannot drift apart
local generatorFor = {}
for _, mode in ipairs(Simulation.MODES) do
   generatorFor[mode.key] = mode.generate
end

--- Create a simulation from its grid dimensions, rule, and initial mode.
function Simulation.new(opts)
   local sim = setmetatable({
      rowSize = opts.rowSize,
      maxGenerations = opts.maxGenerations,
      initMode = opts.initMode,
      scrolling = opts.scrolling,
      ruleNumber = 0,
      ruleSet = {},      --Current rule in binary, most significant bit first
      generation = 1,
      initialState = {}, --The very first generation
      cells = {},        --The current generation
      history = {}       --2D array, every generation produced so far
   }, Simulation)
   sim:setRule(opts.ruleNumber)
   sim:initialize()
   return sim
end

--- Normalize a rule number and store its eight-bit representation.
function Simulation:setRule(ruleNumber)
   self.ruleNumber = ruleNumber % RULE_COUNT
   self.ruleSet = util.toBinary(self.ruleNumber, RULE_BITS)
end

--- Advance to the next rule and restart from the initial row.
function Simulation:nextRule()
   self:setRule(self.ruleNumber + 1)
   self:reset()
end

--- Move to the previous rule and restart from the initial row.
function Simulation:previousRule()
   self:setRule(self.ruleNumber - 1 + RULE_COUNT)
   self:reset()
end

--- Select an initial pattern and rebuild the starting row.
function Simulation:setInitMode(initMode)
   self.initMode = initMode
   self:initialize()
end

--- Update grid dimensions and regenerate the starting row.
function Simulation:resize(rowSize, maxGenerations)
   self.rowSize = rowSize
   self.maxGenerations = maxGenerations
   self:initialize()
end

--- Generate the initial row for the selected mode and reset the run.
function Simulation:initialize()
   local generate = generatorFor[self.initMode]
   if generate then
      self.initialState = generate(self.rowSize)
   end
   self:reset()
end

--- Restart from the stored initial row without changing the current rule.
function Simulation:reset()
   self.cells = util.shallow_copy(self.initialState)
   self.history = {self.cells}
   self.generation = 1
end

--- Report whether a non-scrolling run has filled the visible height.
function Simulation:isComplete()
   return not self.scrolling and self.generation > self.maxGenerations
end

--- Look up the rule output for a three-cell neighborhood.
function Simulation:rule(left, mid, right)
   local index = tonumber(left .. mid .. right, 2)
   return self.ruleSet[RULE_BITS - index]
end

--- Apply the rule to a row, wrapping neighborhoods across both edges.
function Simulation:nextGeneration(currGen)
   local nextGen = util.shallow_copy(currGen)
   local rowSize = self.rowSize
   nextGen[1] = self:rule(currGen[rowSize], currGen[1], currGen[2])
   nextGen[rowSize] = self:rule(currGen[rowSize-1], currGen[rowSize], currGen[1])
   for i=2,rowSize-1 do
      local left = currGen[i - 1]
      local mid = currGen[i]
      local right = currGen[i + 1]
      nextGen[i] = self:rule(left, mid, right)
   end
   return nextGen
end

--- Advance one generation and append its fresh cell row to history.
function Simulation:step()
   self.cells = self:nextGeneration(self.cells)
   table.insert(self.history, self.cells)
   if (self.scrolling and #self.history > self.maxGenerations) then
      table.remove(self.history, 1)
   end
   self.generation = self.generation + 1
end

--- Fill available history rows and optionally report each newly generated row.
function Simulation:fillScreen(onStep)
   while #self.history < self.maxGenerations do
      self:step()
      if onStep then
         onStep(self.cells)
      end
   end
end

return Simulation
