-- ===========================================================================
-- Xu Jiayin v1.1: High-Turnover Development gameplay controller.
-- Event-driven city qualification and financing with serialized properties.
-- ===========================================================================

local LOG_PREFIX = "[XJY][HighTurnover]"
local LEADER_TYPE = "LEADER_XJY_XU_JIAYIN"

local PROPERTY_EARLY_ELIGIBLE = "XJY_EARLY_PROJECT_ELIGIBLE"
local PROPERTY_LAND_RESERVE_ATTACHED = "XJY_EARLY_LAND_RESERVE_ATTACHED"
local PROPERTY_BACKLOG_ATTACHED = "XJY_EARLY_BACKLOG_ATTACHED"
local PROPERTY_PRESALE_GRANTED = "XJY_PRESALE_PROCEEDS_GRANTED"
local PROPERTY_FULL_PROJECTS_USED = "XJY_FULL_FINANCING_PROJECTS_USED"
local PROPERTY_MID_FINANCING_GRANTED = "XJY_MID_FINANCING_GRANTED"
local PROPERTY_DELIVERY_AMENITY_GRANTED = "XJY_ON_TIME_DELIVERY_AMENITY_GRANTED"
local PROPERTY_DELIVERY_AMENITY_REMAINING = "XJY_ON_TIME_DELIVERY_AMENITY_REMAINING"
local PROPERTY_DELIVERY_AMENITY_LAST_TURN = "XJY_ON_TIME_DELIVERY_AMENITY_LAST_TURN"
local PROPERTY_DELIVERY_AMENITY_ENDED = "XJY_ON_TIME_DELIVERY_AMENITY_ENDED"

local MODIFIER_LAND_RESERVE = "MODIFIER_XJY_EARLY_PROJECT_LAND_RESERVE_CITY"
local MODIFIER_BACKLOG = "MODIFIER_XJY_EARLY_PROJECT_BACKLOG_CITY"
local MODIFIER_DELIVERY_AMENITY = "MODIFIER_XJY_ON_TIME_DELIVERY_AMENITY"
local MODIFIER_DELIVERY_AMENITY_END = "MODIFIER_XJY_ON_TIME_DELIVERY_AMENITY_END"

local ERA_ANCIENT = "ERA_ANCIENT"
local ERA_CLASSICAL = "ERA_CLASSICAL"
local ERA_MEDIEVAL = "ERA_MEDIEVAL"
local ERA_RENAISSANCE = "ERA_RENAISSANCE"

local FULL_FINANCING_PROJECT_LIMIT = 5
local FULL_PRESALE_BASE_GOLD = 80
local FULL_PRESALE_ON_TIME_GOLD = 40
local REDUCED_PRESALE_BASE_GOLD = 40
local REDUCED_PRESALE_ON_TIME_GOLD = 20
local MID_FINANCING_GOLD = 100
local DELIVERY_AMENITY_STANDARD_TURNS = 10

local function Log(message)
    print(LOG_PREFIX .. " " .. tostring(message))
end

local function IsXuJiayinPlayer(playerID)
    local playerConfig = PlayerConfigurations[playerID]
    return playerConfig ~= nil
        and playerConfig:GetLeaderTypeName() == LEADER_TYPE
end

local function GetCurrentEraType()
    local gameEras = Game.GetEras()
    if gameEras == nil then
        error("Game era manager is unavailable")
    end

    local era = GameInfo.Eras[gameEras:GetCurrentEra()]
    if era == nil then
        error("Current game era row is unavailable")
    end

    return era.EraType
end

local function IsEarlyEra()
    local eraType = GetCurrentEraType()
    return eraType == ERA_ANCIENT or eraType == ERA_CLASSICAL
end

local function IsMiddleEra()
    local eraType = GetCurrentEraType()
    return eraType == ERA_MEDIEVAL or eraType == ERA_RENAISSANCE
end

local function GetGameSpeedValues()
    local gameSpeedType = GameConfiguration.GetGameSpeedType()
    local gameSpeed = GameInfo.GameSpeeds[gameSpeedType]
    if gameSpeed == nil then
        error("Game speed row was not found for " .. tostring(gameSpeedType))
    end

    local costMultiplier = tonumber(gameSpeed.CostMultiplier)
    if costMultiplier == nil or costMultiplier <= 0 then
        error("Invalid CostMultiplier for " .. tostring(gameSpeedType))
    end

    return costMultiplier, gameSpeed.GameSpeedType or tostring(gameSpeedType)
end

local function ScaleValue(standardValue, costMultiplier)
    return math.floor((standardValue * costMultiplier / 100) + 0.5)
end

local function ReadNumericProperty(object, propertyName, defaultValue)
    local rawValue = object:GetProperty(propertyName)
    if rawValue == nil then
        return defaultValue, true
    end

    if type(rawValue) == "number" then
        return rawValue, true
    end

    if type(rawValue) == "string" then
        local parsedValue = tonumber(rawValue)
        if parsedValue ~= nil then
            return parsedValue, true
        end
    end

    Log("invalid numeric property " .. tostring(propertyName)
        .. " (" .. type(rawValue) .. "): " .. tostring(rawValue))
    return nil, false
end

local function IsSpecialtyDistrict(districtType)
    local districtInfo = GameInfo.Districts[districtType]
    return districtInfo ~= nil
        and (districtInfo.RequiresPopulation == true
            or districtInfo.RequiresPopulation == 1)
end

local function CountCompletedSpecialtyDistricts(player, cityID)
    local count = 0
    local districts = player:GetDistricts()
    if districts == nil then
        return count
    end

    for _, district in districts:Members() do
        local city = district:GetCity()
        if city ~= nil
            and city:GetID() == cityID
            and district:IsComplete()
            and IsSpecialtyDistrict(district:GetType()) then
            count = count + 1
        end
    end

    return count
end

local function AttachCityModifierOnce(city, propertyName, modifierID)
    if city:GetProperty(propertyName) == true then
        return true
    end

    city:AttachModifierByID(modifierID)
    city:SetProperty(propertyName, true)
    return true
end

local function IsCapital(player, city)
    local capital = player:GetCities():GetCapitalCity()
    return capital ~= nil and capital:GetID() == city:GetID()
end

local function QualifyEarlyProject(playerID, cityID)
    if not IsXuJiayinPlayer(playerID) or not IsEarlyEra() then
        return
    end

    local player = Players[playerID]
    local city = CityManager.GetCity(playerID, cityID)
    if player == nil or city == nil then
        error("CityBuilt could not resolve player/city "
            .. tostring(playerID) .. "/" .. tostring(cityID))
    end

    if city:GetOriginalOwner() ~= playerID or IsCapital(player, city) then
        Log("city not qualified: player=" .. tostring(playerID)
            .. ", city=" .. tostring(cityID)
            .. ", reason=capital-or-not-original-owner")
        return
    end

    city:SetProperty(PROPERTY_EARLY_ELIGIBLE, true)
    AttachCityModifierOnce(city, PROPERTY_LAND_RESERVE_ATTACHED, MODIFIER_LAND_RESERVE)
    AttachCityModifierOnce(city, PROPERTY_BACKLOG_ATTACHED, MODIFIER_BACKLOG)
    Log("early project qualified: player=" .. tostring(playerID)
        .. ", city=" .. tostring(cityID)
        .. ", era=" .. tostring(GetCurrentEraType()))
end

local function GrantOnTimeDeliveryAmenity(city, costMultiplier)
    if city:GetProperty(PROPERTY_DELIVERY_AMENITY_GRANTED) == true then
        return
    end

    local duration = math.max(
        1,
        ScaleValue(DELIVERY_AMENITY_STANDARD_TURNS, costMultiplier)
    )

    city:AttachModifierByID(MODIFIER_DELIVERY_AMENITY)
    city:SetProperty(PROPERTY_DELIVERY_AMENITY_GRANTED, true)
    city:SetProperty(PROPERTY_DELIVERY_AMENITY_REMAINING, duration)
    city:SetProperty(PROPERTY_DELIVERY_AMENITY_LAST_TURN, Game.GetCurrentGameTurn())
    Log("on-time delivery amenity granted: city=" .. tostring(city:GetID())
        .. ", turns=" .. tostring(duration))
end

local function GrantPresale(playerID, player, city)
    if city:GetProperty(PROPERTY_EARLY_ELIGIBLE) ~= true
        or city:GetProperty(PROPERTY_PRESALE_GRANTED) == true then
        return
    end

    if city:GetOriginalOwner() ~= playerID or IsCapital(player, city) then
        Log("presale rejected by ownership/capital check: player="
            .. tostring(playerID) .. ", city=" .. tostring(city:GetID()))
        return
    end

    local usedProjects, validCount = ReadNumericProperty(
        player,
        PROPERTY_FULL_PROJECTS_USED,
        0
    )
    if not validCount or usedProjects < 0 then
        Log("presale skipped because project count is invalid")
        return
    end

    local population = city:GetPopulation()
    if type(population) ~= "number" then
        error("City population is not numeric for city " .. tostring(city:GetID()))
    end

    local isFullFinancing = usedProjects < FULL_FINANCING_PROJECT_LIMIT
    local isOnTime = population >= 1 and population <= 3
    local baseGold = isFullFinancing
        and FULL_PRESALE_BASE_GOLD
        or REDUCED_PRESALE_BASE_GOLD
    local onTimeGold = isFullFinancing
        and FULL_PRESALE_ON_TIME_GOLD
        or REDUCED_PRESALE_ON_TIME_GOLD
    local costMultiplier, gameSpeedType = GetGameSpeedValues()
    local actualBaseGold = ScaleValue(baseGold, costMultiplier)
    local actualOnTimeGold = isOnTime
        and ScaleValue(onTimeGold, costMultiplier)
        or 0
    local standardGold = baseGold + (isOnTime and onTimeGold or 0)
    local actualGold = actualBaseGold + actualOnTimeGold
    local treasury = player:GetTreasury()
    if treasury == nil then
        error("Treasury unavailable for player " .. tostring(playerID))
    end

    -- Mark serialized state before changing the balance so a repeated callback
    -- can never pay the same city twice.
    city:SetProperty(PROPERTY_PRESALE_GRANTED, true)
    player:SetProperty(PROPERTY_FULL_PROJECTS_USED, usedProjects + 1)
    treasury:ChangeGoldBalance(actualGold)

    if isOnTime then
        GrantOnTimeDeliveryAmenity(city, costMultiplier)
    end

    Log("presale granted: player=" .. tostring(playerID)
        .. ", city=" .. tostring(city:GetID())
        .. ", project=" .. tostring(usedProjects + 1)
        .. ", standardGold=" .. tostring(standardGold)
        .. ", actualGold=" .. tostring(actualGold)
        .. ", speed=" .. tostring(gameSpeedType)
        .. ", onTime=" .. tostring(isOnTime))
end

local function GrantMidFinancing(playerID, player, city)
    if city:GetProperty(PROPERTY_MID_FINANCING_GRANTED) == true
        or not IsMiddleEra()
        or CountCompletedSpecialtyDistricts(player, city:GetID()) < 3 then
        return
    end

    local costMultiplier, gameSpeedType = GetGameSpeedValues()
    local actualGold = ScaleValue(MID_FINANCING_GOLD, costMultiplier)
    local treasury = player:GetTreasury()
    if treasury == nil then
        error("Treasury unavailable for player " .. tostring(playerID))
    end

    city:SetProperty(PROPERTY_MID_FINANCING_GRANTED, true)
    treasury:ChangeGoldBalance(actualGold)
    Log("mid financing granted: player=" .. tostring(playerID)
        .. ", city=" .. tostring(city:GetID())
        .. ", actualGold=" .. tostring(actualGold)
        .. ", speed=" .. tostring(gameSpeedType))
end

local function ProcessDeliveryAmenity(city)
    if city:GetProperty(PROPERTY_DELIVERY_AMENITY_GRANTED) ~= true
        or city:GetProperty(PROPERTY_DELIVERY_AMENITY_ENDED) == true then
        return
    end

    local remaining, validRemaining = ReadNumericProperty(
        city,
        PROPERTY_DELIVERY_AMENITY_REMAINING,
        nil
    )
    local lastTurn, validLastTurn = ReadNumericProperty(
        city,
        PROPERTY_DELIVERY_AMENITY_LAST_TURN,
        nil
    )
    if not validRemaining or not validLastTurn
        or remaining == nil or lastTurn == nil then
        Log("amenity tick skipped for city " .. tostring(city:GetID())
            .. " because serialized state is incomplete")
        return
    end

    local currentTurn = Game.GetCurrentGameTurn()
    if currentTurn <= lastTurn then
        return
    end

    local nextRemaining = remaining - (currentTurn - lastTurn)
    city:SetProperty(PROPERTY_DELIVERY_AMENITY_LAST_TURN, currentTurn)
    if nextRemaining > 0 then
        city:SetProperty(PROPERTY_DELIVERY_AMENITY_REMAINING, nextRemaining)
        return
    end

    city:AttachModifierByID(MODIFIER_DELIVERY_AMENITY_END)
    city:SetProperty(PROPERTY_DELIVERY_AMENITY_REMAINING, 0)
    city:SetProperty(PROPERTY_DELIVERY_AMENITY_ENDED, true)
    Log("on-time delivery amenity ended: city=" .. tostring(city:GetID()))
end

local function HandleDistrictConstructed(playerID, districtType, x, y)
    if not IsSpecialtyDistrict(districtType) or not IsXuJiayinPlayer(playerID) then
        return
    end

    local player = Players[playerID]
    local district = CityManager.GetDistrictAt(x, y)
    local city = district ~= nil and district:GetCity() or nil
    if player == nil or city == nil then
        error("OnDistrictConstructed could not resolve player/city at "
            .. tostring(x) .. "," .. tostring(y))
    end

    local specialtyCount = CountCompletedSpecialtyDistricts(player, city:GetID())
    if specialtyCount == 1 then
        GrantPresale(playerID, player, city)
    end
    if specialtyCount >= 3 then
        GrantMidFinancing(playerID, player, city)
    end
end

local function HandlePlayerTurnStarted(playerID)
    if not IsXuJiayinPlayer(playerID) then
        return
    end

    local player = Players[playerID]
    if player == nil then
        error("PlayerTurnStarted could not resolve player " .. tostring(playerID))
    end

    for _, city in player:GetCities():Members() do
        if city:GetProperty(PROPERTY_EARLY_ELIGIBLE) == true then
            AttachCityModifierOnce(
                city,
                PROPERTY_LAND_RESERVE_ATTACHED,
                MODIFIER_LAND_RESERVE
            )
            AttachCityModifierOnce(
                city,
                PROPERTY_BACKLOG_ATTACHED,
                MODIFIER_BACKLOG
            )
        end
        ProcessDeliveryAmenity(city)
        if IsMiddleEra() then
            GrantMidFinancing(playerID, player, city)
        end
    end
end

local function OnCityBuilt(...)
    local success, message = pcall(QualifyEarlyProject, ...)
    if not success then
        Log("ERROR in CityBuilt: " .. tostring(message))
    end
end

local function OnDistrictConstructed(...)
    local success, message = pcall(HandleDistrictConstructed, ...)
    if not success then
        Log("ERROR in OnDistrictConstructed: " .. tostring(message))
    end
end

local function OnPlayerTurnStarted(...)
    local success, message = pcall(HandlePlayerTurnStarted, ...)
    if not success then
        Log("ERROR in PlayerTurnStarted: " .. tostring(message))
    end
end

ExposedMembers.XJY = ExposedMembers.XJY or {}
if ExposedMembers.XJY.HighTurnoverControllerLoaded == true then
    Log("duplicate controller load ignored")
else
    ExposedMembers.XJY.HighTurnoverControllerLoaded = true
    GameEvents.CityBuilt.Add(OnCityBuilt)
    GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed)
    GameEvents.PlayerTurnStarted.Add(OnPlayerTurnStarted)
    Log("v1.1 controller loaded")
end
