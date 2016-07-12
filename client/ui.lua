local UI = {
    roll = "";
    equipped = nil;
    timer = "00:00";
    transparency = 0.6;
    chatOpen = false;
    nameEntryOpen = false;
    messages = {};

    defaultFont = love.graphics.newFont("shared/assets/fonts/Vera.ttf");
    mafiaFont = love.graphics.newFont("shared/assets/fonts/LaffRiotNF.ttf", 50);
    clockFont = love.graphics.newFont("shared/assets/fonts/Clocker.ttf", 24);
}

UI.__index = UI

function UI.new(self)
    self.isMafia = self.isMafia or false
    self.timer = self.timer or "00:00"
    self.transparency = self.transparency or 0.2

    self.chatOpen = self.chatOpen or false
    self.nameEntryOpen = self.nameEntryOpen or false

    self.tmpMsg = ""
    self.messages = self.messages or {}

    return setmetatable(self, UI)
end

function UI:msg(name, msg)
    table.insert(self.messages, {
        name = name;
        msg = msg;
    })

    local ind = 0
    local tlc = 0
    local mlc = math.floor(200 / (love.graphics.getFont():getHeight() + 1))

    for k, v in ipairs(self.messages) do
        local lc = math.ceil(love.graphics.getFont():getWidth(v.name .. ": " .. v.msg) / 200)
        tlc = tlc + lc

        if tlc > mlc then
            ind = k
            break
        end
    end

    if ind == 0 then return end

    local rmc = #self.messages - ind

    for i=1,rmc do
        table.remove(self.messages, 1)
    end
end

function UI:draw()
    if self.chatOpen then
        love.graphics.setColor(25, 25, 25, 25)
        love.graphics.rectangle("fill", 10, 10, 300, 200)
        love.graphics.rectangle("fill", 10, 220, 200, 12)
        love.graphics.setColor(255, 255, 255)

        love.graphics.print(self.tmpMsg, 10, 220)
    end

    if self.nameEntryOpen then
        love.graphics.setColor(25, 25, 25, 100)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(self.clockFont)

        love.graphics.print("Enter your Name", (love.graphics.getWidth() - self.clockFont:getWidth("Enter your Name")) / 2, (love.graphics.getHeight() / 2) - self.clockFont:getHeight())
        love.graphics.print(self.tmpMsg, (love.graphics.getWidth() - self.clockFont:getWidth(self.tmpMsg)) / 2, love.graphics.getHeight() / 2)
    end

    if #self.messages > 0 then
        local tot = ""

        for _, msg in ipairs(self.messages) do
            tot = tot .. msg.name .. ": " .. msg.msg .. "\n"
        end

        love.graphics.printf(tot, 10, 10, 200)
    end

    if self.roll ~= "" then
        love.graphics.setColor(25, 25, 25)
        love.graphics.setFont(self.mafiaFont)
        local text = "You are " .. self.roll
        love.graphics.print(text, love.graphics.getWidth() - self.mafiaFont:getWidth(text), love.graphics.getHeight() - 60)
    end

    if self.timer ~= "" then
        love.graphics.setFont(self.clockFont)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(self.timer, (love.graphics.getWidth() / 2) - self.clockFont:getWidth(self.timer), 0, 100, "center")
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.setFont(self.defaultFont)
end

return UI
