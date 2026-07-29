-- XJY in-game leader-theme lifecycle controller.
-- This context is local-player UI only; it does not alter gameplay state.

local LEADER_TYPE = "LEADER_XJY_XU_JIAYIN"
local EVENT_PLAY_THEME = "PLAY_XJY_LEADER_THEME"
local EVENT_STOP_THEME = "STOP_XJY_LEADER_THEME"

local m_isXJY = false
local m_playPosted = false
local m_turnFallbackRemoved = false

print("[XJY][LeaderMusic] formal controller loaded")

local function PostSoundEvent(eventName, purpose)
	if UI == nil or type(UI.PlaySound) ~= "function" then
		print(
			"[XJY][LeaderMusic] "
			.. purpose
			.. ": UI.PlaySound unavailable; event="
			.. eventName
		)
		return false
	end

	local callOK, apiResult = pcall(UI.PlaySound, eventName)
	print(
		"[XJY][LeaderMusic] "
		.. purpose
		.. ": event="
		.. eventName
		.. ", pcall="
		.. tostring(callOK)
		.. ", return="
		.. tostring(apiResult)
		.. " (nil is not playback confirmation)"
	)
	return callOK
end

local function IsLocalPlayerXJY()
	local localPlayerID = Game.GetLocalPlayer()
	if localPlayerID == nil or localPlayerID < 0 then
		print("[XJY][LeaderMusic] local leader resolved: <unresolved>")
		return false
	end

	local playerConfig = PlayerConfigurations[localPlayerID]
	local leaderType = playerConfig ~= nil
		and playerConfig:GetLeaderTypeName()
		or "<unresolved>"
	print("[XJY][LeaderMusic] local leader resolved: " .. tostring(leaderType))
	return leaderType == LEADER_TYPE
end

local function StartTheme(boundary)
	if not m_isXJY or m_playPosted then
		return
	end

	-- Stop first so a recreated UI context or a save reload cannot retain an
	-- older instance, then post exactly one infinite-loop PLAY event.
	PostSoundEvent(EVENT_STOP_THEME, "pre-start stop (" .. boundary .. ")")
	m_playPosted = PostSoundEvent(EVENT_PLAY_THEME, "play posted (" .. boundary .. ")")
	print("[XJY][LeaderMusic] play event posted: " .. tostring(m_playPosted))
end

local function OnLoadGameViewStateDone()
	m_isXJY = IsLocalPlayerXJY()
	if m_isXJY then
		PostSoundEvent(EVENT_STOP_THEME, "load-state stop")
	end
end

local function OnLoadScreenClose()
	if not m_isXJY then
		m_isXJY = IsLocalPlayerXJY()
	end
	StartTheme("load-screen-close")
end

local function OnLocalPlayerTurnBegin()
	if not m_isXJY then
		m_isXJY = IsLocalPlayerXJY()
	end
	StartTheme("first-turn fallback")

	if not m_turnFallbackRemoved then
		Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin)
		m_turnFallbackRemoved = true
		print("[XJY][LeaderMusic] first-turn fallback removed")
	end
end

local function OnShutdown()
	Events.LoadGameViewStateDone.Remove(OnLoadGameViewStateDone)
	Events.LoadScreenClose.Remove(OnLoadScreenClose)
	if not m_turnFallbackRemoved then
		Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin)
		m_turnFallbackRemoved = true
	end

	if m_isXJY then
		PostSoundEvent(EVENT_STOP_THEME, "shutdown stop")
	end
	print("[XJY][LeaderMusic] formal controller shutdown")
end

Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone)
Events.LoadScreenClose.Add(OnLoadScreenClose)
Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin)
ContextPtr:SetShutdown(OnShutdown)
