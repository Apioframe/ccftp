--[[
        if epoch % 5 == 0 then
            local percent = (epoch/epochs)*100
            print((math.floor(percent*100)/100).."% ("..epoch.."/"..epochs..")")
        end
]]

function hash(m, epochs, salt)
    local nums = {}
    for i=1,#m,1 do
        local ch = m:sub(i,i)
        table.insert(nums, string.byte(ch))
    end
    for epoch=1,epochs,1 do
        if epoch % 2 == 0 then
            for k,v in ipairs(nums) do
                nums[k] = v + salt + (nums[k+1] or nums[1])
            end
        else
            for k,v in ipairs(nums) do
                local p = tostring(v)
                local q = ""
                for i=#p,1,-1 do
                    q = q .. p:sub(i,i)
                    if i % 1000 == 0 then
                        os.sleep(0.1)
                    end
                end
                nums[k] = tonumber(q)
            end
            for i=#nums,1,-1 do
                nums[i] = nums[i] + salt + (nums[i-1] or nums[#nums])
                if i % 1000 == 0 then
                    os.sleep(0.1)
                end
            end
        end
    end
    local out = ""
    for k,v in ipairs(nums) do
        --random stolen to hex :D
        out = out..("%2x"):format(v)
    end
    out = out:sub(1, 32)
    return out
end

return hash