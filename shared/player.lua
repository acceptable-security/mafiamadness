
package.path = package.path .. ";../?.lua"

local Player = {
    type = "player1";

    image = {
        root = {
            love.graphics.newImage("shared/assets/png/character/front.png")
        };
        walking = {
            love.graphics.newImage("shared/assets/png/character/walk/walk0001.png");
            love.graphics.newImage("shared/assets/png/character/walk/walk0002.png");
            love.graphics.newImage("shared/assets/png/character/walk/walk0003.png");
            love.graphics.newImage("shared/assets/png/character/walk/walk0004.png");
            love.graphics.newImage("shared/assets/png/character/walk/walk0005.png");
            love.graphics.newImage("shared/assets/png/character/walk/walk0006.png");
            love.graphics.newImage("shared/assets/png/character/walk/walk0007.png");
            love.graphics.newImage("shared/assets/png/character/walk/walk0008.png");
            love.graphics.newImage("shared/assets/png/character/walk/walk0009.png");
            love.graphics.newImage("shared/assets/png/character/walk/walk0010.png");
            love.graphics.newImage("shared/assets/png/character/walk/walk0011.png");
        };
        jumping = {
            love.graphics.newImage("shared/assets/png/character/jump.png");
        };
        falling = {
            love.graphics.newImage("shared/assets/png/character/jump.png");
        }
    };

    state = 'root';
    imageState = 1;

    lastFrame = 0.0;
    currFrame = 0.0;
    frameLen = 0.03;
}

Player.__index = Player

function Player.new(self)
    self.id = self.id or 0

    self.x = self.x or 0
    self.y = self.y or 0

    self.velX = self.velX or 0
    self.velY = self.velY or 0

    self.angle = self.angle or 0

    return setmetatable(self, Player)
end

function Player:createPhysics(world)
    self.w = self.w or self.image['root'][1]:getWidth()
    self.h = self.h or self.image['root'][1]:getHeight()

    self.body = love.physics.newBody(world, self.x, self.y, "dynamic")
    self.shape = love.physics.newRectangleShape(0, 0, self.w, self.h)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1)

    self.body:setFixedRotation(true)
    self.body:setUserData(self)
end

function Player:update(dt)
    local x, y = self.body:getLinearVelocity()

    if y < -5 then
        if self.state == 'falling' then
            self.currFrame = self.currFrame + dt

            if self.currFrame - self.lastFrame >= self.frameLen then
                self.lastFrame = self.currFrame
                self.imageState = 1 + (self.imageState % #self.image.falling)
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
                self.imageState = 1 + (self.imageState % #self.image.jumping)
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
                self.imageState = 1 + (self.imageState % #self.image.walking)
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
                self.imageState = 1 + (self.imageState % #self.image.root)
            end
        else
            self.state = 'root'
            self.imageState = 1
        end
    end
end

function Player:draw(prediction)
    if self.image[self.state][self.imageState] then
        local img = self.image[self.state][self.imageState]

        if self.body and prediction then
            local x, _ = self.body:getLinearVelocity()
            love.graphics.draw(img, math.floor(self.body:getX() + 0.5), math.floor(self.body:getY() + 0.5), self.body:getAngle(), x  > 0 and 1 or -1, 1, math.floor((img:getWidth()/2) + 0.5), math.floor((img:getHeight()/2) + 0.5))
        else
            love.graphics.draw(img, math.floor(self.x + 0.5), math.floor(self.y + 0.5), self.angle, self.velX > 0 and 1 or -1, 1, math.floor((img:getWidth()/2) + 0.5), math.floor((img:getHeight()/2) + 0.5))
        end
    end
end

return Player
