class 'Place'
lootmode = false
lastspawn = 0 -- ID of last object spawned
shownearbyloot = true
function Place:__init()

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
		local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 50)
		local position = ray.position
		Network:Send("SpawnTier1", {pos = position})
	elseif args.key == string.byte("2") then -- tier 2
		local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 50)
		local position = ray.position
		position.y = position.y + .1
		Network:Send("SpawnTier2", {pos = position})
	elseif args.key == string.byte("3") then -- tier 3
		local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 50)
		local position = ray.position
		position.y = position.y + .004
		Network:Send("SpawnTier3", {pos = position})
    elseif args.key == string.byte("4") then -- credits crate
		local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 50)
		local position = ray.position
		Network:Send("SpawnTier4", {pos = position})
	end
end
-----
totalboxes = 0
alpha = 200
radius = 2.5
range = 1500
function Place:RendrBase()
	if lootmode == true then
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
                    if model == "f1m03airstrippile07.eez/go164_01-a.lod" 
                    or model == "mod.heavydrop.beretta.eez/wea00-b.lod" 
                    or model == "km05_01.seq.blz/go164_01-g.lod" 
                    or model == "mod.heavydrop.assault.eez/wea00-a.lod" then --or model == "pickup.boost.cash.eez/pu05-a.lod" then
						if model == "f1m03airstrippile07.eez/go164_01-a.lod" then -- tier 1
							color = Color(0, 255, 0, alpha)
						elseif model == "mod.heavydrop.beretta.eez/wea00-b.lod" then -- tier2
							color = Color(0, 0, 255, alpha)
						elseif model == "km05_01.seq.blz/go164_01-g.lod" then -- tier3
							color = Color(255, 0, 0, alpha)
						elseif model == "mod.heavydrop.assault.eez/wea00-a.lod" then -- tier4
							color = Color(255, 255, 0, alpha)
						end
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