class 'sMines'

function sMines:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS mines (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR UNIQUE, position VARCHAR)")

    self.mines = {} -- Active mines

    self.sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()

    self:LoadAllMines()

    Network:Subscribe("items/CompleteItemUsage", self, self.CompleteItemUsage)
    Network:Subscribe("items/StepOnMine", self, self.StepOnMine)
end

function sMines:StepOnMine(args, player)

    if not args.id then return end
    local id = tonumber(args.id)

    local mine = self.mines[id]
    if not self.mines[id] then return end

    if mine:Explode(player) then

        -- Successfully exploded, remove mine
        local cmd = SQL:Command("DELETE FROM mines where id = ?")
        command:Bind(1, id)
        command:Execute()

        self.mines[id] = nil

    end

end

-- Load all mines from DB
function sMines:LoadAllMines()

    local result = SQL:Query("SELECT * FROM mines"):Execute()
    
    if #result > 0 then

        for _, mine_data in pairs(result) do
            local split = mine_data.position:split(",")
            local pos = Vector3(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))

            self.mines[mine_data.id] = sMine({
                id = mine_data.id,
                owner_id = mine_data.owner_id,
                position = pos
            })

    end

end

function sMines:PlaceMine(position, player)

    local steamID = tostring(player:GetSteamId())
    local cmd = SQL:Command("INSERT INTO mines (steamID, position) VALUES (?, ?)")
    command:Bind(1, steamID)
    command:Bind(2, tostring(position))
    command:Execute()

    local mine = sMine({
        position = position, 
        owner_id = steamID -- TODO: add friends to it as well
    })

    self.mines[]

end

-- args.ray = raycast down
function sMines:TryPlaceMine(args, player)

    -- If they are within sz radius * 2, we don't let them place that close
    if args.player:Distance(self.sz_config.safezone.position) < self.sz_config.safezone.radius * 2 then
        Chat:Send(player, "Cannot place mines while in a vehicle!", Color.Red)
        return
    end

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and player_iu.item.name == "Mine" then

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        -- Now actually place the mine
        self:PlaceMine(args.ray.position, player)

    end


end

function sMines:CompleteItemUsage(args, player)

    if player:InVehicle() then
        Chat:Send(player, "Cannot place mines while in a vehicle!", Color.Red)
        return
    end

    if not args.ray or args.ray.distance >= 5 then
        Chat:Send(player, "Placing mine failed!", Color.Red)
        return
    end

    if args.ray.position:Distance(player:GetPosition() > 5) then
        Chat:Send(player, "Placing mine failed!", Color.Red)
        return
    end

    self:TryPlaceMine(args, player)

end

sMines = sMines()