class "PathNavigation"

function PathNavigation:__init()
    getter_setter(self, "active")
    getter_setter(self, "paused")
    getter_setter(self, "path")
    getter_setter(self, "speed_multiplier")
    getter_setter(self, "initial_progress")
    getter_setter(self, "path_finished_callback")
    getter_setter(self, "path_finished_callback_instance")
    getter_setter(self, "node_reached_callback")
    getter_setter(self, "node_reached_callback_instance")
    self.active = false
    self.paused = false
    self.initial_progress = 0
    self.has_computed_path = false
    self.last_current_node_index = 0
end

function PathNavigation:StartPath()
    self.active = true
    self.life_timer = Timer()

    if not self.has_computed_path then
        self:ComputePath()
    end

    self.check_finished_interval = Timer.SetInterval(250, function()
        if self and self.path and self.path_finished_callback then
            if self:GetPathProgress() >= 1.00 then
                self.path_finished_callback(self.path_finished_callback_instance)
                Timer.Clear(self.check_finished_interval)
                self.check_finished_interval = nil
            end
        else
            Timer.Clear(self.check_finished_interval)
            self.check_finished_interval = nil
        end
    end)

    self.node_reached_interval = Timer.SetInterval(200, function()
        if self and self.active and self.path and self.node_reached_callback then
            -- TODO: find a less expensive way to compute current_node_index using computed data?
            local current_node_index = self:GetCurrentNodeIndex()
            if current_node_index > self.last_current_node_index then
                self.last_current_node_index = current_node_index
                self.node_reached_callback(self.node_reached_callback_instance, current_node_index)
            end
        else
            Timer.Clear(self.node_reached_interval)
            self.node_reached_interval = nil
        end
    end)
end

function PathNavigation:GetPosition()
    if not self.has_computed_path then
        self:ComputePath()
    end

    if self.paused then
        return self.paused_position
    end

    local path_positions = self.path:GetPositions()
    local progress_percentage = self:GetPathProgress()
    if progress_percentage >= 1.00 then
        return path_positions[#path_positions]
    end
    local distance_travelled = self.path_distance_total * progress_percentage
    local progress_percentage_to_next_node
    local current_node_index, next_node_index
    for node_index, position in ipairs(path_positions) do
        distance_travelled = distance_travelled - self.path_distance_map[node_index]
        if distance_travelled < 0 then
            progress_percentage_to_next_node = (distance_travelled + self.path_distance_map[node_index]) / self.path_distance_map[node_index]
            current_node_index = node_index
            next_node_index = node_index + 1
            --print("Currently at node " .. tostring(node_index))
            --print("overall progress percentage: " .. tostring(math.round(progress_percentage, 3)))
            --print("progress to next node: " .. tostring(progress_percentage_to_next_node))
            break
        end
    end

    if not next_node_index then
        return path_positions[#path_positions]
    end

    local exact_position = math.lerp(
        path_positions[current_node_index],
        path_positions[next_node_index],
        progress_percentage_to_next_node
    )

    return exact_position
end

-- returns 0.0 -> 1.0 path progress
function PathNavigation:GetPathProgress()
    if self.paused then
        return self.initial_progress
    end

    if not self.has_computed_path then
        self:ComputePath()
    end
    
    local initial_progress_ms = self.lifetime_ms * self.initial_progress
    local life_time_ms = (self.life_timer:GetMilliseconds() + initial_progress_ms) or 1.0
    return life_time_ms / self.lifetime_ms
end

function PathNavigation:Pause()
    self.paused_position = self:GetPosition()
    self.paused_node_index = self:GetCurrentNodeIndex()
    self.initial_progress = self:GetPathProgress()
    self.paused = true
end

function PathNavigation:Resume()
    self.life_timer:Restart()
    self.paused = false
end

function PathNavigation:GetCurrentNodeIndex()
    if not self.has_computed_path then
        self:ComputePath()
    end

    if self.paused then
        return self.paused_node_index
    end

    local progress_percentage = self:GetPathProgress()
    local distance_travelled = self.path_distance_total * progress_percentage
    local path_positions = self.path:GetPositions()
    local progress_percentage_to_next_node
    local current_node_index, next_node_index
    local node_distance
    for node_index, position in ipairs(path_positions) do
        node_distance = self.path_distance_map[node_index]
        if node_distance then
            distance_travelled = distance_travelled - node_distance
            if distance_travelled < 0 then
                return node_index
            end
        end
    end

    return #path_positions
end

function PathNavigation:ComputePath()
    self.has_computed_path = true
    self.path_distance_total = 0
    self.path_distance_map = {}

    local dist
    local next_position
    local distance_to_next_node
    local distance_function = Vector3.Distance
    local path_positions = self.path:GetPositions()
    for node_index, position in ipairs(path_positions) do
        next_position = path_positions[node_index + 1]
        if next_position then
            distance_to_next_node = distance_function(position, next_position)
            self.path_distance_total = self.path_distance_total + distance_to_next_node
            self.path_distance_map[node_index] = distance_to_next_node
        end
    end

    self.lifetime_ms = self.path_distance_total * (1000.0 / self.speed_multiplier) -- TODO: replace with speed
    --print("lifetime_ms: ", self.lifetime_ms)
end
