class 'sMine'

function sMine:__init(args)

    self.position = args.position
    self.owner_id = args.owner_id
    self.exploded = false

end

function sMine:Explode(player)

    if self.exploded then return false end -- Already exploded
    if tostring(player:GetSteamId() == self.owner_id) then return false end -- This is the owner, don't explode
    if player:GetPosition():Distance(self.position) > ItemsConfig.Usables.Mine.explode_radius then return false end -- Too far

    Network:Send(player, "items/MineExplode", {position = self.position})
    Network:SendNearby(player, "items/MineExplode", {position = self.position})

    self.exploded = true

    return true

end