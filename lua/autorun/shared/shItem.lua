class 'shItem'

function shItem:__init(args)

    if 
    not args or 
    not args.name or 
    not args.amount or 
    args.amount < 1 or
    not args.category or 
    not args.rarity or 
    not args.stacklimit 
    then
        error("shItem:__init failed: missing a key piece of information")
        print(debug.traceback())
    end

    if not CategoryExists(args.category) then
        error("shItem:__init failed: category does not exist: " .. args.category)
        print(debug.traceback())
    end

    self.uid = args.uid or GetUID()
    self.name = args.name
    self.amount = args.amount
    self.category = args.category
    self.rarity = args.rarity
    self.stacklimit = args.stacklimit
    self.durable = args.durable
    self.custom_data = args.custom_data or {}
    self.nodrop = args.nodrop or false

    self:GetCustomData();

    if args.equipped then
        self.equipped = args.equipped
    end

    if args.durability then

        if args.amount > 1 then
            error("shItem:__init failed: durability was given but item had more than one amount")
        end

        self.durability = args.durability

        if args.max_durability then
            self.max_durability = args.max_durability
        else
            error("shItem:__init failed: max_durability was not given when an item had durability")
        end
    end

    self.in_loot = args.in_loot ~= false

    if args.can_equip then
        self.can_equip = args.can_equip

        if args.equip_type == nil then
            error("shItem:__init failed: equip_type was not given for an equippable item: " .. tostring(self.name))
        end

        self.equip_type = args.equip_type
    elseif args.can_use then

        self.can_use = args.can_use
    end

end

-- Gets custom data if there is any
function shItem:GetCustomData()

    -- Custom data logic here

end

function shItem:Equals(item)

    return -- TODO check custom properties
        self.name == item.name and
        self.amount == item.amount and
        self.category == item.category and
        self.rarity == item.rarity and
        self.stacklimit == item.stacklimit and
        self.can_use == item.can_use and
        self.equip_type == item.equip_type and
        self.durable == item.durable and
        self.durability == item.durability and
        self.equipped == item.equipped and
        self:EqualsCustomData(item)

end

function shItem:EqualsCustomData(item)

    for property, data in ipairs(self.custom_data) do 
        if self.custom_data[property] ~= item.custom_data[property] then
            return false
        end
    end

    return true

end

-- Returns a copy of this item
function shItem:Copy()

    return shItem(self)

end

function shItem:GetSyncObject()

    return {
        uid = self.uid,
        name = self.name,
        amount = self.amount,
        category = self.category,
        rarity = self.rarity,
        stacklimit = self.stacklimit,
        durable = self.durable,
        durability = self.durability,
        can_equip = self.can_equip,
        can_use = self.can_use,
        equipped = self.equipped,
        max_durability = self.max_durability,
        equip_type = self.equip_type,
        nodrop = self.nodrop,
        custom_data = self.custom_data
    }

end

function shItem:ToString()

    return self.name .. " [x" .. self.amount .. "] " .. self.uid .. " " .. self.category .. " "
    .. self.stacklimit .. " " .. concat_bool(self.durability) .. " " .. concat_bool(self.max_durability) .. " " 
    .. concat_bool(self.can_equip) .. " " .. concat_bool(self.can_use) .. " " .. concat_bool(self.equipped) .. " " .. concat_bool(self.equip_type)

end

function concat_bool(b)

    return b and "true" or "false"

end