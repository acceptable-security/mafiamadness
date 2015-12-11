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

    for _, v in pairs(players) do
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
    for k, v in ipairs(players) do
        net:destroy(v.peer, id)

        if v.objectID == id then
            print("DEST")
            v.obj.fixture:destroy()
            v.obj.body:destroy()
            n = k
        end
    end

    if n ~= -1 then
        table.remove(players, n)
    end
end

function love.load(args)
    love.physics.setMeter(64)
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
                if v.peer == peer then
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

            for k, v in ipairs(players) do
                if v.peer == peer then
                    d = v
                    break
                end
            end

            if d then
                if data.loc == "global" then
                    for k, v in ipairs(players) do
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

                -- print("(" .. d.obj.body:getX() .. ", " .. d.obj.body:getY() .. ") -> (" .. x .. ", " .. y .. ")")

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
                                print("KILL " .. v.objectID)
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
    elseif k == 'w' then
        createObject("box", math.random(100, 1000), math.random(100, 300))
    end
end

function love.update(dt)
    world:update(0.017)
    net:listen()

    for _, k in ipairs(players) do
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
    love.graphics.print(#players .. " Players Active")
    love.graphics.print(objectID .. " current Object ID", 0, 10)
end
