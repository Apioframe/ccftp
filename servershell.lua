function cmd()
    shell.run("clear")
    print("Warning: if your server crashes then you cant get the error reason, to debug dont use the async server!")
    local ok, err = pcall(shell.run, "shell")
    cmd()
end
function cod()
    local ok, err = pcall(shell.run, "ftpserver.lua")
    cod()
end
parallel.waitForAll(cod, cmd)