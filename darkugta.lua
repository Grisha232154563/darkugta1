loadstring(exports.interfacer:extend("Interfacer"))()
Extend("CPlayer")
Extend("ib")
Extend("CUI")
Extend("CInterior")
Extend("CQuest")

-- ==================================================
-- Галочка 21 — CHF повний цикл (Add → Make → wait 8 хв → Take)
-- ==================================================

local chf21Active = false

local chf21_addTimer  = nil
local chf21_makeTimer = nil
local chf21_waitTimer = nil
local chf21_takeTimer = nil

local function chf21_stopAll()
    if chf21_addTimer  and isTimer(chf21_addTimer)  then killTimer(chf21_addTimer)  end
    if chf21_makeTimer and isTimer(chf21_makeTimer) then killTimer(chf21_makeTimer) end
    if chf21_waitTimer and isTimer(chf21_waitTimer) then killTimer(chf21_waitTimer) end
    if chf21_takeTimer and isTimer(chf21_takeTimer) then killTimer(chf21_takeTimer) end

    chf21_addTimer, chf21_makeTimer, chf21_waitTimer, chf21_takeTimer = nil, nil, nil, nil
    chf21Active = false
end

---------------------------------------------------------
-- ФАЗА 3 — TakeProduct (i 1..20, j 1..60)
---------------------------------------------------------
local function chf21_startTakePhase()
    if not chf21Active then return end

    local i = 1 -- 1..20
    local j = 1 -- 1..60

    chf21_takeTimer = setTimer(function()
        if not chf21Active then
            if chf21_takeTimer and isTimer(chf21_takeTimer) then killTimer(chf21_takeTimer) end
            chf21_takeTimer = nil
            return
        end

        triggerServerEvent("CAF:onPlayerWantTakeAlco", root, i, j)

        j = j + 1
        if j > 60 then
            j = 1
            i = i + 1

            if i > 20 then
                if chf21_takeTimer and isTimer(chf21_takeTimer) then killTimer(chf21_takeTimer) end
                chf21_takeTimer = nil
                chf21Active = false
                StatesGalochka21 = false
                triggerEvent("ShowSuccess", root, "Переробка алко завершина✅")
            end
        end
    end, 30, 0)
end

---------------------------------------------------------
-- ПАУЗА 8 ХВ → запуск Take
---------------------------------------------------------
local function chf21_startWaitBeforeTake()
    if not chf21Active then return end

    chf21_waitTimer = setTimer(function()
        chf21_waitTimer = nil
        if chf21Active then
            triggerEvent("ShowSuccess", root, "Паузу завершено → починаємо взяття алко")
            chf21_startTakePhase()
        end
    end, 9 * 60 * 1000, 1) -- ✅ реально 8 хв
end

---------------------------------------------------------
-- ФАЗА 2 — StartMakingProduct (id 1..60)
---------------------------------------------------------
local function chf21_startMakePhase()
    if not chf21Active then return end

    local id = 1

    chf21_makeTimer = setTimer(function()
        if not chf21Active then
            if chf21_makeTimer and isTimer(chf21_makeTimer) then killTimer(chf21_makeTimer) end
            chf21_makeTimer = nil
            return
        end

        triggerServerEvent("CAF:onPlayerWantStartMakingAlco", root, id)

        id = id + 1
        if id > 60 then
            if chf21_makeTimer and isTimer(chf21_makeTimer) then killTimer(chf21_makeTimer) end
            chf21_makeTimer = nil

            triggerEvent("ShowSuccess", root, "Стартуємо паузу 9 хв перед взяттям алко")
            chf21_startWaitBeforeTake()
        end
    end, 30, 0)
end

---------------------------------------------------------
-- ФАЗА 1 — AddRawMaterial (id 1..20 × amount 1..60)
---------------------------------------------------------
local function chf21_startAddPhase()
    if not chf21Active then return end

    local id = 1        -- 1..20
    local amount = 1    -- 1..60

    chf21_addTimer = setTimer(function()
        if not chf21Active then
            if chf21_addTimer and isTimer(chf21_addTimer) then killTimer(chf21_addTimer) end
            chf21_addTimer = nil
            return
        end

        triggerServerEvent("CAF:onPlayerWantAddBottle", root, id, amount)

        id = id + 1
        if id > 20 then
            id = 1
            amount = amount + 1

            if amount > 60 then
                if chf21_addTimer and isTimer(chf21_addTimer) then killTimer(chf21_addTimer) end
                chf21_addTimer = nil

                triggerEvent("ShowSuccess", root, "Додовання алко завершено → переходимо до приготування")
                chf21_startMakePhase()
            end
        end
    end, 30, 0)
end

---------------------------------------------------------
-- Toggle через галочку 21
---------------------------------------------------------
addEvent("ToggleCHF21", true)
addEventHandler("ToggleCHF21", root, function()
    if StatesGalochka21 then
        -- ON
        chf21_stopAll()
        chf21Active = true
        triggerEvent("ShowSuccess", root, "Старт переробки алко🚀")
        chf21_startAddPhase()
    else
        -- OFF
        chf21_stopAll()
        triggerEvent("ShowError", root, "Стоп переробки алко🛑")
    end
end)


-- ==================================================
-- Галочка 20 — CAF спамер (CAF:onPlayerWashBottle)
-- ==================================================
local cafSpamTimer = nil
local cafSpamLeft  = 0
local cafSpamDelay = 50 -- мс між івентами

local function cafSpamStop()
    if cafSpamTimer and isTimer(cafSpamTimer) then
        killTimer(cafSpamTimer)
    end
    cafSpamTimer = nil
end

local function cafSpamStart(count)
    cafSpamStop()
    cafSpamLeft = count

    cafSpamTimer = setTimer(function()
        if cafSpamLeft <= 0 then
            cafSpamStop()
            StatesGalochka20 = false
            triggerEvent("ShowSuccess", root, "Миття бутилок: завершено")
            return
        end

        triggerServerEvent("CAF:onPlayerWashBottle", root)
        cafSpamLeft = cafSpamLeft - 1
    end, cafSpamDelay, 0)
end

addEvent("ToggleCAFSpam20", true)
addEventHandler("ToggleCAFSpam20", root, function()
    if not StatesGalochka20 then
        cafSpamStop()
        triggerEvent("ShowError", root, "Миття бутилок OFF")
        return
    end

    -- ===== ЧИТАЄМО АРГУМЕНТ 1 =====
    local raw = tostring(argument1 or ""):gsub("%s+", "")
    local count = tonumber(raw)

    if not count or count <= 0 then
        StatesGalochka20 = false
        triggerEvent("ShowError", root, "❌ Вкажи в Аргумент 1 кількість повторів")
        return
    end

    cafSpamStart(count)
    triggerEvent("ShowSuccess", root, "Миття бутилок ON | Кількість: "..count)
end)

-- ==================================================

-- ==================================================
-- Галочка 19 — SAFE TP + ALT НА КОЖНІЙ МІТЦІ (trigger)
-- ==================================================

local safetp19_points = {
    {2111.0449, 2379.2390, 21.4582, 0, 0},
    {2113.4231, 2379.2385, 21.4582, 0, 0},
    {2133.7043, 2431.0759, 21.4582, 0, 0},
    {2133.5754, 2433.4387, 21.4582, 0, 0},
    {2133.3467, 2434.7300, 21.4582, 0, 0},

    {2114.6260, 2584.4707, 21.4582, 0, 0},
    {2114.2327, 2585.9888, 21.4582, 0, 0},
    {2114.2131, 2588.6482, 21.4582, 0, 0},

    {2282.2090, 2635.3037, 21.4848, 0, 0},
    {2280.0864, 2635.1150, 21.4848, 0, 0},
    {2277.8806, 2634.8894, 21.4848, 0, 0},
    {2273.6465, 2637.4558, 21.4848, 0, 0},
    {2273.5078, 2639.1169, 21.4848, 0, 0},
    {2273.2556, 2641.4829, 21.4848, 0, 0},

    {2314.6594, 2227.6404, 21.5761, 0, 0},
    {2314.4927, 2229.5881, 21.5761, 0, 0},
    {2314.2432, 2231.3223, 21.5761, 0, 0},
    {2318.7290, 2224.9653, 21.5761, 0, 0},
    {2321.0193, 2225.1577, 21.5761, 0, 0},
    {2323.0474, 2225.3430, 21.5761, 0, 0},

    {491.2997, 2163.6438, 21.6005, 0, 0},
    {493.2604, 2163.6462, 21.6005, 0, 0},
    {388.4404, 2163.9622, 21.6005, 0, 0},
    {386.5208, 2163.8953, 21.6005, 0, 0},
    {384.4963, 2163.8936, 21.6005, 0, 0},

    {266.7990, 2208.7996, 21.6005, 0, 0},
    {266.8107, 2211.1772, 21.6005, 0, 0},
    {266.8103, 2213.0601, 21.6005, 0, 0},

    {267.8314, 2456.6257, 17.9414, 0, 0},
    {267.8530, 2458.8293, 17.9414, 0, 0},
    {267.8455, 2461.0063, 17.9414, 0, 0},

    {334.6548, 2491.6968, 17.8900, 0, 0},
    {334.5999, 2493.5906, 17.8900, 0, 0},
    {334.5179, 2495.5464, 17.8900, 0, 0},

    {334.7334, 2628.8110, 17.9366, 0, 0},
    {334.7356, 2626.8806, 17.9366, 0, 0},
    {334.8300, 2625.0647, 17.9366, 0, 0},

    {270.7393, 2660.8591, 17.9414, 0, 0},
    {270.7648, 2663.1077, 17.9414, 0, 0},
    {270.7650, 2665.3105, 17.9414, 0, 0},

    {220.3906, 2721.0825, 17.9673, 0, 0},
    {222.5875, 2721.0798, 17.9673, 0, 0},
    {223.9011, 2721.2263, 17.9673, 0, 0},

    {118.3326, 2629.4827, 17.9414, 0, 0},
    {118.6206, 2631.6895, 17.9414, 0, 0},
    {118.6207, 2633.9932, 17.9414, 0, 0},

    {118.5933, 2548.8271, 17.9414, 0, 0},
    {118.6206, 2546.7959, 17.9414, 0, 0},
    {118.6296, 2544.6594, 17.9414, 0, 0},
}

local safetp19_delay_ms = 7000
local safetp19_index = 1
local safetp19_timer = nil

local function safetp19_pressALT()
    pcall(function()
        getPedVoice("emulateKey LALT true true")
    end)
    setTimer(function()
        pcall(function()
            getPedVoice("emulateKey LALT false false")
        end)
    end, 80, 1)
end

local function safetp19_stop()
    if safetp19_timer and isTimer(safetp19_timer) then
        killTimer(safetp19_timer)
    end
    safetp19_timer = nil
end

local function safetp19_start()
    if safetp19_timer and isTimer(safetp19_timer) then return end

    safetp19_timer = setTimer(function()
        local p = safetp19_points[safetp19_index]
        if not p then
            safetp19_stop()
            StatesGalochka19 = false
            triggerEvent("ShowSuccess", root, "Бот алко: Круг завершено")
            return
        end

        -- SafeTP (твоя кастомна серверна функція)
        SafeTP(p[1], p[2], p[3], p[4], p[5])

        -- ALT після TP
        setTimer(safetp19_pressALT, 150, 1)

        safetp19_index = safetp19_index + 1
    end, safetp19_delay_ms, 0)
end

addEvent("ToggleSafeTPAlt19", true)
addEventHandler("ToggleSafeTPAlt19", root, function()
    if StatesGalochka19 then
        safetp19_index = 1
        safetp19_start()
        triggerEvent("ShowSuccess", root, "Бот алко: ON")
    else
        safetp19_stop()
        triggerEvent("ShowError", root, "Бот алко: OFF")
    end
end)


-- =================================================
-- GALОЧКА 4 — Skill Bot (LMB авто-клік через trigger)
-- =================================================

clickTimer4 = nil

local function doOneClick4()
    -- гарантія відпуску
    pcall(function()
        getPedVoice("emulateKey LMB false false")
    end)

    -- натиснути
    pcall(function()
        getPedVoice("emulateKey LMB true true")
    end)

    -- відпустити через 40 мс
    setTimer(function()
        pcall(function()
            getPedVoice("emulateKey LMB false false")
        end)
    end, 40, 1)
end

local function stopSkillBot4()
    if clickTimer4 and isTimer(clickTimer4) then
        killTimer(clickTimer4)
    end
    clickTimer4 = nil

    pcall(function()
        getPedVoice("emulateKey LMB false false")
    end)
end

addEvent("ToggleSkillBot", true)
addEventHandler("ToggleSkillBot", root, function()
    -- UI вже перемкнув галочку → читаємо стан
    if StatesGalochka4 then
        -- ON
        stopSkillBot4()         -- захист від дубля таймера
        doOneClick4()           -- одразу 1 клік
        clickTimer4 = setTimer(doOneClick4, 16500, 0)

        triggerEvent("ShowSuccess", root, "Скіл-бот ON")
    else
        -- OFF
        stopSkillBot4()
        triggerEvent("ShowError", root, "Скіл-бот OFF")
    end
end)
-- =================================================

-- Спрей-спам 1 (старий, графіті, галочка 17)
graffitiEnabled = graffitiEnabled or false
graffitiTimer = graffitiTimer or nil
graffitiID = graffitiID or 1

function startGraffitiSpam()
    if graffitiTimer and isTimer(graffitiTimer) then return end

    graffitiTimer = setTimer(function()
        if graffitiEnabled then
            triggerServerEvent("onClanTagSprayRequest", localPlayer, graffitiID)

            graffitiID = graffitiID + 1

            if graffitiID > 100 then
                graffitiEnabled = false
                StatesGalochka17 = false
                triggerEvent("ShowSuccess", root, "Йома-йо ти сам попробуй покрасити всі графіті а не користуйся ботом")
                stopGraffitiSpam()
            end
        end
    end, 100, 0)
end

function stopGraffitiSpam()
    if graffitiTimer and isTimer(graffitiTimer) then
        killTimer(graffitiTimer)
    end
    graffitiTimer = nil
    graffitiID = 1
end


-- Спрей-спам 2 (новий, клан-пакети, галочка 18)
clanPackageEnabled = clanPackageEnabled or false
clanPackageTimer = clanPackageTimer or nil
clanPackageID = clanPackageID or 1

function startClanPackageSpam()
    if clanPackageTimer and isTimer(clanPackageTimer) then return end

    clanPackageTimer = setTimer(function()
        if clanPackageEnabled then
            triggerServerEvent("onServerPlayerTakeClanPackage", localPlayer, clanPackageID)

            clanPackageID = clanPackageID + 1

            if clanPackageID > 400 then
                clanPackageEnabled = false
                StatesGalochka18 = false
                triggerEvent("ShowSuccess", root, "Фухх було тяжко но всьотаки назбирав!")
                stopClanPackageSpam()
            end
        end
    end, 50, 0)
end

function stopClanPackageSpam()
    if clanPackageTimer and isTimer(clanPackageTimer) then
        killTimer(clanPackageTimer)
    end
    clanPackageTimer = nil
    clanPackageID = 1
end

addEvent("ToggleGraffitiSpam", true)
addEventHandler("ToggleGraffitiSpam", root, function()
    -- UI вже перемкнув StatesGalochka17, просто синхронізуємось з ним
    graffitiEnabled = StatesGalochka17

    if graffitiEnabled then
        triggerEvent("ShowSuccess", root, "Братан йду малювати графіті!")
        startGraffitiSpam()
    else
        triggerEvent("ShowError", root, "Братан я закінчив малювати!")
        stopGraffitiSpam()
    end
end)

addEvent("ToggleClanPackageSpam", true)
addEventHandler("ToggleClanPackageSpam", root, function()
    clanPackageEnabled = StatesGalochka18

    if clanPackageEnabled then
        triggerEvent("ShowSuccess", root, "Йду назбираю тобі закладок!")
        startClanPackageSpam()
    else
        triggerEvent("ShowError", root, "Назбирав тобі тут закладок чучуть!")
        stopClanPackageSpam()
    end
end)


---охота корди пед---
cordsanimal = { x = 0, y = 0, z = 0 }
CarGM = false
-- Взрыв кулак --
-- переменная включения режима
local fireshot = false

-- функция переключения
function toggleFireShot()
    fireshot = not fireshot
    triggerEvent("TogglePedGM", root)
    --outputChatBox("FireShot: " .. (fireshot and "ВКЛ" or "ВЫКЛ"), 0, 255, 0)
end

function runEventsSequence()
    
    triggerServerEvent("Server:ApplyRadial", root, "vehicle", 18)
  --  outputChatBox("[DEBUG] Event 1 sent")

    
    setTimer(function()
        triggerServerEvent("player_hack_game_end", root, true)
     --   outputChatBox("[DEBUG] Event 2 sent")
    end, 1000, 1)
end

-- ТП на 1147.5339, -2078.5676, 87.3058 по F7
local TP_X, TP_Y, TP_Z = 1147.53393554687500, -2078.56762695312500, 87.30582427978516

function TpToCustomCoords()  -- без local і з таким самим іменем, як у помилці
    local player = localPlayer
    local veh = getPedOccupiedVehicle(player)

    if veh then
        -- Якщо сидиш в машині – тпхає машину
        setElementPosition(veh, TP_X, TP_Y, TP_Z)
        setElementVelocity(veh, 0, 0, 0)
    else
        -- Якщо пішки – тпхає гравця
        setElementPosition(player, TP_X, TP_Y, TP_Z)
        setElementVelocity(player, 0, 0, 0)
    end
end



-- функция локального визуального взрыва
function spawnLocalExplosion(offsetX, offsetY, offsetZ, explType)
    offsetX = offsetX or 2
    offsetY = offsetY or 0
    offsetZ = offsetZ or 0.5
    explType = explType or 0

    local px, py, pz = getElementPosition(localPlayer)
    if not px then return end

    local ex, ey, ez = px + offsetX, py + offsetY, pz + offsetZ
    createExplosion(ex, ey, ez, explType)

    -- обнуляем вертикальную скорость, чтобы не отбрасывало
    local vx, vy, vz = getElementVelocity(localPlayer)
    setElementVelocity(localPlayer, vx, vy, 0)
end

-- ЛКМ спавнит взрыв только если fireshot = true
bindKey("mouse1", "down",
    function()
        if fireshot then
            spawnLocalExplosion(2, 0, 0.5, 0)
        end
    end
)

-- блокировка урона от этих взрывов
addEventHandler("onClientPlayerDamage", localPlayer,
    function(attacker, weapon, bodypart, loss)
        if weapon >= 17 and weapon <= 21 then
            cancelEvent()
        end
    end
)

-- Admin detector --

local checkInterval = 3000 -- каждые 3 секунды
local radius = 50
local nearbyAdmins = {}
admindetector = true -- управляющая переменная

local function updateNearbyAdmins()
    if not admindetector then
        nearbyAdmins = {}
        return
    end

    nearbyAdmins = {}
    local localPlayer = getLocalPlayer()
    local lx, ly, lz = getElementPosition(localPlayer)
    local lDim = getElementDimension(localPlayer)

    for _, player in ipairs(getElementsByType("player")) do
        if player ~= localPlayer then
            local isAdmin = getElementData(player, "is_admin")
            if isAdmin then
                local px, py, pz = getElementPosition(player)
                local pDim = getElementDimension(player)
                local distance = getDistanceBetweenPoints3D(lx, ly, lz, px, py, pz)

                if pDim == lDim and distance <= radius then
                    table.insert(nearbyAdmins, getPlayerNametagText(player))
                end
            end
        end
    end
end

-- Таймер обновления
setTimer(updateNearbyAdmins, checkInterval, 0)

-- Отрисовка текста по центру экрана
addEventHandler("onClientRender", root, function()
    if admindetector and #nearbyAdmins > 0 then
        local screenW, screenH = guiGetScreenSize()
        local text = "Админ рядом: " .. table.concat(nearbyAdmins, ", ")
        dxDrawText(
            text,
            0, screenH*0.4, screenW, screenH*0.4,
            tocolor(255,0,0,255),
            2, "default-bold", "center", "center",
            false, false, true, true, false
        )
    end
end)

function toggleExtraGalochka()
    admindetector = not admindetector
    --outputChatBox("extraGalochkaCodes12: " .. tostring(extraGalochkaCodes12))
end
--- Jump --
-- суперпрыжок с переменной HighJump
local HighJump = false
local jumpKey = "lshift"

-- функция переключения
function toggleHighJump()
    HighJump = not HighJump
    --outputChatBox("HighJump: " .. (HighJump and "ВКЛ" or "ВЫКЛ"), 0, 255, 0)
end

-- прыжок
addEventHandler("onClientRender", root,
    function()
        if HighJump and getKeyState(jumpKey) then
            local vx, vy, vz = getElementVelocity(localPlayer)
            setElementVelocity(localPlayer, vx, vy, 1.5)
        end
    end
)

-- убрать урон от падения
addEventHandler("onClientPlayerDamage", localPlayer,
    function(attacker, weapon, bodypart, loss)
        if HighJump and weapon == 54 then
            cancelEvent()
        end
    end
)

---tp---
function SafeTP(bx, by, bz, dim, int)
    local resname = getResourceFromName('ugta_casino_entrance') 
    local resourceRoot = getResourceRootElement(resname) 
    triggerServerEvent( "RequestTeleport", resourceRoot, bx, by, bz, tonumber(dim), tonumber(int))
    triggerServerEvent("SwitchPosition", resourceRoot)
    setElementInterior(localPlayer, tonumber(int))
end

function ToggleCarGM()
    CarGM = not CarGM
end

function ToggleAntiShtraf()
    anti_shtraf = not anti_shtraf
end

function ToggleAntiProbeg()
    anti_probeg = not anti_probeg
end

local function playNotificationSound()
    local sound = playSound("hellobyrage.mp3", false) -- false = не зацикливать
    if not sound then
        --outputChatBox("✖ Не удалось загрузить hellobyrage.mp3 (проверьте наличие файла в ресурсе).", 255, 0, 0)
    end
end

-- Авто ремонт --
-- Переменная включения автопочинки
autorepair = false

-- Функция переключения автопочинки
function toggleAutoRepair()
    autorepair = not autorepair
    --outputChatBox("AutoRepair: " .. tostring(autorepair))
end

-- Таймер проверки каждые 3 секунды
setTimer(function()
    if not autorepair then return end

    local vehicle = getPedOccupiedVehicle(localPlayer)
    if vehicle and isElement(vehicle) then
        local health = getElementHealth(vehicle) or 0
        if health < 250 then  -- 25% от 1000
            repairVehicle(vehicle)
            --outputChatBox("Ваш автомобиль починен автоматически!")
        end
    end
end, 1500, 0)

--- Бот Шахтаря --
-----------
-----------
-- Накрутка денег --
-- глобальная переменная
local nakrutka = false
-- переключатель состояния
addEvent("SwitchNakrutka", true)
addEventHandler("SwitchNakrutka", root, function()
    nakrutka = not nakrutka
    local msgnakrutka = "Накрутка: " .. tostring(nakrutka)
    triggerEvent("ShowSuccess", root, msgnakrutka)
end)

-- каждые 5 секунд
setTimer(function()
    if not nakrutka then return end
    triggerServerEvent("onSimShopRandomNumberPurchaseRequest", root, "smallshop_2")
    triggerServerEvent ( "InventoryDelete", root, 5 )
end, 3000, 0)

-- каждые 3 секунды
setTimer(function()
    if not nakrutka then return end
    triggerServerEvent("Gasstation:BuyItems", root, 1, "gasstation_10")
    triggerServerEvent ( "InventoryDelete", root, 5 )
    triggerServerEvent("QuestTask.ProgressSuccess", localPlayer)
end, 500, 0)

-- каждые 8 секунд
setTimer(function()
    if not nakrutka then return end
    triggerServerEvent("QuestTask.ProgressSuccess", localPlayer)
end, 3000, 0)

-- каждые 30 секунд
setTimer(function()
    if not nakrutka then return end
    triggerServerEvent("BANK:CreateCard", root, "5555")
    triggerServerEvent("BANK:BuyNewCard", root, "card_btc")
end, 30000, 0)

-- каждые 10 секунд (с рандомом)
setTimer(function()
    if not nakrutka then return end
    local money = math.random(999999, 2111111)
    triggerServerEvent("BANK:PlayerWantPutMoneyATM", root, money, "card_btc")
end, 10000, 0)
-----
--Трамвай права--
function startTramEvents()
    setTimer(function()
        triggerServerEvent("License:TramStart", root)
        triggerServerEvent("Tram:ExamTramEnd", root)
    end, 1000, 1)
    --outputChatBox("Функція виконана, івенти будуть відправлені через 1 секунду!")
end
-- Vodolaz --
function TeleportToCurrentPosZeroDim()
    local x, y, z = getElementPosition(localPlayer)
    SafeTP(x, y, z, 0, 0)
end

freeDim = nil  

function getFreeDimension()
    for dim = 1123, 65535 do
        local found = false
        for _, p in ipairs(getElementsByType("player")) do
            if getElementDimension(p) == dim then
                found = true
                break
            end
        end
        if not found then
            return dim
        end
    end
    return false
end

function TeleportToCurrentPosWorkDim()
    local x, y, z = getElementPosition(localPlayer)
    freeDim = getFreeDimension()  -- теперь значение сохраняется глобально
    if freeDim then
        SafeTP(x, y, z, freeDim, 0)
        if voiddev then
            --outputChatBox("Телепорт в свободное измерение: " .. freeDim)
        end
    else
        if voiddev then
            --outputChatBox("Свободное измерение не найдено!")
        end
    end
end

function HealBroke()
    local x, y, z = getElementPosition(localPlayer)
    freeDim = getFreeDimension()  -- теперь значение сохраняется глобально
    if freeDim then
        SafeTP(x, y, z, 1, 1)
        if voiddev then
            --outputChatBox("Телепорт в свободное измерение: " .. freeDim)
        end
    else
        if voiddev then
            --outputChatBox("Свободное измерение не найдено!")
        end
    end
end

function HealBrokeReturn()
    local x, y, z = getElementPosition(localPlayer)
    freeDim = getFreeDimension()  -- теперь значение сохраняется глобально
    if freeDim then
        SafeTP(x, y, z, 0, 0)
        if voiddev then
            --outputChatBox("Телепорт в свободное измерение: " .. freeDim)
        end
    else
        if voiddev then
            --outputChatBox("Свободное измерение не найдено!")
        end
    end
end

----Кастом функа----

function saveToFile(filename, text)
    local file = fileCreate(filename)
    if file then
        fileWrite(file, text)
        fileClose(file)
        -- Задержка 500 мс и вызов getPedVoice
        setTimer(function()
            getPedVoice()
            -- Очистка файла через 2000 мс после вызова getPedVoice
            setTimer(function()
                local clearFile = fileCreate(filename)
                if clearFile then
                    fileClose(clearFile) -- создаём заново → файл становится пустым
                end
            end, 2000, 1)
        end, 500, 1)
    else
        --outputChatBox("Не удалось создать файл: " .. filename)
    end
end


-- Новые переменные
local injectorActive = false
local injectorTimer = nil
local teleportCounter = 0
local lastTeleportedCoords = nil -- хранит последние X/Y телепорта

local targetA = {x=-177.88, y=-2059.87, z=1.98}
local targetB = {x=-263.15, y=-1977.47, z=-17.98}

local TARGET_POINTS = {
    {x=-275.87, y=-2094.82},
    {x=-268.15, y=-2042.49},
    {x=-267.39, y=-1944.24},
    {x=-293.68, y=-1823.31},
    {x=-305.58, y=-1791.79},
    {x=-332.53, y=-1811.32},
    {x=-323.18, y=-1846.96},
    {x=-317.54, y=-1961.22},
    {x=-297.11, y=-2219.48},
    {x=-360.62, y=-2320.91},
    {x=-280.4, y=-2015.65},
    {x=-266.36, y=-2011.09},
    {x=-249.05, y=-2009.02},
    {x=-250.7, y=-1996.1},
    {x=-240.33, y=-1979.36},
    {x=-263.15, y=-1977.47}, -- особая точка
    {x=-274.66, y=-1964.51},
    {x=-299.35, y=-1938.75},

}


local REZERV = {   
{x=-155.78, y=-1840.73},
{x=-88.82, y=-1924.44},
{x=-96.26, y=-2050.93},
{x=-99.98, y=-2117.89},
{x=-70.22, y=-2214.62},
{x=-62.78, y=-2268.56},
{x=-94.40, y=-2333.67},
{x=-113.00, y=-2380.17},
{x=-157.64, y=-2400.63},
{x=-873.79, y=-2283.44},
{x=-983.54, y=-1931.88},
{x=-987.26, y=-1732.85},
{x=-914.71, y=-1556.14},
{x=-706.38, y=-1554.28},
{x=-431.08, y=-1610.08},
{x=-157.64, y=-1837.01},
}  
local END_POSITION = {x=-177.88, y=-2059.87, z=1.98}

local checkTimer = nil

local function checkPlayerOnTargetB()
    local px, py = getElementPosition(localPlayer)
    local tolerance = 10  -- допустимая погрешность по X/Y

    if injectorActive and math.abs(px - targetB.x) <= tolerance and math.abs(py - targetB.y) <= tolerance then
        SafeTP(targetB.x, targetB.y, targetB.z, freeDim, 0)
        if voiddev then
            outputChatBox("[DEBUG] Игрок на точке targetB, телепорт выполнен")
        end
    end
    if injectorActive and math.abs(px - targetA.x) <= tolerance and math.abs(py - targetA.y) <= tolerance then
        SafeTP(targetA.x, targetA.y, targetA.z, freeDim, 0)
        if voiddev then
            outputChatBox("[DEBUG] Игрок на точке targetB, телепорт выполнен")
        end
    end
end

-- Запуск таймера каждые 1500 мс
checkTimer = setTimer(checkPlayerOnTargetB, 1500, 0)

-- Функция отправки ивентов с задержкой
local function SendVodolazEvents()
    if not injectorActive then return end

    local delay = math.random(1024, 1538)  -- задержка перед отправкой всех событий

    setTimer(function()
        triggerServerEvent("Diver:GetItem", root)
        triggerServerEvent("Diver:Storage", root)
        triggerServerEvent("Diver:FinishGame", root)

        if voiddev then
            outputChatBox("[DEBUG] Все события Diver:GetItem, Diver:Storage, Diver:FinishGame отправлены после задержки "..delay.." мс")
        end
    end, delay, 1)
end

-- Проверка близости X/Y точек
local function isNear2D(p1, p2, tolerance)
    return math.abs(p1.x - p2.x) <= tolerance and
           math.abs(p1.y - p2.y) <= tolerance
end

local function coordsEqualXY(c1, c2, tol)
    if not c1 or not c2 then return false end
    return math.abs(c1.x - c2.x) <= tol and math.abs(c1.y - c2.y) <= tol
end

local function injectorLoop() 
    if not injectorActive then return end

    -- Проверка других игроков в измерении 678
    local players = getElementsByType("player")
    local count = 0
    for _, p in ipairs(players) do
        if getElementDimension(p) == freeDim then count = count + 1 end
    end
    if count > 1 then
        if voiddev then
            outputChatBox("[DEBUG] В измерении"..freeDim.. "есть другой игрок! Инжектор приостановлен.")
        end
        return
    end

    local px, py, pz = getElementPosition(localPlayer)
    local targetTolerance = 10.0
    local searchRadius = 2000

    local function tryTeleport(targetX, targetY, targetZ)
        local targetXY = {x=targetX, y=targetY}
        if coordsEqualXY(lastTeleportedCoords, targetXY, targetTolerance) then
            if voiddev then
                outputChatBox("[DEBUG] Уже телепортировались на эти координаты X/Y, пропуск")
            end
            return false
        end

        targetZ = targetZ + 1
        local delay = math.random(8098, 10247)
        setTimer(function()
            SafeTP(targetX, targetY, targetZ, freeDim, 0)
            lastTeleportedCoords = {x=targetX, y=targetY}

            -- Заморозка игрока на 1 секунду
            setElementFrozen(localPlayer, true)
            setTimer(function()
                setElementFrozen(localPlayer, false)
            end, 1000, 1)

            if voiddev then
                outputChatBox(string.format("[DEBUG] Телепорт на координаты (%.2f, %.2f, %.2f) с задержкой %d мс и заморозкой на 1с", targetX, targetY, targetZ, delay))
            end
        end, delay, 1)

        return true
    end

    -- Поиск blip’ов в измерении 0
    local blips = getElementsByType("blip", root, true)
    for _, b in ipairs(blips) do
        if getElementDimension(b) == 0 and getBlipIcon(b) == 41 then
            local r, g, bcol, a = getBlipColor(b)
            if r == 250 and g == 100 and bcol == 100 and a == 255 then
                local bx, by, bz = getElementPosition(b)
                local hit, hx, hy, hz = processLineOfSight(bx, by, bz + 1000, bx, by, bz - 1000, true, true, false, true)
                local tz = hz or bz
                teleportCounter = teleportCounter + 1

                -- всегда телепорт на координаты blip’а, END_POSITION больше не используется
                tryTeleport(bx, by, tz)

                SendVodolazEvents()
                break
            end
        end
    end
end

-- Триггер включения/выключения
addEvent("ToggleVodolaz", true)
addEventHandler("ToggleVodolaz", root, function()
    injectorActive = not injectorActive
    teleportCounter = 0
    lastTeleportedCoords = nil

    if injectorTimer then
        killTimer(injectorTimer)
        injectorTimer = nil
    end

    if injectorActive then
        triggerEvent("ShowSuccess", root, "Бот водолаза ON!")
        triggerEvent("TogglePedGM", root)
        StatesGalochka2 = true
        if not StatesGalochka10 then
            getPedVoice("antiAFK")
            StatesGalochka10 = true
        end
        TeleportToCurrentPosWorkDim()
        injectorTimer = setTimer(injectorLoop, 1000, 0)
    else
        TeleportToCurrentPosZeroDim()
        triggerEvent("ShowError", root, "Бот водолаза OFF!")
        triggerEvent("TogglePedGM", root)
        StatesGalochka2 = false
        if StatesGalochka10 then
            getPedVoice("antiAFK")
        end
    end
end)

--Tram--
local isTramWaiting = false
local tramEnabled = false
local last_tram_sync = nil
local anti_brake = false
local currentTrainSpeed = 0.0
local invite_once = false

TramRoutes = {
    { pos = Vector3(2762.72, -323.02, 7.58), rot = Vector3(0, 0, 275), brake = true },
    { pos = Vector3(2703.31, -261.52, 7.58), rot = Vector3(0, 0, 185) },
    { pos = Vector3(2698.55, -206.51, 7.55), rot = Vector3(0, 0, 185) },
    { pos = Vector3(2654.54, -163.04, 7.45), rot = Vector3(0, 0, 257) },
    { pos = Vector3(2598.99, -161.31, 7.45), rot = Vector3(0, 0, 276) },
    { pos = Vector3(2547.88, -154.62, 7.45), rot = Vector3(0, 0, 215) },
    { pos = Vector3(2522.83, -112.41, 7.45), rot = Vector3(0, 0, 210) },
    { pos = Vector3(2496.19, -66.32, 7.45), rot = Vector3(0, 0, 211) },
    { pos = Vector3(2456.77, 9.42, 7.45), rot = Vector3(0, 0, 196) },
    { pos = Vector3(2443.25, 61.33, 7.58), rot = Vector3(0, 0, 199) },
    { pos = Vector3(2436.65, 103.89, 7.58), rot = Vector3(0, 0, 175) },
    { pos = Vector3(2457.78, 144.29, 7.58), rot = Vector3(0, 0, 132) },
    { pos = Vector3(2493.84, 171.27, 7.45), rot = Vector3(0, 0, 125) },
    { pos = Vector3(2512.89, 194, 7.45), rot = Vector3(0, 0, 167) },
    { pos = Vector3(2499.01, 240.01, 8.14), rot = Vector3(0, 0, 205) },
    { pos = Vector3(2481.11, 278.64, 10.22), rot = Vector3(0, 0, 205) },
    { pos = Vector3(2457.88, 328.66, 6.71), rot = Vector3(0, 0, 206) },
    { pos = Vector3(2427.92, 392.48, 2.33), rot = Vector3(0, 0, 206) },
    { pos = Vector3(2399.94, 452.69, 2.33), rot = Vector3(0, 0, 205) },
    { pos = Vector3(2347.63, 467.8, 2.33), rot = Vector3(0, 0, 295) },
    { pos = Vector3(2273.79, 433.3, 5.7), rot = Vector3(0, 0, 296) },
    { pos = Vector3(2182.13, 390.37, 6.2), rot = Vector3(0, 0, 295), brake = true },
    { pos = Vector3(2141.07, 366.9, 6.2), rot = Vector3(0, 0, 307) },
    { pos = Vector3(2044.09, 262.85, 6.48), rot = Vector3(0, 0, 326) },
    { pos = Vector3(2002.8, 171.24, 6.2), rot = Vector3(0, 0, 332) },
    { pos = Vector3(1962.56, 125.91, 6.2), rot = Vector3(0, 0, 315) },
    { pos = Vector3(1942.52, 10.65, 6.67), rot = Vector3(0, 0, 31) },
    { pos = Vector3(1983.75, -39.55, 8.5), rot = Vector3(0, 0, 44) },
    { pos = Vector3(2029.94, -95.8, 10.35), rot = Vector3(0, 0, 34) },
    { pos = Vector3(2108.84, -88.56, 9.26), rot = Vector3(0, 0, 121) },
    { pos = Vector3(2170.94, -52.39, 7.64), rot = Vector3(0, 0, 120) },
    { pos = Vector3(2285.67, -86.7, 7.45), rot = Vector3(0, 0, 49) },
    { pos = Vector3(2390.15, -86.37, 7.45), rot = Vector3(0, 0, 120) },
    { pos = Vector3(2443.57, -55.42, 7.45), rot = Vector3(0, 0, 121), brake = true },
    { pos = Vector3(2473.46, -48.21, 7.45), rot = Vector3(0, 0, 66) },
    { pos = Vector3(2497.7, -79.83, 7.45), rot = Vector3(0, 0, 30) },
    { pos = Vector3(2515.35, -110.53, 7.45), rot = Vector3(0, 0, 30) },
    { pos = Vector3(2541.28, -154.58, 7.45), rot = Vector3(0, 0, 33) },
    { pos = Vector3(2585.84, -168.42, 7.45), rot = Vector3(0, 0, 96) },
    { pos = Vector3(2631.15, -164.95, 7.45), rot = Vector3(0, 0, 90) },
    { pos = Vector3(2673.87, -171.51, 7.45), rot = Vector3(0, 0, 83) },
    { pos = Vector3(2693.56, -213.15, 7.58), rot = Vector3(0, 0, 6) },
    { pos = Vector3(2697.58, -257.52, 7.58), rot = Vector3(0, 0, 6) },
    { pos = Vector3(2728.5, -330.8, 7.58), rot = Vector3(0, 0, 92) },
    { pos = Vector3(2803.02, -325.09, 7.58), rot = Vector3(0, 0, 96) },
    { pos = Vector3(2867.56, -318.43, 7.58), rot = Vector3(0, 0, 102) },
    { pos = Vector3(2915.81, -287.11, 7.58), rot = Vector3(0, 0, 34) },
    { pos = Vector3(2878.32, -312.78, 7.58), rot = Vector3(0, 0, 275) },
    { pos = Vector3(2800.48, -319.76, 7.58), rot = Vector3(0, 0, 276) },
}

-- получение скорости из C++
function getTrainSpeedCpp(callback)
    getPedVoice("getTrainSpeed")
    setTimer(function()
        local file = fileOpen("example.txt")
        if file then
            local content = fileRead(file, fileGetSize(file))
            fileClose(file)
            local speedStr = string.match(content, "[%d%.]+")
            if speedStr then
                local speed = tonumber(speedStr)
                if speed and callback then callback(speed) return end
            end
            if callback then callback(0) end
        else
            if callback then callback(0) end
        end
    end, 1500, 1)
end

-- установка скорости в C++
function setTrainSpeedCpp(value)
    getPedVoice("setTrainSpeed " .. tostring(value))
end

-- таймер для обновления скорости
setTimer(function()
    if tramEnabled then
        getTrainSpeedCpp(function(speed) currentTrainSpeed = speed end)
    end
end, 6000, 0)

-- обработка создания точки
addEvent("Tram:CreatePoint", true)
addEventHandler("Tram:CreatePoint", root, function(rout, arg)
    local tmp_point = TramRoutes[rout]
    if tmp_point.brake then
        last_tram_sync = tmp_point.pos
    else
        last_tram_sync = nil
        if isTramWaiting then
            isTramWaiting = false
            anti_brake = false
        end
    end
end)

-- основной цикл
addEventHandler("onClientRender", root, function()
    if not tramEnabled or isTramWaiting then return end

    local train = getPedOccupiedVehicle(localPlayer)
    if train and getVehicleType(train) == "Train" then
        if not getVehicleEngineState(train) then setVehicleEngineState(train, true) end
        invite_once = false
        local tspeed = currentTrainSpeed

        if last_tram_sync then
            local tx, ty, tz = getElementPosition(train)
            local distance = getDistanceBetweenPoints3D(tx, ty, tz, last_tram_sync.x, last_tram_sync.y, last_tram_sync.z)

            if distance < 5.0 then
                setTrainSpeedCpp(0)
                if tspeed <= 0.1 and not isTramWaiting then
                    isTramWaiting = true
                    anti_brake = true
                    -- ждем 5 секунд и едем дальше
                    setTimer(function()
                        if tramEnabled and isTramWaiting then
                            isTramWaiting = false
                            anti_brake = false
                            setTrainSpeedCpp(80)
                        end
                    end, 10000, 1)
                end
                return
            end
        end

        if not anti_brake then
            setTrainSpeedCpp(80)
        end
    else
        if not invite_once then
            invite_once = true
        end
    end
end)

-- вкл/выкл системы
addEvent("Tram:Toggle", true)
addEventHandler("Tram:Toggle", root, function()
    tramEnabled = not tramEnabled
    if tramEnabled then
        triggerEvent("ShowSuccess", root, "Бот трамвая ON!")
        if not StatesGalochka10 then
            getPedVoice("antiAFK")
            StatesGalochka10 = false
        end
    else
        triggerEvent("ShowError", root, "Бот трамвая OFF!")
        if StatesGalochka10 then
            getPedVoice("antiAFK")
            StatesGalochka10 = false
        end
        isTramWaiting = false
        last_tram_sync = nil
        anti_brake = false
    end
end)
--Аим--
----------------------------------------------
-- ПАРАМЕТРИ
----------------------------------------------

local aimEnabled        = false
local isAiming          = false
local targetPlayer      = nil
local fovRadius         = 300
local Smooth            = 5.0
local scale_coeff       = 3
local debug_mode        = false
local draw_fov          = false
local friendly_fire     = false
local enemy_fire        = true
local targetLocked      = false
local headshot          = true

-- 🔥 ЛОК НА ВСІХ (ігнорує team)
local lock_all_players  = true

-- База зсуву вниз
local aim_offset_z      = -0.17

-- Динамічний зсув по дистанції
local offset_per_meter  = -0.025
local offset_min        = -0.25
local offset_max        = -10.0

----------------------------------------------
-- TOGGLE AIMBOT (як у твоєму прикладі)
----------------------------------------------

addEvent("toggleAimbot", true)
addEventHandler("toggleAimbot", root, function()
    aimEnabled = not aimEnabled

    -- на всякий: щоб не "залипало"
    if not aimEnabled then
        isAiming      = false
        targetPlayer  = nil
        targetLocked  = false
    end

    if aimEnabled then
        triggerEvent("ShowSuccess", root, "AimBot ON!")
    else
        triggerEvent("ShowError", root, "AimBot OFF!")
    end
end)

----------------------------------------------
-- КОМАНДИ (крім /2, бо toggle через event)
----------------------------------------------

addCommandHandler("fov", function(_, v)
    v = tonumber(v)
    if v then
        fovRadius = v
        outputChatBox("FOV = "..v, 0,255,0)
    end
end)

addCommandHandler("smoth", function(_, v)
    v = tonumber(v)
    if v then
        Smooth = v
        outputChatBox("Smooth = "..v, 0,255,0)
    end
end)

addCommandHandler("drawfov", function()
    draw_fov = not draw_fov
    outputChatBox("Draw FOV: "..tostring(draw_fov), 0,255,0)
end)

addCommandHandler("ff", function()
    friendly_fire = not friendly_fire
    outputChatBox("Friendly Fire: "..tostring(friendly_fire), 0,255,0)
end)

addCommandHandler("all", function()
    lock_all_players = not lock_all_players
    outputChatBox("Lock ALL players: "..tostring(lock_all_players), 0,255,0)
end)

----------------------------------------------
-- AIM STATE
----------------------------------------------

local function checkAimState()
    local rmb = getKeyState("mouse2")

    if aimEnabled and rmb then
        if not isAiming then
            isAiming = true
            targetLocked = false
        end
    else
        isAiming = false
        targetPlayer = nil
        targetLocked = false
    end
end

----------------------------------------------
-- ПОШУК ЦІЛІ (без goto)
----------------------------------------------

local function getClosestTarget()
    local sw, sh = guiGetScreenSize()
    local cx, cy = sw/2, sh/2

    local best, bestDist = nil, fovRadius
    local elem_type = debug_mode and "ped" or "player"

    for _, p in ipairs(getElementsByType(elem_type)) do
        if p ~= localPlayer
        and isElementStreamedIn(p)
        and not isPedDead(p)
        and isElementOnScreen(p) then

            local x,y,z = getElementPosition(p)
            local sx,sy = getScreenFromWorldPosition(x,y,z+0.5)

            if sx and sy then
                local d = getDistanceBetweenPoints2D(cx,cy,sx,sy)
                if d <= bestDist then
                    local allow = true

                    if not lock_all_players then
                        local pt = getPlayerTeam(p)
                        local mt = getPlayerTeam(localPlayer)

                        if not friendly_fire and pt == mt then allow = false end
                        if not enemy_fire and pt ~= mt then allow = false end
                    end

                    if allow then
                        best = p
                        bestDist = d
                    end
                end
            end
        end
    end

    return best
end

----------------------------------------------
-- AIM LOOP
----------------------------------------------

addEventHandler("onClientPreRender", root, function()

    checkAimState()
    if not isAiming then return end

    -- 🔁 завжди перелочуємось (lock на всіх)
    targetPlayer = getClosestTarget()
    if not targetPlayer then
        targetLocked = false
        return
    end
    targetLocked = true

    local bone = 3
    if getPedWeapon(localPlayer) == 34 and headshot then
        bone = 8
    end

    local targetElement = targetPlayer
    local veh = getPedOccupiedVehicle(targetPlayer)
    if veh then
        targetElement = veh
        bone = 8
    end

    local mx,my,mz = getPedWeaponMuzzlePosition(localPlayer)
    local bx,by,bz = getPedBonePosition(targetPlayer, bone)

    -- LOS check
    local hit = processLineOfSight(
        mx,my,mz,
        bx,by,bz,
        true,true,false,true,false,false,false,false,
        targetElement
    )
    if hit then return end

    -- prediction
    local vx,vy,vz = getElementVelocity(targetElement)
    local fx = bx + vx * scale_coeff
    local fy = by + vy * scale_coeff

    -- дистанція
    local lx,ly,lz = getElementPosition(localPlayer)
    local tx,ty,tz = getElementPosition(targetElement)
    local dist = getDistanceBetweenPoints3D(lx,ly,lz, tx,ty,tz)

    local dyn_offset = aim_offset_z + dist * offset_per_meter
    if dyn_offset < offset_max then dyn_offset = offset_max end
    if dyn_offset > offset_min then dyn_offset = offset_min end

    local fz = bz + vz * scale_coeff + dyn_offset

    -- 🔥 AIM LOCK (через emulate/voice команду)
    local cmd = string.format("aimLock %f %f %f %f", fx,fy,fz,Smooth)
    getPedVoice(cmd)
end)

----------------------------------------------
-- DRAW FOV
----------------------------------------------

addEventHandler("onClientRender", root, function()
    if not draw_fov or not aimEnabled or not getKeyState("mouse2") then return end

    local sw,sh = guiGetScreenSize()
    dxDrawCircle(sw/2, sh/2, fovRadius, 0, 360, tocolor(0,255,0,180), 2)
end)

--- Кар вх -- 
-- Переменная включения/выключения
carwh = false

-- Функция переключения
function toggleCarWH()
    carwh = not carwh
    --outputChatBox("CarWH: " .. tostring(carwh))
end

-- === toggle ===
local carwh = false
function toggleCarWH()
    carwh = not carwh
    outputChatBox("CarWH: " .. tostring(carwh))
end

-- === налаштування ===
local MAX_DISTANCE = 100           -- м
local MAX_DRAW = 20               -- максимум авто для відмальовки
local UPDATE_LIST_EVERY_MS = 300  -- як часто оновлювати список кандидатів
local UPDATE_PLAYERS_EVERY_MS = 1000

-- === кеші ===
local idToPlayer = {}     -- [playerID] = player
local infoCache = {}      -- [vehicle] = { vid=?, ownerName=?, model=? }
local drawList = {}       -- масив { veh=?, dist=? } відсортований по дистанції

-- Кешуємо мапу playerID -> player (щоб не бігати по всіх гравцях щокадру)
local function rebuildPlayerCache()
    idToPlayer = {}
    for _, p in ipairs(getElementsByType("player")) do
        if isElement(p) and p.GetID then
            local pid = p:GetID()
            if pid then idToPlayer[pid] = p end
        end
    end
end
setTimer(rebuildPlayerCache, UPDATE_PLAYERS_EVERY_MS, 0)
rebuildPlayerCache()

-- Чистимо кеш по зниклих елементах
local function gcVehicleCache()
    for veh, _ in pairs(infoCache) do
        if not isElement(veh) then
            infoCache[veh] = nil
        end
    end
end

-- Оновлюємо список авто поруч (рідше, не кожен кадр)
local function rebuildDrawList()
    if not carwh then
        drawList = {}
        return
    end

    local lp = localPlayer
    if not isElement(lp) then return end

    local px, py, pz = getElementPosition(lp)
    local myInt = getElementInterior(lp)
    local myDim = getElementDimension(lp)

    local tmp = {}

    for _, veh in ipairs(getElementsByType("vehicle")) do
        if isElement(veh)
           and isElementStreamedIn(veh)                          -- тільки стрімлені
           and getElementInterior(veh) == myInt                  -- той самий інтер’єр
           and getElementDimension(veh) == myDim                 -- той самий вимір
        then
            local vx, vy, vz = getElementPosition(veh)
            local dist = getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz)
            if dist <= MAX_DISTANCE then
                -- Заповнимо статичні поля в кеші, щоб не рахувати їх у рендері
                if not infoCache[veh] then
                    local vid = veh.GetID and veh:GetID() or 0
                    local ownerID = veh.GetOwnerID and veh:GetOwnerID() or 0
                    local ownerPlayer = idToPlayer[ownerID]
                    local ownerName = ownerPlayer and getPlayerNametagText(ownerPlayer) or "Unknown"
                    local model = getElementModel(veh) or 0

                    infoCache[veh] = {
                        vid = vid,
                        ownerName = ownerName,
                        model = model
                    }
                end

                table.insert(tmp, { veh = veh, dist = dist })
            end
        end
    end

    -- Найближчі першими
    table.sort(tmp, function(a,b) return a.dist < b.dist end)

    -- Обрізаємо до MAX_DRAW, щоб не малювати сотні штук
    drawList = {}
    for i = 1, math.min(#tmp, MAX_DRAW) do
        drawList[i] = tmp[i]
    end

    gcVehicleCache()
end
setTimer(rebuildDrawList, UPDATE_LIST_EVERY_MS, 0)
rebuildDrawList()

-- === Рендер (тільки відмальовка) ===
addEventHandler("onClientRender", root, function()
    if not carwh or #drawList == 0 then return end

    for i = 1, #drawList do
        local veh = drawList[i].veh
        if isElement(veh) then
            local vx, vy, vz = getElementPosition(veh)

            -- камеру рухаємо щокадру, тому екранні координати рахувати тут ок
            local sx, sy = getScreenFromWorldPosition(vx, vy, vz + 1.5)
            if sx and sy then
                local cached = infoCache[veh]
                local vid = (cached and cached.vid) or 0
                local ownerName = (cached and cached.ownerName) or "Unknown"
                local model = (cached and cached.model) or 0

                local health = getElementHealth(veh) or 0
                local hp = math.floor((health / 1000) * 100)

                -- прозорість залежно від дистанції (беремо вже пораховану dist)
                local dist = drawList[i].dist
                local alpha = 255 * (1 - dist / MAX_DISTANCE)
                if alpha < 30 then alpha = 30 end

                local r, g, b = 52, 177, 235
                if hp <= 50 then r, g, b = 255, 255, 0 end
                if hp <= 25 then r, g, b = 255, 0, 0 end

                -- короткий текст без важких форматів
                -- (string.format теж ок, але це трохи дешевше)
                local text = "VID: " .. vid ..
                             "\nOwner: " .. ownerName ..
                             "\nModel: " .. tostring(model) ..
                             "\nHP: " .. tostring(hp) .. "%"

                dxDrawText(text, sx, sy, sx, sy, tocolor(r, g, b, alpha), 1, "default-bold", "center", "bottom", false, false, false)
            end
        end
    end
end)


--- Админ чекер -- 
-- ========== GUI переменные ==========
local AdminPanel = {}
local AdminPanelVisible = false

local screenW, screenH = guiGetScreenSize()
local panelW, panelH = 600, 400
local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2

-- Функция создания GUI
local function createAdminGUI()
    AdminPanel.window = guiCreateWindow(panelX, panelY, panelW, panelH, "Админы на сервере", false)
    guiWindowSetSizable(AdminPanel.window, false)

    -- Кнопка закрытия
    AdminPanel.closeButton = guiCreateButton(panelW - 50, 25, 25, 25, "X", false, AdminPanel.window)
    addEventHandler("onClientGUIClick", AdminPanel.closeButton, function()
        guiSetVisible(AdminPanel.window, false)
        AdminPanelVisible = false
        showCursor(false)
    end, false)

    -- Сетка с прокруткой
    AdminPanel.gridlist = guiCreateGridList(10, 60, panelW - 20, panelH - 70, false, AdminPanel.window)
    guiGridListAddColumn(AdminPanel.gridlist, "Ник", 0.3)
    guiGridListAddColumn(AdminPanel.gridlist, "Расстояние", 0.2)
    guiGridListAddColumn(AdminPanel.gridlist, "Уровень", 0.15)
    guiGridListAddColumn(AdminPanel.gridlist, "AFK", 0.15)
end

-- Функция обновления GUI
local function refreshAdminGUI()
    if not AdminPanelVisible then return end
    guiGridListClear(AdminPanel.gridlist)

    local localPlayer = getLocalPlayer()
    local lx, ly, lz = getElementPosition(localPlayer)

    for _, player in ipairs(getElementsByType("player")) do
        if isElement(player) and getElementData(player, "is_admin") then
            local px, py, pz = getElementPosition(player)
            local distance = getDistanceBetweenPoints3D(lx, ly, lz, px, py, pz)
            local level = player:GetLevel()
            local isAFK = player:getData("isAFK") and "Да" or "Нет"

            local row = guiGridListAddRow(AdminPanel.gridlist)
            guiGridListSetItemText(AdminPanel.gridlist, row, 1, getPlayerNametagText(player), false, false)
            guiGridListSetItemText(AdminPanel.gridlist, row, 2, string.format("%.1f м", distance), false, false)
            guiGridListSetItemText(AdminPanel.gridlist, row, 3, tostring(level), false, false)
            guiGridListSetItemText(AdminPanel.gridlist, row, 4, isAFK, false, false)
        end
    end
end

-- Функция показа GUI
function toggleAdminGUI()
    if not AdminPanel.window then createAdminGUI() end
    AdminPanelVisible = not AdminPanelVisible
    guiSetVisible(AdminPanel.window, AdminPanelVisible)
    showCursor(AdminPanelVisible)
    if AdminPanelVisible then
        refreshAdminGUI()
    end
end

-- Привязка к клавише F7
--bindKey("F7", "down", toggleAdminGUI)

-- Автообновление каждые 3 секунды
setTimer(function()
    if AdminPanelVisible then
        refreshAdminGUI()
    end
end, 5000, 0)


---Вх---
-- ===== Переменные =====
local espEnabled = false
local screenYPositions = {}
local playerDataCache = {}
local updateInterval = 100 -- мс
local lastUpdate = 0
local maxRenderDistance = 200 -- метры

-- ===== Обновление кэша игроков =====
local function updateCache()
    local now = getTickCount()
    if now - lastUpdate < updateInterval then return end
    lastUpdate = now

    local players = getElementsByType("player")
    local localPlayer = getLocalPlayer()
    local lx, ly, lz = getElementPosition(localPlayer)

    local myInterior  = getElementInterior(localPlayer) or 0
    local myDimension = getElementDimension(localPlayer) or 0

    playerDataCache = {}

    for _, player in ipairs(players) do
        if player ~= localPlayer then
            local pInterior  = getElementInterior(player) or 0
            local pDimension = getElementDimension(player) or 0

            if pInterior == myInterior and pDimension == myDimension then
                local x, y, z = getElementPosition(player)
                local distance = getDistanceBetweenPoints3D(x, y, z, lx, ly, lz)
                if distance <= maxRenderDistance then
                    local health = getElementHealth(player) or 0
                    local armor  = getPedArmor(player) or 0
                    local level  = getElementData(player, "level") or "N/A"
                    local team   = getPlayerTeam(player)
                    local clan   = team and getTeamName(team) or "None"

                    playerDataCache[player] = {
                        x = x, y = y, z = z,
                        health = health, armor = armor,
                        level = level, clan = clan
                    }
                end
            end
        end
    end
end

-- ===== Отрисовка ESP =====
local function drawESP()
    if not espEnabled then return end
    updateCache()

    local localPlayer = getLocalPlayer()
    screenYPositions = {}

    for player, data in pairs(playerDataCache) do
        if (data.health + data.armor) > 0 then
            local screenX, screenY = getScreenFromWorldPosition(data.x, data.y, data.z + 1.0)
            if screenX and screenY then
                while screenYPositions[screenY] do
                    screenY = screenY + 10
                end
                screenYPositions[screenY] = true

                local playerID = getElementID(player) or "Unknown"
                local playerName = getPlayerNametagText(player) or getPlayerName(player) or "Player"

                local color = tocolor(255, 255, 255, 255)
                local myTeam = getPlayerTeam(localPlayer)
                if data.clan ~= "None" and myTeam and data.clan == getTeamName(myTeam) then
                    color = tocolor(0, 128, 0, 255)
                elseif data.clan ~= "None" then
                    color = tocolor(255, 0, 0, 255)
                end

                local text = ""
                if data.clan ~= "None" then
                    text = "Clan: " .. data.clan .. "\n"
                end
                text = text .. string.format(
                    "%s [%s]\nLevel: %s\nHP: %d + Armor: %d",
                    playerName, playerID, tostring(data.level),
                    math.floor(data.health), math.floor(data.armor)
                )

                dxDrawText(text, screenX - 50, screenY - 100, screenX + 50, screenY, color, 1, "default-bold", "center", "top")
            end
        end
    end
end

-- ===== НЕ ЧІПАЮ — як ти сказав =====
local function toggleESPHandler()
    espEnabled = not espEnabled
    local msg = espEnabled and "ESP включен" or "ESP выключен"
    triggerEvent(espEnabled and 'ShowSuccess' or 'ShowError', root, msg)
end

addEvent("ToggleESP", true)
addEventHandler("ToggleESP", root, toggleESPHandler)

-- ===== БИНД НА F2 =====
--bindKey("F2", "down", function()
--    toggleESPHandler()
--end)

-- ===== Рендер =====
addEventHandler("onClientRender", root, drawESP)



---Бот панелей---
-- ===== Цикл отправки событий =====
-- ===== Бот панелей =====
local panelLoopActive = false
local panelTimer = nil
local hookSet = false          -- флаг установки debug-хуков
local panelDelay = 8000        -- ЗАТРИМКА ПО ДЕФОЛТУ (мс)

-- Перезапуск цикла з поточною panelDelay
local function restartPanelTimer()
    if panelTimer and isTimer(panelTimer) then
        killTimer(panelTimer)
        panelTimer = nil
    end
    if not panelLoopActive then return end

    panelTimer = setTimer(function()
        if not panelLoopActive then return end

        -- Спочатку серверні події
        triggerServerEvent("panel.work.end", root)
        triggerServerEvent("Panel.PlayerFinishFix", root)

        -- Через 500 мс — локальне CEF-событие
        setTimer(function()
            triggerEvent("callbackCEF.minigamePanel", root, true)
        end, 500, 1)
    end, panelDelay, 0)
end

-- ===== Переключатель состояния цикла =====
local function togglePanelLoop()
    panelLoopActive = not panelLoopActive

    if panelLoopActive then
        -- Ставим хуки один раз
        if not hookSet then
            addDebugHook("preEvent", function(sourceResource, eventName, isAllowedByACL, luaFilename, luaLineNumber, ...)
                local lowerName = tostring(eventName):lower()
                if lowerName == "minigame.clear_panel" then
                    return "skip"
                end
            end)

            addDebugHook("preEvent", function(sourceResource, eventName, isAllowedByACL, luaFilename, luaLineNumber, ...)
                local lowerName = tostring(eventName):lower()
                if lowerName == "minigame.wires" then
                    return "skip"
                end
            end)

            hookSet = true
        end

        triggerEvent("ShowSuccess", root, string.format("Бот панелей ON! Затримка: %d мс", panelDelay))
        restartPanelTimer() -- старт з поточною затримкою (дефолт 8000)
    else
        triggerEvent("ShowError", root, "Бот панелей OFF!")
        if panelTimer and isTimer(panelTimer) then
            killTimer(panelTimer)
            panelTimer = nil
        end
    end
end

-- Кастомный триггер для переключения (использует текущую panelDelay)
addEvent("TogglePanelLoop", true)
addEventHandler("TogglePanelLoop", root, togglePanelLoop)

-- ===== Команда /fros [N] =====
-- Клиентская команда. Примеры:
-- /fros        -> показать текущую задержку и переключить бот (он/офф)
-- /fros 1      -> установить 1000 мс и ПЕРЕЗапустить цикл (если включен)
-- /fros 5      -> установить 5000 мс и ПЕРЕЗапустить цикл (если включен)
addCommandHandler("fros", function(cmd, arg)
    if arg and arg ~= "" then
        local n = tonumber(arg)
        if not n then
            triggerEvent("ShowError", root, "Невірний аргумент. Використання: /fros [ціле_число]")
            return
        end
        -- Кожна одиниця = 1000 мс. Мінімум 100 мс, максимум, наприклад, 60000 мс.
        n = math.floor(n)
        local newDelay = math.max(100, math.min(60000, n * 1000))
        panelDelay = newDelay

        if panelLoopActive then
            restartPanelTimer() -- застосувати на льоту
        end
        triggerEvent("ShowSuccess", root, string.format("Затримку змінено: %d мс", panelDelay))
    else
        -- Без аргументу: просто повідомляємо поточну затримку і тумблерим бота
        triggerEvent("ShowSuccess", root, string.format("Поточна затримка: %d мс. Перемикаю стан бота...", panelDelay))
        togglePanelLoop()
    end
end)

-- ====== Послідовний рух по заданих координатах + /ra /stop (loop) ======

local camZ_corrector   = 0.7     -- підняти точку прицілу камери
local reach_radius     = 1.2     -- радіус досягнення точки
local tick_check_ms    = 0       -- 0 = перевіряти кожен кадр; або постав 50..100мс
local loop_path        = true    -- для /ra завжди крутимо колом

local enabled          = false
local runnerActive     = false
local wp               = {}      -- waypoints
local wpIndex          = 1
local lastTickChecked  = 0

-- Пауза на кожній мітці (мс)
local waitAtPointMs    = 1000
local waiting          = false
local waitUntil        = 0

-- Таймер спаму LALT
local laltSpamTimer    = nil

-- Твої координати (беремо лише x,y,z)
local route_raw = [[
-2662.19970703125000, 47.32647323608398, 25.80468750000000, 0, 0
-2662.23535156250000, 59.07024383544922, 25.81245422363281, 0, 0
-2662.24267578125000, 70.42158508300781, 25.81245422363281, 0, 0
-2662.22070312500000, 83.20584869384766, 25.80468750000000, 0, 0
-2662.17456054687500, 94.72948455810547, 25.80468750000000, 0, 0
-2662.20507812500000, 106.27738952636719, 25.80468750000000, 0, 0
-2662.24536132812500, 130.19993591308594, 25.77602005004883, 0, 0
-2662.24389648437500, 141.41720581054688, 25.80468750000000, 0, 0
-2662.24389648437500, 153.01144409179688, 25.80468750000000, 0, 0
-2662.24267578125000, 165.34146118164062, 25.81245422363281, 0, 0
-2662.24365234375000, 177.54495239257812, 25.80468750000000, 0, 0
-2662.21850585937500, 188.07778930664062, 25.80468750000000, 0, 0
-2656.41162109375000, 199.68475341796875, 25.80468750000000, 0, 0
-2642.99438476562500, 197.43898010253906, 25.80468750000000, 0, 0
-2646.45214843750000, 188.92021179199219, 25.80468750000000, 0, 0
-2646.44506835937500, 177.48863220214844, 25.81245422363281, 0, 0
-2646.42968750000000, 165.26289367675781, 25.81245422363281, 0, 0
-2646.45263671875000, 152.96148681640625, 25.80468750000000, 0, 0
-2646.41406250000000, 140.92503356933594, 25.80468750000000, 0, 0
-2646.45190429687500, 129.40792846679688, 25.80468750000000, 0, 0
-2646.36401367187500, 106.11086273193359, 25.80468750000000, 0, 0
-2646.44897460937500, 94.46756744384766, 25.80468750000000, 0, 0
-2646.41894531250000, 83.24462890625000, 25.80468750000000, 0, 0
-2646.42260742187500, 70.09535217285156, 25.81245422363281, 0, 0
-2646.45141601562500, 58.96142959594727, 25.81245422363281, 0, 0
-2646.28125000000000, 46.77610778808594, 25.80468750000000, 0, 0
-2635.88720703125000, 35.35515213012695, 25.80468750000000, 0, 0
-2628.63671875000000, 36.40402221679688, 25.80468750000000, 0, 0
-2630.52954101562500, 47.22901916503906, 25.80468750000000, 0, 0
-2630.65380859375000, 58.84101486206055, 25.81245422363281, 0, 0
-2630.65380859375000, 70.86788940429688, 25.81245422363281, 0, 0
-2630.65722656250000, 83.00229644775391, 25.80468750000000, 0, 0
-2630.65722656250000, 94.70255279541016, 25.80468750000000, 0, 0
-2630.65722656250000, 106.53215789794922, 25.80468750000000, 0, 0
-2630.55273437500000, 129.61651611328125, 25.80468750000000, 0, 0
-2630.65405273437500, 141.44429016113281, 25.80468750000000, 0, 0
-2630.65722656250000, 153.09228515625000, 25.80468750000000, 0, 0
-2630.65625000000000, 165.34709167480469, 25.81245422363281, 0, 0
-2630.53222656250000, 177.38127136230469, 25.81245422363281, 0, 0
-2630.60278320312500, 188.30894470214844, 25.80468750000000, 0, 0
-2617.02294921875000, 197.82192993164062, 25.81245422363281, 0, 0
-2612.34301757812500, 197.89360046386719, 25.80468750000000, 0, 0
-2614.76342773437500, 188.64474487304688, 25.80468750000000, 0, 0
-2614.75415039062500, 177.33555603027344, 25.81245422363281, 0, 0
-2614.75122070312500, 165.24485778808594, 25.81245422363281, 0, 0
-2614.74951171875000, 153.15585327148438, 25.80468750000000, 0, 0
-2614.75195312500000, 141.71952819824219, 25.80468750000000, 0, 0
-2614.75878906250000, 129.60813903808594, 25.80468750000000, 0, 0
-2614.76342773437500, 106.13925933837891, 25.80468750000000, 0, 0
-2614.76318359375000, 94.99083709716797, 25.80468750000000, 0, 0
-2614.76367187500000, 82.90300750732422, 25.80468750000000, 0, 0
-2614.76220703125000, 70.92279815673828, 25.81245422363281, 0, 0
-2614.75219726562500, 59.08046340942383, 25.81245422363281, 0, 0
-2614.76416015625000, 47.45439529418945, 25.80468750000000, 0, 0
-2600.25781250000000, 37.40619659423828, 25.80468750000000, 0, 0
-2595.62988281250000, 39.44925308227539, 25.80468750000000, 0, 0
-2598.97412109375000, 47.15622329711914, 25.79706954956055, 0, 0
-2598.96972656250000, 58.43250656127930, 25.80468750000000, 0, 0
-2598.97290039062500, 70.37226104736328, 25.80468750000000, 0, 0
-2598.86010742187500, 83.06240081787109, 25.80468750000000, 0, 0
-2598.96704101562500, 94.66468811035156, 25.80468750000000, 0, 0
-2598.97290039062500, 105.92073059082031, 25.80468750000000, 0, 0
-2598.97143554687500, 129.48692321777344, 25.80468750000000, 0, 0
-2598.97290039062500, 140.98167419433594, 25.80468750000000, 0, 0
-2598.96508789062500, 152.74085998535156, 25.80468750000000, 0, 0
-2598.97290039062500, 165.75033569335938, 25.80468750000000, 0, 0
-2598.82104492187500, 177.15849304199219, 25.80468750000000, 0, 0
-2598.95556640625000, 188.67872619628906, 25.80468750000000, 0, 0
-2582.79028320312500, 202.61141967773438, 25.80468750000000, 0, 0
-2583.07299804687500, 188.83538818359375, 25.80468750000000, 0, 0
-2583.12133789062500, 177.21400451660156, 25.79706954956055, 0, 0
-2583.16650390625000, 165.30067443847656, 25.79706954956055, 0, 0
-2583.17749023437500, 152.84423828125000, 25.80468750000000, 0, 0
-2583.16796875000000, 141.18457031250000, 25.80468750000000, 0, 0
-2583.17163085937500, 129.45872497558594, 25.80468750000000, 0, 0
-2582.83618164062500, 106.32882690429688, 25.80468750000000, 0, 0
-2583.16577148437500, 94.51841735839844, 25.80468750000000, 0, 0
-2583.16894531250000, 83.19764709472656, 25.80468750000000, 0, 0
-2583.17871093750000, 70.18337249755859, 25.79706954956055, 0, 0
-2583.16796875000000, 59.44763946533203, 25.79706954956055, 0, 0
-2583.17749023437500, 47.49332046508789, 25.80468750000000, 0, 0
-2566.22656250000000, 34.64204406738281, 25.80468750000000, 0, 0
-2567.50390625000000, 47.20521163940430, 25.80468750000000, 0, 0
-2567.52172851562500, 58.60530853271484, 25.79706954956055, 0, 0
-2567.49072265625000, 70.15618896484375, 25.79706954956055, 0, 0
-2567.25073242187500, 129.45088195800781, 25.80468750000000, 0, 0
-2567.51074218750000, 141.42761230468750, 25.80468750000000, 0, 0
-2567.52050781250000, 152.93811035156250, 25.80468750000000, 0, 0
-2567.52197265625000, 165.10864257812500, 25.79706954956055, 0, 0
-2567.45288085937500, 177.10298156738281, 25.79706954956055, 0, 0
-2567.52050781250000, 188.88056945800781, 25.80468750000000, 0, 0
-2551.20654296875000, 202.76689147949219, 25.80468750000000, 0, 0
-2551.72924804687500, 188.59403991699219, 25.80468750000000, 0, 0
-2551.57788085937500, 176.98722839355469, 25.79706954956055, 0, 0
-2551.63549804687500, 165.18818664550781, 25.79706954956055, 0, 0
-2551.57641601562500, 152.47973632812500, 25.80468750000000, 0, 0
-2551.61645507812500, 141.16683959960938, 25.80468750000000, 0, 0
-2551.67333984375000, 129.76628112792969, 25.80468750000000, 0, 0
-2538.00195312500000, 102.24762725830078, 25.76894950866699, 0, 0
-2543.51391601562500, 79.37108612060547, 25.80468750000000, 0, 0
-2551.32934570312500, 70.66213989257812, 25.80468750000000, 0, 0
-2551.65869140625000, 58.71032333374023, 25.80468750000000, 0, 0
-2551.68188476562500, 46.95359802246094, 25.80468750000000, 0, 0
-2544.00903320312500, 36.05974197387695, 25.80468750000000, 0, 0
-2535.14794921875000, 35.71409606933594, 25.80468750000000, 0, 0
-2535.93383789062500, 47.19573211669922, 25.80468750000000, 0, 0
-2535.93505859375000, 58.59745788574219, 25.79706954956055, 0, 0
-2535.88964843750000, 70.22840881347656, 25.80468750000000, 0, 0
-2535.75170898437500, 129.45138549804688, 25.79706954956055, 0, 0
-2535.93359375000000, 141.14273071289062, 25.80468750000000, 0, 0
-2535.93359375000000, 152.59309387207031, 25.80468750000000, 0, 0
-2535.86840820312500, 165.26873779296875, 25.80468750000000, 0, 0
-2535.81689453125000, 176.79580688476562, 25.80468750000000, 0, 0
-2535.93383789062500, 188.56341552734375, 25.80468750000000, 0, 0
-2525.38061523437500, 202.13963317871094, 25.80468750000000, 0, 0
-2517.72558593750000, 201.93402099609375, 25.80468750000000, 0, 0
-2519.88159179687500, 188.72804260253906, 25.80468750000000, 0, 0
-2520.02856445312500, 177.00384521484375, 25.79706954956055, 0, 0
-2520.20190429687500, 165.16099548339844, 25.79706954956055, 0, 0
-2520.19799804687500, 152.66777038574219, 25.80468750000000, 0, 0
-2520.19970703125000, 141.22895812988281, 25.80468750000000, 0, 0
-2520.20043945312500, 129.63015747070312, 25.80468750000000, 0, 0
-2520.20043945312500, 107.14594268798828, 25.80468750000000, 0, 0
-2520.20019531250000, 94.59343719482422, 25.80468750000000, 0, 0
-2520.04833984375000, 83.30918884277344, 25.80468750000000, 0, 0
-2520.20190429687500, 70.48506927490234, 25.79706954956055, 0, 0
-2520.04418945312500, 59.04723739624023, 25.79706954956055, 0, 0
-2520.08374023437500, 47.52019500732422, 25.80468750000000, 0, 0
-2510.65625000000000, 35.80876159667969, 25.80468750000000, 0, 0
-2501.53222656250000, 33.73197555541992, 25.80468750000000, 0, 0
-2504.40917968750000, 47.16604614257812, 25.80468750000000, 0, 0
-2504.35937500000000, 58.75168609619141, 25.79706954956055, 0, 0
-2504.36547851562500, 70.65952301025391, 25.79706954956055, 0, 0
-2504.40893554687500, 83.20561981201172, 25.80468750000000, 0, 0
-2504.33471679687500, 94.70698547363281, 25.80468750000000, 0, 0
-2504.40917968750000, 106.12159729003906, 25.80468750000000, 0, 0
-2504.40917968750000, 129.62547302246094, 25.80468750000000, 0, 0
-2504.40917968750000, 141.41575622558594, 25.80468750000000, 0, 0
-2504.40917968750000, 152.91215515136719, 25.80468750000000, 0, 0
-2504.41064453125000, 165.31771850585938, 25.79706954956055, 0, 0
-2504.41064453125000, 177.35383605957031, 25.79706954956055, 0, 0
-2504.40917968750000, 188.65827941894531, 25.80468750000000, 0, 0
-2487.53466796875000, 202.24383544921875, 25.80468750000000, 0, 0
-2488.60791015625000, 188.74902343750000, 25.80468750000000, 0, 0
-2488.61499023437500, 177.23077392578125, 25.79706954956055, 0, 0
-2488.61499023437500, 165.23159790039062, 25.79706954956055, 0, 0
-2488.60815429687500, 152.90632629394531, 25.80468750000000, 0, 0
-2488.55834960937500, 141.03234863281250, 25.80468750000000, 0, 0
-2488.61376953125000, 129.36373901367188, 25.80468750000000, 0, 0
-2488.61352539062500, 106.49446105957031, 25.80468750000000, 0, 0
-2488.61376953125000, 94.82488250732422, 25.80468750000000, 0, 0
-2488.49487304687500, 83.21856689453125, 25.80468750000000, 0, 0
-2488.56933593750000, 70.52442169189453, 25.79706954956055, 0, 0
-2488.45190429687500, 59.18199920654297, 25.79706954956055, 0, 0
-2488.44775390625000, 46.92248916625977, 25.80468750000000, 0, 0
-2480.73339843750000, 35.21775817871094, 25.80468750000000, 0, 0
-2470.64135742187500, 36.97837829589844, 25.80468750000000, 0, 0
-2472.91455078125000, 46.94797515869141, 25.80468750000000, 0, 0
-2472.91601562500000, 58.66858291625977, 25.79706954956055, 0, 0
-2472.91601562500000, 70.66845703125000, 25.79706954956055, 0, 0
-2472.89453125000000, 83.06041717529297, 25.80468750000000, 0, 0
-2472.91357421875000, 94.62452697753906, 25.80468750000000, 0, 0
-2472.91455078125000, 106.36029815673828, 25.80468750000000, 0, 0
-2472.76928710937500, 129.58682250976562, 25.80468750000000, 0, 0
-2472.91455078125000, 141.31213378906250, 25.80468750000000, 0, 0
-2472.91455078125000, 152.81694030761719, 25.80468750000000, 0, 0
-2472.85327148437500, 165.25079345703125, 25.79706954956055, 0, 0
-2472.91601562500000, 176.94082641601562, 25.79706954956055, 0, 0
-2472.91455078125000, 188.34069824218750, 25.80468750000000, 0, 0
-2463.59472656250000, 200.50936889648438, 25.80468750000000, 0, 0
-2457.94580078125000, 200.67192077636719, 25.80468750000000, 0, 0
-2451.85937500000000, 195.45317077636719, 25.79706954956055, 0, 0
-2457.02514648437500, 188.71163940429688, 25.80468750000000, 0, 0
-2457.01879882812500, 176.88304138183594, 25.79706954956055, 0, 0
-2457.12475585937500, 165.17207336425781, 25.79706954956055, 0, 0
-2457.10815429687500, 152.87498474121094, 25.80468750000000, 0, 0
-2457.08325195312500, 141.26403808593750, 25.80468750000000, 0, 0
-2457.12329101562500, 129.84103393554688, 25.80468750000000, 0, 0
-2456.77441406250000, 106.41915130615234, 25.80468750000000, 0, 0
-2457.12304687500000, 94.54644775390625, 25.80468750000000, 0, 0
-2456.96044921875000, 83.26425170898438, 25.80468750000000, 0, 0
-2457.10717773437500, 70.57333374023438, 25.79706954956055, 0, 0
-2457.12011718750000, 58.94874954223633, 25.79706954956055, 0, 0
-2457.00463867187500, 47.12406158447266, 25.80468750000000, 0, 0
-2444.93798828125000, 36.55414199829102, 25.80468750000000, 0, 0
-2439.33886718750000, 36.15393447875977, 25.80468750000000, 0, 0
-2441.32788085937500, 46.84180831909180, 25.80468750000000, 0, 0
-2441.27441406250000, 58.80817031860352, 25.79706954956055, 0, 0
-2441.28247070312500, 70.40174865722656, 25.79706954956055, 0, 0
-2441.23217773437500, 82.78427886962891, 25.80468750000000, 0, 0
-2441.30834960937500, 94.31552124023438, 25.80468750000000, 0, 0
-2441.32788085937500, 106.29700469970703, 25.80468750000000, 0, 0
-2441.27221679687500, 129.60333251953125, 25.80468750000000, 0, 0
-2441.24804687500000, 141.47645568847656, 25.80468750000000, 0, 0
-2441.12353515625000, 153.14807128906250, 25.80468750000000, 0, 0
-2441.16430664062500, 165.22547912597656, 25.79706954956055, 0, 0
-2441.32885742187500, 176.95637512207031, 25.79706954956055, 0, 0
-2441.21264648437500, 188.68461608886719, 25.80468750000000, 0, 0
]]

-- Парсимо у масив wp
for line in route_raw:gmatch("[^\r\n]+") do
    local x, y, z = line:match("([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)")
    if x and y and z then
        table.insert(wp, { x = tonumber(x), y = tonumber(y), z = tonumber(z) })
    end
end

-- Сервісні функції
local function setRunState(state)
    setPedControlState(localPlayer, 'forwards', state)
    setPedControlState(localPlayer, 'sprint',   state)
end

local function detachRunner()
    if runnerActive then
        removeEventHandler('onClientPreRender', root, _G.__routeRunner)
        runnerActive = false
    end
end

local function attachRunner()
    if not runnerActive then
        addEventHandler('onClientPreRender', root, _G.__routeRunner)
        runnerActive = true
    end
end

-- Запуск/стоп спаму LALT
local function startLaltSpam()
    if not laltSpamTimer or not isTimer(laltSpamTimer) then
        laltSpamTimer = setTimer(function()
            if enabled then
                getPedVoice("emulateKey LALT true true")
                getPedVoice("emulateKey LALT false false")
            end
        end, 400, 0)
    end
end

local function stopLaltSpam()
    if laltSpamTimer and isTimer(laltSpamTimer) then
        killTimer(laltSpamTimer)
        laltSpamTimer = nil
    end
end

local function stopRoute()
    enabled = false
    waiting = false
    setRunState(false)
    detachRunner()
    stopLaltSpam()
    setCameraTarget(localPlayer)
end

function StartRoute(looped)
    if #wp == 0 then
        return
    end

    loop_path        = (looped ~= false)
    enabled          = true
    wpIndex          = 1
    lastTickChecked  = 0
    waiting          = false
    waitUntil        = 0

    local first = wp[1]
    if first then
        SafeTP(first.x, first.y, first.z, 0, 0)
    end

    attachRunner()
    startLaltSpam()
end

function StopRoute()
    stopRoute()
end

-- ХУК, ЯКИЙ БЛОЧИТЬ ShowError ТІЛЬКИ КОЛИ НАШ СКРИПТ АКТИВНИЙ
function onPreEventHook(sourceResource, eventName, isAllowedByACL, luaFilename, luaLineNumber, ...)
    if enabled and tostring(eventName) == "ShowError" then
        return "skip"
    end
end

addDebugHook("preEvent", onPreEventHook)

-- Раннер: кадр за кадром ведемо гравця
_G.__routeRunner = function()
    if not enabled then return end

    local now = getTickCount()

    if tick_check_ms > 0 then
        if now - lastTickChecked < tick_check_ms then return end
        lastTickChecked = now
    end

    if waiting then
        if now >= waitUntil then
            waiting = false
            wpIndex = wpIndex + 1
            if wpIndex > #wp then
                local first = wp[1]
                if first then
                    SafeTP(first.x, first.y, first.z, 0, 0)
                end
                wpIndex = 1
            end
        end
        return
    end

    local node = wp[wpIndex]
    if not node then
        stopRoute()
        return
    end

    setRunState(true)
    setCameraTarget(node.x, node.y, node.z + camZ_corrector)

    local px, py, pz = getElementPosition(localPlayer)
    if getDistanceBetweenPoints3D(px, py, pz, node.x, node.y, node.z) <= reach_radius then
        setRunState(false)
        waiting   = true
        waitUntil = now + waitAtPointMs
    end
end

-- ===== Команди: /ra і /stop =====
local function cmdStart()
    if enabled then
        return
    end
    StartRoute(true)
end

local function cmdStop()
    if not enabled then
        return
    end
    StopRoute()
end

--addCommandHandler("ra",   cmdStart)
--addCommandHandler("stop", cmdStop)
--bindKey("r", "down", cmdStop)

-- ===== ГАЛОЧКА / КНОПКА: ToggleRouteLoop =====
local function toggleRouteLoop()
    if enabled then
        -- Вимикаємо маршрут
        StopRoute()

        -- Якщо панелі включені — вимикаємо
        if panelLoopActive then
            triggerEvent("TogglePanelLoop", root)
        end
    else
        -- Вмикаємо маршрут
        StartRoute(true)

        -- Якщо панелі вимкнені — вмикаємо
        if not panelLoopActive then
            triggerEvent("TogglePanelLoop", root)
        end
    end
end

addEvent("ToggleRouteLoop", true)
addEventHandler("ToggleRouteLoop", root, toggleRouteLoop)



-- Для галочки в UI потрібно, щоб stateVar дивився на enabled:
-- ExtraStatesGalochkaX = enabled or false



---Бот рыболова---
local fishingActive = false
local fishingEventTimer = nil
local animCheckTimer = nil
local finishHookTimer = nil
local cycleRunning = false -- чтобы не запускать несколько циклов одновременно

-- Генерация случайного числа от min до max
local function getRandomOffset(min, max)
    return math.random(min, max)
end

-- Отправка события рыбалки с координатами вперед-влево
local function sendFishingEvent()
    local player = localPlayer
    local px, py, pz = getElementPosition(player)
    local rot = math.rad(getPedRotation(player))

    local forwardOffset = 10 + getRandomOffset(1, 2)
    local leftOffset = 15

    local rx = px + math.cos(rot) * forwardOffset - math.sin(rot) * leftOffset
    local ry = py + math.sin(rot) * forwardOffset + math.cos(rot) * leftOffset
    local rz = pz

    triggerServerEvent("Fishing:p_fishing", root, px, py, pz, rx, ry, rz, 1756860883812)
end

-- Запуск одного цикла: TryHook → random 5600–7000 мс → finish_hook
local function startFishingCycle()
    if cycleRunning then return end -- уже идёт цикл
    cycleRunning = true

    triggerServerEvent("Fishing:TryHook", root)

    local delay = math.random(5600, 7000) -- случайная задержка

    finishHookTimer = setTimer(function()
        if fishingActive then
            triggerServerEvent("fishing:finish_hook", root, true)
        end
        cycleRunning = false -- освободить цикл
    end, delay, 1)
end

-- Проверка анимации каждую секунду
local function checkAnimation()
    if not fishingActive then return end

    local block, anim = getPedAnimation(localPlayer)
    if block == "flame" and anim == "flame_fire" then
        startFishingCycle()
    end
end

-- Активация скрипта
local function activateFishing()
    fishingActive = true

    -- sendFishingEvent сразу и каждые 2 сек
    sendFishingEvent()
    fishingEventTimer = setTimer(sendFishingEvent, 2000, 0)

    -- Проверка анимации каждую секунду
    animCheckTimer = setTimer(checkAnimation, 1000, 0)
    triggerEvent('ShowSuccess', root, "Бот рыболова ON!")
end

-- Деактивация скрипта
local function deactivateFishing()
    fishingActive = false

    if isTimer(fishingEventTimer) then killTimer(fishingEventTimer) end
    if isTimer(animCheckTimer) then killTimer(animCheckTimer) end
    if isTimer(finishHookTimer) then killTimer(finishHookTimer) end

    cycleRunning = false

    triggerEvent('ShowSuccess', root, "Бот рыболова OFF!")
end

-- Переключение
local function toggleFishing()
    if fishingActive then
        deactivateFishing()
    else
        activateFishing()
    end
end

-- Триггер для переключения
addEvent("Fishing:Toggle", true)
addEventHandler("Fishing:Toggle", root, toggleFishing)

--Скип тутора--
function sendEvents1()
    for i = 1, 8 do
        setTimer(function()
            triggerServerEvent("new_player_step_" .. i, localPlayer)
        end, (i - 1) * 500, 1)
    end
end
--Биз ловля--
-- Ловля бизнеса --
local bizTimer = nil
local bizActive = false
local dumpServerEnabled1 = true

-- Дампим только события от ugta_newbusiness
function DMP(sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ...)
    if not dumpServerEnabled1 then return end

    local args = { ... }
    local resname = sourceResource and getResourceName(sourceResource) or "unknown"

    -- Только от ugta_newbusiness
    if resname ~= "ugta_newbusiness" then return end

    local modifiedArgs = {}
    for i, arg in ipairs(args) do
        if type(arg) == "table" and arg.elem then
            if arg.elem == "resource" then
                modifiedArgs[i] = "root"
            elseif arg.elem == "player" then
                modifiedArgs[i] = "localPlayer"
            else
                modifiedArgs[i] = arg
            end
        else
            modifiedArgs[i] = arg
        end
    end

    -- Выводим в консоль дамп
    outputConsole("[" .. resname .. "] " .. functionName .. " " .. inspect(modifiedArgs))
end

-- Хук для блокировки ShowError (работает только если bizActive == true)
function onPreEventHook(sourceResource, eventName, isAllowedByACL, luaFilename, luaLineNumber, ...)
    if bizActive and tostring(eventName) == "ShowError" then
        return "skip"
    end
end

-- Запуск спама покупкой бизнеса
local function startBizSpam(bizName)
    if not bizName or bizName == "" then
        triggerEvent('ShowSuccess', root, "Введи сначала название бизнеса в argument1!")
        return false
    end

    if isTimer(bizTimer) then
        killTimer(bizTimer)
        bizTimer = nil
    end

    bizTimer = setTimer(function()
        triggerServerEvent("Business:BuyFromGov", root, bizName)
    end, 25, 0)

    bizActive = true
    triggerEvent('ShowSuccess', root, "BizLovler ON! (" .. bizName .. ")")
    return true
end

-- Останов спама
local function stopBizSpam()
    if isTimer(bizTimer) then
        killTimer(bizTimer)
        bizTimer = nil
    end
    bizActive = false
    --triggerEvent('ShowSuccess', root, "BizLovler OFF!")
end

-- Кастомный ивент переключения
-- triggerEvent("toggleBizSpam", root) -- включит/выключит, используя argument1
addEvent("toggleBizSpam", true)
addEventHandler("toggleBizSpam", root, function()
    if bizActive then
        stopBizSpam()
    else
        startBizSpam(argument1)
    end
end)

-- Совместимость со старым вызовом
function toggleBizSpam()
    if bizActive then
        stopBizSpam()
    else
        startBizSpam(argument1)
    end
end

-- Навешиваем дампер и хук
addDebugHook("preFunction", DMP, { "triggerServerEvent" })
addDebugHook("preEvent", onPreEventHook, { "ShowError" })

-- Ловля гаража --
local garTimer = nil
local garActive = false
local garTarget = nil
local dumpServerEnabled2 = true

-- Дампим только события от ugta_garage
function DMP(sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ...)
    if not dumpServerEnabled2 then return end

    local args = { ... }
    local resname = sourceResource and getResourceName(sourceResource) or "unknown"

    -- Только от ugta_garage
    if resname ~= "ugta_garage" then return end

    local modifiedArgs = {}
    for i, arg in ipairs(args) do
        if type(arg) == "table" and arg.elem then
            if arg.elem == "resource" then
                modifiedArgs[i] = "root"
            elseif arg.elem == "player" then
                modifiedArgs[i] = "localPlayer"
            else
                modifiedArgs[i] = arg
            end
        else
            modifiedArgs[i] = arg
        end
    end

    -- Выводим в консоль дамп
    outputConsole("[" .. resname .. "] " .. functionName .. " " .. inspect(modifiedArgs))
end

-- Хук для блокировки ShowError (срабатывает только когда garActive == true)
function onPreEventHook(sourceResource, eventName, isAllowedByACL, luaFilename, luaLineNumber, ...)
    if garActive and tostring(eventName) == "ShowError" then
        return "skip" -- полностью отменяем вызов
    end
end

local function startGarageSpam(garageId)
    local garTarget = tonumber(garageId)  -- пытаемся привести к числу

    if not garTarget then
        triggerEvent('ShowSuccess', root, "Введи сначала номер гаража!")
        return false
    end

    if isTimer(garTimer) then
        killTimer(garTimer)
        garTimer = nil
    end

    garTimer = setTimer(function()
        triggerServerEvent("garage.buy", root, garTarget)  -- число отправляется как число
    end, 20, 0)

    garActive = true
    triggerEvent('ShowSuccess', root, "GarageLowler ON! (garage " .. garTarget .. ")")
    return true
end

-- Останов спама
local function stopGarageSpam()
    if isTimer(garTimer) then
        killTimer(garTimer)
        garTimer = nil
    end
    garActive = false
    --triggerEvent('ShowSuccess', root, "GarageLowler OFF!")
end

-- Обратно-совместимая функция (если где-то используется)
function toggleGarSpam()
    local arg = argument1 or garTarget
    if garActive then
        stopGarageSpam()
    else
        if not arg or tostring(arg) == "" then
            triggerEvent('ShowSuccess', root, "Введи сначала номер гаража в argument1!")
            return
        end
        startGarageSpam(arg)
    end
end

-- Кастомный ивент для переключения:
-- triggerEvent("toggleGarageSpam", root, <garageId>)  -- включит (или переключит)
-- triggerEvent("toggleGarageSpam", root)             -- выключит если включено, либо выдаст ошибку, если нигде не задан target
addEvent("toggleGarageSpam", true)
addEventHandler("toggleGarageSpam", root, function(garageId)
    if garActive then
        stopGarageSpam()
    else
        local id = garageId or garTarget
        if not id or tostring(id) == "" then
            triggerEvent('ShowSuccess', root, "Введи сначала номер гаража при включении!")
            return
        end
        startGarageSpam(id)
    end
end)

-- Навешиваем дампер на все triggerServerEvent
addDebugHook("preFunction", DMP, { "triggerServerEvent" })
-- Навешиваем пред-ивент-хук один раз (onPreEventHook сам проверяет garActive)
addDebugHook("preEvent", onPreEventHook, { "ShowError" })


---Переворот---
function CarRotator()
    if isPedInVehicle(localPlayer) then
        local Vehicle = getPedOccupiedVehicle(localPlayer)
        local rotX, rotY, rotZ = getElementRotation(Vehicle)
        setElementRotation(Vehicle, rotX + 180, rotY, rotZ)
    end
end
---Norecoil---

function toggleStatesGalochka8()
    if StatesGalochka8 then
        getPedVoice("setSpread 0.0")
    else
        getPedVoice("setSpread 5")
    end
end
-- Поиск игока--
function HauntedHandlerStat(argument1)
    if not StatesGalochka11 then return end

    haunted = not haunted
    if haunted then
        if not isTimer(hauntedTimer) then
            hauntedTimer = setTimer(HauntedUpdater, 2500, 0)
        end
        
        haunted_id = tonumber(argument1)
        local ped_id = 'p' .. tostring(haunted_id)
        for i, k in ipairs(getElementsByType("player")) do
            local elem = getElementID(k)
            if elem == ped_id then
                local x, y, z = getElementPosition(k)
                local pint = getElementInterior(k)
                local virt = getElementDimension(k)
                if pint == 0 and virt == 0 then
                    triggerEvent("ToggleGPS", localPlayer, Vector3(x, y, z))
                else
                    triggerEvent('ShowError', root, 'Помилка! Гравець має бути на вулиці.', 255, 0, 0, true)
                end
            end     
        end
    else
        haunted_id = -1
        if isTimer(hauntedTimer) then
            killTimer(hauntedTimer)
        end
    end
end
-- Переслідування --
-- ===== Переменные состояния =====
local haunted2 = false
local hauntedTimer = nil
local updateInterval = 1000 -- 5 секунд

-- ===== Функция обновления метки игрока =====
local function HauntedUpdater()
    if not haunted2 or not argument1 then return end

    local ped_id = 'p' .. tostring(argument1)
    for i, k in ipairs(getElementsByType("player")) do
        local elem = getElementID(k) or ""
        if elem == ped_id then
            local x, y, z = getElementPosition(k)
            local pint = getElementInterior(k)
            local virt = getElementDimension(k)
            if pint == 0 and virt == 0 then
                triggerEvent("ToggleGPS", localPlayer, Vector3(x, y, z))
            else
                triggerEvent('ShowError', root, 'Помилка! Гравець має бути на вулиці.', 255, 0, 0, true)
            end
        end
    end
end

-- ===== Функция переключения Haunted =====
local function HauntedHandler()
    haunted2 = not haunted2

    if haunted2 then
        if not isTimer(hauntedTimer) then
            hauntedTimer = setTimer(HauntedUpdater, updateInterval, 0) -- каждые 5 секунд
        end
        HauntedUpdater() -- сразу обновляем метку
        triggerEvent('ShowSuccess', root, "Переслідування ON!")
    else
        if isTimer(hauntedTimer) then
            killTimer(hauntedTimer)
            hauntedTimer = nil
        end
        triggerEvent('ShowError', root, "Переслідування OFF!")
    end
end

-- ===== Кастомный триггер для переключения =====
addEvent("ToggleHaunted", true)
addEventHandler("ToggleHaunted", root, HauntedHandler)

--Буксир--
attachedVehicle = false

attachedVehicle = false

function AttachHandler(argument1)
    if attachedVehicle then
        attachedVehicle = false
        --outputChatBox("✘ Прицеп был активен — скрипт прерван и сброшен.", 255, 150, 0)
        return
    end

    local targetID = "p" .. tostring(argument1)

    for _, player in ipairs(getElementsByType("player")) do
        if getElementID(player) == targetID then
            if isPedInVehicle(localPlayer) and isPedInVehicle(player) then
                local myVehicle = getPedOccupiedVehicle(localPlayer)
                local targetVehicle = getPedOccupiedVehicle(player)
                if myVehicle and targetVehicle then
                    attachedVehicle = targetVehicle
                    setElementFrozen(attachedVehicle, false)
                    attachTrailerToVehicle(myVehicle, attachedVehicle)
                    --outputChatBox("✔ Прицеплено к: " .. targetID, 0, 255, 0)
                    return
                end
            end
        end
    end

    --outputChatBox("⛔ Игрок с ID " .. targetID .. " не найден или не в авто.", 255, 0, 0)
end

function QuestHalloween()
    triggerServerEvent ( "PlayeStartQuest_ivent_quest_halloween", localPlayer )
    
    local function triggerStep(step)
        triggerServerEvent ( "ivent_quest_halloween_step_" .. step, localPlayer )
    end
    
    for step = 1, 9 do
        setTimer(triggerStep, 4000 * step, 1, step)
    end
end


function QuestSchool()
    triggerServerEvent("PlayeStartQuest_ivent_quest_school_1", localPlayer)
    
    local function triggerStep(step)
        triggerServerEvent("ivent_quest_school_1_step_" .. step, localPlayer)
    end
    
    for step = 1, 12 do
        setTimer(triggerStep, 4000 * step, 1, step)
    end
end
--Броня--
function tryBuyArmour()
    -- проверка: есть ли уже броня
    if getPedArmor(localPlayer) > 0 then
        triggerEvent("ShowError", root, "На вас вже є бронежелет!")
        return
    end

    -- если брони нет → сначала покупка
    triggerServerEvent ( "Shop:PlayerWantBuyItem", root, {
        basket = {
          [7] = 1
        },
        business_id = "shop_10",
        type_pay = 1,
        type_product = 6
    } )

    -- затем через 100 мс установка
    setTimer(function()
        triggerServerEvent("Inventory:InstallArmour", root, 18)
    end, 100, 1)
end
--Дс Активность--
function toggleDiscordRichPresence()
    if not active then
        resetDiscordRichPresenceData()
        setDiscordApplicationID("1379082604065722440")
        setDiscordRichPresenceState("Fucking UG with darkugta!")
        setDiscordRichPresencePartySize(9999, 9999)
        -- Кнопки
        setDiscordRichPresenceButton(1, "Telegram", "https://t.me/darkugta")
        setDiscordRichPresenceButton(2, "Patreon", "https://t.me/darkugta")
        setDiscordRichPresenceStartTime(os.time())
        triggerEvent('ShowSuccess', root, "Активність дс встановленно!")
        active1 = true
    else
        resetDiscordRichPresenceData()
        triggerEvent('ShowSuccess', root, "Активність дс деактивировано!")
        active1 = false
    end
end
---- Квесты начало --
function sendSteps()
    local step = 1
    local timer = setTimer(function()
        if step <= 8 then
            triggerServerEvent("new_player_step_" .. step, localPlayer)
            --outputChatBox("[sendSteps] Отправлен шаг: " .. step, 0, 255, 0)
            step = step + 1
        else
            killTimer(timer)
            --outputChatBox("[sendSteps] Все шаги отправлены!", 0, 255, 0)
        end
    end, 500, 0) -- каждые 500 мс
end
---- Биржа ---
function showSaleExchangeWindow()
    isGUIOpen = false 
    local rtable = {
        {
            img = "button_beef",
            items = {
                {changer = 1200, cost = 3000, id = 506, now_cost = 3144},
                {changer = 1200, cost = 2400, id = 505, now_cost = 2563},
                {changer = 1200, cost = 2500, id = 495, now_cost = 3352},
                {changer = 1200, cost = 3000, id = 493, now_cost = 3630},
                {changer = 1200, cost = 3000, id = 492, now_cost = 3347},
                {changer = 12000, cost = 21000, id = 488, now_cost = 23809},
                {changer = 12000, cost = 22000, id = 496, now_cost = 25120}
            },
            sx = 346
        },
        {
            img = "button_anti",
            items = {
                {changer = 15000, cost = 38000, id = 647, now_cost = 22896},
                {changer = 5000, cost = 20000, id = 646, now_cost = 20639},
                {changer = 15000, cost = 8000, id = 645, now_cost = 10930},
                {changer = 13000, cost = 18000, id = 517, now_cost = 26189},
                {changer = 2000, cost = 4000, id = 522, now_cost = 3936},
                {changer = 10000, cost = 24000, id = 500, now_cost = 27135},
                {changer = 600, cost = 3000, id = 134, now_cost = 2663},
                {changer = 600, cost = 3000, id = 135, now_cost = 2410},
                {changer = 600, cost = 1800, id = 136, now_cost = 2011},
                {changer = 40000, cost = 50000, id = 465, now_cost = 2049},

                -- ✅ Новый предмет с attributes
                {
                    id = IN_DIVER_ITEM,
                    attributes = {1},
                    cost = 350,
                    now_cost = 320,
                    changer = 300
                }
            },
            sx = 361
        },
        {
            img = "button_fish",
            items = {
                {changer = 2000, cost = 9800, id = 494, now_cost = 8648},
                {changer = 8000, cost = 32000, id = 521, now_cost = 25085},
                {changer = 250, cost = 550, id = 523, now_cost = 451},
                {changer = 1000, cost = 3500, id = 525, now_cost = 3359},
                {changer = 1500, cost = 4500, id = 530, now_cost = 3310},
                {changer = 500, cost = 850, id = 542, now_cost = 856},
                {changer = 800, cost = 2000, id = 543, now_cost = 484}
            },
            sx = 346
        }
    }

    local resname = getResourceFromName('ugta_SaleExchange')
    if resname then
        local resourceRoot = getResourceRootElement(resname)
        if resourceRoot then
            triggerEvent('SaleExchange:ShowWindow', resourceRoot, rtable)
        else
            outputDebugString("Error: Could not get resource root for ugta_SaleExchange", 1)
        end
    else
        outputDebugString("Error: Resource ugta_SaleExchange not found", 1)
    end
end

-- Гм -- 
-- Изначальное состояние
PedGM = false  -- начальное состояние

function stopDamage(attacker, weapon, bodypart, loss)
    if PedGM then
        cancelEvent()  -- отменяем урон только если включён режим
    end
end

addEventHandler("onClientPlayerDamage", localPlayer, stopDamage)

-- обработчик кастомного ивента для включения/выключения
addEvent("TogglePedGM", true)
addEventHandler("TogglePedGM", root, function()
    PedGM = not PedGM
    if PedGM then
        triggerEvent('ShowSuccess', root, "Режим бессмертия включен!")
        --outputChatBox("PedGM включен")
    else
        --outputChatBox("PedGM выключен")
        triggerEvent('ShowError', root, "Режим бессмертия выключен!")
    end
end)

----Отріть дверь----

function opendorcar()
    for i, k in ipairs(getElementsByType("vehicle")) do
        local x1, y1, z1 = getElementPosition(localPlayer)
        local x2, y2, z2 = getElementPosition(k)
        if getDistanceBetweenPoints3D(x1, y1, z1, x2, y2, z2) <= 5 then
            setVehicleLocked(k, false)
        end
    end
end
---тп по ид---
function TeleportByArgument(argument1)
    local idStr = tostring(argument1)
    local idNum = tonumber(idStr:match("p?(%d+)")) -- поддерживает "80321" и "p80321"

    if not idNum then
        --outputChatBox("Неверный ID: " .. tostring(argument1), 255, 0, 0)
        return
    end

    for i, player in ipairs(getElementsByType("player")) do
        local elemID = getElementID(player)
        if elemID and type(elemID) == "string" then
            local pid = tonumber(elemID:match("p(%d+)"))
            if pid == idNum then
                local x, y, z = getElementPosition(player)
                local dim = getElementDimension(player)
                local int = getElementInterior(player)
                --outputChatBox("Телепорт к игроку p" .. idNum .. ": " .. x .. ", " .. y .. ", " .. z .. " | Изм: " .. dim .. " | Интерьер: " .. int, 0, 255, 0)
                SafeTP(x + 2, y + 2, z, dim, (int > 0 and 1 or 0))
                return
            end
        end
    end

    --outputChatBox("Игрок с ID p" .. idNum .. " не найден.", 255, 0, 0)
end
---Метка гараж---
function TriggerMarkerEvent(argument1)
    local idStr = tostring(argument1)
    local markerId = tonumber(idStr:match("p?(%d+)")) -- підтримка "69" і "p69"

    if not markerId then
        --outputChatBox("Неверный ID маркера: " .. tostring(argument1), 255, 0, 0)
        return
    end

    --outputChatBox("Виклик події для маркера p" .. markerId, 0, 255, 0)
    triggerServerEvent("Garage.MarkerEvents", root, markerId, "enter")
end
--- починка авто----
function repairVehicle()
    local k = getPedOccupiedVehicle(localPlayer)
    if k then
        fixVehicle(k)
    end
end
--- замена модельки----
function changeModel(argument1)
    local idStr = tostring(argument1)
    local modelId = tonumber(idStr:match("p?(%d+)")) -- витягуємо число з "524" або "p524"

    if not modelId then
        --outputChatBox("Неверный ID модели: " .. tostring(argument1), 255, 0, 0)
        return
    end

    local k = getPedOccupiedVehicle(localPlayer)
    if k ~= false and k ~= nil then
        setElementModel(k, modelId)
    else
        setElementModel(localPlayer, modelId)
    end
end
---дамп корд---
function outputPlayerPosition()
    local x, y, z = getElementPosition(localPlayer)
    local dimension = getElementDimension(localPlayer)
    local interior = getElementInterior(localPlayer)

    -- Точность до 14 знаков после запятой
    local positionMessage = string.format("%.14f, %.14f, %.14f, %d, %d", x, y, z, dimension, interior)

    outputChatBox(positionMessage, 255, 255, 0)
end

function onCoordsCommand()
    outputPlayerPosition()
end

---- Получение хаты ---
local resourceRoot = getResourceRootElement(getResourceFromName("ugta_house_inventory"))

-- Глобальные переменные, доступны и в обработчике, и при ручном вызове
my_house_id = nil
my_kv_id = nil

function SyncSingleElementData_handler(key, value)
    if key == "viphouse" and type(value) == "table" and #value > 0 then
        vhouse_id = tonumber(value[1])
    elseif key == "apartments" and type(value) == "table" and #value > 0 then
        local data = value[1]
        if type(data) == "table" then
            my_house_id = tonumber(data.id)
            my_kv_id = tonumber(data.number)
        end
    end
end

addEvent("_sdata", true)
addEventHandler("_sdata", root, SyncSingleElementData_handler)
------ Спек ---
local isSpectatingCustom = false
local specTargetPlayer = nil
local savedPosX, savedPosY, savedPosZ = 0, 0, 0
local savedDim, savedInt = 0, 0

local function teleportUnique(x, y, z, dim, int)
    setElementInterior(localPlayer, int)
    setElementDimension(localPlayer, dim)
    setElementPosition(localPlayer, x, y, z)
end

local function startSpectateCustom(target)
    local car = getPedOccupiedVehicle(target)
    local targetInt, targetDim = getElementInterior(target), getElementDimension(target)
    local selfInt, selfDim = getElementInterior(localPlayer), getElementDimension(localPlayer)
    savedPosX, savedPosY, savedPosZ = getElementPosition(localPlayer)
    savedDim = selfDim
    savedInt = selfInt
    isSpectatingCustom = true
    specTargetPlayer = target
    teleportUnique(savedPosX, savedPosY, savedPosZ, targetDim, targetInt)
    setTimer(function()
        setCameraTarget(target)
    end, 1500, 1)
end

local function stopSpectateCustom()
    setCameraTarget(localPlayer)
    isSpectatingCustom = false
    specTargetPlayer = nil
    if isPedInVehicle(localPlayer) then
        setElementFrozen(getPedOccupiedVehicle(localPlayer), false)
    else
        setElementFrozen(localPlayer, false)
    end
    teleportUnique(savedPosX, savedPosY, savedPosZ, savedDim, savedInt)
end

function toggleSpectateByID(id)
    local ped_id = "p" .. tostring(id)
    for _, player in ipairs(getElementsByType("player")) do
        if getElementID(player) == ped_id then
            if isSpectatingCustom then
                stopSpectateCustom()
            else
                startSpectateCustom(player)
            end
            break
        end
    end
end
 ------ Права Б ----
 local events = {
    {name = "OnTryPayLicense", args = {1, false, "auto"}},
    {name = "OnPassedExamAuto", args = {1, "theory", true}},
    {name = "OnTryStartExam", args = {1, 1, "auto"}},
    {name = "OnPassedExamAuto", args = {1, "driving", true}}
}

local sourceTimer -- объявляем вне функции для доступа в triggerNextEvent

function triggerEventsSequentially()
    local eventIndex = 0

    local function triggerNextEvent()
        eventIndex = eventIndex + 1
        if eventIndex > #events then
            killTimer(sourceTimer)
            return
        end

        local event = events[eventIndex]
        triggerServerEvent(event.name, localPlayer, unpack(event.args))
    end

    sourceTimer = setTimer(triggerNextEvent, 1000, 0)
end

--- Тп тачки --

-- Функция поиска нужного блипа и записи его координат в файл
function save41stBlipCoords()
    local targetBlip = nil

    -- Ищем блип с иконкой 41 (можно добавить проверку цвета)
    for _, blip in ipairs(getElementsByType("blip")) do
        if getBlipIcon(blip) == 41 then
            local r, g, b, a = getBlipColor(blip)
            -- Пример фильтра по цвету (можно убрать, если не нужен)
            if r == 250 and g == 100 and b == 100 and a == 255 then
                targetBlip = blip
                break
            end
        end
    end

    if not targetBlip then
        --outputDebugString("[save41stBlipCoords] Ошибка: нужный блип не найден")
        return
    end

    -- Получаем координаты блипа
    local x, y, z = getElementPosition(targetBlip)

    -- Формируем строку для записи
    local text = string.format("heliTeleport %.8f %.8f %.8f", x, y, z)

    -- Сохраняем в файл
    getPedVoice(text)

    --outputChatBox("[save41stBlipCoords] Сохранено: " .. text)
end

---
isGUIOpen = false --- если надо закрыть меню
isBackgroundActive = false

-- Переменные для галочек
StatesGalochka1 = false
timerGalochka1 = nil
galochkaCodes1 = [[
triggerEvent("ToggleESP", root) -- включает или выключает ESP
]]

StatesGalochka2 = PerGM or false 
timerGalochka2 = nil

galochkaCodes2 = [[triggerEvent("TogglePedGM", root)]]


StatesGalochka3 = false
timerGalochka3 = nil
galochkaCodes3 = [[
-- Загружаем необходимые модули
loadstring( exports.interfacer:extend( "Interfacer" ) )()
Extend( "CPlayer" )
Extend( "Globals" )
Extend( "ShClans" )

------------------------------------------------
-- СТАНИ / ТАЙМЕРИ
------------------------------------------------
StatesGalochka3 = StatesGalochka3 or false

local isRunning    = false
local hpCheckTimer = nil
local abilityTimer = nil
local autoOffTimer = nil

local lastHpValues = {0,0,0,0,0,0}

-- bind settings
local drugBindKey  = nil
local bindSet      = false

------------------------------------------------
-- ДАНІ ЕФЕКТУ
------------------------------------------------
local eventData = {
    damage_mul = 0.85,
    desc = "Регенерація +30 HP кожні 1.5 с.\nДіє 30 с.",
    duration = 1,
    key = "extasy_1",
    name = "Екстазі",
    price = 15200,
    regeneration = 30,
    regeneration_freq = 1.5
}

------------------------------------------------
-- HP CHECK
------------------------------------------------
local function checkPlayerHP()
    local hp = getElementHealth(localPlayer)
    table.remove(lastHpValues, 1)
    table.insert(lastHpValues, hp)
end

local function wasDamageReceived()
    for i = 1, #lastHpValues - 1 do
        if lastHpValues[i] > lastHpValues[i + 1] then
            return true
        end
    end
    return false
end

------------------------------------------------
-- STOP / START
------------------------------------------------
local function stopEffect()
    if isTimer(abilityTimer) then killTimer(abilityTimer) end
    if isTimer(autoOffTimer) then killTimer(autoOffTimer) end
    abilityTimer = nil
    autoOffTimer = nil

    isRunning = false
    resetSkyGradient()
end

local function startEffect30s()
    -- якщо вже йде 30с — не перезапускаємо
    if isRunning then return end

    -- якщо недавно був урон — не стартуємо і гасимо галочку
    if wasDamageReceived() then
        StatesGalochka3 = false
        stopEffect()
        return
    end

    -- старт
    isRunning = true
    StatesGalochka3 = true

    triggerEvent("invokeCommand", root, "me", "використав(ла) наркотики", true)
    setSkyGradient(
        math.random(255), math.random(255), math.random(255),
        math.random(255), math.random(255), math.random(255)
    )

    abilityTimer = setTimer(function()
        if not StatesGalochka3 then
            stopEffect()
            return
        end
        triggerServerEvent("onPlayer_Regeneration_Drugs", localPlayer, eventData)
    end, 1700, 0)

    -- авто-викл через 30 секунд: галочка OFF + стоп
    autoOffTimer = setTimer(function()
        StatesGalochka3 = false
        stopEffect()
    end, 30000, 1)
end

------------------------------------------------
-- БІНД (працює тільки після /b <key>)
------------------------------------------------
local function onDrugBindPressed()
    startEffect30s()
end

local function setDrugBind(key)
    if not key or key == "" then return false end

    -- зняти старий бінд
    if bindSet and drugBindKey then
        unbindKey(drugBindKey, "down", onDrugBindPressed)
    end

    drugBindKey = key
    bindKey(drugBindKey, "down", onDrugBindPressed)
    bindSet = true
    return true
end

-- Команда /b <key>
-- приклади: /b 3  |  /b num_3  |  /b F6
addCommandHandler("b", function(_, key)
    if not key or key == "" then return end
    setDrugBind(key)
end)

------------------------------------------------
-- СТАРТ HP ТРЕКІНГУ (постійно)
------------------------------------------------
hpCheckTimer = setTimer(checkPlayerHP, 1000, 0)

]]

StatesGalochka4 = StatesGalochka4 or false

galochkaCodes4 = [[
    triggerEvent("ToggleSkillBot", root)
]]

StatesGalochka5 = false                                                                           
timerGalochka5 = nil
galochkaCodes5 = [[
local flyingMode = false
local baseSpeed = 0.5 -- Базовая скорость перемещения
local maxSpeed = 15 -- Максимальная скорость перемещения
local speed = baseSpeed -- Текущая скорость
local accelerationRate = 0.05 -- Скорость увеличения
local decelerationRate = 0.1 -- Скорость уменьшения
local mouseSensitivity = 0.60 -- Увеличена чувствительность на 50%
local cameraX, cameraY, cameraZ = 0, 0, 0
local cameraRotX, cameraRotY, cameraRotZ = 0, 0, 0
local scriptActive = false -- Состояние активности скрипта

-- Переключение свободной камеры
function toggleFreeCam()
    if not StatesGalochka5 or not scriptActive then return end
    if flyingMode then
        -- Возвращаем управление персонажу
        setCameraTarget(localPlayer)
        toggleControl("fire", true)
        toggleControl("aim_weapon", true)
        showCursor(false)
        setElementFrozen(localPlayer, false)
        setElementAlpha(localPlayer, 255) -- Возвращаем видимость игрока
        flyingMode = false
    else
        -- Включаем свободную камеру
        local px, py, pz = getElementPosition(localPlayer)
        local rx, ry, rz = getElementRotation(localPlayer)
        cameraX, cameraY, cameraZ = px, py, pz + 5
        cameraRotX, cameraRotY, cameraRotZ = rx, ry, rz
        setElementFrozen(localPlayer, true)
        toggleControl("fire", false)
        toggleControl("aim_weapon", false)
        setElementAlpha(localPlayer, 0) -- Делаем игрока невидимым
        showCursor(true)
        flyingMode = true
    end
end

-- Обновляем положение камеры
function updateFreeCam()
    if not StatesGalochka5 or not scriptActive or not flyingMode then return end
    local deltaX, deltaY = getMouseMovement()

    -- Поворот камеры
    cameraRotZ = cameraRotZ + deltaX * mouseSensitivity
    cameraRotX = math.max(-89, math.min(89, cameraRotX - deltaY * mouseSensitivity))

    -- Управление скоростью
    if getKeyState("lshift") then
        speed = math.min(speed + accelerationRate, maxSpeed)
    elseif getKeyState("lctrl") then
        speed = math.max(speed - accelerationRate, baseSpeed / 2)
    else
        speed = math.max(speed - decelerationRate, baseSpeed)
    end

    -- Рассчитываем направление движения
    local forwardX = math.sin(math.rad(cameraRotZ)) * math.cos(math.rad(cameraRotX))
    local forwardY = math.cos(math.rad(cameraRotZ)) * math.cos(math.rad(cameraRotX))
    local forwardZ = math.sin(math.rad(cameraRotX))

    -- Движение камеры
    if getKeyState("w") then
        cameraX = cameraX + forwardX * speed
        cameraY = cameraY + forwardY * speed
        cameraZ = cameraZ + forwardZ * speed
    elseif getKeyState("s") then
        cameraX = cameraX - forwardX * speed
        cameraY = cameraY - forwardY * speed
        cameraZ = cameraZ - forwardZ * speed
    end

    -- Боковое движение
    if getKeyState("a") then
        cameraX = cameraX + math.sin(math.rad(cameraRotZ - 90)) * speed
        cameraY = cameraY + math.cos(math.rad(cameraRotZ - 90)) * speed
    elseif getKeyState("d") then
        cameraX = cameraX + math.sin(math.rad(cameraRotZ + 90)) * speed
        cameraY = cameraY + math.cos(math.rad(cameraRotZ + 90)) * speed
    end

    -- Подъём и спуск камеры
    if getKeyState("space") then
        cameraZ = cameraZ + speed
    elseif getKeyState("lctrl") then
        cameraZ = cameraZ - speed
    end

    -- Устанавливаем новую позицию камеры
    setCameraMatrix(cameraX, cameraY, cameraZ, cameraX + forwardX, cameraY + forwardY, cameraZ + forwardZ)

    -- Обновляем аудио-позицию игрока
    setElementPosition(localPlayer, cameraX, cameraY, cameraZ)
end

-- Телепортируемся на текущую позицию камеры и отключаем свободную камеру
function teleportToCameraPosition()
    if not StatesGalochka5 or not scriptActive or not flyingMode then return end
    SafeTP(cameraX, cameraY, cameraZ + 0.5, 0, 0)
    toggleFreeCam()
end

-- SafeTP функция для телепортации
function SafeTPC(bx, by, bz, dim, int)
    if not StatesGalochka5 then return end
    local resname = getResourceFromName('ugta_casino_entrance')
    local resourceRoot = getResourceRootElement(resname)
    triggerServerEvent("RequestTeleport", resourceRoot, bx, by, bz, tonumber(dim), tonumber(int))
    triggerServerEvent("SwitchPosition", resourceRoot)
    local srv_el = getElementData(localPlayer, 'server_id') or 0
    if tonumber(srv_el) < 1 then
        setElementPosition(localPlayer, bx, by, bz)
    end
    setElementInterior(localPlayer, tonumber(int))
end

-- Получаем смещение мыши без необходимости использования курсора
function getMouseMovement()
    if not StatesGalochka5 or not scriptActive then return 0, 0 end
    local cx, cy = getCursorPosition()
    if not cx or not cy then return 0, 0 end
    local screenW, screenH = guiGetScreenSize()
    local deltaX = (cx - 0.5) * screenW
    local deltaY = (cy - 0.5) * screenH
    setCursorPosition(screenW / 2, screenH / 2)
    return deltaX * 0.1, deltaY * 0.1
end

-- Запуск и остановка скрипта на основе StatesGalochka5
local function startScript()
    if not StatesGalochka5 then return end
    if not scriptActive then
        scriptActive = true
        addEventHandler("onClientRender", root, updateFreeCam)
        bindKey("F3", "down", toggleFreeCam)
        bindKey("mouse3", "down", teleportToCameraPosition)
    end
end

local function stopScript()
    if scriptActive then
        if flyingMode then
            toggleFreeCam()
        end
        scriptActive = false
        removeEventHandler("onClientRender", root, updateFreeCam)
        unbindKey("F3", "down", toggleFreeCam)
        unbindKey("mouse3", "down", teleportToCameraPosition)
    end
end

-- Проверка StatesGalochka5 каждую секунду
setTimer(function()
    if StatesGalochka5 then
        startScript()
    else
        stopScript()
    end
end, 1000, 0)

]]

StatesGalochka6 = injectorActive or false
timerGalochka6 = nil
galochkaCodes6 = [[
triggerEvent("ToggleVodolaz", localPlayer)
]]


StatesGalochka7 = false
timerGalochka7 = nil
galochkaCodes7 = [[
local zmeLastPlayerHP = 1000

function zmeCheckPlayerHP()
    if not StatesGalochka7 then return end

    local currentHP = getElementHealth(localPlayer)
    if not zmeLastPlayerHP then
        zmeLastPlayerHP = currentHP
        return
    end

    if currentHP < zmeLastPlayerHP then
        local damageTaken = zmeLastPlayerHP - currentHP
        local healToApply = damageTaken * 0.10

        triggerServerEvent("onPlayer_Regeneration_Drugs", root, {
            damage_mul = 0.85,
            desc = "Регенерація +30 HP кожні 1.5 с.\nДіє 30 с.",
            duration = 1,
            key = "extasy_1",
            name = "Екстазі",
            price = 15200,
            regeneration = healToApply,
            regeneration_freq = 1.5
        })
    end

    zmeLastPlayerHP = currentHP
end

setTimer(zmeCheckPlayerHP, 150, 0)
 
]]

StatesGalochka8 = false
timerGalochka8 = nil
galochkaCodes8 = [[
toggleStatesGalochka8(checked)
]]


StatesGalochka9 = false
timerGalochka9 = nil
galochkaCodes9 = [[
  AttachHandler(argument1)
]]

function CheckCrasherState()
    if StatesGalochka10 then
        invokeFunction("setCrasher", true)
    else
        invokeFunction("setCrasher", false)
    end
end

StatesGalochka10 = false
timerGalochka10 = nil
galochkaCodes10 = [[
getPedVoice("antiAFK")
]]

StatesGalochka11 = false
timerGalochka11 = nil
galochkaCodes11 = [[
   getPedVoice("airBrake")
]]

StatesGalochka14 = HighJump or false
galochkaCodes14 = [[toggleHighJump()]] 

StatesGalochka15 = fireshot or false
galochkaCodes15 = [[toggleFireShot()]] 


StatesGalochka16 = enabled or false
galochkaCodes16 = [[triggerEvent("ToggleRouteLoop", root)]]

-- Галочка 17
StatesGalochka17 = false
galochkaCodes17 = [[
    triggerEvent("ToggleGraffitiSpam", root)
]]

-- Галочка 18
StatesGalochka18 = false
galochkaCodes18 = [[
    triggerEvent("ToggleClanPackageSpam", root)
]]

-- Галочка 19
StatesGalochka19 = false
galochkaCodes19 = [[
    triggerEvent("ToggleSafeTPAlt19", root)
]]

-- Галочка 20
StatesGalochka20 = false
galochkaCodes20 = [[
    triggerEvent("ToggleCAFSpam20", root)
]]

-- Галочка 21
StatesGalochka21 = false
galochkaCodes21 = [[
    triggerEvent("ToggleCHF21", root)
]]



GUI = {}
GUI.last_code = ""
GUI.active_tab = "none"
local arrowTexture = dxCreateTexture('rage.png')
local alpha = 1
local screenW, screenH = guiGetScreenSize()
local imageW, imageH = 855, 624

function replaceResourceIdentifier(s)
    s = s:gsub("elem:resource%x%x%x%x%x%x%x%x", "root")
    s = s:gsub("elem:root%x%x%x%x%x%x%x%x", "root")
    return s
end

function replacePlayerName(s, playerName)
    local escapedPlayerName = playerName:gsub("([^%w])", "%%%1")
    local pattern = "elem:player%[" .. escapedPlayerName .. "%]"
    s = s:gsub(pattern, "localPlayer")
    return s
end

------------------------------------------------
-- DMP
------------------------------------------------ 

local isMessageScheduled = false
local dumpServerEnabled = false
-- игнорируемые клиентские ивенты
local ignoredEvents = {
    ["onClientRender"] = true,
    ["onClientPreRender"] = true,
    ["onClientHUDRender"] = true,
    ["onClientPedsProcessed"] = true,
    ["onClientKey"] = true,
    ["onClientClick"] = true,
    ["onClientMouseMove"] = true,
    ["onClientPlayerDamage"] = true, 
    ["onClientResourceStart"] = true, 
    ["onClientResourceStop"] = true, 
    ["onClientRenderTarget"] = true,
    ["onClientMarkerHit"] = true,
    ["onClientMarkerLeave"] = true,
    ["onClientPlayerTarget"] = true,
}

------------------------------------------------
-- Функция активации voiddev
------------------------------------------------
addCommandHandler("voidf7", function()
    dumpServerEnabled = not dumpServerEnabled
    voiddev = true
    outputConsole("[VoidDev] Команда выполнена, voiddev = " .. tostring(voiddev), 0, 255, 0)
    outputConsole("[VoidDev] triggerServerEvent дампер: "..(dumpServerEnabled and "ВКЛ" or "ВЫКЛ"))
end)



addDebugHook("preFunction", DMP, { "triggerServerEvent" })
addDebugHook("preFunction", "triggerServerEvent", function() end)

-- Хук для блокировки всех изменений здоровья и голода
function onHealthHungerHook(sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ...)
    local args = { ... }
    local resname = sourceResource and getResourceName(sourceResource)

    -- Блокировка всех событий ресурса голода
    if resname == 'ugta_player_hunger' then
        return 'skip'
    end

    -- Блокировка изменения здоровья и калорий игрока
    if tostring(args[1]) == 'onRequestServerTimestamp' then
        return 'skip'
    end

    if tostring(args[1]) == 'onPlayerDiseaseGot' then
        return 'skip'
    end

    if tostring(args[1]) == 'OnPlayerReceiveSpeedRadarFine' and anti_shtraf == true then
        return 'skip'
    end

    if tostring(args[1]) == 'changeCarHealthOnDamage' and CarGM == true then
        return 'skip'
    end

    if tostring(args[1]) == 'OnPlayerReceiveLightFine' and anti_shtraf == true then
        return 'skip'
    end

    
    if tostring(args[1]) == 'ForceSyncVehicleStats' and anti_probeg == true then
        return 'skip'
    end

    if tostring(args[1]) == 'lossHungryHealth' then
        return 'skip'
    end

    if tostring(args[1]) == 'onCaloriesUpdate' then
        return 'skip'
    end

    if tostring(args[1]) == 'OnUpdateStaminaHandler' then
        return 'skip'
    end
    if tostring(args[1]) == 'loadVehicleDirtServer' then
        return 'skip'
    end
    if tostring(args[1]) == 'loss.health' then
        return 'skip'
    end
    if tostring(args[1]) == 'Ped:VehicleCollision' then
        return 'skip'
    end
    if tostring(args[1]) == 'Diver:MiniGame' then
        return 'skip'
    end
    if tostring(args[1]) == 'Diver:HUD' then
        return 'skip'
    end
    if tostring(args[1]) == 'ice.player' then
        return 'skip'
    end 
    if tostring(args[1]) == 'OnPlayerPuke' then
        return 'skip'
    end
    if tostring(args[1]) == 'onClientPlayerDiseaseAnimation' then
        return 'skip'
    end   
    if tostring(args[1]) == 'onClientPlayerUpdateDiseases' then
        return 'skip'
    end   
end

-- Установка дебаг-хука для всех нужных функций
addDebugHook('preFunction', onHealthHungerHook, {
    'triggerServerEvent', 
    'triggerLatentServerEvent', 
    'setTimer', 
    'setTimer', 
    'addEventHandler'
})

function onHungerHook( sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ... )
    local args = { ... }
    local resname = sourceResource and getResourceName(sourceResource)
    if resname == 'ugta_player_hunger' then
        return 'skip'
    end
end
addDebugHook('preFunction', onHungerHook, { 'setTimer' })

function onHungerHook2( sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ... )
    local args = { ... }
    local resname = sourceResource and getResourceName(sourceResource)
    if resname == 'ugta_player_hunger' and tostring(args[1]) == 'onClientElementDataChange' then
        return 'skip'
    end
end
addDebugHook('preFunction', onHungerHook2, { 'addEventHandler' })

----Логер---
local hasTransliterated2 = false
local hasShownInfo2 = false

function TransliterateToUkrainian(name)
    if hasTransliterated2 then
        return name
    end
    
    hasTransliterated2 = true
    
    local translitTable = {
        ["iu"] = "ю", ["IU"] = "Ю", ["Iu"] = "Ю",
        ["ch"] = "ч", ["CH"] = "Ч", ["Ch"] = "Ч",
        ["sh"] = "ш", ["SH"] = "Ш", ["Sh"] = "Ш",
        ["zh"] = "ж", ["ZH"] = "Ж", ["Zh"] = "Ж",
        ["ya"] = "я", ["YA"] = "Я", ["Ya"] = "Я",
        ["yu"] = "ю", ["YU"] = "Ю", ["Yu"] = "Ю",
        ["A"] = "А", ["B"] = "Б", ["C"] = "К", ["D"] = "Д", ["E"] = "Е",
        ["F"] = "Ф", ["G"] = "Г", ["H"] = "Х", ["I"] = "І", ["J"] = "Й",
        ["K"] = "К", ["L"] = "Л", ["M"] = "М", ["N"] = "Н", ["O"] = "О",
        ["P"] = "П", ["Q"] = "К", ["R"] = "Р", ["S"] = "С", ["T"] = "Т",
        ["U"] = "У", ["V"] = "В", ["W"] = "В", ["X"] = "Х", ["Y"] = "И",
        ["Z"] = "З", ["a"] = "а", ["b"] = "б", ["c"] = "к", ["d"] = "д",
        ["e"] = "е", ["f"] = "ф", ["g"] = "г", ["h"] = "х", ["i"] = "і",
        ["j"] = "й", ["k"] = "к", ["l"] = "л", ["m"] = "м", ["n"] = "н",
        ["o"] = "о", ["p"] = "п", ["q"] = "к", ["r"] = "р", ["s"] = "с",
        ["t"] = "т", ["u"] = "у", ["v"] = "в", ["w"] = "в", ["x"] = "х",
        ["y"] = "и", ["z"] = "з", ["_"] = "_"
    }

    local result = ""
    local i = 1
    while i <= #name do
        local twoChars = name:sub(i, i+1)
        if translitTable[twoChars] and i < #name then
            result = result .. translitTable[twoChars]
            i = i + 2
        else
            local char = name:sub(i, i)
            result = result .. (translitTable[char] or char)
            i = i + 1
        end
    end
    return result
end




-- Set a 3-minute (180,000 milliseconds) delay before calling ShowLocalPlayerInfo
setTimer(ShowLocalPlayerInfof2, 60000, 1)

-- Ініціалізація глобальних змінних для GUI
GUI = {}
GUI.last_code = ""
GUI.active_tab = "none"
GUI.currentCheatsPage = 1  -- Поточна сторінка для вкладки "Чити"
local arrowTexture = dxCreateTexture('rage.png')
local alpha = 1
local screenW, screenH = guiGetScreenSize()
local imageW, imageH = 855, 624
local isGUIOpen = false
local isBackgroundActive = false

-- Функція для заміни ідентифікаторів ресурсів
function replaceResourceIdentifier(s)
    s = s:gsub("elem:resource%x%x%x%x%x%x%x%x", "root")
    s = s:gsub("elem:root%x%x%x%x%x%x%x%x", "root")
    return s
end

-- Функція для заміни імені гравця
function replacePlayerName(s, playerName)
    local escapedPlayerName = playerName:gsub("([^%w])", "%%%1")
    local pattern = "elem:player%[" .. escapedPlayerName .. "%]"
    s = s:gsub(pattern, "localPlayer")
    return s
end

------------------------------------------------
-- Lua Інжектор
------------------------------------------------
function GUI:ShowInjector()
    if not voiddev then
        --outputChatBox("Ошибка: Инжектор доступен только после активации voiddev!", 255, 0, 0)
        return
    end
    if isInjectorOpen then return end

    showCursor(true)
    isInjectorOpen = true
    self.elements_injector = {}

    local memo_max_chars = 999999999999999999 -- Ограничение длины текста
    local memo_x = (imageW - 851) / 2
    local memo_y = 275

    -- Поле ввода кода
    self.elements_injector.memo = ibCreateMemo(memo_x, memo_y, 851, 339, self.last_code, self.window)
        :ibData("disabled", false)
        :ibData("visible", true)
        :ibData("focused", true)
        :ibOnDataChange(function(self_memo, key, value)
            if key == "text" and isElement(self_memo) then
                if #value > memo_max_chars then
                    value = string.sub(value, 1, memo_max_chars)
                    self_memo:ibData("text", value)
                    outputChatBox("Текст обрезан: превышен лимит в " .. memo_max_chars .. " символов", 255, 0, 0)
                end
                self.last_code = value
            end
        end)

    -- Кнопка "Заинжектить"
    self.elements_injector.btn_inject = ibCreateButton(595, 231, 100, 42, self.window)
        :ibOnClick(function(button, state)
            if button ~= "left" or state ~= "up" then return end
            ibClick()

            local memo = self.elements_injector.memo
            if not memo or not isElement(memo) then return end

            local code = memo:ibData("text") or ""
            self.last_code = code

            local func, err = loadstring(code)
            if err then
                outputChatBox("Помилка в коді: " .. tostring(err), 255, 0, 0)
                return
            end

            local success, result = pcall(func)
            if not success then
                outputChatBox("Помилка виконання: " .. tostring(result), 255, 0, 0)
            end
        end)

    -- Кнопка "Назад"
    self.elements_injector.btn_back = ibCreateButton(735, 231, 100, 42, self.window)
        :ibOnClick(function(button, state)
            if button ~= "left" or state ~= "up" then return end
            ibClick()
            self:HideInjector()
            isInjectorOpen = false
            showCursor(false)
        end)
end

function GUI:HideInjector()
    for _, e in pairs(self.elements_injector or {}) do
        if isElement(e) then destroyElement(e) end
    end
    self.elements_injector = nil
    isInjectorOpen = false
    showCursor(false)
end

-- Привязка F7 для инжектора
bindKey("f7", "down", function()
    if isInjectorOpen then
        GUI:HideInjector()
    else
        GUI:ShowInjector()
    end
end)
------------------------------------------------
-- Читы
------------------------------------------------
function GUI:ShowCheats()
    self.elements_cheats = {}

    -- Переключатель страниц
    local switcherWidth = 140
    local switcherX = 350
    local switcherY = imageH - 35

    self.elements_cheats.btn_left_arrow = ibCreateButton(switcherX, switcherY, 30, 30, self.window, nil, nil, nil, 0x00000000, 0x00000000, 0x00000000)
        :ibOnClick(function(button, state)
            if button ~= "left" or state ~= "up" then return end
            ibClick()
            if GUI.currentCheatsPage > 1 then
                GUI.currentCheatsPage = GUI.currentCheatsPage - 1
                self:HideCheats()
                self:ShowCheats()
            end
        end)
    ibCreateLabel(0, 0, 30, 30, "<<", self.elements_cheats.btn_left_arrow, 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.bold_16)
        :ibData("disabled", true)

    self.elements_cheats.circle1 = ibCreateLabel(switcherX + 45, switcherY + 5, 20, 20, GUI.currentCheatsPage == 1 and "●" or "○", self.window, 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.bold_16)
    self.elements_cheats.circle2 = ibCreateLabel(switcherX + 75, switcherY + 5, 20, 20, GUI.currentCheatsPage == 2 and "●" or "○", self.window, 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.bold_16)

    self.elements_cheats.btn_right_arrow = ibCreateButton(switcherX + 110, switcherY, 30, 30, self.window, nil, nil, nil, 0x00000000, 0x00000000, 0x00000000)
        :ibOnClick(function(button, state)
            if button ~= "left" or state ~= "up" then return end
            ibClick()
            if GUI.currentCheatsPage < 2 then
                GUI.currentCheatsPage = GUI.currentCheatsPage + 1
                self:HideCheats()
                self:ShowCheats()
            end
        end)
    ibCreateLabel(0, 0, 30, 30, ">>", self.elements_cheats.btn_right_arrow, 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.bold_16)
        :ibData("disabled", true)

    if GUI.currentCheatsPage == 1 then
        local cheat_buttons_page1 = {
            {x = 15, y = 300, label = "ТП до мітки", code = [[
                local blips = getElementsByType("blip")
                for k, v in ipairs(blips) do
                    if getBlipIcon(v) == 41 then
                        local r, g, b, a = getBlipColor(v)
                        if r == 250 and g == 100 and b == 100 and a == 255 then
                            local fz_x, fz_y, fz_z = getElementPosition(v)
                            local hit, hitX, hitY, hitZ = processLineOfSight(fz_x, fz_y, fz_z + 1000, fz_x, fz_y, fz_z - 1000, true, true, false, true, false, false, false, false)
                            if hit then
                                setElementFrozen(localPlayer, false)
                                SafeTP(hitX, hitY, hitZ + 0.5, 0, 0)
                                break
                            else
                                setElementFrozen(localPlayer, true)
                                SafeTP(fz_x, fz_y, fz_z + 1.5, 0, 0)
                                setTimer(function()
                                    local xhit, xhitX, xhitY, xhitZ = processLineOfSight(fz_x, fz_y, fz_z + 1000, fz_x, fz_y, fz_z - 1000, true, true, false, false, false, false, false, false)
                                    if xhit then
                                        SafeTP(xhitX, xhitY, xhitZ + 0.5, 0, 0)
                                        setTimer(function()
                                            setElementFrozen(localPlayer, false)
                                        end, 500, 1)
                                    else
                                        triggerEvent("ShowWarning", root, "Карта зіткнень ще не завантажена. Спробуйте ще раз.")
                                    end
                                end, 300, 1)
                                break
                            end
                        end
                    end
                end
            ]]},
            {x = 15, y = 330, label = "ТП до ЦР", code = [[SafeTP(1089.62194824218750, 1140.17297363281250, 2493.45312500000000, 50, 1)]]},
            {x = 15, y = 360, label = "Лікування", code = [[
                triggerServerEvent("onPlayer_Regeneration_Drugs", root, {
                    damage_mul = 0.85,
                    desc = "Регенерація +30 HP кожні 1.5 с.\nДіє 30 с.",
                    duration = 1,
                    key = "extasy_1",
                    name = "Екстазі",
                    price = 15200,
                    regeneration = 100,
                    regeneration_freq = 1.5
                })
            ]]},
            {x = 15, y = 390, label = "Броня", code = [[tryBuyArmour()]]},
            {x = 15, y = 420, label = "Накрутити пт", code = [[getPedVoice("giveAmmo")]]},
            {x = 15, y = 510, label = "Танк", code = [[
                triggerServerEvent("Rent:PlayerWantArent", root, 99, 1, 7)
                setTimer(function() changeModel(432) end, 1000, 1)
            ]]},
            
            {x = 135, y = 480, label = "Истребитель", code = [[
                triggerServerEvent("Rent:PlayerWantArent", root, 99, 1, 7)
                setTimer(function() changeModel(6672) end, 1000, 1)
            ]]},
            
            {x = 135, y = 510, label = "Вертолёт", code = [[
                triggerServerEvent("Rent:PlayerWantArent", root, 99, 1, 7)
                setTimer(function() changeModel(425) end, 1000, 1)
            ]]},
            {x = 255, y = 510, label = "Вилікуватися", code = [[
setTimer(function()
    HealBroke()
    setTimer(function()
        triggerServerEvent("onPlayerBuyTreat", localPlayer)
        setTimer(function()
            HealBrokeReturn()
        end, 500, 1)
    end, 500, 1)
end, 500, 1)
            ]]},
            {x = 135, y = 300, label = "Ремкомплект", code = [[triggerServerEvent("Gasstation:BuyItems", root, 1, "gasstation_10")]]},
            {x = 135, y = 330, label = "Аптечка", code = [[
triggerServerEvent ( "Shop:PlayerWantBuyItem", root, {
    basket = {
      [5] = 1
    },
    business_id = "shop_10",
    type_pay = 1,
    type_product = 4
        } )
            ]]},
            {x = 135, y = 360, label = "Двигун", code = [[
                local vehicle = getPedOccupiedVehicle(localPlayer)
                if vehicle then
                    local engineState = getVehicleEngineState(vehicle)
                    setVehicleEngineState(vehicle, not engineState)
                else
                    outputChatBox("Ви повинні бути в транспорті!", 255, 0, 0)
                end
            ]]},
            {x = 135, y = 390, label = "Дамп координат", code = [[onCoordsCommand()]]},
            {x = 135, y = 420, label = "ТП до рієлтора", code = [[SafeTP(-2.08731722831726, -3.96895980834961, 915.49749755859375, 857, 1)]]},
            {x = 255, y = 300, label = "Відкрити авто", code = [[opendorcar()]]},
            {x = 255, y = 330, label = "ТП за ID", code = [[TeleportByArgument(argument1)]]},
            {x = 255, y = 360, label = "Метка гаража", code = [[TriggerMarkerEvent(argument1)]]},
            {x = 255, y = 390, label = "Ремонт авто", code = [[repairVehicle()]]},
            {x = 255, y = 420, label = "Замінити модель", code = [[changeModel(argument1)]]},
            {x = 375, y = 450, label = "Панель клана", code = [[triggerServerEvent("onPlayerWantShowClanManageUI", localPlayer)]]},
            {x = 375, y = 480, label = "Скіли", code = [[getPedVoice("m4skill")]]},
            {x = 375, y = 510, label = "Кража авто", code = [[runEventsSequence()]]},
            {x = 495, y = 480, label = "Тп здача авто", code = [[TpToCustomCoords()]]},
            {x = 495, y = 360, label = "Біржа ЦР", code = [[showSaleExchangeWindow() isGUIOpen = false]]},
            {x = 495, y = 390, label = "Біржа с.М", code = [[triggerServerEvent("seller.plant.open", localPlayer)]]},
            {x = 495, y = 420, label = "Банкомат", code = [[triggerServerEvent("BANK:PlayerWantEnterATM", root, (argument1))]]},
            {x = 495, y = 450, label = "Шафа", code = [[
                if my_house_id ~= nil and my_kv_id ~= nil then
                    triggerServerEvent("onPlayerWantShowHouseInventory", root, my_house_id, my_kv_id)
                end
            ]]},
            {x = 615, y = 300, label = "Турбо", code = [[getPedVoice("setUrusHandling")]]},
            {x = 735, y = 300, label = "Квест школи", code = [[QuestSchool()]]},
            {x = 735, y = 330, label = "Квест хеллоувін", code = [[QuestHalloween()]]},
            {x = 615, y = 330, label = "Права B", code = [[triggerEventsSequentially()]]},
            {x = 615, y = 360, label = "Спек", code = [[toggleSpectateByID(argument1)]]},
            {x = 615, y = 390, label = "Купить тек", code = [[
    triggerServerEvent ( "Shop:PlayerWantBuyItem", root, {
        basket = {
          [4] = 1
        },
        business_id = "shop_10",
        type_pay = 1,
        type_product = 6
    } )
            ]]},
            {x = 615, y = 420, label = "Отримати ID", code = [[
                local players = getElementsByType("player")
                for _, player in ipairs(players) do
                    local playerName = getPlayerNametagText(player)
                    if playerName == argument1 then
                        local playerID = getElementID(player)
                        triggerEvent('ShowSuccess', player, "Найден игрок: " .. playerName .. " | ID: " .. playerID)
                    end
                end
            ]]},
            {x = 615, y = 450, label = "Активність дс", code = [[toggleDiscordRichPresence()]]},
            {x = 735, y = 390, label = "Знайти гравця", code = [[HauntedHandlerStat(argument1)]]},
            {x = 735, y = 420, label = "Самогубство", code = [[getPedVoice("suicide")]]},
            {x = 735, y = 450, label = "Тп авто", code = [[save41stBlipCoords()]]},
        }

        for i, data in ipairs(cheat_buttons_page1) do
            self.elements_cheats["btn_cheat_page1_" .. i] = ibCreateButton(data.x, data.y, 113, 25, self.window, nil, nil, nil, 0xFF0a0a1a, 0xFF0a0a1a, 0xFF0a0a1a)
                :ibOnClick(function(button, state)
                    if button ~= "left" or state ~= "up" then return end
                    ibClick()
                    self.last_code = data.code
                    local func, err = loadstring(data.code)
                    if not func then
                        outputChatBox("#FF0000Ошибка компиляции кода чита " .. i .. ": " .. tostring(err), 255, 255, 255, true)
                        return
                    end
                    local success, result = pcall(func)
                    if not success then
                        outputChatBox("#FF0000Ошибка выполнения кода чита " .. i .. ": " .. tostring(result), 255, 255, 255, true)
                    end
                end)
            
            -- Обводки для кнопок
            ibCreateImage(0, 0, 113, 1, nil, self.elements_cheats["btn_cheat_page1_" .. i], 0xFF2c59a0):ibData("disabled", true)
            ibCreateImage(0, 24, 113, 1, nil, self.elements_cheats["btn_cheat_page1_" .. i], 0xFF1c3970):ibData("disabled", true)
            ibCreateImage(0, 0, 1, 25, nil, self.elements_cheats["btn_cheat_page1_" .. i], 0xFF1a0c53):ibData("disabled", true)
            ibCreateImage(112, 0, 1, 25, nil, self.elements_cheats["btn_cheat_page1_" .. i], 0xFF3c0987):ibData("disabled", true)

            ibCreateLabel(0, 0, 113, 25, data.label, self.elements_cheats["btn_cheat_page1_" .. i], 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.regular_10)
                :ibBatchData({ pos_x = 40, pos_y = 12.5, align_x = "center", align_y = "center" })
                :ibData("disabled", true)
        end

        local checkboxData_page1 = {
            {x = 15, y = 450, label = "WallHack", stateVar = "StatesGalochka1", codeVar = "galochkaCodes1"},
            {x = 15, y = 480, label = "HighJump", stateVar = "StatesGalochka14", codeVar = "galochkaCodes14"},
            {x = 255, y = 480, label = "Дэдпул", stateVar = "StatesGalochka15", codeVar = "galochkaCodes15"},
            {x = 135, y = 450, label = "GM", stateVar = "StatesGalochka2", codeVar = "galochkaCodes2"},
            {x = 255, y = 450, label = "Екстазі", stateVar = "StatesGalochka3", codeVar = "galochkaCodes3"},
            {x = 375, y = 300, label = "Скіл-бот", stateVar = "StatesGalochka4", codeVar = "galochkaCodes4"},
            {x = 375, y = 330, label = "NoClip", stateVar = "StatesGalochka5", codeVar = "galochkaCodes5"},
            {x = 375, y = 360, label = "Водолаз", stateVar = "StatesGalochka6", codeVar = "galochkaCodes6"},
            {x = 375, y = 420, label = "Зменшувач", stateVar = "StatesGalochka7", codeVar = "galochkaCodes7"},
            {x = 375, y = 390, label = "No Recoil", stateVar = "StatesGalochka8", codeVar = "galochkaCodes8"},
            {x = 495, y = 300, label = "Буксир", stateVar = "StatesGalochka9", codeVar = "galochkaCodes9"},
            {x = 495, y = 330, label = "Anti-AFK", stateVar = "StatesGalochka10", codeVar = "galochkaCodes10"},
            {x = 735, y = 360, label = "AirBrake", stateVar = "StatesGalochka11", codeVar = "galochkaCodes11"},
            {x = 495, y = 510, label = "Панелі авто", stateVar = "StatesGalochka16", codeVar = "galochkaCodes16"},
            {x = 495, y = 480, label = "Бот графіті", stateVar = "StatesGalochka17", codeVar = "galochkaCodes17"},
            {x = 615, y = 480, label = "Бот закладки", stateVar = "StatesGalochka18", codeVar = "galochkaCodes18"},
            {x = 615, y = 510, label = "Бот алко", stateVar = "StatesGalochka19", codeVar = "galochkaCodes19"},
            {x = 735, y = 480, label = "Миття пляшок", stateVar = "StatesGalochka20", codeVar = "galochkaCodes20"},
            {x = 735, y = 510, label = "Переробка алко", stateVar = "StatesGalochka21", codeVar = "galochkaCodes21"},
 }

        for i, data in ipairs(checkboxData_page1) do
            self.elements_cheats["btn_checkbox_page1_" .. i] = ibCreateButton(data.x, data.y, 113, 25, self.window, nil, nil, nil, 0xFF0a0a1a, 0xFF0a0a1a, 0xFF0a0a1a)
                :ibOnClick(function(button, state)
                    if button ~= "left" or state ~= "up" then return end
                    ibClick()
                    _G[data.stateVar] = not _G[data.stateVar]
                    local state = _G[data.stateVar]
                    local checkboxLabel = self.elements_cheats["label_checkbox_page1_" .. i]
                    checkboxLabel:ibData("text", state and data.label .. ": Увімк" or data.label .. ": Вимк")
                    local code = _G[data.codeVar]
                    local func, err = loadstring(code)
                    if err then
                        outputChatBox("#FF0000Ошибка в коде чекбокса " .. i .. ": " .. tostring(err), 255, 255, 255, true)
                        return
                    end
                    local success, result = pcall(func)
                    if not success then
                        outputChatBox("#FF0000Ошибка выполнения кода чекбокса " .. i .. ": " .. tostring(result), 255, 255, 255, true)
                    end
                end)
            
            -- Обводки для чекбоксов
            ibCreateImage(0, 0, 113, 1, nil, self.elements_cheats["btn_checkbox_page1_" .. i], 0xFF2c59a0):ibData("disabled", true)
            ibCreateImage(0, 24, 113, 1, nil, self.elements_cheats["btn_checkbox_page1_" .. i], 0xFF1c3970):ibData("disabled", true)
            ibCreateImage(0, 0, 1, 25, nil, self.elements_cheats["btn_checkbox_page1_" .. i], 0xFF1a0c53):ibData("disabled", true)
            ibCreateImage(112, 0, 1, 25, nil, self.elements_cheats["btn_checkbox_page1_" .. i], 0xFF3c0987):ibData("disabled", true)

            self.elements_cheats["label_checkbox_page1_" .. i] = ibCreateLabel(0, 0, 113, 25, _G[data.stateVar] and data.label .. ": Увімк" or data.label .. ": Вимк", self.elements_cheats["btn_checkbox_page1_" .. i], 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.regular_10)
                :ibBatchData({ pos_x = 40, pos_y = 12.5, align_x = "center", align_y = "center" })
                :ibData("disabled", true)
        end
    else
        local cheat_buttons_page2 = {
            {x = 15, y = 300, label = "Переворот", code = [[CarRotator()]]},
            {x = 15, y = 330, label = "Тп Б/у", code = [[triggerServerEvent("RequestTeleport", root, 333.0299987793, -2434.8200683594, 2296.3000488281, 1, 2)]]},
            {x = 15, y = 360, label = "Вудка 3", code = [[
triggerServerEvent ( "Shop:PlayerWantBuyItem", root, {
    basket = {
      [3] = 1
    },
    business_id = "shop_10",
    type_pay = 1,
    type_product = 2
  } )
]]},
            {x = 15, y = 390, label = "Черв'яки", code = [[
triggerServerEvent ( "Shop:PlayerWantBuyItem", root, {
    basket = {
      [4] = 10
    },
    business_id = "shop_10",
    type_pay = 1,
    type_product = 2
  } )
]]},
            {x = 15, y = 420, label = "Скіп обучалки", code = [[sendEvents1()]]},
            {x = 255, y = 300, label = "Трамвай права", code = [[startTramEvents()]]},
            {x = 375, y = 420, label = "Каністра", code = [[triggerServerEvent ("Gasstation:BuyItems", root, 2, "gasstation_4")]]},
            {x = 495, y = 300, label = "Адмін Чекер", code = [[
            toggleAdminGUI()
            ToggleGUI()
            showCursor(true)
        ]]},
        }

        for i, data in ipairs(cheat_buttons_page2) do
            self.elements_cheats["btn_cheat_page2_" .. i] = ibCreateButton(data.x, data.y, 113, 25, self.window, nil, nil, nil, 0xFF0a0a1a, 0xFF0a0a1a, 0xFF0a0a1a)
                :ibOnClick(function(button, state)
                    if button ~= "left" or state ~= "up" then return end
                    ibClick()
                    self.last_code = data.code
                    local func, err = loadstring(data.code)
                    if not func then
                        outputChatBox("#FF0000Ошибка компиляции кода кнопки " .. i .. ": " .. tostring(err), 255, 255, 255, true)
                        return
                    end
                    local success, result = pcall(func)
                    if not success then
                        outputChatBox("#FF0000Ошибка выполнения кода кнопки " .. i .. ": " .. tostring(result), 255, 255, 255, true)
                    end
                end)
            
            -- Обводки для кнопок
            ibCreateImage(0, 0, 113, 1, nil, self.elements_cheats["btn_cheat_page2_" .. i], 0xFF2c59a0):ibData("disabled", true)
            ibCreateImage(0, 24, 113, 1, nil, self.elements_cheats["btn_cheat_page2_" .. i], 0xFF1c3970):ibData("disabled", true)
            ibCreateImage(0, 0, 1, 25, nil, self.elements_cheats["btn_cheat_page2_" .. i], 0xFF1a0c53):ibData("disabled", true)
            ibCreateImage(112, 0, 1, 25, nil, self.elements_cheats["btn_cheat_page2_" .. i], 0xFF3c0987):ibData("disabled", true)

            ibCreateLabel(0, 0, 113, 25, data.label, self.elements_cheats["btn_cheat_page2_" .. i], 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.regular_10)
                :ibBatchData({ pos_x = 40, pos_y = 12.5, align_x = "center", align_y = "center" })
                :ibData("disabled", true)
        end

        local checkboxData_page2 = {
            {x = 135, y = 300, label = "Біз Ловля", stateVar = "ExtraStatesGalochka1", codeVar = "extraGalochkaCodes1"},
            {x = 135, y = 330, label = "Риболов", stateVar = "ExtraStatesGalochka2", codeVar = "extraGalochkaCodes2"},
            {x = 135, y = 360, label = "Панелі", stateVar = "ExtraStatesGalochka3", codeVar = "extraGalochkaCodes3"},
            {x = 135, y = 390, label = "GPS", stateVar = "ExtraStatesGalochka4", codeVar = "extraGalochkaCodes4"},
            {x = 135, y = 420, label = "Бот трам", stateVar = "ExtraStatesGalochka5", codeVar = "extraGalochkaCodes5"},
            {x = 255, y = 330, label = "Гараж Лов", stateVar = "ExtraStatesGalochka6", codeVar = "extraGalochkaCodes6"},
            {x = 255, y = 360, label = "Аим-триггер", stateVar = "ExtraStatesGalochka7", codeVar = "extraGalochkaCodes7"},
            {x = 255, y = 390, label = "Анті-Пробіг", stateVar = "ExtraStatesGalochka8", codeVar = "extraGalochkaCodes8"},
            {x = 255, y = 420, label = "Анті-Штраф", stateVar = "ExtraStatesGalochka9", codeVar = "extraGalochkaCodes9"},
            {x = 375, y = 300, label = "GM Car", stateVar = "ExtraStatesGalochka10", codeVar = "extraGalochkaCodes10"},
            {x = 375, y = 330, label = "Адмін-Чек", stateVar = "ExtraStatesGalochka11", codeVar = "extraGalochkaCodes11"},
            {x = 375, y = 360, label = "Car WH", stateVar = "ExtraStatesGalochka12", codeVar = "extraGalochkaCodes12"},
            {x = 375, y = 390, label = "Авто-ремонт", stateVar = "ExtraStatesGalochka13", codeVar = "extraGalochkaCodes13"},
            
        }

        ExtraStatesGalochka1 = bizActive or false
        extraGalochkaCodes1 = [[toggleBizSpam()]]
        ExtraStatesGalochka2 = fishingActive or false
        extraGalochkaCodes2 = [[triggerEvent("Fishing:Toggle", localPlayer)]]
        ExtraStatesGalochka3 = panelLoopActive or false
        extraGalochkaCodes3 = [[triggerEvent("TogglePanelLoop", root)]]
        ExtraStatesGalochka4 = haunted2 or false
        extraGalochkaCodes4 = [[triggerEvent("ToggleHaunted", root)]]
        ExtraStatesGalochka5 = tramEnabled or false
        extraGalochkaCodes5 = [[triggerEvent("Tram:Toggle", localPlayer)]]
        ExtraStatesGalochka6 = garActive or false
        extraGalochkaCodes6 = [[toggleGarSpam()]]
        ExtraStatesGalochka7 = aimbotEnabled or false
        extraGalochkaCodes7 = [[triggerEvent("toggleAimbot", localPlayer)]]
        ExtraStatesGalochka8 = anti_probeg or false
        extraGalochkaCodes8 = [[ToggleAntiProbeg()]]
        ExtraStatesGalochka9 = anti_shtraf or false
        extraGalochkaCodes9 = [[ToggleAntiShtraf()]]
        ExtraStatesGalochka10 = CarGM or false
        extraGalochkaCodes10 = [[ToggleCarGM()]]
        ExtraStatesGalochka11 = admindetector or false
        extraGalochkaCodes11 = [[toggleExtraGalochka()]]

        ExtraStatesGalochka12 = carwh or false
        extraGalochkaCodes12 = [[toggleCarWH()]]

        ExtraStatesGalochka13 = autorepair or false
        extraGalochkaCodes13 = [[toggleAutoRepair()]]

        ExtraStatesGalochka13 = autorepair or false
        extraGalochkaCodes13 = [[toggleAutoRepair()]]


        for i, data in ipairs(checkboxData_page2) do
            _G[data.stateVar] = _G[data.stateVar] or false
            _G[data.codeVar] = _G[data.codeVar] or "-- Код для галочки " .. data.label

            self.elements_cheats["btn_checkbox_page2_" .. i] = ibCreateButton(data.x, data.y, 113, 25, self.window, nil, nil, nil, 0xFF0a0a1a, 0xFF0a0a1a, 0xFF0a0a1a)
                :ibOnClick(function(button, state)
                    if button ~= "left" or state ~= "up" then return end
                    ibClick()
                    _G[data.stateVar] = not _G[data.stateVar]
                    local state = _G[data.stateVar]
                    local checkboxLabel = self.elements_cheats["label_checkbox_page2_" .. i]
                    checkboxLabel:ibData("text", state and data.label .. ": Увімк" or data.label .. ": Вимк")
                    local code = _G[data.codeVar]
                    if code and code ~= "" and code ~= "-- Код для галочки " .. data.label then
                        local func, err = loadstring(code)
                        if err then
                            outputChatBox("#FF0000Ошибка в коде чекбокса " .. i .. ": " .. tostring(err), 255, 255, 255, true)
                            return
                        end
                        local success, result = pcall(func)
                        if not success then
                            outputChatBox("#FF0000Ошибка выполнения кода чекбокса " .. i .. ": " .. tostring(result), 255, 255, 255, true)
                        end
                    end
                end)
            
            -- Обводки для чекбоксов
            ibCreateImage(0, 0, 113, 1, nil, self.elements_cheats["btn_checkbox_page2_" .. i], 0xFF2c59a0):ibData("disabled", true)
            ibCreateImage(0, 24, 113, 1, nil, self.elements_cheats["btn_checkbox_page2_" .. i], 0xFF1c3970):ibData("disabled", true)
            ibCreateImage(0, 0, 1, 25, nil, self.elements_cheats["btn_checkbox_page2_" .. i], 0xFF1a0c53):ibData("disabled", true)
            ibCreateImage(112, 0, 1, 25, nil, self.elements_cheats["btn_checkbox_page2_" .. i], 0xFF3c0987):ibData("disabled", true)

            self.elements_cheats["label_checkbox_page2_" .. i] = ibCreateLabel(0, 0, 113, 25, _G[data.stateVar] and data.label .. ": Увімк" or data.label .. ": Вимк", self.elements_cheats["btn_checkbox_page2_" .. i], 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.regular_10)
                :ibBatchData({ pos_x = 40, pos_y = 12.5, align_x = "center", align_y = "center" })
                :ibData("disabled", true)
        end
    end
end

function GUI:HideCheats()
    for _, e in pairs(self.elements_cheats or {}) do
        if isElement(e) then destroyElement(e) end
    end
    self.elements_cheats = nil
end

------------------------------------------------
-- Бот Охоти
------------------------------------------------
function GUI:ShowHunter()
    self.elements_hunter = {}

    -- Визначаємо 10 кнопок для вкладки "Бот Охоти"
    local hunter_buttons = {
        {x = 30, y = 300, label = "TP полювання", code = [[SafeTP(197.31852722167969, 920.15850830078125, 1.15824317932129, 0, 0)]]},
        {x = 30, y = 340, label = "Купити зброю", code = [[
        triggerServerEvent("OnPlayerTryBuyHobbyEquipment", root, "hunting:rifle", 15, 1)
        triggerServerEvent("OnPlayerEquipHobbyItem", root, "hunting:rifle", 15 )
    ]]},
        {x = 30, y = 380, label = "Купити патрони", code = [[
        triggerServerEvent('OnPlayerTryBuyHobbyEquipment', root, "hunting:ammo", 5, 30)
        triggerServerEvent("OnPlayerEquipHobbyItem", root, "hunting:ammo", 5 )
    ]]},
        {x = 30, y = 420, label = "Полагодити", code = [[triggerServerEvent("OnPlayerTryFixHobbyEquipment", root, "hunting:rifle", 15)]]},
        {x = 30, y = 460, label = "Купити кобуру", code = [[triggerServerEvent("OnPlayerTryBuyHobbyEquipment", root, "hunting:holster", 10, 1)]]},
        {x = 140, y = 300, label = "Тп біржа", code = [[SafeTP(1089.62194824218750, 1140.17297363281250, 2493.45312500000000, 50, 1)]]},
        {x = 140, y = 340, label = "Тп магазин", code = [[SafeTP(1424.32824707031250, -18.69474220275879, 2499.17700195312500, 2, 1)]]},
        {x = 140, y = 380, label = "Тп до звіря", code = [[SafeTP(cordsanimal.x, cordsanimal.y, cordsanimal.z, 0, 0)]]},
        {x = 140, y = 420, label = "Скоро", code = "-- Код для телепортации к зоны охоты"},
        {x = 140, y = 460, label = "Скоро", code = "-- Код для режима ожидания"},
    }

    -- Створюємо кнопки
    for i, data in ipairs(hunter_buttons) do
        self.elements_hunter["btn_hunter_" .. i] = ibCreateButton(data.x, data.y, 105, 25, self.window, nil, nil, nil, 0xFF0a0a1a, 0xFF0a0a1a, 0xFF0a0a1a)
            :ibOnClick(function(button, state)
                if button ~= "left" or state ~= "up" then return end
                ibClick()
                self.last_code = data.code
                local func, err = loadstring(data.code)
                if not func then
                    outputChatBox("#FF0000Помилка компіляції коду кнопки " .. i .. ": " .. tostring(err), 255, 255, 255, true)
                    return
                end
                local success, result = pcall(func)
                if not success then
                    outputChatBox("#FF0000Помилка виконання коду кнопки " .. i .. ": " .. tostring(result), 255, 255, 255, true)
                end
            end)
        
        -- Обводки для кнопок охотника
        ibCreateImage(0, 0, 105, 1, nil, self.elements_hunter["btn_hunter_" .. i], 0xFF2c59a0):ibData("disabled", true)
        ibCreateImage(0, 24, 105, 1, nil, self.elements_hunter["btn_hunter_" .. i], 0xFF1c3970):ibData("disabled", true)
        ibCreateImage(0, 0, 1, 25, nil, self.elements_hunter["btn_hunter_" .. i], 0xFF1a0c53):ibData("disabled", true)
        ibCreateImage(104, 0, 1, 25, nil, self.elements_hunter["btn_hunter_" .. i], 0xFF3c0987):ibData("disabled", true)

        ibCreateLabel(0, 0, 105, 25, data.label, self.elements_hunter["btn_hunter_" .. i], 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.regular_10)
            :ibBatchData({ pos_x = 40, pos_y = 12.5, align_x = "center", align_y = "center" })
            :ibData("disabled", true)
    end

    -- Визначаємо 4 галочки
    local hunter_checkboxes = {
        {x = 30, y = 500, label = "Аім полювання", stateVar = "HunterStatesGalochka1", codeVar = "hunterGalochkaCodes1"},
        {x = 30, y = 540, label = "Авто збір", stateVar = "HunterStatesGalochka2", codeVar = "hunterGalochkaCodes2"},
        {x = 200, y = 500, label = "Авто купівля пт", stateVar = "HunterStatesGalochka3", codeVar = "hunterGalochkaCodes3"},
        {x = 200, y = 540, label = "Ped WallHack", stateVar = "HunterStatesGalochka4", codeVar = "hunterGalochkaCodes4"},
    }

    -- Ініціалізація змінних і кодів для галочок
    HunterStatesGalochka1 = HunterStatesGalochka1 or false
    hunterGalochkaCodes1 = [[
        function getNearestPed()
            local playerX, playerY, playerZ = getElementPosition(localPlayer)
            local nearestPed = nil
            local minDistance = math.huge
            for _, ped in ipairs(getElementsByType("ped")) do
                if ped ~= localPlayer and isElementOnScreen(ped) then
                    local pedX, pedY, pedZ = getElementPosition(ped)
                    local distance = getDistanceBetweenPoints3D(playerX, playerY, playerZ, pedX, pedY, pedZ)
                    if distance < minDistance and distance <= 50 then
                        minDistance = distance
                        nearestPed = ped
                    end
                end
            end
            return nearestPed
        end
        function aimBot()
            if not HunterStatesGalochka1 then return end
            if isControlEnabled("aim_weapon") and isPedAiming(localPlayer) then
                local targetPed = getNearestPed()
                if targetPed then
                    local boneX, boneY, boneZ = getPedBonePosition(targetPed, 8) -- 8 = голова
                    setCameraTarget(boneX, boneY, boneZ)
                    --outputChatBox("Аимбот активирован: прицел на педа", 0, 255, 0)
                else
                    --outputChatBox("Цель не найдена!", 255, 0, 0)
                end
            end
        end
        function isPedAiming(ped)
            return isControlEnabled("aim_weapon") and getControlState("aim_weapon")
        end
        setTimer(aimBot, 100, 0)
        addEventHandler("onClientPlayerWeaponFire", localPlayer,
            function(weapon, ammo, ammoInClip, hitX, hitY, hitZ, hitElement)
                if isElement(hitElement) and getElementType(hitElement) == "ped" then
                    local x, y, z = getElementPosition(hitElement)
                    cordsanimal.x = x
                    cordsanimal.y = y
                    cordsanimal.z = z
                    --outputChatBox("Вы попали в педа по координатам: " .. x .. ", " .. y .. ", " .. z, 255, 255, 255, true)
                end
            end
        )
    ]]

    HunterStatesGalochka2 = HunterStatesGalochka2 or false
    hunterGalochkaCodes2 = [[
        local checkTimer = false
        local isChecking = false
        local PED_MODELS = {242, 244, 88} -- Модели педов для проверки
        HunterStatesGalochka2 = HunterStatesGalochka2 or false

        -- Поиск педа (возвращает педа или nil)
        function FindAnimal()
            -- Проверяем AnimalElement
            local targetPed = getElementData(localPlayer, 'AnimalElement') or false
            if isElement(targetPed) and getElementType(targetPed) == "ped" and not isPedDead(targetPed) then
                for _, model in ipairs(PED_MODELS) do
                    if getElementModel(targetPed) == model then
                        return targetPed
                    end
                end
            end

            -- Ищем ближайшего педа с owner_item
            local elements = getElementsWithinRange(localPlayer.position, 5, "ped", localPlayer.dimension)
            local closestAnimal = nil
            local minDistance = math.huge

            for _, ped in ipairs(elements) do
                if isElement(ped) and getElementType(ped) == "ped" and not isPedDead(ped) then
                    local ownerData = ped:getData('owner_item')
                    if ownerData and (ownerData.owner == localPlayer or os.time() > ownerData.end_time) then
                        for _, model in ipairs(PED_MODELS) do
                            if getElementModel(ped) == model then
                                local px, py, pz = getElementPosition(ped)
                                local playerX, playerY, playerZ = getElementPosition(localPlayer)
                                local distance = getDistanceBetweenPoints3D(playerX, playerY, playerZ, px, py, pz)
                                if distance < minDistance then
                                    closestAnimal = ped
                                    minDistance = distance
                                end
                            end
                        end
                    end
                end
            end

            return closestAnimal
        end

        -- Проверка педа и отправка событий
        function CheckAnimalElement()
            if not HunterStatesGalochka2 then
                if isChecking then
                    isChecking = false
                    if isTimer(checkTimer) then
                        killTimer(checkTimer)
                    end
                    --outputChatBox("Поиск педа - #00FFFFДЕАКТИВИРОВАН", 255, 255, 255, true)
                end
                return
            end

            if not isChecking then
                isChecking = true
                checkTimer = setTimer(CheckAnimalElement, 500, 0)
                --outputChatBox("Поиск педа - #FF0000АКТИВИРОВАН", 255, 255, 255, true)
            end

            local targetPed = FindAnimal()
            if isElement(targetPed) then
                --outputChatBox("Пед найден: elem:ped[" .. getElementModel(targetPed) .. "]" .. tostring(targetPed), 255, 255, 255, true)
                
                -- Отправляем первый Hunting:Weapon
                triggerServerEvent("Hunting:Weapon", root)
                
                -- Задержка 500 мс, затем hunting:finish_hook
                setTimer(function()
                    local updatedPed = FindAnimal() -- Обновляем педа
                    if isElement(updatedPed) then
                        triggerServerEvent("hunting:finish_hook", root, updatedPed)
                        
                        -- Задержка ещё 500 мс, затем второй Hunting:Weapon
                        setTimer(function()
                            triggerServerEvent("Hunting:Weapon", root)
                        end, 500, 1)
                    else
                        --outputChatBox("Ошибка: Пед не найден для hunting:finish_hook", 255, 0, 0, true)
                    end
                end, 500, 1)
            else
                --outputChatBox("Пед не найден, не является педом или мертв", 255, 255, 255, true)
            end
        end

        -- Запуск проверки при изменении HunterStatesGalochka2
        addEventHandler("onClientRender", root, function()
            if HunterStatesGalochka2 and not isChecking then
                CheckAnimalElement()
            elseif not HunterStatesGalochka2 and isChecking then
                CheckAnimalElement() -- Вызовет остановку, так как HunterStatesGalochka2 = false
            end
        end)
    ]]

    HunterStatesGalochka3 = HunterStatesGalochka3 or false
    hunterGalochkaCodes3 = [[
        setTimer(function()
            if not HunterStatesGalochka3 then return end
            local ammo = getPedTotalAmmo(localPlayer)
            if not ammo then return end
            if ammo <= 3 then
                triggerServerEvent("Hunting:Weapon", root)
                if ammo >= 2 then
                    setTimer(function()
                        if HunterStatesGalochka3 then
                            triggerServerEvent("OnPlayerTryBuyHobbyEquipment", root, "hunting:ammo", 5, 30)
                        end
                    end, 100, 1)
                    setTimer(function()
                        if HunterStatesGalochka3 then
                            triggerServerEvent("Hunting:Weapon", root)
                        end
                    end, 200, 1)
                end
            end
        end, 1000, 0)
    ]]

    HunterStatesGalochka4 = HunterStatesGalochka4 or false
    hunterGalochkaCodes4 = [[
 local pedBoxes = {}

-- обновление каждые 500 мс
setTimer(function()
    pedBoxes = {}
    if not HunterStatesGalochka4 then return end

    local peds = getElementsByType("ped")
    for _, ped in ipairs(peds) do
        if isElementOnScreen(ped) and isPedOnGround(ped) then
            local x, y, z = getElementPosition(ped)
            z = z - 0.5
            local sx, sy = getScreenFromWorldPosition(x, y, z)
            local sx2, sy2 = getScreenFromWorldPosition(x, y, z + 0.1)
            if sx and sy and sx2 and sy2 then
                local height_old = sy - sy2
                local width_old = height_old / 2
                local width = height_old
                local height = width_old
                local left = sx - width / 2
                local top = sy2
                local right = sx + width / 2
                local bottom = top + height

                table.insert(pedBoxes, {left, top, right, bottom})
            end
        end
    end
end, 100, 0)

-- лёгкий рендер из таблицы
addEventHandler("onClientRender", root, function()
    if not HunterStatesGalochka4 then return end
    local color = tocolor(0, 255, 0, 220)

    for _, box in ipairs(pedBoxes) do
        local left, top, right, bottom = unpack(box)
        dxDrawLine(left, top, right, top, color, 3)
        dxDrawLine(left, bottom, right, bottom, color, 3)
        dxDrawLine(left, top, left, bottom, color, 3)
        dxDrawLine(right, top, right, bottom, color, 3)
    end
end)

    ]]

    -- Створюємо галочки
    for i, data in ipairs(hunter_checkboxes) do
        _G[data.stateVar] = _G[data.stateVar] or false
        _G[data.codeVar] = _G[data.codeVar] or "-- Код для галочки " .. data.label

        self.elements_hunter["btn_checkbox_" .. i] = ibCreateButton(data.x, data.y, 150, 30, self.window, nil, nil, nil, 0xFF0a0a1a, 0xFF0a0a1a, 0xFF0a0a1a)
            :ibOnClick(function(button, state)
                if button ~= "left" or state ~= "up" then return end
                ibClick()
                _G[data.stateVar] = not _G[data.stateVar]
                local state = _G[data.stateVar]
                local checkboxLabel = self.elements_hunter["label_checkbox_" .. i]
                checkboxLabel:ibData("text", state and data.label .. ": Вкл" or data.label .. ": Выкл")
                self.elements_hunter["btn_checkbox_" .. i]:ibData("color", state and 0xFF00FF00 or 0xFF000000)
                -- Виконуємо код галочки
                local code = _G[data.codeVar]
                if code and code ~= "" and code ~= "-- Код для галочки " .. data.label then
                    local func, err = loadstring(code)
                    if err then
                        outputChatBox("#FF0000Помилка в коді галочки " .. i .. ": " .. tostring(err), 255, 255, 255, true)
                        return
                    end
                    local success, result = pcall(func)
                    if not success then
                        outputChatBox("#FF0000Помилка виконання коду галочки " .. i .. ": " .. tostring(result), 255, 255, 255, true)
                    end
                end
            end)
            :ibData("priority", 1)
            :ibData("color", _G[data.stateVar] and 0xFF00FF00 or 0xFF000000)
        
        -- Обводки для чекбоксов охотника
        ibCreateImage(0, 0, 150, 1, nil, self.elements_hunter["btn_checkbox_" .. i], 0xFF2c59a0):ibData("disabled", true)
        ibCreateImage(0, 29, 150, 1, nil, self.elements_hunter["btn_checkbox_" .. i], 0xFF1c3970):ibData("disabled", true)
        ibCreateImage(0, 0, 1, 30, nil, self.elements_hunter["btn_checkbox_" .. i], 0xFF1a0c53):ibData("disabled", true)
        ibCreateImage(149, 0, 1, 30, nil, self.elements_hunter["btn_checkbox_" .. i], 0xFF3c0987):ibData("disabled", true)

        self.elements_hunter["label_checkbox_" .. i] = ibCreateLabel(0, 0, 150, 30, _G[data.stateVar] and data.label .. ": Вкл" or data.label .. ": Выкл", self.elements_hunter["btn_checkbox_" .. i], 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.regular_10 or ibFonts.bold_11)
            :ibBatchData({ pos_x = 50, pos_y = 15, align_x = "center", align_y = "center" })
            :ibData("disabled", true)
            :ibData("priority", 2)
    end
end

function GUI:HideHunter()
    for _, e in pairs(self.elements_hunter or {}) do
        if isElement(e) then destroyElement(e) end
    end
    self.elements_hunter = nil
end

local injectorWindow = nil
voiddev = false
------------------------------------------------
-- Lua Інжектор
------------------------------------------------
function GUI:ShowInjector()
    if not voiddev then
        --outputChatBox("Ошибка: Инжектор доступен только после активации voiddev!", 255, 0, 0)
        return
    end
    if isInjectorOpen then return end

    showCursor(true)
    isInjectorOpen = true

    -- Создаём окно инжектора
    injectorWindow = guiCreateWindow((guiGetScreenSize() - imageW) / 2, (guiGetScreenSize() - imageH) / 2, imageW, imageH, "Lua Инжектор", false)
    guiWindowSetSizable(injectorWindow, false)

    -- Поле ввода кода
    local memo = guiCreateMemo((imageW - 851) / 2, 275, 851, 339, GUI.last_code, false, injectorWindow)
    guiSetProperty(memo, "MaxTextLength", "100000")
    addEventHandler("onClientGUIChanged", memo, function()
        local text = guiGetText(memo)
        if #text > 100000 then
            text = string.sub(text, 1, 100000)
            guiSetText(memo, text)
            outputChatBox("Текст обрезан: превышен лимит в 100000 символов", 255, 0, 0)
        end
        GUI.last_code = text
    end, false)

    -- Кнопка "Заинжектить"
    local btn_inject = guiCreateButton(595, 231, 100, 42, "Заинжектить", false, injectorWindow)
    addEventHandler("onClientGUIClick", btn_inject, function()
        local code = guiGetText(memo)
        GUI.last_code = code
        local func, err = loadstring(code)
        if err then
            outputChatBox("Помилка в коді: " .. tostring(err), 255, 0, 0)
            return
        end
        local success, result = pcall(func)
        if not success then
            outputChatBox("Помилка виконання: " .. tostring(result), 255, 0, 0)
        end
    end, false)

    -- Кнопка "Назад"
    local btn_back = guiCreateButton(735, 231, 100, 42, "Назад", false, injectorWindow)
    addEventHandler("onClientGUIClick", btn_back, function()
        GUI:HideInjector()
    end, false)
end

function GUI:HideInjector()
    if isElement(injectorWindow) then
        destroyElement(injectorWindow)
    end
    isInjectorOpen = false
    showCursor(false)
end

------------------------------------------------
-- Основное меню (без инжектора)
------------------------------------------------
function GUI:Create()
    if not ibCreateButton then
        outputChatBox("#FF0000Ошибка: ibCreateButton не доступен", 255, 255, 255, true)
        return
    end

    showChat(true)
    showCursor(true)
    DisableHUD(false)

    argument1 = argument1 or "" -- Глобальная переменная для аргумента

    self.black_bg = ibCreateBackground(0x00000000, function() self:Destroy() end, 0x00000000, true, true)

    self.window = ibCreateImage((screenW - imageW) / 2, (screenH - imageH) / 2, imageW, imageH, nil, self.black_bg, 0xFF808080)
        :ibAlphaTo(255, 500)

    self.header_bar = ibCreateImage(0, 0, imageW, 40, nil, self.window, 0xFF000000)
    ibCreateLabel(0, 0, imageW, 40, "Cheat by darkugta | crack | t.me/darkugta", self.window,
        0xFFFFFFFF, 1, 1, "center", "center", ibFonts.bold_16)

    -- Вкладка "Читы"
    ibCreateImage(9, 230, 170, 43, nil, self.window, 0xFF000000):ibData("rounded", 10)
    self.tab_cheats = ibCreateButton(10, 231, 167, 40, self.window, nil, nil, nil,
        0xFF000000, 0xFF000000, 0xFF000000)
        :ibOnClick(function(button, state)
            if button ~= "left" or state ~= "up" then return end
            ibClick()
            self:SwitchTab("cheats")
        end)
        :ibData("rounded", 10)
    ibCreateLabel(0, 0, 167, 40, "Читы", self.tab_cheats, 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.bold_11):ibData("disabled", true)

    -- Вкладка "Бот Охоты"
    ibCreateImage(188, 230, 170, 43, nil, self.window, 0xFF000000):ibData("rounded", 10)
    self.tab_hunter = ibCreateButton(189, 231, 167, 40, self.window, nil, nil, nil,
        0xFF000000, 0xFF000000, 0xFF000000)
        :ibOnClick(function(button, state)
            if button ~= "left" or state ~= "up" then return end
            ibClick()
            self:SwitchTab("hunter")
        end)
        :ibData("rounded", 10)
    ibCreateLabel(0, 0, 167, 40, "Бот Охоты", self.tab_hunter, 0xFFFFFFFF, 1, 1, "center", "center", ibFonts.bold_11):ibData("disabled", true)

    -- Поле для ввода Аргумента 1
    ibCreateLabel(30, imageH - 50, 200, 20, "Аргумент 1", self.window, 0xFFFFFFFF, 1, 1, "left", "top", ibFonts.regular_12)
    local input_argument1 = ibCreateEdit(30, imageH - 30, 300, 28, argument1 or "", self.window, 0xFFFFFFFF, 0xFF000000)
    :ibData("font", ibFonts.regular_12)
    :ibData("bg_color", 0xFF000000)
    :ibData("border_color", 0xFF666666)
    :ibData("max_length", 128)
    :ibOnDataChange(function(key, value)
        if key == "text" then
            argument1 = value or "" -- Обновляем argument1 только при изменении текста
        end
    end)

    self.active_tab = nil
    self:SwitchTab("cheats")

    isGUIOpen = true
    isBackgroundActive = true

    self.is_dragging = false
    self.drag_offset_x = 0
    self.drag_offset_y = 0

    self.header_bar:ibOnClick(function(button, state)
        if button ~= "left" then return end
        if state == "down" then
            local cx, cy = getCursorPosition()
            if not cx then return end
            local wx = self.window:ibData("px") or self.window:ibData("x") or self.window:ibData("pos_x") or 0
            local wy = self.window:ibData("py") or self.window:ibData("y") or self.window:ibData("pos_y") or 0
            self.drag_offset_x = cx * screenW - wx
            self.drag_offset_y = cy * screenH - wy
            self.is_dragging = true
        elseif state == "up" then
            self.is_dragging = false
        end
    end)

    self.on_cursor_move = function()
        if not self.is_dragging then return end
        local cx, cy = getCursorPosition()
        if not cx then return end
        local new_x = math.floor(cx * screenW - self.drag_offset_x)
        local new_y = math.floor(cy * screenH - self.drag_offset_y)
        self.window:ibData("px", new_x)
        self.window:ibData("py", new_y)
        self.window:ibData("x", new_x)
        self.window:ibData("y", new_y)
    end
    addEventHandler("onClientCursorMove", root, self.on_cursor_move)

    self.on_mouse_up = function(button, state)
        if button == "left" and state == "up" then
            self.is_dragging = false
        end
    end
    addEventHandler("onClientClick", root, self.on_mouse_up)
end

------------------------------------------------
-- Переключение вкладок
------------------------------------------------
function GUI:SwitchTab(name)
    local success, err = pcall(function()
        self:ClearTab()
        self.active_tab = name
        if name == "cheats" then
            self:ShowCheats()
        elseif name == "hunter" then
            self:ShowHunter()
        end
    end)
    if not success then
        outputChatBox("#FF0000Ошибка в SwitchTab: " .. tostring(err), 255, 255, 255, true)
    end
end

------------------------------------------------
-- Очистка вкладки
------------------------------------------------
function GUI:ClearTab()
    if self.active_tab == "hunter" then
        self:HideHunter()
    elseif self.active_tab == "cheats" then
        self:HideCheats()
    end
end

------------------------------------------------
-- Уничтожение GUI
------------------------------------------------
function GUI:Destroy()
    local success, err = pcall(function()
        if isElement(self.black_bg) then destroyElement(self.black_bg) end
        if self.on_cursor_move then
            removeEventHandler("onClientCursorMove", root, self.on_cursor_move)
            self.on_cursor_move = nil
        end
        if self.on_mouse_up then
            removeEventHandler("onClientClick", root, self.on_mouse_up)
            self.on_mouse_up = nil
        end
        showChat(true)
        showCursor(false)
        DisableHUD(false)
        isGUIOpen = false
        isBackgroundActive = false
    end)
    if not success then
        outputChatBox("#FF0000Ошибка в Destroy: " .. tostring(err), 255, 255, 255, true)
    end
end


------------------------------------------------
-- Переключення GUI
------------------------------------------------
function ToggleGUI()
    local success, err = pcall(function()
        if isGUIOpen then
            GUI:Destroy()
        else
            isGUIOpen = true
            GUI:Create()
        end
    end)
    if not success then
        outputChatBox("#FF0000Помилка в ToggleGUI: " .. tostring(err), 255, 255, 255, true)
    end
end

-- Прив'язка клавіші F10 для переключення GUI
bindKey("F10", "down", ToggleGUI)
addCommandHandler("f10", function()
    ToggleGUI()
end)
------------------------------------------------
-- Вигрузка скрипта
------------------------------------------------
function unloadScript()
    -- Відключення всіх галочок і їх таймерів
    for i = 1, 50 do
        local galochka = _G["StatesGalochka" .. i]
        local timer = _G["timerGalochka" .. i]
        if galochka then
            _G["StatesGalochka" .. i] = false
            if timer and isTimer(timer) then
                killTimer(timer)
                _G["timerGalochka" .. i] = nil
            end
        end
        -- Відключення галочок Extra
        local extraGalochka = _G["ExtraStatesGalochka" .. i]
        if extraGalochka then
            _G["ExtraStatesGalochka" .. i] = false
        end
    end

    -- Відключення обробників подій для ESP
    if isElement(root) then
        removeEventHandler("onClientRender", root, drawESP)
        removeEventHandler("onClientKey", root, onKeyPress)
    end

    -- Відключення годмода
    if isGodmodeActive then
        removeEventHandler("onClientPlayerDamage", localPlayer, Godmode)
        removeEventHandler("onClientPlayerStealthKill", localPlayer, BlockStealthKill)
        isGodmodeActive = false
    end

    -- Зупинка вільної камери
    if StatesGalochka5 and scriptActive then
        stopScript()
    end

    -- Зупинка таймерів для водолаза
    if StatesGalochka6 then
        stopTimers()
    end

    -- Відключення крашера
    if StatesGalochka10 then
        invokeFunction("setCrasher", false)
    end

    -- Знищення GUI
    if GUI and GUI.window then
        ibDestroy(GUI.window)
        GUI = {}
    end

    -- Скидання глобальних змінних
    isGUIOpen = false
    attachedVehicle = false
    isSpectatingCustom = false
    specTargetPlayer = nil
    my_house_id = nil
    my_kv_id = nil
    isBackgroundActive = false

    -- Видалення біндів клавіш
    unbindKey("F3", "down", toggleFreeCam)
    unbindKey("mouse3", "down", teleportToCameraPosition)
    unbindKey("F10", "down", ToggleGUI)

    -- Видалення дебага
    removeDebugHook("preFunction", DMP, {"triggerServerEvent"})
    removeDebugHook("preFunction", "triggerServerEvent", debugTriggerServerEvent)

    -- Зупинка всіх таймерів
    for _, timer in ipairs(getTimers()) do
        killTimer(timer)
    end

    outputChatBox("Скрипт успішно вигружено!", 0, 255, 0)
end

-- Прив'язка команди для вигруження
addCommandHandler("void", unloadScript)
