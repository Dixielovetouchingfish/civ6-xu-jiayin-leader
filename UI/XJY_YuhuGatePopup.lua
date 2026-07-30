-- ===========================================================================
-- Evergrande Yuhu Gate static completion popup.
-- UI-only presentation; no camera, audio, animation or gameplay changes.
-- ===========================================================================

local LOG_PREFIX = "[XJY][YuhuGatePopup]"
local BUILDING_TYPE = "BUILDING_XJY_YUHU_GATE"
local SHOWN_PROPERTY = "XJY_YUHU_GATE_POPUP_SHOWN"
local MARK_SHOWN_EVENT = "XJY_YuhuGatePopupShown"
local ORDER_CONSTRUCT = 1
local SOURCE_WIDTH = 1672
local SOURCE_HEIGHT = 941

local m_isVisible = false
local m_isRegistered = false
local m_sessionShown = {}

local function Log(message)
    print(LOG_PREFIX .. " " .. tostring(message))
end

local function Resize()
    local screenWidth, screenHeight = UIManager:GetScreenSizeVal()
    if type(screenWidth) ~= "number" or type(screenHeight) ~= "number" then
        Log("resize skipped: invalid screen size")
        return
    end

    local maxImageWidth = math.max(480, math.min(960, screenWidth - 160))
    local maxImageHeight = math.max(270, math.min(540, screenHeight - 250))
    local scale = math.min(
        maxImageWidth / SOURCE_WIDTH,
        maxImageHeight / SOURCE_HEIGHT,
        1
    )
    local imageWidth = math.floor((SOURCE_WIDTH * scale) + 0.5)
    local imageHeight = math.floor((SOURCE_HEIGHT * scale) + 0.5)
    local panelWidth = imageWidth + 60
    local panelHeight = imageHeight + 190

    Controls.PopupPanel:SetSizeVal(panelWidth, panelHeight)
    Controls.PopupImage:SetSizeVal(imageWidth, imageHeight)
    Controls.Caption:SetOffsetVal(0, imageHeight + 74)
    Controls.Caption:SetWrapWidth(panelWidth - 80)
    Controls.Title:SetWrapWidth(panelWidth - 60)
end

local function Close()
    if not m_isVisible then
        return
    end

    m_isVisible = false
    ContextPtr:SetHide(true)
    Log("closed")
end

local function RequestPersistentShownState(localPlayerID, cityID)
    local parameters = {}
    parameters.OnStart = MARK_SHOWN_EVENT
    parameters.CityID = cityID
    parameters.BuildingType = BUILDING_TYPE
    UI.RequestPlayerOperation(
        localPlayerID,
        PlayerOperations.EXECUTE_SCRIPT,
        parameters
    )
end

local function Show(localPlayerID, cityID)
    RequestPersistentShownState(localPlayerID, cityID)
    Resize()
    m_isVisible = true
    ContextPtr:SetHide(false)
    Log("shown for player=" .. tostring(localPlayerID)
        .. ", city=" .. tostring(cityID))
end

local function HandleCityProductionCompleted(
    playerID,
    cityID,
    orderType,
    itemType,
    canceled,
    typeModifier
)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == PlayerTypes.NONE or playerID ~= localPlayerID then
        return
    end

    local player = Players[localPlayerID]
    if player == nil or player:IsHuman() ~= true then
        return
    end

    if orderType ~= ORDER_CONSTRUCT
        or canceled == true
        or canceled == 1 then
        return
    end

    local building = GameInfo.Buildings[itemType]
    if building == nil or building.BuildingType ~= BUILDING_TYPE then
        return
    end

    local city = CityManager.GetCity(playerID, cityID)
    if city == nil or city:GetOwner() ~= localPlayerID then
        Log("ignored completion with unresolved/non-local city")
        return
    end

    local cityBuildings = city:GetBuildings()
    if cityBuildings == nil or not cityBuildings:HasBuilding(building.Index) then
        Log("ignored completion before building state was available")
        return
    end

    if city:GetProperty(SHOWN_PROPERTY) ~= nil then
        Log("persistent duplicate ignored for city=" .. tostring(cityID))
        return
    end

    local sessionKey = tostring(playerID) .. ":" .. tostring(cityID)
    if m_sessionShown[sessionKey] == true or m_isVisible then
        Log("session duplicate ignored for city=" .. tostring(cityID))
        return
    end

    m_sessionShown[sessionKey] = true
    Show(localPlayerID, cityID)
end

local function OnCityProductionCompleted(...)
    local success, message = pcall(HandleCityProductionCompleted, ...)
    if not success then
        Log("ERROR in CityProductionCompleted: " .. tostring(message))
        Close()
    end
end

local function OnInputHandler(input)
    if input:GetMessageType() == KeyEvents.KeyUp
        and input:GetKey() == Keys.VK_ESCAPE then
        Close()
        return true
    end
    return false
end

local function OnSystemUpdateUI(updateType)
    if updateType == SystemUpdateUI.ScreenResize and m_isVisible then
        Resize()
    end
end

local function Initialize()
    if m_isRegistered then
        Log("duplicate registration ignored")
        return
    end

    if Controls.PopupPanel == nil
        or Controls.PopupImage == nil
        or Controls.Caption == nil
        or Controls.Title == nil
        or Controls.ContinueButton == nil then
        error("required popup controls were not created")
    end

    m_isRegistered = true
    ContextPtr:SetHide(true)
    ContextPtr:SetInputHandler(OnInputHandler, true)
    Controls.ContinueButton:RegisterCallback(Mouse.eLClick, Close)
    Events.CityProductionCompleted.Add(OnCityProductionCompleted)
    Events.SystemUpdateUI.Add(OnSystemUpdateUI)
    Log("controller loaded")
end

local initializeSuccess, initializeMessage = pcall(Initialize)
if not initializeSuccess then
    Log("ERROR initializing popup: " .. tostring(initializeMessage))
    pcall(function()
        ContextPtr:SetHide(true)
    end)
end
