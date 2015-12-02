local Entities = require("shared/entities")
local mp = require("shared/MessagePack")

require "enet"

mp.set_number('float')
mp.set_array('with_hole')
mp.set_string('string')

local connection_pktid = 0x01
local creation_pkktid = 0x02
local movement_pktid = 0x03
local update_pktid = 0x04
local destruction_pktid = 0x05

local clients = {}

local Net = {
    host = nil;
    channel = nil;

    connectCallback = nil;
    disconnectCallback = nil;
    creationCallback = nil;
    movementCallback = nil;
}

Net.__index = Net

function Net.new(self)
    if self.server == "" then
        error("Unable to connect to an empty server")
        return nil
    end

    self.ip = self.ip or ""

    if self.ip == "connect" then
        error("Channel didn't have a connection on it")
        return nil
    end

    self.host = enet.host_create(self.ip, nil, 10)
    self.server = nil
    self.connected = false

    return setmetatable(self, Net)
end

function Net:create(peer, id, obj)
    local type = nil
    for k, v in ipairs(Entities.entities) do
        if v.type == obj.type then
            type = k
        end
    end

    if type == nil then
        error("Unable to identify type " .. obj.type)
        return
    end

    local vx, vy = obj.body:getLinearVelocity()

    data = {
        id = id;
        type = type;
        px = obj.body:getX();
        py = obj.body:getY();
        vx = vx;
        vy = vy;
        a = obj.body:getAngle();
    }

    peer:send(mp.pack(data), creation_pktid, "reliable")
end

function Net:update(peer, id, obj)
    local vx, vy = obj.body:getLinearVelocity()

    local data = {
        id = id;
        px = obj.body:getX();
        py = obj.body:getY();
        vx = vx;
        vy = vy;
        a = obj.body:getAngle();
    }

    peer:send(mp.pack(data), update_pktid, "unreliable")
end

function Net:destroy(peer, id)
    local data = {
        id = id;
    }

    peer:send(mp.pack(data), destruction_pktid, "unreliable")
end

function Net:parse(peer, channel, data)
    if channel == connection_pktid then
        if self.joinCallback then
            self.creationCallback(peer, mp.unpack(data))
        end
    elseif channel == movement_pktid then
        if self.movementCallback then
            self.movementCallback(peer, mp.unpack(data))
        end
    end
end

function Net:close()
    self.server:disconnect()
    self.host:flush()
    self.listening = false
end

function Net:listen()
    local event = self.host:service()

    while event do
        if event.type == "connect" then
            if self.connectCallback then
                self.connectCallback(event.peer)
            end
        elseif event.type == "receive" then
            self:parse(event.peer, event.channel, event.data)
        elseif event.type == "disconnect" then
            if self.disconnectCallback then
                self.disconnectCallback(event.peer)
            end
        end

        event = self.host:service()
    end
end

return Net
