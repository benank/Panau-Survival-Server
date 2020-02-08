function ModelViewer:__init()	; EventBase.__init(self)
								; NetworkBase.__init(self)
	
	self.window = Window.Create()
	self.window:SetSizeRel( Vector2( 0.3, 1 ) )
	self.window:SetPosition( 
		Vector2( Render.Width - self.window:GetWidth(), 0 ) )
	self.window:SetTitle( "Model Viewer" )
	self.window:SetVisible( false )

	self.tree = Tree.Create( self.window )
	self.tree:SetDock( GwenPosition.Fill )

	self.physics_text = Label.Create( self.window )
	self.physics_text:SetDock( GwenPosition.Bottom )
	self.physics_text:SetText( "Collision: Nothing selected" )
	self.physics_text:SetHeight(16)
	self.physics_text:SetAlignment( GwenPosition.Bottom )

	self.model_text = Label.Create( self.window )
	self.model_text:SetDock( GwenPosition.Bottom )
	self.model_text:SetText( "Model: Nothing selected" )
	self.model_text:SetHeight(16)
	self.model_text:SetAlignment( GwenPosition.Bottom )

	self.slider_base = BaseWindow.Create( self.window )
	self.slider_base:SetDock( GwenPosition.Bottom )
	self.slider_base:SetHeight(16)

	self.time_text = Label.Create( self.slider_base )
	self.time_text:SetDock( GwenPosition.Left )
	self.time_text:SetAlignment( GwenPosition.Bottom )
	local time = Game:GetTime()
	self.time_text:SetText( 
		("Time: %i:%.02i"):format( time, (time - math.floor(time)) * 60 ) )
	self.time_text:SizeToContents()

	self.slider = HorizontalSlider.Create( self.slider_base )
	self.slider:SetDock( GwenPosition.Fill )
	self.slider:SetRange( 0, 24 )
	self.slider:SetValue( time )
	self.slider:SetNotchCount( 48 )
	self.slider:SetClampToNotches( true )
	self.slider:Subscribe( "ValueChanged", self, self.TimeSliderChanged )

	self.locked_text = Label.Create( self.window )
	self.locked_text:SetDock( GwenPosition.Bottom )
	self.locked_text:SetText( "Locked: false" )
	self.locked_text:SetHeight(16)
	self.locked_text:SetAlignment( GwenPosition.Bottom )

	self.position = Vector3.Zero
	self.locked = false

	self:NetworkSubscribe( "ObjectChange" )
	self:NetworkSubscribe( "PlayerJoinView" )
	self:NetworkSubscribe( "PlayerQuitView" )
	self:NetworkSubscribe( "TimeChange" )

	self:EventSubscribe( "LocalPlayerInput" )

	self.input_timer = Timer()

	-- Generate a sorted list of names
	local names = {}

	for archive_name, _ in pairs( models ) do
		table.insert( names, archive_name )
	end

	table.sort( names )

	-- Iterate through the list and create tree nodes
	for _, name in ipairs( names ) do
		node = self.tree:AddNode( name )

		for i, model in ipairs( models[name] ) do
			child_node = node:AddNode( model[1] )
			child_node:SetDataNumber( "Index", i )
			child_node:Subscribe( "Select", self, self.ModelSelected )
		end
	end

	-- Disable locking by default
	self:SetLock( false )
end

function ModelViewer:SetActive( active )
	self.window:SetVisible( active )

	if active then
		self.orbit_camera = OrbitCamera()
		self.orbit_camera.targetPosition = self.position
	else
		self.orbit_camera:Destroy()
		self.orbit_camera = nil
	end
end

function ModelViewer:GetLock()
	return self.locked
end

function ModelViewer:SetLock( lock )
	self.locked = lock

	Mouse:SetVisible( lock )

	if self.orbit_camera then
		self.orbit_camera.locked = self.locked
	end

	self.locked_text:SetText( "Locked: " .. tostring( self:GetLock() ) )
	self.window:SetEnabled( self:GetLock() )
	self.tree:SetEnabled( self:GetLock() )
end

-- Events
function ModelViewer:LocalPlayerInput( e )
	if not self.window:GetVisible() then return true end

	if e.input == Action.Reload then
		if self.input_timer:GetSeconds() > 0.25 then
			self:SetLock( not self:GetLock() )

			self.input_timer:Restart()
			return false
		end
	end

	if self:GetLock() then return false end

	return true
end

-- Network Events
function ModelViewer:ObjectChange( e )
	self.model_text:SetText( "Model: " .. e[1] )
	self.physics_text:SetText( "Collision: " .. e[2] )
end

function ModelViewer:PlayerJoinView( e )
	self.position = e[3]
	self:ObjectChange( e )
	self:SetActive( true )

	local time = Game:GetTime()

	self.time_text:SetText( 
		("Time: %i:%.02i"):format( time, (time - math.floor(time)) * 60 ) )

	self.slider:SetValue( time )
end

function ModelViewer:PlayerQuitView( e )
	self:SetActive( false )
end

function ModelViewer:TimeChange( e )
	local time = e[1]
	local sender = e[2]

	self.time_text:SetText( 
		("Time: %i:%.02i"):format( time, (time - math.floor(time)) * 60 ) )

	if LocalPlayer ~= sender then
		self.slider:SetValue( time )
	end
end

-- GWEN Events
function ModelViewer:TimeSliderChanged( slider )
	Network:Send( "TimeChange", slider:GetValue() )
end

function ModelViewer:ModelSelected( window )
	local lod = window:GetText()
	local archive = window:GetParent():GetText()
	local index = window:GetDataNumber( "Index" )
	local physics = models[archive][index][2]

	archive = FileName.basename( archive, "/" )

	Network:Send( "RequestObjectChange", { archive, lod, physics } )
end