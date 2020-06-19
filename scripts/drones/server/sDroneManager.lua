class 'sDroneManager'

function sDroneManager:__init()


    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring(Cell_Size), self, self.PlayerCellUpdate)

end

function sDroneManager:PlayerCellUpdate(args)

    -- Update player cell and sync them new drones in new cells :)

end

sDroneManager = sDroneManager()