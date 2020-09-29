class 'sLandclaimObject'

-- Data container for objects within landclaims
function sLandclaimObject:__init(args)

    self.id = args.id -- Unique object id per claim, changes every reload
    self.owner_id = args.owner_id -- Steam id of player who placed it
    self.owner_name = args.owner_name
    self.name = args.name
    self.position = type(args.position) == "string" and DeserializePosition(args.position) or args.position
    self.angle = type(args.angle) == "string" and DeserializeAngle(args.angle) or args.angle
    self.health = args.health
    self.custom_data = args.custom_data or self:GetDefaultCustomData()

end

function sLandclaimObject:Damage(amount)
    self.health = math.max(0, self.health - math.abs(amount))
end

-- Removes all existing spawns from this bed object if they exist
function sLandclaimObject:RemoveAllBedSpawns()
    if self.name ~= "Bed" then return end

    for steam_id, _ in pairs(self.custom_data.player_spawns) do
        Events:Fire("ResetHomePosition", {
            player_id = tostring(SteamId(steam_id).id),
            player = sLandclaimManager.players[steam_id]
        })
    end

end

-- Get default custom data for an object when it is first placed, like a door access mode
function sLandclaimObject:GetDefaultCustomData()
    
    local custom_data = {}

    if self.name == "Door" then
        custom_data.access_mode = LandclaimAccessModeEnum.OnlyMe
        custom_data.open = false
    elseif self.name == "Light" then
        custom_data.enabled = true -- If the light is turned on or not
    elseif self.name == "Bed" then
        custom_data.player_spawns = {} -- List of player spawns for this bed
    end

    return custom_data
end

function sLandclaimObject:GetSerializable()
    local data = self:GetSyncObject()
    data.id = nil
    data.angle = SerializeAngle(data.angle)
    data.position = SerializePosition(data.position)
    return data
end

function sLandclaimObject:GetSyncObject()

    return {
        id = self.id,
        name = self.name,
        angle = self.angle,
        position = self.position,
        health = self.health,
        owner_id = self.owner_id,
        owner_name = self.owner_name,
        custom_data = self.custom_data
    }

end