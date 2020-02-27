class 'Place'
lootmode = false
lastspawn = 0 -- ID of last object spawned
shownearbyloot = true
function Place:__init()

    self.current_object = nil
    self.yaw = 0
    self.yaw_adj = math.pi / 12
    self.lastpos = Vector3()

    Events:Subscribe("MouseScroll", self, self.MouseScroll)
    Events:Subscribe("MouseUp", self, self.MouseUp)
end

function Place:MouseScroll(args)
    self.yaw = self.yaw + math.ceil(args.delta) * self.yaw_adj
end
-----
function Place:ChatHandle(args)
	if args.text == "/lootmode" then
		lootmode = not lootmode
		Chat:Print("lootmode: " .. tostring(lootmode), Color(0, 255, 0))
		return false
	elseif args.text == "/showloot" then
		shownearbyloot = not shownearbyloot
		return false
	elseif args.text:find("/yaw") then
		local splittext = args.text:split(" ")
		local newyaw = tonumber(splittext[2])
		self.yaw_adj = newyaw
		return false
	elseif args.text:find("/alpha") then
		local splittext = args.text:split(" ")
		local newalpha = tonumber(splittext[2])
		if type(newalpha) == "string" then return end
		if newalpha >= 0 and newalpha <= 255 then
			alpha = newalpha
		end
		return false
	elseif args.text:find("/radius ") then
		local splittext = args.text:split(" ")
		local newradius = tonumber(splittext[2])
		if type(newradius) == "string" then return end
		if newradius >= .01 and newradius <= 175 then
			radius = newradius
		end
		return false
	elseif args.text:find("/range ") then
		local splittext = args.text:split(" ")
		local newrange = tonumber(splittext[2])
		if type(newrange) == "string" then return end
		if newrange >= 250 and newrange <= 12500 then
			range = newrange
		end
		return false
	elseif args.text == "/undo" then
		if lastspawnedid then
			Network:Send("DeleteLootbox", {id = lastspawnedid})
			lastspawnedid = nil
		end
	end
end
-----
function Place:KeyHandle(args)
	if Game:GetState() ~= GUIState.Game then return end
	if lootmode ~= true then return end
	if args.key == string.byte("1") then -- tier 1
		self:SpawnBox(Lootbox.Types.Level1)
	elseif args.key == string.byte("2") then -- tier 2
		self:SpawnBox(Lootbox.Types.Level2)
	elseif args.key == string.byte("3") then -- tier 3
		self:SpawnBox(Lootbox.Types.Level3)
    elseif args.key == string.byte("4") then -- tier 4
		self:SpawnBox(Lootbox.Types.Level4)
    elseif args.key == string.byte("5") then -- food vending machine
		self:SpawnBox(Lootbox.Types.VendingMachineFood)
    elseif args.key == string.byte("6") then -- drink vending machine
		self:SpawnBox(Lootbox.Types.VendingMachineDrink)
	end
end

function Place:SpawnBox(tier)
    if IsValid(self.current_object) then
        self.current_object:Remove()
        self.current_object = nil
    end

    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 500)
    local obj_data = Lootbox.Models[tier]
    self.current_offset = obj_data.offset
    self.current_object = ClientStaticObject.Create({
        position = ray.position,
        angle = Angle(),
        model = obj_data.model
    })
    self.current_tier = tier
end

function Place:MouseUp(args)
    if IsValid(self.current_object) then
        Network:Send("SpawnBox", {
            pos = self.lastpos, 
            tier = self.current_tier,
            angle = self.current_object:GetAngle()})
        self.current_object:Remove()
        self.current_object = nil
    end
end

function Place:MoveBox()

    if not IsValid(self.current_object) then return end

    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 500)
    self.lastpos = ray.position + self.current_offset
    self.current_object:SetPosition(self.lastpos)
    local ang = Angle.FromVectors(Vector3.Up, ray.normal) * Angle(self.yaw, 0, 0)
    --ang.yaw = self.yaw
    self.current_object:SetAngle(ang)

end

-----
totalboxes = 0
alpha = 150
radius = 2.5
range = 1500
function Place:RendrBase()
    if lootmode == true then
        
        self:MoveBox()


		Render:DrawText(Vector2(Render.Width * .025, Render.Height * .35), "/lootmode to exit loot-placing mode", Color(0, 255, 0, 175), (TextSize.Default * 1))
		Render:DrawText(Vector2(Render.Width * .025, Render.Height * .40), "/saveloot to save all loot", Color(0, 255, 0, 175), (TextSize.Default * 1))
		Render:DrawText(Vector2(Render.Width * .025, Render.Height * .45), "/alpha 0-255 to set the alpha on /showloot", Color(0, 255, 0, 175), (TextSize.Default * 1))
		Render:DrawText(Vector2(Render.Width * .025, Render.Height * .5), "/radius .01-175 to set the radius on /showloot's circles", Color(0, 255, 0, 175), (TextSize.Default * 1))
		Render:DrawText(Vector2(Render.Width * .025, Render.Height * .6), "/showloot to see nearby loot", Color(0, 255, 0, 175), (TextSize.Default * 1))
		Render:DrawText(Vector2(Render.Width * .025, Render.Height * .55), "/range 250-12500 set the range on /showloot's circles", Color(0, 255, 0, 175), (TextSize.Default * 1))
		Render:DrawText(Vector2(Render.Width * .025, Render.Height * .3), "Total Loot in Server: " .. tostring(totalboxes), Color(0, 255, 0, 175), (TextSize.Default * 1))
		--
		if shownearbyloot == true then
			local plypos = LocalPlayer:GetPosition()
			for object in Client:GetStaticObjects() do
				if plypos:Distance(object:GetPosition()) <= range then
					model = object:GetModel()
                    if Lootbox.Colors[model] then
                        color = Lootbox.Colors[model]
                        color.a = alpha
						local pos = object:GetPosition()
						local transform = Transform3()
						transform:Translate(Vector3(pos.x, pos.y, pos.z))
						transform:Rotate(Angle(0, 0.5 * math.pi, 0))
						Render:SetTransform(transform)
						Render:FillCircle(Vector3.Zero, radius, color)
						Render:ResetTransform()
					end
				end
			end
		end
	end
end
-------
function Place:GetLastSpawned(args)
	lastspawnedid = args.id
end
------
function Place:CountedLoot(args)
	totalboxes = args.num - 1
end


place = Place()

Events:Subscribe("LocalPlayerChat", place, place.ChatHandle)
Events:Subscribe("KeyUp", place, place.KeyHandle)
Events:Subscribe("Render", place, place.RendrBase)
Network:Subscribe("GetLast", place, place.GetLastSpawned)
Network:Subscribe("LootCounted", place, place.CountedLoot)