-- Preserve the complete official LoadScreen implementation and add only the
-- XJY custom narration call. This replacement is registered by the InGame
-- action, after XJY_LOADING_AUDIO has been loaded.
include("LoadScreen")

local LEADER_TYPE = "LEADER_XJY_XU_JIAYIN"
local EVENT_LOADING_NARRATION = "PLAY_XJY_LOADING_NARRATION"

local m_eventAttempted = false

print("[XJY][LoadingNarration] context loaded")

local function ResolveLoadingLeader()
	local localPlayerID = Network.GetLocalPlayerID()

	if GameConfiguration.IsHotseat() then
		local maxPlayers = MapConfiguration.GetMaxMajorPlayers()
		for playerID = 0, maxPlayers - 1 do
			local playerConfig = PlayerConfigurations[playerID]
			if playerConfig ~= nil
				and playerConfig:GetSlotStatus() == SlotStatus.SS_TAKEN then
				localPlayerID = playerID
				break
			end
		end
	end

	local playerConfig = localPlayerID ~= nil
		and localPlayerID >= 0
		and PlayerConfigurations[localPlayerID]
		or nil
	local leaderType = playerConfig ~= nil
		and playerConfig:GetLeaderTypeName()
		or "<unresolved>"

	print("[XJY][LoadingNarration] leader resolved: " .. tostring(leaderType))
	return leaderType
end

local function PostLoadingNarration()
	if m_eventAttempted
		or GameConfiguration.IsWorldBuilderEditor()
		or GameConfiguration.IsSavedGame() then
		return
	end

	if ResolveLoadingLeader() ~= LEADER_TYPE then
		return
	end

	m_eventAttempted = true

	if UI == nil or type(UI.PlaySound) ~= "function" then
		print(
			"[XJY][LoadingNarration] event not posted: UI.PlaySound unavailable; event="
			.. EVENT_LOADING_NARRATION
		)
		return
	end

	local callOK, apiResult = pcall(UI.PlaySound, EVENT_LOADING_NARRATION)
	print(
		"[XJY][LoadingNarration] event posted: event="
		.. EVENT_LOADING_NARRATION
		.. ", pcall="
		.. tostring(callOK)
		.. ", return="
		.. tostring(apiResult)
		.. " (nil is not playback confirmation)"
	)
end

local XJY_OriginalOnLoadScreenContentReady = OnLoadScreenContentReady
Events.LoadScreenContentReady.Remove(XJY_OriginalOnLoadScreenContentReady)

function OnLoadScreenContentReady()
	XJY_OriginalOnLoadScreenContentReady()
	PostLoadingNarration()
end

Events.LoadScreenContentReady.Add(OnLoadScreenContentReady)
