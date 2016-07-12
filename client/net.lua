local mp = require("shared/MessagePack")

require "enet"

mp.set_number('float')
mp.set_array('with_hole')
mp.set_string('string')

local connection_pktid = 1
local creation_pkktid = 2
local movement_pktid = 3
local update_pktid = 4
local destruction_pktid = 5
local chat_pktid = 6
local asset_pktid = 7
local shoot_pktid = 8
local control_pktid = 9
local game_pktid = 10

local clients = {}

local Net = {
    host = nil;
    server = nil;
    channel = nil;

    connectCallback = nil;
    disconnectCallback = nil;
    creationCallback = nil;
    updateCallback = nil;
    destructionCallback = nil;
    assetCallback = nil;
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
    self.server = self.host:connect(ip, 11)
end

function Net:join(name, ver)
    local data = {
        name = name;
        ver = ver;
    }

    self.server:send(mp.pack(data), connection_pktid, "reliable")
end

function Net:shoot()
    local data = {}

    self.server:send(mp.pack(data), shoot_pktid, "unreliable")
end

function Net:msg(msg, loc)
    local data = {
        msg = msg;
        loc = loc;
    }

    self.server:send(mp.pack(data), chat_pktid, "reliable")
end

function Net:move(mvt)
    self.server:send(mp.pack(mvt), movement_pktid, "unreliable")
end

function Net:parse(channel, data)
    if channel == 0 then
        if self.creationCallback then
            self.creationCallback(mp.unpack(data))
        end
    elseif channel == update_pktid then
        if self.updateCallback then
            self.updateCallback(mp.unpack(data))
        end
    elseif channel == destruction_pktid then
        if self.destructionCallback then
            self.destructionCallback(mp.unpack(data))
        end
    elseif channel == chat_pktid then
        if self.chatCallback then
            self.chatCallback(mp.unpack(data))
        end
    elseif channel == asset_pktid then
        if self.assetCallback then
            self.assetCallback(mp.unpack(data))
        end
    elseif channel == shoot_pktid then
        if self.shootCallback then
            self.shootCallback(mp.unpack(data))
        end
    elseif channel == control_pktid then
        if self.controlCallback then
            self.controlCallback(mp.unpack(data))
        end
    elseif channel == game_pktid then
        if self.gameCallback then
            self.gameCallback(mp.unpack(data))
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
