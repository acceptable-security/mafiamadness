local AssetManager = {
    images = {};
    assets = {};
    world = nil;
}

local function round(x)
    return math.floor(x + 0.5)
end

-- collision:
-- 1 == circle
-- 2 == rectangle
-- > 2 == polygon

local Asset = {
    image = nil;
    bodyType = "dynamic";
    collision = {};
    density = 1;
    friction = 1;
    rotable = true;
}

Asset.__index = Asset

AssetManager.__index = AssetManager

function AssetManager.new(self)
    if not self.world then return nil end

    self.images = self.images or {}
    self.assets = self.assets or {}

    return setmetatable(self, AssetManager)
end

function AssetManager:getImage(file)
    if not self.images[file] then
        self.images[file] = love.graphics.newImage(file)
    end

    return self.images[file]
end

function AssetManager:load(asset)
    if not asset.name or self.assets[asset.name] then return end

    self.assets[asset.name] = Asset.new(self, asset)

    return asset.name
end

function AssetManager:inst(name, x, y)
    if self.assets[name] == nil then return nil end

    return self.assets[name]:instance(self.world, x, y)
end

function Asset.new(asmgr, self)
    if not self.file then return nil end

    if type(self.file) == "string" then
        self.image = self.image or asmgr:getImage(self.file)
    elseif type(self.file) == "table" then
        self.image = {}

        for k, v in pairs(self.file) do
            if type(v) == "string" then
                self.image[k] = asmgr:getImage(v)
            elseif type(v) == "table" then
                if not self.image[k] then
                    self.image[k] = {}
                end

                for vk, vv in ipairs(v) do
                    self.image[k][vk] = asmgr:getImage(vv)
                end
            else
                return nil
            end
        end
    else
        return nil
    end

    self.bodyType = self.bodyType or "dynamic"
    self.density = self.density or 1
    if self.rotable == nil then self.rotable = true end
    self.friction = self.friction or 5

    if not self.collision or #self.collision < 1 then
        if type(self.file) == "string" then
            self.collision = { self.image:getWidth(); self.image:getHeight(); }
        elseif type(self.file) == "table" then
            self.collision = { self.image["root"][1]:getWidth(); self.image["root"][1]:getHeight(); }
        end
    end

    if self.type == "player" then
        self.update = function (obj, dt)
            local x, y = obj.body:getLinearVelocity()

            if y < -5 and (obj.numContacts and obj.numContacts == 0) then
                if obj.state == 'falling' then
                    obj.currFrame = obj.currFrame + dt

                    if obj.currFrame - obj.lastFrame >= obj.frameLen then
                        obj.lastFrame = obj.currFrame
                        obj.imageState = 1 + (obj.imageState % #obj.image.falling)
                    end
                else
                    obj.state = 'falling'
                    obj.imageState = 1
                end
            elseif y > 3 and (obj.numContacts and obj.numContacts == 0) then
                if obj.state == 'jumping' then
                    obj.currFrame = obj.currFrame + dt

                    if obj.currFrame - obj.lastFrame >= obj.frameLen then
                        obj.lastFrame = obj.currFrame
                        obj.imageState = 1 + (obj.imageState % #obj.image.jumping)
                    end
                else
                    obj.state = 'jumping'
                    obj.imageState = 1
                end
            elseif math.abs(x) > 1 and (obj.numContacts and obj.numContacts > 0) then
                if obj.state == 'walking' then
                    obj.currFrame = obj.currFrame + dt

                    if obj.currFrame - obj.lastFrame >= obj.frameLen then
                        obj.lastFrame = obj.currFrame
                        obj.imageState = 1 + (obj.imageState % #obj.image.walking)
                    end
                else
                    obj.state = 'walking'
                    obj.imageState = 1
                end
            else
                if obj.numContacts and obj.numContacts > 0 then
                    if obj.state == 'root' then
                        obj.currFrame = obj.currFrame + dt

                        if obj.currFrame - obj.lastFrame >= obj.frameLen then
                            obj.lastFrame = obj.currFrame
                            obj.imageState = 1 + (obj.imageState % #obj.image.root)
                        end
                    else
                        obj.state = 'root'
                        obj.imageState = 1
                    end
                else
                    if obj.state == 'falling' then
                        obj.currFrame = obj.currFrame + dt

                        if obj.currFrame - obj.lastFrame >= obj.frameLen then
                            obj.lastFrame = obj.currFrame
                            obj.imageState = 1 + (obj.imageState % #obj.image.falling)
                        end
                    else
                        obj.state = 'falling'
                        obj.imageState = 1
                    end
                end
            end
        end

        self.draw = function (obj)
            if obj.image[obj.state][obj.imageState] then
                local img = obj.image[obj.state][obj.imageState]

                local x, y, angle, velX
                x, y = obj.body:getPosition()
                angle = obj.body:getAngle()
                velX = select(1, obj.body:getLinearVelocity())

                love.graphics.draw(img, round(x), round(y), angle, velX < -1 and -1 or 1, 1, round((img:getWidth()/2)), round((img:getHeight()/2)))

                if obj.wepAngle and obj.image["weapon"] then
                    love.graphics.draw(obj.image["weapon"], obj.body:getX() + 5, obj.body:getY() + 5, obj.wepAngle, 1, 1)
                end
            end
        end

        self.move = function (obj, mvt)
            if mvt.up then
                if obj.numContacts ~= nil and obj.numContacts > 0 then
                    if not obj.lastJumpTime then
                        obj.lastJumpTime = love.timer.getTime()
                        obj.body:applyLinearImpulse(0, obj.body:getMass() * love.physics.getMeter()*-5)
                    else
                        if love.timer.getTime() - obj.lastJumpTime > 0.5 then
                            obj.lastJumpTime = love.timer.getTime()
                            obj.body:applyLinearImpulse(0, obj.body:getMass() * love.physics.getMeter()*-5)
                        end
                    end
                end
            end

            if mvt.left then
                obj.body:applyLinearImpulse(-20 * obj.body:getMass(), 0)
            end

            if mvt.right then
                obj.body:applyLinearImpulse(20 * obj.body:getMass(), 0)
            end
        end
    elseif self.type == "object" then
        self.update = nil

        self.draw = function (obj)
            if obj.body then
                love.graphics.draw(obj.image, math.floor(obj.body:getX() + 0.5), math.floor(obj.body:getY() + 0.5), obj.body:getAngle(), 1, 1, math.floor((obj.image:getWidth()/2) + 0.5), math.floor((obj.image:getHeight()/2) + 0.5))
            end
        end;
    end

    return setmetatable(self, Asset)
end

function Asset:instance(world, x, y)
    obj = {
        lastFrame = 0.0;
        currFrame = 0.0;
        frameLen = 0.03;
        imageState = 1;
        state = "root";

        x = x;
        y = y;
        image = self.image;
        body = love.physics.newBody(world, x, y, self.bodyType)
    };

    if #self.collision == 1 then
        obj.shape = love.physics.newCircleShape(0, 0, self.collision[1])
    elseif #self.collision == 2 then
        obj.shape = love.physics.newRectangleShape(0, 0, self.collision[1], self.collision[2])
    else
        obj.shape = love.physics.newPolygonShape(0, 0, unpack(self.collision))
    end

    obj.fixture = love.physics.newFixture(obj.body, obj.shape, self.density)

    obj.body:setFixedRotation(not self.rotable)
    obj.fixture:setFriction(self.friction)
    obj.body:setUserData(obj)
    obj.asset = self.name

    obj.draw = self.draw
    obj.update = self.update

    if self.move then
        obj.move = self.move
    end

    return obj
end


return AssetManager
