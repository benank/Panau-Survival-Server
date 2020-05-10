class 'cInventory'

function cInventory:__init()

    Events:Fire("loader/RegisterResource", {count = 2})

    Network:Subscribe(var("InventoryUpdated"):get(), self, self.InventoryUpdated)
    Network:Subscribe(var("Inventory/GetGroundData"):get(), self, self.GetGroundData)

    Events:Fire("loader/CompleteResource", {count = 1})

    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)

end

function cInventory:GetGroundData()
    local ray = Physics:Raycast(LocalPlayer:GetBonePosition("ragdoll_Spine"), Vector3.Down, 0, 1000)

    local ang = Angle.FromVectors(Vector3.Up, ray.normal) * Angle(math.random() * math.pi * 2, 0, 0)

    Network:Send(var("Inventory/GroundData" .. tostring(LocalPlayer:GetSteamId().id)):get(), {
        position = ray.position,
        angle = ang
    })
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