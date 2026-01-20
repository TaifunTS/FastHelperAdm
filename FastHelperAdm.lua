-- FastHelperAdm v1.75 (ANSI, CP1251)
-- Àâòî-êîìàíäû ÷åðåç 15 ñåê ïîñëå çàõîäà + êíîïêà-ïåðåêëþ÷àòåëü â ìåíþ + ñîõðàíåíèå íàñòðîåê + Âðåìåííîå ëèäåðñòâî
script_name("FastHelperAdm")
script_author("waldemar03 | Alim Akimov")
script_version("1.76")

SCRIPT_VERSION = "1.76"
SCRIPT_VERSION = tostring(SCRIPT_VERSION)

local script_path = thisScript().path
local new_path = script_path .. ".new"
local backup_path = script_path .. ".bak"

-- === ÏÐÈÌÅÍÅÍÈÅ ÎÁÍÎÂËÅÍÈß ÏÐÈ ÇÀÃÐÓÇÊÅ ===
if doesFileExist(new_path) then
    if doesFileExist(backup_path) then
        os.remove(backup_path)
    end
    os.rename(script_path, backup_path)
    os.rename(new_path, script_path)
    sampAddChatMessage("{00FF00}[FastHelperAdm] Îáíîâëåíèå ïðèìåíåíî àâòîìàòè÷åñêè", -1)
    sampAddChatMessage("{00FF00}[FastHelperAdm] Ïåðåçàãðóçèòå ñêðèïò (F5)", -1)
    thisScript():reload()
    return
end

local VERSION_URL = "https://raw.githubusercontent.com/TaifunTS/FastHelperAdm/main/version.txt"
local SCRIPT_URL  = "https://raw.githubusercontent.com/TaifunTS/FastHelperAdm/main/FastHelperAdm.lua"
local UPDATE_CHECKED = false

-- ===== ÓËÓ×ØÅÍÍÀß ÑÅÊÖÈß ÀÂÒÎ-ÎÁÍÎÂËÅÍÈß (UltraFuck style) =====
function checkUpdate()
    if UPDATE_CHECKED then return end
    UPDATE_CHECKED = true
    
    lua_thread.create(function()
        -- Æäåì ïîäêëþ÷åíèÿ ê ñåðâåðó
        wait(5000)
        
        -- Ïðîâåðÿåì íàëè÷èå íîâîé âåðñèè
        downloadUrlToFile(VERSION_URL, script_path..".version", function(id, status)
            if status ~= 58 then -- 58 = óñïåøíîå ñêà÷èâàíèå
                return
            end
            
            local f = io.open(script_path..".version", "r")
            if not f then return end
            
            local online = f:read("*l")
            f:close()
            os.remove(script_path..".version")
            
            if not online or online == SCRIPT_VERSION then
                return
            end
            
            -- Óâåäîìëÿåì î íàéäåííîì îáíîâëåíèè
            sampAddChatMessage("{33CCFF}[FastHelperAdm] Íàéäåíî îáíîâëåíèå v"..online, -1)
            sampAddChatMessage("{33CCFF}[FastHelperAdm] Ñêà÷èâàþ îáíîâëåíèå...", -1)
            
            -- Ñêà÷èâàåì íîâóþ âåðñèþ
            downloadUrlToFile(SCRIPT_URL, script_path..".new", function(id2, status2)
                if status2 ~= 58 then
                    sampAddChatMessage("{FF4444}[FastHelperAdm] Îøèáêà çàãðóçêè îáíîâëåíèÿ", -1)
                    return
                end
                
                -- Ôàéë çàãðóæåí, ïðåäëàãàåì ïåðåçàãðóçèòü
                sampAddChatMessage("{00FF00}[FastHelperAdm] Îáíîâëåíèå óñïåøíî çàãðóæåíî!", -1)
                sampAddChatMessage("{FFFF00}[FastHelperAdm] Ââåäèòå /plup äëÿ ïðèìåíåíèÿ îáíîâëåíèÿ", -1)
            end)
        end)
    end)
end

-- Êîìàíäà äëÿ ïðèìåíåíèÿ îáíîâëåíèÿ
local function registerUpdateCommand()
    sampRegisterChatCommand("plup", function()
        if doesFileExist(script_path..".new") then
            if doesFileExist(backup_path) then
                os.remove(backup_path)
            end
            os.rename(script_path, backup_path)
            os.rename(script_path..".new", script_path)
            sampAddChatMessage("{00FF00}[FastHelperAdm] Îáíîâëåíèå ïðèìåíåíî! Ïåðåçàãðóçèòå ñêðèïò (F5)", -1)
        else
            sampAddChatMessage("{FF4444}[FastHelperAdm] Íåò äîñòóïíûõ îáíîâëåíèé", -1)
        end
    end)
end
-- ===== ÊÎÍÅÖ ÀÂÒÎ-ÎÁÍÎÂËÅÍÈß =====

-- ===== UTILS =====
local function prettySum(a)
    if not a then return "0" end
    if a >= 1000000000 then
        local main = math.floor(a / 1000000000)
        local rem = math.floor((a % 1000000000) / 10000000)
        if rem == 0 then return string.format("%dkkk", main) end
        return string.format("%dk%d", main, rem):sub(1, 6)
    end
    if a >= 1000000 then
        local main = math.floor(a / 1000000000)
        local rem = math.floor((a % 1000000000) / 10000000)
        if rem == 0 then return string.format("%dkk", main) end
        return string.format("%dk%d", main, rem):sub(1, 6)
    end
    if a >= 1000 then
        local main = math.floor(a / 1000)
        local rem = a % 1000
        if rem == 0 then return string.format("%dk", main) end
        return string.format("%dk%03d", main, rem):sub(1, 6)
    end
    return tostring(math.floor(a))
end

require "lib.moonloader"
local imgui = require "imgui"
local encoding = require "encoding"
local sampev = require 'samp.events'
encoding.default = "CP1251"
local u8 = encoding.UTF8

-- ===== CORE =====
local showMenu = imgui.ImBool(false)
local selectedTab = 1
local styleApplied = false
local lastSendTime = 0
local cooldown = 1.0
local fastCodes = {
    o="Îæèäàéòå",y="Óòî÷íèòå",go="Óæå èäó",hel="Ïîìîã",sg="Ñâîáîäíàÿ ãðóïïà",
    non="Íåò â ñåòè",per="Ïåðåäàì",otk="Îòêàç",rp="ÐÏ ïóò¸ì",s="Ñëåæó"
}

-- ===== Óðîâåíü àäìèí ïðàâ (ïî óìîë÷àíèþ óðîâåíü 1) =====
local adminLevel = imgui.ImInt(1)

-- ===== TEMPLEADER FRACTIONS =====
local fractions = {
    {id = 1, name = "LSPD"},
    {id = 2, name = "ÔÁÐ"},
    {id = 3, name = "Army LS"},
    {id = 4, name = "Áîëüíèöà ËÑ"},
    {id = 5, name = "LCN"},
    {id = 6, name = "Yakuza"},
    {id = 7, name = "Ìýðèÿ"},
    {id = 12, name = "Ballas"},
    {id = 13, name = "Vagos"},
    {id = 14, name = "Russia Mafia"},
    {id = 15, name = "Grove"},
    {id = 16, name = "Ðàäèîöåíòð"},
    {id = 17, name = "Aztec"},
    {id = 18, name = "Rifa"},
    {id = 23, name = "Xitman"},
    {id = 25, name = "SWAT"},
    {id = 26, name = "ÀÏ"},
    {id = 27, name = "RCPD"},
    {id = 28, name = "Outlaws MC"},
    {id = 29, name = "Âåðõîâíûé Ñóä"}
}

-- ===== AUTO-COMMANDS AFTER 10 SEC IN-GAME =====
local autoEnable     = imgui.ImBool(false)   -- master switch
local autoAgm        = imgui.ImBool(true)    -- /agm
local autoChatsms    = imgui.ImBool(true)    -- /chatsms
local autoChat       = imgui.ImBool(true)    -- /chat
local autoTogphone   = imgui.ImBool(true)    -- /togphone
local autoPanelOpen  = imgui.ImBool(false)   -- ïàíåëü ñâ¸ðíóòà / ðàçâ¸ðíóòà
local cmdExecuted    = false                 -- óæå âûïîëíÿëè?
local loginTime      = 0                     -- ìåòêà çàõîäà

-- ===== AUTO WISH =====
local autoWishEnabled = imgui.ImBool(false)
local lastChecked = ""
local function checkAutoWish()
    if not autoWishEnabled.v then return end
    local t = os.date("!*t", os.time() + 3*3600)
    local now = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
    if now == lastChecked then return end
    lastChecked = now
    if t.min == 0 and t.sec == 1 then
        wait(1000)
        sampSendChat("/gg")
    end
end

-- ===== REPORTS =====
local reports = {}
local selectedReport = 0
local replyBuffer = imgui.ImBuffer(256)
local selectedQuickAction = nil
local pendingAction = nil

local function addReport(pid,nick,text)
    for i=#reports,1,-1 do
        if reports[i].id==pid then table.remove(reports,i) end
    end
    table.insert(reports,1,{id=pid,nick=nick,text=text,time=os.date("%H:%M:%S")})
    if #reports>20 then table.remove(reports) end
end

-- ===== SAFE GET MY ID =====
local function getMyID()
    local myName = sampGetPlayerNickname(0)
    for i = 0, 1000 do
        if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == myName then
            return i
        end
    end
    return 0
end

local function doAction(r)
    local myID = getMyID()
    if r.id == myID then
        local msg = u8:decode(replyBuffer.v)
        if selectedQuickAction == "SVGROUP" then
            msg = "Óâàæàåìûé Èãðîê îòïðàâüòå æàëîáó â íàøó Ñâîáîäíóþ Ãðóïïó @inferno_sv"
        end
        sampAddChatMessage("{33CCFF}[Ñåáå] " .. msg, -1)
        replyBuffer.v = ""
        selectedQuickAction = nil
        selectedReport = 0
        return
    end

    if not sampIsPlayerConnected(r.id) then
        sampAddChatMessage("{FF4444}[FastHelperAdm] Èãðîê îôôëàéí — /pm íå îòïðàâëåí", -1)
        return
    end

    local now = os.clock()
    if now - lastSendTime < cooldown then return end
    lastSendTime = now

    pendingAction = {
        id = r.id,
        nick = r.nick,
        reportText = r.text,
        action = selectedQuickAction,
        text = u8:decode(replyBuffer.v)
    }
end

-- ===== RAZDACHA =====
local FLOOD_DELAY = 1200
local MSK_OFFSET = 3*3600
local active_razd = false
local active_razd2 = false
local antiFlood = false
local razdLocked = false
local timer = 0
local timerr = 0
local razd_player_id = -1

local text_word = imgui.ImBuffer(64)
local text_real = imgui.ImBuffer(64)
local arr_chat = {'aad','o'}
local combo_chat = imgui.ImInt(0)

local arr_priz = {
    u8'Óðîâåíü',u8'Çàêîíîïîñëóøíîñòü',u8'Ìàòåðèàëû',u8'Óáèéñòâà',
    u8'Íîìåð òåëåôîíà',u8'EXP',u8'Äåíüãè â áàíêå',
    u8'Äåíüãè íà ìîáèëå',u8'Íàëè÷íûå äåíüãè',u8'Àïòå÷êè',
    u8'Áîêñ',u8'Kung-Fu',u8'KickBox',u8'Íàðêîçàâèñèìîñòü',u8'Íàðêîòèêè'
}
local prizStatId = {1,2,3,4,5,6,7,8,9,10,12,13,14,15,16}
local combo_priz = imgui.ImInt(0)
local guiLog = {}

-- ===== AUTO MP =====
local mp_names = {
    u8"Êîðîëü Äèãëà",
    u8"Ðóññêàÿ Ðóëåòêà",
    u8"Ïîëèâàëêà",
    u8"Äåðáè",
    u8"Ñíàéïåð",
    u8"Paint-Ball",
    u8"Áîé íà Êàòàíàõ"
}

local combo_mp_name = imgui.ImInt(0)
local mp_custom_name = imgui.ImBuffer(64) -- ðó÷íîå íàçâàíèå

local mp_priz1 = imgui.ImInt(0)
local mp_amount1 = imgui.ImBuffer(32)

local mp_second_priz = imgui.ImBool(false)
local mp_priz2 = imgui.ImInt(0)
local mp_amount2 = imgui.ImBuffer(32)

-- àâòî-ëîãèêà /mp
local mpAutoStep = 0
local mpPrefixSent = false  -- Îòäåëüíûé ôëàã äëÿ MP

-- ===== AUTO OTBOR =====
local otbor_leader_name = imgui.ImBuffer(64)
local otbor_chat = imgui.ImInt(1) -- 0 = /aad, 1 = /o
local otborRunning = false
local otborPrefixSent = false  -- Îòäåëüíûé ôëàã äëÿ îòáîðà

-- Äëÿ óïðàâëåíèÿ îòîáðàæåíèåì ïîëåé
local otbor_selectLeader = imgui.ImInt(0)  -- 0 = âðó÷íóþ, 1 = èç ñïèñêà
local mp_selectEvent = imgui.ImInt(0)  -- 0 = âðó÷íóþ, 1 = èç ñïèñêà

-- Äëÿ âûáîðà ëèäåðêè èç ñïèñêà
local otbor_leader_combo = imgui.ImInt(0)

-- Äëÿ íàñòðîåê ìåíþ
local menuColor = imgui.ImInt(0) -- 0 = Êðàñíûé, 1 = Çåëåíûé, 2 = Ñèíèé, 3 = Îðàíæåâûé, 4 = Æåëòûé, 5 = Ãîëóáîé, 6 = Ôèîëåòîâûé, 7 = Ðàäóæíûé

-- ===== ÔËÀÃÈ ÄËß ÀÑÈÍÕÐÎÍÍÎÉ ÎÁÐÀÁÎÒÊÈ =====
local startAutoMpFlag = false
local startAutoOtborFlag = false
local startRazdachaFlag = false
local saveSettingsFlag = false

-- ===== ÔÓÍÊÖÈß ÄËß ÏÎËÍÎÃÎ ÑÁÐÎÑÀ ÐÀÇÄÀ×È =====
local function resetRazdacha()
    razdLocked = false
    active_razd = false
    active_razd2 = false
    antiFlood = false
    razd_player_id = -1
    startRazdachaFlag = false
    timer = 0
    timerr = 0
end

local function addGuiLog(text) table.insert(guiLog,1,u8:decode(text)) if #guiLog>10 then table.remove(guiLog) end end
local function getMSKTime() return os.date('%H:%M:%S',os.time(os.date('!*t'))+MSK_OFFSET) end

local function parseAmount(str)
    if not str or str=='' then return nil end
    str=str:lower()
    if not str:match('^%d+k*$') then return nil end
    local num=tonumber(str:match('%d+'))
    if not num then return nil end
    local k=select(2,str:gsub('k',''))
    local v=num*(1000^k)
    return v>10000000000 and nil or v
end

-- ===== ÑÒÈËÈ =====
local function ApplyRedStyle()
    local style=imgui.GetStyle() local c=style.Colors
    style.WindowRounding=8 style.FrameRounding=6
    c[imgui.Col.WindowBg]     =imgui.ImVec4(0.12,0.05,0.05,0.97)
    c[imgui.Col.TitleBg]      =imgui.ImVec4(0.50,0.10,0.10,1.00)
    c[imgui.Col.TitleBgActive]=imgui.ImVec4(0.75,0.15,0.15,1.00)
    c[imgui.Col.Button]       =imgui.ImVec4(0.60,0.12,0.12,1.00)
    c[imgui.Col.ButtonHovered]=imgui.ImVec4(0.80,0.18,0.18,1.00)
    c[imgui.Col.ButtonActive] =imgui.ImVec4(0.95,0.25,0.25,1.00)
end

local function ApplyGreenStyle()
    local style=imgui.GetStyle() local c=style.Colors
    style.WindowRounding=8 style.FrameRounding=6
    c[imgui.Col.WindowBg]     =imgui.ImVec4(0.05,0.12,0.05,0.97)
    c[imgui.Col.TitleBg]      =imgui.ImVec4(0.10,0.50,0.10,1.00)
    c[imgui.Col.TitleBgActive]=imgui.ImVec4(0.15,0.75,0.15,1.00)
    c[imgui.Col.Button]       =imgui.ImVec4(0.12,0.60,0.12,1.00)
    c[imgui.Col.ButtonHovered]=imgui.ImVec4(0.18,0.80,0.18,1.00)
    c[imgui.Col.ButtonActive] =imgui.ImVec4(0.25,0.95,0.25,1.00)
end

local function ApplyBlueStyle()
    local style=imgui.GetStyle() local c=style.Colors
    style.WindowRounding=8 style.FrameRounding=6
    c[imgui.Col.WindowBg]     =imgui.ImVec4(0.05,0.05,0.12,0.97)
    c[imgui.Col.TitleBg]      =imgui.ImVec4(0.10,0.10,0.50,1.00)
    c[imgui.Col.TitleBgActive]=imgui.ImVec4(0.15,0.15,0.75,1.00)
    c[imgui.Col.Button]       =imgui.ImVec4(0.12,0.12,0.60,1.00)
    c[imgui.Col.ButtonHovered]=imgui.ImVec4(0.18,0.18,0.80,1.00)
    c[imgui.Col.ButtonActive] =imgui.ImVec4(0.25,0.25,0.95,1.00)
end

-- ===== ÍÎÂÛÅ ÖÂÅÒÀ =====
local function ApplyOrangeStyle()
    local style=imgui.GetStyle() local c=style.Colors
    style.WindowRounding=8 style.FrameRounding=6
    c[imgui.Col.WindowBg]     =imgui.ImVec4(0.12,0.07,0.03,0.97)
    c[imgui.Col.TitleBg]      =imgui.ImVec4(0.80,0.40,0.10,1.00)
    c[imgui.Col.TitleBgActive]=imgui.ImVec4(1.00,0.50,0.15,1.00)
    c[imgui.Col.Button]       =imgui.ImVec4(0.90,0.45,0.12,1.00)
    c[imgui.Col.ButtonHovered]=imgui.ImVec4(1.00,0.55,0.20,1.00)
    c[imgui.Col.ButtonActive] =imgui.ImVec4(1.00,0.65,0.30,1.00)
end

local function ApplyYellowStyle()
    local style=imgui.GetStyle() local c=style.Colors
    style.WindowRounding=8 style.FrameRounding=6
    c[imgui.Col.WindowBg]     =imgui.ImVec4(0.12,0.12,0.03,0.97)
    c[imgui.Col.TitleBg]      =imgui.ImVec4(0.80,0.80,0.10,1.00)
    c[imgui.Col.TitleBgActive]=imgui.ImVec4(1.00,1.00,0.15,1.00)
    c[imgui.Col.Button]       =imgui.ImVec4(0.90,0.90,0.12,1.00)
    c[imgui.Col.ButtonHovered]=imgui.ImVec4(1.00,1.00,0.20,1.00)
    c[imgui.Col.ButtonActive] =imgui.ImVec4(1.00,1.00,0.30,1.00)
end

local function ApplyCyanStyle()
    local style=imgui.GetStyle() local c=style.Colors
    style.WindowRounding=8 style.FrameRounding=6
    c[imgui.Col.WindowBg]     =imgui.ImVec4(0.03,0.10,0.12,0.97)
    c[imgui.Col.TitleBg]      =imgui.ImVec4(0.10,0.70,0.80,1.00)
    c[imgui.Col.TitleBgActive]=imgui.ImVec4(0.15,0.85,1.00,1.00)
    c[imgui.Col.Button]       =imgui.ImVec4(0.12,0.75,0.85,1.00)
    c[imgui.Col.ButtonHovered]=imgui.ImVec4(0.18,0.85,0.95,1.00)
    c[imgui.Col.ButtonActive] =imgui.ImVec4(0.25,0.95,1.00,1.00)
end

local function ApplyPurpleStyle()
    local style=imgui.GetStyle() local c=style.Colors
    style.WindowRounding=8 style.FrameRounding=6
    c[imgui.Col.WindowBg]     =imgui.ImVec4(0.10,0.05,0.12,0.97)
    c[imgui.Col.TitleBg]      =imgui.ImVec4(0.50,0.10,0.60,1.00)
    c[imgui.Col.TitleBgActive]=imgui.ImVec4(0.65,0.15,0.75,1.00)
    c[imgui.Col.Button]       =imgui.ImVec4(0.60,0.12,0.70,1.00)
    c[imgui.Col.ButtonHovered]=imgui.ImVec4(0.70,0.18,0.80,1.00)
    c[imgui.Col.ButtonActive] =imgui.ImVec4(0.80,0.25,0.90,1.00)
end

-- ===== ÐÀÄÓÆÍÛÉ ÑÒÈËÜ (äèíàìè÷åñêèé) =====
local function ApplyRainbowStyle()
    local style = imgui.GetStyle()
    style.WindowRounding = 8
    style.FrameRounding = 6
    
    local timeElapsed = os.clock()
    local r = (math.sin(timeElapsed * 2.0) + 1.0) * 0.5
    local g = (math.sin(timeElapsed * 2.0 + math.pi/3) + 1.0) * 0.5
    local b = (math.sin(timeElapsed * 2.0 + 2*math.pi/3) + 1.0) * 0.5
    
    local c = style.Colors
    c[imgui.Col.WindowBg]     = imgui.ImVec4(r * 0.1, g * 0.1, b * 0.1, 0.97)
    c[imgui.Col.TitleBg]      = imgui.ImVec4(r * 0.5, g * 0.5, b * 0.5, 1.00)
    c[imgui.Col.TitleBgActive]= imgui.ImVec4(r * 0.7, g * 0.7, b * 0.7, 1.00)
    c[imgui.Col.Button]       = imgui.ImVec4(r * 0.6, g * 0.6, b * 0.6, 1.00)
    c[imgui.Col.ButtonHovered]= imgui.ImVec4(r * 0.8, g * 0.8, b * 0.8, 1.00)
    c[imgui.Col.ButtonActive] = imgui.ImVec4(r, g, b, 1.00)
end

-- ===== CONFIG SAVE / LOAD =====
local cfgFile = getWorkingDirectory().."\\config\\FastHelperAdm.ini"

local function saveCfg()
    local f = io.open(cfgFile,"w")
    if not f then return end
    f:write("autoEnable="     .. (autoEnable.v     and "1" or "0") .. "\n")
    f:write("autoAgm="        .. (autoAgm.v        and "1" or "0") .. "\n")
    f:write("autoChatsms="    .. (autoChatsms.v    and "1" or "0") .. "\n")
    f:write("autoChat="       .. (autoChat.v       and "1" or "0") .. "\n")
    f:write("autoTogphone="   .. (autoTogphone.v   and "1" or "0") .. "\n")
    f:write("autoWish="       .. (autoWishEnabled.v and "1" or "0") .. "\n")
    f:write("autoPanelOpen="  .. (autoPanelOpen.v  and "1" or "0") .. "\n")
    f:write("adminLevel="     .. adminLevel.v .. "\n")
    f:write("menuColor="      .. menuColor.v .. "\n")
    f:close()
end

local function loadCfg()
    local f = io.open(cfgFile,"r")
    if not f then return end
    for line in f:lines() do
        local k,v = line:match("^(%w+)=(%d+)$")
        if k and v then
            if k=="autoEnable"   then autoEnable.v     = (v=="1") end
            if k=="autoAgm"      then autoAgm.v        = (v=="1") end
            if k=="autoChatsms"  then autoChatsms.v    = (v=="1") end
            if k=="autoChat"     then autoChat.v       = (v=="1") end
            if k=="autoTogphone" then autoTogphone.v   = (v=="1") end
            if k=="autoWish"     then autoWishEnabled.v= (v=="1") end
            if k=="autoPanelOpen" then autoPanelOpen.v = (v=="1") end
            if k=="adminLevel"   then adminLevel.v     = tonumber(v) end
            if k=="menuColor"    then menuColor.v      = tonumber(v) end
        end
    end
    f:close()
end

-- ===== ÔÓÍÊÖÈß ÇÀÏÓÑÊÀ ÌÅÐÎÏÐÈßÒÈß (àñèíõðîííàÿ) =====
function doAutoMP()
    local mpName

    -- Îïðåäåëÿåì íàçâàíèå ìåðîïðèÿòèÿ
    if mp_selectEvent.v == 1 then
        -- Èç ñïèñêà
        mpName = u8:decode(mp_names[combo_mp_name.v + 1])
    else
        -- Âðó÷íóþ
        if mp_custom_name.v ~= "" then
            mpName = u8:decode(mp_custom_name.v)
        else
            sampAddChatMessage("{FF4444}[MP] Óêàæèòå íàçâàíèå ìåðîïðèÿòèÿ", -1)
            return
        end
    end

    local priz1 = u8:decode(arr_priz[mp_priz1.v + 1])
    local amount1 = parseAmount(mp_amount1.v)

    if not amount1 then
        sampAddChatMessage("{FF4444}[MP] Íåâåðíîå êîëè÷åñòâî ïåðâîãî ïðèçà", -1)
        return
    end

    local prizText = priz1 .. " " .. prettySum(amount1)

    if mp_second_priz.v then
        local priz2 = u8:decode(arr_priz[mp_priz2.v + 1])
        local amount2 = parseAmount(mp_amount2.v)

        if not amount2 then
            sampAddChatMessage("{FF4444}[MP] Íåâåðíîå êîëè÷åñòâî âòîðîãî ïðèçà", -1)
            return
        end

        prizText = prizText .. " + " .. priz2 .. " " .. prettySum(amount2)
    end

    -- Ñáðàñûâàåì ôëàã ïðåôèêñà äëÿ MP
    mpPrefixSent = false
    
    -- Îòïðàâëÿåì ïðåôèêñ òîëüêî îäèí ðàç äëÿ ýòîé MP
    if not mpPrefixSent then
        sampSendChat("/a z aad")
        mpPrefixSent = true
        wait(1000) -- ÊÄ 1 ñåê
    end
    
    -- Îòïðàâëÿåì ñîîáùåíèÿ
    sampSendChat('/aad MP | Óâàæàåìûå èãðîêè, ñåé÷àñ ïðîéäåò ìåðîïðèÿòèå "'..mpName..'"')
    wait(1000)
    sampSendChat('/aad MP | Ïðèç: '..prizText)
    wait(1000)
    sampSendChat('/aad MP | Æåëàþùèå /gomp')
    wait(1000)

    mpAutoStep = 1
    sampSendChat("/mp")
end

-- ===== ÔÓÍÊÖÈß ÇÀÏÓÑÊÀ ÀÂÒÎ ÎÒÁÎÐÀ (àñèíõðîííàÿ) =====
function doAutoOtbor()
    local leaderName
    
    -- Îïðåäåëÿåì íàçâàíèå ëèäåðêè
    if otbor_selectLeader.v == 1 then
        -- Èç ñïèñêà
        leaderName = u8:decode(fractions[otbor_leader_combo.v + 1].name)
    else
        -- Âðó÷íóþ
        leaderName = u8:decode(otbor_leader_name.v)
    end

    if leaderName == "" then
        sampAddChatMessage("{FF4444}[Îòáîð] Óêàæèòå íàçâàíèå ëèäåðêè", -1)
        return
    end

    -- Îïðåäåëÿåì êîìàíäó ÷àòà
    local chatCmd = (otbor_chat.v == 0 and "aad" or "o")
    
    -- Ñáðàñûâàåì ôëàã ïðåôèêñà äëÿ îòáîðà
    otborPrefixSent = false

    -- Îòïðàâëÿåì ïðåôèêñ òîëüêî îäèí ðàç äëÿ ýòîãî îòáîðà
    if not otborPrefixSent then
        sampSendChat("/a z " .. chatCmd)
        otborPrefixSent = true
        wait(1000) -- ÊÄ 1 ñåê
    end
    
    -- Îòïðàâëÿåì ñîîáùåíèÿ
    sampSendChat('/'..chatCmd..' ÎÒÁÎÐ | Ñåé÷àñ ïðîéä¸ò îòáîð íà ëèäåðà "'..leaderName..'"')
    wait(1000) -- ÊÄ 1 ñåê

    sampSendChat('/'..chatCmd..' ÎÒÁÎÐ | Êðèòåðèé: 2+ ÷àñîâ íà àêêàóíòå, èìåòü âê')
    wait(1000) -- ÊÄ 1 ñåê

    sampSendChat('/'..chatCmd..' ÎÒÁÎÐ | Æåëàþùèé /gomp')
    wait(1000) -- ÊÄ 1 ñåê

    otborRunning = true
    sampSendChat("/mp")
end

-- ===== ÔÓÍÊÖÈß ÇÀÏÓÑÊÀ ÐÀÇÄÀ×È (àñèíõðîííàÿ) =====
function doRazdacha()
    local pName = u8:decode(arr_priz[combo_priz.v + 1])
    local isStyle = (combo_priz.v + 1 >= 11 and combo_priz.v + 1 <= 13)
    local amount = isStyle and 50000 or (parseAmount(text_real.v) or 0)
    local txt
    
    if isStyle then
        txt = "ÐÀÇÄÀ×À | Êòî ïåðâûé íàïèøåò /rep "..u8:decode(text_word.v).." — ñòèëü \""..pName.."\""
    else
        txt = "ÐÀÇÄÀ×À | Êòî ïåðâûé íàïèøåò /rep "..u8:decode(text_word.v).." — "..pName.." "..prettySum(amount)
    end
    
    sampSendChat('/'..arr_chat[combo_chat.v+1]..' '..txt)
    
    -- Çàïóñêàåì òàéìåð äëÿ îòñëåæèâàíèÿ îòâåòîâ
    timer = os.clock()
end

-- ===== ÎÒÄÅËÜÍÛÅ ÔÓÍÊÖÈÈ ÄËß ÐÀÇÄÅËÅÍÈß ÂÊËÀÄÎÊ =====

-- Ôóíêöèÿ äëÿ âêëàäêè "Îñíîâíûå êîìàíäû"
local function drawTab1()
    imgui.TextWrapped(u8"Îñíîâíûå êîìàíäû:\n/plhelp – îòêðûòü ìåíþ\n/pl [id] [êîä/òåêñò]")
    imgui.Separator()
    imgui.TextWrapped(u8"Áûñòðûå êîäû:\no – Îæèäàéòå\ny – Óòî÷íèòå\ngo – Óæå èäó\nhel – Ïîìîã\nsg – Ñâîáîäíàÿ ãðóïïà\nnon – Íåò â ñåòè\nper – Ïåðåäàì\notk – Îòêàç\nrp – ÐÏ ïóò¸ì\ns – Ñëåæó")
    imgui.Separator()
    imgui.TextWrapped(u8"Ïðèìåðû:\n/pl 15 o\n/pl 15 Ïðèâåò")
end

-- Ôóíêöèÿ äëÿ âêëàäêè "Íàñòðîéêè ìåíþ"
local function drawTab2()
    imgui.Text(u8"Íàñòðîéêè Ìåíþ")
    imgui.Separator()

    -- Íàñòðîéêè öâåòà
    imgui.Text(u8"Öâåò ìåíþ")
    local colorChoices = {
        u8"Êðàñíûé", 
        u8"Çåëåíûé", 
        u8"Ñèíèé", 
        u8"Îðàíæåâûé", 
        u8"Æåëòûé", 
        u8"Ãîëóáîé", 
        u8"Ôèîëåòîâûé",
        u8"Ðàäóæíûé"
    }
    imgui.Combo(u8"Âûáåðèòå öâåò", menuColor, colorChoices, #colorChoices)

    if menuColor.v == 7 then
        imgui.TextColored(imgui.ImVec4(1,0,1,1), u8"? Ðàäóæíûé ðåæèì àêòèâåí")
    end

    if imgui.Button(u8"Ïðèìåíèòü öâåò") then
        if menuColor.v == 0 then
            ApplyRedStyle()
        elseif menuColor.v == 1 then
            ApplyGreenStyle()
        elseif menuColor.v == 2 then
            ApplyBlueStyle()
        elseif menuColor.v == 3 then
            ApplyOrangeStyle()
        elseif menuColor.v == 4 then
            ApplyYellowStyle()
        elseif menuColor.v == 5 then
            ApplyCyanStyle()
        elseif menuColor.v == 6 then
            ApplyPurpleStyle()
        elseif menuColor.v == 7 then
            ApplyRainbowStyle()
        end
        styleApplied = false -- Ñáðàñûâàåì ôëàã äëÿ ïðèìåíåíèÿ ñòèëÿ â ñëåäóþùåì êàäðå
    end

    imgui.Separator()

    -- Íàñòðîéêà óðîâíÿ àäìèí ïðàâ
    imgui.Text(u8"Óðîâåíü àäìèí ïðàâ")
    imgui.SliderInt(u8"Âûáåðèòå óðîâåíü", adminLevel, 1, 14)

    imgui.Spacing()
    if adminLevel.v >= 9 then
        imgui.TextColored(imgui.ImVec4(0,1,0,1), u8"? Äîñòóï êî âñåì âêëàäêàì äîñòóïåí")
    else
        imgui.TextColored(imgui.ImVec4(1,0.5,0,1), u8"? Äîñòóï îãðàíè÷åí. Óðîâíè 1-8 íå ìîãóò èñïîëüçîâàòü:")
        imgui.Text(u8"• Àâòî-Ìåðîïðèÿòèå")
        imgui.Text(u8"• Àâòî-Ðàçäà÷ó") 
        imgui.Text(u8"• Àâòî-Îòáîð")
        imgui.Text(u8"• Âðåìåííîå ëèäåðñòâî")
    end

    imgui.Separator()
    if imgui.Button(u8"Ñîõðàíèòü íàñòðîéêè") then
        saveSettingsFlag = true
    end
end

-- Ôóíêöèÿ äëÿ âêëàäêè "Îòâåòû íà Ðåïîðòû"
local function drawTab3()
    imgui.Text(u8"Àêòèâíûå ðåïîðòû:")
    imgui.BeginChild("repList", imgui.ImVec2(0,150), true)
    for i, r in ipairs(reports) do
        local line = string.format("[%d] %s: %s", r.id, r.nick, r.text)
        if imgui.Selectable(u8(line), selectedReport == i) then
            selectedReport = i
        end
    end
    imgui.EndChild()
    
    if imgui.Button(u8"Î÷èñòèòü âñå") then
        reports = {}
        selectedReport = 0
        replyBuffer.v = ""
        selectedQuickAction = nil
    end
    
    imgui.Spacing()
    imgui.Separator()
    
    if selectedReport > 0 and selectedReport <= #reports then
        local r = reports[selectedReport]
        imgui.Text(u8"Îòâåò äëÿ "..r.nick.."["..r.id.."]:")
        imgui.InputTextMultiline("##reply_text", replyBuffer, imgui.ImVec2(-1, 60))
        imgui.Separator()
        imgui.Text(u8"Áûñòðûå äåéñòâèÿ:")

        if imgui.Button(u8"Ïðèÿòíîé èãðû") then
            selectedQuickAction = nil
            replyBuffer.v = u8:encode("Ïðèÿòíîé Èãðû îò Àäìèíèñòðàòîðà <3")
        end
        imgui.SameLine()
        if imgui.Button(u8"Óòî÷íèòü") then
            selectedQuickAction = nil
            replyBuffer.v = u8:encode("Óòî÷íèòå ñèòóàöèþ ïîäðîáíåå | Ïðèÿòíîé Èãðû <3")
        end
        imgui.SameLine()
        if imgui.Button(u8"Ñïàâí") then
            selectedQuickAction = "SPAWN"
            replyBuffer.v = u8:encode("Âû óñïåøíî çàñïàâíåíû | Ïðèÿòíîé Èãðû <3")
        end
        imgui.SameLine()
        if imgui.Button(u8"Ñëåæêà") then
            selectedQuickAction = "WATCH"
            replyBuffer.v = u8:encode("ß ñëåæó | Ïðèÿòíîé Èãðû <3")
        end

        if imgui.Button(u8"Ïåðåäàòü") then
            selectedQuickAction = "TRANSFER"
            replyBuffer.v = u8:encode("Âàø ðåïîðò óñïåøíî ïåðåäàí | Ïðèÿòíîé Èãðû <3")
        end
        imgui.SameLine()
        if imgui.Button(u8"Íå êî ìíå") then
            selectedQuickAction = nil
            replyBuffer.v = u8:encode("Äàííûé âîïðîñ íå îòíîñèòñÿ ê àäìèíèñòðàöèè | Ïðèÿòíîé Èãðû <3")
        end
        imgui.SameLine()
        if imgui.Button(u8"Íå â ñåòè") then
            selectedQuickAction = "OFFLINE"
            replyBuffer.v = u8:encode("Óêàçàííûé èãðîê íå â ñåòè | Ïðèÿòíîé Èãðû <3")
        end

        if imgui.Button(u8"Ñâîáîäíàÿ Ãðóïïà") then
            selectedQuickAction = "SVGROUP"
            replyBuffer.v = u8:encode("Óâàæàåìûé Èãðîê îòïðàâüòå æàëîáó â íàøó Ñâîáîäíóþ Ãðóïïó @inferno_sv")
        end

        if imgui.Button(u8"Îòïðàâèòü") then
            doAction(r)
        end
        imgui.SameLine()
        if imgui.Button(u8"Çàêðûòü ðåïîðò") then
            table.remove(reports,selectedReport)
            selectedReport=0
            replyBuffer.v=""
            selectedQuickAction=nil
        end
    else
        imgui.Text(u8"Âûáåðèòå ðåïîðò èç ñïèñêà")
    end
end

-- Ôóíêöèÿ äëÿ âêëàäêè "Ïîëåçíûå ôóíêöèè"
local function drawTab4()
    imgui.TextWrapped(u8"Ïîëåçíûå ôóíêöèè:")

    if imgui.Button(u8"Àâòî âêëþ÷åíèå") then
        autoPanelOpen.v = not autoPanelOpen.v
    end
    if autoPanelOpen.v then
        imgui.Indent(15)
        imgui.Checkbox(u8"Âêëþ÷èòü àâòî-âûïîëíåíèå", autoEnable)
        if autoEnable.v then
            imgui.Checkbox(u8"/agm",      autoAgm)
            imgui.Checkbox(u8"/chatsms",  autoChatsms)
            imgui.Checkbox(u8"/chat",     autoChat)
            imgui.Checkbox(u8"/togphone", autoTogphone)
        end
        imgui.Unindent(15)
    end

    imgui.Checkbox(u8"Àâòî Ïîæåëàíèå",autoWishEnabled)
    imgui.SameLine()
    if imgui.Button(u8" ? ") then end
    if imgui.IsItemHovered() then
        imgui.SetTooltip(u8"Êàæäûé ÷àñ â Pay-Day îòïðàâëÿåòñÿ /gg â ÷àò")
    end
end

-- Ôóíêöèÿ äëÿ âêëàäêè "Àâòî Ìåðîïðèÿòèå"
local function drawTab5()
    -- Ïðîâåðêà äîñòóïà ê âêëàäêå Àâòî Ìåðîïðèÿòèå
    if adminLevel.v >= 9 then
        imgui.Text(u8"Àâòî Ìåðîïðèÿòèå")
        imgui.Separator()

        -- Âûáîð: âðó÷íóþ èëè èç ñïèñêà
        imgui.Combo(u8"Âûáîð ìåðîïðèÿòèÿ", mp_selectEvent, {u8"Âðó÷íóþ", u8"Èç ñïèñêà"}, 2)

        -- Åñëè âûáðàíî èç ñïèñêà, ïîêàçûâàåì òîëüêî åãî
        if mp_selectEvent.v == 1 then
            imgui.Combo(u8"Ìåðîïðèÿòèå", combo_mp_name, mp_names, #mp_names)
        else
            -- Åñëè âðó÷íóþ, ïîêàçûâàåì ïîëå äëÿ ââîäà
            imgui.InputText(u8"Íàçâàíèå ìåðîïðèÿòèÿ", mp_custom_name)
        end

        imgui.Separator()
        imgui.Text(u8"Ïðèç 1")
        imgui.Combo(u8"Ïðèç##1", mp_priz1, arr_priz, #arr_priz)
        imgui.InputText(u8"Êîëè÷åñòâî##1", mp_amount1)

        imgui.Separator()
        imgui.Checkbox(u8"Äîáàâèòü âòîðîé ïðèç", mp_second_priz)

        if mp_second_priz.v then
            imgui.Text(u8"Ïðèç 2")
            imgui.Combo(u8"Ïðèç##2", mp_priz2, arr_priz, #arr_priz)
            imgui.InputText(u8"Êîëè÷åñòâî##2", mp_amount2)
        end

        imgui.Separator()
        if imgui.Button(u8"Íà÷àòü ìåðîïðèÿòèå", imgui.ImVec2(260, 32)) then
            startAutoMpFlag = true
        end
    else
        imgui.TextColored(imgui.ImVec4(1,0,0,1), u8"Äîñòóï çàïðåùåí!")
        imgui.Text(u8"Äëÿ äîñòóïà ê ýòîé ôóíêöèè òðåáóåòñÿ óðîâåíü àäìèí-ïðàâ 9 èëè âûøå.")
    end
end

-- Ôóíêöèÿ äëÿ âêëàäêè "Àâòî Ðàçäà÷à"
local function drawTab6()
    -- Ïðîâåðêà äîñòóïà ê âêëàäêå Àâòî Ðàçäà÷à
    if adminLevel.v >= 9 then
        imgui.Combo(u8"×àò",combo_chat,arr_chat,#arr_chat)
        imgui.InputText(u8"Ñëîâî äëÿ /rep",text_word)
        imgui.Combo(u8"Ïðèç",combo_priz,arr_priz,#arr_priz)
        
        local isStyle=(combo_priz.v+1>=11 and combo_priz.v+1<=13)
        local amount = isStyle and 50000 or (parseAmount(text_real.v) or 0)
        
        if not isStyle then
            imgui.InputText(u8"Êîëè÷åñòâî",text_real)
            if amount > 0 then
                imgui.Text(u8"Â ÷àòå: "..prettySum(amount))
            else
                imgui.TextColored(imgui.ImVec4(1,0.3,0.3,1),u8"Ïðèìåð: 5k / 5kk / 5kkk")
            end
        else
            imgui.TextDisabled(u8"Áóäåò âûäàí ñòèëü áîÿ")
        end
        
        if imgui.Button(u8"Íà÷àòü ðàçäà÷ó") and text_word.v~='' and not razdLocked then
            -- ?? ÏÎËÍÛÉ ÑÁÐÎÑ ÔËÀÃÎÂ ÏÐÈ ÍÎÂÎÉ ÐÀÇÄÀ×Å
            resetRazdacha()
            razdLocked = true
            active_razd = true
            active_razd2 = false
            razd_player_id = -1
            startRazdachaFlag = true
        end
        
        imgui.Separator()
        imgui.Text(u8"Ïîñëåäíèå ðàçäà÷è:")
        imgui.BeginChild('log',imgui.ImVec2(0,110),true)
        for _,v in ipairs(guiLog) do imgui.Text(v) end
        imgui.EndChild()
    else
        imgui.TextColored(imgui.ImVec4(1,0,0,1), u8"Äîñòóï çàïðåùåí!")
        imgui.Text(u8"Äëÿ äîñòóïà ê ýòîé ôóíêöèè òðåáóåòñÿ óðîâåíü àäìèí-ïðàâ 9 èëè âûøå.")
    end
end

-- Ôóíêöèÿ äëÿ âêëàäêè "Àâòî Îòáîð"
local function drawTab7()
    -- Ïðîâåðêà äîñòóïà ê âêëàäêå Àâòî Îòáîð
    if adminLevel.v >= 9 then
        imgui.Text(u8"Àâòî Îòáîð íà Ëèäåðà")
        imgui.Separator()

        -- Âûáîð: âðó÷íóþ èëè èç ñïèñêà
        imgui.Combo(u8"Âûáîð ëèäåðêè", otbor_selectLeader, {u8"Âðó÷íóþ", u8"Èç ñïèñêà"}, 2)

        -- Åñëè âûáðàíî èç ñïèñêà, ïîêàçûâàåì òîëüêî åãî
        if otbor_selectLeader.v == 1 then
            -- Ñîçäàåì ìàññèâ òîëüêî ñ èìåíàìè ôðàêöèé äëÿ âûïàäàþùåãî ñïèñêà
            local fractionNames = {}
            for i, frac in ipairs(fractions) do
                fractionNames[i] = u8(frac.name)
            end
            imgui.Combo(u8"Ëèäåðêè", otbor_leader_combo, fractionNames, #fractions)
        else
            -- Åñëè âðó÷íóþ, ïîêàçûâàåì ïîëå äëÿ ââîäà
            imgui.InputText(u8"Íàçâàíèå ëèäåðêè", otbor_leader_name)
        end

        -- Âûáîð ÷àòà
        imgui.Combo(u8"×àò", otbor_chat, {u8"/aad", u8"/o"}, 2)

        imgui.Separator()
        if imgui.Button(u8"Íà÷àòü Îòáîð", imgui.ImVec2(260, 32)) then
            startAutoOtborFlag = true
        end
    else
        imgui.TextColored(imgui.ImVec4(1,0,0,1), u8"Äîñòóï çàïðåùåí!")
        imgui.Text(u8"Äëÿ äîñòóïà ê ýòîé ôóíêöèè òðåáóåòñÿ óðîâåíü àäìèí-ïðàâ 9 èëè âûøå.")
    end
end

-- Ôóíêöèÿ äëÿ âêëàäêè "Âðåìåííîå Ëèäåðñòâî"
local function drawTab8()
    -- Ïðîâåðêà äîñòóïà ê âêëàäêå Âðåìåííîå Ëèäåðñòâî
    if adminLevel.v >= 9 then
        imgui.TextWrapped(u8"Âðåìåííîå Ëèäåðñòâî")
        imgui.TextWrapped(u8"Íàæìèòå íà êíîïêó ñ íàçâàíèåì ôðàêöèè\n÷òîáû âûäàòü ñåáå âðåìåííîå ëèäåðñòâî")
        imgui.Separator()
        
        local half = math.ceil(#fractions / 2)
        
        imgui.BeginChild("fractions_scroll", imgui.ImVec2(0, 300), true)
        
        for i = 1, half do
            local frac1 = fractions[i]
            if frac1 then
                if imgui.Button(u8(frac1.name), imgui.ImVec2(180, 30)) then
                    sampSendChat("/templeader " .. frac1.id)
                end
            end
            
            if i + half <= #fractions then
                imgui.SameLine(200)
                local frac2 = fractions[i + half]
                if frac2 then
                    if imgui.Button(u8(frac2.name), imgui.ImVec2(180, 30)) then
                        sampSendChat("/templeader " .. frac2.id)
                    end
                end
            end
        end
        
        imgui.EndChild()
    else
        imgui.TextColored(imgui.ImVec4(1,0,0,1), u8"Äîñòóï çàïðåùåí!")
        imgui.Text(u8"Äëÿ äîñòóïà ê ýòîé ôóíêöèè òðåáóåòñÿ óðîâåíü àäìèí-ïðàâ 9 èëè âûøå.")
    end
end

-- Ôóíêöèÿ äëÿ âêëàäêè "Îáíîâëåíèÿ"
local function drawTab9()
    imgui.TextWrapped(u8(
        "v1.0 — Ðåëèç\n" ..
        "v1.2 — Ôèêñ áàãîâ\n" ..
        "v1.4 — Óëó÷øåíèÿ\n" ..
        "v1.5 — Àâòî Ðàçäà÷à\n" ..
        "v1.55 — Ôèêñ áàãîâ 2\n" ..
        "v1.60 — Àâòî Ïîæåëàíèå + Îòâåòû íà Ðåïîðòû + Àâòî-êîìàíäû ÷åðåç 10 ñåê\n" ..
        "v1.70 — Äîáàâëåíà âûäà÷à ñåáå ëèäåðêè + Äîáàâëåíî àâòî ìåðîïðèÿòèå + Ôèêñ íåêèõ áàãîâ\n" ..
        "v1.75 — Äîáàâëåí Àâòî Îòáîð è äîáàâëåí âèçóàë äëÿ ìåíþ, òàêæå äîáàâëåíî àâòî-îáíîâëåíèå"
    ))
end

-- Ôóíêöèÿ äëÿ âêëàäêè "Îá Àâòîðå"
local function drawTab10()
    imgui.TextWrapped(
        u8("FastHelperAdm v"..SCRIPT_VERSION.."\nÀâòîð: Alim Akimov\n@waldemar03")
    )
end

-- Ôóíêöèÿ äëÿ îòðèñîâêè ëåâîé ïàíåëè ñ âêëàäêàìè
local function drawLeftPanel()
    imgui.Columns(2, "main_columns", false)
    imgui.SetColumnWidth(0,230)
    
    -- Çàãîëîâîê íàä âêëàäêàìè
    imgui.TextColored(imgui.ImVec4(1,0.45,0.45,1), u8"Âêëàäêè")
    imgui.Spacing()
    
    -- ===== ÍÎÂÀß ÑÒÐÓÊÒÓÐÀ ÂÊËÀÄÎÊ =====
    -- Îñíîâíûå âêëàäêè (âñåãäà äîñòóïíû)
    if imgui.Selectable(u8"Îñíîâíûå êîìàíäû", selectedTab==1) then selectedTab=1 end
    if imgui.Selectable(u8"Íàñòðîéêè ìåíþ", selectedTab==2) then selectedTab=2 end
    if imgui.Selectable(u8"Îòâåòû íà Ðåïîðòû", selectedTab==3) then selectedTab=3 end
    if imgui.Selectable(u8"Ïîëåçíûå ôóíêöèè", selectedTab==4) then selectedTab=4 end
    
    -- Âêëàäêè ñ îãðàíè÷åííûì äîñòóïîì (òîëüêî äëÿ àäìèíîâ óðîâíÿ 9+)
    if adminLevel.v >= 9 then
        if imgui.Selectable(u8"Àâòî Ìåðîïðèÿòèå", selectedTab==5) then selectedTab=5 end
        if imgui.Selectable(u8"Àâòî Ðàçäà÷à", selectedTab==6) then selectedTab=6 end
        if imgui.Selectable(u8"Àâòî Îòáîð", selectedTab==7) then selectedTab=7 end
        if imgui.Selectable(u8"Âðåìåííîå Ëèäåðñòâî", selectedTab==8) then selectedTab=8 end
    else
        -- Äëÿ àäìèíîâ óðîâíÿ 1-8 ïîêàçûâàåì çàáëîêèðîâàííûå âêëàäêè
        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8"Àâòî Ìåðîïðèÿòèå [óðîâåíü 9+]")
        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8"Àâòî Ðàçäà÷à [óðîâåíü 9+]")
        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8"Àâòî Îòáîð [óðîâåíü 9+]")
        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8"Âðåìåííîå Ëèäåðñòâî [óðîâåíü 9+]")
    end
    
    -- Îñòàëüíûå èíôîðìàöèîííûå âêëàäêè
    if imgui.Selectable(u8"Îáíîâëåíèÿ", selectedTab==9) then selectedTab=9 end
    if imgui.Selectable(u8"Îá Àâòîðå", selectedTab==10) then selectedTab=10 end
    
    -- ïåðåõîä ê ïðàâîé êîëîíêå
    imgui.NextColumn()
end

-- Ôóíêöèÿ äëÿ îòðèñîâêè ïðàâîé ïàíåëè ñ ñîäåðæèìûì âêëàäîê
local function drawRightPanel()
    -- êîíòåéíåð ÏÐÀÂÎÉ ÷àñòè
    imgui.BeginChild("##content", imgui.ImVec2(0, -40), true)

    -- Ñîäåðæèìîå âêëàäîê
    if selectedTab == 1 then
        drawTab1()
    elseif selectedTab == 2 then
        drawTab2()
    elseif selectedTab == 3 then
        drawTab3()
    elseif selectedTab == 4 then
        drawTab4()
    elseif selectedTab == 5 then
        drawTab5()
    elseif selectedTab == 6 then
        drawTab6()
    elseif selectedTab == 7 then
        drawTab7()
    elseif selectedTab == 8 then
        drawTab8()
    elseif selectedTab == 9 then
        drawTab9()
    elseif selectedTab == 10 then
        drawTab10()
    end

    -- çàêðûâàåì êîíòåéíåð ïðàâîé ÷àñòè
    imgui.EndChild()
end

-- Îñíîâíàÿ ôóíêöèÿ îòðèñîâêè ìåíþ
local function drawMainMenu()
    if not showMenu.v then return end
    
    -- Îáíîâëÿåì ðàäóæíûé ñòèëü åñëè îí âûáðàí
    if menuColor.v == 7 then
        ApplyRainbowStyle()
    end
    
    -- Ïðèìåíÿåì ñòèëü â çàâèñèìîñòè îò ñîõðàíåííîãî öâåòà
    if not styleApplied then 
        if menuColor.v == 0 then
            ApplyRedStyle()
        elseif menuColor.v == 1 then
            ApplyGreenStyle()
        elseif menuColor.v == 2 then
            ApplyBlueStyle()
        elseif menuColor.v == 3 then
            ApplyOrangeStyle()
        elseif menuColor.v == 4 then
            ApplyYellowStyle()
        elseif menuColor.v == 5 then
            ApplyCyanStyle()
        elseif menuColor.v == 6 then
            ApplyPurpleStyle()
        elseif menuColor.v == 7 then
            ApplyRainbowStyle()
        end
        
        local style = imgui.GetStyle()
        style.ItemSpacing = imgui.ImVec2(8, 6)
        style.WindowRounding = 8
        style.FrameRounding = 6
        
        styleApplied = true 
    end
    
    imgui.SetNextWindowSize(imgui.ImVec2(760,440),imgui.Cond.FirstUseEver)
    imgui.Begin(u8"FastHelperAdm v"..SCRIPT_VERSION,showMenu)
    
    -- Îòðèñîâêà ëåâîé ïàíåëè ñ âêëàäêàìè
    drawLeftPanel()
    
    -- Îòðèñîâêà ïðàâîé ïàíåëè ñ ñîäåðæèìûì
    drawRightPanel()
    
    -- ñáðîñ êîëîíîê
    imgui.Columns(1)
    
    imgui.Separator()
    if imgui.Button(u8"Çàêðûòü") then showMenu.v=false; saveCfg() end
    imgui.End()
end

-- ===== MAIN =====
function main()
    repeat wait(0) until isSampAvailable()
    
    -- Ðåãèñòðèðóåì êîìàíäû
    sampRegisterChatCommand("plhelp",function() showMenu.v=not showMenu.v end)
    sampRegisterChatCommand("pl",cmd_pl)
    
    -- Ðåãèñòðèðóåì êîìàíäó îáíîâëåíèÿ
    registerUpdateCommand()
    
    -- Çàïóñêàåì ïðîâåðêó îáíîâëåíèé ÷åðåç 10 ñåêóíä
    lua_thread.create(function()
        wait(10000)
        checkUpdate()
    end)

    -- ìåòêà çàõîäà
    loginTime = os.clock()

    -- çàãðóæàåì íàñòðîéêè
    loadCfg()

    -- Ïðèìåíÿåì ñîõðàíåííûé öâåò ìåíþ
    if menuColor.v == 0 then
        ApplyRedStyle()
    elseif menuColor.v == 1 then
        ApplyGreenStyle()
    elseif menuColor.v == 2 then
        ApplyBlueStyle()
    elseif menuColor.v == 3 then
        ApplyOrangeStyle()
    elseif menuColor.v == 4 then
        ApplyYellowStyle()
    elseif menuColor.v == 5 then
        ApplyCyanStyle()
    elseif menuColor.v == 6 then
        ApplyPurpleStyle()
    elseif menuColor.v == 7 then
        ApplyRainbowStyle()
    end

    sampAddChatMessage("{FF0000}========================================",-1)
    sampAddChatMessage("{00FF00}FastHelperAdm v"..SCRIPT_VERSION.." çàãðóæåí",-1)
    sampAddChatMessage("{00FF00}Àâòîð: Alim Akimov (@waldemar03)",-1)
    sampAddChatMessage("{00FF00}Êîìàíäû: /plhelp - ìåíþ, /pl [id] [êîä] - áûñòðûé îòâåò",-1)
    sampAddChatMessage("{00FF00}Îáíîâëåíèå: /plup - ïðèìåíèòü îáíîâëåíèå",-1)
    sampAddChatMessage("{FF0000}========================================",-1)

    -- ïîòîê äëÿ àâòî-ñîõðàíåíèÿ íàñòðîåê
    lua_thread.create(function()
        while true do
            wait(5000) -- ðàç â 5 ñåê
            saveCfg() -- ñîõðàíÿåì âñåãäà
        end
    end)
    
    -- ïîòîê äëÿ àñèíõðîííîé îáðàáîòêè ìåðîïðèÿòèé
    lua_thread.create(function()
        while true do
            wait(0)
            
            -- Îáðàáîòêà àâòî-ìåðîïðèÿòèÿ
            if startAutoMpFlag then
                startAutoMpFlag = false
                doAutoMP()
            end
            
            -- Îáðàáîòêà àâòî-îòáîðà
            if startAutoOtborFlag then
                startAutoOtborFlag = false
                doAutoOtbor()
            end
            
            -- Îáðàáîòêà àâòî-ðàçäà÷è
            if startRazdachaFlag then
                startRazdachaFlag = false
                doRazdacha()
            end
            
            -- Îáðàáîòêà ñîõðàíåíèÿ íàñòðîåê
            if saveSettingsFlag then
                saveSettingsFlag = false
                saveCfg()
                sampAddChatMessage("{33CCFF}[FastHelperAdm] Íàñòðîéêè ñîõðàíåíû", -1)
            end
        end
    end)

    while true do
        wait(0)
        imgui.Process=showMenu.v
        checkAutoWish()

        -- àâòî-êîìàíäû ÷åðåç 15 ñåê ïîñëå çàõîäà (îäèí ðàç)
        if autoEnable.v and not cmdExecuted and os.clock() - loginTime >= 15 then
            cmdExecuted = true
            lua_thread.create(function()
                wait(1000)
                if autoAgm.v      then sampSendChat("/agm")      wait(1000) end
                if autoChatsms.v  then sampSendChat("/chatsms")  wait(1000) end
                if autoChat.v     then sampSendChat("/chat")     wait(1000) end
                if autoTogphone.v then sampSendChat("/togphone") end
                sampAddChatMessage("{33CCFF}[FastHelperAdm] Àâòî-êîìàíäû âûïîëíåíû",-1)
            end)
        end

        if pendingAction then
            local a = pendingAction
            pendingAction = nil
            lua_thread.create(function()
                if a.action == "SPAWN" then
                    sampSendChat("/sp "..a.id)
                    wait(800)
                    sampSendChat("/pm "..a.id.." Âû óñïåøíî çàñïàâíåíû | Ïðèÿòíîé Èãðû <3")
                elseif a.action == "WATCH" then
                    sampSendChat("/re "..a.id)
                    wait(800)
                    sampSendChat("/pm "..a.id.." ß ñëåæó | Ïðèÿòíîé Èãðû <3")
                elseif a.action == "TRANSFER" then
                    sampSendChat("/a <<Ðåïîðò îò "..a.nick.."["..a.id.."]>> "..a.reportText)
                    wait(1200)  -- ?? Óâåëè÷åíà çàäåðæêà äëÿ ïðåäîòâðàùåíèÿ ôëóäà
                    sampSendChat("/pm "..a.id.." Âàø ðåïîðò óñïåøíî ïåðåäàí | Ïðèÿòíîé Èãðû <3")
                elseif a.action == "SVGROUP" then
                    sampSendChat("/pm "..a.id.." Óâàæàåìûé Èãðîê îòïðàâüòå æàëîáó â íàøó Ñâîáîäíóþ Ãðóïïó @inferno_sv")
                elseif a.action == "OFFLINE" then
                    sampAddChatMessage("{FFA500}[FastHelperAdm] Ðåïîðò çàêðûò (èãðîê îôôëàéí)", -1)
                else
                    sampSendChat("/pm "..a.id.." "..a.text)
                end
                for i = 1, #reports do
                    if reports[i].id == a.id then
                        table.remove(reports, i)
                        break
                    end
                end
                replyBuffer.v = ""
                selectedQuickAction = nil
                selectedReport = 0
            end)
        end
        
        -- Àâòî-ðàçäà÷à
        if active_razd and active_razd2 and not antiFlood then
            antiFlood = true
            active_razd = false
            active_razd2 = false
            
            -- Ïðîâåðÿåì ïîäêëþ÷åíèå èãðîêà
            if not sampIsPlayerConnected(razd_player_id) then
                sampAddChatMessage('{FF5555}[FastHelperAdm] Ïîáåäèòåëü âûøåë, ðàçäà÷à îòìåíåíà.', -1)
                resetRazdacha()
            else
                local idx = combo_priz.v + 1
                local statId = prizStatId[idx]
                local prize = u8:decode(arr_priz[idx])
                local nick = sampGetPlayerNickname(razd_player_id)
                local isStyle = (idx >= 11 and idx <= 13)
                local amount = isStyle and 50000 or (parseAmount(text_real.v) or 0)
                
                wait(FLOOD_DELAY)
                
                if statId == 7 then
                    sampSendChat('/money '..razd_player_id..' '..amount)
                else
                    sampSendChat('/setstat '..razd_player_id..' '..statId..' '..amount)
                end
                
                wait(FLOOD_DELAY)
                
                local pm = isStyle
                    and ('Ïîçäðàâëÿåì! Âû âûèãðàëè ñòèëü áîÿ "'..prize..'"')
                    or  ('Ïîçäðàâëÿåì! Âû âûèãðàëè '..prize..' '..prettySum(amount))
                    
                sampSendChat('/pm '..razd_player_id..' '..pm..' | Ïðèÿòíîé èãðû îò àäìèíà <3')
                
                wait(FLOOD_DELAY)
                
                local announce = isStyle
                    and ('WIN '..nick..'['..razd_player_id..'] ñòèëü "'..prize..'"')
                    or  ('WIN '..nick..'['..razd_player_id..'] '..prize..' '..prettySum(amount))
                
                sampSendChat('/'..arr_chat[combo_chat.v+1]..' '..announce)
                
                addGuiLog(getMSKTime()..' | '..announce)
                
                -- ?? ÏÎËÍÛÉ ÑÁÐÎÑ ÔËÀÃÎÂ ïîñëå óñïåøíîé ðàçäà÷è
                resetRazdacha()
            end
        end
    end
end

-- ===== /pl =====
function cmd_pl(param)
    local now=os.clock()
    if now-lastSendTime<cooldown then
        sampAddChatMessage("{FF0000}[FastReply] Ïîäîæäèòå íåìíîãî",-1) return
    end
    lastSendTime=now
    if not param or param=="" then
        sampAddChatMessage("{FF0000}Èñïîëüçîâàíèå: /pl [id] [êîä/òåêñò]",-1) return
    end
    local space=param:find(" ")
    local id=tonumber(space and param:sub(1,space-1) or param)
    local txt=space and param:sub(space+1) or ""
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage("{FF0000}Îøèáêà: èãðîê íå íàéäåí",-1) return
    end
    local final=fastCodes[txt] or txt or ""
    local msg=(final~="" and final.." | " or "").."Ïðèÿòíîé Èãðû îò Àäìèíèñòðàòîðà <3"
    sampSendChat("/pm "..id.." "..msg)
end

-- ===== GUI =====
function imgui.OnDrawFrame()
    -- Ïðîñòî âûçûâàåì îñíîâíóþ ôóíêöèþ îòðèñîâêè ìåíþ
    drawMainMenu()
end

-- ===== /rep CAPTOR =====
function sampev.onServerMessage(color,text)
    local nick,pid,msg=text:match('Ðåïîðò îò (.*)%[(%d+)%]: %{FFFFFF%}(.*)')
    if nick and pid and msg then
        addReport(tonumber(pid),nick,msg)
    end

    if active_razd and not active_razd2 and text_word.v ~= "" then
        local _,pid2,msg2 = text:match('Ðåïîðò îò (.*)%[(%d+)%]: %{FFFFFF%}(.*)')
        if msg2 then
            local repWord = msg2:match("^(%S+)")  -- ?? Áåðåì òîëüêî ïåðâîå ñëîâî
            if repWord == u8:decode(text_word.v) then
                razd_player_id = tonumber(pid2)
                active_razd2 = true
            end
        end
    end
end

-- ===== ÏÅÐÅÕÂÀÒ ÄÈÀËÎÃÀ /mp =====
function sampev.onShowDialog(id, style, title, button1, button2, text)
    if not title then return end

    -- Àâòî ìåðîïðèÿòèå
    if mpAutoStep == 1 and title:find(u8:decode("Ìåíþ ìåðîïðèÿòèé")) then
        lua_thread.create(function()
            wait(200)
            sampSendDialogResponse(id, 1, 0, "")
            mpAutoStep = 0
        end)
    end

    -- Àâòî îòáîð
    if otborRunning and title:find(u8:decode("Ìåíþ ìåðîïðèÿòèé")) then
        lua_thread.create(function()
            wait(200)
            sampSendDialogResponse(id, 1, 0, "")
            otborRunning = false
        end)
    end
end
