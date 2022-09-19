

local strings = 
{
    title = {
        "Welcome to",
        "Panau Survival"
    },
    play_button = {
        "Play"
    },
    tutorial_button = {
        "Learn the Basics (Tutorial)"
    }
}

class 'sIntroScreen'

function sIntroScreen:__init()
    
    self.default_stream_distance = 1024
    
    Events:Subscribe("LoadStatus", self, self.LoadStatus)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    
    Network:Subscribe("intro/Play", self, self.Play)
    Network:Subscribe("intro/Tutorial", self, self.Tutorial)
end

function sIntroScreen:Play(args, player)
    self:TogglePlayerInIntroScreen(player, false)
end

function sIntroScreen:Tutorial(args, player)
    self:TogglePlayerInIntroScreen(player, false)
end

function sIntroScreen:LoadStatus(args)
    -- Player finished loading
    if not args.player:GetValue("FirstLoad") then
        self:TogglePlayerInIntroScreen(args.player, true)
    end
    args.player:SetValue("FirstLoad", true)
end

function sIntroScreen:ClientModuleLoad(args)
    self:TogglePlayerInIntroScreen(args.player, true) 
end

function sIntroScreen:TogglePlayerInIntroScreen(player, in_intro_screen)
    if in_intro_screen then

        player:SetNetworkValue("InIntroScreen", true)
        player:SetStreamDistance(0)
        player:SetEnabled(false)

    else

        player:SetEnabled(true)
        player:SetStreamDistance(self.default_stream_distance)
        player:SetNetworkValue("InIntroScreen", false)

    end
end

sIntroScreen = sIntroScreen()