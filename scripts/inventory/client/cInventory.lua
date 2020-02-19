class 'cInventory'

function cInventory:__init()

    Events:Fire("loader/RegisterResource", {count = 2})

    Network:Send("InventoryRequest")

    Network:Subscribe("InventoryUpdated", self, self.InventoryUpdated)

    Events:Fire("loader/CompleteResource", {count = 1})

    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)

end

function cInventory:ModulesLoad()

    local contents = {}

    for _, cat in pairs(Inventory.contents) do
        contents[cat] = {}
        for index, stack in ipairs(Inventory.contents) do
            contents[cat][index] = {stack = stack:GetSyncObject(), uid = stack.uid}
        end
    end

    Events:Fire("InventoryUpdated", {data = {contents = contents}, action = "full"})

end

function cInventory:InventoryUpdated(args)

    Events:Fire("InventoryUpdated", args)
    self.last_update = args

    if not self.ui then
        self.ui = cInventoryUI()
        self.lootbox_ui = cLootboxUI(self)
        Events:Fire("loader/CompleteResource", {count = 1})
    end

    self.ui:Update(args)

end


ClientInventory = nil

Events:Subscribe("LoaderReady", function()

    if not ClientInventory then
        ClientInventory = cInventory()
    end

end)