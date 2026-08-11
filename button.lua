local Button = {}
Button.__index = Button

function Button.new(x, y, width, height, text, callback)
	local button = {
		x = x, y = y,
		width = width, height = height,
		text = text,
		active = false,
		callback = callback,
		hovered = false
	}
	setmetatable(button, Button)
	return button
end

function Button:update()
	local mouseX, mouseY = love.mouse.getPosition()
	self.hovered = mouseX >= self.x and mouseX <= self.x + self.width and
				   mouseY >= self.y and mouseY <= self.y + self.height
end

function Button:draw()
	love.graphics.setColor(1,0.5,0.5)
	love.graphics.rectangle("fill" ,self.x, self.y, self.width, self.height)
	love.graphics.setColor(0, 0, 0)
	love.graphics.printf(self.text, self.x, self.y + self.height/2 - 8, self.width, "center")
end

function Button:click()
	if self.hovered and self.callback then
		self.callback()
	end
end

return Button