local util = {}

--- Return a shallow copy of a table.
function util.shallow_copy(original_table)
   local new_table = {}
   for k, v in pairs(original_table) do
      new_table[k] = v
   end
   return new_table
end

--- Convert a nonnegative integer to a zero-padded array of binary digits.
function util.toBinary(num, bits) 
   local binary = ""
   while num > 0 do
      binary = num % 2 .. binary
      num = math.floor(num / 2)
   end
   if bits > #binary then
      local padding = bits - #binary
      binary = string.rep("0", padding) .. binary
   end
   return util.strToTable(binary)

end

--- Convert a string of digits into an array of numbers.
function util.strToTable(str)
   local list = {}
   for i=1,#str do
      list[i] = tonumber(string.sub(str,i, i))
   end
   return list
end

--- Print an array in a compact bracketed format.
function util.printTable(tbl)
   local endString = ""
   for i,v in ipairs(tbl) do
      endString = endString .. v .. ", "
   end
   endString = "[" .. endString .. "]"
   print(endString)
end

--- Restrict a value to the inclusive low-to-high range.
function util.clamp(value, low, high)
   return math.max(low, math.min(value, high))
end

--- Draw coordinate labels for the current window dimensions.
function util.createRuler()
   local value = 0
   while value < HEIGHT do
      love.graphics.print(tostring(value), 200, value)
      value = value + 10
   end

   love.graphics.push()
   love.graphics.scale(0.75, 1)
   value = 0
   while value < WIDTH do
      love.graphics.print(tostring(value), value * 4/3, 0)
      value = value + 20
   end
   love.graphics.pop()
end

return util