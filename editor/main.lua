local Level = require("level")
local UI = require("ui")

local debug = true
local paused = false
local ui = nil
local level = nil

-- TODO
-- - Map Editor

function love.load(arg)
    love.physics.setMeter(64) --the height of a meter our worlds will be 64px

    love.graphics.setBackgroundColor(155, 207, 198)

    ui = UI.new {
        equipped = love.graphics.newImage("assets/png/bonus.png")
    }

    level = Level.new {
        file = "level1.json"
    }

    level.camera:setBounds(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function love.update(dt)
    if not paused then
        level:update(dt)
    end
end

function love.keypressed(k)
    if k == 'escape' then
        love.event.quit()
    elseif k == 'p' then
        paused = not paused
   end
end

function love.draw(dt)
    if paused then
        love.graphics.print('PAUSED', love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    end

    level:draw(dt)

    ui:draw()

    if debug then
        local x, y = level.player.body:getLinearVelocity()
        love.graphics.print('(' .. level.player.body:getX() .. ', ' .. level.player.body:getY() .. ')', 0, 0)
        love.graphics.print('(' .. x .. ', ' .. y .. ')', 0, 10)
        love.graphics.print('state: ' .. level.player.state .. '[' .. level.player.imageState .. ']', 0, 20)
    end
end
