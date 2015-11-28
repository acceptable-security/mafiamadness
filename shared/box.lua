local Box = {
    type = "box1";
    image = love.graphics.newImage("assets/png/block.png");
}

Box.__index = Box

function Box.new(self)
    self.id = self.id or 0

    self.x = self.x or 0
    self.y = self.y or 0

    self.velX = self.velX or 0
    self.velY = self.velY or 0

    self.angle = self.angle or 0

    return setmetatable(self, Box)
end

function Box:draw()
    love.graphics.draw(self.image, math.floor(self.x + 0.5), math.floor(self.y + 0.5), self.angle, 1, 1, math.floor((self.image:getWidth()/2) + 0.5), math.floor((self.image:getHeight()/2) + 0.5))
end
