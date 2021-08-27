class 'cLockonModule'

function cLockonModule:__init()
    
    Network:Subscribe("items/ToggleEquippedLockonModule", self, self.ToggleEquipped)
end

function cLockonModule:ToggleEquipped(args)
    self.equipped = args.equipped
    
    LocalPlayer:SetValue("LockonModuleEquipped", self.equipped)
end

cLockonModule = cLockonModule()