local ffi = require("ffi")

require "enet"

local connection_pktid = 0x01
local creation_pkktid = 0x02
local movement_pktid = 0x03
local update_pktid = 0x04

local clients = {}

ffi.cdef[[
    typedef struct {
        unsigned int ver;
        const char name[32];
    } connection_pkt;
]]

ffi.cdef[[
    typedef struct {
        unsigned int id;
        unsigned int type;
        float px;
        float py;
        float vx;
        float vy;
        float a;
    } creation_pkt;
]]

ffi.cdef[[
    typedef struct {
        char dir;
    } movement_pkt
]]

ffi.cdef[[
    typedef struct {
        unsigned int id;
        int px;
        int py;
        int vx;
        int vy;
        float a;
    } update_pkt;
]]

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

    self.host = enet.host_create(self.ip, nil, 4)
    self.server = nil
    self.connected = false

    return setmetatable(self, Net)
end

function Net:create(peer, id, obj)
    local type = nil

    for k, v in Entities.entities do
        if v.type == obj.type then
            type = k
        end
    end

    if type == nil then
        error("Unable to identify type " .. obj.type)
    end

    local data = ffi.new(ffi.typeof("creation_pkt"))

    data.id = id
    data.type = type
    data.px = obj.body:getX()
    data.py = obj.body:getY()
    data.vx, data.vy = obj.body:getLinearVelocity()
    data.a = obj.body:getAngle()

    peer:send(ffi.string(ffi.cast("const char*", data), ffi.sizeof(data)), creation_pktid)
end

function Net:update(peer, id, body)
    if #name > 32 then
        error("Name can't be greater than 32 characters")
    end

    local data = ffi.new(ffi.typeof("update_pkt"))

    data.id = id
    data.px = obj.body:getX()
    data.py = obj.body:getY()
    data.vx, data.vy = obj.body:getLinearVelocity()
    data.a = obj.body:getAngle()

    peer:send(ffi.string(ffi.cast("const char*", data), ffi.sizeof(data)), update_pktid)
end

function Net:parse(peer, channel, data)
    if channel == connection_pktid then
        if self.joinCallback then
            local data = ffi.cast(ffi.typeof("creation_pkt*"), event.data)[0]
            self.creationCallback(peer, data)
        end
    elseif channel == movement_pktid then
        if self.movementCallback then
            local data = ffi.cast(ffi.typeof("movement_pkt*"), event.data)[0]
            self.movementCallback(peer, data)
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
                self.connectCallback(peer)
            end
        elseif event.type == "receive" then
            self:parse(event.peer, event.channel, event.data)
        elseif event.type == "disconnect" then
            if self.disconnectCallback then
                self.disconnectCallback(peer)
            end
        end

        event = self.host:service()
    end
end

return Net
