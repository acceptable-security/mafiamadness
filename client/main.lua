-- local UI = require("ui")
local Camera = require("client/camera")
local Entities = require("shared/entities")
local Net = require("client/net")

require("client/math")

local debug = true
local paused = false
local myID = nil
-- local ui = nil

function love.load(arg)
    love.physics.setMeter(64) --the height of a meter our worlds will be 64px
    love.graphics.setBackgroundColor(155, 207, 198)

    connected = false

    -- ui = UI.new {
    --     equipped = love.graphics.newImage("shared/assets/png/bonus.png")
    -- }

    objects = {}

    net = Net.new {
        connectCallback = function()
            connected = true
            net:join("Anonymous", Entities.version)
        end;

        disconnectCallback = function()
            connected = false
            net:close()
        end;

        creationCallback = function(data)
            local type = Entities.entities[data.type]

            if not myID then
                myID = data.id
            end

            objects[data.id] = type.new {
                x = data.px;
                y = data.py;
                velX = data.vx;
                velY = data.vy;
                angle = data.a;
            }

            if objects[data.id].createPhysics then
                objects[data.id]:createPhysics(ourWorld)
            end
        end;

        updateCallback = function(data)
            if objects[data.id] then
                if objects[data.id].body and prediction then
                    dx, dy = (data.px - objects[data.id].body:getX()), (data.py - objects[data.id].body:getY())
                    d = (dx^2 + dy^2)^0.5

                    if d > 2.0 then
                        objects[data.id].body:setPosition(data.px, data.py)
                    elseif d > 0.1 then
                        objects[data.id].body:setPosition(objects[data.id].body:getX() + dx, objects[data.id].body:getY() + dy)
                    end
                    
                    objects[data.id].body:setLinearVelocity(data.vx, data.vy)
                    objects[data.id].body:setAngle(data.a)
                else
                    objects[data.id].x = data.px
                    objects[data.id].y = data.py
                    objects[data.id].velX = data.vx
                    objects[data.id].velY = data.vy
                    objects[data.id].a = data.a
                end

                if objects[data.id].update then
                    objects[data.id]:update(0.01) -- probably not the right DT
                end
            end
        end;

        destructionCallback = function(data)
            objects[data.id] = nil
        end;
    }

    net:connect("67.87.226.231:1234")

    camera = Camera.new{}
    camera:setBounds(0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.physics.setMeter(64)
    gravity = 9.81
    ourWorld = love.physics.newWorld(0, gravity * love.physics.getMeter(), true)
    prediction = true
end

function love.keypressed(k)
    if k == "escape" then
        net:close()
        love.event.quit()
    elseif k == "p" then
        predicton = not prediction
    end
end

function love.update(dt)
    net:read()

    local mvt = {
        up = 0;
        left = 0;
        right = 0;
        down = 0;
    }

    local empty = true

    if love.keyboard.isDown('w') then
        empty = false
        mvt.up = 1

        if prediction then
            local _, y = objects[myID].body:getLinearVelocity()
            if math.abs(y) < 7 then
                objects[myID].body:applyLinearImpulse(0, objects[myID].body:getMass() * love.physics.getMeter()*-5)
            end
        end
    end
    if love.keyboard.isDown('a') then
        empty = false
        mvt.left = 1

        if predicton then
            objects[myID].body:applyLinearImpulse(-20 * objects[myID].body:getMass(), 0)
        end
    end
    if love.keyboard.isDown('d') then
        empty = false
        mvt.right = 1

        if prediction then
            objects[myID].body:applyLinearImpulse(20 * objects[myID].body:getMass(), 0)
        end
    end

    ourWorld:update(dt)

    if not empty then
        net:move(mvt)
    end
end

function love.draw(dt)
    if paused then
        love.graphics.print('PAUSED', love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    end

    if not connected then
        love.graphics.print('Waiting for Connection', (love.graphics.getWidth()/2), love.graphics.getHeight()/2)
    end

    for _, v in pairs(objects) do
        if v and v.draw then
            v:draw()
        end
    end

    -- ui:draw()
end
