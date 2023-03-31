var ws = require("nodejs-websocket")
var { EventHandler } = require("./afonyaEvents")
var { Logger } = require("./logger")

var logger = new Logger("Main/Socket")

exports.server = function(port, callback) {
    var out = new EventHandler()
    var socketServer = ws.createServer(function(conn) {
        let outt = {}
        outt.raw = conn
        outt.eh = new EventHandler()
        conn.on("text", function (str) {
            let pars = undefined
            try {
                //logger.debug(str)
                pars = JSON.parse(str)
                outt.eh.call(...pars)
            } catch (e) {
                logger.error("Failed to parse socket data!");
            }
        })
        conn.on("close", function () {
            outt.eh.call("close")
        })
        conn.on("error", function(err) {
            outt.eh.call("error", err)
        })
        outt.close = function() {
            conn.close()
        }
        outt.on = function(...data) { outt.eh.on(...data) }
        outt.off = function(...data) { outt.eh.off(...data) }
        outt.emit = function(...data) {
            let d = JSON.stringify(data)
            conn.sendText(d)
        }
        out.call("connection", outt)
    })
    socketServer.listen(port, callback)
    socketServer.afapi = out
    return socketServer
}