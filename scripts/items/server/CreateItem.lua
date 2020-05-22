function CreateItem(args)

    if not args.name or not args.amount or args.amount < 1 then
        print("CreateItem failed: missing name or amount")
        return nil
    end

    if not Items_indexed[args.name] then
        print("CreateItem failed: item was not found: " .. args.name)
        return nil
    end

    local data = deepcopy(Items_indexed[args.name])

    if data.durable then

        data.max_durability = data.max_durability and data.max_durability or Items.Config.default_durability
        data.durability = args.max_dura and data.max_durability or randy(
            math.ceil(Items.Config.min_durability_percent * data.max_durability),
            math.ceil(Items.Config.max_durability_percent * data.max_durability)
        )

    end

    data.equipped = false

    for k,v in pairs(args) do data[k] = v end

    return shItem(data)

end
