class 'cInventory'

function cInventory:__init()

    Events:Fire("loader/RegisterResource", {count = 2})

    Network:Send(var("InventoryRequest"):get())

    Network:Subscribe(var("InventoryUpdated"):get(), self, self.InventoryUpdated)

    Events:Fire("loader/CompleteResource", {count = 1})

    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)

end

function cInventory:ModulesLoad()

    local contents = {}

    for cat, _ in pairs(Inventory.contents) do
        contents[cat] = {}
        for index, stack in ipairs(Inventory.contents[cat]) do
            contents[cat][index] = {stack = stack:GetSyncObject(), uid = stack.uid}
        end
    end

    Events:Fire(var("InventoryUpdated"):get(), {data = {contents = contents, slots = Inventory.slots}, action = "full"})

end

function cInventory:InventoryUpdated(args)

    Events:Fire(var("InventoryUpdated"):get(), args)
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