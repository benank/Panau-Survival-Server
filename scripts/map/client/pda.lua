class "PDA"

PDA.ToggleDelay = 0.25

function PDA:__init()
	self.active            = false
	self.mouseDown         = false
	self.dragging          = false
	self.lastMousePosition = Mouse:GetPosition()
	self.timer             = Timer()

	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
end

function PDA:IsUsingGamepad()
	return Game:GetSetting(GameSetting.GamepadInUse) ~= 0
end

function PDA:Toggle()
	self.active = not self.active
	LocalPlayer:SetValue("MapOpen", self.active)
end

function PDA:ModuleLoad()
	Events:Subscribe("MouseDown", self, self.MouseDown)
	Events:Subscribe("MouseMove", self, self.MouseMove)
	Events:Subscribe("MouseUp", self, self.MouseUp)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
	Events:Subscribe("Render", self, self.Render)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function PDA:MouseDown(args)
	if self.active then
		self.mouseDown = args.button
	end

	self.lastMousePosition = Mouse:GetPosition()
end

function PDA:MouseMove(args)
	if self.active and self.mouseDown then
		Map.Offset = Map.Offset + ((args.position - self.lastMousePosition) / Map.Zoom)
		self.dragging = true
	end

	self.lastMousePosition = args.position
end

function PDA:MouseUp(args)
	if self.mouseDown == args.button then
		if not self.dragging then
			if args.button == 3 then
				Map:ToggleWaypoint(Map.ActiveLocation and Map.ActiveLocation.position or Map:ScreenToWorld(Mouse:GetPosition()))
			end
		end

		self.mouseDown = false
		self.dragging = false
	end

	self.lastMousePosition = Mouse:GetPosition()
end

function PDA:LocalPlayerInput(args)
	if args.input == Action.GuiPDA then
		if self.timer:GetSeconds() > PDA.ToggleDelay then
			PDA:Toggle()
			self.timer:Restart()

			if self.active then
				Map.Zoom = 1.5

				Map.Image:SetSize(Vector2.One * Render.Height * Map.Zoom)

				Map.Offset = Vector2(LocalPlayer:GetPosition().x, LocalPlayer:GetPosition().z) / 16384
				Map.Offset = -Vector2(Map.Offset.x * (Map.Image:GetSize().x / 2), Map.Offset.y * (Map.Image:GetSize().y / 2)) / Map.Zoom
			end
		end

		return false
	elseif self.active then
		if (args.input == Action.GuiPDAZoomIn or args.input == Action.GuiPDAZoomOut) and args.state > 0.15 then
			local oldZoom = Map.Zoom

			Map.Zoom = math.max(math.min(Map.Zoom + (0.1 * args.state * (PDA:IsUsingGamepad() and -1 or 1) * (args.input == Action.GuiPDAZoomIn and 1 or -1)), 3), 1)

			local zoomFactor  = Map.Zoom - oldZoom
			local zoomProduct = oldZoom * oldZoom + oldZoom * zoomFactor
			local zoomTarget  = ((PDA:IsUsingGamepad() and (Render.Size / 2) or Mouse:GetPosition()) - (Render.Size / 2))

			Map.Offset = Map.Offset - ((zoomTarget * zoomFactor) / zoomProduct)
		elseif args.input == Action.GuiAnalogDown and args.state > 0.15 then
			Map.Offset = Map.Offset - (Vector2.Down * 5 * math.pow(args.state, 2) / Map.Zoom)
		elseif args.input == Action.GuiAnalogUp and args.state > 0.15 then
			Map.Offset = Map.Offset - (Vector2.Up * 5 * math.pow(args.state, 2) / Map.Zoom)
		elseif args.input == Action.GuiAnalogLeft and args.state > 0.15 then
			Map.Offset = Map.Offset - (Vector2.Left * 5 * math.pow(args.state, 2) / Map.Zoom)
		elseif args.input == Action.GuiAnalogRight and args.state > 0.15 then
			Map.Offset = Map.Offset - (Vector2.Right * 5 * math.pow(args.state, 2) / Map.Zoom)
        elseif args.input == Action.FireLeft and self.timer:GetSeconds() > PDA.ToggleDelay then
			Map:ToggleWaypoint(Map.ActiveLocation and Map.ActiveLocation.position or Map:ScreenToWorld(Mouse:GetPosition()))
			self.timer:Restart()
		else
			return false
		end
	end
end

function PDA:Render()

	if Game:GetState() ~= GUIState.Game then
		if self.active then
			PDA:Toggle()
		end

		return
	end

	Map:DrawMinimap()

	Mouse:SetVisible(not PDA:IsUsingGamepad() and self.active)

	if self.active then
		Map:Draw()
	end
end

function PDA:ModuleUnload()
	if self.active then
		PDA:Toggle()
	end
end

PDA = PDA()
