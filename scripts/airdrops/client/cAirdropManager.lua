class 'cAirdropManager'

function cAirdropManager:__init()

    if IsTest then
        self.locations = {}
        Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
    end

end

function cAirdropManager:LocalPlayerChat(args)
    if args.text == "/loc" then
        table.insert(self.locations, LocalPlayer:GetPosition())
        Chat:Print("Saved location", Color.LawnGreen)
    elseif args.text == "/printloc" then
        print("---------------------")
        for _, pos in pairs(self.locations) do
            print(string.format("{x = %.3f, y = %.3f, z = %.3f},", pos.x, pos.y, pos.z))
        end
        print("---------------------")
        Chat:Print("Printed all locations", Color.LawnGreen)
    end
end

cAirdropManager = cAirdropManager()