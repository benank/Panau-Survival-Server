class 'sItemExplodeManager'

function sItemExplodeManager:__init()

    self.exploding_items = {}

    
    Timer.SetInterval(150, function()
        self:ProcessPendingItems()
    end)

end

function sItemExplodeManager:Add(func)
    table.insert(self.exploding_items, func)
end

function sItemExplodeManager:ProcessPendingItems()
    if count_table(self.exploding_items) == 0 then return end

    table.remove(self.exploding_items, 1)()
end

sItemExplodeManager = sItemExplodeManager()