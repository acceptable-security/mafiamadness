function love.load(arg)
    if arg[2] then
        if arg[2] == "server" then
            require "server/main"
        else
            require "client/main"
        end
    else
        require "client/main"
    end

    love.load()
end
