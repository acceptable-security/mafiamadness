local UI = require("client/ui")
local Camera = require("client/camera")
local Net = require("client/net")
local AssetManager = require("shared/AssetManager")

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. tostring(v))
    end
  end
end

require("client/math")

local debug = true
local paused = false
local myID = nil
local ui = nil

function love.load(arg)
    wep = false
    projectiles = {}


    love.physics.setMeter(64) --the height of a meter our worlds will be 64px
    love.graphics.setBackgroundColor(155, 207, 198)

    connected = false

    ui = UI.new { }

    objects = {}

    net = Net.new {
        connectCallback = function()
            connected = true
            net:join("Anonymous", 1)
        end;

        disconnectCallback = function()
            connected = false
            net:close()
        end;

        creationCallback = function(data)
            objects[data.id] = assetMgr:inst(data.asset, data.px, data.py)
            objects[data.id].body:setLinearVelocity(data.vx, data.vy)
            objects[data.id].body:setAngle(data.a)
        end;

        chatCallback = function(data)
            ui:msg(data.name, data.msg)
        end;

        updateCallback = function(data)
            if love.keyboard.isDown("l") then
                if objects[data.id] and objects[data.id].update then
                    objects[data.id]:update(0.01)
                end
                return
            end

            if objects[data.id] ~= nil then
                if data.wepAngle then
                    objects[data.id].wepAngle = data.wepAngle
                else
                    objects[data.id].wepAngle = nil
                end

                if objects[data.id].body then
                    dx, dy = (data.px - objects[data.id].body:getX()), (data.py - objects[data.id].body:getY())
                    d = (dx^2 + dy^2)^0.5

                    if d > 2.0 then
                        objects[data.id].body:setPosition(data.px, data.py)
                    elseif d > 0.1 then
                        objects[data.id].body:setPosition(objects[data.id].body:getX() + dx, objects[data.id].body:getY() + dy)
                    end

                    if data.id == myID and prediction then
                        objects[myID].body:setPosition(data.px, data.py)

                        for _, k in ipairs(lastMovements) do
                            objects[myID]:move(k)
                        end

                        lastMovements = {}
                    end

                    objects[data.id].body:setLinearVelocity(data.vx, data.vy)
                    objects[data.id].body:setAngle(data.a)
                end

                if objects[data.id].update then
                    objects[data.id]:update(0.01) -- probably not the right DT
                end
            end
        end;

        destructionCallback = function(data)
            if data.id == myID then
                myID = nil
            end

            if objects[data.id] then
                objects[data.id].fixture:destroy()
                objects[data.id].body:destroy()
                objects[data.id] = nil
            end
        end;

        assetCallback = function(data)
            assetMgr:load(data)
        end;

        shootCallback = function(data)
            local o = objects[data.id]
            if not o then return end

            local len = 500

            local y = o.body:getY() + (len * math.sin(o.wepAngle))
            local x = o.body:getX() + (len * math.cos(o.wepAngle))

            table.insert(projectiles, {
                x = o.body:getX();
                y = o.body:getY();
                len = len;
                angle = o.wepAngle;
                added = love.timer.getTime();
            })

            local ind = #projectiles

            ourWorld:rayCast(o.body:getX(), o.body:getY(), x, y, function (fixture, x, y, xn, yn, fraction)
                projectiles[ind].len = ((xn-x)^2 + (yn-y)^2)^0.5

                return 0
            end)
        end;

        controlCallback = function(data)
            if data.id == -1 then
                myID = nil
            else
                myID = data.id
            end
        end;
    }

    net:connect(arg[3])

    camera = Camera.new{}
    camera:setBounds(0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.physics.setMeter(64)
    gravity = 9.81
    ourWorld = love.physics.newWorld(0, gravity * love.physics.getMeter(), true)
    prediction = true
    lastMovements = {}

    assetMgr = AssetManager.new({
        world = ourWorld;
    })

    ourWorld:setCallbacks(function (a, b, col)
        x, y = col:getNormal()
        x = math.floor(0.5 + x)
        y = math.floor(0.5 + y)

        if x ~= 0 and y ~= 1 then
            return
        end

        if a:getBody():getUserData() then
            if not a:getBody():getUserData().numContacts or a:getBody():getUserData().numContacts < 0  then
                a:getBody():getUserData().numContacts = 1
            else
                a:getBody():getUserData().numContacts = a:getBody():getUserData().numContacts + 1
            end
        end

        if b:getBody():getUserData() then
            if not b:getBody():getUserData().numContacts or b:getBody():getUserData().numContacts < 0 then
                b:getBody():getUserData().numContacts = 1
            else
                b:getBody():getUserData().numContacts = b:getBody():getUserData().numContacts + 1
            end
        end
    end, function(a, b, col)
        x, y = col:getNormal()
        x = math.floor(0.5 + x)
        y = math.floor(0.5 + y)

        if x ~= 0 and y ~= 1 then
            return
        end

        if a:getBody():getUserData() then
            if not a:getBody():getUserData().numContacts or a:getBody():getUserData().numContacts < 0  then
                a:getBody():getUserData().numContacts = 0
            else
                a:getBody():getUserData().numContacts = a:getBody():getUserData().numContacts - 1
            end
        end

        if b:getBody():getUserData() then
            if not b:getBody():getUserData().numContacts or b:getBody():getUserData().numContacts < 0  then
                b:getBody():getUserData().numContacts = 0
            else
                b:getBody():getUserData().numContacts = b:getBody():getUserData().numContacts - 1
            end
        end
    end, _, _)
end

function love.mousepressed(x, y, button)
    if button == "l" and myID and objects[myID] and objects[myID].wepAngle then
        net:shoot()
    end
end

function love.keypressed(k)
    if not ui.chatOpen then
        if k == "escape" then
            net:close()
            love.event.quit()
        elseif k == "p" then
            prediction = not prediction
        elseif k == "q" then
            if myID and objects[myID] then
                wep = not wep

                if not wep then
                    net:move({
                        up = false;
                        left = false;
                        right = false;
                        down = false;
                    })
                end
            end
        end
    else
        if k == "return" then
            ui:msg("Anonymous", ui.tmpMsg)
            net:msg(ui.tmpMsg, "global")
            ui.tmpMsg = ""
            ui.chatOpen = false
        elseif k == "backspace" then
            if #ui.tmpMsg > 0 then
                ui.tmpMsg = ui.tmpMsg:sub(1, #ui.tmpMsg - 1)
            end
        elseif k == "escape" then
            ui.tmpMsg = ""
            ui.chatOpen = false
        end
    end
end

function love.textinput(k)
    if ui.chatOpen then
        ui.tmpMsg = ui.tmpMsg .. k
    elseif k == "t" then
        ui.chatOpen = true
    end
end

function love.update(dt)
    net:read()

    local mvt = {
        up = false;
        left = false;
        right = false;
        down = false;
    }

    local empty = true

    if not ui.chatOpen then
        if love.keyboard.isDown('w') then
            empty = false
            mvt.up = true
        end
        if love.keyboard.isDown('a') then
            empty = false
            mvt.left = true
        end
        if love.keyboard.isDown('d') then
            empty = false
            mvt.right = true
        end
    end

    if myID and objects[myID] and wep then
        local x = (love.mouse.getX() + camera.x) - objects[myID].body:getX()
        local y = (love.mouse.getY() + camera.y) - objects[myID].body:getY()
        mvt.wepAngle = math.atan(y/x)

        if x < 0 then mvt.wepAngle = mvt.wepAngle + math.pi end

        empty = false
    end

    if prediction and myID ~= nil and objects[myID] ~= nil then
        objects[myID]:move(mvt)

        ourWorld:update(0.017)

        table.insert(lastMovements, {
            mvt = mvt;
            dt = dt;
        })
    end

    if not empty and myID then
        net:move(mvt)
    end

    if objects[myID] then
        camera:setPosition((objects[myID].body:getX() + 5 - (love.graphics.getWidth() / 2)) / 2,
                           (objects[myID].body:getY() + 5 - (love.graphics.getHeight() / 2)) / 2)
    else
        camera:setPosition(love.mouse.getX() / 2, love.mouse.getY() / 2)
    end
end

function love.draw(dt)
    if paused then
        love.graphics.print('PAUSED', love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    end

    if not connected then
        love.graphics.print('Waiting for Connection', (love.graphics.getWidth()/2), love.graphics.getHeight()/2)
    end

    camera:set()
    for _, v in pairs(objects) do
        if v and v.draw then
            v:draw(prediction)
        end
    end

    for k, v in ipairs(projectiles) do
        if love.timer.getTime() - v.added >= 0.5 then
            table.remove(projectiles, k)
        else
            love.graphics.push()
            love.graphics.translate(v.x, v.y)
            love.graphics.push()
            love.graphics.rotate(v.angle)
            love.graphics.rectangle("fill", 0, 0, ((love.timer.getTime() - v.added) / 0.3)  * v.len, 5 - (((love.timer.getTime() - v.added) / 0.5) * 5))
            love.graphics.pop()
            love.graphics.pop()
        end
    end

    camera:unset()

    ui:draw()
end
