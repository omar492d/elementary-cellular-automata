local util = require("utilities")

local Simulation = {}
Simulation.__index = Simulation

local RULE_COUNT = 256 --Elementary CA rules are numbered 0..255
local RULE_BITS = 8    --One bit per possible 3-cell neighborhood

--Starting-state generators. Each takes the row size and returns a new row.
local function initCenter(rowSize)
   local cells = {}
   for i=1,rowSize do
      table.insert(cells, 0)
   end
   cells[math.floor(rowSize/2)] = 1
   return cells
end

local function initRandom(rowSize)
   local cells = {}
   for i=1,rowSize do
      table.insert(cells, math.random(0, 1))
   end
   return cells
end

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

--TODO: let the user paint this row directly; for now it is a blank canvas
local function initCustom(rowSize)
   local cells = {}
   for i=1,rowSize do
      table.insert(cells, 0)
   end
   return cells
end

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

--opts: rowSize, maxGenerations, ruleNumber, initMode
function Simulation.new(opts)
   local sim = setmetatable({
      rowSize = opts.rowSize,
      maxGenerations = opts.maxGenerations,
      initMode = opts.initMode,
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

function Simulation:setRule(ruleNumber)
   self.ruleNumber = ruleNumber % RULE_COUNT
   self.ruleSet = util.toBinary(self.ruleNumber, RULE_BITS)
end

--Advancing the rule restarts the run, so the new rule is drawn from the top
function Simulation:nextRule()
   self:setRule(self.ruleNumber + 1)
   self:reset()
end

function Simulation:previousRule()
   self:setRule(self.ruleNumber - 1 + RULE_COUNT)
   self:reset()
end

function Simulation:setInitMode(initMode)
   self.initMode = initMode
   self:initialize()
end

--Called when the cell size changes, since that changes how many cells fit
function Simulation:resize(rowSize, maxGenerations)
   self.rowSize = rowSize
   self.maxGenerations = maxGenerations
   self:initialize()
end

--Builds a fresh starting row for the current mode, then restarts the run
function Simulation:initialize()
   local rowSize = self.rowSize
   if self.initMode == "center" then
      self.initialState = initCenter(rowSize)
   elseif self.initMode == "random" then
      self.initialState = initRandom(rowSize)
   elseif self.initMode == "aliveEnds" then
      self.initialState = initAliveEnds(rowSize)
   elseif self.initMode == "custom" then
      self.initialState = initCustom(rowSize)
   elseif self.initMode == "alternate" then
      self.initialState = initAlternate(rowSize)
   elseif self.initMode == "sineWave" then
      self.initialState = initSineWave(rowSize)
   elseif self.initMode == "halfHalf" then
      self.initialState = initHalfHalf(rowSize)
   elseif self.initMode == "tangent" then
      self.initialState = initTangentWave(rowSize)
   end
   self:reset()
end

--Restarts from the stored starting row, keeping the current rule
function Simulation:reset()
   self.cells = util.shallow_copy(self.initialState)
   self.history = {self.cells}
   self.generation = 1
end

function Simulation:isComplete()
   return self.generation > self.maxGenerations
end

--Looks up one neighborhood. The neighborhood is a 3-bit number, and ruleSet
--runs from 111 down to 000; e.g. in 01100010, 111 maps to 0 and 110 maps to 1.
--From Nature of Code by Daniel Shiffman.
function Simulation:rule(left, mid, right)
   local index = tonumber(left .. mid .. right, 2)
   return self.ruleSet[RULE_BITS - index]
end

--Applies the rule to a single generation and returns the new generation.
--Edges wrap around.
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

--Advances one generation. history stores the same table as cells, which is
--safe because nextGeneration always returns a fresh one.
function Simulation:step()
   self.cells = self:nextGeneration(self.cells)
   table.insert(self.history, self.cells)
   self.generation = self.generation + 1
end

--Runs out the remaining generations in one go
function Simulation:runToEnd()
   while not self:isComplete() do
      self:step()
   end
end

return Simulation
