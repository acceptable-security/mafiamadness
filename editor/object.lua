local Object = {
    body = nil;
    shape = nil;
    fixture = nil;

    image = nil;

    x = 0;
    y = 0;
    w = 0;
    h = 0;
    radius = 0;

    type = "static";
    friction = 5;
    density = 1;
    rotate = true;
}

Object.__index = Object

function Object.new(self)
    self.x = self.x or 0
    self.y = self.y or 0

    if not self.radius then
        if self.image then
            self.w = self.image:getWidth()
            self.h = self.image:getHeight()
        else
            self.w = self.w or 5
            self.h = self.h or 5
        end
    end

    if type == "art" then
        return setmetatable(self, Object)
    end

    self.type = self.type or "static"
    self.density = self.density or 1
    self.friction = self.friction or 5
    self.rotate = self.rotate or true

    self.body = love.physics.newBody(self.world, self.x, self.y, self.type)

    if not self.radius then
        self.shape = love.physics.newRectangleShape(0, 0, self.w, self.h)
    else
        self.shape = love.physics.newCircleShape(self.radius)
    end

    self.fixture = love.physics.newFixture(self.body, self.shape, self.density)
    self.body:setUserData(self)

    return setmetatable(self, Object)
end

function Object:draw()
    if self.image then
        love.graphics.draw(self.image, math.floor(self.body:getX() + 0.5), math.floor(self.body:getY() + 0.5), self.body:getAngle(), 1, 1, math.floor((self.image:getWidth()/2) + 0.5), math.floor((self.image:getHeight()/2) + 0.5))
    else
        love.graphics.setColor(146, 162, 159)

        if not self.radius then
            love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
        else
            love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())
        end
    end
end

return Object
