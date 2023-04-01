var { Logger } = require("./logger")
var fs = require("fs")
var socio = require("./socio2")
var { EventHandler } = require("./afonyaEvents")
var http = require("http")
var url = require("url")

var config = JSON.parse(fs.readFileSync("config.json", "utf8"))
var logger = new Logger("MAIN")

global.server = {
    version: "1.0",
}

logger.log("YesVNC v" + server.version)
logger.log("Settng up ratelimits...")
global.rateLimit = {}
global.ratelimitData = {}
global.rateLimit.tickRatelimit = function() {
    for (let i in global.ratelimitData) {
        if (global.ratelimitData[i] != undefined) {
            for (let ii in global.ratelimitData[i].cache) {
                if (global.ratelimitData[i].cache[ii] != undefined) {
                    global.ratelimitData[i].cache[ii].end--
                    if (global.ratelimitData[i].cache[ii].end <= 0) {
                        global.ratelimitData[i].cache[ii] = undefined
                    }
                }
            }
        }
    }
    setTimeout(rateLimit.tickRatelimit, 1000)
}
global.rateLimit.createRatelimit = function(name, time, reqs) {
    global.ratelimitData[name] = {"time": time, "reqs": reqs, "cache": {}}
}
global.rateLimit.ratelimit = function(name, ip) {
    if (global.ratelimitData[name].cache[ip] == undefined) {
        global.ratelimitData[name].cache[ip] = {"reqs": 0, "end": 0}
    }
    global.ratelimitData[name].cache[ip].reqs++
    global.ratelimitData[name].cache[ip].end = global.ratelimitData[name].time
    if (global.ratelimitData[name].cache[ip].reqs > global.ratelimitData[name].reqs) {
        return true
    } else {
        return false
    }
}
rateLimit.tickRatelimit()

var eh = new EventHandler()
server.eh = eh

eh.on("request", function (request, response) {
    if (request.urla == "/socio") {
        response.writeHead(200, { "Content-Type": "application/javascript" })
        response.end(fs.readFileSync("./socio2-client.js"))
        return
    }
    let path = request.urla
    if (path == "/") {
        path = "index"
    }
    if (fs.existsSync("./public/" + path + ".jsx")) {
        let a = require("./public/" + path + ".jsx")
        try {
            a.run(request, response, config, request.ip, request.args, socketServer)
        } catch (e) {
            logger.error(e.stack)
            res.writeHead(500, {"Content-Type": "text/html"})
            let err = fs.readFileSync(__dirname + "/error.html", "utf-8")
            err = err.replace(/%error%/g,"500 Internal server error")
            res.write(err)
            res.end()
            return
        }
        let find = "./public" + path + ".jsx"
        while(find.includes("./")) {
            find = find.replace("./", "\\")
        }
        while(find.includes("/")) {
            find = find.replace("/", "\\")
        }
        let ndn = __dirname
        let ndncut = ndn.split("\\")
        let newtx = ""
        for (let i = 0; i < ndncut.length; i++) {
            if (i == ndncut.length-1) {
                newtx += ndncut[i]
            } else {
                if (i != ndncut.length-1) {
                    newtx += ndncut[i] + "\\"
                }
            }
        }
        find = newtx + find
        //console.log(require.cache);
        //console.log(find);
        //console.log(require.cache[find]);
        require.cache[find] = undefined
    } else {
        if (fs.existsSync("./public/" + path + ".html")) {
            response.writeHead(200, { "Content-Type": "text/html" })
            response.end(fs.readFileSync("./public/" + path + ".html"))
        } else {
            if (fs.existsSync("./public/" + path + ".css")) {
                response.writeHead(200, { "Content-Type": "text/css" })
                response.end(fs.readFileSync("./public/" + path + ".css"))
            } else {
                if (fs.existsSync("./public/" + path + ".js")) {
                    response.writeHead(200, { "Content-Type": "text/javascript" })
                    response.end(fs.readFileSync("./public/" + path + ".js"))
                } else {
                    if (fs.existsSync("./public/" + path + ".lua")) {
                        response.writeHead(200, { "Content-Type": "text/plain" })
                        response.end(fs.readFileSync("./public/" + path + ".lua"))
                    } else {
                        response.writeHead(404, { "Content-Type": "text/plain" })
                        response.write("404 Not Found\n")
                        response.end()
                    }
                }
            }
        }
    }
})

http.createServer(function(req, res) {
    req.urla = req.url.split("?")[0]
    req.args = url.parse(req.url, true).query
    req.ip = req.connection.remoteAddress.replace("::ffff:", "")
    if (req.ip == "::1") {
        req.ip = "127.0.0.1"
    }
    eh.call("request", req, res)
}).listen(config.port, function() {
    logger.log("listening on port " + config.port)
})

var socketServer = socio.server(Number(config.ws), function() {
    logger.log("Socketting on: ws://localhost:" + Number(config.ws))
})
server.ws = socketServer.afapi

global.sockets = []

server.ws.on("connection", function(socket) {
    socket.sub = []
    socket.isSubscribed = function(evnt) {
        for (let i = 0; i < socket.sub.length; i++) {
            if (socket.sub[i].event == evnt) {
                return socket.sub[i]
            }
        }
        return false
    }
    socket.on("close", function() {
        if (global.sockets.includes(socket)) {
            global.sockets.splice(sockets.indexOf(socket), 1)   
        }

        if (socket.lid != undefined) {
            for (let i = 0; i < sockets.length; i++) {
                let sub = sockets[i].isSubscribed("screen")
                if (sub != false && sub.args[0] == socket.lid) {
                    sockets[i].emit("disconnected")
                }
            }
        }
    })
    socket.on("subscribe", function(event, ...args) {
        socket.sub.push({event: event, args: args})
    })
    socket.on("computer", function(type, lid, id) {
        socket.lid = lid
        for (let i = 0; i < sockets.length; i++) {
            let sub = sockets[i].isSubscribed("screen")
            if (sub != false && sub.args[0] == lid) {
                sockets[i].emit("connected", type, id)
            }
        }
    })
    socket.on("screen", function(lid, ...args) {
        for (let i = 0; i < sockets.length; i++) {
            let sub = sockets[i].isSubscribed("screen")
            if (sub != false && sub.args[0] == lid) {
                sockets[i].emit("screen", ...args)
            }
        }  
    })
    socket.on('interact', function(lid, ...args) {
        for (let i = 0; i < sockets.length; i++) {
            let sub = sockets[i].isSubscribed("interact")
            if (sub != false && sub.args[0] == lid) {
                sockets[i].emit("interact", ...args)
            }
        }
    })
    global.sockets.push(socket)
})