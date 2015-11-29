local ffi = require("ffi")

require "enet"

local connection_pktid = 0x01
local creation_pkktid = 0x02
local movement_pktid = 0x03
local update_pktid = 0x04
local destruction_pktid = 0x05

local clients = {}

ffi.cdef[[
    typedef struct {
        unsigned int ver;
        char name[32];
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
    } movement_pkt;
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

ffi.cdef[[
    typedef struct {
        unsigned int id;
    } destruction_pkt;
]]

local Net = {
    host = nil;
    server = nil;
    channel = nil;

    connectCallback = nil;
    disconnectCallback = nil;
    creationCallback = nil;
    updateCallback = nil;
    destructionCallback = nil;
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

    self.host = enet.host_create()
    self.server = nil
    self.connected = false

    return setmetatable(self, Net)
end

function Net:connect(ip)
    self.server = self.host:connect(ip, 5)
end

function Net:join(name, ver)
    if #name > 32 then
        error("Name can't be greater than 32 characters")
    end

    local data = ffi.new(ffi.typeof("connection_pkt"))

    data.name = ffi.string(ffi.new("char[32]", name), 32)
    data.ver = ver

    self.server:send(ffi.string(ffi.cast("const char*", data), ffi.sizeof(data)), creation_pktid)
end

function Net:move(mvt)
    local data = ffi.new(ffi.typeof("movement_pkt"))

    data.dir = bit.bor(bit.lshift(bit.band(mvt.up, 0x1), 3), bit.bor(bit.lshift(bit.band(mvt.down, 0x1), 2), bit.lshift(bit.band(mvt.left, 0x1), 1)), bit.band(mvt.right, 0x1))

    self.server:send(ffi.string(ffi.cast("const char*", data), ffi.sizeof(data)), movement_pktid)
end

function Net:parse(channel, data)
    if channel == 0 then
        if self.creationCallback then
            print("CREATE")
            local data = ffi.cast(ffi.typeof("creation_pkt*"), data)[0]
            self.creationCallback(data)
        end
    elseif channel == update_pktid then
        if self.updateCallback then
            local data = ffi.cast(ffi.typeof("update_pkt*"), data)[0]
            self.updateCallback(data)
        end
    elseif channel == destruction_pktid then
        if self.destructionCallback then
            print("DESTROY")
            local data = ffi.cast(ffi.typeof("destruction_pkt*"), data)[0]
            self.destructionCallback(data)
        end
    end
end

function Net:close()
    self.server:disconnect()
    self.host:flush()
    self.listening = false
end

function Net:read()
    local event = self.host:service()

    while event do
        if event.type == "connect" then
            self.conencted = true

            if self.connectCallback then
                self.connectCallback()
            end
        elseif event.type == "receive" then
            self:parse(event.channel, event.data)
        elseif event.type == "disconnect" then
            self.conencted = false

            if self.disconnectCallback then
                self.disconnectCallback()
            end
        end

        event = self.host:service()
    end
end

return Net
