-- Stage 2E: Presale Proceeds.
-- Event-driven and persisted per city; no per-turn or load-time scan.

local XJY_LEADER_TYPE = "LEADER_XJY_XU_JIAYIN"
local GRANTED_PROPERTY = "XJY_PRESALE_PROCEEDS_GRANTED"

local GOLD_BY_GAME_SPEED = {
    GAMESPEED_ONLINE = 20,
    GAMESPEED_QUICK = 27,
    GAMESPEED_STANDARD = 40,
    GAMESPEED_EPIC = 60,
    GAMESPEED_MARATHON = 120
}

local function IsSpecialtyDistrict(districtType)
    local districtInfo = GameInfo.Districts[districtType]
    return districtInfo ~= nil
        and (districtInfo.RequiresPopulation == true or districtInfo.RequiresPopulation == 1)
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

local function OnDistrictConstructed(playerID, districtType, x, y)
    if not IsSpecialtyDistrict(districtType) then
        return
    end

    local player = Players[playerID]
    local playerConfig = PlayerConfigurations[playerID]
    if player == nil or playerConfig == nil then
        print("[XJY][Presale] ignored invalid player: " .. tostring(playerID))
        return
    end

    local district = CityManager.GetDistrictAt(x, y)
    local city = district ~= nil and district:GetCity() or nil
    if city == nil then
        print("[XJY][Presale] ignored missing city at " .. tostring(x) .. "," .. tostring(y))
        return
    end

    if city:GetProperty(GRANTED_PROPERTY) == true then
        return
    end

    -- Record first completions by other leaders as consumed. If that city is
    -- captured later, Xu Jiayin cannot receive a retroactive payment.
    if playerConfig:GetLeaderTypeName() ~= XJY_LEADER_TYPE then
        city:SetProperty(GRANTED_PROPERTY, true)
        return
    end

    if city:GetOriginalOwner() ~= playerID then
        city:SetProperty(GRANTED_PROPERTY, true)
        print("[XJY][Presale] marked without grant: player=" .. tostring(playerID)
            .. ", city=" .. tostring(city:GetID()) .. ", reason=captured-city")
        return
    end

    -- A city already containing another completed specialty district is an
    -- old-save/capture/rebuild case. Mark it consumed without retroactive gold.
    if CountCompletedSpecialtyDistricts(player, city:GetID()) ~= 1 then
        city:SetProperty(GRANTED_PROPERTY, true)
        print("[XJY][Presale] marked without grant: player=" .. tostring(playerID)
            .. ", city=" .. tostring(city:GetID()) .. ", reason=not-first-specialty")
        return
    end

    local gameSpeedIndex = GameConfiguration.GetGameSpeedType()
    local gameSpeedInfo = GameInfo.GameSpeeds[gameSpeedIndex]
    local gameSpeedType = gameSpeedInfo ~= nil and gameSpeedInfo.GameSpeedType or nil
    local amount = GOLD_BY_GAME_SPEED[gameSpeedType]
    if amount == nil then
        city:SetProperty(GRANTED_PROPERTY, true)
        print("[XJY][Presale] no grant: unsupported game speed " .. tostring(gameSpeedType))
        return
    end

    local treasury = player:GetTreasury()
    if treasury == nil then
        city:SetProperty(GRANTED_PROPERTY, true)
        print("[XJY][Presale] no grant: treasury unavailable for player " .. tostring(playerID))
        return
    end

    treasury:ChangeGoldBalance(amount)
    city:SetProperty(GRANTED_PROPERTY, true)
    print("[XJY][Presale] granted " .. tostring(amount)
        .. " gold: player=" .. tostring(playerID)
        .. ", city=" .. tostring(city:GetID())
        .. ", speed=" .. tostring(gameSpeedType))
end

GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed)
print("[XJY][Presale] controller loaded")
