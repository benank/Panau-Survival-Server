class("Light" , Objects)

function Objects.Light:__init(...) ; MapEditor.Object.__init(self , ...)
	self.isClientSide = true
	
	self:AddProperty{
		name = "radius" ,
		type = "number" ,
		default = 12 ,
		description = "If you set the radius too high, it can slow down the framerate. 80m is a "..
			"very large radius." ,
	}
	self:AddProperty{
		name = "multiplier" ,
		type = "number" ,
		default = 2 ,
		description = "How bright the light is, between 0 and 10." ,
	}
	self:AddProperty{
		name = "color" ,
		type = "Color" ,
		default = Color(255 , 255 , 255) ,
		description = "Most lights in real life have either a yellow or cyan tint." ,
	}
	self:AddProperty{
		name = "attenuationConstant" ,
		type = "number" ,
		default = 0 ,
		description = "Does not seem to have an effect." ,
	}
	self:AddProperty{
		name = "attenuationLinear" ,
		type = "number" ,
		default = 0 ,
		description = "Does not seem to have an effect." ,
	}
	self:AddProperty{
		name = "attenuationQuadratic" ,
		type = "number" ,
		default = 1 ,
		description = "Does not seem to have an effect." ,
	}
	
	self.selectionStrategy = {type = "Icon" , icon = Icons.Light}
	
	self:OnRecreate()
end

function Objects.Light:OnRecreate()
	self.light = ClientLight.Create{
		position = self:GetPosition() ,
		color = self:GetProperty("color").value ,
		multiplier = self:GetProperty("multiplier").value ,
		radius = self:GetProperty("radius").value ,
		constant_attenuation = self:GetProperty("attenuationConstant").value ,
		linear_attenuation = self:GetProperty("attenuationLinear").value ,
		quadratic_attenuation = self:GetProperty("attenuationQuadratic").value ,
	}
end

function Objects.Light:OnDestroy()
	self.light:Remove()
end

function Objects.Light:OnTransformChange(position , angle)
	self.light:SetPosition(position)
end

function Objects.Light:OnPropertyChange(args)
	-- Luabuse is fun
	self.light[({
		color = "SetColor" ,
		multiplier = "SetMultiplier" ,
		radius = "SetRadius" ,
		attenuationConstant = "SetConstantAttenuation" ,
		attenuationLinear = "SetLinearAttenuation" ,
		attenuationQuadratic = "SetQuadraticAttenuation" ,
	})[args.name]](self.light , args.newValue)
end
