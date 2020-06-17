class 'VehicleWeapons'

function VehicleWeapons:__init()

    -- TODO: add support for multiple shots at once (aka 2 rockets at once for helis)
    self.vehicles_with_weapons = 
    {
        -- Each has weapon1, weapon2 ids for use with weaponenum
        [16] = 
        {
            [VehicleSeat.MountedGun1] = {FireLeft = WeaponEnum.V_MachineGun}
        }, -- YP-107 Phoenix 
        [18] = 
        {
            [VehicleSeat.MountedGun1] = {FireLeft = WeaponEnum.V_Minigun}
        }, -- SV-1003 Raider
        [48] = 
        {
            [VehicleSeat.MountedGun1] = {FireLeft = WeaponEnum.V_MachineGun}
        }, -- Maddox FVA 45
        [56] = 
        {
            [VehicleSeat.Driver] = {FireRight = WeaponEnum.V_Cannon}
        }, -- GV-104 Razorback
        [72] = 
        {
            [VehicleSeat.MountedGun1] = {FireLeft = WeaponEnum.V_MachineGun}
        }, -- Chepachet PVD
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
            [VehicleSeat.Driver] = {FireLeft = WeaponEnum.V_Minigun},
        }, -- Sivirkin 15 Havoc
        [57] = 
        {
            [VehicleSeat.Driver] = {FireLeft = WeaponEnum.V_Minigun},
        }, -- Sivirkin 15 Havoc
        [62] = 
        {
            [VehicleSeat.Driver] = {FireLeft = WeaponEnum.V_Minigun},
        }, -- UH-10 Chippewa
        [64] = 
        {
            [VehicleSeat.Driver] = {FireLeft = WeaponEnum.V_MachineGun, FireRight = WeaponEnum.V_Rockets},
        }, -- AH-33 Topachula
    }

end

-- Returns vehicle weapon enum
-- is_left is a boolean of whether they are firing left or right
function VehicleWeapons:GetPlayerVehicleWeapon(player, is_left)

    local v = player:GetVehicle() or player:GetValue("VehicleMG")
    local is_MG = IsValid(player:GetValue("VehicleMG"))

    if not IsValid(v) then return end

    -- Unsupported vehicle weapon
    local weapon_data = self.vehicles_with_weapons[v:GetModelId()]
    if not weapon_data then return false end

    local seat_index = v:GetDriver() == player and VehicleSeat.Driver or nil

    if is_MG then
        seat_index = VehicleSeat.MountedGun1
    end

    if seat_index == nil then return end

    local weapon = weapon_data[seat_index]

    if not weapon then return end

    if is_left == nil then return true end

    if is_left then
        return weapon.FireLeft
    else
        return weapon.FireRight
    end

end

VehicleWeapons = VehicleWeapons()