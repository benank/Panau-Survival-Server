class("StaticObject" , Objects)

function Objects.StaticObject:__init(...) ; MapEditor.Object.__init(self , ...)
	self.isClientSide = true
	
	self:AddProperty{
		name = "model" ,
		type = "model" ,
		default = "" ,
	}
	self:AddProperty{
		name = "visibleRange" ,
		type = "number" ,
		default = "500" ,
		description = "This is the range that the model appears at. Set this to a reduced value "..
			"for unimportant objects to reduce framerate slowdown." ,
	}
	self:AddProperty{
		name = "collisionEnabled" ,
		type = "boolean" ,
		default = true ,
	}
	
	self.selectionStrategy = {type = "Icon" , icon = Icons.StaticObject}
	
	self.staticObject = nil
	self.isUpdatingBounds = false
	
	self:OnRecreate()
end

function Objects.StaticObject:UpdateBounds()
	if IsValid(self.staticObject) == false then
		return
	end
	
	local b1 , b2 = self.staticObject:GetBoundingBox()
	-- The bounds are sometimes zero if the object just spawned, probably only when it's loaded for
	-- the first time.
	local hasBounds = not(b1 == Vector3.Zero and b2 == Vector3.Zero)
	if hasBounds and b1:IsNaN() == false and b2:IsNaN() == false then
		b1 = b1 - self:GetPosition()
		b2 = b2 - self:GetPosition()
		self.selectionStrategy = {type = "Bounds" , bounds = {b1 , b2}}
		-- Apply our angle.
		self.staticObject:SetAngle(self:GetAngle())
		
		self.isUpdatingBounds = false
	end
end

function Objects.StaticObject:OnRecreate()
	-- The angle is default until we get the object's neutral bounding box.
	self.staticObject = ClientStaticObject.Create{
		position = self:GetPosition() ,
		angle = Angle() ,
		model = self:GetProperty("model").value ,
	}
	
	self.selectionStrategy = {type = "Icon" , icon = Icons.StaticObject}
	
	self.isUpdatingBounds = true
end

function Objects.StaticObject:OnDestroy()
	self.staticObject:Remove()
end

function Objects.StaticObject:OnRender()
	if self.isUpdatingBounds then
		self:UpdateBounds()
	end
end

function Objects.StaticObject:OnTransformChange(position , angle)
	self.staticObject:SetPosition(position)
	
	if self.isUpdatingBounds == false then
		self.staticObject:SetAngle(angle)
	end
end

function Objects.StaticObject:OnPropertyChange(args)
	if args.name == "model" then
		self.staticObject:Remove()
		self:OnRecreate()
	end
end
