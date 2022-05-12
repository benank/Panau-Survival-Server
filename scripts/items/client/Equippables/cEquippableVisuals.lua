EquippableVisuals = 
{
    ["Combat Backpack"] = 
    {
        model = "pd_gov_base02.eez/pd_gov_base-bags.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-1.25,0),
        angle = Angle()
    },
    ["Explorer Backpack"] = 
    {
        model = "pd_ularboysbase1.eez/pd_ularboys_base_male-backpack.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-1.25,0),
        angle = Angle()
    },
    ["Helmet"] = 
    {
        model = "pd_oilplatform_male1.eez/pd_oilplatform-helmet.lod",
        bone = "ragdoll_Head",
        offset = Vector3(0,-1.64,-0.0425),
        angle = Angle()
    },
    ["Police Helmet"] = 
    {
        model = "pd_panaupolice.eez/panaupolice-helmet.lod",
        bone = "ragdoll_Head",
        offset = Vector3(0,-1.64,-0.0425),
        angle = Angle()
    },
    ["Military Helmet"] = 
    {
        model = "pd_gov_elite.eez/pd_govnewfix_elite-helmet.lod",
        bone = "ragdoll_Head",
        offset = Vector3(0,-1.63,-0.03),
        angle = Angle()
    },
    ["Military Vest"] = 
    {
        model = "pd_gov_elite.eez/pd_govnewfix_elite-vest1.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-1.25,0),
        angle = Angle()
    },
    ["Kevlar Vest"] = 
    {
        model = "pd_gov_elite.eez/pd_govnewfix_elite-vest2.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-1.25,0),
        angle = Angle()
    },
    ["Palm Costume"] = 
    {
        model = "vegetation_0.blz/jungle_T11_palmS-Whole.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,0,0),
        angle = Angle()
    },
    ["Umbrella Costume"] = 
    {
        model = "37x10.nlz/go220-b.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-0.5,0),
        angle = Angle()
    },
    ["Heli Costume"] = 
    {
        model = "arve.v059_civilian_helicopter.eez/v059-body_m.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-2,0),
        angle = Angle()
    },
    ["Boat Costume"] = 
    {
        model = "seve.v089_raceboat.eez/v089-body_m.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-1,0),
        angle = Angle()
    },
    ["Car Costume"] = 
    {
        model = "lave.v030_super_sportcar.eez/v030-body_m.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-1,0),
        angle = Angle()
    },
    ["Halo Hat"] = 
    {
        model = "general.blz/halo_01-a.lod",
        bone = "ragdoll_Head",
        offset = Vector3(0,0,0),
        angle = Angle()
    },
    ["Meathead Hat"] = 
    {
        model = "bwc.nlz/v320-mt02.lod",
        bone = "ragdoll_Head",
        offset = Vector3(0,0,0),
        angle = Angle()
    },
    ["Sun Costume"] = 
    {
        model = "general.blz/muzzle-muzzle.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,0,0),
        angle = Angle()
    },
    ["Snowman Outfit"] = 
    {
        model = "f3m06.afterski.nlz/key020_01-t.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-1,0),
        angle = Angle(math.pi, -math.pi / 12, 0)
    },
    ["Wall Costume"] = 
    {
        model = "obj.jumpgarbage.eez/gb206-g.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,0,0),
        angle = Angle(0, 1.57, 0)
    },
    ["Cone Hat"] = 
    {
        model = "35x12.nlz/go040-b.lod",
        bone = "ragdoll_Head",
        offset = Vector3(0,-0.1,0),
        angle = Angle()
    },
    ["Stash Costume"] = 
    {
        model = "areaset03.blz/go161-a1_dst.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-1,0),
        angle = Angle()
    },
    ["Plant Costume"] = 
    {
        model = "Jungle_B03_SnakeplantM-Whole.lod",
        bone = "ragdoll_Spine1",
        offset = Vector3(0,-1,0),
        angle = Angle()
    },
    ["Two Year Party Hat"] = 
    {
        render = true,
        bone = "ragdoll_Head",
        offset = Vector3(-0.11,-0.55,0),
        angle = Angle(math.pi, math.pi, 0),
        text = "2",
        fontsize = 200,
        scale = 0.0025,
        color = function(total_delta)
            return Color.FromHSV(total_delta * 360 * 0.2, 1, 1) 
        end
    },
}