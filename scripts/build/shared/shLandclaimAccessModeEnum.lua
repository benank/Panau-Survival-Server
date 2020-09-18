class 'LandclaimAccessModeEnum'

function LandclaimAccessModeEnum:__init()

    self.OnlyMe = 1
    self.Friends = 2
    self.Everyone = 3
    self.Clan = 4

    self.descriptions = 
    {
        [self.OnlyMe] = "Only Me",
        [self.Friends] = "Friends",
        [self.Everyone] = "Everyone",
        [self.Clan] = "Clan"
    }

end

function LandclaimAccessModeEnum:GetDescription(enum)
    return self.descriptions[enum]
end

LandclaimAccessModeEnum = LandclaimAccessModeEnum()