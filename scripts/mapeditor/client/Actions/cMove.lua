class("Move" , Actions)

function Actions.Move:__init()
	Actions.TransformBase.__init(self)
	
	self.sensitivity = 0.001
	
	self.controlDisplayer.name = "Move"
	self.controlDisplayer:AddControl("Snap to surface")
	
	self.gizmoModel = MapEditor.models["Move gizmo"]
end

function Actions.Move:OnProcess(objectInfo , mouse , pivot)
	local delta
	-- Holding shift moves the object to the mouse cursor using a raycast.
	if Controls.Get("Snap to surface").state ~= 0 and self.lockedAxis == nil then
		local result = Physics:Raycast(
			Camera:GetPosition() ,
			Render:ScreenToWorldDirection(Mouse:GetPosition()) ,
			0 ,
			2000
		)
		delta = result.position - objectInfo.startTransform.position
	else
		local distance = Vector3.Distance(Camera:GetPosition() , pivot)
		local mult = distance * self.sensitivity
		delta = Camera:GetAngle() * Vector3(mouse.delta.x , -mouse.delta.y , 0) * mult
		
		if self.lockedAxis then
			if self.lockedAxis == "X" then
				delta.y = 0
				delta.z = 0
			elseif self.lockedAxis == "Y" then
				delta.x = 0
				delta.z = 0
			elseif self.lockedAxis == "Z" then
				delta.x = 0
				delta.y = 0
			end
			
			if self.isLocal then
				delta = objectInfo.startTransform.angle * delta
			end
			
			if self.gizmoModel then
				local angle
				if self.lockedAxis == "X" then
					angle = Angle(0 , 0 , 0)
				elseif self.lockedAxis == "Y" then
					angle = Angle(0 , 0 , math.tau / 4)
				elseif self.lockedAxis == "Z" then
					angle = Angle(math.tau / 4 , 0 , 0)
				end
				
				if self.isLocal then
					angle = objectInfo.startTransform.angle * angle
				end
				
				local transform = Transform3()
				transform:Translate(pivot)
				transform:Rotate(angle)
				Render:SetTransform(transform)
				
				self.gizmoModel:Draw()
				
				Render:ResetTransform()
			end
		end
	end
	
	local endPosition = objectInfo.startTransform.position + delta
	
	local snap = MapEditor.Preferences.snapPosition
	if snap ~= 0 then
		endPosition.x = math.floor(endPosition.x / snap + 0.5) * snap
		endPosition.y = math.floor(endPosition.y / snap + 0.5) * snap
		endPosition.z = math.floor(endPosition.z / snap + 0.5) * snap
	end
	
	objectInfo.endTransform.position = endPosition
end
