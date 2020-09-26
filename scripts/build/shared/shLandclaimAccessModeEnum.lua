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

    self.descriptions_to_enum = {}

    for enum, description in pairs(self.descriptions) do
        self.descriptions_to_enum[description] = enum
    end

end

function LandclaimAccessModeEnum:IsValidAccessMode(access_mode)
    for enum, description in pairs(self.descriptions) do
        if enum == access_mode then return true end
    end
end

function LandclaimAccessModeEnum:GetEnumFromDescription(description)
    return self.descriptions_to_enum[description]
end

function LandclaimAccessModeEnum:GetDescription(enum)
    return self.descriptions[enum]
end

LandclaimAccessModeEnum = LandclaimAccessModeEnum()