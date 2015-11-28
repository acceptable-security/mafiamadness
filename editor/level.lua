require "json/json"
local Player = require("player")
local Object = require("object")
local Camera = require("camera")

local Level = {
    world = nil;
    player = nil;
    camera = nil;

    objects = {};
    file = "";
    gravity = 9.81;

    debug = false;
}

Level.__index = Level

function Level.new(self)
    self.gravity = self.gravity or 9.81
    self.file = self.file or ""

    self.world = self.world or love.physics.newWorld(0, self.gravity * love.physics.getMeter(), true)
    self.camera = self.camera or Camera.new{}
    self.objects = self.objects or {}

    self.debug = self.debug or false

    self = setmetatable(self, Level)

    if self.file then self:_load(self.file) end

    return self
end

function Level:_load(file)
    local content, _ = love.filesystem.read(file)

    local obj = json.decode(content)

    if obj.player then
        obj.player.world = self.world

        local old = obj.player.images
        obj.player.images = {}

        for k, v in pairs(old) do
            obj.player.images[k] = {}

            for _, i in pairs(v) do
                table.insert(obj.player.images[k], love.graphics.newImage(i or ""))
            end
        end

        self.player = Player.new(obj.player)
    end

    if obj.objects then
        for _, v in ipairs(obj.objects) do
            v.world = self.world
            v.image = love.graphics.newImage(v.image)
            table.insert(self.objects, Object.new(v))
        end
    end

    if obj.camera then
        self.camera = Camera.new(obj.camera)
    end

    if obj.background then
        for k, v in pairs(obj.background) do
            local imgs = {}

            for _, img in pairs(v) do
                table.insert(imgs, {
                    x = img.x;
                    y = img.y;
                    img = love.graphics.newImage(img.img);
                })
            end

            self.camera:newLayer(tonumber(k), function ()
                for _, i in ipairs(imgs) do
                    love.graphics.draw(i.img, i.x, i.y)
                end
            end)
        end
    end
end

function Level:update(dt)
    self.world:update(dt) --this puts the world into motion
    self.camera:setPosition((self.player.body:getX() - (love.graphics.getWidth() / 2)) / 2,
                            (self.player.body:getY() - (love.graphics.getHeight() / 2)) / 2)
    self.player:update(dt)
end

function Level:draw(dt)
    self.camera:draw()
    self.camera:set()

    for _, v in ipairs(self.objects) do
        v:draw()
    end

    love.graphics.setColor(255, 255, 255)
    self.player:draw()
    self.camera:unset()
end

return Level
