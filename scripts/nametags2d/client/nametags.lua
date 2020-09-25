-- Nametags v2.0, written by Philpax
class 'Nametags'

function Nametags:__init()
    -- Most of the settings you'll want to tweak are in here
    self.enabled            = true
    self.player_enabled     = true
    self.vehicle_enabled    = false
    self.minimap_enabled    = true

    self.player_limit       = 500
    self.vehicle_limit      = 500
    self:UpdateLimits()

    self.zero_health        = Color( 255,  78, 69 ) -- Zero health colour
    self.full_health        = Color( 55,  204, 73 ) -- Full health colour

    self.FriendColor        = Color( 0, 200, 0 )

    self.size               = TextSize.Default -- Font size
    self.recent_drones      = {}

    self:CreateSettings()

    -- Subscribe to events
    Events:Subscribe( "Render", self, self.Render )
    --Events:Subscribe( "LocalPlayerChat", self, self.LocalPlayerChat )
    Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )
    Events:Subscribe( "ModuleLoad", self, self.ModulesLoad )
    Events:Subscribe( "ModulesLoad", self, self.ModulesLoad )
    Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )
end

function Nametags:UpdateLimits()
    self.player_bias        = self.player_limit / 10
    self.player_max         = self.player_limit * 1.5    
    self.vehicle_bias       = self.vehicle_limit / 10
    self.vehicle_max        = self.vehicle_limit * 1.5
end

function Nametags:CreateSettings()
    self.window_open = false

    self.window = Window.Create()
    self.window:SetSize( Vector2( 160, 246 ) )
    self.window:SetPosition( (Render.Size - self.window:GetSize())/2 )

    self.window:SetTitle( "Nametags Settings" )
    self.window:SetVisible( self.window_open )
    self.window:Subscribe( "WindowClosed", self, self.WindowClosed )

    local enabled_checkbox = LabeledCheckBox.Create( self.window )
    enabled_checkbox:SetSize( Vector2( 320, 20 ) )
    enabled_checkbox:SetDock( GwenPosition.Top )
    enabled_checkbox:GetLabel():SetText( "Enabled" )
    enabled_checkbox:GetCheckBox():SetChecked( self.enabled )
    enabled_checkbox:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.enabled = enabled_checkbox:GetCheckBox():GetChecked() end )

    local player_checkbox = LabeledCheckBox.Create( self.window )
    player_checkbox:SetSize( Vector2( 320, 20 ) )
    player_checkbox:SetDock( GwenPosition.Top )
    player_checkbox:GetLabel():SetText( "Player Nametags" )
    player_checkbox:GetCheckBox():SetChecked( self.player_enabled )
    player_checkbox:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.player_enabled = player_checkbox:GetCheckBox():GetChecked() end )

    local vehicle_checkbox = LabeledCheckBox.Create( self.window )
    vehicle_checkbox:SetSize( Vector2( 320, 20 ) )
    vehicle_checkbox:SetDock( GwenPosition.Top )
    vehicle_checkbox:GetLabel():SetText( "Vehicle Nametags" )
    vehicle_checkbox:GetCheckBox():SetChecked( self.vehicle_enabled )
    vehicle_checkbox:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.vehicle_enabled = vehicle_checkbox:GetCheckBox():GetChecked() end )

    local minimap_checkbox = LabeledCheckBox.Create( self.window )
    minimap_checkbox:SetSize( Vector2( 320, 20 ) )
    minimap_checkbox:SetDock( GwenPosition.Top )
    minimap_checkbox:GetLabel():SetText( "Minimap Icons" )
    minimap_checkbox:GetCheckBox():SetChecked( self.minimap_enabled )
    minimap_checkbox:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.minimap_enabled = minimap_checkbox:GetCheckBox():GetChecked() end )

    local player_text = Label.Create( self.window )
    player_text:SetSize( Vector2( 160, 32 ) )
    player_text:SetDock( GwenPosition.Top )
    player_text:SetText( "Player Distance (m)" )
    player_text:SetAlignment( GwenPosition.CenterV )

    local player_numeric = Numeric.Create( self.window )
    player_numeric:SetSize( Vector2( 160, 32 ) )
    player_numeric:SetDock( GwenPosition.Top )
    player_numeric:SetRange( 0, 500 )
    player_numeric:SetValue( self.player_limit )
    player_numeric:Subscribe( "Changed", 
        function() 
            self.player_limit = player_numeric:GetValue() 
            self:UpdateLimits()
        end )

    local vehicle_text = Label.Create( self.window )
    vehicle_text:SetSize( Vector2( 160, 32 ) )
    vehicle_text:SetDock( GwenPosition.Top )
    vehicle_text:SetText( "Vehicle Distance (m)" )
    vehicle_text:SetAlignment( GwenPosition.CenterV )

    local vehicle_numeric = Numeric.Create( self.window )
    vehicle_numeric:SetSize( Vector2( 160, 32 ) )
    vehicle_numeric:SetDock( GwenPosition.Top )
    vehicle_numeric:SetRange( 0, 500 )
    vehicle_numeric:SetValue( self.vehicle_limit )
    vehicle_numeric:Subscribe( "Changed", 
        function() 
            self.vehicle_limit = vehicle_numeric:GetValue() 
            self:UpdateLimits()
        end )
end

function Nametags:GetWindowOpen()
    return self.window_open
end

function Nametags:SetWindowOpen( state )
    self.window_open = state
    self.window:SetVisible( self.window_open )
    Mouse:SetVisible( self.window_open )
end

-- Determines whether the following position is being aimed at
function Nametags:AimingAt( pos )
    local cam_pos   = Camera:GetPosition()
    local cam_dir   = Camera:GetAngle() * Vector3( 0, 0, -1 )

    local pos_dir   = (pos - cam_pos):Normalized()
    local diff      = (pos_dir - cam_dir):LengthSqr()

    return diff
end

-- Wrapper function that draws things with the right alpha and scale
function Nametags:DrawText( pos, text, colour, scale, alpha )
    local col = colour
    col.a = alpha

    Render:DrawText( pos, text, col, self.size, scale )
end

-- Similar to Nametags:DrawText, but a shadowed variant
function Nametags:DrawShadowedText( pos, text, colour, scale, alpha )
    local col = colour
    col.a = alpha

    Render:DrawText( pos + Vector2( 1, 1 ), text, 
        Color( 20, 20, 20, alpha * 0.6 ), self.size, scale )
    Render:DrawText( pos + Vector2( 2, 2 ), text, 
        Color( 20, 20, 20, alpha * 0.3 ), self.size, scale )

    Render:DrawText( pos, text, col, self.size, scale )
end

-- Calculates the alpha for a given distance, bias, maximum and limit
function Nametags:CalculateAlpha( dist, bias, max, limit )
    if dist > limit then return nil end

    local alpha = 1

    if dist > bias then
        alpha =  1.0 - ( dist - bias ) /
                       ( max  - bias )
    end

    return alpha
end

-- Used to draw the health bar
function Nametags:DrawHealthbar( pos_2d, scale, width, height, health, min, max, alpha )
    -- Calculate an intermediate colour based on health
    local col = math.lerp( min, max, health )
    col.a = alpha    

    -- Draw the background
    Render:FillArea( pos_2d, Vector2( width, height ), Color( 0, 0, 0, alpha ) )
    -- Draw the actual health section
    Render:FillArea( pos_2d, Vector2( width * health, height ), col )
end

function Nametags:DrawNametag( pos_3d, text, colour, scale, alpha, health, draw_healthbar, nametag, level )
    -- Calculate the 2D position on-screen from the 3D position
    local pos_2d, success = Render:WorldToScreen( pos_3d )

    -- If we succeeded, continue to draw
    if success then
        local width = Render:GetTextWidth( text, self.size, scale )
        local height = Render:GetTextHeight( text, self.size, scale )

        local tag_width = Render:GetTextWidth( nametag and nametag.name or "", self.size, scale )
        local tag_height = Render:GetTextHeight( nametag and nametag.name or "", self.size, scale )

        local level_str = string.format("Level %s", tostring(level))
        local level_width = Render:GetTextWidth( level_str, self.size, scale )
        local level_height = Render:GetTextHeight( level_str, self.size, scale )

        -- Subtract half of the text size from both axis' so that the text is
        -- centered

        if nametag then
            -- Draw the nametag
            local nametag_pos_2d = pos_2d - Vector2( tag_width / 2, tag_height / 2 )
            self:DrawShadowedText( nametag_pos_2d - Vector2(0, tag_height), nametag.name, nametag.color, scale, alpha )


            local level_pos_2d = pos_2d - Vector2( level_width / 2, level_height / 2 )
            self:DrawShadowedText( level_pos_2d - Vector2(0, level_height * 2), level_str, Color.Yellow, scale, alpha )

        else

            local level_pos_2d = pos_2d - Vector2( level_width / 2, level_height / 2 )
            self:DrawShadowedText( level_pos_2d - Vector2(0, level_height), level_str, Color.Yellow, scale, alpha )

        end

        pos_2d = pos_2d - Vector2( width / 2, height / 2 )

        -- Draw the name
        self:DrawShadowedText( pos_2d, text, colour, scale, alpha )

        if draw_healthbar and scale > 0.75 and health > 0 then
            -- Move the draw position down
            pos_2d.y = pos_2d.y + height + 2

            local actual_width = width

            if width < 50 then
                actual_width = 50
            end

            local offset = Vector2( actual_width - width, 0 ) / 2

            pos_2d = pos_2d - offset

            self:DrawHealthbar( pos_2d, scale,
                                actual_width, 
                                3 * scale, 
                                health, 
                                self.zero_health, 
                                self.full_health, 
                                alpha )
        end
    end
end

function Nametags:DrawCircle( pos_3d, scale, alpha, colour )
    local radius = 6
    local shadow_radius = radius + 1
    local pos_2d, success = Render:WorldToScreen( pos_3d )
    if not success then return end

    radius = radius * scale
    shadow_radius = shadow_radius * scale

    colour.a = colour.a * alpha
    local shadow_colour = Color( 0, 0, 0, 255 * alpha )

    Render:FillCircle( pos_2d, shadow_radius, shadow_colour )
    Render:FillCircle( pos_2d, radius, colour )
end

function Nametags:DrawFullTag( pos, name, dist, colour, health, nametag, level )
     -- Calculate the alpha for the player nametag
    local scale         = Nametags:CalculateAlpha(  dist, 
                                                    self.player_bias,
                                                    self.player_max,
                                                    self.player_limit )

    -- Make sure we're supposed to draw
    if scale == nil then return end

    local alpha = scale * 255

    -- Draw the player nametag!
    self:DrawNametag( pos, name, colour, scale, alpha, health, true, nametag, level )
end

function Nametags:DrawCircleTag( pos, dist, colour )
    local scale = math.lerp( 1, 0, math.clamp( 1, 0, dist/self.player_limit ) )

    -- Make sure we're supposed to draw
    if scale == nil then return end

    self:DrawCircle( pos, scale, scale, colour )
end

function Nametags:CanDraw(p)

    -- Always render admins
    if p:GetValue("Admin") then return true end

    if AreFriends(LocalPlayer, tostring(p:GetSteamId())) then return true end
    
    if LocalPlayer:GetValue("Admin") then return true end

    if LocalPlayer:GetValue("InSafezone") and not p:GetValue("InSafezone") then
        
        local exp = LocalPlayer:GetValue("Exp")

        if exp and exp.level == 0 then return true end

    elseif LocalPlayer:GetValue("InSafezone") and p:GetValue("InSafezone") then return true end

    return false

end

function Nametags:DrawDrone(args)
    local drone = args.drone
    local pos = args.position + Vector3.Up * 0.5
    self:DrawFullTag( pos, "Drone", 5, Color.Red, drone.health / drone.max_health, nil, drone.level )
end

function Nametags:DrawPlayer( player_data )
    local p         = player_data[1]

    if not self:CanDraw(p) then return end

    local dist      = player_data[2]

    local pos       = p:GetBonePosition( "ragdoll_Head" ) + 
                      (p:GetAngle() * Vector3( 0, 0.25, 0 ))

    local colour    = p:GetColor()

    if self.minimap_enabled then
        local radar_pos_2d, radar_success = Render:WorldToMinimap(pos)

        if radar_success then
            local size = Vector2( 6, 6 )
            local color = self.FriendColor
            color.a = (Game:GetSetting( GameSetting.HUDOpacity ) / 100) * 255
            Render:FillCircle(radar_pos_2d - size/2, size.x, color )
            Render:DrawCircle(radar_pos_2d - size/2, size.x, Color.Black )
        end
    end

    local exp = p:GetValue("Exp")
    local level = exp and exp.level or ""

    if self.player_count <= 20 then
        if  self:AimingAt( pos ) < 0.1 or
            (LocalPlayer:InVehicle() and p:GetVehicle() == LocalPlayer:GetVehicle()) or
            self.player_count <= 10 then

            self:DrawFullTag( pos, p:GetName(), dist, colour, p:GetHealth(), p:GetValue("NameTag"), level )

        elseif not (IsValid(self.highlighted_vehicle) and p:InVehicle() and
                    self.highlighted_vehicle == p:GetVehicle()) then

            self:DrawCircleTag( pos, dist, colour )
        end
    else
        if self:AimingAt( pos ) < 0.005 then
            self:DrawFullTag( pos, p:GetName(), dist, colour, p:GetHealth(), p:GetValue("NameTag"), level )
        else
            self:DrawCircleTag( pos, dist, colour )
        end
    end
end

function Nametags:DrawVehicle( vehicle_data )
    local v             = vehicle_data[1]
    local dist          = vehicle_data[2]
    local aim_dist      = vehicle_data[3]

    -- Get the first colour of the vehicle
    local colour = v:GetColors()

    -- Use a 30% blend of white and the vehicle colour to give a nice
    -- colour with a tinge that corresponds to the vehicle
    colour = math.lerp( Color( 200, 200, 200 ), colour, 0.3 )

    -- Calculate the alpha for the vehicle nametag
    local scale         = Nametags:CalculateAlpha(  dist, 
                                                    self.vehicle_bias, 
                                                    self.vehicle_max, 
                                                    self.vehicle_limit )

    -- Make sure we're supposed to draw
    if scale ~= nil then
        -- Factor of aim distance from vehicle used to fade in
        local alpha = scale * 255 * (1.0 - (aim_dist * 10))

        -- Draw the vehicle nametag!
        self:DrawNametag(   v:GetPosition() + Vector3( 0, 1, 0 ), 
                            v:GetName(), colour, 
                            scale, alpha, v:GetHealth(), false )
    end
end

function Nametags:LocalPlayerInput( args )
    if self:GetWindowOpen() and Game:GetState() == GUIState.Game then
        return false
    end
end

function Nametags:WindowClosed( args )
    self:SetWindowOpen( false )
end

function Nametags:ModulesLoad()
    Events:Fire( "HelpAddItem",
        {
            name = "Nametags",
            text = 
                "The nametags are the names you see on players and vehicles." ..
                "\n\n" ..
                "To configure them, type /tags in chat to bring " ..
                "up a window in which you can choose your own settings."
        } )
end

function Nametags:ModuleUnload()
    Events:Fire( "HelpRemoveItem",
        {
            name = "Nametags"
        } )
end

function Nametags:Render()
    -- If we're not supposed to draw now, then take us out
    if not self.enabled or Game:GetState() ~= GUIState.Game or LocalPlayer:GetValue("MapOpen") then
        return
    end

    -- Create some prerequisite variables
    --local local_pos = LocalPlayer:GetPosition()
    local local_pos = Camera:GetPosition()

    self.highlighted_vehicle = nil

    if self.vehicle_enabled then
        local sorted_vehicles = {}

        for v in Client:GetVehicles() do
            if IsValid(v) then
                local pos = v:GetPosition()
                table.insert( sorted_vehicles, 
                    { v, local_pos:Distance(pos), self:AimingAt(v:GetPosition()) } )
            end
        end

        -- Sort by distance from aim, and distance from player, descending
        table.sort( sorted_vehicles, 
            function( a, b ) 
                local aim1 = a[3] * 5000
                local aim2 = b[3] * 5000
                local dist1 = a[2]
                local dist2 = b[2]

                return (aim1 + dist1) < (aim2 + dist2)
            end )

        if #sorted_vehicles > 0 then
            local vehicle_data  = sorted_vehicles[1]
            local vehicle       = vehicle_data[1]
            local aim_dist      = vehicle_data[3]

            if  LocalPlayer:GetVehicle() ~= vehicle and 
                #vehicle:GetOccupants() == 0 and 
                aim_dist < 0.1 then

                self:DrawVehicle( vehicle_data )
                self.highlighted_vehicle = vehicle
            end
        end
    end

    if self.player_enabled then
        local sorted_players = {}
        --table.insert( sorted_players, { LocalPlayer, 0})

        for p in Client:GetStreamedPlayers() do
            local pos = p:GetPosition()
            table.insert( sorted_players, { p, local_pos:Distance(pos) } )
        end

        -- Sort by distance, descending
        table.sort( sorted_players, 
            function( a, b ) 
                return (a[2] > b[2]) 
            end )

        self.player_count = #sorted_players

        for _, player_data in ipairs( sorted_players ) do
            self:DrawPlayer( player_data )
        end
    end

    local time = Client:GetElapsedSeconds()
    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 1000)
    if ray.entity and ray.entity.__type == "ClientStaticObject" and ray.entity:GetModel() == "lave.v023_customcar.eez/v023-base.lod" then
        self.recent_drones[ray.entity:GetId()] = {time = time, entity = ray.entity}
    end

    -- TODO: sort by distance to determine render order like player tags
    for cso_id, data in pairs(self.recent_drones) do
        -- Render nametags for drones while looking at the base piece only
        if time - data.time > 2 or not IsValid(data.entity) then
            self.recent_drones[cso_id] = nil
        else
            local drone = cDroneContainer:CSOIdToDrone(cso_id)
            local args = 
            {
                position = data.entity:GetPosition(),
                drone = drone
            }

            if drone then
                self:DrawDrone(args)
            end
        end
    end
end

function Nametags:LocalPlayerChat( args )
    local msg = args.text

    if msg == "/tags" then
        self:SetWindowOpen( not self:GetWindowOpen() )
    end
end

-- Create our class, and start the script proper
script = Nametags()