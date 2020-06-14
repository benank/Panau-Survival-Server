class 'sWorkBenchManager'

function sWorkBenchManager:__init()

    self.workbenches = {}

    Events:Subscribe("LoadStatus", self, self.LoadStatus)

    Network:Subscribe("Workbenches/StartCombine", self, self.StartCombine)

end

function sWorkBenchManager:StartCombine(args, player)

    if not args.id then return end

    local workbench = self.workbenches[args.id]

    if not workbench then return end

    workbench:BeginCombining(player)

end

function sWorkBenchManager:LoadStatus(args)

    -- Send player workbench status
    for name, workbench in pairs(self.workbenches) do
        workbench:SyncStatus(args.player)
    end

end

function sWorkBenchManager:CreateWorkbenches()

    local id = -20

    for name, data in pairs(WorkBenchConfig.locations) do

        local lootbox_data = Lootbox.Stashes[Lootbox.Types.Workbench]

        id = id - 1

        local lootbox = sStashes:AddStash({
            id = id,
            position = data.position,
            angle = data.angle,
            tier = Lootbox.Types.Workbench,
            contents = {},
            owner_id = "SERVER",
            health = lootbox_data.health,
            access_mode = lootbox_data.default_access
        })

        local workbench = sWorkBench({
            lootbox = lootbox,
            stash = lootbox.stash,
            name = name
        })

        self.workbenches[id] = workbench

    end

end

sWorkBenchManager = sWorkBenchManager()