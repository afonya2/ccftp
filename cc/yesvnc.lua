local args = {...}

local getSocket = require("socio")
if _G.yesvnc ~= nil then
    print("Command not understood")
else
    function copy(table)
        local out = {}
        for k,v in pairs(table) do
            out[k] = v
        end
        return out
    end

    if #args ~= 2 then
        print("Usage: yesvnc.lua <hostname> <id>")
        return
    end
    local soc
    function conn()
        soc = getSocket(args[1])
        soc.emit("computer", "cc", args[2], os.getComputerID())
        local w,h = term.getSize()
        soc.emit("screen", {{"resize", w, h}})
        soc.on("close", function()
            os.shutdown()
        end)
    end

    conn()
    print("Connected")
    local oterm = copy(term)

    function senndy()
        while true do
            if #queue > 0 then
                local sent = {}
                for i=1,50,1 do
                    table.insert(sent, queue[i])
                end
                soc.emit("screen", sent)
                for i=1,50,1 do
                    table.remove(queue, 1)
                end
            end
            os.sleep(0.1)
        end
    end

    _G.queue = {}
    for k,v in pairs(term) do
        if (k ~= "redirect") and (k ~= "current") then
            term[k] = function(...)
                local tosend = {k}
                for k,v in ipairs({...}) do
                    if (type(v) == "number") or (type(v) == "string") then
                        table.insert(tosend, v)
                    end
                end
                table.insert(queue, tosend)
                --pcall(soc.emit,"screen", k, table.unpack(tosend))
                return v(...) 
            end
        end
    end
    _G.yesvnc = {soc=soc,oterm=oterm}

    parallel.waitForAny(senndy, function()
        shell.run("clear")
        shell.run("shell")
    end)
    yesvnc.soc.close()
    term = yesvnc.oterm
    print("Connection closed")
    _G.yesvnc = nil
end