local UI = require("ui")
local Camera = require("camera")
local Entities = require("../shared/entities.lua")

local debug = true
local paused = false
local ui = nil

function loadImage()
    return
end

function love.load(arg)
    love.physics.setMeter(64) --the height of a meter our worlds will be 64px
    love.graphics.setBackgroundColor(155, 207, 198)

    ui = UI.new {
        equipped = love.graphics.newImage("assets/png/bonus.png")
    }

    objects = {}

    net = Net {
        ip = "localhost:1234";

        connectCallback = function()
            net:join("Anonymous", Entities.version)
        end;

        disconnectCallback = function()
            net:close()
        end;

        creationCallback = function(data)
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
            objects[data.id].x = data.px
            objects[data.id].y = data.py
            objects[data.id].velX = data.vx
            objects[data.id].velY = data.vy
            objects[data.id].a = data.a

            if objects[data.id].update then
                objects[data.id].update(dt) -- probably not the right DT
            end
        end;
    }
    camera = Camera.new()
    camera:setBounds(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function love.update(dt)
    net:read()
end

function love.keypressed(k)
    local mvt = {
        up = 0;
        left = 0;
        right = 0;
    }

    local empty = true

    if k == 'escape' then
        love.event.quit()
    elseif k == 'w' or k == 'up' then
        empty = false
        mvt.up = 1
    elseif k == 'a' or k == 'left' then
        empty = false
        mvt.left = 1
    elseif k == 'd' or k == 'right' then
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

    for _, v in ipairs(objects) do
        if v.draw then
            v:draw()
        end
    end

    ui:draw()

    if debug then
        local x, y = level.player.body:getLinearVelocity()
        love.graphics.print('(' .. level.player.body:getX() .. ', ' .. level.player.body:getY() .. ')', 0, 0)
        love.graphics.print('(' .. x .. ', ' .. y .. ')', 0, 10)
        love.graphics.print('state: ' .. level.player.state .. '[' .. level.player.imageState .. ']', 0, 20)
    end
end
