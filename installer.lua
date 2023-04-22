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
print("Enter the port you want to use on the ftp")
local port = tonumber(io.read())
print("Enter the first user's username")
local username = io.read()
print("Enter "..username.."'s password")
local password = io.read()
print("Configuring...")
local confi = {
    port = port,
    users = {}
}
confi.users[username] = {
    password = password,
}
print("Done")
print("To add other configuration edit the ftp.conf file")
print("If you want to start the ftp by default rename the ftpserver.lua to startup.lua")
print("If you want to use the ftpserver while a console is running rename the ftpservershell.lua to startup.lua")