var fs = require("fs")

function getCallerFile() {
    var filename;
    var _pst = Error.prepareStackTrace
    Error.prepareStackTrace = function (err, stack) { return stack; };
    try {
        var err = new Error();
        var callerfile;
        var currentfile;
        currentfile = err.stack.shift().getFileName();
        while (err.stack.length) {
            callerfile = err.stack.shift().getFileName();
            if(currentfile !== callerfile) {
                filename = callerfile;
                break;
            }
        }
    } catch (err) {}
    Error.prepareStackTrace = _pst;
    if (filename == "node:internal/modules/cjs/loader") {
      filename = process.mainModule.filename
    }
    if (filename == "internal/modules/cjs/loader.js") {
      filename = process.mainModule.filename
    }
    if (filename == "node:events") {
      filename = "EventHandler"
    }
    if (filename == "events.js") {
      filename = "EventHandler"
    }
    if (filename == undefined) {
      filename = "None"
    }
    return filename.split(".")[0].replace(__dirname, "").replace("\\","");
}

function getTime() {
    var datetime = new Date().toISOString();
    var date = datetime.split("T")[0]
    var year = date.split("-")[0]
    var mout = date.split("-")[1]
    var sun = date.split("-")[2]
    var time = datetime.split("T")[1]
    time = time.split(".")[0]
    var hour = time.split(":")[0]
    hour = Number(hour) + 1
    var min = time.split(":")[1]
    var sec = time.split(":")[2]
    //console.log(datetime/*.toISOString().slice(0,10)*/);
    //console.log(year + ". " + mout + ". " + sun + ". " + hour + ":" + min + ":" + sec);
    let outa = year + ". " + mout + ". " + sun + ". " + hour + ":" + min + ":" + sec
    return outa
}

if (!fs.existsSync("./logs/")) {
    fs.mkdirSync("./logs/")
}
var logFile = getTime()
while (logFile.includes(" ")) {
    logFile = logFile.replace(" ","_")
}
while (logFile.includes(":")) {
    logFile = logFile.replace(":","_")
}
logFile = "./logs/" + logFile + ".log"
fs.writeFileSync(logFile, "")

class Logger {
    constructor(name, settings) {
        this.name = name
        this.settings = settings
        this.file = getCallerFile()
    }

    log(...text) {
        let lag = fs.readFileSync(logFile, "utf-8")
        let txt = ""
        for (let i = 0; i < text.length; i++) {
            txt = txt + text[i] + "   "
        }
        console.log(`\x1b[34m[LOG] \x1b[35m[${getTime()}] \x1b[32m[${this.name}]: \x1b[35m${txt}\x1b[0m`);
        lag = lag + `[LOG] [${getTime()}] [${this.name}]: ${txt}\n`
        fs.writeFileSync(logFile, lag)
    }

    debug(...text) {
        let lag = fs.readFileSync(logFile, "utf-8")
        let txt = ""
        for (let i = 0; i < text.length; i++) {
            txt = txt + text[i] + "   "
        }
        console.log(`\x1b[36m[DEBUG] \x1b[35m[${getTime()}] \x1b[32m[${this.name}]: \x1b[35m${txt}\x1b[0m`);
        lag = lag + `[DEBUG] [${getTime()}] [${this.name}]: ${txt}\n`
        fs.writeFileSync(logFile, lag)
    }

    warn(...text) {
        let lag = fs.readFileSync(logFile, "utf-8")
        let txt = ""
        for (let i = 0; i < text.length; i++) {
            txt = txt + text[i] + "   "
        }
        console.log(`\x1b[33m[WARN] \x1b[35m[${getTime()}] \x1b[32m[${this.name}]: \x1b[35m${txt}\x1b[0m`);
        lag = lag + `[WARN] [${getTime()}] [${this.name}]: ${txt}\n`
        fs.writeFileSync(logFile, lag)
    }

    error(...text) {
        let lag = fs.readFileSync(logFile, "utf-8")
        let txt = ""
        for (let i = 0; i < text.length; i++) {
            txt = txt + text[i] + "   "
        }
        console.log(`\x1b[31m[ERROR] \x1b[35m[${getTime()}] \x1b[32m[${this.name}]: \x1b[35m${txt}\x1b[0m`);
        lag = lag + `[ERROR] [${getTime()}] [${this.name}]: ${txt}\n`
        fs.writeFileSync(logFile, lag)
    }
}

exports.Logger = Logger

/*let logger = new Logger("test")
logger.log("asd", "wasdf", "lkefe")
logger.debug("asd","kefír?", "manya!")
logger.warn("asd", "wasdf", "lkefe")
logger.error("asd","kefír?", "manya!")*/