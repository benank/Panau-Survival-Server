class 'LandclaimAccessModeEnum'

function LandclaimAccessModeEnum:__init()

    self.OnlyMe = 1
    self.Friends = 2
    self.Clan = 3
    self.Everyone = 4

    self.descriptions = 
    {
        [self.OnlyMe] = "Only Me",
        [self.Friends] = "Friends",
        [self.Clan] = "Clan",
        [self.Everyone] = "Everyone"
    }

end

function LandclaimAccessModeEnum:GetDescription(enum)
    return self.descriptions[enum]
end

LandclaimAccessModeEnum = LandclaimAccessModeEnum()