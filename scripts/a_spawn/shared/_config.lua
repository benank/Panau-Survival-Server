config = 
{
    safezone = 
    {
        position = Vector3(-10291, 202.5, -3019),
        radius = 75,
        color = Color(255,255,0,50)
    },
    neutralzone = 
    {
        position = Vector3(-10299, 204, -3012),
        radius = 2000,
        color = Color(0,106,255,100)
    }
}

local sz_config = SharedObject.Create("SafezoneConfig", config)