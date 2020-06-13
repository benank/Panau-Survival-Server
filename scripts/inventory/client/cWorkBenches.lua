class 'cWorkBenches'

function cWorkBenches:__init()

    self.sounds = {}
    self.fx = {}

    self.active_workbenches = {} -- [id] = {position, state}

    -- 79 for finish firework

    -- 118 fire

    -- f2m05_buildingfall streaks for laser grenade 

    Network:Subscribe("Workbenches/ChangeState", self, self.ChangeState)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function cWorkBenches:ChangeState(args)


    -- also events fire to update map
end

function cWorkBenches:PlayFinishEffect(pos)

    ClientEffect.Play(AssetLocation.Game, {
        position = pos,
        angle = Angle(),
        effect_id = 79
    })

end

function cWorkBenches:CreateAmbientWorkbenchSound(pos)
    
    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 32,
        sound_id = 24,
        position = pos,
        angle = Angle()
    })

    sound:SetParameter(0,1)
    sound:SetParameter(1,0)
    sound:SetParameter(2,0)

end

function cWorkBenches:PlayCombiningSound(pos, time)

    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 19,
        sound_id = 40,
        position = pos,
        angle = Angle()
    })

    sound:SetParameter(0,1)

end

function cWorkBenches:
