--[[
class "FollowPathBehavior"
FollowPathBehavior.name = "FollowPathBehavior"

-- requires that the actor profile has a Path
function FollowPathBehavior:__init(actor_profile_instance)
    self.actor_profile_instance = actor_profile_instance
    getter_setter(self, "active")
    getter_setter(self, "path_progress")

    self.moving = false

    print("actor id: ", tostring(self.actor_profile_instance.actor.actor_id))
    if IsTest then
        Events:Subscribe("Render", self, self.RenderDebug)
    end
    Network:Subscribe("npc/NextPath" .. tostring(self.actor_profile_instance.actor.actor_id), self, self.NextPath)
    self:StartUpdateThread()
end

function FollowPathBehavior:GetPosition()
    if not self.path_navigation then return nil end
    return self.path_navigation:GetPosition()
end

function FollowPathBehavior:StartUpdateThread()
    self.update_thread = Thread(function()
        Timer.Sleep(500)

        while self.active do
            Timer.Sleep(150)
            self.client_actor = self.actor_profile_instance.client_actor

            if self.path and IsValid(self.client_actor) then
                self.client_actor_position = self.client_actor:GetPosition()
                self.client_actor_angle = self.client_actor:GetAngle()
                self:ContinuePathing()
            end
        end
    end)
end

function FollowPathBehavior:FollowNewPath(path, path_progress, path_speed_multiplier)
    self.path = path
    self.path_navigation = PathNavigation()
    self.path_navigation:SetPath(path)
    self.path_navigation:SetSpeedMultiplier(path_speed_multiplier)
    self.path_navigation:SetInitialProgress(path_progress)
    self.path_navigation:StartPath()

    self.current_path_speed_multiplier = path_speed_multiplier
    self.current_node_index = self.path_navigation:GetCurrentNodeIndex()
    Chat:Print("Starting on node index of " .. tostring(self.current_node_index), Color.Aqua)
    self.current_node = self.path.positions[self.current_node_index]
end

function FollowPathBehavior:NextPath(args)
    self.stop_turning_immediately = true
    self.path = Path()
    self.path:InitializeFromJsonData(args.path)

    local ang = Angle(Angle.FromVectors(Vector3.Forward, self.path.positions[2] - self.path.positions[1]).yaw, 0, 0)

    if not IsValid(self.client_actor) then
        self.actor_profile_instance:Respawn(self.path.positions[1], ang)
    else
        -- this looks fine, no need to do fancy turning simulation or running to this position
        self.client_actor:SetPosition(self.path.positions[1])
        self.client_actor:SetAngle(ang)
    end
    self:FollowNewPath(self.path, 0.00001, self.current_path_speed_multiplier)
    self.moving = false
end

function FollowPathBehavior:EnsureIsMoving()
    if not self.moving and IsValid(self.client_actor) then
        self.client_actor:SetBaseState(7)
        self.moving = true
    end
end

function FollowPathBehavior:ContinuePathing()
    self:EnsureIsMoving()

    self.next_node = self.path.positions[self.current_node_index + 1]
    local next_node = self.next_node
    if next_node then
        local distance_to_next_node = Vector3.Distance(self.client_actor_position, next_node)
        local angle_to_next_node = Angle(Angle.FromVectors(Vector3.Forward, next_node - self.current_node).yaw, 0, 0) -- angle between the nodes
        local forward = -(self.client_actor_position - next_node):Dot(self.client_actor_angle * Vector3.Backward) -- positive if forward, negative if backward

        --print(distance_to_next_node)
        --print(forward)
        
        -- if angle_to_next_node.yaw (using clientactor pos instead) is too different from client actor angle.yaw then turn the actor

        if distance_to_next_node < 1 and (forward > -0.5 and forward < 0.5) then
            self:NextNode()
        end
    else
        --Chat:Print("Finished Path", Color.Yellow)
    end
end

function FollowPathBehavior:NextNode()
    self.current_node_index = self.current_node_index + 1
    self.current_node = self.path.positions[self.current_node_index]

    if self.path.positions[self.current_node_index + 1] then
        Chat:Print("Turning to node " .. tostring(self.current_node_index + 1), Color.Yellow)
        local ang = Angle.FromVectors(Vector3.Forward, self.path.positions[self.current_node_index + 1] - self.current_node)
        --print("TURNING")
        self:TurnToAngle(ang)
    end
    --Chat:Print("Next Node", Color.Blue)
end

function FollowPathBehavior:TurnToAngle(angle) -- yaw, 0, 0
    Chat:Print("self.stop_turning_immediately: " .. tostring(self.stop_turning_immediately), Color.Yellow)
    Chat:Print("self.turning: " .. tostring(self.turning), Color.Yellow)
    if self.stop_turning_immediately and not self.turning then
        self.stop_turning_immediately = false
    end

	if not self.turning or self.stop_turning_immediately then
		self.turning = true
		
		coroutine.wrap(function(angle)
			local timer = Timer()
			local set_angle_timer = Timer()
			local min_input_strength = .8
			local max_input_strength = 1
			local input_strength = min_input_strength
			local input_step = .005
			local ms = timer:GetMilliseconds()
			local duration = 1000
			
            while(ms < duration and not self.stop_turning_immediately) do
				--Chat:Print("Turning", Color.LawnGreen)
				ms = timer:GetMilliseconds()
				
				if ms < duration / 2 then
					input_strength = input_strength + input_step
				elseif ms > duration / 2 then	
					input_strength = input_strength - input_step
				end
				
				if input_strength > max_input_strength then input_strength = max_input_strength end
				if input_strength < min_input_strength then input_strength = min_input_strength end
				
				--print(set_angle_timer:GetMilliseconds())
				
				if set_angle_timer:GetMilliseconds() > 15 then
					set_angle_timer:Restart()
                    self.current_angle = self.client_actor:GetAngle()
                    
                    local yaw_dif = math.abs(self.current_angle.yaw - angle.yaw)
					if yaw_dif > .02 then
						local new_angle = Angle.Slerp(self.current_angle, angle, .085)
						if new_angle then
                            self.client_actor:SetAngle(new_angle)
                            --Chat:Print("TURNING!", Color.Red)
						end
					else
						break
					end
				end
				
				Timer.Sleep(1)
            end
            self.stop_turning_immediately = false
			self.turning = false
		end)(angle)
	end
end

function FollowPathBehavior:RenderDebug()
    if self.next_node then
        local transform = Transform3()
        transform:Translate(self.next_node)
        transform:Rotate(Angle(0, math.pi / 2, 0))
        Render:SetTransform(transform)
        Render:FillCircle(Vector3.Zero, 0.3, Color.Red)
        Render:ResetTransform()
    end
end
]]
