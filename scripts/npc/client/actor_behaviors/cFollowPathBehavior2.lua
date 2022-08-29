class "FollowPathBehavior2"
FollowPathBehavior2.name = "FollowPathBehavior2"

-- requires that the actor profile has a Path
function FollowPathBehavior2:__init(actor_profile_instance)
    self.actor_profile_instance = actor_profile_instance
    getter_setter(self, "active")
    getter_setter(self, "path_progress")
    self.max_distance_from_correct_position = 15

    self.moving = false
    self.turning = false
    self.speed_modding = false

    if IsTest then
        self.render_debug_sub = Events:Subscribe("Render", self, self.RenderDebug)
    end

    self.next_path_sub = Network:Subscribe("npc/NextPath" .. tostring(self.actor_profile_instance.actor.actor_id), self, self.NextPath)
    self:StartUpdateThread()
end

function FollowPathBehavior2:GetPosition()
    if not self.path_navigation then return nil end
    return self.path_navigation:GetPosition()
end

function FollowPathBehavior2:StartUpdateThread()
    self.update_thread = Thread(function()
        Timer.Sleep(500)

        while self.active do
            Timer.Sleep(200)
            
            --print(1, self.path)
            --print(2, self.path_navigation)
            --print(3, self.path_navigation:GetActive())
            --print(4, IsValid(self.actor_profile_instance.client_actor))
            --print(5, self.actor_profile_instance.client_actor)
            --print(6, self.active)
            if self.path and self.path_navigation and self.path_navigation:GetActive() and IsValid(self.actor_profile_instance.client_actor) then
                self.client_actor_position = self.actor_profile_instance.client_actor:GetPosition()
                self.client_actor_angle = self.actor_profile_instance.client_actor:GetAngle()
                self.correct_position = self.path_navigation:GetPosition()
                self:ContinuePathing()
            end
        end
    end)
end

function FollowPathBehavior2:FollowNewPath(path, path_progress, path_speed_multiplier)
    if self.path_navigation then
        self.path_navigation:SetActive(false)
    end

    self.path = path
    self.path_navigation = PathNavigation()
    self.path_navigation:SetPath(path)
    self.path_navigation:SetSpeedMultiplier(path_speed_multiplier)
    self.path_navigation:SetInitialProgress(path_progress)
    self.path_navigation:SetNodeReachedCallback(self.NextNode)
    self.path_navigation:SetNodeReachedCallbackInstance(self)
    self.path_navigation:StartPath()

    self.current_path_speed_multiplier = path_speed_multiplier
    self.current_node_index = self.path_navigation:GetCurrentNodeIndex()
    self.current_node = self.path.positions[self.current_node_index]
end

function FollowPathBehavior2:NextPath(args)
    self.path = Path()
    self.path:InitializeFromJsonData(args.path)
    self.actor_profile_instance:SetPath(self.path)

    local ang = Angle(Angle.FromVectors(Vector3.Forward, self.path.positions[2] - self.path.positions[1]).yaw, 0, 0)

    if not IsValid(self.actor_profile_instance.client_actor) then
        if self.actor_profile_instance.actor:GetClientActorSpawnedTime() > 3.5 then
            Chat:Print("Respawned actor at initial path node because ClientActor became invalid", Color.Red)
            self.actor_profile_instance:Respawn(self.path.positions[1], ang)
        end
    else
        -- this looks fine, no need to do fancy turning simulation or running to this position
        self.actor_profile_instance.client_actor:SetPosition(self.path.positions[1])
        self.actor_profile_instance.client_actor:SetAngle(ang)
        self.actor_profile_instance.client_actor:SetBaseState(AnimationState.SUprightBasicNavigation)
    end
    self:FollowNewPath(self.path, 0.00001, args.path_speed_multiplier)
    self.moving = false
end

function FollowPathBehavior2:EnsureIsMoving()
    if not self.moving and IsValid(self.actor_profile_instance.client_actor) then
        self.actor_profile_instance.client_actor:SetBaseState(7)
        self.moving = true
    end
end

-- high-level frequent update function for pathing
function FollowPathBehavior2:ContinuePathing()
    if self.paused then return end

    self:EnsureIsMoving()
    self:CheckIfShouldTakeCorrectiveAction()
end

function FollowPathBehavior2:CheckIfShouldTakeCorrectiveAction()
    -- calculate the yaw difference to the correct position
    --local ideal_yaw = Angle.FromVectors(Vector3.Forward, self.correct_position - self.client_actor_position).yaw
    --print("ideal yaw: ", ideal_yaw)
    --local yaw_dif = math.abs(self.client_actor_angle.yaw - ideal_yaw)
    --print("yaw_dif: ", yaw_dif)
    --Chat:Print("yaw dif: " .. tostring(yaw_dif), Color.LawnGreen)
    
    -- TODO: if left_right > threshold then turn client actor so they're heading in the right direction after being displaced
    local forward = -(self.client_actor_position - self.correct_position):Dot(Angle(self.client_actor_angle.yaw, 0, 0) * Vector3.Backward) -- positive if in-front, negative if behind

    local distance_from_correct_position = Vector3.Distance(self.client_actor_position, self.correct_position)
    -- TODO: check if distance_from_correct_position > self.max_distance_from_correct_position and teleport if too far
    
    if forward < -5 and not self.speed_modding then
        self.speed_modding = true
        
        coroutine.wrap(function()
            local timer = Timer()
            local ms = timer:GetMilliseconds()
            local duration = 5000

            while(ms < duration) do
                ms = timer:GetMilliseconds()

                if IsValid(self.actor_profile_instance.client_actor) then
                    if self.paused then break end
                    self.actor_profile_instance.client_actor:SetInput(Action.MoveForward, 0.35)
                    -- base state 19 is super fast sprint
                end

                Timer.Sleep(1)
            end

            if not self.paused then
                self.actor_profile_instance.client_actor:SetBaseState(7) -- this needs to happen to ensure we maintain regular speed
            end
            self.speed_modding = false
        end)()
    end

end

function FollowPathBehavior2:NextNode(node_index)
    self.current_node_index = node_index
    self.current_node = self.path.positions[self.current_node_index]

    if self.path.positions[self.current_node_index + 1] then
        --Chat:Print("Turning to node " .. tostring(self.current_node_index + 1), Color.Yellow)
        if self.actor_profile_instance.client_actor and IsValid(self.actor_profile_instance.client_actor) then
            local ang = Angle.FromVectors(Vector3.Forward, self.path.positions[self.current_node_index + 1] - self.actor_profile_instance.client_actor:GetPosition())
            self:TurnToAngle(ang)
        end
    end
    --Chat:Print("Next Node", Color.Blue)
end

function FollowPathBehavior2:PausePath()
    if self.path_navigation then
        self.path_navigation:Pause()
    end
    if self.actor_profile_instance.client_actor and IsValid(self.actor_profile_instance.client_actor) then
        self.actor_profile_instance.client_actor:SetBaseState(6) -- idle
        self.moving = false
    end

    self.paused = true
end

function FollowPathBehavior2:ResumePath()
    self.paused = false

    -- turn to next node
    self:TurnToCurrentNode()
    if self.path_navigation then
        self.path_navigation:Resume()
    end
end

function FollowPathBehavior2:TurnToCurrentNode()
    if self.path.positions[self.current_node_index + 1] then
        local ang = Angle.FromVectors(Vector3.Forward, self.path.positions[self.current_node_index + 1] - self.actor_profile_instance.client_actor:GetPosition())
        self:TurnToAngle(ang)
    end
end

function FollowPathBehavior2:TurnToAngle(angle) -- yaw, 0, 0
    self.turning = true
    coroutine.wrap(function(angle)
        local timer = Timer()
        local set_angle_timer = Timer()
        local input_step = .005
        local ms = timer:GetMilliseconds()
        local duration = 1000
        local client_actor_angle_safe
        
        while(ms < duration) do
            --Chat:Print("In Turning Loop", Color.LawnGreen)
            ms = timer:GetMilliseconds()
            
            --print(set_angle_timer:GetMilliseconds())
            
            if set_angle_timer:GetMilliseconds() > 15 then
                if not IsValid(self.actor_profile_instance.client_actor) then
                    break
                end
                set_angle_timer:Restart()
                client_actor_angle_safe = Angle(self.actor_profile_instance.client_actor:GetAngle().yaw, 0, 0)
                
                local yaw_dif = math.abs(client_actor_angle_safe.yaw - angle.yaw)
                if yaw_dif > .02 then
                    local new_angle = Angle.Slerp(client_actor_angle_safe, angle, .085)
                    if new_angle then
                        new_angle.roll = 0
                        new_angle.pitch = 0
                        self.actor_profile_instance.client_actor:SetAngle(new_angle)
                        --Chat:Print("TURNING!", Color.Red)
                    else
                        Chat:Print("Invalid Angle in Turn", Color.Red)
                    end
                else
                    break
                end
            end
            
            Timer.Sleep(1)
        end
        self.turning = false
    end)(angle)
end

function FollowPathBehavior2:RenderDebug()
    if self.next_node and false then
        local transform = Transform3()
        transform:Translate(self.next_node)
        transform:Rotate(Angle(0, math.pi / 2, 0))
        Render:SetTransform(transform)
        Render:FillCircle(Vector3.Zero, 0.20, Color.Red)
        Render:ResetTransform()
    end

    if self.correct_position then
        local transform = Transform3()
        transform:Translate(self.correct_position)
        transform:Rotate(Angle(0, math.pi / 2, 0))
        Render:SetTransform(transform)
        Render:FillCircle(Vector3.Zero, 0.20, Color.LawnGreen)
        Render:ResetTransform()
    end
end

function FollowPathBehavior2:Remove()
    Network:Unsubscribe(self.next_path_sub)
    if self.render_debug_sub then
        Events:Unsubscribe(self.render_debug_sub)
    end
    self.path_navigation = nil
    self.update_thread = nil
end