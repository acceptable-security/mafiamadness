local Net = require("server/net")
local AssetManager = require("shared/AssetManager")

require "shared/json/json"

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

objects = {}

function newObject(asset, x, y)
    local obj = assetMgr:inst(asset, x, y)

    if obj == nil then return nil, -1 end

    local id = objectID
    objectID = objectID + 1

    for _, v in pairs(peers) do
        net:createObject(v.peer, id, obj)
    end

    return obj, id
end

function createObject(asset, x, y)
    obj, id = newObject(asset, x, y)

    if obj == nil then return end

    objects[id] = {
        obj = obj;
        objectID = id;
    };
end

function killPlayer(id)
    local n = -1
    local p = nil

    for _, v in ipairs(peers) do
        net:destroy(v.peer, id)
    end

    for k, v in ipairs(players) do
        if v.objectID == id then
            p = v.peer
            v.obj.fixture:destroy()
            v.obj.body:destroy()
            n = k
            table.remove(players, k)
            break
        end
    end

    if n ~= -1 then
        if gameState == 1 then
            for k, v in ipairs(innos) do
                if v == id then
                    table.remove(innos, k)
                end
            end

            for k, v in ipairs(mafs) do
                if v == id then
                    table.remove(mafs, k)
                end
            end

            if #mafs == 0 or #innos == 0 then
                endGame()
            end
        else
            for _, v in ipairs(peers) do
                if v.peer == p then
                    respawn(v)
                    break
                end
            end
        end
    end
end

function respawn(v)
    pobj = {
        peer = v.peer;
        name = v.name;
        objectID = nil;
        obj = nil;
    }

    pobj.obj, pobj.objectID = newObject("player", math.random(0, 300), 0) -- TODO: spawn points

    if pobj.obj == nil then
        print("OH FUCK")
    end

    table.insert(players, pobj)

    net:control(v.peer, pobj.objectID)

    return pobj.objectID
end

function startGame()
    if #peers < 3 then
        return
    end

    local tmp = {}

    for _, v in ipairs(players) do table.insert(tmp, v.objectID) end

    for _, v in ipairs(tmp) do
        killPlayer(v)
    end

    players = {}

    local mafC = math.floor(0.5 + (#peers / 3.5))

    innos = {}
    mafs = {}

    for _, v in ipairs(peers) do
        table.insert(innos, respawn(v))
    end

    for i = 1, mafC do
        local n = math.random(1, #innos)
        local pl = table.remove(innos, n)

        table.insert(mafs, pl)

        for _, v in ipairs(players) do
            if v.objectID == pl then
                net:gameState(v.peer, 0, 1) -- NEW / MAF
            end
        end
    end

    for _, id in ipairs(innos) do
        for _, v in ipairs(players) do
            if v.objectID == id then
                net:gameState(v.peer, 0, 0) -- NEW / INNO
            end
        end
    end

    gameState = 1
end

function endGame()
    local winner = ""

    if #mafs > 0 then
        winner = "mafia"
    elseif #innos > 0 then
        winner = "innocents"
    end

    local tmp = {}

    for _, v in ipairs(players) do table.insert(tmp, v.objectID) end

    for _, v in ipairs(tmp) do
        killPlayer(v)
    end

    players = {}

    for _, k in ipairs(peers) do
        respawn(k)
        net:gameState(k.peer, 1)
        net:msg(k.peer, "WORLD", "The " .. winner .. " have won")
    end

    gameState = 0
    innos = {}
    mafs = {}
end

function love.load(args)
    love.window.setMode(300, 300)
    love.physics.setMeter(64)
    gameState = 0
    gravity = 9.81

    world = love.physics.newWorld(0, gravity * love.physics.getMeter(), true)
    world:setCallbacks(function (a, b, col)
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

    players = {}
    peers = {}

    assetMgr = AssetManager.new {
        world = world;
    }

    objectID = 0

    net = Net.new {
        ip = "0.0.0.0:1234";

        creationCallback = function (peer, data)
            pobj = {
                peer = peer;
                name = data.name;
                objectID = nil;
                obj = nil;
            }

            pobj.obj, pobj.objectID = newObject("player", 0, 0)

            if pobj.obj == nil then
                print("OH FUCK")
            end

            table.insert(players, pobj)

            table.insert(peers, {
                peer = peer;
                name = data.name;
            })

            for _, k in pairs(assetMgr.assets) do
                net:createAsset(peer, k)
            end

            for _, k in pairs(players) do
                net:createObject(peer, k.objectID, k.obj)
            end

            for v, k in pairs(objects) do
                net:createObject(peer, k.objectID, k.obj)
            end

            net:control(peer, pobj.objectID)
        end;

        disconnectCallback = function (peer)
            d = nil

            for k, v in ipairs(peers) do
                if v.peer == peer then
                    table.remove(peers, k)
                end
            end

            for k, v in ipairs(players) do
                if v.peer == peer then
                    d = v
                    table.remove(players, k)
                    break
                end
            end

            if d ~= nil then
                for _, k in ipairs(players) do
                    net:destroy(k.peer, d.objectID)
                end

                d.obj.fixture:destroy()
                d.obj.body:destroy()
            end
        end;

        movementCallback = function(peer, data)
            d = nil

            for k, v in ipairs(players) do
                if v.peer == peer and v.obj ~= nil then
                    d = v
                    break
                end
            end

            if d and d.objectID then
                d.obj:move(data)

                if data.wepAngle then
                    d.obj.wepAngle = data.wepAngle
                else
                    d.obj.wepAngle = nil
                end
            end
        end;

        chatCallback = function(peer, data)
            if #data.msg < 1 then return end

            d = nil

            for _, v in ipairs(peers) do
                if v.peer == peer then
                    print("FOUND")
                    d = v
                    break
                end
            end

            if d then
                if data.loc == "global" then
                    for k, v in ipairs(peers) do
                        if v.peer ~= peer then
                            net:msg(v.peer, d.name, data.msg)
                        end
                    end
                -- elseif data.loc == "local"
                end
            end
        end;

        shootCallback = function(peer, data)
            d = nil

            for k, v in ipairs(players) do
                if v.peer == peer then
                    d = v
                    break
                end
            end

            if d and d.obj.wepAngle then
                if d.lastShot and d.lastShot - love.timer.getTime() > 0.5 then
                    return
                end

                if d.obj.wepAngle == nan then return end

                d.lastShot = love.timer.getTime()

                local len = 500

                local y = d.obj.body:getY() + (len * math.sin(d.obj.wepAngle))
                local x = d.obj.body:getX() + (len * math.cos(d.obj.wepAngle))

                for k, v in ipairs(players) do
                    net:shoot(v.peer, d.objectID)
                end

                world:rayCast(d.obj.body:getX(), d.obj.body:getY(), x, y, function (fixture, x, y, xn, yn, fraction)
                    local b = fixture:getBody()

                    if b == d.obj.body then
                        return 1
                    end

                    local data = b:getUserData()

                    if data and data.asset == "player" then
                        for _, v in ipairs(players) do
                            if v.obj == data then
                                killPlayer(v.objectID)
                            end
                        end
                    end

                    return 0
                end)
            end
        end;
    }

    local content, _ = love.filesystem.read("server/level1.json")
    local obj = json.decode(content)

    for _, v in ipairs(obj.assets) do
        assetMgr:load(v)
    end

    for _, v in ipairs(obj.objects) do
        createObject(v.asset, v.x, v.y)
    end
end

function love.keypressed(k)
    if k == 'escape' then
        love.event.quit()
    elseif k == ' ' then
        if gameState == 0 then
            startGame()
        else
            endGame()
        end
    elseif k == 'w' then
        createObject("box", math.random(100, 1000), math.random(100, 300))
    end
end

function love.update(dt)
    world:update(0.017)
    net:listen()

    for _, k in ipairs(peers) do
        for _, o in ipairs(objects) do
            if not o.static then
                net:update(k.peer, o.objectID, o.obj)
            end
        end

        for _, o in ipairs(players) do
            if o.obj ~= nil then
                net:update(k.peer, o.objectID, o.obj)
            end
        end
    end
end

function love.draw(dt)
    love.graphics.print(#peers .. " Players Active")
    love.graphics.print(objectID .. " current Object ID", 0, 10)

    if gameState == 0 then
        love.graphics.print("Press Space to begin the game", (love.graphics.getWidth() - love.graphics.getFont():getWidth("Press Space to begin the game")) / 2, 30)
    else
        love.graphics.print("Press Space to end the game", (love.graphics.getWidth() - love.graphics.getFont():getWidth("Press Space to end the game")) / 2, 30)
    end
end
