local Net = require("server/net")
local Entities = require("shared/entities")
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

    assetMgr = AssetManager.new {
        world = world;
    }

    print("loaded " .. assetMgr:load {
        name = "box";
        file = "shared/assets/png/block.png";
        bodyType = "static";
        type = "object";
    })

    print("loaded " .. assetMgr:load {
        name = "player";
        rotable = false;
        file = {
            root = {
                "shared/assets/png/character/front.png"
            };
            walking = {
                "shared/assets/png/character/walk/walk0001.png";
                "shared/assets/png/character/walk/walk0002.png";
                "shared/assets/png/character/walk/walk0003.png";
                "shared/assets/png/character/walk/walk0004.png";
                "shared/assets/png/character/walk/walk0005.png";
                "shared/assets/png/character/walk/walk0006.png";
                "shared/assets/png/character/walk/walk0007.png";
                "shared/assets/png/character/walk/walk0008.png";
                "shared/assets/png/character/walk/walk0009.png";
                "shared/assets/png/character/walk/walk0010.png";
                "shared/assets/png/character/walk/walk0011.png";
            };
            jumping = {
                "shared/assets/png/character/jump.png";
            };
            falling = {
                "shared/assets/png/character/jump.png";
            }
        };
        type = "player";
    })

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

            for _, k in pairs(assetMgr.assets) do
                net:createAsset(peer, k)
            end

            net:createObject(peer, pobj.objectID, pobj.obj)

            for _, k in pairs(players) do
                net:createObject(peer, k.objectID, k.obj)
            end

            for v, k in pairs(objects) do
                net:createObject(peer, k.objectID, k.obj)
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

            if d then
                d.obj:move(data)
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
    }

    createObject("box", 0, 200)
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
            net:update(k.peer, o.objectID, o.obj)
        end
    end
end

function love.draw(dt)
    love.graphics.print(#players .. " Players Active")
    love.graphics.print(objectID .. " current Object ID", 0, 10)
end
