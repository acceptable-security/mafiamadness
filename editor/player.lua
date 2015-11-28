local Player = {
    images = {
        root = {};
        walking = {};
        jumping = {};
        falling = {};
    };

    state = 'root';
    imageState = 1;

    lastFrame = 0.0;
    currFrame = 0.0;
    frameLen = 0.03;

    world = nil;
    body = nil;
    shape = nil;
    fixture = nil;
}

Player.__index = Player

function Player.new(self)
    self.x = self.x or 0
    self.y = self.y or 0

    self.w = self.w or self.images['root'][1]:getWidth()
    self.h = self.h or self.images['root'][1]:getHeight()

    self.body = love.physics.newBody(self.world, self.x, self.y, "dynamic")
    self.shape = love.physics.newRectangleShape(0, 0, self.w, self.h)
    self.fixture = love.physics.newFixture(self.body, self.shape, self.density or 1)

    self.body:setFixedRotation(true)
    self.fixture:setFriction(5)
    self.body:setUserData(self)

    return setmetatable(self, Player)
end

function Player:update(dt)
    if love.keyboard.isDown("a") then
        self.body:applyLinearImpulse(-20 * self.body:getMass(), 0)
    elseif love.keyboard.isDown("d") then
        self.body:applyLinearImpulse(20 * self.body:getMass(), 0)
    end

    if love.keyboard.isDown("w") then
        local _, y = self.body:getLinearVelocity()
        if math.abs(y) < 7 then
            self.body:applyLinearImpulse(0, self.body:getMass() * love.physics.getMeter()*-5)
        end
    end

    local x, y = self.body:getLinearVelocity()

    if y < -5 then
        if self.state == 'falling' then
            self.currFrame = self.currFrame + dt

            if self.currFrame - self.lastFrame >= self.frameLen then
                self.lastFrame = self.currFrame
                self.imageState = 1 + (self.imageState % #self.images.falling)
            end
        else
            self.state = 'falling'
            self.imageState = 1
        end
    elseif y > 3 then
        if self.state == 'jumping' then
            self.currFrame = self.currFrame + dt

            if self.currFrame - self.lastFrame >= self.frameLen then
                self.lastFrame = self.currFrame
                self.imageState = 1 + (self.imageState % #self.images.jumping)
            end
        else
            self.state = 'jumping'
            self.imageState = 1
        end
    elseif math.abs(x) > 1 then
        if self.state == 'walking' then
            self.currFrame = self.currFrame + dt

            if self.currFrame - self.lastFrame >= self.frameLen then
                self.lastFrame = self.currFrame
                self.imageState = 1 + (self.imageState % #self.images.walking)
            end
        else
            self.state = 'walking'
            self.imageState = 1
        end
    else
        if self.state == 'root' then
            self.currFrame = self.currFrame + dt

            if self.currFrame - self.lastFrame >= self.frameLen then
                self.lastFrame = self.currFrame
                self.imageState = 1 + (self.imageState % #self.images.root)
            end
        else
            self.state = 'root'
            self.imageState = 1
        end
    end
end

function Player:draw()
    local x, _ = self.body:getLinearVelocity()

    if self.images[self.state][self.imageState] then
        local img = self.images[self.state][self.imageState]
        love.graphics.draw(img, math.floor(self.body:getX() + 0.5), math.floor(self.body:getY() + 0.5), self.body:getAngle(), x > 0 and 1 or -1, 1, math.floor((img:getWidth()/2) + 0.5), math.floor((img:getHeight()/2) + 0.5))
    else
        love.graphics.setColor(146, 162, 159)
        love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
    end
end

return Player
