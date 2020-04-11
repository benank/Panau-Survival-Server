--[[function Collide(args)
	print("args.impulse",args.impulse,"args.vehicle",args.attacker)
end
--Events:Subscribe("VehicleCollide", Collide)
function Ray()
	if LocalPlayer:InVehicle() then
		local v = LocalPlayer:GetVehicle()
		local velocity = -v:GetAngle() * v:GetLinearVelocity()
		local impulse = -velocity.z
		if impulse < 5 then return end
		local b1,b2 = v:GetBoundingBox()
		local lengthx = math.abs(b1.x - b2.x) / 2
		local lengthy = math.abs(b1.y - b2.y) / 2
		local lengthz = math.abs(b1.z - b2.z) / 2
		--print(lengthx,lengthy,lengthz)
		local result1 = Physics:Raycast(v:GetPosition(),v:GetAngle() * Vector3.Forward,0,lengthx) --front
		local result2 = Physics:Raycast(v:GetPosition(),v:GetAngle() * Vector3.Left,0,lengthz) --left
		local result3 = Physics:Raycast(v:GetPosition(),v:GetAngle() * Vector3.Backward,0,lengthx) --back
		local result4 = Physics:Raycast(v:GetPosition(),v:GetAngle() * Vector3.Right,0,lengthz) --right
		local result5 = Physics:Raycast(v:GetPosition(),v:GetAngle() * Vector3.Up,0,lengthy) --up
		Chat:Print(tostring(result2.distance), Color.White)
	end
end
Events:Subscribe("PostTick", Ray)--]]