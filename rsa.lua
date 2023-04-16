function customFor(start, expression, cb)
    local i = start
    while expression(i) do
        cb(i)
        i = i + 1
    end
end

function isPrime(n)
    if n <= 1 then
        return false
    end
    local outer = true
    customFor(2, function(i) return i * i <= n end, function(i)
        if n % i == 0 then
            outer = false
        end
    end)
    return outer
end

function genPrimes(max, start)
    if start == nil then 
        start = 0
    end
    local out = {}
    customFor(1, function(i) return #out < max end, function(i)
        if isPrime(i) then
            table.insert(out, i)
        end
    end)
    return out
end

function isCooprime(a,b)
    local smaller = 0
    if a > b then
        smaller = a
    else
        smaller = b
    end
    for ind = 2, smaller, 1 do
        local c1 = a % ind == 0
        local c2 = b % ind == 0
        if c1 and c2 then
            return false
        end
    end
    return true
end

function gcd(a, b)
    if a == 0 then
        return b
    end

    return gcd(b % a, a)
end

function lcm(a, b)
    return (a * b) / gcd(a,b)
end

function modInverse(a, m)
    local m0 = m
    local t,q
    local x0 = 0
    local x1 = 1
    if m == 1 then
        return 0
    end

    while a > 1 do
        q = math.floor(a / m)
        t = m
        m = a % m
        a = t
        t = x0
        x0 = x1 - q * x0
        x1 = t
    end

    if x1 < 0 then
        x1 = x1 + m0
    end

    return x1
end 

function generateKeyPairs()
    local pa = math.random(1, 9)
    local pb = math.random(1, 9)
    local pc = math.random(1, 9)
    local pd = math.random(1, 9)
    local pe = math.random(1, 9)
    local pf = math.random(1, 9)
    local nim = "1"..tostring(pa)..tostring(pb)..tostring(pc)..tostring(pd)..tostring(pe)..tostring(pf)
    local primes = genPrimes(100, tonumber(nim))

    local p = primes[math.random(1, #primes)]
    local q = primes[math.random(1, #primes)]
    local n = p * q
    local yn = lcm(p-1, q-1)
    local e
    while (e == nil) or (gcd(e, yn) ~= 1) do
        e = math.random(1, yn-2) + 2
    end
    local d = modInverse(e, yn)
    return {
        publicKey = {n = n, e = e},
        privateKey = {n = n, d = d},
    }
end

function modExp(a,b,n)
    local result = 1
    a = a % n
    while b > 0 do
        if b % 2 == 1 then
            result = (result * a) % n
        end
        b = math.floor(b / 2)
        a = (a * a) % n
    end
    return result
end

function encode(key, m)
    return modExp(m,key.e,key.n)
end

function decode(key, c)
    return modExp(c,key.d,key.n)
end

function encodeString(key, m)
    local out = {}
    for i=1, #m, 1 do
        local char = string.byte(m, i)
        table.insert(out, modExp(char,key.e,key.n))
    end
    local oout = ""
    for k,v in ipairs(out) do
        out[k] = ("%2x"):format(v)
    end
    for k,v in ipairs(out) do
        oout = oout .. v .. "AA"
    end
    return oout:sub(1, #oout-2)
end

function mysplit (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function decodeString(key, c)
    local out = ""
    local spi = mysplit(c, "AA")
    for k,v in ipairs(spi) do
        spi[k] = tonumber(v, 16)
    end
    for k,v in ipairs(spi) do
        local char = modExp(tonumber(v), key.d, key.n)
        out = out..string.char(char)
    end
    return out
end

local keys = generateKeyPairs()
print(textutils.serialise(keys))
local eac = encode(keys.publicKey, 127)
print(eac)
print(decode(keys.privateKey, eac))

local eas = encodeString(keys.publicKey, "Hello, world!")
print(eas)
print(decodeString(keys.privateKey, eas))