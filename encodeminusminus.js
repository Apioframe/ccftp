var abc = ["ö","ü","ó","q","w","e","r","t","z","u","i","o","p","ő","ú","ű","a","s","d","f","g","h","j","k","l","é","á","í","y","x","c","v","b","n","m","Ö","Ü","Ó","Q","W","E","R","T","Z","U","I","O","P","Ő","Ú","Ű","A","S","D","F","G","H","J","K","L","É","Á","Í","Y","X","C","V","B","N","M"," ","@","=","!","/","%",".",",","#","&","$","{","}","[","]","?",":","+","(",")","-","0","1","2","3","4","5","6","7","8","9"]

function rawEncrypt(string) {
    let out = ""
    for (let i = 0; i < string.length; i++) {
        if (abc.includes(string[i])) {
            if (abc.indexOf(string[i]) < 10) {
                out = out + "0" + abc.indexOf(string[i])
            } else {
                out = out + abc.indexOf(string[i])
            }
        }
    }
    return out
}

function rawDecrypt(code) {
    let out = ""
    for (let i = 0; i < code.length; i++) {
        if (abc[Number(code[i] + code[i+1])] != undefined) {
            out = out + abc[Number(code[i] + code[i+1])]
        }
        i++
    }
    return out
}

//console.log(rawEncrypt("öasd"))
//console.log(rawDecrypt(rawEncrypt("öasd")))

function betterIndexOf(table, string) {
    for (let i in table) {
        if (table[i] == string) {
            return i
        }
    }
    return undefined
}

function generateToken(len) {
    let out = ""
    for (let i = 0; i < len; i++) {
        out = out + abc[Math.floor(Math.random() * abc.length)]
    }
    return out
}

class Key {
    key = {}
    num = 0
    string = ""
    validateId = ""

    constructor(a, b) {
        if (typeof(a) == "number") {
            if (b != undefined) {
                this.load(b, a)
            } else {
                this.generate(a)
            }
        } else if (typeof(a) == "string") {
            if (a != undefined) {
                this.load(a, b)
            } else {
                this.generate(b)
            }
        } else {
            this.generate()
        }
    }
    generate(num) {
        if (num == undefined) {
            num = 5
        }
        let canBe = abc.slice()
        let out = {}
        while (canBe.length > 0) {
            let g = ""
            for (let i = 0; i < num; i++) {
                g = g + abc[Math.floor(Math.random() * abc.length)]
            }
            out[canBe[0]] = g
            canBe.splice(0,1)
        }
        this.key = out
        this.num = num
        this.export()
        this.validateId = generateToken(10)
    }
    load(string,num) {
        if (string == undefined) {
            string = this.string
        }
        if (num == undefined) {
            num = 5
        }
        let out = {}
        for (let i = 10; i < string.length; i++) {
            out[string[i]] = ""
            for (let ii = 1; ii < num+1; ii++) {
                out[string[i]] = out[string[i]] + string[i+ii]
            }
            i = i + num
        }
        this.key = out
        this.num = num
        this.export()
        let k = ""
        for (let i = 0; i < 10; i++) {
            k = k + string[i]
        }
        this.validateId = k
    }
    export() {
        let out = ""
        for (let i in this.key) {
            out = out + i + this.key[i]
        }
        this.string = this.validateId + out
        return this.validateId + out
    }

    encrypt(string) {
        let out = ""
        for (let i = 0; i < string.length; i++) {
            out = out + this.key[string[i]]
        }
        return out
    }
    decrypt(code) {
        let out = ""
        for (let i = 0; i < code.length; i++) {
            let szissz = ""
            for (let ii = 0; ii < this.num; ii++) {
                szissz = szissz + code[i+ii]
            }
            if (betterIndexOf(this.key, szissz) != undefined) {
                out = out + betterIndexOf(this.key, szissz)
            }
            i = i + this.num - 1
        }
        return out
    }
}

exports.Key = Key