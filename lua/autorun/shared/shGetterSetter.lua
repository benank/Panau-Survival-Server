-- an addition to the object-oriented structure that adds a getter and setter to a class
-- adds instance:GetVariableName and instance:SetVariableName to a class instance
function getter_setter(instance, get_set_name)
    local function firstCharacterToUpper(str)
        return (str:gsub("^%l", string.upper))
    end

    local name = ""
    local words = get_set_name:split("_")
    for k, word in ipairs(words) do
        name = name .. firstCharacterToUpper(word)
    end

    local get_name = "Get" .. name
    local set_name = "Set" .. name

    instance[get_name] = function()
        return instance[get_set_name]
    end

    instance[set_name] = function(instance, value)
        instance[get_set_name] = value
    end
end 