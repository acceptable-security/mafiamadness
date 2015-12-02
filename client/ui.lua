local UI = {
    roll = "an Innocent";
    equipped = nil;
    timer = "00:00";
    transparency = 0.6;

    defaultFont = love.graphics.newFont("shared/assets/fonts/Vera.ttf");
    mafiaFont = love.graphics.newFont("shared/assets/fonts/LaffRiotNF.ttf", 50);
    clockFont = love.graphics.newFont("shared/assets/fonts/Clocker.ttf", 24);
}

UI.__index = UI

function UI.new(self)
    self.isMafia = self.isMafia or false
    self.equipped = self.equipped or nil
    self.timer = self.timer or "00:00"
    self.transparency = self.transparency or 0.2

    return setmetatable(self, UI)
end

function UI:draw()
    if self.equipped then
        local r = math.sqrt(math.pow(self.equipped:getWidth(), 2) + math.pow(self.equipped:getHeight(), 2)) / 2
        love.graphics.setColor(0, 0, 0, self.transparency * 255)
        love.graphics.circle("fill", r, (love.window.getHeight() - (r * 2)) + (r/2), r)
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(self.equipped, math.floor(r - (self.equipped:getWidth()/2)), math.floor((love.window.getHeight() - (r * 2)) + (r/2) - (self.equipped:getHeight()/2)))
    end

    love.graphics.setColor(25, 25, 25)
    love.graphics.setFont(self.mafiaFont)
    local text = "You are " .. self.roll
    love.graphics.print(text, love.window.getWidth() - self.mafiaFont:getWidth(text), love.window.getHeight() - 60)

    love.graphics.setFont(self.clockFont)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(self.timer, (love.graphics.getWidth() / 2) - self.clockFont:getWidth(self.timer), 0, 100, "center")

    love.graphics.setColor(255, 255, 255)
    love.graphics.setFont(self.defaultFont)
end

return UI
