local suit = require("suit")
suit.theme.color.normal.fg = {0, 0, 0}

local Panel = {
	x = 0, y = 0,
	width = 200, height = 0, --height will be set in main.lua
	visible = true,
	editingAliveColor = true,
	callbacks = {},
	inputBox = {text = ""},
	speedSlider = {value = 120, min = 30, max = 120, step=30},
	cellSlider = {value = 4, min = 1, max = 10, step = 1},
	aliveColor = {100/255,180/255,220/255},
	deadColor = {15/255,20/255,35/255},
	rSlider = {value=100, min=0, max=255}, --rgb sliders should begin with alive color
	gSlider = {value=180, min=0, max=255},
	bSlider = {value=220, min=0, max=255},
	dividingLineCoords = {}
}

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

function Panel:update(dt, state)
	self.dividingLineCoords = {}
	suit.layout:reset(30, 20)
	suit.layout:padding(10, 10)

	local label = state.isPaused and "Play" or "Pause"
	if suit.Button(label, suit.layout:row(140, 30)).hit then
		self.callbacks.onPause()
	end
	if suit.Button("Reset", suit.layout:row(140, 30)).hit then
		self.callbacks.onReset()
	end
	if suit.Button("Step", suit.layout:row(140, 30)).hit then
		self.callbacks.onStep()
	end
	local x, y = suit.layout:nextRow()
	table.insert(self.dividingLineCoords, x)
	table.insert(self.dividingLineCoords, y)

	suit.Label("Rule: "..state.ruleNumber, suit.layout:row(140, 30))
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
		self.callbacks.onStep()
	end
	suit.Label(tostring(math.floor(state.cellSize)), {align="left"}, suit.layout:col(110, 20))
	suit.layout:left(140, 20)

	x, y = suit.layout:nextRow()
	table.insert(self.dividingLineCoords, x)
	table.insert(self.dividingLineCoords, y)

	suit.Label("Colors", suit.layout:row(140, 30))
	local label = self.editingAliveColor and "Editing: Alive" or "Editing: Dead"
	if suit.Button(label, suit.layout:row(140, 30)).hit then
		self.editingAliveColor = not self.editingAliveColor
		local c = self.editingAliveColor and self.aliveColor or self.deadColor
    	self.rSlider.value = c[1] * 255
    	self.gSlider.value = c[2] * 255
    	self.bSlider.value = c[3] * 255
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
	if suit.Button("Classic", suit.layout:row(58, 30)).hit then
		self.aliveColor = {0, 0, 0}
		self.deadColor = {1, 1, 1}
		if self.editingAliveColor then
			self.rSlider.value = self.aliveColor[1] * 255
			self.gSlider.value = self.aliveColor[2] * 255
			self.bSlider.value = self.aliveColor[3] * 255
		else
			self.rSlider.value = self.deadColor[1] * 255
			self.gSlider.value = self.deadColor[2] * 255
			self.bSlider.value = self.deadColor[3] * 255
		end
	end
	if suit.Button("Green", suit.layout:col(58, 30)).hit then
	 	self.aliveColor = {100/255, 255/255, 120/255}
		self.deadColor = {5/255, 15/255, 5/255}
		if self.editingAliveColor then
			self.rSlider.value = self.aliveColor[1] * 255
			self.gSlider.value = self.aliveColor[2] * 255
			self.bSlider.value = self.aliveColor[3] * 255
		else
			self.rSlider.value = self.deadColor[1] * 255
			self.gSlider.value = self.deadColor[2] * 255
			self.bSlider.value = self.deadColor[3] * 255
		end
	end
	if suit.Button("Cyan", suit.layout:col(58, 30)).hit then
	 	self.aliveColor = {0, 200/255, 255/255}
		self.deadColor = {10/ 255, 15/255, 25/255}
		if self.editingAliveColor then
			self.rSlider.value = self.aliveColor[1] * 255
			self.gSlider.value = self.aliveColor[2] * 255
			self.bSlider.value = self.aliveColor[3] * 255
		else
			self.rSlider.value = self.deadColor[1] * 255
			self.gSlider.value = self.deadColor[2] * 255
			self.bSlider.value = self.deadColor[3] * 255
		end
	end
	suit.layout:left()
	suit.layout:left()
	if suit.Button("Arctic", suit.layout:row(58, 30)).hit then
		self.aliveColor = {180/255, 235/255, 255/255}
		self.deadColor = {0/255, 50/255, 80/255}
		if self.editingAliveColor then
			self.rSlider.value = self.aliveColor[1] * 255
			self.gSlider.value = self.aliveColor[2] * 255
			self.bSlider.value = self.aliveColor[3] * 255
		else
			self.rSlider.value = self.deadColor[1] * 255
			self.gSlider.value = self.deadColor[2] * 255
			self.bSlider.value = self.deadColor[3] * 255
		end
	end
	if suit.Button("Hot Pink", suit.layout:col(58, 30)).hit then
	 	self.aliveColor = {255/255, 60/255, 100/255}
		self.deadColor = {40/255, 10/255, 30/255}
		if self.editingAliveColor then
			self.rSlider.value = self.aliveColor[1] * 255
			self.gSlider.value = self.aliveColor[2] * 255
			self.bSlider.value = self.aliveColor[3] * 255
		else
			self.rSlider.value = self.deadColor[1] * 255
			self.gSlider.value = self.deadColor[2] * 255
			self.bSlider.value = self.deadColor[3] * 255
		end
	end
	if suit.Button("Gold", suit.layout:col(58, 30)).hit then
		self.aliveColor = {255/255, 215/255, 0/255}
		self.deadColor = {0/ 255, 0/255, 0/255}
		if self.editingAliveColor then
			self.rSlider.value = self.aliveColor[1] * 255
			self.gSlider.value = self.aliveColor[2] * 255
			self.bSlider.value = self.aliveColor[3] * 255
		else
			self.rSlider.value = self.deadColor[1] * 255
			self.gSlider.value = self.deadColor[2] * 255
			self.bSlider.value = self.deadColor[3] * 255
		end
	end
	suit.layout:left()
	suit.layout:left()

	x, y = suit.layout:nextRow()
	table.insert(self.dividingLineCoords, x)
	table.insert(self.dividingLineCoords, y)

	suit.Label("Starting State", {align="center"}, suit.layout:row(180, 30))
	local centerLabel = state.initMode == "center" and "> Center" or "Center"
	local randomLabel = state.initMode == "random" and "> Random" or "Random"
	local aliveEndsLabel = state.initMode == "aliveEnds" and "> Alive Ends" or "Alive Ends"
	local customLabel = state.initMode == "custom" and "> Custom" or "Custom"
	local alternateLabel = state.initMode == "alternate" and "> Alternate" or "Alternate"
	local sineWaveLabel = state.initMode == "sineWave" and "> Sine Wave" or "Sine Wave"
	local halfHalfLabel = state.initMode == "halfHalf" and "> Half/Half" or "Half/Half"
	local tangentLabel = state.initMode == "tangent" and "> Tangent" or "Tangent"
	suit.layout:padding(10, 5)
	if suit.Button(centerLabel, suit.layout:row(85, 25)).hit then
    	state.initMode = "center"
		self.callbacks.onInitializeCells()
	end
	if suit.Button(randomLabel, suit.layout:col(85, 25)).hit then
		state.initMode = "random"
		self.callbacks.onInitializeCells()
	end
	suit.layout:left()

	if suit.Button(aliveEndsLabel, suit.layout:row(85, 25)).hit then
		state.initMode = "aliveEnds"
		self.callbacks.onInitializeCells()
	end
	if suit.Button(customLabel, suit.layout:col()).hit then
		state.initMode = "custom"
		--Deliberately no regeneration: initCustom() is still a stub (see main.lua)
	end
	suit.layout:left()

	if suit.Button(alternateLabel, suit.layout:row(85, 25)).hit then
		state.initMode = "alternate"
		self.callbacks.onInitializeCells()
	end
	if suit.Button(sineWaveLabel, suit.layout:col()).hit then
		state.initMode = "sineWave"
		self.callbacks.onInitializeCells()
	end
	suit.layout:left()

	if suit.Button(halfHalfLabel, suit.layout:row(85, 25)).hit then
		state.initMode = "halfHalf"
		self.callbacks.onInitializeCells()
	end
	if suit.Button(tangentLabel, suit.layout:col()).hit then
		state.initMode = "tangent"
		self.callbacks.onInitializeCells()
	end
	suit.layout:left()

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