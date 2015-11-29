local Net = require("server/net")
local Entities = require("shared/entities")

function newObject(type, data)
    local obj = type.new(data)
    local id = objectID
    objectID = objectID + 1

    if obj.createPhysics then
        obj:createPhysics(world)
    end

    for _, v in ipairs(players) do
        net:update(peer, id, obj)
    end

    return obj, id
end

function createObject(type, data)
    obj, id = newObject(type, data)

    tables.insert(objects, {
        obj = obj;
        objectID = id;
    })
end

function love.load(args)
    love.physics.setMeter(64)
    gravity = 9.81
    world = love.physics.newWorld(0, gravity * love.physics.getMeter(), true)

    players = {}
    objects = {}
    objectID = 0

    net = Net.new {
        ip = "localhost:1234";

        connectCallback = function (peer)
            pobj = {
                peer = peer;
                objectID = nil;
                obj = nil;
            }

            pobj.obj, pobj.objectID = newObject(Entities.entities[2], {})

            print("CREATE")
            net:create(peer, pobj.objectID, pobj.obj)

            for _, k in ipairs(players) do
                net:create(peer, k.objectID, k.obj)
            end

            for _, k in ipairs(objects) do
                net:update(peer, k.objectID, k.obj)
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
            d.obj.shape:destroy()
        end;

        movementCallback = function(peer, data)
            d = nil

            for k, v in ipairs(players) do
                if v.peer == peer then
                    d = v
                    table.remove(players, k)
                    break
                end
            end

            if data == 8 then
                local _, y = d.obj.body:getLinearVelocity()
                if math.abs(y) < 7 then
                    d.obj.body:applyLinearImpulse(0, d.obj.body:getMass() * love.physics.getMeter()*-5)
                end
            elseif data == 2 then
                d.obj.body:applyLinearImpulse(-20 * d.obj.body:getMass(), 0)
            elseif data == 1 then
                d.obj.body:applyLinearImpulse(20 * d.obj.body:getMass(), 0)
            end
        end;
    }
end

function love.mousepressed(k)
    if k == 'escape' then
        love.event.quit()
    end
end

function love.update(dt)
    net:listen()
    world:update(dt)

    for _, k in ipairs(players) do
        for _, o in ipairs(objects) do
            net:update(k.peer, o.objectID, o.obj)
        end

        for _, o in ipairs(players) do
            net:update(k.peer, o.objectID, o.obj)
        end
    end
end

function love.draw(dt)
    love.graphics.print(#players .. " Players Active")
end
