-- TODO: Shouldn't this call Cancel?

class("Load" , Actions)

function Actions.Load:__init() ; Actions.SaveLoadBase.__init(self)
	self.mapName = nil
	
	self.window:SetTitle("Load map")
	self.processButton:SetText("Load")
	
	self:NetworkSubscribe("ReceiveMap")
end

function Actions.Load:OnProcess(mapName)
	self.mapName = mapName
	
	local args = {
		name = self.mapName
	}
	Network:Send("RequestMap" , args)
end

-- Network events

function Actions.Load:ReceiveMap(marshalledSource)
	if marshalledSource == nil then
		Chat:Print("Cannot load map" , Color.DarkRed)
		return
	end
	
	if MapEditor.map then
		MapEditor.map:Destroy()
	end
	
	MapEditor.Map.Load(marshalledSource)
	if MapEditor.map ~= nil then
		MapEditor.map.name = self.mapName
	end
	
	self:Destroy()
end
