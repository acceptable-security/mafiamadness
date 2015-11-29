-- local UI = require("ui")
local Camera = require("client/camera")
local Entities = require("shared/entities")
local Net = require("client/net")

local debug = true
local paused = false
-- local ui = nil

function love.load(arg)
    love.physics.setMeter(64) --the height of a meter our worlds will be 64px
    love.graphics.setBackgroundColor(155, 207, 198)

    connected = false

    -- ui = UI.new {
    --     equipped = love.graphics.newImage("shared/assets/png/bonus.png")
    -- }

    objects = {}
    myID = nil

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
            if myID == nil then
                myID = data.id
            end

            local type = Entities.entities[data.type]

            objects[data.id] = type.new {
                x = data.px;
                y = data.py;
                velX = data.vx;
                velY = data.vy;
                angle = data.a;
            }
        end;

        updateCallback = function(data)
            if objects[data.id] then
                objects[data.id].x = data.px
                objects[data.id].y = data.py
                objects[data.id].velX = data.vx
                objects[data.id].velY = data.vy
                objects[data.id].a = data.a

                if objects[data.id].update then
                    objects[data.id]:update(0.01) -- probably not the right DT
                end
            end
        end;

        destructionCallback = function(data)
            objects[data.id] = nil
        end;
    }

    net:connect("localhost:1234")

    camera = Camera.new{}
    camera:setBounds(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
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

    if love.keyboard.isDown("escape") then
        net:close()
        love.event.quit()
    end
    if love.keyboard.isDown('w') then
        empty = false
        mvt.up = 1
    end
    if love.keyboard.isDown('a') then
        empty = false
        mvt.left = 1
    end
    if love.keyboard.isDown('d') then
        empty = false
        mvt.right = 1
    end

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
