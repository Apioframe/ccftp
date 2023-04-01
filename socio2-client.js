class EventHandler {
    constructor() {
        this.events = {}
    }
    on(event, callback) {
        if (this.events[event] == undefined) {
            this.events[event] = []
        }
        this.events[event].push(callback)
    }
    off(event, callback) {
        if (this.events[event] == undefined) {
            this.events[event] = []
        }
        if (this.events[event].includes(callback)) {
            this.events[event].splice(events[event].indexOf(callback), 1)
        }
    }
    call(event, ...args) {
        if (this.events[event] == undefined) {
            this.events[event] = []
        }
        for (let i = 0; i < this.events[event].length; i++) {
            this.events[event][i](...args)
        }
    }
}

class Socio {
    constructor(uri) {
        let ws = new WebSocket(uri)
        this.ws = ws
        let eh = new EventHandler()
        this.eh = eh
        this.ws.onmessage = function(data) {
            let pars = undefined
            try {
                pars = JSON.parse(data.data)
                eh.call(...pars)
            } catch (e) {
                console.log("Failed to parse socket data!");
                console.error(e.stack);
            }
        }
        this.ws.onclose = function () {
            eh.call("close")
        }
        this.close = function() {
            this.ws.close()
        }
        this.on = function(...data) { this.eh.on(...data) }
        this.off = function(...data) { this.eh.off(...data) }
        this.emit = function(...data) {
            let d = JSON.stringify(data)
            if (ws.readyState == WebSocket.OPEN) {
                ws.send(d)
            } else {
                setTimeout(this.emit,1000,...data)
            }
        }
    }
}