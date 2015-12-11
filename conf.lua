function love.conf(t)
	t.window = t.window or t.screen

    -- Set window/screen flags here.
    t.window.width = 1024
    t.window.height = 768

	t.title = "Mafia Madness"
	t.version = "0.9.2"

	t.screen = t.screen or t.window

	-- For Windows debugging
	t.console = true

	t.window.fsaa = 4
end
