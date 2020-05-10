class 'sInventoryManager'


function sInventoryManager:__init()

    self.inventories = {}

    Events:Subscribe("ModuleUnload", self, self.Unload)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)

    Events:Subscribe("PlayerExpLoaded", self, self.PlayerExpLoaded)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)

end

function sInventoryManager:PlayerQuit(args)

    if self.inventories[tostring(args.player:GetSteamId().id)] then
        self.inventories[tostring(args.player:GetSteamId().id)]:Unload()
        self.inventories[tostring(args.player:GetSteamId().id)] = nil
    end

end

function sInventoryManager:Unload()

    Events:Fire("InventoryUnload")

    for player in Server:GetPlayers() do
        player:SetValue("Inventory", nil)
    end

end

function sInventoryManager:ClientModuleLoad(args)

    if not args.player:GetValue("Exp") then
        args.player:SetValue("InventoryWaitingForExp", true)
        return
    end
    
    if self.inventories[tostring(args.player:GetSteamId().id)] then
        self.inventories[tostring(args.player:GetSteamId().id)]:Unload()
        self.inventories[tostring(args.player:GetSteamId().id)] = nil
    end

    self.inventories[tostring(args.player:GetSteamId().id)] = sInventory(args.player)

    sStashes:ClientModuleLoad(args)

end

function sInventoryManager:PlayerExpLoaded(args)
    if args.player:GetValue("InventoryWaitingForExp") then
        args.player:GetValue("InventoryWaitingForExp", false)
        self:ClientModuleLoad(args)
    end
end

InventoryManager = sInventoryManager()