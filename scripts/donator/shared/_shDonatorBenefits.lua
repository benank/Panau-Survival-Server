DonatorLevel = 
{
    None = 0, -- For those who donated in the past but are no longer donating
    Donator = 1,
    Colorful = 2,
    GhostRider = 3,
    ShadowWings = 4,
    AvatarSpray = 5
}

DonatorBenefits = 
{
    [DonatorLevel.Donator] = 
    {
        DonatorTagEnabled = true,
    },
    [DonatorLevel.Colorful] = 
    {
        NameColor = Color(255, 255, 255), -- Default to player name color
        DonatorTagColor = Color(164, 95, 204),
        ColorStreakEnabled = true,
    },
    [DonatorLevel.GhostRider] = 
    {
        DonatorTagName = "Donator",
        GhostRiderHeadEnabled = true,
    },
    [DonatorLevel.ShadowWings] = 
    {
        ShadowWingsEnabled = true
    },
    [DonatorLevel.AvatarSpray] = 
    {
        AvatarSprayEnabled = true
    }
}