set_idle_timeout(1000 * 1000)


file = io.open("log.txt")
pos = file:seek("end")
stop_at = nil
inputmap = {b=0, y=1, u=4, d=5, l=6, r=7, a=8, x=9}
inputmap["+"] = 3
inputmap["-"] = 2

keymap = {}

for k, v in pairs(inputmap) do
    keymap[v] = k
end

-- Buttons is the currently pressed set of
-- buttons from the user. Buttons maps from
-- a numeric button code to a boolean.
buttons = {}


is_paused = false
just_loaded = false

function on_idle()
    newPos = file:seek("end")
    if newPos ~= pos then
        file:seek("set", pos)
        line = file:read("L")
        print(line)
        pos = pos + string.len(line)
        -- t is a list of the tokens in the
        -- input command.
        t = {}
        ntokens = 0
        unpause = true
        for token in string.gmatch(line, "[^%s]+") do
            ntokens = ntokens + 1
            table.insert(t, token)
        end
        if ntokens == 1 then
            cmd = ""
            frames = tonumber(t[1])-1
        else
            cmd = ""
            if t[1] == "save" then
                exec("save-state " .. t[2])
                unpause = false
            elseif t[1] == "load" then
                exec("load-state " .. t[2])
                just_loaded = true
                unpause = false
            else
                cmd = t[1]:lower()
                frames = tonumber(t[2])-1
            end
        end
        input.reset()
        buttons={}
        for c in string.gmatch(cmd, ".") do
            i = inputmap[c]
            if i ~= nil then
                buttons[i] = true
            end
        end
        stop_at = movie.currentframe() + frames
        if unpause then
            is_paused = false
            exec("pause-emulator")
        end
    end
    -- Call this 2x/second
    set_idle_timeout(500 * 1000)
end

function on_input()
    -- print("input")
    for i=1,11 do
        input.set(0,i,0)
    end
    for k, v in pairs(buttons) do
        input.set(0, k, 1)
    end
end

skippablegamestates = {
    -- fade to overworld
    [0x0b] = true,
    -- load overworld
    [0x0c] = true,
    -- overworld fade in
    [0x0d] = true,
    -- fade to level
    [0x0f] = true,
    -- fade to level black
    [0x10] = true,
    -- load level
    [0x11] = true,
    -- prepare level
    [0x12] = true,
    -- level fade in
    [0x13] = true }


last_snapshot = 0
function on_frame()
    --curframe = movie.currentframe()
    --if curframe > last_snapshot + 60 then
    --    last_snapshot = curframe
    --    -- exec("save-state foo")
    --end
    -- Player animation status = 9 means
    -- we're dead, so wait until that's over.
    if memory.readbyte(0x7E0071) == 9 then
        return
    end
    gamestate = memory.readbyte(0x7E0100)
    if skippablegamestates[gamestate] ~= nil then
        return
    end
    if stop_at ~= nil and stop_at <= movie.currentframe() then
        exec("pause-emulator")
        is_paused = true
        stop_at = nil
    end
    if just_loaded then
        is_paused = true
        just_loaded = false
        stop_at = nil
        exec("pause-emulator")
    end
end

white = gui.color(255, 255, 255)
transparent = gui.color(255, 255, 255, 0)

function draw_circle(x, y, r, color, button)
    if buttons[inputmap[button]] then
        gui.circle(x, y, r, 1, color, color)
    else
        gui.circle(x, y, r, 1, color)
    end
end

function on_paint()
    raw_input = input.raw()
    -- left
    draw_circle(5, 10, 4, white, "l")
    -- up
    draw_circle(10, 4, 4, white, "u")
    -- right
    draw_circle(15, 10, 4, white, "r")
    -- down
    draw_circle(10, 16, 4, white, "d")

    -- y
    draw_circle(25, 10, 4, gui.color(0, 255, 0), "y")
    -- x
    draw_circle(30, 4, 4,  gui.color(0, 0, 255), "x")
    -- b
    draw_circle(30, 16, 4, gui.color(255, 255, 0), "b")
    -- a
    draw_circle(35, 10, 4, gui.color(255, 0, 0), "a")
end
