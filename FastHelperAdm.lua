-- FastHelperAdm v1.75 (ANSI, CP1251)
-- Авто-команды через 15 сек после захода + кнопка-переключатель в меню + сохранение настроек + Временное лидерство
script_name("FastHelperAdm")
script_author("waldemar03 | Alim Akimov")
script_version("1.75")

-- ===== СЕКЦИЯ АВТО-ОБНОВЛЕНИЯ =====
local CURRENT_VERSION = 1.75
local VERSION_URL = "https://raw.githubusercontent.com/TaifunTS/FastHelperAdm/refs/heads/main/version.txt"
local SCRIPT_URL  = "https://raw.githubusercontent.com/TaifunTS/FastHelperAdm/refs/heads/main/FastHelperAdm.lua"
local SCRIPT_PATH = thisScript().path

local updateChecked = false

function checkUpdate()
    if updateChecked then return end
    updateChecked = true
    
    -- Даем игре загрузиться
    wait(2000)
    
    -- Получаем директорию скрипта для сохранения временного файла
    local scriptDir = thisScript().path:match("(.+\\)")
    local tmpPath = scriptDir .. "version_tmp.txt"
    
    -- Скачиваем версию с GitHub
    downloadUrlToFile(VERSION_URL, tmpPath,
        function(id, status)
            -- Статус 58 = загрузка завершена в MoonLoader
            if status ~= 58 then 
                -- Пытаемся удалить временный файл если он есть
                if doesFileExist(tmpPath) then
                    os.remove(tmpPath)
                end
                sampAddChatMessage("{FF4444}[FastHelperAdm] Не удалось загрузить version.txt", -1)
                return 
            end
            
            -- Читаем версию из файла
            local f = io.open(tmpPath, "r")
            if not f then 
                sampAddChatMessage("{FFA500}[FastHelperAdm] Не удалось прочитать version.txt", -1)
                return 
            end
            
            local versionText = f:read("*l")
            f:close()
            
            -- Удаляем временный файл
            os.remove(tmpPath)
            
            if not versionText then 
                sampAddChatMessage("{FFA500}[FastHelperAdm] version.txt пустой", -1)
                return 
            end
            
            -- Очищаем версию от лишних символов
            versionText = versionText:gsub("%s+", ""):gsub("v", ""):gsub("V", "")
            local onlineVersion = tonumber(versionText)
            
            if not onlineVersion then 
                sampAddChatMessage("{FFA500}[FastHelperAdm] Неверный формат версии: "..versionText, -1)
                return 
            end
            
            -- Сравниваем версии
            if onlineVersion > CURRENT_VERSION then
                sampAddChatMessage(
                    "{33CCFF}[FastHelperAdm] Найдено обновление v"..onlineVersion.." (у вас v"..CURRENT_VERSION..")",
                    -1
                )
                sampAddChatMessage(
                    "{33CCFF}[FastHelperAdm] Начинаю загрузку обновления...",
                    -1
                )
                
                -- Скачиваем новый скрипт
                downloadUrlToFile(SCRIPT_URL, SCRIPT_PATH,
                    function(id2, status2)
                        if status2 ~= 58 then 
                            sampAddChatMessage("{FF0000}[FastHelperAdm] Ошибка загрузки обновления", -1)
                            return 
                        end
                        
                        sampAddChatMessage(
                            "{00FF00}[FastHelperAdm] Обновление установлено! Перезапустите игру.",
                            -1
                        )
                    end
                )
            else
                sampAddChatMessage("{00FF00}[FastHelperAdm] У вас актуальная версия v"..CURRENT_VERSION, -1)
            end
        end
    )
end
-- ===== КОНЕЦ СЕКЦИИ АВТО-ОБНОВЛЕНИЯ =====

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
    o="Ожидайте",y="Уточните",go="Уже иду",hel="Помог",sg="Свободная группа",
    non="Нет в сети",per="Передам",otk="Отказ",rp="РП путём",s="Слежу"
}

-- ===== Уровень админ прав (по умолчанию уровень 1) =====
local adminLevel = imgui.ImInt(1)

-- ===== TEMPLEADER FRACTIONS =====
local fractions = {
    {id = 1, name = "LSPD"},
    {id = 2, name = "ФБР"},
    {id = 3, name = "Army LS"},
    {id = 4, name = "Больница ЛС"},
    {id = 5, name = "LCN"},
    {id = 6, name = "Yakuza"},
    {id = 7, name = "Мэрия"},
    {id = 12, name = "Ballas"},
    {id = 13, name = "Vagos"},
    {id = 14, name = "Russia Mafia"},
    {id = 15, name = "Grove"},
    {id = 16, name = "Радиоцентр"},
    {id = 17, name = "Aztec"},
    {id = 18, name = "Rifa"},
    {id = 23, name = "Xitman"},
    {id = 25, name = "SWAT"},
    {id = 26, name = "АП"},
    {id = 27, name = "RCPD"},
    {id = 28, name = "Outlaws MC"},
    {id = 29, name = "Верховный Суд"}
}

-- ===== AUTO-COMMANDS AFTER 10 SEC IN-GAME =====
local autoEnable     = imgui.ImBool(false)   -- master switch
local autoAgm        = imgui.ImBool(true)    -- /agm
local autoChatsms    = imgui.ImBool(true)    -- /chatsms
local autoChat       = imgui.ImBool(true)    -- /chat
local autoTogphone   = imgui.ImBool(true)    -- /togphone
local autoPanelOpen  = imgui.ImBool(false)   -- панель свёрнута / развёрнута
local cmdExecuted    = false                 -- уже выполняли?
local loginTime      = 0                     -- метка захода

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
            msg = "Уважаемый Игрок отправьте жалобу в нашу Свободную Группу @inferno_sv"
        end
        sampAddChatMessage("{33CCFF}[Себе] " .. msg, -1)
        replyBuffer.v = ""
        selectedQuickAction = nil
        selectedReport = 0
        return
    end

    if not sampIsPlayerConnected(r.id) then
        sampAddChatMessage("{FF4444}[FastHelperAdm] Игрок оффлайн — /pm не отправлен", -1)
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
    u8'Уровень',u8'Законопослушность',u8'Материалы',u8'Убийства',
    u8'Номер телефона',u8'EXP',u8'Деньги в банке',
    u8'Деньги на мобиле',u8'Наличные деньги',u8'Аптечки',
    u8'Бокс',u8'Kung-Fu',u8'KickBox',u8'Наркозависимость',u8'Наркотики'
}
local prizStatId = {1,2,3,4,5,6,7,8,9,10,12,13,14,15,16}
local combo_priz = imgui.ImInt(0)
local guiLog = {}

-- ===== AUTO MP =====
local mp_names = {
    u8"Король Дигла",
    u8"Русская Рулетка",
    u8"Поливалка",
    u8"Дерби",
    u8"Снайпер",
    u8"Paint-Ball",
    u8"Бой на Катанах"
}

local combo_mp_name = imgui.ImInt(0)
local mp_custom_name = imgui.ImBuffer(64) -- ручное название

local mp_priz1 = imgui.ImInt(0)
local mp_amount1 = imgui.ImBuffer(32)

local mp_second_priz = imgui.ImBool(false)
local mp_priz2 = imgui.ImInt(0)
local mp_amount2 = imgui.ImBuffer(32)

-- авто-логика /mp
local mpAutoStep = 0

-- ===== AUTO OTBOR =====
local otbor_leader_name = imgui.ImBuffer(64)
local otbor_chat = imgui.ImInt(1) -- 0 = /aad, 1 = /o
local otborRunning = false

-- Для управления отображением полей
local otbor_selectLeader = imgui.ImInt(0)  -- 0 = вручную, 1 = из списка
local mp_selectEvent = imgui.ImInt(0)  -- 0 = вручную, 1 = из списка

-- Для выбора лидерки из списка
local otbor_leader_combo = imgui.ImInt(0)

-- Для настроек меню
local menuColor = imgui.ImInt(0) -- 0 = Красный, 1 = Зеленый, 2 = Синий, 3 = Оранжевый, 4 = Желтый, 5 = Голубой, 6 = Фиолетовый, 7 = Радужный

-- ===== НОВЫЙ: Флаг для префикса =====
local prefixSent = false

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

-- ===== СТИЛИ =====
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

-- ===== НОВЫЕ ЦВЕТА =====
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

-- ===== РАДУЖНЫЙ СТИЛЬ (динамический) =====
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

-- ===== ФУНКЦИЯ ЗАПУСКА МЕРОПРИЯТИЯ =====
function startAutoMP()
    local mpName

    -- Определяем название мероприятия
    if mp_selectEvent.v == 1 then
        -- Из списка
        mpName = u8:decode(mp_names[combo_mp_name.v + 1])
    else
        -- Вручную
        if mp_custom_name.v ~= "" then
            mpName = u8:decode(mp_custom_name.v)
        else
            sampAddChatMessage("{FF4444}[MP] Укажите название мероприятия", -1)
            return
        end
    end

    local priz1 = u8:decode(arr_priz[mp_priz1.v + 1])
    local amount1 = parseAmount(mp_amount1.v)

    if not amount1 then
        sampAddChatMessage("{FF4444}[MP] Неверное количество первого приза", -1)
        return
    end

    local prizText = priz1 .. " " .. prettySum(amount1)

    if mp_second_priz.v then
        local priz2 = u8:decode(arr_priz[mp_priz2.v + 1])
        local amount2 = parseAmount(mp_amount2.v)

        if not amount2 then
            sampAddChatMessage("{FF4444}[MP] Неверное количество второго приза", -1)
            return
        end

        prizText = prizText .. " + " .. priz2 .. " " .. prettySum(amount2)
    end

    -- Сбрасываем флаг префикса
    prefixSent = false
    
    lua_thread.create(function()
        -- Отправляем префикс только один раз
        if not prefixSent then
            sampSendChat("/a z aad")
            prefixSent = true
            wait(1000) -- КД 1 сек
        end
        
        -- Отправляем сообщения
        sampSendChat('/aad MP | Уважаемые игроки, сейчас пройдет мероприятие "'..mpName..'"')
        wait(1000)
        sampSendChat('/aad MP | Приз: '..prizText)
        wait(1000)
        sampSendChat('/aad MP | Желающие /gomp')
        wait(1000)

        mpAutoStep = 1
        sampSendChat("/mp")
    end)
end

-- ===== ФУНКЦИЯ ЗАПУСКА АВТО ОТБОРА =====
function startAutoOtbor()
    local leaderName
    
    -- Определяем название лидерки
    if otbor_selectLeader.v == 1 then
        -- Из списка
        leaderName = u8:decode(fractions[otbor_leader_combo.v + 1].name)
    else
        -- Вручную
        leaderName = u8:decode(otbor_leader_name.v)
    end

    if leaderName == "" then
        sampAddChatMessage("{FF4444}[Отбор] Укажите название лидерки", -1)
        return
    end

    -- Определяем команду чата
    local chatCmd = (otbor_chat.v == 0 and "aad" or "o")
    
    -- Сбрасываем флаг префикса
    prefixSent = false

    lua_thread.create(function()
        -- Отправляем префикс только один раз
        if not prefixSent then
            sampSendChat("/a z " .. chatCmd)
            prefixSent = true
            wait(1000) -- КД 1 сек
        end
        
        -- Отправляем сообщения
        sampSendChat('/'..chatCmd..' ОТБОР | Сейчас пройдёт отбор на лидера "'..leaderName..'"')
        wait(1000) -- КД 1 сек

        sampSendChat('/'..chatCmd..' ОТБОР | Критерий: 2+ часов на аккаунте, иметь вк')
        wait(1000) -- КД 1 сек

        sampSendChat('/'..chatCmd..' ОТБОР | Желающий /gomp')
        wait(1000) -- КД 1 сек

        otborRunning = true
        sampSendChat("/mp")
    end)
end

-- ===== MAIN =====
function main()
    -- Проверка обновлений (один раз при старте)
    checkUpdate()

    repeat wait(0) until isSampAvailable()
    sampRegisterChatCommand("plhelp",function() showMenu.v=not showMenu.v end)
    sampRegisterChatCommand("pl",cmd_pl)

    -- метка захода
    loginTime = os.clock()

    -- загружаем настройки
    loadCfg()

    -- Применяем сохраненный цвет меню
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
    sampAddChatMessage("{00FF00}FastHelperAdm загружен",-1)
    sampAddChatMessage("{00FF00}Автор: Alim Akimov (@waldemar03)",-1)
    sampAddChatMessage("{00FF00}Версия: v1.75",-1)
    sampAddChatMessage("{FF0000}========================================",-1)
    sampAddChatMessage("{ADFF2F}Для открытия меню скрипта пропишите команду /plhelp",-1)
    sampAddChatMessage("{ADFF2F}Для использования скрипта пропишите команду /pl [id]",-1)

    -- авто-сохранение при выходе
    lua_thread.create(function()
        while true do
            wait(5000) -- раз в 5 сек
            saveCfg() -- сохраняем всегда
        end
    end)

    while true do
        wait(0)
        imgui.Process=showMenu.v
        checkAutoWish()

        -- авто-команды через 15 сек после захода (один раз)
        if autoEnable.v and not cmdExecuted and os.clock() - loginTime >= 15 then
            cmdExecuted = true
            lua_thread.create(function()
                wait(1000)
                if autoAgm.v      then sampSendChat("/agm")      wait(1000) end
                if autoChatsms.v  then sampSendChat("/chatsms")  wait(1000) end
                if autoChat.v     then sampSendChat("/chat")     wait(1000) end
                if autoTogphone.v then sampSendChat("/togphone") end
                sampAddChatMessage("{33CCFF}[FastHelperAdm] Авто-команды выполнены",-1)
            end)
        end

        if pendingAction then
            local a = pendingAction
            pendingAction = nil
            lua_thread.create(function()
                if a.action == "SPAWN" then
                    sampSendChat("/sp "..a.id)
                    wait(800)
                    sampSendChat("/pm "..a.id.." Вы успешно заспавнены | Приятной Игры <3")
                elseif a.action == "WATCH" then
                    sampSendChat("/re "..a.id)
                    wait(800)
                    sampSendChat("/pm "..a.id.." Я слежу | Приятной Игры <3")
                elseif a.action == "TRANSFER" then
                    sampSendChat("/a <<Репорт от "..a.nick.."["..a.id.."]>> "..a.reportText)
                    wait(800)
                    sampSendChat("/pm "..a.id.." Ваш репорт успешно передан | Приятной Игры <3")
                elseif a.action == "SVGROUP" then
                    sampSendChat("/pm "..a.id.." Уважаемый Игрок отправьте жалобу в нашу Свободную Группу @inferno_sv")
                elseif a.action == "OFFLINE" then
                    sampAddChatMessage("{FFA500}[FastHelperAdm] Репорт закрыт (игрок оффлайн)", -1)
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
        if active_razd and active_razd2 and not antiFlood then
            antiFlood=true
            active_razd=false
            active_razd2=false
            if not sampIsPlayerConnected(razd_player_id) then
                sampAddChatMessage('{FF4444}[AutoRazdacha] Игрок вышел, раздача отменена.',-1)
                razdLocked=false; antiFlood=false; goto skip
            end
            local idx     = combo_priz.v+1
            local statId  = prizStatId[idx]
            local prize   = u8:decode(arr_priz[idx])
            local nick    = sampGetPlayerNickname(razd_player_id)
            local isStyle = (idx>=11 and idx<=13)
            local amount = isStyle and 50000 or (parseAmount(text_real.v) or 0)
            local timeStr = ''
            wait(FLOOD_DELAY)
            if statId==7 then
                sampSendChat('/money '..razd_player_id..' '..amount)
            else
                sampSendChat('/setstat '..razd_player_id..' '..statId..' '..amount)
            end
            wait(FLOOD_DELAY)
            local pm = isStyle
                and ('Поздравляем! Вы выиграли стиль боя "'..prize..'"')
                or  ('Поздравляем! Вы выиграли '..prize..' '..prettySum(amount))
            sampSendChat('/pm '..razd_player_id..' '..pm..' | Приятной игры от админа <3')
            wait(FLOOD_DELAY)
            local announce = isStyle
                and ('WIN '..nick..'['..razd_player_id..'] стиль "'..prize..'"')
                or  ('WIN '..nick..'['..razd_player_id..'] '..prize..' '..prettySum(amount))
            
            -- Отправляем с префиксом для раздачи (только один раз)
            if not prefixSent then
                local chatCmd = arr_chat[combo_chat.v + 1]
                sampSendChat("/a z " .. chatCmd)
                prefixSent = true
                wait(1000) -- КД 1 сек
            end
            
            sampSendChat('/'..arr_chat[combo_chat.v+1]..' '..announce)
            
            addGuiLog(getMSKTime()..' | '..announce)
            razdLocked=false
            antiFlood=false
        end
        ::skip::
    end
end

-- ===== /pl =====
function cmd_pl(param)
    local now=os.clock()
    if now-lastSendTime<cooldown then
        sampAddChatMessage("{FF0000}[FastReply] Подождите немного",-1) return
    end
    lastSendTime=now
    if not param or param=="" then
        sampAddChatMessage("{FF0000}Использование: /pl [id] [код/текст]",-1) return
    end
    local space=param:find(" ")
    local id=tonumber(space and param:sub(1,space-1) or param)
    local txt=space and param:sub(space+1) or ""
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage("{FF0000}Ошибка: игрок не найден",-1) return
    end
    local final=fastCodes[txt] or txt or ""
    local msg=(final~="" and final.." | " or "").."Приятной Игры от Администратора <3"
    sampSendChat("/pm "..id.." "..msg)
end

-- ===== GUI =====
function imgui.OnDrawFrame()
    if not showMenu.v then return end
    
    -- Обновляем радужный стиль если он выбран
    if menuColor.v == 7 then
        ApplyRainbowStyle()
    end
    
    -- Применяем стиль в зависимости от сохраненного цвета
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
    imgui.Begin(u8"FastHelperAdm v1.75",showMenu)
    
    imgui.Columns(2, "main_columns", false)
    imgui.SetColumnWidth(0,230)
    
    -- Заголовок над вкладками
    imgui.TextColored(imgui.ImVec4(1,0.45,0.45,1), u8"Вкладки")
    imgui.Spacing()
    
    -- ===== НОВАЯ СТРУКТУРА ВКЛАДОК =====
    -- Основные вкладки (всегда доступны)
    if imgui.Selectable(u8"Основные команды", selectedTab==1) then selectedTab=1 end
    if imgui.Selectable(u8"Настройки меню", selectedTab==2) then selectedTab=2 end
    if imgui.Selectable(u8"Ответы на Репорты", selectedTab==3) then selectedTab=3 end
    if imgui.Selectable(u8"Полезные функции", selectedTab==4) then selectedTab=4 end
    
    -- Вкладки с ограниченным доступом (только для админов уровня 9+)
    if adminLevel.v >= 9 then
        if imgui.Selectable(u8"Авто Мероприятие", selectedTab==5) then selectedTab=5 end
        if imgui.Selectable(u8"Авто Раздача", selectedTab==6) then selectedTab=6 end
        if imgui.Selectable(u8"Авто Отбор", selectedTab==7) then selectedTab=7 end
        if imgui.Selectable(u8"Временное Лидерство", selectedTab==8) then selectedTab=8 end
    else
        -- Для админов уровня 1-8 показываем заблокированные вкладки
        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8"Авто Мероприятие [уровень 9+]")
        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8"Авто Раздача [уровень 9+]")
        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8"Авто Отбор [уровень 9+]")
        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8"Временное Лидерство [уровень 9+]")
    end
    
    -- Остальные информационные вкладки
    if imgui.Selectable(u8"Обновления", selectedTab==9) then selectedTab=9 end
    if imgui.Selectable(u8"Об Авторе", selectedTab==10) then selectedTab=10 end
    
    -- переход к правой колонке
    imgui.NextColumn()
    
    -- контейнер ПРАВОЙ части
    imgui.BeginChild("##content", imgui.ImVec2(0, -40), true)

    -- Содержимое вкладок
    if selectedTab==1 then
        imgui.TextWrapped(u8"Основные команды:\n/plhelp – открыть меню\n/pl [id] [код/текст]")
        imgui.Separator()
        imgui.TextWrapped(u8"Быстрые коды:\no – Ожидайте\ny – Уточните\ngo – Уже иду\nhel – Помог\nsg – Свободная группа\nnon – Нет в сети\nper – Передам\notk – Отказ\nrp – РП путём\ns – Слежу")
        imgui.Separator()
        imgui.TextWrapped(u8"Примеры:\n/pl 15 o\n/pl 15 Привет")
    elseif selectedTab == 2 then
        imgui.Text(u8"Настройки Меню")
        imgui.Separator()

        -- Настройки цвета
        imgui.Text(u8"Цвет меню")
        local colorChoices = {
            u8"Красный", 
            u8"Зеленый", 
            u8"Синий", 
            u8"Оранжевый", 
            u8"Желтый", 
            u8"Голубой", 
            u8"Фиолетовый",
            u8"Радужный"
        }
        imgui.Combo(u8"Выберите цвет", menuColor, colorChoices, #colorChoices)

        if menuColor.v == 7 then
            imgui.TextColored(imgui.ImVec4(1,0,1,1), u8"? Радужный режим активен")
        end

        if imgui.Button(u8"Применить цвет") then
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
            styleApplied = false -- Сбрасываем флаг для применения стиля в следующем кадре
        end

        imgui.Separator()

        -- Настройка уровня админ прав
        imgui.Text(u8"Уровень админ прав")
        imgui.SliderInt(u8"Выберите уровень", adminLevel, 1, 14)

        imgui.Spacing()
        if adminLevel.v >= 9 then
            imgui.TextColored(imgui.ImVec4(0,1,0,1), u8"? Доступ ко всем вкладкам доступен")
        else
            imgui.TextColored(imgui.ImVec4(1,0.5,0,1), u8"? Доступ ограничен. Уровни 1-8 не могут использовать:")
            imgui.Text(u8"• Авто-Мероприятие")
            imgui.Text(u8"• Авто-Раздачу") 
            imgui.Text(u8"• Авто-Отбор")
            imgui.Text(u8"• Временное лидерство")
        end

        imgui.Separator()
        if imgui.Button(u8"Сохранить настройки") then
            saveCfg()
            sampAddChatMessage("{33CCFF}[FastHelperAdm] Настройки сохранены", -1)
        end
    elseif selectedTab==3 then
        imgui.Text(u8"Активные репорты:")
        imgui.BeginChild("repList", imgui.ImVec2(0,150), true)
        for i, r in ipairs(reports) do
            local line = string.format("[%d] %s: %s", r.id, r.nick, r.text)
            if imgui.Selectable(u8(line), selectedReport == i) then
                selectedReport = i
            end
        end
        imgui.EndChild()
        
        if imgui.Button(u8"Очистить все") then
            reports = {}
            selectedReport = 0
            replyBuffer.v = ""
            selectedQuickAction = nil
        end
        
        imgui.Spacing()
        imgui.Separator()
        
        if selectedReport > 0 and selectedReport <= #reports then
            local r = reports[selectedReport]
            imgui.Text(u8"Ответ для "..r.nick.."["..r.id.."]:")
            imgui.InputTextMultiline("##reply_text", replyBuffer, imgui.ImVec2(-1, 60))
            imgui.Separator()
            imgui.Text(u8"Быстрые действия:")

            if imgui.Button(u8"Приятной игры") then
                selectedQuickAction = nil
                replyBuffer.v = u8:encode("Приятной Игры от Администратора <3")
            end
            imgui.SameLine()
            if imgui.Button(u8"Уточнить") then
                selectedQuickAction = nil
                replyBuffer.v = u8:encode("Уточните ситуацию подробнее | Приятной Игры <3")
            end
            imgui.SameLine()
            if imgui.Button(u8"Спавн") then
                selectedQuickAction = "SPAWN"
                replyBuffer.v = u8:encode("Вы успешно заспавнены | Приятной Игры <3")
            end
            imgui.SameLine()
            if imgui.Button(u8"Слежка") then
                selectedQuickAction = "WATCH"
                replyBuffer.v = u8:encode("Я слежу | Приятной Игры <3")
            end

            if imgui.Button(u8"Передать") then
                selectedQuickAction = "TRANSFER"
                replyBuffer.v = u8:encode("Ваш репорт успешно передан | Приятной Игры <3")
            end
            imgui.SameLine()
            if imgui.Button(u8"Не ко мне") then
                selectedQuickAction = nil
                replyBuffer.v = u8:encode("Данный вопрос не относится к администрации | Приятной Игры <3")
            end
            imgui.SameLine()
            if imgui.Button(u8"Не в сети") then
                selectedQuickAction = "OFFLINE"
                replyBuffer.v = u8:encode("Указанный игрок не в сети | Приятной Игры <3")
            end

            if imgui.Button(u8"Свободная Группа") then
                selectedQuickAction = "SVGROUP"
                replyBuffer.v = u8:encode("Уважаемый Игрок отправьте жалобу в нашу Свободную Группу @inferno_sv")
            end

            if imgui.Button(u8"Отправить") then
                doAction(r)
            end
            imgui.SameLine()
            if imgui.Button(u8"Закрыть репорт") then
                table.remove(reports,selectedReport)
                selectedReport=0
                replyBuffer.v=""
                selectedQuickAction=nil
            end
        else
            imgui.Text(u8"Выберите репорт из списка")
        end
    elseif selectedTab==4 then
        imgui.TextWrapped(u8"Полезные функции:")

        if imgui.Button(u8"Авто включение") then
            autoPanelOpen.v = not autoPanelOpen.v
        end
        if autoPanelOpen.v then
            imgui.Indent(15)
            imgui.Checkbox(u8"Включить авто-выполнение", autoEnable)
            if autoEnable.v then
                imgui.Checkbox(u8"/agm",      autoAgm)
                imgui.Checkbox(u8"/chatsms",  autoChatsms)
                imgui.Checkbox(u8"/chat",     autoChat)
                imgui.Checkbox(u8"/togphone", autoTogphone)
            end
            imgui.Unindent(15)
        end

        imgui.Checkbox(u8"Авто Пожелание",autoWishEnabled)
        imgui.SameLine()
        if imgui.Button(u8" ? ") then end
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Каждый час в Pay-Day отправляется /gg в чат")
        end
    elseif selectedTab==5 then
        -- Проверка доступа к вкладке Авто Мероприятие
        if adminLevel.v >= 9 then
            imgui.Text(u8"Авто Мероприятие")
            imgui.Separator()

            -- Выбор: вручную или из списка
            imgui.Combo(u8"Выбор мероприятия", mp_selectEvent, {u8"Вручную", u8"Из списка"}, 2)

            -- Если выбрано из списка, показываем только его
            if mp_selectEvent.v == 1 then
                imgui.Combo(u8"Мероприятие", combo_mp_name, mp_names, #mp_names)
            else
                -- Если вручную, показываем поле для ввода
                imgui.InputText(u8"Название мероприятия", mp_custom_name)
            end

            imgui.Separator()
            imgui.Text(u8"Приз 1")
            imgui.Combo(u8"Приз##1", mp_priz1, arr_priz, #arr_priz)
            imgui.InputText(u8"Количество##1", mp_amount1)

            imgui.Separator()
            imgui.Checkbox(u8"Добавить второй приз", mp_second_priz)

            if mp_second_priz.v then
                imgui.Text(u8"Приз 2")
                imgui.Combo(u8"Приз##2", mp_priz2, arr_priz, #arr_priz)
                imgui.InputText(u8"Количество##2", mp_amount2)
            end

            imgui.Separator()
            if imgui.Button(u8"Начать мероприятие", imgui.ImVec2(260, 32)) then
                startAutoMP()
            end
        else
            imgui.TextColored(imgui.ImVec4(1,0,0,1), u8"Доступ запрещен!")
            imgui.Text(u8"Для доступа к этой функции требуется уровень админ-прав 9 или выше.")
        end
    elseif selectedTab==6 then
        -- Проверка доступа к вкладке Авто Раздача
        if adminLevel.v >= 9 then
            imgui.Combo(u8"Чат",combo_chat,arr_chat,#arr_chat)
            imgui.InputText(u8"Слово для /rep",text_word)
            imgui.Combo(u8"Приз",combo_priz,arr_priz,#arr_priz)
            
            local isStyle=(combo_priz.v+1>=11 and combo_priz.v+1<=13)
            local amount = isStyle and 50000 or (parseAmount(text_real.v) or 0)
            
            if not isStyle then
                imgui.InputText(u8"Количество",text_real)
                if amount > 0 then
                    imgui.Text(u8"В чате: "..prettySum(amount))
                else
                    imgui.TextColored(imgui.ImVec4(1,0.3,0.3,1),u8"Пример: 5k / 5kk / 5kkk")
                end
            else
                imgui.TextDisabled(u8"Будет выдан стиль боя")
            end
            
            if imgui.Button(u8"Начать раздачу") and text_word.v~='' and not razdLocked then
                razdLocked=true
                active_razd=true
                active_razd2=false
                timer=os.clock()
                local pName=u8:decode(arr_priz[combo_priz.v+1])
                local txt
                
                if isStyle then
                    txt = "РАЗДАЧА | Кто первый напишет /rep "..u8:decode(text_word.v).." — стиль \""..pName.."\""
                else
                    txt = "РАЗДАЧА | Кто первый напишет /rep "..u8:decode(text_word.v).." — "..pName.." "..prettySum(amount)
                end
                
                -- Отправляем префикс только один раз
                prefixSent = false
                if not prefixSent then
                    local chatCmd = arr_chat[combo_chat.v + 1]
                    sampSendChat("/a z " .. chatCmd)
                    prefixSent = true
                    wait(1000) -- КД 1 сек
                end
                
                sampSendChat('/'..arr_chat[combo_chat.v+1]..' '..txt)
            end
            
            imgui.Separator()
            imgui.Text(u8"Последние раздачи:")
            imgui.BeginChild('log',imgui.ImVec2(0,110),true)
            for _,v in ipairs(guiLog) do imgui.Text(v) end
            imgui.EndChild()
        else
            imgui.TextColored(imgui.ImVec4(1,0,0,1), u8"Доступ запрещен!")
            imgui.Text(u8"Для доступа к этой функции требуется уровень админ-прав 9 или выше.")
        end
    elseif selectedTab == 7 then
        -- Проверка доступа к вкладке Авто Отбор
        if adminLevel.v >= 9 then
            imgui.Text(u8"Авто Отбор на Лидера")
            imgui.Separator()

            -- Выбор: вручную или из списка
            imgui.Combo(u8"Выбор лидерки", otbor_selectLeader, {u8"Вручную", u8"Из списка"}, 2)

            -- Если выбрано из списка, показываем только его
            if otbor_selectLeader.v == 1 then
                -- Создаем массив только с именами фракций для выпадающего списка
                local fractionNames = {}
                for i, frac in ipairs(fractions) do
                    fractionNames[i] = u8(frac.name)
                end
                imgui.Combo(u8"Лидерка", otbor_leader_combo, fractionNames, #fractions)
            else
                -- Если вручную, показываем поле для ввода
                imgui.InputText(u8"Название лидерки", otbor_leader_name)
            end

            -- Выбор чата
            imgui.Combo(u8"Чат", otbor_chat, {u8"/aad", u8"/o"}, 2)

            imgui.Separator()
            if imgui.Button(u8"Начать Отбор", imgui.ImVec2(260, 32)) then
                startAutoOtbor()
            end
        else
            imgui.TextColored(imgui.ImVec4(1,0,0,1), u8"Доступ запрещен!")
            imgui.Text(u8"Для доступа к этой функции требуется уровень админ-прав 9 или выше.")
        end
    elseif selectedTab==8 then
        -- Проверка доступа к вкладке Временное Лидерство
        if adminLevel.v >= 9 then
            imgui.TextWrapped(u8"Временное Лидерство")
            imgui.TextWrapped(u8"Нажмите на кнопку с названием фракции\nчтобы выдать себе временное лидерство")
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
            imgui.TextColored(imgui.ImVec4(1,0,0,1), u8"Доступ запрещен!")
            imgui.Text(u8"Для доступа к этой функции требуется уровень админ-прав 9 или выше.")
        end
    elseif selectedTab == 9 then
        imgui.TextWrapped(u8(
            "v1.0 — Релиз\n" ..
            "v1.2 — Фикс багов\n" ..
            "v1.4 — Улучшения\n" ..
            "v1.5 — Авто Раздача\n" ..
            "v1.55 — Фикс багов 2\n" ..
            "v1.60 — Авто Пожелание + Ответы на Репорты + Авто-команды через 10 сек\n" ..
            "v1.70 — Добавлена выдача себе лидерки + Добавлено авто мероприятие + Фикс неких багов\n" ..
            "v1.75 — Добавлен Авто Отбор и добавлен визуал для меню"
        ))
    elseif selectedTab==10 then
        imgui.TextWrapped(u8"FastHelperAdm v1.75\nАвтор: Alim Akimov\n@waldemar03")
    end

    -- закрываем контейнер правой части
    imgui.EndChild()
    
    -- сброс колонок
    imgui.Columns(1)
    
    imgui.Separator()
    if imgui.Button(u8"Закрыть") then showMenu.v=false; saveCfg() end
    imgui.End()
end

-- ===== /rep CAPTOR =====
function sampev.onServerMessage(color,text)
    local nick,pid,msg=text:match('Репорт от (.*)%[(%d+)%]: %{FFFFFF%}(.*)')
    if nick and pid and msg then
        addReport(tonumber(pid),nick,msg)
    end

    if active_razd and not active_razd2 then
        local _,pid2,msg2=text:match('Репорт от (.*)%[(%d+)%]: %{FFFFFF%}(.*)')
        if msg2 and msg2:find(u8:decode(text_word.v)) then
            razd_player_id=tonumber(pid2)
            active_razd2=true
            timerr=os.clock()
        end
    end
end

-- ===== ПЕРЕХВАТ ДИАЛОГА /mp =====
function sampev.onShowDialog(id, style, title, button1, button2, text)
    if not title then return end

    -- Авто мероприятие
    if mpAutoStep == 1 and title:find(u8:decode("Меню мероприятий")) then
        lua_thread.create(function()
            wait(200)
            sampSendDialogResponse(id, 1, 0, "")
            mpAutoStep = 0
        end)
    end

    -- Авто отбор
    if otborRunning and title:find(u8:decode("Меню мероприятий")) then
        lua_thread.create(function()
            wait(200)
            sampSendDialogResponse(id, 1, 0, "")
            otborRunning = false
        end)
    end
end