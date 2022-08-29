class "ActorProfileEnum"

function ActorProfileEnum:__init()
    self.Patroller = 1
    self.CityLooter = 2

    
    self.descriptions = {
        [self.Patroller] = "Patroller",
        [self.CityLooter] = "CityLooter"
    }

    -- https://wiki.jc-mp.com/Character_Models
    self.model_ids = {
        [self.Patroller] = 66,
        [self.CityLooter] = {
            94, 92, 76, 72, 69, 68, 56, 50
        }
    }
end

function ActorProfileEnum:GetDescription(actor_profile_enum)
    assert(self.descriptions[actor_profile_enum] ~= nil)
    return self.descriptions[actor_profile_enum]
end

function ActorProfileEnum:GetClass(actor_profile_enum)
    local actor_profiles = {
        [self.Patroller] = Patroller,
        [self.CityLooter] = CityLooter
    }
    assert(actor_profiles[actor_profile_enum] ~= nil, "Actor profile enum does not have a mapped class")
    return actor_profiles[actor_profile_enum]
end

function ActorProfileEnum:GetModelId(actor_profile_enum)
    assert(self.model_ids[actor_profile_enum] ~= nil, "Actor profile enum " .. tostring(actor_profile_enum) .. " is not mapped to a model id")
    local model_data = self.model_ids[actor_profile_enum]
    if type(model_data) == "table" then
        return random_table_value(model_data)
    else
        return model_data
    end
end

ActorProfileEnum = ActorProfileEnum()