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

exports.EventHandler = EventHandler