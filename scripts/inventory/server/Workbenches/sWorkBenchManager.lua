class 'sWorkBenchManager'

function sWorkBenchManager:__init()

    self.workbenches = {}

    Events:Subscribe("LoadStatus", self, self.LoadStatus)

end

function sWorkBenchManager:LoadStatus(args)

    -- Send player workbench info

    for index, workbench in pairs(self.workbenches) do

        if workbench.status == WorkBenchState.Combining then
            Network:Send(args.player, )

    end

end

function sWorkBenchManager:CreateWorkbenches()

    for index, data in pairs(WorkBenchConfig.locations) do

        local lootbox_data = Lootbox.Stashes[Lootbox.Types.Workbench]

        local lootbox = sStashes:AddStash({
            id = -20 + index,
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
            stash = lootbox.stash
        })

        self.workbenches[index] = workbench

    end

end

sWorkBenchManager = sWorkBenchManager()