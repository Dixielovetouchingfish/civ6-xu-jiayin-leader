-- ===========================================================================
-- Stage 1F: Evergrande Yuhu Gate completion reward and timed recovery.
-- Uses only gameplay events and serialized Player properties.
-- ===========================================================================

local LOG_PREFIX = "[XJY][YuhuGate]"
local LEADER_TYPE = "LEADER_XJY_XU_JIAYIN"
local BUILDING_TYPE = "BUILDING_XJY_YUHU_GATE"

local PROPERTY_REWARD_GRANTED = "XJY_YUHU_GATE_COMPLETION_REWARD_GRANTED"
local PROPERTY_RECOVERY_REMAINING = "XJY_YUHU_GATE_RECOVERY_REMAINING_TURNS"
local PROPERTY_RECOVERY_LAST_TURN = "XJY_YUHU_GATE_RECOVERY_LAST_PROCESSED_TURN"

local BASE_GOLD_REWARD = 800
local BASE_RECOVERY_TURNS = 10
local RECOVERY_PERCENT = 15

local function Log(message)
    print(LOG_PREFIX .. " " .. tostring(message))
end

local function ReadNumericPlayerProperty(player, propertyName)
    -- GetProperty returns no Lua values when a property has never been set.
    -- Assign first so the missing value is normalized to an explicit nil.
    local rawValue = player:GetProperty(propertyName)
    if rawValue == nil then
        return nil, true
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

    Log("Invalid numeric player property " .. tostring(propertyName)
        .. " (" .. type(rawValue) .. "): " .. tostring(rawValue)
        .. "; recovery tick skipped")
    return nil, false
end

local function IsXuJiayinPlayer(playerID)
    local playerConfig = PlayerConfigurations[playerID]
    return playerConfig ~= nil and playerConfig:GetLeaderTypeName() == LEADER_TYPE
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

    local goldReward = math.floor((BASE_GOLD_REWARD * costMultiplier / 100) + 0.5)
    local recoveryTurns = math.max(1, math.floor((BASE_RECOVERY_TURNS * costMultiplier / 100) + 0.5))
    return goldReward, recoveryTurns, costMultiplier, gameSpeedType
end

local function IsEligibleCurrentProduction(productionHash)
    if productionHash == nil or productionHash == 0 then
        return false
    end

    if GameInfo.Units[productionHash] ~= nil then
        return true
    end

    local district = GameInfo.Districts[productionHash]
    if district ~= nil then
        return district.RequiresPopulation == true
    end

    local building = GameInfo.Buildings[productionHash]
    if building ~= nil then
        return building.BuildingType ~= BUILDING_TYPE
            and building.IsWonder ~= true
            and building.InternalOnly ~= true
    end

    -- Projects and every unrecognized production category are excluded.
    return false
end

local function ApplyRecoveryToCity(city, productionYieldIndex)
    local buildQueue = city:GetBuildQueue()
    if buildQueue == nil then
        return false
    end

    local productionHash = buildQueue:GetCurrentProductionTypeHash()
    if not IsEligibleCurrentProduction(productionHash) then
        return false
    end

    local productionYield = city:GetYield(productionYieldIndex)
    if productionYield == nil or productionYield <= 0 then
        return false
    end

    buildQueue:AddProgress(productionYield * RECOVERY_PERCENT / 100)
    return true
end

local function HandleBuildingConstructed(playerID, cityID, buildingIndex, plotIndex, originalConstruction)
    local gate = GameInfo.Buildings[BUILDING_TYPE]
    if gate == nil or buildingIndex ~= gate.Index then
        return
    end

    if originalConstruction ~= true then
        Log("Ignored non-original building event for player " .. tostring(playerID)
            .. ", city " .. tostring(cityID))
        return
    end

    if not IsXuJiayinPlayer(playerID) then
        Log("Ignored Gate completion event from non-Xu player " .. tostring(playerID))
        return
    end

    local player = Players[playerID]
    if player == nil then
        error("Player object was nil for player " .. tostring(playerID))
    end

    if player:GetProperty(PROPERTY_REWARD_GRANTED) ~= nil then
        Log("Ignored duplicate completion event for player " .. tostring(playerID))
        return
    end

    local treasury = player:GetTreasury()
    if treasury == nil then
        error("Treasury object was nil for player " .. tostring(playerID))
    end

    local goldReward, recoveryTurns, costMultiplier, gameSpeedType = GetGameSpeedValues()
    local currentTurn = Game.GetCurrentGameTurn()

    -- Mark first so an interrupted or repeated event can never duplicate Gold.
    player:SetProperty(PROPERTY_REWARD_GRANTED, true)
    player:SetProperty(PROPERTY_RECOVERY_REMAINING, recoveryTurns)
    player:SetProperty(PROPERTY_RECOVERY_LAST_TURN, currentTurn)
    treasury:ChangeGoldBalance(goldReward)

    Log("Granted player " .. tostring(playerID)
        .. " " .. tostring(goldReward) .. " Gold and "
        .. tostring(recoveryTurns) .. " recovery turns"
        .. " (game speed " .. tostring(gameSpeedType)
        .. ", CostMultiplier " .. tostring(costMultiplier)
        .. ", city " .. tostring(cityID) .. ")")
end

local function HandlePlayerTurnStarted(playerID)
    if not IsXuJiayinPlayer(playerID) then
        return
    end

    local player = Players[playerID]
    if player == nil then
        return
    end

    local remainingTurns, isRemainingValid =
        ReadNumericPlayerProperty(player, PROPERTY_RECOVERY_REMAINING)
    if not isRemainingValid or remainingTurns == nil or remainingTurns <= 0 then
        return
    end

    local currentTurn = Game.GetCurrentGameTurn()
    local lastProcessedTurn, isLastTurnValid =
        ReadNumericPlayerProperty(player, PROPERTY_RECOVERY_LAST_TURN)
    if not isLastTurnValid then
        return
    end
    if lastProcessedTurn == currentTurn then
        return
    end

    -- Persist the tick before applying progress so a reload on this turn
    -- cannot apply the same 15 percent a second time.
    local nextRemainingTurns = math.max(0, remainingTurns - 1)
    player:SetProperty(PROPERTY_RECOVERY_LAST_TURN, currentTurn)
    player:SetProperty(PROPERTY_RECOVERY_REMAINING, nextRemainingTurns)

    local productionYield = GameInfo.Yields["YIELD_PRODUCTION"]
    if productionYield == nil then
        error("YIELD_PRODUCTION row was not found")
    end

    local affectedCities = 0
    for _, city in player:GetCities():Members() do
        local success, result = pcall(ApplyRecoveryToCity, city, productionYield.Index)
        if success then
            if result then
                affectedCities = affectedCities + 1
            end
        else
            Log("ERROR applying recovery in city " .. tostring(city:GetID())
                .. ": " .. tostring(result))
        end
    end

    Log("Recovery tick for player " .. tostring(playerID)
        .. " on turn " .. tostring(currentTurn)
        .. ": affected " .. tostring(affectedCities)
        .. " cities; " .. tostring(nextRemainingTurns) .. " turns remain")

    if nextRemainingTurns == 0 then
        Log("Recovery ended for player " .. tostring(playerID))
    end
end

local function OnBuildingConstructed(...)
    local success, message = pcall(HandleBuildingConstructed, ...)
    if not success then
        Log("ERROR in BuildingConstructed: " .. tostring(message))
    end
end

local function OnPlayerTurnStarted(...)
    local success, message = pcall(HandlePlayerTurnStarted, ...)
    if not success then
        Log("ERROR in PlayerTurnStarted: " .. tostring(message))
    end
end

GameEvents.BuildingConstructed.Add(OnBuildingConstructed)
GameEvents.PlayerTurnStarted.Add(OnPlayerTurnStarted)
Log("Gameplay script initialized")
