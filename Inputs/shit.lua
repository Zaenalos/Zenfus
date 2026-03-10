local startTime, endTime, nextQueue, seconds, minutes, sbText, sbHours, startSB, blockSDB, scriptEnded, playerId, usedGems, currentGems
local totalGemsUsed = 0
local sbCount = 0
local playerName = GetLocal().name:gsub("`.", ""):gsub("%((%d+)%)", "")
local worldName = GetWorld().name
local LogToConsole = LogToConsole
local SendPacket = SendPacket
local SendVariantList = SendVariantList
local AddHook = AddHook

for lib, enabled in pairs({ os = true, MakeRequest = true }) do
    if not _G[lib] then
        LogToConsole(string.format("`0[`4ERROR`0] : `6'%s' is not enabled, please enable it first.", lib))
        return
    end
end

local function formatNumber(num)
    return tostring(math.floor(num + 0.5)):reverse():gsub("(%d%d%d)", "%1,"):gsub(",(%-?)$", "%1"):reverse()
end

local function sendVariant(variant, text)
    SendVariantList({ [0] = variant, [1] = text })
end

local function getHours(...)
    return os.date("%H:%M:%S", ... or os.time())
end

local function getSeconds()
    return os.time()
end

local dialog = {
    [1] = {
        "add_label_with_icon|big|`cLaster's `9Super-Broadcast Script|left|2480|",
        "add_spacer|small|",
        "add_label_with_icon|small|`0Welcome back, " .. GetLocal().name .. "!|left|9474|",
        "add_spacer|small|",
        "add_label_with_icon|big|`9How to use:|left|1752|",
        "add_spacer|small|",
        "add_label_with_icon|small|`9Wrench any `2sign `9with a text|left|482|",
        "add_label_with_icon|small|`9Use the `2command `9(`2/setup`9)|left|482|",
        "add_label_with_icon|small|`9Use the `2command `9(`2/menu`9) to show this menu|left|482|",
        "add_spacer|small|",
        "add_url_button||`eDiscord|noflags|https://discord.gg/rSRerXbF9b|Would you like to check out the discord server?|0|0|",
        "add_url_button||`4Youtube|noflags|https://youtube.com/@LasterGT|Would you like to check out my youtube channel?|0|0|",
        "add_quick_exit|"
    }
}

AddHook("onvariant", "var", function(var)
    if var[0] == "OnConsoleMessage" and var[1]:match("Super%-Broadcast") then
        local consoleMessage = var[1]:gsub("`.", "")

        if consoleMessage:find("Gems") then
            usedGems, currentGems = consoleMessage:match("Used (%d+) Gems%. %((%d+) left%)")
            totalGemsUsed = totalGemsUsed + tonumber(usedGems)
        end

        if consoleMessage:find("Appears") then
            minutes = tonumber(consoleMessage:match("(%d+) min")) or 0
            seconds = tonumber(consoleMessage:match("(%d+) sec")) or 0
            nextQueue = minutes * 60 + seconds

            if nextQueue < 90 then
                nextQueue = 90
            end
        end
    end

    if var[0] == "OnDialogRequest" and var[1]:find("Sign") then
        sbText = var[1]:match("display_text||(.+)|128|")
        sendVariant("OnTextOverlay", "`^Super-Broadcast `cText `^is now set.")
        return true
    end

    if var[0] == "OnSDBroadcast" and blockSDB then
        sendVariant("OnTextOverlay", "`^Super Duper Broadcast `cBlocked!")
        return true
    end
end)

AddHook("onsendpacket", "packet", function(type, packet)
    if packet:find("/setup") then
        dialog[2] = {
            "add_label_with_icon|big|`9Super Broadcast Setup|left|2480",
            "add_spacer|small|",
            "add_checkbox|block_sdb|`2Enable `0Block SDB|" .. (blockSDB and 1 or 0) .. "|",
            "add_label|small|`0Super-Broadcast Text: " .. (not sbText and "`2Wrench any sign with a text to set." or sbText) .. "|left",
            "add_spacer|small",
            "add_text_input|sb_hours|`0Hour(s) to Super-Broadcast:|" .. (not sbAmount and 1 or sbAmount) .. "|2|",
            "add_spacer|small|",
            "add_quick_exit|",
            "end_dialog|sb_dialog|Close|Start"
        }
        sendVariant("OnDialogRequest", table.concat(dialog[2], "\n"))
        return true
    end

    if packet:find("/menu") then
        sendVariant("OnDialogRequest", table.concat(dialog[1], "\n"))
        return true
    end

    if packet:find("sb_dialog") then
        blockSDB = packet:find("block_sdb|1") and true or false
        sbHours = packet:find("sb_hours|(%d+)") or 0
        endTime = getSeconds() + (tonumber(sbHours) * 3600)

        if not sbText then
            sendVariant("OnTextOverlay", "`6No 'Super-Broadcast Text' detected! Wrench any sign with a text.")
            return
        end

        startTime = getSeconds()
        startSB = true
    end

    return false
end)

local function sendWebhook()
    local payload = [[
        {
            "embeds": [
                {
                    "title": "AUTO SB LOG",
                    "color": ]] .. math.random(0, 16777215) .. [[,
                    "thumbnail": {
                        "url": "https://cdn.discordapp.com/icons/1109357006567002132/04c450078d115268e7c3b0760e59a618.webp?size=100"
                    },
                    "fields" : [
                        {
                            "name": "<:gt_player:1226459325279768667> Player Name",
                            "value": "]] .. playerName .. [[ (]] .. GetLocal().userid .. [[)",
                            "inline": true
                        },
                        {
                            "name": "<:globe:1226432401715105892> Current World",
                            "value": "]] .. worldName .. [[",
                            "inline": true
                        },
                        {
                            "name" : "<:gt_sb:1259771914516303942> Broadcast Queue",
                            "value" : "Appears in ~]] .. minutes .. [[ minute(s), and ]] .. seconds .. [[ second(s)",
                            "inline" : false
                        },
                        {
                            "name" : "<:gt_sb:1259771914516303942> Next Broadcast",
                            "value" : "Will be in ~]] .. (nextQueue <= 90 and "1 minute(s), and 30 second(s)" or minutes .. " minute(s), and " .. seconds .. " seconds(s)") .. [[",
                            "inline" : false
                        },
                        {
                            "name" : "<:gt_sb:1259771914516303942> Total Broadcasts Sent",
                            "value" : "]] .. sbCount .. [[",
                            "inline" : false
                        },
                        {
                            "name" : "<:gt_gems:1226474791205343322> Player Gems",
                            "value" : "]] .. formatNumber(currentGems) .. [[",
                            "inline" : false
                        },
                        {
                            "name" : "<:gt_gems:1226474791205343322> Gems Used",
                            "value" : "]] .. formatNumber(usedGems) .. [[",
                            "inline" : false
                        },
                        {
                            "name" : "<:gt_gems:1226474791205343322> Total Gems Used",
                            "value" : "]] .. formatNumber(totalGemsUsed) .. [[",
                            "inline" : false
                        },
                        {
                            "name" : "<:gt_clock:1227292509143564312> Script Started",
                            "value" : "]] .. getHours(startTime) .. [[",
                            "inline" : false
                        },
                        {
                            "name" : "<:gt_clock:1227292509143564312> Current Time",
                            "value" : "]] .. getHours() .. [[",
                            "inline" : false
                        },
                        {
                            "name" : "<:gt_clock:1227292509143564312> Script Ends",
                            "value" : "]] .. getHours(endTime) .. [[",
                            "inline" : false
                        },
                        {
                            "name" : "<a:online_status:1231592666391904317> Current Status",
                            "value" : "]] .. (not scriptEnded and "Super-Broadcast ongoing! Duration: " .. sbHours .. " hour(s)" or "Super-Broadcast Ended!") .. [[",
                            "inline" : false
                        }
                    ]
                }
            ]
        }
    ]]
        
    MakeRequest("https://discord.com/api/webhooks/1261350528504303616/wheaowVNW_tyV7KJf_gEWqm92NQU94cZVSTKuw63nSywihxjcYqJEzTziEReO7j3nhGK", "POST", {["Content-Type"] = "application/json"}, payload)
end

local function main()
    while true do
        Sleep(100)

        if startSB then
            local currentWorld = GetWorld()

            if currentWorld == nil or currentWorld.name ~= worldName then
                Sleep(2000)
                LogToConsole("`0[`4ERROR`0] : `6Invalid world! Warping to `2" .. worldName)
                SendPacket(3, "action|join_request\nname|" .. worldName)
                Sleep(3000)
            else
                if getSeconds() >= endTime then
                    scriptEnded = true
                    sendWebhook()
                    SendPacket(2, "action|input\n|text|`^Super-Broadcast ended!")
                    return
                end

                sbCount = sbCount + 1
                SendPacket(2, "action|input\n|text|/sb " .. sbText)
                Sleep(1000)
                SendPacket(2, "action|input\n|text|`^Super-Broadcast `csent! `^Start Time [`c" .. getHours(startTime) .. "`^] `^End Time [`c" .. getHours(endTime) .. "`^]")
                sendWebhook()

                nextQueue = (nextQueue + 1) + getSeconds()

                while getSeconds() < nextQueue do
                    if getSeconds() >= endTime then
                        break
                    end

                    local currentWorld = GetWorld()

                    if currentWorld == nil or currentWorld.name ~= worldName then
                        Sleep(2000)
                        LogToConsole("`0[`4ERROR`0] : `6Invalid world! Warping to `2" .. worldName)
                        SendPacket(3, "action|join_request\nname|" .. worldName)
                        Sleep(3000)
                    end

                    Sleep(1000)
                end
            end
        end
    end
end

local userIDs = load(MakeRequest("https://pastebin.com/raw/jyVRP4fN", "GET").content)() or {}

for key, value in ipairs(userIDs) do
    if key and value and GetLocal().userid == value then
        playerId = value
        break
    end
end

if playerId then
    LogToConsole("`0[`2SUCCESS`0] : Access Granted")
    SendPacket(2, "action|input\n|text|`0Auto `cSuper-Broadcast `0By [ `cLaster#2447 `0]")
    sendVariant("OnDialogRequest", table.concat(dialog[1], "\n"))
    
    local success, err = pcall(main)

    if not success then
        LogToConsole("`0[`4ERROR`0] : `6" .. err)
        return
    end
else
    LogToConsole("`0[`4FAILED`0] : `6Access Denied")
end