class 'VehicleWeapons'

function VehicleWeapons:__init()

    -- TODO: add support for multiple shots at once (aka 2 rockets at once for helis)
    self.vehicles_with_weapons = 
    {
        -- Each has weapon1, weapon2 ids for use with weaponenum
        [18] = 
        {
            [VehicleSeat.MountedGun1] = {FireLeft = WeaponEnum.V_Minigun}
        }, -- SV-1003 Raider
        [56] = 
        {
            [VehicleSeat.Driver] = {FireRight = WeaponEnum.V_Cannon}
        }, -- GV-104 Razorback
        [75] = 
        {
            [VehicleSeat.Driver] = {FireRight = WeaponEnum.V_Cannon}
        }, -- Tuk Tuk Boom Boom
        [69] = 
        {
            [VehicleSeat.MountedGun1] = {FireLeft = WeaponEnum.V_Minigun},
            [VehicleSeat.MountedGun2] = {FireLeft = WeaponEnum.V_Minigun}
        }, -- Winstons Amen 69
        [88] = 
        {
            [VehicleSeat.Driver] = {FireLeft = WeaponEnum.V_MachineGun},
        }, -- MTA Powerrun 77
        [3] = 
        {
            -- TODO: support for templates
            --[VehicleSeat.Driver] = {FireLeft = WeaponEnum.V_MachineGun},
        },  -- Rowlinson K22
        [30] = 
        {
            [VehicleSeat.Driver] = {FireRight = WeaponEnum.V_Rockets, FireLeft = WeaponEnum.V_Minigun},
        }, -- Si-47 Leopard
        [34] = 
        {
            [VehicleSeat.Driver] = {FireRight = WeaponEnum.V_Rockets, FireLeft = WeaponEnum.V_Cannon},
        }, -- G9 Eclipse
        [37] = 
        {
            [VehicleSeat.Driver] = {FireLeft = WeaponEnum.V_MachineGun},
        }, -- Sivirkin 15 Havoc
        [57] = 
        {
            [VehicleSeat.Driver] = {FireLeft = WeaponEnum.V_MachineGun},
        }, -- Sivirkin 15 Havoc
        [62] = 
        {
            [VehicleSeat.Driver] = {FireLeft = WeaponEnum.V_MachineGun},
        }, -- UH-10 Chippewa
        [64] = 
        {
            [VehicleSeat.Driver] = {FireLeft = WeaponEnum.V_MachineGun, FireRight = WeaponEnum.V_Rockets},
        }, -- AH-33 Topachula
    }

end

VehicleWeapons = VehicleWeapons()