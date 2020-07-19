class("Delete" , Actions)

function Actions.Delete:__init() ; MapEditor.Action.__init(self)
	-- Cancel if there aren't any selected objects.
	if MapEditor.map.selectedObjects:IsEmpty() then
		self:Cancel()
		return
	end
	-- Create the ObjectDeletionHelper using all selected objects.
	local objects = {}
	MapEditor.map.selectedObjects:IterateObjects(function(object)
		table.insert(objects , object)
	end)
	self.objectDeletionHelper = MapEditor.ObjectDeletionHelper(objects)
	
	self:Redo()
	self:Confirm()
end

function Actions.Delete:Undo()
	self.objectDeletionHelper:Undo()
	
	MapEditor.map:UpdatePropertiesMenu()
end

function Actions.Delete:Redo()
	self.objectDeletionHelper:Apply()
	
	MapEditor.map:UpdatePropertiesMenu()
end
