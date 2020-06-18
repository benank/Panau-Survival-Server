class 'shItem'

function shItem:__init(args)

    if 
    not args or 
    not args.name or 
    not args.amount or 
    args.amount < 1 or
    not args.category or 
    not args.stacklimit 
    then
        error(debug.traceback("shItem:__init failed: missing a key piece of information"))
    end

    if not CategoryExists(args.category) then
        error(debug.traceback("shItem:__init failed: category does not exist: " .. args.category))
    end

    self.uid = args.uid or GetUID()
    self.name = args.name
    self.amount = args.amount
    self.category = args.category
    self.stacklimit = args.stacklimit
    self.durable = args.durable
    self.custom_data = args.custom_data or {}
    self.nodrop = args.nodrop or false

    self:GetCustomData()

    if args.equipped then
        self.equipped = args.equipped
    end

    if args.durability then

        if args.amount > 1 then
            error(debug.traceback("shItem:__init failed: durability was given but item had more than one amount"))
        end

        self.durability = args.durability

        if args.max_durability then
            self.max_durability = args.max_durability
        else
            error(debug.traceback("shItem:__init failed: max_durability was not given when an item had durability"))
        end
    end

    self.in_loot = args.in_loot ~= false

    if args.can_equip then
        self.can_equip = args.can_equip

        if args.equip_type == nil then
            error(debug.traceback("shItem:__init failed: equip_type was not given for an equippable item: " .. tostring(self.name)))
        end

        self.equip_type = args.equip_type
    elseif args.can_use then

        self.can_use = args.can_use
    end

end

-- Gets custom data if there is any
function shItem:GetCustomData()

	-- Checks if item is Car Paint and does not yet have custom data assigned to it
    if self.name == "Car Paint" and not self.custom_data.color then
	
		-- Color rarity table
		local cRarity = {
			["Red"] = 0.1,
			["Green"] = 0.1,
			["Blue"] = 0.1,
			["Purple"] = 0.1,
			["Pink"] = 0.1,
			["Nyan"] = 0.1,
			["Lime"] = 0.1,
			["Orange"] = 0.1,
			["Yellow"] = 0.1,
			["White"] = 0.025,
            ["Black"] = 0.025,
            ["Brown"] = 0.025,
            ["DarkGreen"] = 0.025
		}
	
		-- Selects color and assigns to the item
		local sum = 0
		local target = math.random() 
		for name, rarity in pairs(cRarity) do
			sum = sum + rarity
			if target <= sum then
				self.custom_data.color = name
				break
			end
		end
		
	end
	
	-- Additional custom data will be added here

end

function shItem:Equals(item)

    return -- TODO check custom properties
        self.name == item.name and
        self.amount == item.amount and
        self.category == item.category and
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

    local msg = self.name .. " [x" .. self.amount .. "] "
    .. "SL: " .. self.stacklimit .. " Dura: " .. tostring(self.durability) .. "/" .. tostring(self.max_durability)

    if count_table(self.custom_data) > 0 then
        msg = msg .. " "
        for key, value in pairs(self.custom_data) do
            msg = msg .. tostring(key) .. ": " .. tostring(value) .. " "
        end
    end

    return msg

end

function concat_bool(b)

    return b and "true" or "false"

end