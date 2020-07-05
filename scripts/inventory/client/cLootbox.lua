class 'cLootbox'

function cLootbox:__init(args)

    self.uid = args.uid
    self.cell = args.cell
    self.position = args.position
    self.angle = args.angle
    self.tier = args.tier
    self.active = args.active
    self.model_data = args.model_data
    self.static_objects = {}
    self.contents = args.contents or {}
    self.stash = args.stash
    self.locked = args.locked
    self.hidden = false

    self:CreateModel()

end

function cLootbox:Remove(no_event)

    if not no_event then
        Events:Fire("Inventory/LootboxRemove", {
            id = self.uid,
            tier = self.tier,
            cso_id = self.cso_id
        })

        self.active = false
    end

    if no_event then
        self.hidden = true
    end

    for _, obj in pairs(self.static_objects) do
        if IsValid(obj) then 
            obj:Remove()
            LootManager.objects[obj:GetId()] = nil
        end
    end

    self.static_objects = {}

end

function cLootbox:CreateModel()

    if not self.active then return end

    local position = self.position + self.model_data.offset
    self.look_position = self.position + self.angle * (self.model_data.look_offset and self.model_data.look_offset or Vector3())

    table.insert(self.static_objects, 
        ClientStaticObject.Create({
            position = position,
            angle = self.angle,
            model = self.model_data.model,
            collision = self.model_data.col
        }))

    if self.model_data.top_model then

        table.insert(self.static_objects, 
            ClientStaticObject.Create({
                position = position + self.angle * self.model_data.offset2,
                angle = self.angle,
                model = self.model_data.top_model,
                collision = self.model_data.top_col
            }))

    end

    if self.model_data.model2 then

        table.insert(self.static_objects, 
            ClientStaticObject.Create({
                position = self.position - Vector3(0, 1, 0) + self.model_data.offset,
                angle = self.angle,
                model = self.model_data.model2
            }))

    end

    -- Enable outlines
    for _, obj in pairs(self.static_objects) do
        --obj:SetOutlineColor(Color(255,255,255,100))
        --obj:SetOutlineEnabled(true)

        -- Register static object ids in uid lookup table
        obj:SetValue("LootboxId", self.uid)
        LootManager.SO_id_to_uid[obj:GetId()] = self.uid
        LootManager.objects[obj:GetId()] = obj
    end

    self.hidden = false

    self.cso_id = self.static_objects[1]:GetId()

    Events:Fire("Inventory/LootboxCreate", {
        id = self.uid,
        cso_id = self.static_objects[1]:GetId(),
        tier = self.tier,
        position = self.position,
        angle = self.angle
    })

end