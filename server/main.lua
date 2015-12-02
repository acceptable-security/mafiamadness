local Net = require("server/net")
local Entities = require("shared/entities")

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. v)
    end
  end
end

objects = {}

function newObject(type, data)
    local obj = type.new(data)
    local id = objectID
    objectID = objectID + 1

    if obj.createPhysics then
        obj:createPhysics(world)
    end

    for _, v in pairs(players) do
        net:create(v.peer, id, obj)
    end

    return obj, id
end

function createObject(type, data)
    obj, id = newObject(type, data)

    objects[id] = {
        obj = obj;
        objectID = id;
    };
end

function love.load(args)
    love.physics.setMeter(64)
    gravity = 9.81
    world = love.physics.newWorld(0, gravity * love.physics.getMeter(), true)
    world:setCallbacks(function (a, b, col)
        x, y = col:getNormal()

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
    objectID = 0

    net = Net.new {
        ip = "0.0.0.0:1234";

        connectCallback = function (peer)
            pobj = {
                peer = peer;
                objectID = nil;
                obj = nil;
            }

            pobj.obj, pobj.objectID = newObject(Entities.entities[2], {})

            net:create(peer, pobj.objectID, pobj.obj)

            for _, k in pairs(players) do
                net:create(peer, k.objectID, k.obj)
            end

            for v, k in pairs(objects) do
                net:create(peer, k.objectID, k.obj)
            end

            table.insert(players, pobj)
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

            for _, k in ipairs(players) do
                net:destroy(k.peer, d.objectID)
            end

            d.obj.fixture:destroy()
            d.obj.body:destroy()
        end;

        movementCallback = function(peer, data)
            d = nil

            for k, v in ipairs(players) do
                if v.peer == peer then
                    d = v
                    break
                end
            end

            d.obj:applyMovement(data)
        end;
    }

    createObject(Entities.entities[1], { x = 0; y = 200; })
end

function love.keypressed(k)
    if k == 'escape' then
        love.event.quit()
    elseif k == 'w' then
        createObject(Entities.entities[1], { x = math.random(100, 1000); y = math.random(100, 300); })
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
            net:update(k.peer, o.objectID, o.obj)
        end
    end
end

function love.draw(dt)
    love.graphics.print(#players .. " Players Active")
    love.graphics.print(objectID .. " current Object ID", 0, 10)
end
