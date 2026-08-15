local suit = require("suit")
suit.theme.color.normal.fg = {0, 0, 0}

--Colour presets, written as 0-255 channels to match the RGB sliders.
--Laid out PRESET_COLUMNS to a row.
local PRESET_COLUMNS = 3
local PRESETS = {
	{name = "Classic",  alive = {0, 0, 0},         dead = {255, 255, 255}},
	{name = "Green",    alive = {100, 255, 120},   dead = {5, 15, 5}},
	{name = "Cyan",     alive = {0, 200, 255},     dead = {10, 15, 25}},
	{name = "Arctic",   alive = {180, 235, 255},   dead = {0, 50, 80}},
	{name = "Hot Pink", alive = {255, 60, 100},    dead = {40, 10, 30}},
	{name = "Gold",     alive = {255, 215, 0},     dead = {0, 0, 0}}
}

--Starting-state button labels. Keyed by the mode keys in Simulation.MODES.
local MODE_COLUMNS = 2
local MODE_LABELS = {
	center = "Center",
	random = "Random",
	aliveEnds = "Alive Ends",
	custom = "Custom",
	alternate = "Alternate",
	sineWave = "Sine Wave",
	halfHalf = "Half/Half",
	tangent = "Tangent"
}

local Panel = {
	x = 0, y = 0,
	width = 200, height = 0, --height will be set in main.lua
	visible = true,
	editingAliveColor = true,
	callbacks = {},
	inputBox = {text = ""},
	speedSlider = {value = 120, min = 1, max = 120, step=30},
	cellSlider = {value = 4, min = 1, max = 10, step = 1},
	aliveColor = {100/255,180/255,220/255},
	deadColor = {15/255,20/255,35/255},
	rSlider = {value=100, min=0, max=255}, --rgb sliders should begin with alive color
	gSlider = {value=180, min=0, max=255},
	bSlider = {value=220, min=0, max=255},
	dividingLineCoords = {}
}

--Pulls the RGB sliders back in line with whichever colour is being edited
function Panel:syncSlidersToColor()
	local c = self.editingAliveColor and self.aliveColor or self.deadColor
	self.rSlider.value = c[1] * 255
	self.gSlider.value = c[2] * 255
	self.bSlider.value = c[3] * 255
end

function Panel:applyPreset(preset)
	self.aliveColor = {preset.alive[1]/255, preset.alive[2]/255, preset.alive[3]/255}
	self.deadColor = {preset.dead[1]/255, preset.dead[2]/255, preset.dead[3]/255}
	self:syncSlidersToColor()
end

function Panel:draw()
	love.graphics.setColor(204/255, 204/255, 204/255)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	suit.draw()

	love.graphics.setColor(0,0,0)
	love.graphics.line(0, self.dividingLineCoords[2], self.width, self.dividingLineCoords[2])
	love.graphics.line(0, self.dividingLineCoords[4], self.width, self.dividingLineCoords[4])
	love.graphics.line(0, self.dividingLineCoords[6], self.width, self.dividingLineCoords[6])
	love.graphics.line(0, self.dividingLineCoords[8], self.width, self.dividingLineCoords[8])
	
end

function Panel:update(dt, state, sim)
	self.dividingLineCoords = {}
	suit.layout:reset(30, 20)
	suit.layout:padding(10, 10)

	local playLabel = state.isPaused and "Play" or "Pause"
	if suit.Button(playLabel, suit.layout:row(140, 30)).hit then
		self.callbacks.onPause()
	end
	if suit.Button("Reset", suit.layout:row(140, 30)).hit then
		self.callbacks.onReset()
	end
	if suit.Button("Fill", suit.layout:row(140, 30)).hit then
		self.callbacks.onFill()
	end
	local x, y = suit.layout:nextRow()
	table.insert(self.dividingLineCoords, x)
	table.insert(self.dividingLineCoords, y)

	suit.Label("Rule: "..sim.ruleNumber, suit.layout:row(140, 30))
	suit.layout:padding(0, 0)

	suit.layout:row(45, 30)
	if suit.Input(self.inputBox, suit.layout:col(50, 30)).submitted then
		print("submitted: " .. self.inputBox.text)
		local rule = tonumber(self.inputBox.text)
		if rule then
			rule = math.floor(rule)
			if rule >= 0 and rule <= 255 then
				self.callbacks.onRuleInput(rule)
			end
		end
	end
	suit.layout:left(45)
	suit.layout:padding(10,10)

	if suit.Button("Previous", suit.layout:row(65, 30)).hit then
	 	self.callbacks.onPreviousRule()
	 end
	if suit.Button("Next", suit.layout:col(65, 30)).hit then
		self.callbacks.onNextRule()
	end
	suit.layout:left()
	x, y = suit.layout:nextRow()
	table.insert(self.dividingLineCoords, x)
	table.insert(self.dividingLineCoords, y)

	suit.Label("Speed:", suit.layout:row(140, 20))
	if suit.Slider(self.speedSlider, suit.layout:row(140, 20)).changed then
		state.speed = self.speedSlider.value
	end
	suit.layout:padding(0,0)
	suit.Label(tostring(math.floor(self.speedSlider.value)), {align="left"}, suit.layout:col(110, 20))
	suit.layout:left(140, 20)

	suit.Label("Cell Size:", suit.layout:row(140, 20))
	self.cellSlider.value = state.cellSize
	if suit.Slider(self.cellSlider, suit.layout:row(140, 20)).changed then
		self.cellSlider.value = math.floor(self.cellSlider.value)
		self.callbacks.onCellChange(self.cellSlider.value)
		self.callbacks.onFill()
	end
	suit.Label(tostring(math.floor(state.cellSize)), {align="left"}, suit.layout:col(110, 20))
	suit.layout:left(140, 20)

	x, y = suit.layout:nextRow()
	table.insert(self.dividingLineCoords, x)
	table.insert(self.dividingLineCoords, y)

	suit.Label("Colors", suit.layout:row(140, 30))
	local editLabel = self.editingAliveColor and "Editing: Alive" or "Editing: Dead"
	if suit.Button(editLabel, suit.layout:row(140, 30)).hit then
		self.editingAliveColor = not self.editingAliveColor
		self:syncSlidersToColor()
	end
	suit.Slider(self.rSlider, suit.layout:row(140, 20))
	suit.Label(tostring(math.floor(self.rSlider.value)), {align="left"}, suit.layout:col(110, 20))
	suit.layout:left(140, 20)

	suit.Slider(self.gSlider, suit.layout:row(140, 20))
	suit.Label(tostring(math.floor(self.gSlider.value)), {align="left"}, suit.layout:col(110, 20))
	suit.layout:left(140, 20)

	suit.Slider(self.bSlider, suit.layout:row(140, 20))
	suit.Label(tostring(math.floor(self.bSlider.value)), {align="left"}, suit.layout:col(110, 20))
	suit.layout:left(140, 20)

	local color = self.editingAliveColor and self.aliveColor or self.deadColor
	color[1] = self.rSlider.value/255
	color[2] = self.gSlider.value/255
	color[3] = self.bSlider.value/255

	x, y = suit.layout:nextRow()
	suit.layout:reset(10, y+10)
	suit.layout:padding(3,5)
	for i, preset in ipairs(PRESETS) do
		local column = (i - 1) % PRESET_COLUMNS
		local hit
		if column == 0 then
			hit = suit.Button(preset.name, suit.layout:row(58, 30)).hit
		else
			hit = suit.Button(preset.name, suit.layout:col(58, 30)).hit
		end
		if hit then
			self:applyPreset(preset)
		end
		--Step back to the start of the row, once per column added to it
		if column == PRESET_COLUMNS - 1 or i == #PRESETS then
			for _ = 1, column do
				suit.layout:left()
			end
		end
	end

	x, y = suit.layout:nextRow()
	table.insert(self.dividingLineCoords, x)
	table.insert(self.dividingLineCoords, y)

	suit.Label("Starting State", {align="center"}, suit.layout:row(180, 30))
	suit.layout:padding(10, 5)
	for i, mode in ipairs(sim.MODES) do
		local modeLabel = MODE_LABELS[mode.key] or mode.key
		if sim.initMode == mode.key then
			modeLabel = "> " .. modeLabel
		end
		local column = (i - 1) % MODE_COLUMNS
		local hit
		if column == 0 then
			hit = suit.Button(modeLabel, suit.layout:row(85, 25)).hit
		else
			hit = suit.Button(modeLabel, suit.layout:col(85, 25)).hit
		end
		if hit then
			self.callbacks.onInitMode(mode.key)
		end
		if column == MODE_COLUMNS - 1 or i == #sim.MODES then
			for _ = 1, column do
				suit.layout:left()
			end
		end
	end
	love.graphics.rectangle("fill", 60, 100, 200, 250)
end

function Panel:setCallbacks(callbacks)
	self.callbacks = callbacks
end

function Panel:keypressed(key)
	suit.keypressed(key)
end

function Panel:textinput(t)
	suit.textinput(t)
end

return Panel