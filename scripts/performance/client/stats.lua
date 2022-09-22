class 'stats'

function stats:__init()
    Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
end

function stats:LocalPlayerChat(args)
    if args.text == '/performance' then
        if not self.render then
            self.render = Events:Subscribe("PostRender", self, self.RenderText)
        else
            self.render = Events:Unsubscribe(self.render)
        end
    end
end

function stats:RenderText(args)
    
    local mem = LocalPlayer:GetValue("MeasureMemory")
    if mem then
        local mem_indexed = {}
        for a,b in pairs(mem) do
            table.insert(mem_indexed, {name = a, memory = b}) 
        end
        table.sort(mem_indexed, function(a, b)
            return tonumber(a.memory) > tonumber(b.memory)
        end)
        local pos = Vector2(50, 300)
        for _, d in ipairs(mem_indexed) do
            local color = Color.White
            local mem_num_mb = tonumber(d.memory) / 1024
            if mem_num_mb > 30 then
                color = Color.Red
            elseif mem_num_mb > 10 then
                color = Color.Orange
            elseif mem_num_mb > 3 then
                color = Color.Yellow
            end
            
            Render:DrawText(pos, d.name, color, 14)
            Render:DrawText(pos + Vector2(150, 0), string.format("%.2f mb", mem_num_mb), color, 14)
            pos = pos + Vector2(0, 20)
        end
    end

end

Safezone = stats()