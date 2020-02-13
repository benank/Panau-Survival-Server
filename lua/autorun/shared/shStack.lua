class 'shStack'

function shStack:__init(args)

    if not args.contents or #args.contents == 0 then
        error("shStack:__init failed: contents is empty")
    end

    self.uid = args.uid or GetUID()
    self.contents = args.contents
    
    self:UpdateProperties()

end

function shStack:GetProperty(property)

    return self.properties[property]

end

function shStack:GetAmount()

    return (#self.contents == 0 or not self.contents[1] or (self:GetProperty("durable") or self:GetProperty("can_equip"))) and 
        #self.contents or 
        self.contents[1].amount

end

function shStack:UpdateProperties()

    self.properties = 
    {
        name = self.contents[1].name,
        amount = self.contents[1].amount,
        category = self.contents[1].category,
        rarity = self.contents[1].rarity,
        stacklimit = self.contents[1].stacklimit,
        durable = self.contents[1].durable,
        durability = self.contents[1].durability,
        can_equip = self.contents[1].can_equip,
        can_use = self.contents[1].can_use,
        equipped = self.contents[1].equipped,
        max_durability = self.contents[1].max_durability,
        equip_type = self.contents[1].equip_type,
        nodrop = self.contents[1].nodrop,
    }

end

-- If at least one item in the stack is equipped
function shStack:GetOneEquipped()

    for k,v in pairs(self.contents) do
        if v.equipped then return true end
    end

end

function shStack:AddStack(_stack)

    local stack = _stack:Copy()

    if not self:CanStack(stack.contents[1]) then
        error("shStack:AddStack failed: the stack cannot be added to the stack")
    end

    if self:GetAmount() >= self:GetProperty("stacklimit") then
        return stack
    end

    while stack:GetAmount() > 0 and self:GetAmount() < self:GetProperty("stacklimit") do

        if stack:GetAmount() > 1 then
            self:AddItem(stack:Split(1).contents[1])
        else
            self:AddItem(stack.contents[1])
            stack:RemoveItem(stack.contents[1])
        end

    end

    if stack:GetAmount() > 0 then
        return stack
    end

end

-- Adds an item to the stack. Returns any items that could not fit into the stack
function shStack:AddItem(_item)

    local item = _item:Copy()

    if not self:CanStack(item) then
        error("shStack:AddItem failed: the item cannot be added to the stack")
    end

    if self:GetAmount() >= self:GetProperty("stacklimit") then
        return item
    end

    -- Adding an item with durability, which means it is a single item
    if self:GetProperty("durable") or self:GetProperty("can_equip") or not self.contents[1] then

        table.insert(self.contents, item)

    else

        local amount_to_add = math.min(item.amount, self:GetProperty("stacklimit") - self:GetAmount())
        item.amount = item.amount - amount_to_add
        self.contents[1].amount = self.contents[1].amount + amount_to_add

        if item.amount > 0 then
            return item
        end

    end

end

function shStack:RemoveStack(_stack)

    local stack = _stack:Copy()

    while stack:GetAmount() > 0 and self:GetAmount() > 0 do

        self:RemoveItem(stack:RemoveItem(nil, nil, true))

    end

    if stack and stack:GetAmount() > 0 then
        return stack
    end

end

-- Removes an item from the stack, and returns it if index is specified
function shStack:RemoveItem(_item, index, only_one)

    if index ~= nil then

        if not self.contents[index] then
            error(string.format("shStack:RemoveItem failed: the specified index %s does not exist in the contents", index))
        end

        return table.remove(self.contents, index)
    end

    if only_one then

        if self.can_equip or self.durable then -- If there are durable or equippable items in here
            return table.remove(self.contents, 1)
        else
            local copy = self.contents[1]:Copy()
            copy.amount = 1
            self.contents[1].amount = self.contents[1].amount - 1
            return copy
        end
    end

    local item = _item:Copy()

    if not self:CanStack(item) then
        error("shStack:RemoveItem failed: the item cannot be removed from the stack")
    end

    if item.amount > self:GetAmount() then
        error("shStack:RemoveItem failed: the amount you are trying to remove is greater than the total amount in the stack")
    end

    if not item.durable and not item.can_equip then
        self.contents[1].amount = self.contents[1].amount - math.min(item.amount, self:GetAmount())
        item.amount = item.amount - math.min(item.amount, self:GetAmount())
        return item.amount > 0 and item or nil
    else
        -- Remove by uid
        for i = 1, self:GetAmount() do
            if self.contents[i].uid == item.uid then
                table.remove(self.contents, i)
                return;
            end
        end
    end

    if item then
        error("shStack:RemoveItem failed: something went wrong and the item failed to remove")
    end

end

-- Returns whether or not at least one of the items in the stack is equipped
function shStack:GetEquipped()

    for i = 1, self:GetAmount() do
        if self.contents[i] and self.contents[i].equipped then
            return true
        end
    end

    return false

end

-- Shifts the items in the stack
function shStack:Shift()

    table.insert(self.contents, 1, table.remove(self.contents, #self.contents));

end

-- Splits a stack into two stacks based on the amount specified and returns the new stack
function shStack:Split(amount)

    if amount < 1 or amount > self:GetAmount() then return end
    if amount == self:GetAmount() then return self end

    local removed_items = {}

    if #self.contents > 1 then
        for i = 1, amount do
            table.insert(removed_items, table.remove(self.contents, 1))
        end
    else
        self.contents[1].amount = self.contents[1].amount - amount
        local copy = self.contents[1]:Copy()
        copy.uid = GetUID() -- Regenerate uid
        copy.amount = amount
        table.insert(removed_items, copy)
    end

    return shStack({contents = removed_items})

end

-- Checks if this stack is the exact same as another stack
function shStack:Equals(stack)

    for index, item in ipairs(self.contents) do 
        if not item:Equals(stack[index]) then
            return false
        end
    end

    return true

end

function shStack:Copy()

    return shStack(self)

end

-- Returns whether or not an item can be stacked on this stack
function shStack:CanStack(item)

    return 
        item.name == self:GetProperty("name") and
        item.category == self:GetProperty("category") and
        item.stacklimit == self:GetProperty("stacklimit") and
        item.rarity == self:GetProperty("rarity") and
        item.can_equip == self:GetProperty("can_equip") and
        item.durable == self:GetProperty("durable")

end

function shStack:GetSyncObject()

    local data = {contents = {}, uid = self.uid}

    for k,v in pairs(self.contents) do
        data.contents[k] = v:GetSyncObject()
    end

    return data

end