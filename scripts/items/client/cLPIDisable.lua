local blacklist = {
    [Action.NextWeapon] = true,
    --[Action.PrevWeapon] = true,
    [Action.SwitchWeapon] = true,
    [Action.Weapon0] = true,
    [Action.Weapon1] = true,
    [Action.Weapon2] = true,
    [Action.Weapon3] = true,
    [Action.Weapon4] = true,
    [Action.Weapon5] = true,
    [Action.Weapon6] = true,
    [Action.Weapon7] = true,
    [Action.Weapon8] = true,
    [Action.Weapon9] = true,
    [Action.SequenceButton1] = true,
    [Action.SequenceButton2] = true,
    [Action.SequenceButton3] = true,
    [Action.SequenceButton4] = true,
    [Action.EquipBlackMarketBeacon] = true,
    [Action.EquipDual] = true,
    [Action.EquipExplosive] = true,
    [Action.EquipLeftSlot] = true,
    [Action.EquipRightSlot] = true,
    [Action.EquipTwohanded] = true
}

Events:Subscribe("LocalPlayerInput", function(args)

    if blacklist[args.input] then return false end

end)