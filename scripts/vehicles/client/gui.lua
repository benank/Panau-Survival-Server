class 'vehGui'
function vehGui:__init()
	--THIS CLASS HANDLES ALL THE GUI FOR VEHICLES
	myvehs = {}
	buttons = {}
	window = Window.Create()
	window:SetSize(Render.Size / 1.5)
	window:SetTitle("Vehicle Management Menu ("..table.count(myvehs).."/10)")
	window:SetPosition((Render.Size / 2) - (window:GetSize() / 2))
	twindow = Window.Create()
	twindow:SetSize(Render.Size / 5)
	twindow:SetTitle("Vehicle Transfer Menu")
	twindow:SetPosition((Render.Size / 2) - (twindow:GetSize() / 2))
	tnameLabel = Label.Create(twindow)
	tnameLabel:SetText("Transfer")
	tnameLabel:SetTextSize(30)
	tnameLabel:SetSizeRel(Vector2(1,1))
	local rel1 = GetMiddlePos(tnameLabel, twindow)
	tnameLabel:SetPosition(Vector2(rel1, twindow:GetSize().y / 50))
	tnameLabel2 = Label.Create(twindow)
	tnameLabel2:SetText("VEHICLENAMEHERE")
	tnameLabel2:SetTextSize(20)
	tnameLabel2:SetTextColor(Color(0,255,255))
	tnameLabel2:SetSizeRel(Vector2(1,1))
	local rel2 = GetMiddlePos(tnameLabel2, twindow)
	tnameLabel2:SetPosition(Vector2(rel2, (twindow:GetSize().y / 50) + (tnameLabel:GetTextHeight() * 1.1)))
	tnameLabel3 = Label.Create(twindow)
	tnameLabel3:SetText("to")
	tnameLabel3:SetTextSize(20)
	tnameLabel3:SetSizeRel(Vector2(1,1))
	local rel3 = GetMiddlePos(tnameLabel3, twindow)
	tnameLabel3:SetPosition(Vector2(rel3, (tnameLabel2:GetPosition().y) + (tnameLabel2:GetTextHeight() * 1.1)))
	textbox = TextBoxNumeric.Create(twindow)
	textbox:SetSize(Vector2(twindow:GetSize().x / 2,twindow:GetSize().y / 5))
	textbox:SetTextSize(30)
	textbox:SetAlignment(96)
	local rel4 = (twindow:GetSize().x / 2) - (textbox:GetSize().x / 2)
	textbox:SetPosition(Vector2(rel4, (tnameLabel3:GetPosition().y) + (tnameLabel3:GetTextHeight() * 1.1)))
	tnameLabel5 = Label.Create(twindow)
	tnameLabel5:SetText("Enter a valid player ID, found in the F6 menu")
	tnameLabel5:SetTextSize(12.5)
	tnameLabel5:SetSizeRel(Vector2(1,1))
	local rel5 = GetMiddlePos(tnameLabel5, twindow)
	tnameLabel5:SetPosition(Vector2(rel5, (textbox:GetPosition().y) + (textbox:GetSize().y * 1.1)))
	tbutton = Button.Create(twindow)
	tbutton:SetText("Confirm")
	tbutton:SetName("Confirm")
	tbutton:SetTextSize(25)
	tbutton:SetTextColor(Color(0,255,255))
	tbutton:SetTextNormalColor(Color(0,255,255))
	tbutton:SetTextHoveredColor(Color(0,255,255))
	tbutton:SetTextPressedColor(Color(0,255,255))
	tbutton:SetSize(Vector2(twindow:GetSize().x / 2,twindow:GetSize().y / 7))
	local rel6 = (twindow:GetSize().x / 2) - (tbutton:GetSize().x / 2)
	tbutton:SetPosition(Vector2(rel6, (tnameLabel5:GetPosition().y) + (tnameLabel5:GetTextHeight() * 1.1)))
	tbutton:Subscribe("Press", self, self.ButtonPress)
	mypos = {}
	myhp = {}
	mynames = {}
	window:Hide()
	twindow:Hide()
	window:Subscribe("WindowClosed", self, self.CloseWindow)
	window:Subscribe("Render", self, self.WindowRender)
	Events:Subscribe("KeyUp", self, self.KeyOpen)
	Events:Subscribe("SecondTick", self, self.SetMyVehs)
	Network:Subscribe("V_UpdateVTable", self, self.ReceiveVTable)
end

--MAKE TABLES FOR EACH PLAYER SERVERSIDE WHAT HOLD ALL THE VEHICLES
--THEY OWN SO THAT THE SERVER ONLY HAS TO SEND THE TABLE

--ON SERVER SEND VEHICLE TABLE
function GetMiddlePos(k, w)
	return (w:GetSize().x / 2) - (k:GetTextWidth() / 2)
end
function vehGui:SetMyVehs()
	--put streamed vehicles in a table if you own them
	for v in Client:GetVehicles() do
		for id, name in pairs(mynames) do
			if v:GetId() == id then
				myvehs[id] = v
			end
		end
	end
end
function vehGui:GetVehs()
	--for the other class to get #vehicles
	return mynames
end
function vehGui:ReceiveVTable(args)
	--receive various data from server like v health, pos, name, etc
	if args.t1 then
		myvehs = args.t1
	end
	if args.t2 then
		mypos = args.t2
	end
	if args.t3 then
		myhp = args.t3
	end
	if args.t4 then
		mynames = args.t4
	end
	self:UpdateButtons()
end
function vehGui:UpdateButtonText()
	--on open, update text like distance and hp, etc
	window:SetTitle("Vehicle Management Menu ("..table.count(mynames).."/10)")
	if table.count(buttons) == 0 then return end
	for index, _ in pairs(buttons) do
		local label = buttons[index].label
		local labelhp = buttons[index].labelhp
		local labeldist = buttons[index].labeldist
		local waypoint = buttons[index].waypoint
		local remov = buttons[index].remov
		local transfer = buttons[index].transfer
		label:SetText(mynames[label:GetDataObject("vid")])
		waypoint:SetTextColor(Color.Yellow)
		waypoint:SetTextNormalColor(Color.Yellow)
		waypoint:SetTextHoveredColor(Color.Yellow)
		waypoint:SetTextPressedColor(Color.Yellow)
		transfer:SetTextColor(Color(0,255,255))
		transfer:SetTextNormalColor(Color(0,255,255))
		transfer:SetTextHoveredColor(Color(0,255,255))
		transfer:SetTextPressedColor(Color(0,255,255))
		remov:SetTextColor(Color.Red)
		remov:SetTextNormalColor(Color.Red)
		remov:SetTextHoveredColor(Color.Red)
		remov:SetTextPressedColor(Color.Red)
		local v = labelhp:GetDataObject("v")
		local vid = labelhp:GetDataObject("vid")
		for id, v2 in pairs(myvehs) do
			if id == vid and IsValid(v2) then
				mypos[id] = v2:GetPosition()
				myhp[id] = v2:GetHealth()*100
				if myhp[id] < 0 then
					myhp[id] = 0
				end
			end
		end
		local dist = Vector3.Distance(LocalPlayer:GetPosition(), mypos[vid])
		local diststr = string.format("%.0f m away",tostring(dist))
		local hpnum = myhp[vid]
		if hpnum < 0 then hpnum = 0 end
		local hp = string.format("Health: %.0f%%",hpnum)
		local green = hpnum * 2.55
		local red = (-hpnum + 100) * 5.1
		local color = Color(red, green, 0)
		labelhp:SetText(hp)
		labelhp:SetTextColor(color)
		if dist > 1000 then
			dist = dist / 1000
			diststr = string.format("%.2f km away",tostring(dist))
		end
		labeldist:SetText(diststr)
	end
end
function vehGui:UpdateButtons() --CALLED WHENEVER THE TABLE IS CHANGED
	--reinitializes buttons due to tables 
	for k, v in pairs(buttons) do
		if IsValid(buttons[k].label) then buttons[k].label:Remove() end
		if IsValid(buttons[k].labeldist) then buttons[k].labeldist:Remove() end
		if IsValid(buttons[k].labelhp) then buttons[k].labelhp:Remove() end
		if IsValid(buttons[k].waypoint) then buttons[k].waypoint:Remove() end
		if IsValid(buttons[k].transfer) then buttons[k].transfer:Remove() end
		if IsValid(buttons[k].remov) then buttons[k].remov:Remove() end
	end
	buttons = {}
	local tnum = 0
	window:SetTitle("Vehicle Management Menu ("..table.count(mynames).."/10)")
	for id, v in pairs(mynames) do
		--makes buttons
		tnum = tnum + 1
		buttons[tnum] = {}
		buttons[tnum].label = Label.Create(window)
		buttons[tnum].label:SetDataObject("v", v)
		buttons[tnum].label:SetDataObject("vid", id)
		buttons[tnum].label:SetText(v)
		buttons[tnum].labelhp = Label.Create(window)
		buttons[tnum].labelhp:SetDataObject("v", v)
		buttons[tnum].labelhp:SetDataObject("vid", id)
		buttons[tnum].labeldist = Label.Create(window)
		buttons[tnum].labeldist:SetDataObject("v", v)
		buttons[tnum].labeldist:SetDataObject("vid", id)
		buttons[tnum].waypoint = Button.Create(window)
		buttons[tnum].waypoint:SetDataObject("v", v)
		buttons[tnum].waypoint:SetDataObject("vid", id)
		buttons[tnum].waypoint:SetName("Waypoint")
		buttons[tnum].transfer = Button.Create(window)
		buttons[tnum].transfer:SetDataObject("v", v)
		buttons[tnum].transfer:SetDataObject("vid", id)
		buttons[tnum].transfer:SetName("Transfer")
		buttons[tnum].remov = Button.Create(window)
		buttons[tnum].remov:SetDataObject("v", v)
		buttons[tnum].remov:SetDataObject("vid", id)
		buttons[tnum].remov:SetName("Remove")
		buttons[tnum].waypoint:SetText("Waypoint")
		buttons[tnum].waypoint:SetTextColor(Color.Yellow)
		buttons[tnum].transfer:SetText("Transfer")
		buttons[tnum].transfer:SetTextColor(Color(0,255,255))
		buttons[tnum].remov:SetText("Remove")
		buttons[tnum].remov:SetTextColor(Color.Red)
		local dist = Vector3.Distance(LocalPlayer:GetPosition(), mypos[id])
		local diststr = string.format("%.0f m away",tostring(dist))
		if dist > 1000 then
			dist = dist / 1000
			diststr = string.format("%.1f km away",tostring(dist))
		end
		if IsValid(v) then
			local hpnum = myhp[id]
			if hpnum < 0 then hpnum = 0 end
			local hp = string.format("Health: %.0f%%",hpnum)
			local green = hpnum * 2.55
			local red = (-hpnum + 100) * 5.1
			local color = Color(red, green, 0)
			buttons[tnum].labelhp:SetText(hp)
			buttons[tnum].labelhp:SetTextColor(color)
			buttons[tnum].labeldist:SetText(diststr)
		end
	end
	local baserel = Vector2(0.001, 0.01)
	local addrel = Vector2(0, 0.05)
	local addrel2 = Vector2(0.275, 0.0)
	local addrel3 = Vector2(0.45, 0.0)
	local siderel = Vector2(0.125, 0)
	local firstrel = Vector2(0.5, 0)
	local sizerel = Vector2(0.115,0.045)
	for i=1,table.count(buttons) do
		--sets button position, etc
		local label = buttons[i].label
		local labelhp = buttons[i].labelhp
		local labeldist = buttons[i].labeldist
		local waypoint = buttons[i].waypoint
		local transfer = buttons[i].transfer
		local remov = buttons[i].remov
		label:SetPositionRel(baserel + (addrel * (i-1)))
		label:SetSizeRel(Vector2(1,1))
		label:SetTextSize(25)
		labelhp:SetPositionRel(label:GetPositionRel() + (addrel2))
		labelhp:SetSizeRel(Vector2(1,1))
		labelhp:SetTextSize(25)
		labeldist:SetPositionRel(label:GetPositionRel() + (addrel3))
		labeldist:SetSizeRel(Vector2(1,1))
		labeldist:SetTextSize(25)
		waypoint:SetPositionRel(label:GetPositionRel() + siderel + firstrel)
		transfer:SetPositionRel(label:GetPositionRel() + (siderel * 2)+ firstrel)
		remov:SetPositionRel(label:GetPositionRel() + (siderel * 3)+ firstrel)
		waypoint:SetSizeRel(sizerel)
		transfer:SetSizeRel(sizerel)
		remov:SetSizeRel(sizerel)
		waypoint:SetTextSize(20)
		transfer:SetTextSize(20)
		remov:SetTextSize(20)
		waypoint:SetTextColor(Color.Yellow)
		waypoint:SetTextNormalColor(Color.Yellow)
		waypoint:SetTextHoveredColor(Color.Yellow)
		waypoint:SetTextPressedColor(Color.Yellow)
		transfer:SetTextColor(Color(0,255,255))
		transfer:SetTextNormalColor(Color(0,255,255))
		transfer:SetTextHoveredColor(Color(0,255,255))
		transfer:SetTextPressedColor(Color(0,255,255))
		remov:SetTextColor(Color.Red)
		remov:SetTextNormalColor(Color.Red)
		remov:SetTextHoveredColor(Color.Red)
		remov:SetTextPressedColor(Color.Red)
		waypoint:Subscribe("Press", self, self.ButtonPress)
		transfer:Subscribe("Press", self, self.ButtonPress)
		remov:Subscribe("Press", self, self.ButtonPress)
		--ADJUST BUTTON HEIGHT AND POSITION HERE USING I
		--ALSO SUBSCRIBE BUTTONS TO FUNCTIONS
	end
end
function vehGui:UpdateTransferMenu(id)
	local name = mynames[id]
	tnameLabel2:SetText(tostring(name))
	local rel2 = GetMiddlePos(tnameLabel2, twindow)
	tnameLabel2:SetPosition(Vector2(rel2, (twindow:GetSize().y / 50) + (tnameLabel:GetTextHeight() * 1.1)))
	tbutton:SetDataObject("id", id)
end
function vehGui:ButtonPress(btn)
	--event that happens on button press
	if btn:GetName() == "Waypoint" then
		local vid = btn:GetDataObject("vid")
		local pos = mypos[vid]
		Waypoint:SetPosition(pos)
	elseif btn:GetName() == "Transfer" then
		local vid = btn:GetDataObject("vid")
		self:UpdateTransferMenu(vid)
		twindow:Show()
	elseif btn:GetName() == "Remove" then
		local id = btn:GetDataObject("vid")
		Network:Send("V_RemoveMyV", id)
	elseif btn:GetName() == "Confirm" then
		local sent = false
		for player in Client:GetPlayers() do --does not return LocalPlayer
			if player:GetId() == tonumber(textbox:GetText()) then
				local args = {}
				args.id = player:GetId()
				args.v = btn:GetDataObject("id")
				Network:Send("V_ConfirmTransfer", args)
				sent = true
				twindow:Hide()
			end
		end
		if not sent then Chat:Print("Not a valid player ID!", Color.Red) end
		--COMPLETE TRANSACTION OF VEHICLE
	end
end
function vehGui:KeyOpen(args)
	--opens the gui
	if args.key == 118 and not window:GetVisible() then --F7
		if table.count(buttons) > 0 then
			self:UpdateButtonText()
		end
		window:Show()
		Mouse:SetVisible(true)
		movesub = Events:Subscribe("LocalPlayerInput", self, self.BlockLooking)
	elseif args.key == 118 and window:GetVisible() then --F7
		window:Hide()
		twindow:Hide()
		if movesub then
			Events:Unsubscribe(movesub)
			movesub = nil
		end
		Mouse:SetVisible(false)
	end
end
function vehGui:BlockLooking(args)
	--blocks looking and firing while open
	if args.input == Action.LookLeft or args.input == Action.LookRight or
	args.input == Action.LookDown or args.input == Action.LookUp
	or args.input == Action.Fire or args.input == Action.FireRight
	or args.input == Action.FireLeft or args.input == Action.FireVehicleWeapon 
	or args.input == Action.McFire or args.input == Action. VehicleFireLeft 
	or args.input == Action.VehicleFireRight then return false end
end
function vehGui:CloseWindow()
	window:Hide()
	twindow:Hide()
	if movesub then
		Events:Unsubscribe(movesub)
		movesub = nil
	end
	Mouse:SetVisible(false)
end
function vehGui:WindowRender()
	Mouse:SetVisible(true)
end
vehGui = vehGui()