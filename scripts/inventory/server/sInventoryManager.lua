class 'sInventoryManager'


function sInventoryManager:__init()

    self.inventories = {}

    Events:Subscribe("ModuleUnload", self, self.Unload)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("PlayerChat", self, self.PlayerChat)

    Events:Subscribe("LoadFlowFinish", self, self.LoadFlowFinish)

end

function sInventoryManager:PlayerChat(args)

    if not IsAdmin(args.player) then return end

    local player_id = tostring(args.player:GetSteamId().id)
    local words = args.text:split(" ")

    if words[1] == "/invsee" then

        -- First disable invsee if it exists
        local old_invsee_id = self.inventories[player_id].invsee_source
        if old_invsee_id then
            if self.inventories[old_invsee_id] then
                self.inventories[old_invsee_id].invsee[player_id] = nil
            end
            self.inventories[player_id].invsee_source = nil
            self.inventories[player_id].contents = self.inventories[player_id].invsee_old_data.contents
            self.inventories[player_id].slots = self.inventories[player_id].invsee_old_data.slots
            self.inventories[player_id].invsee_old_data = nil

            self.inventories[player_id]:Sync({sync_full = true})
            self.inventories[player_id].invsee_source = nil
        end

        local target = args.text:gsub("/invsee", ""):trim()

        if target:len() > 0 then

            target = Player.Match(target)[1]

            if not IsValid(target) then
                Chat:Send(args.player, "No valid player found.", Color.Red)
                return
            end

            local target_id = tostring(target:GetSteamId().id)

            self.inventories[target_id].invsee[player_id] = self.inventories[player_id]
            self.inventories[player_id].invsee_source = target_id

            self.inventories[player_id].invsee_old_data = 
            {
                contents = self.inventories[player_id].contents,
                slots = self.inventories[player_id].slots
            }

            self.inventories[player_id].contents = self.inventories[target_id].contents
            self.inventories[player_id].slots = self.inventories[target_id].slots

            self.inventories[player_id]:Sync({sync_full = true})

            Chat:Send(args.player, string.format("Viewing %s's inventory.", target:GetName()), Color.Green)

        end

    end

end

function sInventoryManager:PlayerQuit(args)

    local id = tostring(args.player:GetSteamId().id)
    if self.inventories[id] then
        self.inventories[id]:Unload()
        self.inventories[id] = nil
    end

end

function sInventoryManager:Unload()

    Events:Fire("InventoryUnload")

    for steamid, inventory in pairs(self.inventories) do
        inventory:Unload()
    end

    for player in Server:GetPlayers() do
        player:SetValue("Inventory", nil)
    end

end

function sInventoryManager:LoadFlowFinish(args)

    if self.inventories[tostring(args.player:GetSteamId().id)] then
        self.inventories[tostring(args.player:GetSteamId().id)]:Unload()
        self.inventories[tostring(args.player:GetSteamId().id)] = nil
    end

    self.inventories[tostring(args.player:GetSteamId().id)] = sInventory(args.player)

    sStashes:ClientModuleLoad(args)

end

InventoryManager = sInventoryManager()