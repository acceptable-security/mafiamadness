local Net = require("net")
local Entities = require("../shared/entities")

function newObject(type, data)
    local obj = type.new(data)
    local id = objectID
    objectID = objectID + 1

    for _, v in ipairs(players) do
        net:update(peer, id, obj)
    end

    return obj, id
end

function love.load(args)
    love.physics.setMeter(64)

    gravity = gravity or 9.81
    world = world or love.physics.newWorld(0, gravity * love.physics.getMeter(), true)

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

            pobj.obj, pobj.objectID = newObject(Entities[1], {})

            table.insert(players, pobj)

            for _, k in ipairs(players) do
                net:create(peer, k.objectID, k.obj)
            end

            for _, k in ipairs(objects) do
                net:update(peer, k.objectID, k.obj)
            end
        end;
    }
end

function love.update(dt)
end

function love.draw(dt)
end
