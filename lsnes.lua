set_idle_timeout(1000 * 1000)


file = io.open("log.txt")
pos = file:seek("end")
stop_at = nil
inputmap = {b=0, y=1, u=4, d=5, l=6, r=7, a=8, x=9}
buttons = {}
function on_idle()
    print("idle")
    newPos = file:seek("end")
    if newPos ~= pos then
        file:seek("set", pos)
        line = file:read("L")
        print(line)
        pos = pos + string.len(line)
        t = {}
        for token in string.gmatch(line, "[^%s]+") do
            table.insert(t, token)
        end
        cmd = t[1]:lower()
        frames = tonumber(t[2])
        input.reset()
        buttons={}
        for c in string.gmatch(cmd, ".") do
            i = inputmap[c]
            if i ~= nil then
                buttons[i] = true
            end
        end
        stop_at = movie.currentframe() + frames
        exec("pause-emulator")
    end
    -- Call this every second
    set_idle_timeout(1000 * 1000)
end

function on_input()
    print("hi")
    for i=1,11 do
        print(1,i,0)
        input.set(0,i,0)
    end
    for k, v in pairs(buttons) do
        print(1,k,1)
        input.set(0, k, 1)
    end
end

function on_frame()
    if stop_at ~= nil and stop_at <= movie.currentframe() then
        exec("pause-emulator")
        stop_at = nil
    end
end
