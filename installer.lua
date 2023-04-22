print("Welcome to the CCFtp installer!")
print("Enter the version you want to install (client/server)")
local fi = io.read()

local repo = "afonya2/ccftp"
local branch = "main"
local files = {
    client = {
        ["client.lua"] = "ftpclient.lua",
        ["sga69.lua"] = "sga69.lua",
    },
    server = {
        ["server.lua"] = "ftpserver.lua",
        ["sga69.lua"] = "sga69.lua",
        ["servershell.lua"] = "ftpservershell.lua",
    }
}
if files[fi] == nil then
    print("Invalid version, exitting...")
    return
end
print("Downloading files...")
for k,v in pairs(files[fi]) do
    print("Downloading file "..k)
    local url = "https://raw.githubusercontent.com/"..repo.."/"..branch.."/"..k
    local con = http.get({url = url, binary = true})
    local h = fs.open(v, "wb")
    h.write(con.readAll())
    h.close()
    print("done")
end
if fi == "server" then
    print("Enter the port you want to use on the ftp")
    local port = tonumber(io.read())
    print("Enter the first user's username")
    local username = io.read()
    print("Enter "..username.."'s password")

    function hiddenread()
        term.setCursorBlink(true)
        local input = ""
        function a()
            while true do
                local event, key, is_held = os.pullEvent("key")
                key = keys.getName(key)
                if key == "backspace" then
                    input = string.sub(input, 1, #input-1)
                else
                    if key == "enter" then
                        term.setCursorBlink(false)
                        break
                    end
                end
                os.sleep(0)
            end
        end
        function b()
            while true do
                local event, key = os.pullEvent("char")
                input = input..key
                os.sleep(0)
            end
        end
        parallel.waitForAny(a,b)
        local x,y = term.getCursorPos()
        term.setCursorPos(1,y+1)
        return input
    end

    local password = hiddenread()
    print("How many characters/packet do you want")
    local cpp = tonumber(io.read())
    print("Configuring...")
    local confi = {
        port = port,
        users = {},
        parts = cpp
    }
    confi.users[username] = {
        password = password,
    }
    local cof = fs.open("ftp.conf", "w")
    cof.write(textutils.serialise(confi))
    cof.close()
    print("Done")
    print("To add other configuration edit the ftp.conf file")
    print("If you want to start the ftp by default rename the ftpserver.lua to startup.lua")
    print("If you want to use the ftpserver while a console is running rename the ftpservershell.lua to startup.lua")
end
if fi == "client" then
    print("If you want to use the client run: ftpclient <username@port>")
end