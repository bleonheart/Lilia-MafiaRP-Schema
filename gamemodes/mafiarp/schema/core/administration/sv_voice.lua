GM = GM or GAMEMODE

function GM:PlayerCanHearPlayersVoice(listener, speaker)
    local VoiceRadios = lia.plugin.list.radio
    local ImprovedTying = lia.plugin.list.tying
    local ImprovedVoice = lia.plugin.list.improvedvoice
    local distance = 600 * 600
    local allowVoice = lia.config.get("allowVoice")

    if allowVoice then
        if listener:GetPos():DistToSqr(speaker:GetPos()) < distance then
            return true, true
        else
            if ImprovedVoice then
                if hook.Run("PlayerCanHearPlayersVoiceHook3DVoice", listener, speaker) then return true end
            end

            if ImprovedTying then
                if hook.Run("PlayerCanHearPlayersVoiceHookTying", listener, speaker) then return true end
            end

            if VoiceRadios then
                if hook.Run("PlayerCanHearPlayersVoiceHookRadio", listener, speaker) then return true end
            end
        end
    end

    return false, false
end