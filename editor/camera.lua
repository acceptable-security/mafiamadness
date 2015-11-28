local Camera = {
    x = 0;
    y = 0;
    scaleX = 1;
    scaleY = 1;
    rotation = 0;
    layers = {};
}

Camera.__index = Camera

local function clamp(x, min, max)
    return x < min and min or (x > max and max or x)
end


function Camera.new(self)
    self.x = self.x or 0
    self.y = self.y or 0
    self.scaleX = self.scaleX or 1
    self.scaleY = self.scaleY or 1
    self.rotation = self.rotation or 0
    self.layers = self.layers or {}

    return setmetatable(self, Camera)
end

function Camera:set()
    love.graphics.push()
    love.graphics.rotate(-self.rotation)
    love.graphics.scale(1 / self.scaleX, 1 / self.scaleY)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:unset()
    love.graphics.pop()
end

function Camera:move(dx, dy)
    self:setX(self.x + (dx or 0))
    self:setY(self.y + (dy or 0))
end

function Camera:rotate(dr)
    self.rotation = self.rotation + dr
end

function Camera:scale(sx, sy)
    sx = sx or 1
    self.scaleX = self.scaleX * sx
    self.scaleY = self.scaleY * (sy or sx)
end

function Camera:setX(value)
    if self._bounds then
        self.x = clamp(value, self._bounds.x1, self._bounds.x2)
    else
        self.x = value
    end
end

function Camera:setY(value)
    if self._bounds then
        self.y = clamp(value, self._bounds.y1, self._bounds.y2)
    else
        self.y = value
  end
end

function Camera:setPosition(x, y)
    if x then self:setX(x) end
    if y then self:setY(y) end
end

function Camera:setScale(sx, sy)
    self.scaleX = sx or self.scaleX
    self.scaleY = sy or self.scaleY
end

function Camera:getBounds()
    return unpack(self._bounds)
end

function Camera:setBounds(x1, y1, x2, y2)
    self._bounds = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

function Camera:newLayer(scale, func)
    table.insert(self.layers, { draw = func, scale = scale })
    table.sort(self.layers, function(a, b) return a.scale < b.scale end)
end

function Camera:draw()
    local bx, by = self.x, self.y

    for _, v in ipairs(self.layers) do
        self.x = bx * v.scale
        self.y = by * v.scale
        self:set()
        v.draw()
        self:unset()
    end
end

return Camera
