Events:Subscribe("LocalPlayerInput", function(args)

    if args.input == Action.FireRight then

        local weapon = LocalPlayer:GetEquippedWeapon()

        if weapon and (weapon.ammo_clip > 0 or weapon.ammo_reserve > 0) then
            Network:Send("Items/FireWeapon")
        end

    end

end)

-- Forces the weapon to come out (and go into player's hands rather than under their legs lol)
Network:Subscribe("items/ForceWeaponSwitch", function()

    Timer.SetTimeout(750, function()
        
        local input_sub = Events:Subscribe("InputPoll", function(args)
            Input:SetValue(Action.PrevWeapon, 1)
        end)

        Timer.SetTimeout(250, function()
            Events:Unsubscribe(input_sub)
        end)

    end)

end)