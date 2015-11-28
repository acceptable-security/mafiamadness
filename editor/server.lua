local enet = nil
local ffi = require("ffi")

require "enet"

local connection_pktid = 0x01;
local movement_pktid = 0x02;

local clients = {}

ffi.cdef[[
    typedef struct {
        unsigned char type;
        unsigned int id;
        const char* name;
    } connection_pkt;
]]

ffi.cdef[[
    typedef struct {
        unsigned char type;
        unsigned int id;
        unsigned char dir;
    } update_pkt;
]]

function packUpdate(id, dir)
    local data = ffi.new(ffi.typeof("update_pkt"), {})
    data.dir = dir
    data.id = id
    return ffi.string(ffi.cast("const char*", data), ffi.sizeof(data))
end

local host = enet.host_create("localhost:5451")

while true do
    local event = host:service(100)

    if event and event.type == "receive" then
        if event.data[1] == connection_pktid then
            local data = ffi.cast(ffi.typeof("update_pkt*"), event.data)[0]
            table.insert(clients, {
                clientID = data.id;
                peer = event.peer;
            })
        elseif event.data[1] == movement_pktid then
            local data = ffi.cast(ffi.typeof("movement_pkt*"), event.data)[0]

            for _, v in ipairs(clients) do
                -- v.send()
            end
        end

        event.peer:send(event.data)
    end
end
