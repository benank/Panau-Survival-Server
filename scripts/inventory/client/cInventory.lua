class 'cInventory'

function cInventory:__init()

    Events:Fire("loader/RegisterResource", {count = 2})

    Network:Subscribe(var("InventoryUpdated"):get(), self, self.InventoryUpdated)
    Network:Subscribe(var("Inventory/GetGroundData"):get(), self, self.GetGroundData)

    Events:Fire("loader/CompleteResource", {count = 1})

    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)

end

function cInventory:GetGroundData()
    local start_pos = LocalPlayer:GetBonePosition("ragdoll_Spine")

    local ray = Physics:Raycast(start_pos, Vector3.Down, 0, 1000)

    if LocalPlayer:GetValue("CloudStriderBootsEquipped") and IsValid(ray.entity) then
        if ray.entity.__type == "ClientStaticObject" and ray.entity:GetCollision() == "34x09.flz/go003_lod1-a_col.pfx" then
            start_pos = start_pos - Vector3(0, 4, 0)
            ray = Physics:Raycast(start_pos, Vector3.Down, 0, 1000)
        end
    end

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