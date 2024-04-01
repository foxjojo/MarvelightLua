-- local ngx = require "ngx"
-- local ndk = require "ndk"


TID = 0

--这个原理是逐个解析字符串，同样可以解析json、xml
--这里解析json作为实例
-- local luaJson = {}
function json2true(str, from, to)
    return true, from + 3
end

 function json2false(str, from, to)
    return false, from + 4
end

 function json2null(str, from, to)
    return nil, from + 3
end

 function json2nan(str, from, to)
    return nil, from + 2
end

 numberchars = {
    ['-'] = true,
    ['+'] = true,
    ['.'] = true,
    ['0'] = true,
    ['1'] = true,
    ['2'] = true,
    ['3'] = true,
    ['4'] = true,
    ['5'] = true,
    ['6'] = true,
    ['7'] = true,
    ['8'] = true,
    ['9'] = true,
}

 function json2number(str, from, to)
    local i = from + 1
    while (i <= to) do
        local char = string.sub(str, i, i)
        if not numberchars[char] then
            break
        end
        i = i + 1
    end
    local num = tonumber(string.sub(str, from, i - 1))
    if not num then
        Log("red", 'json格式错误，不正确的数字, 错误位置:', from)
    end
    return num, i - 1
end

 function json2string(str, from, to)
    local ignor = false
    for i = from + 1, to do
        local char = string.sub(str, i, i)
        if not ignor then
            if char == '\"' then
                return string.sub(str, from + 1, i - 1), i
            elseif char == '\\' then
                ignor = true
            end
        else
            ignor = false
        end
    end
    -- Log("red", 'json格式错误，字符串没有找到结尾, 错误位置:{from}', from)
end

 function json2array(str, from, to)
    local result = {}
    from = from or 1
    local pos = from + 1
    local to = to or string.len(str)
    while (pos <= to) do
        local char = string.sub(str, pos, pos)
        if char == '\"' then
            result[#result + 1], pos = json2string(str, pos, to)
        --[[    elseif char == ' ' then
        
        elseif char == ':' then
        
        elseif char == ',' then]]
        elseif char == '[' then
            result[#result + 1], pos = json2array(str, pos, to)
        elseif char == '{' then
            result[#result + 1], pos = json2table(str, pos, to)
        elseif char == ']' then
            return result, pos
        elseif (char == 'f' or char == 'F') then
            result[#result + 1], pos = json2false(str, pos, to)
        elseif (char == 't' or char == 'T') then
            result[#result + 1], pos = json2true(str, pos, to)
        elseif (char == 'n') then
            result[#result + 1], pos = json2null(str, pos, to)
        elseif (char == 'N') then
            result[#result + 1], pos = json2nan(str, pos, to)
        elseif numberchars[char] then
            result[#result + 1], pos = json2number(str, pos, to)
        end
        pos = pos + 1
    end
end

 function string2json(key, value)
    return string.format("\"%s\":\"%s\",", key, value)
end

 function number2json(key, value)
    return string.format("\"%s\":%s,", key, value)
end

 function boolean2json(key, value)
    value = value == nil and false or value
    return string.format("\"%s\":%s,", key, tostring(value))
end

 function array2json(key, value)
    local str = "["
    for k, v in pairs(value) do

        if type(v) == "string" then
            str = str .. string.format("\"%s\"",v)
        elseif type(v) == "number" then
            str = str .. string.format("%s", v)
        elseif type(v) == "boolean" then
            v = v == nil and false or v
            -- str = str .. boolean2json(k, v)
            str = str .. string.format("%s", key, tostring(v))
        elseif type(v) == "table" then
            str = str .. table2json(k, v)
        end

        str = str .. ","
    end
    str = string.sub(str, 1, string.len(str) - 1) .. "]"
    return string.format("\"%s\":%s,", key, str)
end

 function isArrayTable(t)
    
    if type(t) ~= "table" then
        return false
    end
    
    local n = #t
    for i, v in pairs(t) do
        if type(i) ~= "number" then
            return false
        end
        
        if i > n then
            return false
        end
    end
    
    return true
end

 function table2json(key, value)
    if isArrayTable(value) then
        return array2json(key, value)
    end
    local tableStr = Table2jsonString(value)
    
    return string.format("\"%s\":%s,", key, tableStr)
end



function json2table(str, from, to)
    local result = {}
    from = from or 1
    local pos = from + 1
    local to = to or string.len(str)
    local key
    while (pos <= to) do
        local char = string.sub(str, pos, pos)
        --Log("yellow", pos, "-->", char)
        if char == '\"' then
            if not key then
                key, pos = json2string(str, pos, to)
            else
                result[key], pos = json2string(str, pos, to)
                key = nil
            end
        --[[    elseif char == ' ' then
        
        elseif char == ':' then
        
        elseif char == ',' then]]
        elseif char == '[' then
            if not key then
                key, pos = json2array(str, pos, to)
            else
                result[key], pos = json2array(str, pos, to)
                key = nil
            end
        elseif char == '{' then
            if not key then
                key, pos = json2table(str, pos, to)
            else
                result[key], pos = json2table(str, pos, to)
                key = nil
            end
        elseif char == '}' then
            return result, pos
        elseif (char == 'f' or char == 'F') then
            result[key], pos = json2false(str, pos, to)
            key = nil
        elseif (char == 't' or char == 'T') then
            result[key], pos = json2true(str, pos, to)
            key = nil
        elseif (char == 'n') then
            result[key], pos = json2null(str, pos, to)
            key = nil
        elseif (char == 'N') then
            result[key], pos = json2nan(str, pos, to)
            key = nil
        elseif numberchars[char] then
            if not key then
                key, pos = json2number(str, pos, to)
            else
                result[key], pos = json2number(str, pos, to)
                key = nil
            end
        end
        pos = pos + 1
    end
end

--json格式中表示字符串不能使用单引号
local jsonfuncs = {
    ['\"'] = json2string,
    ['['] = json2array,
    ['{'] = json2table,
    ['f'] = json2false,
    ['F'] = json2false,
    ['t'] = json2true,
    ['T'] = json2true,
}

function json2lua(str)
    local char = string.sub(str, 1, 1)
    local func = jsonfuncs[char]
    if func then
        return func(str, 1, string.len(str))
    end
    if numberchars[char] then
        return json2number(str, 1, string.len(str))
    end
end

function Table2jsonString(tab)
    local str = "{"
    for k, v in pairs(tab) do
        if type(v) == "string" then
            str = str .. string2json(k, v)
        elseif type(v) == "number" then
            str = str .. number2json(k, v)
        elseif type(v) == "boolean" then
            str = str .. boolean2json(k, v)
        elseif type(v) == "table" then
            str = str .. table2json(k, v)
        end
    end
    str = string.sub(str, 1, string.len(str) - 1)
    return str .. "}"
end
----------上面代码是简单的json处理

---数据解析
function CurrTid()
     if (TID > 255)
     then
        TID = 0x00
     end
end


--将字符串转换成16进制的字符串 abc = 0x12,0x34,0x56  return 123456
function ConvertHexString(stringValue)
    local result;
    local stringLen = string.len(stringValue)
    if stringLen == 0 then
        result = nil
    else
        for i = 1, stringLen, 1 do
            local temp = string.byte(string.sub(stringValue, i, i))
            if result ~= nil then
                result = result..string.format("%02x", temp)
            else
                result = string.format("%02x", temp)
            end
        end
    end
    return result
end

-- 将一个整形解析成（bitCount）位的二进制。 比如244。解析成8位的二进制 11111010
-- function toSecond(num, bitCount)
--     local str = ""
--     local temp = num
--     while(temp > 0) do
--         if(temp%2 == 1) then
--             str = str.."1"
--         else
--             str = str.."0"
--         end
--         temp = math.modf(temp/2)
--     end
    
--     local strLenth = string.len(str)
--     local currLenth = bitCount - strLenth
    
--     --不足补充0
--     while(currLenth > 0) do
--         str = str.."0"
--         currLenth = currLenth-1
--     end
    
--     str = string.reverse(str)
--     return str
-- end

--将一个长度小于5的字符串转换整形，低位在前 {0x03,0x04} 0x04 * 16 * 16 + 0x03
function IntFromString(stringValue)
    local lenth = string.len(stringValue)
    local result = 0
    for index=lenth, 1, -1 do  --从最后一个字符开始计算
       result = result*16*16 + string.byte(string.sub(stringValue, index, index))
    end
   return result
--    return tonumber(stringValue,16)
end

--蓝牙数据解析
function BleRecieveDataResolv(bleData)
    local index = 1
    local table = {}
    local lenth = string.len(bleData)
    local result
    
    local head1 = string.sub(bleData, index, index)
    index = index + 1    --index =  2
    head1 = head1..string.sub(bleData, index, index)
    index = index + 1    -- index = 3 不使用
    if head1 ~= 'JX' then
        return nil
    end
    
    --opCode两位
    index = index + 1  --index = 4  tid
    local opCode1 = string.byte(string.sub(bleData, index, index))
    local opCode = string.byte(string.sub(bleData, index + 1, index + 1)) * 16 * 16 + opCode1
    index = index + 2  --index = 6

    local segmentCount = string.byte(string.sub(bleData, index, index))
    index = index + 1  --index = 7
    
    if opCode == 0x8204 then  --设备开关状态 1B
        result = IntFromString(string.sub(bleData, index, lenth - 1))
        table['power'] = result
    elseif opCode == 0x824F  then --设备亮度 1B
        result = IntFromString(string.sub(bleData, index, lenth - 1))
        table['brightness'] = result
    elseif opCode == 0x8261  then --设备速度 1B
        result = IntFromString(string.sub(bleData, index, lenth - 1))
        table['speed'] = result
    elseif opCode == 0x8244 then --场景模式 1B 3~255
        result = IntFromString(string.sub(bleData, index, lenth - 1))
        table['scene'] = result
    elseif opCode == 0x8234 then --颜色设置 3B, 按照RBG的顺序显示颜色
        result = ConvertHexString(string.sub(bleData, index, lenth - 1))
        table['color'] = '#'..result  --0～100
    elseif opCode == 0x8266 then  --色温
        result = IntFromString(string.sub(bleData, index, lenth - 1))
        table['color_temperature'] = result
    elseif opCode == 0x82F1 then  --灯珠个数
        result = IntFromString(string.sub(bleData, index, lenth - 1))
        table['lamp_bead'] = result
    elseif opCode == 0x8212 then --自定义数据
        --修改数据解析
        --模式 1个字节
        local modeValue = string.byte(string.sub(bleData, index, index))  --7 表示模式
        index = index + 1    -- index = 8

        local colorsCount = string.byte(string.sub(bleData, index, index))
        index = index + 1  --index = 9

        --保存颜色数组
        local colorsArray = {}
        for i = 1, colorsCount, 1 do
            --RGB颜色占用了3个字节
            local colorValue = string.sub(bleData, index + (i - 1) * 3, lenth - 1 - (colorsCount - i) * 3)
            colorsArray[i] = '#'..ConvertHexString(colorValue)
        end
        table['mode'] = modeValue
        table['colorsCount'] = colorsCount
        table['colors'] = colorsArray
    elseif opCode == 0x8213 then  -- 场景删除返回结果
        result = ConvertHexString(string.sub(bleData, index, lenth - 1))
        table['sceneResult'] = result  --0～100
    elseif opCode == 0x82B0 then  --删除
        --应答/上报更新结果
        -- local timerId = IntFromString(string.sub(bleData, index, index))
        table['timerId'] = 0
    elseif opCode == 0x82B1 then --上报更新定时器的结果
        --应答/上报设置结果
        local timerId = IntFromString(string.sub(bleData, index, index))
        -- print(index);
        index = index + 1
        local timerTaskStartTimestamp = IntFromString(string.sub(bleData, index, index + 3))
        index = index + 4
        local timerTaskEndTimestamp = IntFromString(string.sub(bleData, index, index + 3))
        index = index + 4
               
        local power = IntFromString(string.sub(bleData, index, index))
        -- local minute = math.modf((timerTaskEndTimestamp - timerTaskStartTimestamp)/60)
        -- local second = (timerTaskEndTimestamp - timerTaskStartTimestamp)%60
                
        table['timerPower'] = power
        table['timerId'] = timerId
        table['startTimeStamp'] = timerTaskStartTimestamp
        table['stopTimeStamp'] = timerTaskEndTimestamp

    elseif opCode == 0x82B3 then
        --应答/上报更新结果
        local timerId = IntFromString(string.sub(bleData, index, index))
        index = index + 1
        local timerTaskStartTimestamp = IntFromString(string.sub(bleData, index, index + 3))
        index = index + 4
        local timerTaskEndTimestamp = IntFromString(string.sub(bleData, index, index + 3))
        index = index + 4
               
        local power = IntFromString(string.sub(bleData, index, index))
        local minute = math.modf((timerTaskEndTimestamp - timerTaskStartTimestamp)/60)
        local second = (timerTaskEndTimestamp - timerTaskStartTimestamp)%60
                
        table['power'] = power
        table['timerId'] = timerId
        table['minute'] = minute
        table['second'] = second
    elseif opCode == 0x82C1 then
        --应答上报时间的结果 （连接上下发当前的时间戳）
        result = ConvertHexString(string.sub(bleData, index, lenth - 1))
        table['timeStamp'] = result
    elseif opCode == 0x82E0 then
        --设备ID
        local deviceIdValue = string.sub(bleData, index, lenth - 1)
        --解析成16进制的字符串
        local deviceId = ConvertHexString(deviceIdValue);
        table['deviceId'] = deviceId

    elseif opCode == 0x82E1 then
        --产品ID
        local productIdValue = string.sub(bleData, index, lenth - 1)
        --解析成16进制的字符串
        local productId = ConvertHexString(productIdValue);
        table['productId'] = productId
    elseif opCode == 0x82A3 then
        if segmentCount == 0 then
            table['timerCount'] = 0
        else
            local timerId = IntFromString(string.sub(bleData, index, index))
            index = index + 1

            local timerState = IntFromString(string.sub(bleData, index, index))
            index = index + 1

            local deviceState = IntFromString(string.sub(bleData, index, index))
            index = index + 1

            local repeatValue = IntFromString(string.sub(bleData, index, index))
            index = index + 1

            local circle = IntFromString(string.sub(bleData, index, index))
            index = index + 1

            local stopTimeStamp = IntFromString(string.sub(bleData, index, index + 3))
            index = index + 1
            
            table['timerId'] = timerId
            table['timerState'] = timerState
            table['deviceState'] = deviceState
            table['repeat'] = repeatValue
            table['circle'] = circle
            table['stopTimeStamp'] = stopTimeStamp
            table['timerCount'] = segmentCount
        end
    elseif opCode == 0xB2D1 then
        local power = IntFromString(string.sub(bleData, index, index))
        index = index + 1

        local brightness = IntFromString(string.sub(bleData, index, index))
        index = index + 1

        local speed = IntFromString(string.sub(bleData, index, index))
        index = index + 1

        local opCodeValue = IntFromString(string.sub(bleData, index, index + 1))
        index = index + 2

        local modeId =  IntFromString(string.sub(bleData, index, index))
        index = index + 2

        table['power'] = power
        table['brightness'] = brightness
        table['speed'] = speed
        if opCodeValue == 0x8243 or opCodeValue == 0x8343 then
            table['dynamicId'] = modeId
        elseif opCodeValue == 0x8244 or opCodeValue == 0x8344 then
            table['musicId'] = modeId
        elseif opCodeValue == 0x8245 or opCodeValue == 0x8345 then
            table['staticId'] = modeId
        end
    else 
        table = {}
    end

    -- return 
    return Table2jsonString(table)
end

-- ResultValue = string.char(
--     0x4a,0x58,
--     0x01,
--     0x12,0x82,
--     0x00,
--     0x01,
--     0x05,
--     0x12,0x23,0x34,
--     0x22,0x23,0x34,
--     0x32,0x23,0x34,
--     0x42,0x23,0x34,
--     0x52,0x23,0x34,
--     0x00
-- )
--0x0x4a5803b082000122
-- ResultValue = string.char(
--     0x4a,0x58,
--     0x7e,
--     0xB1,0x82,
--     0x03,
--     0x00,0x00,0x00,0x00,
--     0x10,0x0E,0x00,0x00,
--     0x01,
--     0x00
-- )
-- print(BleRecieveDataResolv(ResultValue));

-- --蓝牙数据封装 返回数组
-- function BleSendDataPackage(rnTable)
--     local array = {}
--     local status = rnTable['powerstatus']
--     --固定格式
--     array[1] = 0x4a
--     array[2] = 0x58
--     array[3] = TID
--     TID = TID + 1
--     CurrTid()
    
--     if type(status) ~= "nil" then
--         array[4] = 0x02
--         array[5] = 0x80
--         --分段控制
--         array[6] = 0x00
--         array[7] = status
--         array[8] = XorValue(array, 7)
--     end

--     return array
-- end
-- 获取蓝牙协议的头部信息
function GetBleDeviceStatusHeadPackage()
    local resultStr
    local checkValue = 0x4a;

     --固定格式
     resultStr = string.format("%02x", 0x4a)
     checkValue = 0x4a;
 
     resultStr = resultStr..string.format("%02x", 0x58)
     checkValue = checkValue~0x58
    
     --消息ID
     resultStr = resultStr..string.format("%02x", TID)
     checkValue = checkValue~TID
     TID = TID + 1
     CurrTid()

     return resultStr, checkValue
end

--获取设备状态
function GetBleDeviceStatusBlePackage()
    --头部数据
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    --0x82D0表示获取设备状态信息
    resultStr = resultStr..string.format("%02x", 0xD0)
    checkValue = checkValue~0xD0
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    resultStr = resultStr..string.format("%02x", checkValue)
    return resultStr
    
end


--获取设备ID
function GetDeviceIdBlePackage()
    --头部数据
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    --0x82D0表示获取设备状态信息
    resultStr = resultStr..string.format("%02x", 0xD0)
    checkValue = checkValue~0xD0
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    resultStr = resultStr..string.format("%02x", checkValue)
    return resultStr
end

--获取产品ID
function GetProductIdBlePackage()
    --头部数据
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    --0x82E0表示获取设备状态信息
    resultStr = resultStr..string.format("%02x", 0xE1)
    checkValue = checkValue~0xE1
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    resultStr = resultStr..string.format("%02x", checkValue)
    return resultStr
end

--下发时间戳的数据包，timestamp当前的时间戳
function GetTimeStampBlePackage(timestamp)
    --头部数据
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    --0x82D0表示获取设备状态信息
    resultStr = resultStr..string.format("%02x", 0xC0)
    checkValue = checkValue~0xC0
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    --拼接时间戳  4个字节
    local lastValue, thirdValue, secondValue, topValue = Convert4ByteValue(timestamp)

    resultStr = resultStr..string.format("%02x", lastValue)
    checkValue = checkValue~lastValue

    resultStr = resultStr..string.format("%02x", thirdValue)
    checkValue = checkValue~thirdValue

    resultStr = resultStr..string.format("%02x", secondValue)
    checkValue = checkValue~secondValue

    resultStr = resultStr..string.format("%02x", topValue)
    checkValue = checkValue~topValue

    resultStr = resultStr..string.format("%02x", checkValue)
    return resultStr
    
end

-- 返回16进制的字符串
-- function bleSendDataPackage(rnTable)
--     print(tostring(123))
--     currTid()
--     local resultStr
--     local powerstatus = rnTable['powerstatus']
--     local checkValue = 0x4a;
--     --固定格式
--     resultStr = string.format("%02x", 0x4a)
--     resultStr = resultStr..string.format("%02x", 0x58)
--     checkValue = checkValue~0x58
--     resultStr = resultStr..string.format("%02x", TID)
--     checkValue = checkValue~TID

--     if type(powerstatus) ~= "nil" then
--         resultStr = resultStr..string.format("%02x", 0x02)
--         checkValue = checkValue~0x02
--         resultStr = resultStr..string.format("%02x", 0x80)
--         checkValue = checkValue~0x80
--         --分段控制
--         resultStr = resultStr..string.format("%02x", 0x00)
--         checkValue = checkValue~0x00
--         resultStr = resultStr..string.format("%02x", powerstatus)
--         checkValue = checkValue~powerstatus
--         resultStr = resultStr..string.format("%02x", checkValue)
--     end
    
--     TID = TID + 1
--     return resultStr
-- end

--将RN发送的设备转改转换成16进制的字符串
function ControlBleDevice(rnTableStr)
    local rnTable = {}
    rnTable = json2table(rnTableStr);

    --头部数据
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    local powerstate = rnTable['power']
    local bright = rnTable['brightness']
    local speed = rnTable['speed']
    local scene = rnTable['scene']
    local sceneColor = rnTable['color']
    local colors = rnTable['colors']

    --新增控制命令
    local dynamicId = rnTable['dynamicId']
    local musicId = rnTable['musicId']
    local staticId = rnTable['staticId']
    local color_temperature = rnTable['color_temperature']
    local lamp_beads = rnTable['lamp_bead']
    -- for key, value in pairs(rnTable) do
    --     print(tostring(key)..':'..tostring(value))
    -- end

    if type(colors) ~= "nil" then   --0x8211：设置自定义数据
        local modeValue = rnTable['mode']
        local currResultValue, currCheckValue = ControlCustomScene(colors,modeValue)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    elseif type(powerstate) ~= "nil" then   --0x8202：设置开关状态
        local currResultValue, currCheckValue = ControlPowerState(powerstate)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    elseif type(bright) ~= "nil" then
        local currResultValue, currCheckValue = ControlBright(bright)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    elseif type(scene) ~= "nil" then
        local currResultValue, currCheckValue = ControlScene(scene)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    elseif type(speed) ~= "nil" then
        local currResultValue, currCheckValue = ControlSpeed(speed)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    elseif type(sceneColor) ~= "nil" then
        local currResultValue, currCheckValue = ControlSceneClolor(sceneColor)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    elseif type(dynamicId) ~= "nil" then
        local currResultValue, currCheckValue = ControlDynamic(dynamicId)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    elseif type(musicId) ~= "nil" then
        local currResultValue, currCheckValue = ControlMusic(musicId)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    elseif type(staticId) ~= "nil" then
        local currResultValue, currCheckValue = ControlStaticWithStaticId(staticId)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    elseif type(color_temperature) ~= "nil" then
        local currResultValue, currCheckValue = ControlColorTemperature(color_temperature)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    elseif type(lamp_beads) ~= "nil" then
        local currResultValue, currCheckValue = ControlLampBeads(lamp_beads)
        resultStr = resultStr..currResultValue
        checkValue = checkValue~currCheckValue
    end
    
    if resultStr == nil then
        return nil
    end

    resultStr = resultStr..string.format("%02x", checkValue)
    return resultStr
end


--删除自定义动态模式
function RemoveDynamicDiyPackage(dynamicId)
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

     --添加opCode
     resultStr = resultStr..string.format("%02x", 0x43)
     checkValue = 0x43
     resultStr = resultStr..string.format("%02x", 0x84)
     checkValue = checkValue~0x84
 
     --分段控制
     resultStr = resultStr..string.format("%02x", 0x00)
     checkValue = checkValue~0x00
     
     --dynamicDiy ID
     resultStr = resultStr..string.format("%02x", dynamicId)
     checkValue = checkValue~dynamicId

     resultStr = resultStr..string.format("%02x", checkValue)

     return resultStr
end

function RemoveMusicDiyPackage(musicId)
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    --添加opCode
    resultStr = resultStr..string.format("%02x", 0x44)
    checkValue = 0x44
    resultStr = resultStr..string.format("%02x", 0x84)
    checkValue = checkValue~0x84

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00
    
    --dynamicDiy ID
    resultStr = resultStr..string.format("%02x", musicId)
    checkValue = checkValue~musicId

    resultStr = resultStr..string.format("%02x", checkValue)

    return resultStr
end

function RemoveStaticDiyPackage(staticId)
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    --添加opCode
    resultStr = resultStr..string.format("%02x", 0x45)
    checkValue = 0x45
    resultStr = resultStr..string.format("%02x", 0x84)
    checkValue = checkValue~0x84

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00
    
    --dynamicDiy ID
    resultStr = resultStr..string.format("%02x", staticId)
    checkValue = checkValue~staticId

    resultStr = resultStr..string.format("%02x", checkValue)

    return resultStr
    
end

--打开/关闭呼吸权限
function OpenBreatheSpeedPackage(breatheTableStr)
    local breatheTable = {}
    breatheTable = json2table(breatheTableStr);

    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    local breatheState = breatheTable['breatheState']
    local breatheValue = breatheTable['breatheValue']

    --添加opCode
    resultStr = resultStr..string.format("%02x", 0x46)
    checkValue = 0x46
    resultStr = resultStr..string.format("%02x", 0x83)
    checkValue = checkValue~0x83

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00
    
    --
    resultStr = resultStr..string.format("%02x", breatheState)
    checkValue = checkValue~breatheState

    resultStr = resultStr..string.format("%02x", breatheValue)
    checkValue = checkValue~breatheValue

    resultStr = resultStr..string.format("%02x", checkValue)

    return resultStr
    
end

--颜色处理，颜色数组转换成16
function ControlCustomScene(colors, modeValue)
    local resultStr, checkValue

     --添加opCode
    resultStr = string.format("%02x", 0x11)
    checkValue = 0x11
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00
    
    --模式设置
    resultStr = resultStr..string.format("%02x", modeValue)
    checkValue = checkValue~modeValue

    --获取数组个数
    local colorsCount = #colors
    resultStr = resultStr..string.format("%02x", colorsCount)
    checkValue = checkValue~colorsCount

    --解析颜色  按照RGB的顺序存放
    for k, v in pairs(colors) do
        
        local currColor = string.sub(v,2,-1)
        local rColor, gColor,bColor = Convert16HexStrToInt8(currColor.sub(currColor, 1, 2)),Convert16HexStrToInt8(currColor.sub(currColor, 3, 4)),Convert16HexStrToInt8(currColor.sub(currColor, 5, 6))
    
        resultStr = resultStr..string.format("%02x", rColor)
        checkValue = checkValue~rColor
    
        resultStr = resultStr..string.format("%02x", gColor)
        checkValue = checkValue~gColor
    
        resultStr = resultStr..string.format("%02x", bColor)
        checkValue = checkValue~bColor
    end

    return resultStr, checkValue
end

--开关状态控制
function ControlPowerState(powerState)
    local resultStr, checkValue

    --添加opCode 0x8202
    resultStr = string.format("%02x", 0x02)
    checkValue = 0x02
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    resultStr = resultStr..string.format("%02x", powerState)
    checkValue = checkValue~powerState

    return resultStr, checkValue
end

--亮度控制
function ControlBright(bright)
    local resultStr, checkValue

    --添加opCode 0x824C
    resultStr = string.format("%02x", 0x4C)
    checkValue = 0x4C
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    resultStr = resultStr..string.format("%02x", bright)
    checkValue = checkValue~bright

    return resultStr, checkValue
end

--速度控制
function ControlSpeed(speed)
    local resultStr, checkValue

    --添加opCode 0x8260 设置速度
    resultStr = string.format("%02x", 0x60)
    checkValue = 0x60
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    resultStr = resultStr..string.format("%02x", speed)
    checkValue = checkValue~speed

    return resultStr, checkValue
end


--场景控制
function ControlScene(scene)
    local resultStr, checkValue

    --添加opCode 0x8242
    resultStr = string.format("%02x", 0x42)
    checkValue = 0x42
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    resultStr = resultStr..string.format("%02x", scene)
    checkValue = checkValue~scene

    return resultStr, checkValue
end

--场景控制删除自定义场景
function DeleteCustomScene()
    local resultStr, checkValue

    --添加opCode 0x8213
    resultStr = string.format("%02x", 0x13)
    checkValue = 0x13
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    --只有一个场景
    return resultStr, checkValue
end

--创建定时器
function CreateCountdown(timerTableStr)
    local timerTable = json2table(timerTableStr);

    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();
  
    local currResultValue, currCheckValue = ControlTimerTask(timerTable, 0xA1);
    resultStr = resultStr..currResultValue
    checkValue = checkValue~currCheckValue
  
    TID = TID + 1
    CurrTid()
    resultStr = resultStr..string.format("%02x", checkValue)
    return resultStr
end

--更新定时器
function UpdateCountdown(timerTableStr)
     --16进制的字符串
    local timerTable = json2table(timerTableStr);
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    local currResultValue, currCheckValue = ControlTimerTask(timerTable, 0xA2);
    resultStr = resultStr..currResultValue
    checkValue = checkValue~currCheckValue

    resultStr = resultStr..string.format("%02x", checkValue)
    return resultStr
end

--删除定时器 定时器ID (跟H5接口同名)
function DeleteCountdown(timerId)
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

     --添加opCode 0x82A0
    resultStr = resultStr..string.format("%02x", 0xA0)
    checkValue = 0xA0
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82
 
     --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00
 
     --定时器ID
    resultStr = resultStr..string.format("%02x", timerId)
    checkValue = checkValue~timerId

    resultStr = resultStr..string.format("%02x", checkValue)
    return resultStr
end

--将TimerTable转换成对应的数据
function ControlTimerTask(timerTable, opCode)
    --添加定时任务的相关字段
    local timerId = timerTable['timerId']
    local power = timerTable['power']
    local taskStartTimeStamp = timerTable['startTimeStamp']
    local taskEndTimeStamp = timerTable['stopTimeStamp']
    
    local resultStr, checkValue

    --添加opCode 0x82A1
    resultStr = string.format("%02x", opCode)
    checkValue = opCode
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    --一个字节的定时ID
    resultStr = resultStr..string.format("%02x", timerId)
    checkValue = checkValue~timerId


    --4个字节的开始时间戳
    local startTimeStampLastValue, startTimeStampThirdValue, startTimeStampSecondValue, startTimeStampStopValue = Convert4ByteValue(taskStartTimeStamp)

    resultStr = resultStr..string.format("%02x", startTimeStampLastValue)
    checkValue = checkValue~startTimeStampLastValue

    resultStr = resultStr..string.format("%02x", startTimeStampThirdValue)
    checkValue = checkValue~startTimeStampThirdValue

    resultStr = resultStr..string.format("%02x", startTimeStampSecondValue)
    checkValue = checkValue~startTimeStampSecondValue

    resultStr = resultStr..string.format("%02x", startTimeStampStopValue)
    checkValue = checkValue~startTimeStampStopValue


    --4个字节的结束时间戳
    local endTimeStampLastValue, endTimeStampThirdValue, endTimeStampSecondValue, endTimeStampStopValue = Convert4ByteValue(taskEndTimeStamp)

    resultStr = resultStr..string.format("%02x", endTimeStampLastValue)
    checkValue = checkValue~endTimeStampLastValue

    resultStr = resultStr..string.format("%02x", endTimeStampThirdValue)
    checkValue = checkValue~endTimeStampThirdValue

    resultStr = resultStr..string.format("%02x", endTimeStampSecondValue)
    checkValue = checkValue~endTimeStampSecondValue

    resultStr = resultStr..string.format("%02x", endTimeStampStopValue)
    checkValue = checkValue~endTimeStampStopValue


    --定时设备状态
    resultStr = resultStr..string.format("%02x", power)
    checkValue = checkValue~power


    return resultStr, checkValue
end


--修改颜色 颜色的格式是#FFBBEE
function ControlSceneClolor(sceneColor)

    local resultStr, checkValue

    --添加opCode 0x8232
    resultStr = string.format("%02x", 0x32)
    checkValue = 0x32
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    local currColor = string.sub(sceneColor,2,-1)
    local rColor, gColor,bColor = Convert16HexStrToInt8(currColor.sub(currColor, 1, 2)),Convert16HexStrToInt8(currColor.sub(currColor, 3, 4)),Convert16HexStrToInt8(currColor.sub(currColor, 5, 6))

    resultStr = resultStr..string.format("%02x", rColor)
    checkValue = checkValue~rColor

    resultStr = resultStr..string.format("%02x", gColor)
    checkValue = checkValue~gColor

    resultStr = resultStr..string.format("%02x", bColor)
    checkValue = checkValue~bColor

    return resultStr, checkValue
end

function ControlColorTemperature(color_temperature)
    local resultStr, checkValue
    --添加opCode 0x8232
    resultStr = string.format("%02x", 0x64)
    checkValue = 0x64
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    local endTimeStampLastValue, endTimeStampTopValue = Convert2ByteValue(color_temperature)

    resultStr = resultStr..string.format("%02x", endTimeStampLastValue)
    checkValue = checkValue~endTimeStampLastValue

    resultStr = resultStr..string.format("%02x", endTimeStampTopValue)
    checkValue = checkValue~endTimeStampTopValue

    return resultStr, checkValue
end

function ControlLampBeads(lamp_beads)

    local resultStr, checkValue
    --添加opCode 0x82F0
    resultStr = string.format("%02x", 0xF0)
    checkValue = 0x64
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    local lampBeadsLastValue, lampBeadsTopValue = Convert2ByteValue(lamp_beads)

    resultStr = resultStr..string.format("%02x", lampBeadsLastValue)
    checkValue = checkValue~lampBeadsLastValue

    resultStr = resultStr..string.format("%02x", lampBeadsTopValue)
    checkValue = checkValue~lampBeadsTopValue

    return resultStr, checkValue

end

function ControlDynamic(dynamicId)

    local resultStr, checkValue

    --添加opCode 0x8243
    resultStr = string.format("%02x", 0x43)
    checkValue = 0x43
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    resultStr = resultStr..string.format("%02x", dynamicId)
    checkValue = checkValue~dynamicId

    return resultStr, checkValue
end

function ControlMusic(musicId)
    local resultStr, checkValue

    --添加opCode 0x8244
    resultStr = string.format("%02x", 0x44)
    checkValue = 0x44
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    resultStr = resultStr..string.format("%02x", musicId)
    checkValue = checkValue~musicId

    return resultStr, checkValue
end

function ControlStaticWithStaticId(staticId)
    local resultStr, checkValue

    --添加opCode 0x8244
    resultStr = string.format("%02x", 0x45)
    checkValue = 0x45
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82

    --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00

    resultStr = resultStr..string.format("%02x", staticId)
    checkValue = checkValue~staticId

    return resultStr, checkValue
end

-- 控制自定义dynamic模式
function ControlDIYDynamicPackage(diyTableStr)
    local diyTable = json2table(diyTableStr);

    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    local diyId = diyTable['ID']
    local senceId = diyTable['senceId'];
    local brightness = diyTable['brightness']
    local speed = diyTable['speed']
    local colors = diyTable['colors']

     --添加opCode 0x8343 
     resultStr = resultStr..string.format("%02x", 0x43)
     checkValue = checkValue~0x43
     resultStr = resultStr..string.format("%02x", 0x83)
     checkValue = checkValue~0x83
 
     --分段控制
     resultStr = resultStr..string.format("%02x", 0x00)
     checkValue = checkValue~0x00
 
     resultStr = resultStr..string.format("%02x", diyId)
     checkValue = checkValue~diyId

     resultStr = resultStr..string.format("%02x", senceId)
     checkValue = checkValue~senceId

     resultStr = resultStr..string.format("%02x", speed)
     checkValue = checkValue~speed

     resultStr = resultStr..string.format("%02x", brightness)
     checkValue = checkValue~brightness

     local count = GetTableCount(colors)
     resultStr = resultStr..string.format("%02x", count)
     checkValue = checkValue~count

     for k, v in pairs(colors) do
        
        local currColor = string.sub(v,2,-1)
        local rColor, gColor,bColor = Convert16HexStrToInt8(currColor.sub(currColor, 1, 2)),Convert16HexStrToInt8(currColor.sub(currColor, 3, 4)),Convert16HexStrToInt8(currColor.sub(currColor, 5, 6))
    
        resultStr = resultStr..string.format("%02x", rColor)
        checkValue = checkValue~rColor
    
        resultStr = resultStr..string.format("%02x", gColor)
        checkValue = checkValue~gColor
    
        resultStr = resultStr..string.format("%02x", bColor)
        checkValue = checkValue~bColor
    end

    resultStr = resultStr..string.format("%02x", checkValue)

    return resultStr
end


-- 控制自定义music模式

function ControlDIYMusicPackage(diyTableStr)
    local diyTable = json2table(diyTableStr);
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    local diyId = diyTable['ID']
    local senceId = diyTable['senceId']
    local brightness = diyTable['brightness']
    local speed = diyTable['speed']
    local colors = diyTable['colors']

     --添加opCode 0x8344 设置速度
     resultStr = resultStr..string.format("%02x", 0x44)
     checkValue = checkValue~0x44
     resultStr = resultStr..string.format("%02x", 0x83)
     checkValue = checkValue~0x83
 
     --分段控制
     resultStr = resultStr..string.format("%02x", 0x00)
     checkValue = checkValue~0x00
 
     resultStr = resultStr..string.format("%02x", diyId)
     checkValue = checkValue~diyId

     resultStr = resultStr..string.format("%02x", senceId)
     checkValue = checkValue~senceId

     resultStr = resultStr..string.format("%02x", speed)
     checkValue = checkValue~speed

     resultStr = resultStr..string.format("%02x", brightness)
     checkValue = checkValue~brightness

     local count = GetTableCount(colors)
     resultStr = resultStr..string.format("%02x", count)
     checkValue = checkValue~count

     for k, v in pairs(colors) do
        
        local currColor = string.sub(v,2,-1)
        local rColor, gColor,bColor = Convert16HexStrToInt8(currColor.sub(currColor, 1, 2)),Convert16HexStrToInt8(currColor.sub(currColor, 3, 4)),Convert16HexStrToInt8(currColor.sub(currColor, 5, 6))
    
        resultStr = resultStr..string.format("%02x", rColor)
        checkValue = checkValue~rColor
    
        resultStr = resultStr..string.format("%02x", gColor)
        checkValue = checkValue~gColor
    
        resultStr = resultStr..string.format("%02x", bColor)
        checkValue = checkValue~bColor
    end

    resultStr = resultStr..string.format("%02x", checkValue)

    return resultStr
end


-- 控制自定义static模式

function ControlDIYStaticPackage(diyTableStr)
    local diyTable = json2table(diyTableStr);
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    -- for key, value in pairs(diyTable) do
    --     print(tostring(key)..':'..tostring(value))
    -- end

    -- print(resultStr);

    local diyId = diyTable['ID']
    local brightness = diyTable['brightness']
    local breathe = diyTable['breathe']
    local colors = diyTable['colors']
    local senceId = diyTable['senceId']

     --添加opCode 0x8345 
     resultStr = resultStr..string.format("%02x", 0x45)
     checkValue = checkValue~0x45
     resultStr = resultStr..string.format("%02x", 0x83)
     checkValue = checkValue~0x83
 
     --分段控制
     resultStr = resultStr..string.format("%02x", 0x00)
     checkValue = checkValue~0x00
 
     resultStr = resultStr..string.format("%02x", diyId)
     checkValue = checkValue~diyId

     resultStr = resultStr..string.format("%02x", senceId)
     checkValue = checkValue~senceId

     resultStr = resultStr..string.format("%02x", breathe)
     checkValue = checkValue~breathe

     resultStr = resultStr..string.format("%02x", brightness)
     checkValue = checkValue~brightness

     local count = GetTableCount(colors)
     resultStr = resultStr..string.format("%02x", count)
     checkValue = checkValue~count

     for k, v in pairs(colors) do
        
        local currColor = string.sub(v,2,-1)
        local rColor, gColor,bColor = Convert16HexStrToInt8(currColor.sub(currColor, 1, 2)),Convert16HexStrToInt8(currColor.sub(currColor, 3, 4)),Convert16HexStrToInt8(currColor.sub(currColor, 5, 6))
    
        resultStr = resultStr..string.format("%02x", rColor)
        checkValue = checkValue~rColor
    
        resultStr = resultStr..string.format("%02x", gColor)
        checkValue = checkValue~gColor
    
        resultStr = resultStr..string.format("%02x", bColor)
        checkValue = checkValue~bColor
    end

    resultStr = resultStr..string.format("%02x", checkValue)

    return resultStr
end

function CreateTimertaskPackage(timerTableStr)
    local timerTable = json2table(timerTableStr);
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    local timerId = timerTable['timerId']
    local stopTimeStamp = timerTable['stopTimeStamp'];
    local startTimeStamp = timerTable['startTimeStamp']
    local deviceState = timerTable['deviceState']
    local circle = timerTable['circle']
    local timerState = timerTable['timerState']
    local weekday = timerTable['weekday']
    local repeatValue = timerTable['repeat']

     --添加opCode 0x82A1 设置定时器
     resultStr = resultStr..string.format("%02x", 0xA1)
     checkValue = checkValue~0xA1
     resultStr = resultStr..string.format("%02x", 0x82)
     checkValue = checkValue~0x82
 
     --分段控制
     resultStr = resultStr..string.format("%02x", 0x00)
     checkValue = checkValue~0x00
 
     --ID
     resultStr = resultStr..string.format("%02x", timerId)
     checkValue = checkValue~timerId

     --定时器开关
     resultStr = resultStr..string.format("%02x", timerState)
     checkValue = checkValue~timerState

      --设备状态开关
    resultStr = resultStr..string.format("%02x", deviceState)
    checkValue = checkValue~deviceState

      --是否循环
    resultStr = resultStr..string.format("%02x", repeatValue)
    checkValue = checkValue~repeatValue

    --当前周几
    resultStr = resultStr..string.format("%02x", weekday)
    checkValue = checkValue~weekday

    --定时周期
    resultStr = resultStr..string.format("%02x", circle)
    checkValue = checkValue~circle

    --开始时间戳
    local endTimeStampLastValue, endTimeStampThirdValue, endTimeStampSecondValue, endTimeStampStopValue = Convert4ByteValue(startTimeStamp)

    resultStr = resultStr..string.format("%02x", endTimeStampLastValue)
    checkValue = checkValue~endTimeStampLastValue

    resultStr = resultStr..string.format("%02x", endTimeStampThirdValue)
    checkValue = checkValue~endTimeStampThirdValue

    resultStr = resultStr..string.format("%02x", endTimeStampSecondValue)
    checkValue = checkValue~endTimeStampSecondValue

    resultStr = resultStr..string.format("%02x", endTimeStampStopValue)
    checkValue = checkValue~endTimeStampStopValue

    --结束时间戳
    local endTimeStampLastValue, endTimeStampThirdValue, endTimeStampSecondValue, endTimeStampStopValue = Convert4ByteValue(stopTimeStamp)

    resultStr = resultStr..string.format("%02x", endTimeStampLastValue)
    checkValue = checkValue~endTimeStampLastValue

    resultStr = resultStr..string.format("%02x", endTimeStampThirdValue)
    checkValue = checkValue~endTimeStampThirdValue

    resultStr = resultStr..string.format("%02x", endTimeStampSecondValue)
    checkValue = checkValue~endTimeStampSecondValue

    resultStr = resultStr..string.format("%02x", endTimeStampStopValue)
    checkValue = checkValue~endTimeStampStopValue

    resultStr = resultStr..string.format("%02x", checkValue)

    return resultStr
    
end

--删除定时任务
function DeleteTimerTaskPackage(timerId)
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

     --添加opCode 0x82A0 删除定时器
    resultStr = resultStr..string.format("%02x", 0xA0)
    checkValue = checkValue~0xA0
    resultStr = resultStr..string.format("%02x", 0x82)
    checkValue = checkValue~0x82
 
     --分段控制
    resultStr = resultStr..string.format("%02x", 0x00)
    checkValue = checkValue~0x00
 
     --ID
    resultStr = resultStr..string.format("%02x", timerId)
    checkValue = checkValue~timerId

    resultStr = resultStr..string.format("%02x", checkValue)
    return resultStr
    
end


function UpdateTimerTask(timeTable)
    return CreateTimertaskPackage(timeTable);
end

function GetTimerListPackage()
    local resultStr, checkValue = GetBleDeviceStatusHeadPackage();

    --添加opCode 0x82A0 删除定时器
   resultStr = resultStr..string.format("%02x", 0xA3)
   checkValue = checkValue~0xA3
   resultStr = resultStr..string.format("%02x", 0x82)
   checkValue = checkValue~0x82

    --分段控制
   resultStr = resultStr..string.format("%02x", 0x00)
   checkValue = checkValue~0x00

   resultStr = resultStr..string.format("%02x", checkValue)
   return resultStr
end

--将1个两位16进制的字符串转换成整形  比如 FE -> 15 * 16 + 14
function Convert16HexStrToInt8(hexString)
    local value = tonumber(string.sub(hexString, 1, 1), 16) * 16;
    value = value + tonumber(string.sub(hexString, 2, 2), 16)
    return value
end

-- 数组位异或
function XorValue(bleArray, lenth)
    local result = bleArray[1];
    for i = 2, lenth do
        result = result~bleArray[i]
    end
    return result
end

-- 将颜色转转成RGB的值 颜色按照RGB的顺序给的
function ConvertColor(colorValue)
    local first = colorValue>>16
    local temp = colorValue - first* 16 * 16 * 16 * 16
    local middleValue = temp>>8
    temp = temp - middleValue * 16 * 16
    local lastValue = temp
    return first,middleValue,lastValue
end

--将一个整整转换成4个字节  0x02345678   78,56,34,2
function Convert4ByteValue(convertValue)
    local topValue = convertValue>>24

    local temp = convertValue - topValue * 256 * 256 * 256
    local secondValue = temp >> 16

    temp = temp - secondValue * 256 * 256;
    local thirdValue = temp >> 8

    temp = temp - thirdValue * 256;
    local lastValue = temp

    --小段在前
    return lastValue, thirdValue, secondValue, topValue
end

--将一个整整转换成4个字节  0x02345678   78,56,34,2
function Convert2ByteValue(convertValue)
    local topValue = convertValue>>8
    local lastValue = convertValue - topValue * 256
    --小段在前
    return lastValue, topValue
end

-- 获取个数
function GetTableCount(table)
    local count=0
    for k,v in pairs(table) do
        count = count + 1
    end
    return count
end


--验证颜色
-- ControlTable = {}
-- ControlTable['stopTimeStamp'] = 1638762813
-- ControlTable['timerId'] = 1
-- ControlTable['timerState'] = 1
-- ControlTable['power'] = 1
-- ControlTable['repeat'] = 1
-- ControlTable['circle'] = 7
-- local str = CreateCountdown(ControlTable)
-- print(str)

-- 验证获取时间戳的数据包
-- GetTimeStampBlePackage(1630575292)

--region
-- &: 按位与
-- |: 按位或
-- ~: 按位异或
-- >>: 右移
-- <<: 左移
-- ~: 按位非

-- local jsonStr="{\"musicId\":1}"
-- local tesTabl = ControlBleDevice(jsonStr)
-- print(tesTabl)

-- return luaJson



