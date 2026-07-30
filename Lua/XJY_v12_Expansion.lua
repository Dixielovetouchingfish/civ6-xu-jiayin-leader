-- ===========================================================================
-- Xu Jiayin v1.2: Full Expansion Update gameplay controller.
-- Asset Takeover and Sales Network are event-driven and serialize all one-shot
-- state in Player/City properties.
-- ===========================================================================

local LOG_PREFIX = "[XJY v1.2]"
local LEADER_TYPE = "LEADER_XJY_XU_JIAYIN"

local ERA_ANCIENT = "ERA_ANCIENT"
local ERA_CLASSICAL = "ERA_CLASSICAL"

local PROPERTY_FULL_PROJECTS_USED = "XJY_FULL_FINANCING_PROJECTS_USED"
local PROPERTY_ASSET_PENDING = "XJY_V12_ASSET_TAKEOVER_PENDING"
local PROPERTY_ASSET_PENDING_PLAYER = "XJY_V12_ASSET_TAKEOVER_PENDING_PLAYER"
local PROPERTY_ASSET_PENDING_TURN = "XJY_V12_ASSET_TAKEOVER_PENDING_TURN"
local PROPERTY_ASSET_CLAIMED = "XJY_V12_ASSET_TAKEOVER_CLAIMED"
local PROPERTY_ASSET_END_TURN = "XJY_V12_ASSET_TAKEOVER_END_TURN"
local PROPERTY_ASSET_ENDED = "XJY_V12_ASSET_TAKEOVER_ENDED"
local PROPERTY_SALES_GRANTED = "XJY_V12_SALES_NETWORK_GRANTED"

local MODIFIER_ASSET_LOYALTY = "MODIFIER_XJY_V12_ASSET_TAKEOVER_LOYALTY"
local MODIFIER_ASSET_LOYALTY_END = "MODIFIER_XJY_V12_ASSET_TAKEOVER_LOYALTY_END"
local MODIFIER_ASSET_AMENITY = "MODIFIER_XJY_V12_ASSET_TAKEOVER_AMENITY"
local MODIFIER_ASSET_AMENITY_END = "MODIFIER_XJY_V12_ASSET_TAKEOVER_AMENITY_END"
local MODIFIER_ASSET_PRODUCTION = "MODIFIER_XJY_V12_ASSET_TAKEOVER_PRODUCTION"
local MODIFIER_ASSET_PRODUCTION_END = "MODIFIER_XJY_V12_ASSET_TAKEOVER_PRODUCTION_END"
local MODIFIER_SALES_CAPACITY = "MODIFIER_XJY_V12_SALES_NETWORK_TRADE_CAPACITY"

local FULL_FINANCING_PROJECT_LIMIT = 5
local FULL_ASSET_TAKEOVER_GOLD = 120
local REDUCED_ASSET_TAKEOVER_GOLD = 60

local ASSET_DURATION_BY_SPEED = {
    GAMESPEED_ONLINE = 5,
    GAMESPEED_QUICK = 7,
    GAMESPEED_STANDARD = 10,
    GAMESPEED_EPIC = 15,
    GAMESPEED_MARATHON = 30
}

local m_DistrictEventGuard = {}

local function Log(message)
    print(LOG_PREFIX .. " " .. tostring(message))
end

local function IsXuJiayinPlayer(playerID)
    local playerConfig = PlayerConfigurations[playerID]
    return playerConfig ~= nil
        and playerConfig:GetLeaderTypeName() == LEADER_TYPE
end

local function GetPlayerEraType(playerID)
    local player = Players[playerID]
    if player == nil then
        error("player is unavailable: " .. tostring(playerID))
    end

    local eraIndex = player:GetEra()
    if type(eraIndex) ~= "number" then
        error("player era is not numeric for player " .. tostring(playerID))
    end

    local era = GameInfo.Eras[eraIndex]
    if era == nil then
        error("player era row is unavailable: " .. tostring(eraIndex))
    end

    return era.EraType
end

local function IsPlayerEarlyEra(playerID)
    local eraType = GetPlayerEraType(playerID)
    return eraType == ERA_ANCIENT or eraType == ERA_CLASSICAL
end

local function ReadNumericProperty(object, propertyName, defaultValue)
    local rawValue = object:GetProperty(propertyName)
    if rawValue == nil then
        return defaultValue
    end

    if type(rawValue) == "number" then
        return rawValue
    end

    if type(rawValue) == "string" then
        local parsedValue = tonumber(rawValue)
        if parsedValue ~= nil then
            return parsedValue
        end
    end

    error("invalid numeric property " .. tostring(propertyName)
        .. " (" .. type(rawValue) .. "): " .. tostring(rawValue))
end

local function GetGameSpeedData()
    local configuredType = GameConfiguration.GetGameSpeedType()
    local speed = GameInfo.GameSpeeds[configuredType]
    if speed == nil then
        error("game speed row unavailable: " .. tostring(configuredType))
    end

    local costMultiplier = tonumber(speed.CostMultiplier)
    if costMultiplier == nil or costMultiplier <= 0 then
        error("invalid CostMultiplier for " .. tostring(speed.GameSpeedType))
    end

    local speedType = speed.GameSpeedType
    local duration = ASSET_DURATION_BY_SPEED[speedType]
    if duration == nil then
        error("asset takeover duration is not defined for " .. tostring(speedType))
    end

    return speedType, costMultiplier, duration
end

local function ScaleGold(standardValue, costMultiplier)
    return math.floor((standardValue * costMultiplier / 100) + 0.5)
end

local function IsOriginalOwnerMajorCivilization(city, capturerID)
    local originalOwnerID = city:GetOriginalOwner()
    if type(originalOwnerID) ~= "number" or originalOwnerID < 0
        or originalOwnerID == capturerID then
        return false
    end

    local originalConfig = PlayerConfigurations[originalOwnerID]
    return originalConfig ~= nil
        and originalConfig:GetCivilizationLevelTypeID()
            == CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV
end

local function SendUserNotification(playerID, summaryTag, messageTag, amount, x, y)
    local player = Players[playerID]
    if player == nil or not player:IsHuman() then
        return
    end

    local summary = Locale.Lookup(summaryTag)
    local message = amount ~= nil
        and Locale.Lookup(messageTag, amount)
        or Locale.Lookup(messageTag)
    NotificationManager.SendNotification(
        playerID,
        NotificationTypes.USER_DEFINED_1,
        message,
        summary,
        x,
        y
    )
end

local function MarkAssetTakeoverCandidate(capturerID, previousOwnerID, cityID, cityX, cityY)
    if not IsXuJiayinPlayer(capturerID)
        or not IsPlayerEarlyEra(capturerID) then
        return
    end

    local player = Players[capturerID]
    local city = player ~= nil and player:GetCities():FindID(cityID) or nil
    if city == nil then
        error("CityConquered could not resolve captured city "
            .. tostring(capturerID) .. "/" .. tostring(cityID)
            .. " at " .. tostring(cityX) .. "," .. tostring(cityY))
    end

    if city:GetProperty(PROPERTY_ASSET_CLAIMED) == true then
        Log("asset takeover ignored; city already claimed: " .. tostring(cityID))
        return
    end

    if not IsOriginalOwnerMajorCivilization(city, capturerID) then
        Log("asset takeover rejected; original founder is not another major: city="
            .. tostring(cityID) .. ", previousOwner=" .. tostring(previousOwnerID)
            .. ", originalOwner=" .. tostring(city:GetOriginalOwner()))
        return
    end

    local transferType = city:GetLastTransferType()
    if CityTransferTypes ~= nil
        and transferType == CityTransferTypes.BY_GIFT then
        Log("asset takeover rejected; transfer was a gift: city=" .. tostring(cityID))
        return
    end

    city:SetProperty(PROPERTY_ASSET_PENDING, true)
    city:SetProperty(PROPERTY_ASSET_PENDING_PLAYER, capturerID)
    city:SetProperty(PROPERTY_ASSET_PENDING_TURN, Game.GetCurrentGameTurn())
    Log("asset takeover pending retention decision: player="
        .. tostring(capturerID) .. ", city=" .. tostring(cityID)
        .. ", originalOwner=" .. tostring(city:GetOriginalOwner()))
end

local function GrantAssetTakeover(playerID, city)
    if city:GetProperty(PROPERTY_ASSET_CLAIMED) == true then
        return
    end

    local player = Players[playerID]
    if player == nil then
        error("asset takeover player unavailable: " .. tostring(playerID))
    end

    local usedProjects = ReadNumericProperty(
        player,
        PROPERTY_FULL_PROJECTS_USED,
        0
    )
    if usedProjects < 0 or usedProjects ~= math.floor(usedProjects) then
        error("invalid shared financing count: " .. tostring(usedProjects))
    end

    local speedType, costMultiplier, duration = GetGameSpeedData()
    local standardGold = usedProjects < FULL_FINANCING_PROJECT_LIMIT
        and FULL_ASSET_TAKEOVER_GOLD
        or REDUCED_ASSET_TAKEOVER_GOLD
    local actualGold = ScaleGold(standardGold, costMultiplier)
    local treasury = player:GetTreasury()
    if treasury == nil then
        error("treasury unavailable for player " .. tostring(playerID))
    end

    -- Serialized one-shot state is committed before any reward is changed.
    city:SetProperty(PROPERTY_ASSET_CLAIMED, true)
    city:SetProperty(PROPERTY_ASSET_PENDING, false)
    player:SetProperty(PROPERTY_FULL_PROJECTS_USED, usedProjects + 1)
    city:SetProperty(
        PROPERTY_ASSET_END_TURN,
        Game.GetCurrentGameTurn() + duration
    )
    city:SetProperty(PROPERTY_ASSET_ENDED, false)

    treasury:ChangeGoldBalance(actualGold)
    city:AttachModifierByID(MODIFIER_ASSET_LOYALTY)
    city:AttachModifierByID(MODIFIER_ASSET_AMENITY)
    city:AttachModifierByID(MODIFIER_ASSET_PRODUCTION)

    SendUserNotification(
        playerID,
        "LOC_XJY_V12_ASSET_TAKEOVER_NAME",
        "LOC_XJY_V12_ASSET_TAKEOVER_NOTIFICATION",
        actualGold,
        city:GetX(),
        city:GetY()
    )
    Log("asset takeover granted: player=" .. tostring(playerID)
        .. ", city=" .. tostring(city:GetID())
        .. ", financingEvent=" .. tostring(usedProjects + 1)
        .. ", standardGold=" .. tostring(standardGold)
        .. ", actualGold=" .. tostring(actualGold)
        .. ", speed=" .. tostring(speedType)
        .. ", duration=" .. tostring(duration))
end

local function ResolveRetainedAssetTakeovers(playerID)
    if not IsXuJiayinPlayer(playerID) then
        return
    end

    local player = Players[playerID]
    if player == nil then
        error("OnPlayerTurnEnded player unavailable: " .. tostring(playerID))
    end

    local currentTurn = Game.GetCurrentGameTurn()
    for _, city in player:GetCities():Members() do
        if city:GetProperty(PROPERTY_ASSET_PENDING) == true then
            local pendingPlayer = ReadNumericProperty(
                city,
                PROPERTY_ASSET_PENDING_PLAYER,
                -1
            )
            local pendingTurn = ReadNumericProperty(
                city,
                PROPERTY_ASSET_PENDING_TURN,
                -1
            )

            if pendingPlayer == playerID and pendingTurn == currentTurn
                and IsPlayerEarlyEra(playerID)
                and IsOriginalOwnerMajorCivilization(city, playerID) then
                GrantAssetTakeover(playerID, city)
            else
                city:SetProperty(PROPERTY_ASSET_PENDING, false)
                Log("stale or ineligible asset takeover cleared: player="
                    .. tostring(playerID) .. ", city=" .. tostring(city:GetID())
                    .. ", pendingTurn=" .. tostring(pendingTurn)
                    .. ", currentTurn=" .. tostring(currentTurn))
            end
        end
    end
end

local function EndExpiredAssetTakeovers()
    local currentTurn = Game.GetCurrentGameTurn()
    for _, player in ipairs(PlayerManager.GetAlive()) do
        for _, city in player:GetCities():Members() do
            if city:GetProperty(PROPERTY_ASSET_CLAIMED) == true
                and city:GetProperty(PROPERTY_ASSET_ENDED) ~= true then
                local endTurn = ReadNumericProperty(
                    city,
                    PROPERTY_ASSET_END_TURN,
                    nil
                )
                if endTurn == nil then
                    error("asset takeover end turn missing for city "
                        .. tostring(city:GetID()))
                end

                if currentTurn >= endTurn then
                    city:AttachModifierByID(MODIFIER_ASSET_LOYALTY_END)
                    city:AttachModifierByID(MODIFIER_ASSET_AMENITY_END)
                    city:AttachModifierByID(MODIFIER_ASSET_PRODUCTION_END)
                    city:SetProperty(PROPERTY_ASSET_ENDED, true)
                    Log("asset takeover support ended: owner="
                        .. tostring(city:GetOwner())
                        .. ", city=" .. tostring(city:GetID())
                        .. ", turn=" .. tostring(currentTurn))
                end
            end
        end
    end
end

local function CountTraderUnits(player)
    local trader = GameInfo.Units["UNIT_TRADER"]
    if trader == nil then
        error("UNIT_TRADER row is unavailable")
    end

    local count = 0
    for _, unit in player:GetUnits():Members() do
        if unit:GetType() == trader.Index then
            count = count + 1
        end
    end
    return count
end

local function GrantSalesNetwork(playerID, districtType, x, y)
    if not IsXuJiayinPlayer(playerID) then
        return
    end

    local commercialHub = GameInfo.Districts["DISTRICT_COMMERCIAL_HUB"]
    local harbor = GameInfo.Districts["DISTRICT_HARBOR"]
    if commercialHub == nil or harbor == nil then
        error("Commercial Hub or Harbor database row is unavailable")
    end
    if districtType ~= commercialHub.Index and districtType ~= harbor.Index then
        return
    end

    local player = Players[playerID]
    if player == nil
        or player:GetProperty(PROPERTY_SALES_GRANTED) == true then
        return
    end

    local eventKey = tostring(playerID) .. ":" .. tostring(Game.GetCurrentGameTurn())
        .. ":" .. tostring(x) .. ":" .. tostring(y)
    if m_DistrictEventGuard[eventKey] == true then
        Log("duplicate district callback ignored: " .. eventKey)
        return
    end
    m_DistrictEventGuard[eventKey] = true

    local district = CityManager.GetDistrictAt(x, y)
    local city = district ~= nil and district:GetCity() or nil
    if district == nil or city == nil or city:GetOwner() ~= playerID
        or not district:IsComplete() then
        error("completed district/city could not be validated at "
            .. tostring(x) .. "," .. tostring(y))
    end

    -- Commit the serialized guard before applying either reward. This protects
    -- against duplicate engine callbacks and save/reload replay.
    player:SetProperty(PROPERTY_SALES_GRANTED, true)
    player:AttachModifierByID(MODIFIER_SALES_CAPACITY)

    local tradersBefore = CountTraderUnits(player)
    UnitManager.InitUnitValidAdjacentHex(
        playerID,
        "UNIT_TRADER",
        city:GetX(),
        city:GetY(),
        5
    )
    local tradersAfter = CountTraderUnits(player)
    if tradersAfter <= tradersBefore then
        Log("ERROR: Sales Network trade capacity granted, but no legal Trader "
            .. "spawn was found near city " .. tostring(city:GetID()))
    end

    SendUserNotification(
        playerID,
        "LOC_XJY_V12_SALES_NETWORK_NAME",
        "LOC_XJY_V12_SALES_NETWORK_NOTIFICATION",
        nil,
        city:GetX(),
        city:GetY()
    )
    Log("sales network granted: player=" .. tostring(playerID)
        .. ", city=" .. tostring(city:GetID())
        .. ", district=" .. tostring(districtType)
        .. ", traderCreated=" .. tostring(tradersAfter > tradersBefore))
end

local function OnCityConquered(...)
    local success, message = pcall(MarkAssetTakeoverCandidate, ...)
    if not success then
        Log("ERROR in CityConquered: " .. tostring(message))
    end
end

local function OnPlayerTurnEnded(...)
    local success, message = pcall(ResolveRetainedAssetTakeovers, ...)
    if not success then
        Log("ERROR in OnPlayerTurnEnded: " .. tostring(message))
    end
end

local function OnGameTurnStarted(...)
    local success, message = pcall(EndExpiredAssetTakeovers, ...)
    if not success then
        Log("ERROR in OnGameTurnStarted: " .. tostring(message))
    end
end

local function OnDistrictConstructed(...)
    local success, message = pcall(GrantSalesNetwork, ...)
    if not success then
        Log("ERROR in OnDistrictConstructed: " .. tostring(message))
    end
end

ExposedMembers.XJY = ExposedMembers.XJY or {}
if ExposedMembers.XJY.V12ExpansionControllerLoaded == true then
    Log("duplicate controller load ignored")
else
    ExposedMembers.XJY.V12ExpansionControllerLoaded = true
    GameEvents.CityConquered.Add(OnCityConquered)
    GameEvents.OnPlayerTurnEnded.Add(OnPlayerTurnEnded)
    GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted)
    GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed)
    Log("Full Expansion controller loaded")
end
